** HOMELESSNESS **
** E Blom **
** 2020/08/04 **
*Updated 9/6/22 by Emily Gutierrez


clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
*global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Housing"
global years 2014 2015 2016 2017 2018 2019 // refers to 2019-20 school year - most recent data

global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

cap n mkdir "${gitfolder}\02_housing\data"
cd "${gitfolder}\02_housing\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

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

** create additional older years **
preserve
replace year = year - 4
tempfile additionalyears
drop if year>2013 // so that there aren't duplicates after appending
save `additionalyears'
restore

append using `additionalyears'

save "intermediate/countyfile.dta", replace


** Get CCD district data **
foreach year in $years {
	educationdata using "district ccd directory", sub(year=`year') col(year leaid county_code enrollment) clear

	_strip_labels county_code
	tostring county_code, replace
	replace county_code = "0" + county_code if strlen(county_code)==4
	gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
	gen county = substr(county_code,3,5)
	drop if strlen(county)!=3
	drop county_code

	save "intermediate/ccd_lea_`year'.dta", replace
}


** Download EDFacts data **
*https://www2.ed.gov/about/inits/ed/edfacts/data-files/school-status-data.html
foreach year in $years {
	local nextyear = `year' - 2000 + 1
	if `year'== 2018 copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'-wide.csv" "raw/EDFacts Homelessness `year'.csv", replace
	if `year'< 2018  copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'.csv" "raw/EDFacts Homelessness `year'.csv", replace
	if `year'== 2019  copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'-long.csv" "raw/EDFacts Homelessness `year'.csv", replace

	import delimited "raw/EDFacts Homelessness `year'.csv", clear
	gen year = `year'
	save "raw/edfacts_homelessness_`year'.dta", replace
}

*EG: 2019 is only available in long form - reshape below
use "raw/edfacts_homelessness_2019.dta", clear
drop school_year_text data_group_id category subgrant_status prek_flag date_cur
*drop because variable name too long for reshape and don't need later
drop if cat_abbrv=="SHELTERED_TRANSITIONAL_HOUSING"
reshape wide student_count,  i(year stnam fipst leaid st_leaid leanm) j(cat_abbrv) string
*rename to match other years' variables
ren student_countAM7 amin_an
ren student_countBL7 black
ren student_countHI7 hispanic
ren student_countWH7 white
ren student_countMU7 twomore
ren student_countPI7 nh_pi
ren student_countAS7 asian
ren student_countTOTAL total
save "raw/edfacts_homelessness_2019wide.dta", replace

** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
** Oiginal code replaced all suppressed data with the midpoint (1) but this does not yield numbers (for 2017) that align perfectly with this report: 
** https://nche.ed.gov/wp-content/uploads/2020/01/Federal-Data-Summary-SY-15.16-to-17.18-Published-1.30.2020.pdf (Tables 5 and 6)
** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **

clear
foreach year in $years {
	if `year'<2019 {
		append using "raw/edfacts_homelessness_`year'.dta" 
		}
		else {
	append using "raw/edfacts_homelessness_`year'wide.dta" 
	}
	}
	
rename total homeless

*extra variables only for homeless/total for data quality variables
foreach var in homeless  { // 
	di "`var'"
	gen supp_`var' = 1 if `var'=="S"
	replace `var'="1" if `var'=="S"
	destring `var', replace
	bysort year fipst subgrant_status: egen min_`var' = min(`var')
	bysort year fipst subgrant_status: egen count_supp_`var' = total(supp_`var')
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}

*create flag for race/ethnicity variables
foreach var in black hispanic white twomore nh_pi asian amin_an  { // 
	di "`var'"
	replace `var'="1" if `var'=="S"
	destring `var', replace
}

*collapsing American Indian/Alaskan Native,  two/more, Native Hawaiian/Pacific Islander, and Asian to other
egen other = rowtotal(twomore nh_pi asian amin_an) 
drop twomore nh_pi asian amin_an 
 
keep year leaid *homeless* black hispanic white other 
tostring leaid, replace
replace leaid = "0" + leaid if strlen(leaid)!=7
assert strlen(leaid)==7

save "intermediate/homelessness_all_years.dta", replace


** Using district office location to locate LEAs into counties and calculate homelessness share **
use "intermediate/homelessness_all_years.dta", clear
foreach year in $years {
	merge m:1 year leaid using "intermediate/ccd_lea_`year'.dta", update
	drop if _merge==2
	drop _merge
}

*replaces missing enrollments with zeros
replace enrollment=0 if enrollment<0 | enrollment==.

foreach var in homeless {
replace `var'=0 if enrollment==0
replace `var'_upper_ci=0 if enrollment==0
replace `var'_lower_ci=0 if enrollment==0
replace supp_`var'=0 if enrollment==0
}

*EG: since this refers to homeless as total and enrollment, I think this doesn't need the subgroups
gen enroll_nonsupp = enrollment if supp_homeless!=1
gen enroll_supp = enrollment if supp_homeless==1

collapse (sum) *homeless* black hispanic other white enrollment enroll_nonsupp enroll_supp, by(year state county)

foreach var in homeless  {
rename `var' `var'_count
rename `var'_lower_ci `var'_count_lb
rename `var'_upper_ci `var'_count_ub
rename supp_`var' `var'_districts_suppress
gen `var'_share = `var'_count/enrollment
}

foreach var in black white hispanic other {
rename `var' `var'_count 
gen `var'_share = `var'_count/enrollment //This uses total enrollment, i think it should be among homeless? ***************************************************
}

*Quality check variables - use homeless/total
gen coverage = enroll_nonsupp/enrollment
gen homeless_quality = 1 if homeless_count_ub / homeless_count_lb <=1.05
replace homeless_quality = 2 if homeless_count_ub / homeless_count_lb > 1.05 & homeless_count_ub / homeless_count_lb <=1.1
replace homeless_quality = 3 if homeless_quality==. & homeless_count!=.

sum coverage, d, if homeless_quality==1
sum coverage, d, if homeless_quality==2
sum coverage, d, if homeless_quality==3

foreach var in homeless {
drop `var'_districts_suppress
}
drop enrollment coverage enroll_supp enroll_nonsupp

*EG:changes for 20154 - this was part of the original code, not sure why its here
replace county="102" if state=="46" & county=="113"

merge 1:1 year state county using "intermediate/countyfile.dta"
tab year _merge 
drop if _merge==1 // Puerto Rico

bysort year: egen maxmerge=max(_merge)
keep if maxmerge==3
drop _merge maxmerge

*these variables are not in the 2014/2018 data
drop min_homeless count_supp_homeless

order year state county *homeless* black* hispanic* other* white*

gsort -year state county

*race/ethnicity variables missing before 2019
foreach var in black hispanic other white {
replace `var' = . if year<2019
}

export delimited using "built/homelessness_all.csv", replace // EG: 2014 & 2018 match old data, but there are some variables 
*export delimited using "${gitfolder}\02_housing\homelessness_all.csv", replace
*export delimited using "${boxfolder}/homelessness_all.csv", replace
