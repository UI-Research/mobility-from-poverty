* SHARE OF STUDENTS IN HIGH POVERTY SCHOOLS BY RACE/ETHNICITY **
*E Gutierrez
	** 11/28/2022 **
		** Uses MEPS: the share of students attending schools where 20% or more students are in Poverty  **
		** Uses 2014-2018 data
		** Produces city level data
	* 1/31/2025 **
		**Produces data for 2014-2021 (School Years 2014-15 through 2021-22)

**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Set up globals and directories
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty\"
global year=2021 // most recent school year - refers to school year 2021-22
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

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
** Import city crosswalk file to edit names of city crosswalk to match city location strings in CCD school district data
import delimited using "${cityfile}", clear 
*change from numeric to string and add leading zeros
tostring place, replace
replace place = "0" + place if strlen(place)==4
replace place = "00" + place if strlen(place)==3
assert strlen(place)==5
*change from numeric to string and add leading zeros
tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

rename place_name city_name
drop population 

gen city_name_edited = city_name
replace city_name_edited = subinstr(city_name_edited, " town", "", .)
replace city_name_edited = subinstr(city_name_edited, " village", "", .)
replace city_name_edited = subinstr(city_name_edited, " municipality", "", .)
replace city_name_edited = subinstr(city_name_edited, " urban county", "", .)
replace city_name_edited = subinstr(city_name_edited, " city", "", .)

drop city_name
rename city_name_edited city_name

	*hardcode fixes so names merge
	replace city_name="Ventura" if city_name=="San Buenaventura (Ventura)"
	replace city_name="Athens" if city_name=="Athens-Clarke County unified government (balance)"
	replace city_name="Augusta" if city_name=="Augusta-Richmond County consolidated government (balance)"
	replace city_name="Macon" if city_name=="Macon-Bibb County"
	replace city_name="Boise" if city_name=="Boise City"
	replace city_name="Lexington" if city_name=="Lexington-Fayette"
	replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
	replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
	replace city_name="Mcallen" if city_name=="McAllen"
	replace city_name="Mckinney" if city_name=="McKinney"
		
	save "intermediate/cityfile.dta", replace // gitignore

*****************************
*****CCD District Data*******
*****************************
** Download CCD school level enrollment by race/ethnicity data from Urban's Education Data Portal **
educationdata using "school ccd enrollment race", sub(year=2014:${year}) csv clear
save "raw\ccd_enr_2014-${year}.dta", replace
numlabel, add

replace enrollment = . if enrollment < 0

keep if grade==99 
drop grade
drop if sex==99
*add the number enrolled male and female student within race
collapse (sum) enrollment, by (year ncessch ncessch_num leaid fips race)
drop leaid ncessch_num fips

reshape wide enrollment, i(year ncessch) j(race) // 1-white, 2-black, 3-hispanic
save "intermediate\ccd_enr_2014-${year}_wide.dta", replace

** Download CCD district data from Urban's Education Data Portal - total enrollment, city location, & county codes**
educationdata using "school ccd directory", sub(year=2014:${year}) csv clear
save "raw\ccd_dir_2014-${year}.dta", replace

**Download MEPS school level data from Urban's Education Data Portal
	*Updated MEPS data is not currently available on the portal, so using an internal file that the public does not have access to
	*Once it is available on the portal, uncomment lines 96-99 and 108, comment out line 109
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
merge 1:1 year ncessch using "raw\Abrv Set of Portal Variables.dta"
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
replace county_code = . if county_code == -2
_strip_labels county_code
tostring county_code, replace // EG: 112 county codes observations have county_code==-2 [not applicable] (2015), 331 missing (2014/2015)
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
drop if county_code=="." // get rid of those missing county information
assert strlen(state)==2

gen city_name=lower(city_location)
replace city_name = proper(city_name)

*add enrollments of schools to the city level
collapse (sum) enrollment enrollment1 enrollment2 enrollment3  numerator*, by(year state city_name)

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

keep year state city_name meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
order year state city_name meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
duplicates drop

*merge to city crosswalk
merge 1:1 year state city_name using "Intermediate/cityfile.dta"
tab year _merge // nonmatches are largely 2022 and 2023, data we don't have in MEPS
drop if year > $year
drop if _merge==1 // drop ccd district data that doesn't match the those needed indicated by the crosswalk list
drop _merge state_name 
	
****************
*Quality Checks
****************

*summary stats to see possible outliers in the means, maxes, and mins.
bysort year: sum
bysort state: sum

bysort year: count // 485 cities for 2014-17 and 486 for 2018-21

*check missingness for each 
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
order year state place city  meps20_black* meps20_hispanic* meps20_white* meps20_total*
gsort -year state place city

drop meps20_total meps20_total_quality city_name

*rename variables
foreach var in black hispanic white {
rename meps20_`var' share_meps20_`var'
rename meps20_`var'_quality share_meps20_`var'_quality
}

export delimited using "final\meps_city_2014-${year}.csv", replace 
