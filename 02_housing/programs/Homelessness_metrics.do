** HOMELESSNESS **
** E Blom **
** 2020/08/04 **
** Instructions: only lines 8 and 9 need to be edited **

clear all

global gitfolder "K:\EDP\EDP_shared\gates-mobility-metrics"
global year=2018

global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"
cd "${gitfolder}\02_housing\data"

** Import county file **
import delimited ${countyfile}, clear
drop population state_name county_name

tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

save "Intermediate/countyfile.dta", replace


** Get CCD district data **
educationdata using "district ccd directory", sub(year=${year}) col(year leaid county_code) clear

_strip_labels county_code
tostring county_code, replace
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
assert strlen(county)==3
drop county_code

save "Intermediate/ccd_lea_${year}.dta", replace


** Create school-county crosswalk **
educationdata using "school ccd directory", sub(year=${year}) csv clear
save "Raw\ccd_dir_${year}.dta", replace

keep year leaid county_code enrollment

drop if enrollment == 0 | enrollment == .

_strip_labels county_code
tostring county_code, replace
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
assert strlen(county)==3
drop county_code

collapse (sum) enrollment, by(year leaid state county)
bysort year leaid: egen county_share = pc(enrollment), prop
drop enrollment

save "Intermediate\leaid_county_crosswalk_${year}.dta", replace


** Download EDFacts data **
local nextyear = ${year} - 2000 + 1
copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy${year}-`nextyear'-wide.csv" "Raw/EDFacts Homelessness ${year}.csv", replace
import delimited "Raw/EDFacts Homelessness ${year}.csv", clear
gen year = ${year}
save "Raw/EDFacts Homelessness ${year}.csv", replace


** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
** I replaced all suppressed data with the midpoint (1) but this does not yield numbers that align with the report sent by Claudia **
** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **
use "Raw/EDFacts Homelessness ${year}.csv", clear

rename total homeless

foreach var in homeless { // hotels_motels unsheltered sheltered doubled_up
	di "`var'"
	gen supp_`var' = 1 if `var'=="S"
	replace `var'="1" if `var'=="S"
	destring `var', replace
	bysort fipst subgrant_status: egen min_`var' = min(`var')
	bysort fipst subgrant_status: egen count_supp_`var' = total(supp_`var')
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}

keep year leaid homeless homeless_lower_ci homeless_upper_ci supp_homeless
tostring leaid, replace
replace leaid = "0" + leaid if strlen(leaid)!=7
assert strlen(leaid)==7

save "Intermediate/homelessness_${year}.dta", replace


** Using crosswalk above locate LEAs into counties **
use "Intermediate/homelessness_${year}.dta", clear
merge 1:m year leaid using "Intermediate/leaid_county_crosswalk_${year}.dta" // not all homeless data merges
drop if _merge==2
drop _merge

merge m:1 year leaid using "Intermediate/ccd_lea_${year}.dta", update // fill in any missing info (78 leaids)
drop if _merge==2
drop _merge

replace county_share = 1 if county_share==.

foreach var in homeless homeless_lower_ci homeless_upper_ci supp_homeless {
	replace `var' = `var'*county_share
}

collapse (sum) homeless homeless_lower_ci homeless_upper_ci supp_homeless, by(year state county)

merge 1:1 year state county using "Intermediate/countyfile.dta"
drop if _merge==1
drop _merge

keep if year==$year

order year state county homeless homeless_lower_ci homeless_upper_ci supp_homeless
rename supp_homeless districts_suppressed

gsort -year state county

export delimited using "Built/Homelessness.csv", replace



