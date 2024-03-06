** Previously Free and Reduce Price Lunch: the share of students attending schools where 40% or more students receive FRPL **
** Now uses MEPS: the share of students attending schools where 20% or more students are in Poverty **
*https://oese.ed.gov/offices/office-of-discretionary-grants-support-services/well-rounded-education-programs/innovative-approaches-to-literacy/eligibility/
** E Blom ** Updated by E Gutierez
** 2022/11/28 ** Update 9/14/23 with MEPS through 2020-21
** Produces county data 

/*
Update County-level MEPS through 2020 and reformat for Mobility Metrics - Jay Carter 2/23/2024 & Emily Gutierrez 3/6/2024

*/

clear all

global year=2020


global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github2\mobility-from-poverty\"
global education "${gitfolder}08_education\"

global raw_data "${education}\data\raw\"
global intermediate_data "${education}\data\intermediate\"
global final_data "${education}\data\final_data\"

*Updated MEPS data is not currently available on the portal, so using the file in Box - Box is an internal folder at Urban & public does not have access
*Once it is available on the portal, can comment out lines 27 and 84, and uncomment/run lines 75-76 and 83
global box "C:\Users\ekgut\Box\Metrics_2024_round\Student_Poverty_MEPS\"

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
*merge 1:1 year ncessch using "raw\ccd_meps_2014-${year}.dta" // 9_13_23 using .dta file C:\Users\ekgut\Box\Metrics_2024_round\Student_Poverty_MEPS\Abrv Set of Portal Variables
merge 1:1 year ncessch using "${box}Abrv Set of Portal Variables"
tab year _merge
drop if year==2013
drop _merge

save "intermediate/combined_2014-${year}.dta", replace

** county-level rates **
use "intermediate/combined_2014-${year}.dta", clear

drop if missing(enrollment) | enrollment==0

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

numlabel, add
replace county_code=. if county_code==-2
_strip_labels county_code
tostring county_code, replace // EG: 112 county codes observations have county_code==-2 [not applicable] (2015), 331 missing (2014/2015)
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
drop if county_code=="." // get rid of those missing county information
assert strlen(county)==3

collapse (sum) enrollment enrollment1 enrollment2 enrollment3  numerator*, by(year state county)

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


keep year state county meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
order year state county meps20_total meps20_total_quality ///
meps20_white meps20_white_quality meps20_black meps20_black_quality meps20_hispanic meps20_hispanic_quality
duplicates drop


merge 1:1 year state county using "Intermediate/countyfile.dta"
tab year _merge
//# To Do start here 
drop if _merge == 1 & year >= 2014 & year <= 2020 // drops territories 
drop if year > $year
drop _merge

*summary stats to see possible outliers
bysort year: sum
bysort state: sum

*missingness
tab year
tab year if missing(meps20_black)
tab year if missing(meps20_hispanic)
tab year if missing(meps20_white)
tab year if missing(meps20_total)

order year state county meps20_black* meps20_hispanic* meps20_white* meps20_total*
gsort -year state county 

drop meps20_total meps20_total_quality

foreach var in black hispanic white {
rename meps20_`var' share_meps20_`var'
rename meps20_`var'_quality share_meps20_`var'_quality
}

export delimited using "${final_data}meps_county_2020.csv", replace
/*
destring year state county, replace

save "${built_data}MEPS_2014-2020_county.dta", replace
