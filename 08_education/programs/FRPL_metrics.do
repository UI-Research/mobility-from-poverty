** FREE AND REDUCED PRICE LUNCH: the share of students attending schools where 40% or more students receive FRPL **
** E Blom **
** 2020/08/04 **
** Instructions: only lines 8-10 need to be edited for the latest year of data **

clear all

global gitfolder "K:\EDP\EDP_shared\gates-mobility-metrics"
global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Education"
global year=2018

global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"
cd "${gitfolder}\08_education\data"


** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")


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


** get CCD enrollment **
educationdata using "school ccd enrollment race", sub(year=${year}) csv clear
save "Raw\ccd_enr_${year}.dta", replace

keep if grade==99 & sex==99
drop leaid ncessch_num grade sex fips
reshape wide enrollment, i(year ncessch) j(race)
save "Intermediate\ccd_enr_${year}_wide.dta", replace


** get CCD directory data **
educationdata using "school ccd directory", sub(year=${year}) csv clear
save "Raw\ccd_dir_${year}.dta", replace

merge 1:1 year ncessch using "Intermediate\ccd_enr_${year}_wide.dta"

save "Intermediate/combined_${year}.dta", replace


** county-level rates **
use "Intermediate/combined_${year}.dta", clear

drop if enrollment==. | enrollment==0

** CAUTION: SEVERAL STATES DO NOT REPORT FRPL **
gen no_frpl = free_or_reduced==.
gen no_dc = direct_cert==.

tab fips no_frpl, row nofreq rowsort
tab fips no_dc, row nofreq rowsort

tab fips no_frpl, row nofreq rowsort, if ~(no_dc==1 & no_frpl==1) // for footnotes
tab fips no_dc, row nofreq rowsort, if ~(no_dc==1 & no_frpl==1)

gen frpl_share = max(free_or_reduced, direct_cert) /  enrollment
gen frpl_40 = (frpl_share>0.40) if frpl_share!=.
replace frpl_40 = 0 if frpl_share==.

gen numerator = enrollment
replace numerator = 0 if frpl_40 == 0

forvalues i=1/3 {
	gen numerator`i' = enrollment`i'
	replace numerator`i' = 0 if frpl_40 == 0
} 

_strip_labels county_code
tostring county_code, replace
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
assert strlen(county)==3

collapse (sum) enrollment enrollment1 enrollment2 enrollment3 numerator*, by(year state county)

gen frpl40_total = numerator/enrollment
gen frpl40_white = numerator1/enrollment1
gen frpl40_black = numerator2/enrollment2
gen frpl40_hispanic = numerator3/enrollment3

drop enrollment* numerator*

keep year state county frpl40_total frpl40_white frpl40_black frpl40_hispanic
order year state county frpl40_total frpl40_white frpl40_black frpl40_hispanic
duplicates drop

merge 1:1 year state county using "Intermediate/countyfile.dta"
drop if _merge==1 // drops territories
drop _merge

keep if year==$year

gsort -year state county

export delimited using "Built/FRPL.csv", replace
export delimited using "${boxfolder}/FRPL.csv", replace

/* Footnotes for 2018: 
Partial FRPL, partial DC: Ohio, Alaska
Other states with <1% reprting DC instead of FRPL: Pennsylviana, Indiana, Arizona, Alabama, West Virginia
States with 100% DC: Massachusetts, Tennessee, DC, Delaware
*/

