** Previously Free and Reduce Price Lunch: the share of students attending schools where 40% or more students receive FRPL **
** Now uses MEPS: the share of students attending schools where 20% or more students are in Poverty **
*https://oese.ed.gov/offices/office-of-discretionary-grants-support-services/well-rounded-education-programs/innovative-approaches-to-literacy/eligibility/
** E Blom ** Updated by E Gutierez
** 2022/11/28 ** Update 9/14/23 with MEPS through 2020-21
** Produces city level data 

/*
Update City-level MEPS through 2020 and reformat for Mobility Metrics - Jay Carter 2/23/2024 & Emily Gutierrez 3/6/2024

*/

clear all

global year=2020


global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github2\mobility-from-poverty\"
global education "${gitfolder}08_education\"

global raw_data "${education}data\raw\"
global intermediate_data "${education}\data\intermediate\"
global built_data "${education}data\built\"
global final_data "${education}data\final_data\"

*Updated MEPS data is not currently available on the portal, so using the file in Box - Box is an internal folder at Urban & public does not have access
*Once it is available on the portal, can comment out lines 28 and 127, and uncomment/run lines 117-118 and 126
global box "C:\Users\ekgut\Box\Metrics_2024_round\Student_Poverty_MEPS\"


// Files
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"
global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

cd "${gitfolder}\08_education\data"

cap n mkdir ${raw_data}
cap n mkdir ${intermediate_data}
cap n mkdir ${final_data}


global rebuild_portal_data = 1

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** Import city file ** 
import delimited using "${cityfile}", clear // edited 9_13_23

tostring place, replace
replace place = "0" + place if strlen(place)==4
replace place = "00" + place if strlen(place)==3
assert strlen(place)==5

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
replace city_name="Honolulu" if city_name=="Urban Honolulu"
replace city_name="Boise" if city_name=="Boise City"
replace city_name="Indianapolis" if city_name=="Indianapolis city (balance)"
replace city_name="Lexington" if city_name=="Lexington-Fayette"
replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
replace city_name="Lees Summit" if city_name=="Lee's Summit"
replace city_name="Ofallon" if city_name=="O'Fallon"
replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
replace city_name="Ofallon" if city_name=="O'Fallon"
replace city_name="Mcallen" if city_name=="McAllen"
replace city_name="Mckinney" if city_name=="McKinney"
replace city_name="Anchorage" if city_name=="Anchorage municipality"

save "intermediate/cityfile.dta", replace

** get CCD enrollment **
*add if, else command once decide how to deal with future iterations
if $rebuild_portal_data == 1 {
educationdata using "school ccd enrollment race", sub(year=2014:${year}) csv clear
save "raw\ccd_enr_2014-${year}.dta", replace
}
if $rebuild_portal_data == 0 {
	use "${raw_data}ccd_enr_2014-${year}.dta", clear
}

keep if grade==99 & sex==99
drop leaid ncessch_num grade sex fips

replace enrollment = 0 if enrollment < 0

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
replace enrollment = 0 if enrollment < 0
merge 1:1 year ncessch using "intermediate\ccd_enr_2014-${year}_wide.dta"
drop _merge
*merge 1:1 year ncessch using "raw\ccd_meps_2014-${year}.dta" // 9_13_23 using .dta file C:\Users\ekgut\Box\Metrics_2024_round\Student_Poverty_MEPS\Abrv Set of Portal Variables
merge 1:1 year ncessch using "${box}Abrv Set of Portal Variables"
tab year _merge
drop if year==2013
drop _merge

save "intermediate/combined_2014-${year}.dta", replace

** city-level rates **
use "intermediate/combined_2014-${year}.dta", clear

replace enrollment = . if enrollment<0
drop if missing(enrollment) | enrollment==0
forvalues n = 1/3 {
replace enrollment`n' = . if enrollment`n'<0
}


*Using MEPS
gen meps_share = meps_poverty_pct/100 // ./# == . and 0/# == 0
gen meps_20 = (meps_share>=.20) if !missing(meps_share) // meps_20 is . if meps_share .

gen numerator = enrollment
replace numerator = 0 if meps_20 == 0
replace numerator = . if meps_20 == .

// White, Black Hispanic
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

collapse (sum) enrollment enrollment1 enrollment2 enrollment3  numerator*, by(year state city_name)

gen meps20_total = numerator/enrollment
gen meps20_white = numerator1/enrollment1
gen meps20_black = numerator2/enrollment2
gen meps20_hispanic = numerator3/enrollment3


*Quality Check Variables
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

*city data only available for 2016+ and MEPS only available up to 2020
keep if year >= 2016 & year <= $year
merge m:1 year state city_name using "Intermediate/cityfile.dta"
tab year _merge
drop if year > $year
tab _merge if missing(place)
drop if _merge==1 // drop district data that doesn't match 
	drop _merge state_name 

*summary stats to see possible outliers
bysort year: sum
bysort state: sum

*missingness
*missingness
tab year
tab year if missing(meps20_black)
tab year if missing(meps20_hispanic)
tab year if missing(meps20_white)
tab year if missing(meps20_total)

order year state place city  meps20_black* meps20_hispanic* meps20_white* meps20_total*
gsort -year state place city

drop meps20_total meps20_total_quality city_name

foreach var in black hispanic white {
rename meps20_`var' share_meps20_`var'
rename meps20_`var'_quality share_meps20_`var'_quality
}

export delimited using "${final_data}meps_city_2020.csv", replace 
