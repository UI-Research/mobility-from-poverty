** HOMELESSNESS **
** E Blom **
** 2020/08/04 **
*Updated September 2022 by Emily Gutierrez
*Creates the number and share of homeless students by city for 2014-15 through 2019-20
	*Creates the number and share of homeless by race/ethnicity for 2019-20



clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global years 2014 2015 2016 2017 2018 2019 // refers to 2019-20 school year - most recent data
global raceyears 2019 // enrollment by race data starts in 2019-20
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"


cap n mkdir "${gitfolder}\02_housing\data"
cd "${gitfolder}\02_housing\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")


** Import city file **
import delimited ${cityfile}, clear

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
	*replace city_name="Lees Summit" if city_name=="Lee's Summit"
	*replace city_name="Ofallon" if city_name=="O'Fallon"
	replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
	replace city_name="Mcallen" if city_name=="McAllen"
	replace city_name="Mckinney" if city_name=="McKinney"
	
	*changes specific to this data
	replace city_name="Port St Lucie" if city_name=="Port St. Lucie"
	replace city_name="Saint Paul" if city_name=="St. Paul"
	*replace city_name="Las Vegas" if city_name=="North Las Vegas"
	*replace city_name="Charleston" if city_name=="North Charleston"
	
	save "intermediate/cityfile.dta", replace


** Get CCD district data - total enrollment and county_codes**
foreach year in $years {
	educationdata using "district ccd directory ", sub(year=`year') col(year leaid county_code city_location enrollment)  clear

	_strip_labels county_code
	tostring county_code, replace
	replace county_code = "0" + county_code if strlen(county_code)==4
	gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
	*gen county = substr(county_code,3,5)
	*drop if strlen(county)!=3
	drop county_code

	save "intermediate/ccd_lea_`year'_city.dta", replace
}

** Get CCD district data - enrollment by race** data availability starts in 2019-20

foreach year in $raceyears {
	educationdata using "district ccd enrollment race ", sub(year=`year' grade==99) col(year leaid grade enrollment race sex) csv clear
	drop sex grade
	collapse (sum) enrollment, by(race leaid year)
	reshape wide enrollment, i(leaid year) j(race)
	rename enrollment1 enroll_white
	rename enrollment2 enroll_black
	rename enrollment3 enroll_hispanic
	rename enrollment4 enroll_asian
	rename enrollment5 enroll_amin_na
	rename enrollment6 enroll_nh_pi
	rename enrollment7 enroll_twomore
	rename enrollment9 enroll_unknown
	drop enrollment99 
	egen enroll_other = rowtotal(enroll_twomore enroll_nh_pi enroll_asian enroll_amin_na enroll_unknown) 
	drop enroll_twomore enroll_nh_pi enroll_asian enroll_amin_na enroll_unknown 
	
	save "intermediate/ccd_lea_race_`year'.dta", replace
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
	if year<2019 {
	rename total homeless
	}
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
	ren student_countTOTAL homeless
	save "raw/edfacts_homelessness_2019wide.dta", replace

** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
** Oiginal code replaced all suppressed data with the midpoint (1) but this does not yield numbers (for 2017) that align perfectly with this report: 
** https://nche.ed.gov/wp-content/uploads/2020/01/Federal-Data-Summary-SY-15.16-to-17.18-Published-1.30.2020.pdf (Tables 5 and 6)
** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **

*Append edfacts data
clear
foreach year in $years {
	if `year'<2019 {
		append using "raw/edfacts_homelessness_`year'.dta" 
		}
		else {
	append using "raw/edfacts_homelessness_`year'wide.dta" 
	}
	}
	
*Destring/Create variables needed for data quality check variables 
foreach var in homeless black hispanic white twomore nh_pi asian amin_an { // 
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

*collapsing American Indian/Alaskan Native,  two/more, Native Hawaiian/Pacific Islander, and Asian to other
egen other = rowtotal(twomore nh_pi asian amin_an) , missing

*because there are only suppressions and no true missings in other
	*we replace other==. to other==1 to mirror lines 171 in the other 4 race categories
	replace other = 1 if other==. & year==2019

foreach var in other { // 
	di "`var'"
	gen supp_`var' = 1 if other==1
	*replace `var'="1" if `var'=="S"
	*destring `var', replace
	bysort year fipst subgrant_status: egen min_`var' = min(`var')
	bysort year fipst subgrant_status: egen count_supp_`var' = total(supp_`var')
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}
 
keep year leaid *homeless* *black* *hispanic* *white* *other* 
tostring leaid, replace
replace leaid = "0" + leaid if strlen(leaid)!=7
assert strlen(leaid)==7

save "intermediate/homelessness_all_years.dta", replace


** Using district office location to locate LEAs into counties and calculate homelessness share **
use "intermediate/homelessness_all_years.dta", clear
foreach year in $years {
	merge m:1 year leaid using "intermediate/ccd_lea_`year'_city.dta", update
	drop if _merge==2
	drop _merge
	}
*add 2019's enrollment data	
	merge m:1 year leaid using "intermediate/ccd_lea_race_2019.dta", update
	drop if _merge==2
	drop _merge

*replaces missing enrollments with zeros
replace enrollment=0 if enrollment<0 | enrollment==.

foreach var in homeless black white hispanic other {
replace `var'=0 if enrollment==0
replace `var'_upper_ci=0 if enrollment==0
replace `var'_lower_ci=0 if enrollment==0
replace supp_`var'=0 if enrollment==0
}

foreach var in homeless black white hispanic other {
gen enroll_nonsupp_`var' = enrollment if supp_`var'!=1
gen enroll_supp_`var' = enrollment if supp_`var'==1
}

*city_location is all caps for some observations. Fixing here
gen city_name=lower(city_location)
replace city_name = proper(city_name)

collapse (sum) *homeless* *black* *hispanic* *other* *white* enrollment , by(year state city_name)

foreach var in homeless black white hispanic other {
rename `var' `var'_count
rename `var'_lower_ci `var'_count_lb
rename `var'_upper_ci `var'_count_ub
rename supp_`var' `var'_districts_suppress
}

*create shares variables
gen homeless_share = homeless_count/enrollment
gen coverage_homeless = enroll_nonsupp_homeless/enrollment


foreach var in black white hispanic other{
gen `var'_share = `var'_count/enroll_`var'
gen coverage_`var' = enroll_nonsupp_`var'/enroll_`var'
}

*Quality check variables - use homeless/total
foreach var in homeless black white hispanic other {
gen `var'_quality = 1 if `var'_count_ub / `var'_count_lb <=1.05
replace `var'_quality = 2 if `var'_count_ub / `var'_count_lb > 1.05 & `var'_count_ub / `var'_count_lb <=1.1
replace `var'_quality = 3 if `var'_quality==. & `var'_count!=.
}

sum coverage*, d, if homeless_quality==1
sum coverage*, d, if homeless_quality==2
sum coverage*, d, if homeless_quality==3

foreach var in homeless black white hispanic other {
drop `var'_districts_suppress
}
drop enrollment coverage* enroll_*

*these variables are not in the 2014/2018 data
drop min_* count_supp_* 
order year state city_name *homeless* black* hispanic* other* white*

gsort -year state city_name

*race/ethnicity variables missing before 2019
foreach var in ///
black_count black_count_lb black_count_ub black_share black_quality ///
white_count white_count_lb white_count_ub white_share white_quality ///
hispanic_count hispanic_count_lb hispanic_count_ub hispanic_share hispanic_quality ///
other_count other_count_lb other_count_ub other_share other_quality ///
 {
replace `var' = . if year<2019
}

keep if year>=2016
merge 1:1 year state city_name using "intermediate/cityfile.dta"
drop if year==2020
tab year _merge
	*those that didn't merge from the city data - they just don't exist in the EdFacts data
	drop if _merge==1 
	drop _merge 

*summary stats to see possible outliers
bysort year: sum
bysort state: sum

tab year // total of 486 cities possible
tab year if homeless_count==.
* 2016: 57/485, 2017:58/485, 2018:55/486, 2019:55/486

drop city_name state_name

order year state place
gsort -year state place

*save "all" separately
preserve
keep year state place homeless_count homeless_count_lb homeless_count_ub homeless_share homeless_quality
export delimited using "built/homelessness_all_city.csv", replace
restore

rename homeless* all*

rename all_* *All
rename black_* *Black
rename hispanic_* *Hispanic
rename other_* *Other
rename white_* *White

reshape long count count_lb count_ub share quality, i(year state place) j(subgroup) string

gen subgroup_type = ""
replace subgroup_type = "all" if subgroup=="All"
replace subgroup_type = "race-ethnicity" if subgroup!="All"

order year state place subgroup_type subgroup
gsort -year state place subgroup_type subgroup 

replace subgroup = "Black, Non-Hispanic" if subgroup=="Black"
replace subgroup = "White, Non-Hispanic" if subgroup=="White"
replace subgroup = "Other Races and Ethnicities" if subgroup=="Other"
rename count homeless_count
rename count_lb homeless_count_lb
rename count_ub homeless_count_ub
rename share homeless_share
rename quality homeless_quality

*data quality check 
gen check1 = 1 if homeless_count<homeless_count_lb
gen check2 = 1 if homeless_count>homeless_count_ub
bysort subgroup: tab check1, m
bysort subgroup: tab check2, m

export delimited using "built/homelessness_all_subgroups_city.csv", replace 
