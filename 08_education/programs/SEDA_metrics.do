** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** E Blom **
** 2020/08/04 **
** Instructions: lines 10-12 need to be edited for the latest year of data, and new data downloaded manually to the data/Raw folder **

clear all
set maxvar 10000
set matsize 10000

global gitfolder "K:\EDP\EDP_shared\gates-mobility-metrics"
global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Education"
global year=2016

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


** NOTE: Download data in advance (manually) from SEDA website **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
use "Raw/seda_county_long_gcs_v30.dta", clear

keep if subject=="ela"

gen cohort = year - grade + 8

destring countyid, gen(county)
gen learning_rate=.
gen se=.

qui levelsof county, local(counties)
local year=${year}
forvalues cohort = `year'/`year' { 
	reg mn_all c.grade#county i.county if cohort==`cohort' [aw=totgyb_all]
	foreach county of local counties {
		cap n replace learning_rate = _b[c.grade#`county'.county] if county==`county' & cohort==`cohort'
		cap n replace se = _se[c.grade#`county'.county] if county==`county' & cohort==`cohort'
	}
}

bysort cohort county: egen num_grades_included = count(mn_all)

gen learning_rate_lb = learning_rate - 1.96 * se
gen learning_rate_ub = learning_rate + 1.96 * se

keep if cohort>=2014 & cohort!=.
drop year
rename cohort year

replace countyid = substr(countyid,3,5)
assert strlen(countyid)==3

tostring fips, replace
replace fips = "0" + fips if strlen(fips)==1
assert strlen(fips)==2

keep year fips countyid learning_rate learning_rate_lb learning_rate_ub num_grades_included
order year fips countyid learning_rate learning_rate_lb learning_rate_ub num_grades_included
duplicates drop

rename fips state
rename countyid county

replace year = year - 1 // changed so that the year reflects the fall of the academic year 

gsort -year state county

gen flag = 1 if learning_rate==0 & learning_rate_lb==0 & learning_rate_ub==0
replace learning_rate = . if flag==1
replace learning_rate_lb = . if flag==1
replace learning_rate_ub = . if flag==1
drop flag

replace num_grades_included = . if learning_rate == .

save "Intermediate/SEDA.dta", replace


use "Intermediate/SEDA.dta", clear

merge 1:1 year state county using "Intermediate/countyfile.dta"

keep if year == ${year} - 1
drop if _merge==1
drop _merge

gsort -year state county

export delimited using "Built/SEDA.csv", replace
export delimited using "${boxfolder}/SEDA.csv", replace

