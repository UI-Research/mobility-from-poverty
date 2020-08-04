** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** E Blom **
** 2020/08/04 **
** Instructions: lines 10 and 11 need to be edited, and new data downloaded to the data/Raw folder **

clear all
set maxvar 10000
set matsize 10000

global gitfolder "K:\EDP\EDP_shared\gates-mobility-metrics"
global year=2016

global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"
cd "${gitfolder}\08_education\data"


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
	reg mn_all c.grade#county i.county if cohort==`cohort'
	foreach county of local counties {
		cap n replace learning_rate = _b[c.grade#`county'.county] if county==`county' & cohort==`cohort'
		cap n replace se = _se[c.grade#`county'.county] if county==`county' & cohort==`cohort'
	}
}

gen learning_rate_lower_ci = learning_rate - 1.96 * se
gen learning_rate_upper_ci = learning_rate + 1.96 * se

keep if cohort>=2014 & cohort!=.
drop year
rename cohort year

replace countyid = substr(countyid,3,5)
assert strlen(countyid)==3

tostring fips, replace
replace fips = "0" + fips if strlen(fips)==1
assert strlen(fips)==2

keep year fips countyid learning_rate learning_rate_lower_ci learning_rate_upper_ci
order year fips countyid learning_rate learning_rate_lower_ci learning_rate_upper_ci
duplicates drop

rename fips state
rename countyid county

replace year = year - 1 // changed so that the year reflects the fall of the academic year 

gsort -year state county

gen flag = 1 if learning_rate==0 & learning_rate_lower_ci==0 & learning_rate_upper_ci==0
replace learning_rate = . if flag==1
replace learning_rate_lower_ci = . if flag==1
replace learning_rate_upper_ci = . if flag==1
drop flag

save "Intermediate/SEDA.dta", replace


use "Intermediate/SEDA.dta", clear

merge 1:1 year state county using "Intermediate/countyfile.dta"

keep if year == ${year} - 1
drop if _merge==1
drop _merge

gsort -year state county

export delimited using "Built/SEDA.csv", replace


