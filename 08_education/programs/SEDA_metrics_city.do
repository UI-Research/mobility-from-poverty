** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** E Blom **
** 2020/08/04 **
** Instructions: lines 10-12 need to be edited for the latest year of data, and new data downloaded manually to the data/raw folder (currently saved on Box in the education folder) **

*creates city level estimates. uses school level and aggregates to school city location, but doesn't have breakdowns by race/ethnicity

clear all
set maxvar 10000
set matsize 10000

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
*global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Education"
global year=2018

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
** exact file: "https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_4.1.dta" for 2009-2018 **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "" "raw/seda_school_pool_gcs_4.1.dta"
use "raw/seda_school_pool_gcs_4.1.dta", clear

keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015,
** in 6th grade in 2014, etc **
gen cohort = year - grade + 8

gen county = sedacounty
gen learning_rate=.
gen se=.

*EG: this only gives 2018-2018? should it be 2014-2018?
qui levelsof county, local(counties)
local year=${year}
forvalues cohort = `year'/`year' { 
	reg gcs_mn_all c.grade#county i.county if cohort==`cohort' [aw=totgyb_all]
	foreach county of local counties {
		cap n replace learning_rate = _b[c.grade#`county'.county] if county==`county' & cohort==`cohort'
		cap n replace se = _se[c.grade#`county'.county] if county==`county' & cohort==`cohort'
	}
}

bysort cohort county: egen num_grades_included = count(gcs_mn_all)
bysort cohort county: egen total_sample_size = sum(totgyb_all)
bysort cohort county: egen min_sample_size = min(totgyb_all)

gen learning_rate_lb = learning_rate - 1.96 * se
gen learning_rate_ub = learning_rate + 1.96 * se

keep if cohort>=2014 & cohort!=.
drop year
rename cohort year

*
tostring sedacounty, replace
replace sedacounty = "0" + sedacounty if strlen(sedacounty)==4
replace sedacounty = substr(sedacounty,3,5)
assert strlen(sedacounty)==3

tostring fips, replace
replace fips = "0" + fips if strlen(fips)==1
assert strlen(fips)==2

save "intermediate/SEDA_all.dta", replace

use "intermediate/SEDA_all.dta", clear

keep year fips sedacounty learning_rate learning_rate_lb learning_rate_ub num_grades_included min_sample_size
order year fips sedacounty learning_rate learning_rate_lb learning_rate_ub num_grades_included min_sample_size
duplicates drop

rename fips state
rename sedacounty county

replace year = year - 1 // changed so that the year reflects the fall of the academic year 

gsort -year state county

gen flag = 1 if learning_rate==0 & learning_rate_lb==0 & learning_rate_ub==0
replace learning_rate = . if flag==1
replace learning_rate_lb = . if flag==1
replace learning_rate_ub = . if flag==1
drop flag

replace num_grades_included = . if learning_rate == .

gen learning_rate_quality=1 if (num_grades_included==6 | num_grades_included==5) & min_sample_size>=30 & min_sample_size!=.
replace learning_rate_quality=2 if num_grades_included==4 & min_sample_size>=30 & min_sample_size!=.
replace learning_rate_quality=3 if learning_rate!=. & learning_rate_quality==.

drop min_sample_size

save "intermediate/SEDA.dta", replace


use "intermediate/SEDA.dta", clear

merge 1:1 year state county using "intermediate/countyfile.dta"

keep if year == ${year} - 1
drop if _merge==1
drop _merge

gsort -year state county
drop num_grades_included

export delimited using "built/SEDA.csv", replace
export delimited using "${boxfolder}/SEDA.csv", replace
export delimited using "${gitfolder}\08_education\SEDA.csv", replace

