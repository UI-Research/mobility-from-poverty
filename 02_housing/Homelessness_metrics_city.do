** HOMELESSNESS **
** E Blom **
** 2020/08/04 **
*Updated September 2022 by E Gutierrez
*Updated February 2024 by E Gutierrez
*Creates the number and share of homeless students by city for 2020-21 & 2021-22 (2014-15 through 2019-20 completed in previous update)
	*Creates the number and share of homeless by race/ethnicity for 2020-21 & 2021-22 (recreates 2019-20 with total homeless as denominator)
*Updated December 2024 by E Gutierrez
*Creates the number and share of homeless students by city for 2014-15, 2015-16, and 2022-23 (2014-15 through 2019-20 completed in previous update)
	*Creates the number and share of homeless by race/ethnicity for 2022-23 (recreates with each total student ethnicity as denominator)

	
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global years 2014 2015 // refers to 2014-15 and 2015-16 school years - still need to add 2022-23
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

cap n mkdir "${gitfolder}\02_housing\data"
cd "${gitfolder}\02_housing\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** Import city file to edit names of city crosswalk to match city location strings in CCD school district data
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
	*replace city_name="Honolulu" if city_name=="Urban Honolulu"
	replace city_name="Boise" if city_name=="Boise City"
	*replace city_name="Indianapolis" if city_name=="Indianapolis city (balance)"
	replace city_name="Lexington" if city_name=="Lexington-Fayette"
	replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
	replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
	replace city_name="Mcallen" if city_name=="McAllen"
	replace city_name="Mckinney" if city_name=="McKinney"
	
	*changes specific to this data
	replace city_name="Port St Lucie" if city_name=="Port St. Lucie"
	replace city_name="Saint Paul" if city_name=="St. Paul"
	
	save "intermediate/cityfile.dta", replace

** Get CCD district data - total enrollment and city location & county codes**
foreach year in $years {
	clear
	educationdata using "district ccd directory ", sub(year=`year') col(year leaid county_code city_location enrollment) csv

	_strip_labels county_code
	tostring county_code, replace
	replace county_code = "0" + county_code if strlen(county_code)==4
	gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
	drop county_code

	save "intermediate/ccd_lea_`year'_city.dta", replace
}

*Download EdDataExpress Data
*https://eddataexpress.ed.gov/download/data-library
*each zip file is named differently
*2014-15 & 2015-16 are in the same file
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_1350/SY1018_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2010-18.zip", replace

*2022-23
copy

*unzip each file

	*2014
	import delimited "raw/SY1018_FS118_DG655_LEA.csv", clear
	keep if schoolyear=="2014-2015"
	gen year=2014
	save "raw/edfacts_homelessness_2014.dta", replace

	*2015
	import delimited "raw/SY1018_FS118_DG655_LEA.csv", clear
	keep if schoolyear=="2015-2016"
	gen year=2015
	save "raw/edfacts_homelessness_2015.dta", replace

	*2022


*reshape long form 
	foreach year in 2014 2015 2022 {
	use "raw/edfacts_homelessness_`year'.dta", clear
		drop schoolyear school ncesschid datagroup datadescription numerator denominator population characteristics agegrade academicsubject outcome programtype
		*these are missing because they have answers for characteristic (i.e., doubled up, etc.)
		drop if subgroup=="" | subgroup=="Children with disabilities" | subgroup=="English Learner" | subgroup=="Migratory students" | subgroup=="Unaccompanied Youth" | subgroup=="Children with one or more disabilities (IDEA)"
		
		replace subgroup="amin_an" if subgroup=="American Indian or Alaska Native" 
		replace subgroup="black" if subgroup=="Black or African American" 
		replace subgroup="hispanic" if subgroup=="Hispanic/Latino" 
		replace subgroup="white" if subgroup=="White" 
		replace subgroup="twomore" if subgroup=="Two or more races" 
		replace subgroup="nh_pi" if subgroup=="Native Hawaiian or Other Pacific Islander" 
		replace subgroup="asian" if subgroup=="Asian" 
		replace subgroup="homeless" if subgroup=="All Students in LEA" | subgroup=="All Students"
		
		reshape wide value,  i(state ncesleaid lea year) j(subgroup) string
		ren value* *
		ren ncesleaid leaid
		save "raw/eddataex_homelessness_`year'.dta", replace
	}
	
*Append eddataexpress data
clear
foreach year in $years {
	append using "raw/eddataex_homelessness_`year'.dta" 
		}

*create fips variable from nces_lea variable
	tostring leaid, replace
	replace leaid = "0"+leaid if strlen(leaid)==6
	gen fipst = substr(leaid,1,2)
*left off 12/9/2024

*Original code from Erica Blom
	** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
	** Original code replaced all suppressed data with the midpoint (1) but this does not yield numbers (for 2017) that align perfectly with this report: 
	** https://nche.ed.gov/wp-content/uploads/2020/01/Federal-Data-Summary-SY-15.16-to-17.18-Published-1.30.2020.pdf (Tables 5 and 6)
	** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **

/*
*2/8/24
Raw data is now posted on EdDataExpress instead of EdFacts. 
The data posted on EdDataExpress does not include the subgrant_status variable. 
According to EdFacts documentation, the variable is used to determine suppression information through 2018-19, 
and is therefore used in our own suppression determinations for data up through 2018-19. Starting in 2019-20, 
subgrant_status is no longer used to determine suppression information, and is therefore not necessary for this or future updates.
*/

*Destring/Create variables needed for data quality check variables 
foreach var in homeless black hispanic white twomore nh_pi asian amin_an { 
	di "`var'"
	gen supp_`var' = 1 if `var'=="S"
	replace `var'="1" if `var'=="S"
	destring `var', replace
	bysort year fipst : egen min_`var' = min(`var')
	bysort year fipst : egen count_supp_`var' = total(supp_`var')
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}

*collapsing American Indian/Alaskan Native,  two/more, Native Hawaiian/Pacific Islander, and Asian to other
egen other = rowtotal(twomore nh_pi asian amin_an) , missing

*because there are only suppressions and no true missings in other
	*we replace other==. to other==1 to mirror the other 4 race categories
	replace other = 1 if other==. 

	foreach var in other {  
		di "`var'"
		gen supp_`var' = 1 if other==1
		bysort year fipst : egen min_`var' = min(`var')
		bysort year fipst : egen count_supp_`var' = total(supp_`var')
		gen `var'_lower_ci = `var'
		replace `var'_lower_ci = 0 if supp_`var'==1
		gen `var'_upper_ci = `var'
		replace `var'_upper_ci = 2 if supp_`var'==1
		replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
	}
 
*keep variables we need 
	keep year leaid *homeless* *black* *hispanic* *white* *other* 
	tostring leaid, replace
	replace leaid = "0" + leaid if strlen(leaid)!=7
	assert strlen(leaid)==7
	save "intermediate/homelessness_all_years.dta", replace

** Using district office location to locate LEAs into cities/counties and calculate homelessness share **
use "intermediate/homelessness_all_years.dta", clear
foreach year in $years {
	merge m:1 year leaid using "intermediate/ccd_lea_`year'_city.dta", update
	drop if _merge==2 //  don't need ccd data that doesn't match eddataexpress data
	drop _merge
	}

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

*collapse to city level
collapse (sum) *homeless* *black* *hispanic* *other* *white* enrollment , by(year state city_name)

*rename variables to count/lb/ub/etc
	foreach var in homeless black white hispanic other {
	rename `var' `var'_count
	rename `var'_lower_ci `var'_count_lb
	rename `var'_upper_ci `var'_count_ub
	rename supp_`var' `var'_districts_suppress
	}

*create shares variables
	gen homeless_share = homeless_count/enrollment
	gen coverage_homeless = enroll_nonsupp_homeless/enrollment

*2/8/24 - changed the denominator from ex: enroll_black to total homelesss
	foreach var in black white hispanic other{
	gen `var'_share = `var'_count/homeless_count
	gen coverage_`var' = enroll_nonsupp_`var'/enroll_nonsupp_homeless
	}

*Quality check variables - use homeless/total
	foreach var in homeless black white hispanic other {
	gen `var'_quality_count = 1 if `var'_count_ub / `var'_count_lb <=1.05
	replace `var'_quality = 2 if `var'_count_ub / `var'_count_lb > 1.05 & `var'_count_ub / `var'_count_lb <=1.1
	replace `var'_quality = 3 if `var'_quality==. & `var'_count!=.
	}

*new as of 4/13/23 - updated 2/8/24 - in ACS-based metrics, if it was less than 30, it's set to NA
	replace homeless_quality = 3 if enrollment<30 
	
	*replace total and subgroup metrics =-1 (will be NA in string form) for homeless_count<10
	*2/8/24 subgroup enrollments are no longer the denominators - instead use total homeless counts
	foreach var in homeless black white hispanic other {
	replace `var'_count=-1  if homeless_count<10 // it's fine that this will catch all the -1's from now on
	replace `var'_count_lb=-1 if homeless_count<10
	replace `var'_count_ub=-1 if homeless_count<10
	replace `var'_share=-1 if homeless_count<10
	*replace subgroup quality flag=-1 (NA) for homeless_count<10
	replace `var'_quality=-1 if homeless_count<10
	*replace subgroup quality flag =3 if homeless_count 10-29
	replace `var'_quality=3 if homeless_count>=10 & homeless_count<30 
	}
	
	*foreach subgroup and total homeless metric, set all = -1 (NA) if share>1 
	*2/8/24 - in future, reconsider to look at lower and upper bounds and change quality variables instead of just setting to NA
	foreach var in homeless black white hispanic other {
	replace `var'_count=-1  if `var'_share>1 & `var'_share!=.
	replace `var'_count_lb=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_count_ub=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_share=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_quality=-1 if `var'_share>1 & `var'_share!=.
	}
	
*new as of 3/4/2024
		*When the subgroup summed total is <70% or >110% of total homeless, replace with -1 or N/A
		*create a variable set to . instead of -1 so we can sum & find the share of subgroup out of total homeless
		*we have to do this now bc we want it based on the -1s/NAs we changed in the section above
		foreach var in black_count white_count hispanic_count other_count {
		gen `var'_missing = `var'
		replace `var'_missing=. if `var'==-1
		}
		*create variable to tell us the percent of reported race subgroups of total homeless
		egen total_race = rowtotal(black_count_missing white_count_missing hispanic_count_missing other_count_missing)
		gen share_race_total = (total_race/homeless_count)*100
		replace share_race_total =. if black_count_missing==. // because of the code above, black is the same as all other race missings
		
		*replace all with -1/NA when they are <70% & >110%
		foreach var in black white hispanic other {
		replace `var'_count=-1 if (share_race_total<70 | share_race_total>110) & share_race_total!=.
		replace `var'_count_lb=-1 if (share_race_total<70 | share_race_total>110) & share_race_total!=.
		replace `var'_count_ub=-1 if (share_race_total<70 | share_race_total>110) & share_race_total!=.
		replace `var'_share=-1 if (share_race_total<70 | share_race_total>110) & share_race_total!=.
		replace `var'_quality=-1 if (share_race_total<70 | share_race_total>110) & share_race_total!=.
		}

		*for cell sizes <=2, set all variables to N/A
		foreach var in homeless black white hispanic other {
		replace `var'_count_lb=-1 if `var'_count<=2
		replace `var'_count_ub=-1 if `var'_count<=2
		replace `var'_share=-1 if `var'_count<=2
		replace `var'_quality=-1 if `var'_count<=2
		
		replace `var'_count=-1 if `var'_count<=2
		}
		
*check quality
sum coverage*, d, if homeless_quality==1
sum coverage*, d, if homeless_quality==2
sum coverage*, d, if homeless_quality==3

drop enrollment coverage* enroll_* *_districts_suppress min_* count_supp_* *_missing total_race 

order year state city_name *homeless* black* hispanic* other* white*

gsort -year state city_name

merge 1:1 year state city_name using "intermediate/cityfile.dta"
tab year _merge
	*drop cities that don't merge to the urban-provided file
	drop if _merge==1
	keep if year>=2019 & year<=2021 // only updating 2019-2021 years
	drop _merge 

*summary stats to see possible outliers
bysort year: sum
bysort state: sum

tab year // total of 486 cities possible
tab year if homeless_count==.
* 2019:56/486 2020:54/486 2021:53/486

*check for race/ethnicity 
		sum share_race_total, detail
		sum share_race_total if black_count!=-1, detail
		gen missing = 0
		replace missing = 1 if share_race_total==.
		tab year missing, row
	
drop city_name state_name share_race_total missing

order year state place
gsort -year state place

*data quality check 
gen check1 = 1 if homeless_count<homeless_count_lb
gen check2 = 1 if homeless_count>homeless_count_ub
tab check1, m
tab check2, m 
drop check*

**new as of 4/13/23
	*string variables, and replace -1 with NA & . with blank	
	*tostring the rest of the variables
	tostring *share, replace force
	tostring *count* *share *quality*, replace

foreach group in homeless black white hispanic other {
	foreach var in count count_lb count_ub quality share {
	replace `group'_`var' = "NA" if  `group'_`var'=="-1"
	replace `group'_`var' = "" if  `group'_`var'=="."
	}
	}

/*2/8/24 create share quality variable - 
right now it is equal to the quality count variable since both refer to the quality of the numerator 
*/
foreach var in homeless black white hispanic other {
	gen `var'_quality_share = `var'_quality_count
}

*save "all" or total homeless data separately
preserve
*2/8/24 - rename variables
foreach var in homeless  {
	ren `var'_count count_`var'
	ren `var'_share share_`var'
	ren `var'_count_lb count_`var'_lb
	ren `var'_count_ub count_`var'_ub
	ren `var'_quality_count count_`var'_quality
	ren `var'_quality_share share_`var'_quality
}
keep year state place count_homeless count_homeless_lb count_homeless_ub share_homeless count_homeless_quality share_homeless_quality
*2019 was already calculated, 2020-21 and 2021-22 are the new data
keep if year==2020 | year==2021
export delimited using "final/homelessness_2020_21_city.csv", replace
restore

*rename variables for reshape
rename *homeless* *all*
rename all_* *All
rename black_* *Black
rename hispanic_* *Hispanic
rename other_* *Other
rename white_* *White

reshape long count count_lb count_ub share quality_count quality_share, i(year state place) j(subgroup) string

*reshape clean
	gen subgroup_type = ""
	replace subgroup_type = "all" if subgroup=="All"
	replace subgroup_type = "race-ethnicity" if subgroup!="All"

	order year state place subgroup_type subgroup
	gsort -year state place subgroup_type subgroup 

	replace subgroup = "Black, Non-Hispanic" if subgroup=="Black"
	replace subgroup = "White, Non-Hispanic" if subgroup=="White"
	replace subgroup = "Other Races and Ethnicities" if subgroup=="Other"
	rename count count_homeless
	rename share share_homeless
	rename count_lb count_homeless_lb
	rename count_ub count_homeless_ub
	rename quality_share share_homeless_quality
	rename quality_count count_homeless_quality

*even though this metric exists for 2019, we recalulated the shares by changing the denominator
*therefore this is the full 2019-20 through 2021-22 subgroup data
export delimited using "final/homelessness_all_subgroups_city.csv", replace 
