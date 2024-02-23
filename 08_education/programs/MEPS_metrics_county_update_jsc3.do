** Previously Free and Reduce Price Lunch: the share of students attending schools where 40% or more students receive FRPL **
** Now uses MEPS: the share of students attending schools where 20% or more students are in Poverty **
*https://oese.ed.gov/offices/office-of-discretionary-grants-support-services/well-rounded-education-programs/innovative-approaches-to-literacy/eligibility/
** E Blom ** Updated by E Gutierez
** 2022/11/28 ** Update 9/14/23 with MEPS through 2020-21
** Produces county data 

/*
Update County-level MEPS through 2020 and reformat for Mobility Metrics - Jay Carter 2/23/2024

*/

clear all

global year=2020


global gitfolder "C:\Users\jcarter\Documents\git_repos\mobility-from-poverty\"
global education "${gitfolder}08_education\"

global raw_data "${education}\data\raw\"
global intermediate_data "${education}\data\intermediate\"
global final_data "${education}\data\final_data\"

global box "C:\Users\jcarter\Box\"

// Files
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"
global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

cd "${gitfolder}\08_education\data"

cap n mkdir ${raw_data}
cap n mkdir ${intermediate_data}
cap n mkdir ${final_data}


** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** Import county file **
import delimited "${countyfile}", clear
drop population state_name county_name

tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

save "intermediate/countyfile.dta", replace

** get CCD enrollment **
*add if, else command once decide how to deal with future iterations
educationdata using "school ccd enrollment race", sub(year=2014:${year}) csv clear
save "raw\ccd_enr_2014-${year}.dta", replace

keep if grade==99 & sex==99
drop leaid ncessch_num grade sex fips
reshape wide enrollment, i(year ncessch) j(race)
*1-white, 2-black, 3-hispanic
save "intermediate\ccd_enr_2014-${year}_wide.dta", replace

** get CCD directory data county/city **
educationdata using "school ccd directory", sub(year=2014:${year}) csv clear
save "raw\ccd_dir_2014-${year}.dta", replace

/* edited 9_14_23 - already have the .dta file in C:\Users\ekgut\Box\My Box Notes\Mobility Metrics - MEPS\Abrv Set of Portal Variables
educationdata using "school meps", sub(year=2014:${year}) csv clear
save "raw\ccd_meps_2014-${year}.dta", replace
*/
*Merge Data together
use "raw\ccd_dir_2014-${year}.dta", clear
merge 1:1 year ncessch using "intermediate\ccd_enr_2014-${year}_wide.dta"
drop _merge
*merge 1:1 year ncessch using "raw\ccd_meps_2014-${year}.dta" // 9_13_23 using .dta file C:\Users\ekgut\Box\My Box Notes\Mobility Metrics - MEPS\Abrv Set of Portal Variables
merge 1:1 year ncessch using "${box}Mobility Metrics - MEPS\Abrv Set of Portal Variables"
tab year _merge
drop if year==2013
drop _merge

save "intermediate/combined_2014-${year}.dta", replace

** county-level rates **
use "intermediate/combined_2014-${year}.dta", clear

drop if enrollment==. | enrollment==0

*Using MEPS
gen meps_share = meps_poverty_pct/100
gen meps_20 = (meps_share>=.20) if !missing(meps_share)
replace meps_20 = 0 if missing(meps_share)

gen numerator = enrollment
replace numerator = 0 if meps_20 == 0

// White, Black Hispanic
forvalues i=1/3 {
	gen numerator`i' = enrollment`i'
	replace numerator`i' = 0 if meps_20 == 0
} 

// Other Ethnicities
gen enrollment_other = enrollment4 + enrollment5 + enrollment6 + enrollment7 + enrollment9
gen numerator4 = enrollment_other

replace numerator4 = 0 if meps_20 == 0
 

numlabel, add
replace county_code=. if county_code==-2
_strip_labels county_code
tostring county_code, replace // EG: 112 county codes observations have county_code==-2 [not applicable] (2015), 331 missing (2014/2015)
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
drop if county_code=="." // get rid of those missing county information
assert strlen(county)==3

collapse (sum) enrollment enrollment1 enrollment2 enrollment3 enrollment_other numerator*, by(year state county)

rename enrollment enrollment99
rename numerator numerator99
rename enrollment_other enrollment4

merge 1:1 year state county using "Intermediate/countyfile.dta"
tab year _merge
//# To Do start here 
drop if _merge == 1 & year >= 2014 & year <= 2020 // drops territories 
drop if year > $year
drop _merge

// Reshape Data Wide
reshape long enrollment numerator, i(year state county) j(gp)

gen subgroup = ""
replace subgroup = "White, Non-Hispanic" if gp == 1
replace subgroup = "Black, Non-Hispanic" if gp == 2
replace subgroup = "Hispanic" if gp == 3
replace subgroup = "Other Races and Ethnicities" if gp == 4
replace subgroup = "All" if gp == 99

gen meps20 = 100 * (numerator / enrollment)

* Data Quality Variable
gen meps20_quality = .
replace meps20_quality = 1 if enrollment >= 30 & !missing(meps20)
replace meps20_quality = 2 if enrollment >= 15 & missing(meps20_quality) & !missing(meps20)
replace meps20_quality = 3 if missing(meps20_quality) & !missing(meps20)

keep year state county subgroup meps20 meps20_quality
order year state county subgroup meps20 meps20_quality

gsort -year state county

*summary stats to see possible outliers
bysort year: sum
bysort state: sum

*missingness
tab year, mi
tab year if missing(meps20)

rename meps20* share_meps20*

export delimited using "${final_data}meps_county_2020.csv", replace

destring year state county, replace

save "${built_data}MEPS_2016-2020_county.dta", replace