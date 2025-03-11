* SHARE OF STUDENTS IN HIGH POVERTY SCHOOLS BY RACE/ETHNICITY **
*E Gutierrez
	** 11/28/2022 **
		** Uses MEPS: the share of students attending schools where 20% or more students are in Poverty  **
		** Uses 2014-2018 data
		** Produces county level data
	* 1/31/2025 **
		**Produces data for 2014-2021 (School Years 2014-15 through 2021-22)

**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Set up globals and directories		
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty\"
global year=2021 // most recent school year - refers to school year 2021-22
global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

************************************
*Import, edit, and save needed data*
************************************

*****************************
****City/Place Crosswalk*****
*****************************
** Import county crosswalk file to edit names of city crosswalk to match county location strings in CCD school district data
import delimited "${countyfile}", clear
drop population state_name county_name
*change from numeric to string and add leading zeros
tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3
*change from numeric to string and add leading zeros
tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

save "intermediate/countyfile.dta", replace

*****************************
*****CCD District Data*******
*****************************
** Download CCD school level enrollment by race/ethnicity data from Urban's Education Data Portal **
educationdata using "school ccd enrollment race", sub(year=2014:${year}) csv clear
save "raw\ccd_enr_2014-${year}.dta", replace
numlabel, add

replace enrollment = . if enrollment < 0

keep if grade==99 // 99 is the total enrollment inthe school, regardless of grade
drop grade
drop if sex==99 // 99 is the total enrollment in the school, regardless of sex
*add the number enrolled male and female student within race
collapse (sum) enrollment, by (year ncessch ncessch_num leaid fips race)
drop leaid ncessch_num fips

reshape wide enrollment, i(year ncessch) j(race) // *1-white, 2-black, 3-hispanic
save "intermediate\ccd_enr_2014-${year}_wide.dta", replace

** Download CCD district data from Urban's Education Data Portal - total enrollment, city location, & county codes**
educationdata using "school ccd directory", sub(year=2014:${year}) csv clear
save "raw\ccd_dir_2014-${year}.dta", replace

**Download MEPS school level data from Urban's Education Data Portal
	*Updated MEPS data is not currently available on the portal, so using an internal file that the public does not have access to
	*to check availability, just run the code in line 79. If it provides you with an error on the year, it is unavailable.
	*Once it is available on the portal, uncomment lines 79-80 and 90, comment out line 91
	/* 
	educationdata using "school meps", sub(year=2014:${year}) csv clear
	save "raw\ccd_meps_2014-${year}.dta", replace
	*/
	*This raw dataset is currently saved on Box in the Metrics_2025_round folder
*********************
*Merge Data together
*********************
use "raw\ccd_dir_2014-${year}.dta", clear
replace enrollment = 0 if enrollment < 0
merge 1:1 year ncessch using "intermediate\ccd_enr_2014-${year}_wide.dta"
drop _merge
*merge 1:1 year ncessch using "raw\ccd_meps_2014-${year}.dta" // 
merge 1:1 year ncessch using "raw\Abrv Set of Portal Variables"
tab year _merge // non merges are 2013 and 2022
drop if year==2013 | year==2022
drop _merge

replace enrollment = . if enrollment<0
drop if missing(enrollment) | enrollment==0
forvalues n = 1/3 {
replace enrollment`n' = . if enrollment`n'<0
}

*Using MEPS - edit MEPS share and binary if the share is greater than or equal to 20%
gen meps_share = meps_poverty_pct/100 // ./# == . and 0/# == 0
gen meps_20 = (meps_share>=.20) if !missing(meps_share) // meps_20 is . if meps_share .

gen numerator = enrollment
replace numerator = 0 if meps_20 == 0
replace numerator = . if meps_20 == .

*Create numerators for race - White, Black Hispanic
forvalues i=1/3 {
	gen numerator`i' = enrollment`i'
	replace numerator`i' = 0 if meps_20 == 0
	replace numerator`i' = . if meps_20 == .
}  

numlabel, add
*clean for state variable
replace county_code=. if county_code==-2
_strip_labels county_code
tostring county_code, replace // EG: 112 county codes observations have county_code==-2 [not applicable] (2015), 331 missing (2014/2015)
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
drop if county_code=="." // get rid of those missing county information
assert strlen(county)==3

*add enrollments of schools to the county level
collapse (sum) enrollment enrollment1 enrollment2 enrollment3  numerator*, by(year state county)

*create shares for total and race
gen meps20_total = numerator/enrollment
gen meps20_white = numerator1/enrollment1
gen meps20_black = numerator2/enrollment2
gen meps20_hispanic = numerator3/enrollment3

*Create quality Check Variables
gen meps20_total_quality = 1 if enrollment>=30 & meps20_total!=.
replace meps20_total_quality = 2 if enrollment>=15 & meps20_total_quality==. & meps20_total!=.
replace meps20_total_quality = 3 if meps20_total_quality==. & meps20_total!=.

gen meps20_white_quality = 1 if enrollment1>=30 &  meps20_white!=.
replace meps20_white_quality = 2 if enrollment1>=15 & meps20_white_quality==. & meps20_white!=.
replace meps20_white_quality = 3 if meps20_white_quality==. & meps20_white!=.

gen meps20_black_quality = 1 if enrollment2>=30 & meps20_black!=.
replace meps20_black_quality = 2 if enrollment2>=15 & meps20_black_quality==. & meps20_black!=.
replace meps20_black_quality = 3 if meps20_black_quality==. & meps20_black!=.

gen meps20_hispanic_quality = 1 if enrollment3>=30 & meps20_hispanic!=.
replace meps20_hispanic_quality = 2 if enrollment3>=15 & meps20_hispanic_quality==. & meps20_hispanic!=.
replace meps20_hispanic_quality = 3 if meps20_hispanic_quality==. & meps20_hispanic!=.

drop enrollment* numerator* 

keep year state county meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
order year state county meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
duplicates drop

*merge to county crosswalk
merge 1:1 year state county using "Intermediate/countyfile.dta"
tab year _merge // nonmatches are largely 2022 and 2023, data we don't have in MEPS
drop if year > $year
drop if _merge==1 // drop ccd district data that doesn't match the those needed indicated by the crosswalk list
drop _merge

****************
*Quality Checks
****************

*summary stats to see possible outliers in the means, maxes, and mins.
bysort year: sum
bysort state: sum

bysort year: count // 3142 counties for 2014-19 and 3143 for 2020-21

*check missingness for each 
*missingness should be the same across total and races/ethnicities
*missingness is generally reflective of counties missing data from the merge to the crosswalk rather that MEPS missing data (see line 164)
tab year if missing(meps20_total)
tab year if missing(meps20_black)
tab year if missing(meps20_hispanic)
tab year if missing(meps20_white)

*are all quality flags missing if metric is missing
assert meps20_total_quality==. if meps20_total==.
assert meps20_white_quality==. if meps20_white==.
assert meps20_black_quality==. if meps20_black==.
assert meps20_hispanic_quality==. if meps20_hispanic==.

*clean for output
order year state county meps20_black* meps20_hispanic* meps20_white* meps20_total*
gsort -year state county 

drop meps20_total meps20_total_quality

*rename variables
foreach var in black hispanic white {
rename meps20_`var' share_meps20_`var'
rename meps20_`var'_quality share_meps20_`var'_quality
}

export delimited using "final\meps_county_2014-${year}.csv", replace
