** FREE AND REDUCED PRICE LUNCH: the share of students attending schools where 40% or more students receive FRPL **
** E Blom ** Updated by E Gutierez
** 2022/08/08 **
** Instructions: only lines 8-10 need to be edited for the latest year of data **
*Makes city level estimates by aggregating school data to the city location of the school

clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global year=2020

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** get CCD enrollment **
*add if, else command once decide how to deal with future iterations
educationdata using "school ccd enrollment race", sub(year=2014:${year}) csv clear
save "raw\ccd_enr_2014-${year}.dta", replace

keep if grade==99 & sex==99
drop leaid ncessch_num grade sex fips
reshape wide enrollment, i(year ncessch) j(race)
save "intermediate\ccd_enr_2014-${year}_wide.dta", replace


** get CCD directory data **
educationdata using "school ccd directory", sub(year=2014:${year}) csv clear
save "raw\ccd_dir_2014-${year}.dta", replace

merge 1:1 year ncessch using "intermediate\ccd_enr_2014-${year}_wide.dta"

save "intermediate/combined_2014-${year}.dta", replace


** city-level rates **
use "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty\08_education\data\intermediate/combined_2014-${year}.dta", clear

drop if enrollment==. | enrollment==0

** CAUTION: SEVERAL STATES DO NOT REPORT FRPL **
	*there are also -3 suppressed, -2 N/A, and -1 missing, not just "." in years prior to 2018
	*also free/red == 0 generally means not reported - ask kristin
gen no_frpl = free_or_reduced==.
gen no_dc = direct_cert==.

tab fips no_frpl, row nofreq rowsort
tab fips no_dc, row nofreq rowsort

tab fips no_frpl, row nofreq rowsort, if ~(no_dc==1 & no_frpl==1) // for footnotes
tab fips no_dc, row nofreq rowsort, if ~(no_dc==1 & no_frpl==1)

gen frpl_used = max(free_or_reduced, direct_cert) == free_or_reduced
gen dc_used = max(free_or_reduced, direct_cert) == direct_cert & max(free_or_reduced, direct_cert) != free_or_reduced

gen frpl_share = max(free_or_reduced, direct_cert) / enrollment
gen frpl_40 = (frpl_share>=0.40) if frpl_share!=.
replace frpl_40 = 0 if frpl_share==.

gen numerator = enrollment
replace numerator = 0 if frpl_40 == 0

forvalues i=1/3 {
	gen numerator`i' = enrollment`i'
	replace numerator`i' = 0 if frpl_40 == 0
} 
/*
_strip_labels county_code
tostring county_code, replace
replace county_code = "0" + county_code if strlen(county_code)==4
gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
gen county = substr(county_code,3,5)
assert strlen(county)==3
*/
collapse (sum) enrollment enrollment1 enrollment2 enrollment3 numerator* frpl_used dc_used, by(year fips city_location)

gen frpl40_total = numerator/enrollment
gen frpl40_white = numerator1/enrollment1
gen frpl40_black = numerator2/enrollment2
gen frpl40_hispanic = numerator3/enrollment3

gen poverty_measure_used = "FRPL" if frpl_used>0 & frpl_used!=. & dc_used==0
replace poverty_measure_used = "DC" if frpl_used==0 & dc_used>0 & dc_used!=.
replace poverty_measure_used = "Both" if frpl_used>0 & frpl_used!=. & dc_used>0 & dc_used!=.

*is "Both" supposed to be a bad thing and that's why its in the below code?
gen frpl40_total_quality = 1 if enrollment>=30 & poverty_measure_used!="Both" & frpl40_total!=.
replace frpl40_total_quality = 2 if enrollment>=15 & poverty_measure_used!="Both" & frpl40_total_quality==. & frpl40_total!=.
replace frpl40_total_quality = 3 if frpl40_total_quality==. & frpl40_total!=.

gen frpl40_white_quality = 1 if enrollment1>=30 & poverty_measure_used!="Both" & frpl40_white!=.
replace frpl40_white_quality = 2 if enrollment1>=15 & poverty_measure_used!="Both" & frpl40_white_quality==. & frpl40_white!=.
replace frpl40_white_quality = 3 if frpl40_white_quality==. & frpl40_white!=.

gen frpl40_black_quality = 1 if enrollment2>=30 & poverty_measure_used!="Both" & frpl40_black!=.
replace frpl40_black_quality = 2 if enrollment2>=15 & poverty_measure_used!="Both" & frpl40_black_quality==. & frpl40_black!=.
replace frpl40_black_quality = 3 if frpl40_black_quality==. & frpl40_black!=.

gen frpl40_hispanic_quality = 1 if enrollment3>=30 & poverty_measure_used!="Both" & frpl40_hispanic!=.
replace frpl40_hispanic_quality = 2 if enrollment3>=15 & poverty_measure_used!="Both" & frpl40_hispanic_quality==. & frpl40_hispanic!=.
replace frpl40_hispanic_quality = 3 if frpl40_hispanic_quality==. & frpl40_hispanic!=.

drop enrollment* numerator* frpl_used dc_used

keep year fips city_location frpl40_total poverty_measure_used frpl40_total_quality ///
frpl40_white frpl40_white_quality frpl40_black frpl40_black_quality frpl40_hispanic frpl40_hispanic_quality
order year fips city_location frpl40_total poverty_measure_used frpl40_total_quality ///
frpl40_white frpl40_white_quality frpl40_black frpl40_black_quality frpl40_hispanic frpl40_hispanic_quality
duplicates drop

/*
merge 1:1 year state county using "Intermediate/countyfile.dta"
drop if _merge==1 // drops territories
drop _merge
*/
*keep if year==$year

gsort -year fips city_location

export delimited using "built/FRPL_city.csv", replace
*export delimited using "${boxfolder}/FRPL.csv", replace
export delimited using "${gitfolder}\08_education\FRPL_city.csv", replace


/* Suggest removing footnotes since replaced with flags.
Footnotes for 2018: 
Partial FRPL, partial DC: Ohio, Alaska
Other states with <1% reporting DC instead of FRPL: Pennsylviana, Indiana, Arizona, Alabama, West Virginia
States with 100% DC: Massachusetts, Tennessee, DC, Delaware
*/

