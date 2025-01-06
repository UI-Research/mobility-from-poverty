** HOMELESSNESS **
** E Blom **
** 2020/08/04 **
	*Original code from E Blom
	** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
	** Original code replaced all suppressed data with the midpoint (1) but this does not yield numbers (for 2017) that align perfectly with this report: 
	** https://nche.ed.gov/wp-content/uploads/2020/01/Federal-Data-Summary-SY-15.16-to-17.18-Published-1.30.2020.pdf (Tables 5 and 6)
	** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **
*Updated September 2022 by E Gutierrez
*Updated February 2024 by E Gutierrez
	*Creates the number and share of homeless students by city for 2020-21 & 2021-22 (2014-15 through 2019-20 completed in previous update)
		*Creates the number and share of homeless by race/ethnicity for 2020-21 & 2021-22 (recreates 2019-20 with total homeless as denominator)
			/*Raw data is now posted on EdDataExpress instead of EdFacts. 
			The data posted on EdDataExpress does not include the subgrant_status variable. 
			According to EdFacts documentation, the variable is used to determine suppression information through 2018-19, 
			and is therefore used in our own suppression determinations for data up through 2018-19. Starting in 2019-20, 
			subgrant_status is no longer used to determine suppression information, and is therefore not necessary for this or future updates.*/
*Updated December 2024 by E Gutierrez
	*Creates the total number and share of homeless students by city for 2014-15 through 2018-19 (2014-2018)

**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Set up globals and directories
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global years 2014 2015 2016 2017 2018 // these refer to the fall of the school i.e. 2014 = 2014-15
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

cap n mkdir "${gitfolder}\02_housing\data"
cd "${gitfolder}\02_housing\data"

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
	replace city_name="Boise" if city_name=="Boise City"
	replace city_name="Lexington" if city_name=="Lexington-Fayette"
	replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
	replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
	replace city_name="Mcallen" if city_name=="McAllen"
	replace city_name="Mckinney" if city_name=="McKinney"
	
*duplicate 2015 to create 2014 place
	expand 2 if year==2015
	bysort year state place state_name city_name: gen obs=_n
	replace year = 2014 if obs==2
	drop obs
	sort year state place state_name city_name
	
	save "intermediate/cityfile.dta", replace // gitignore

*****************************
*****CCD District Data*******
*****************************
** Download CCD district data from Urban's Education Data Portal - total enrollment, city location, & county codes**
foreach year in $years {
	clear
	educationdata using "district ccd directory ", sub(year=`year') col(year leaid county_code city_location enrollment) csv

	_strip_labels county_code
	tostring county_code, replace
	replace county_code = "0" + county_code if strlen(county_code)==4
	gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
	drop county_code

	save "intermediate/ccd_lea_`year'_city.dta", replace // gitignore
}
*Append 
clear
use "intermediate/ccd_lea_2014_city.dta"
forvalues year == 2015/2018 {
	append using "intermediate/ccd_lea_`year'_city.dta" 
		} 
	save "intermediate/ccd_lea_2014-2018_city.dta", replace // gitignore

****************************
*Download EdDataExpress Data
****************************
*https://eddataexpress.ed.gov/download/data-library
*each zip file is named differently, but use Level: "LEA" & "Data Group": 655
*2014-15, 2015-16, 2016-17, 2017-18 are in the same file
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_1350/SY1018_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2010-17.zip", replace
	*unzip
	cd "${gitfolder}\02_housing\data\raw"
	unzipfile "EdDataEx Homelessness 2010-17.zip", replace
	cd "${gitfolder}\02_housing\data"
	
*2018-19
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_2111/SY1819_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2018-19.zip", replace
	*unzip
	cd "${gitfolder}\02_housing\data\raw"
	unzipfile "EdDataEx Homelessness 2018-19.zip", replace
	cd "${gitfolder}\02_housing\data"
	
*2014-2017
	import delimited "raw/SY1018_FS118_DG655_LEA.csv", clear
	gen year=2014 if schoolyear=="2014-2015"
	replace year=2015 if schoolyear=="2015-2016"
	replace year=2016 if schoolyear=="2016-2017"
	replace year=2017 if schoolyear=="2017-2018"
	keep if year!=.
	save "raw/edfacts_homelessness_2014-2017.dta", replace // gitignore

*2018	
	import delimited "raw/SY1819_FS118_DG655_LEA.csv", clear
	gen year=2018 
	append using "raw/edfacts_homelessness_2014-2017.dta"
	
**********************************
*Clean EdDataExporess Student Data
**********************************
*reshape from long form to wide form
	drop schoolyear school ncesschid datagroup datadescription numerator denominator population characteristics agegrade academicsubject outcome programtype
	*subgroup== missing because they have answers for characteristic (i.e., doubled up, etc.)
	drop if subgroup=="" | subgroup=="Children with disabilities" | subgroup=="English Learner" | subgroup=="Migratory students" | subgroup=="Unaccompanied Youth" | subgroup=="Children with one or more disabilities (IDEA)"
	replace subgroup="homeless" if subgroup=="All Students in LEA" | subgroup=="All Students"
	reshape wide value,  i(state ncesleaid lea year) j(subgroup) string
	ren value* *
	ren ncesleaid leaid
	
*create fips variable from nces_lea variable
	tostring leaid, replace
	replace leaid = "0"+leaid if strlen(leaid)==6
	gen fipst = substr(leaid,1,2)

*create/interpret suppressed variables
	*suppressed observations have between 1 or 2 students, replacing here with 1 so that when aggregated to the city level, we have the best estimate
foreach var in homeless { 
	di "`var'"
	*create variable indicating if originally suppressed
	gen supp_`var' = 1 if `var'=="S"
	*replace the original variable with 1 if it originally was suppressed
	replace `var'="1" if `var'=="S"
	destring `var', replace
	*create the minimum value for suppressed data by state and year
	bysort year fipst : egen min_`var' = min(`var')
	bysort year fipst : egen count_supp_`var' = total(supp_`var')
	*create lower confidence interval
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	*create upper confidence interval
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}

*keep variables we need 
	keep year leaid *homeless* 
	tostring leaid, replace
	replace leaid = "0" + leaid if strlen(leaid)!=7
	assert strlen(leaid)==7

** Using district office location to locate LEAs into cities/counties and calculate homelessness share **
	merge m:1 year leaid using "intermediate/ccd_lea_2014-2018_city.dta", update
	drop if _merge==2 //  don't need ccd data that doesn't match eddataexpress data
	drop _merge
	
*replaces missing enrollments with zeros
	replace enrollment=0 if enrollment<0 | enrollment==.
	foreach var in homeless {
	replace `var'=0 if enrollment==0
	replace `var'_upper_ci=0 if enrollment==0
	replace `var'_lower_ci=0 if enrollment==0
	replace supp_`var'=0 if enrollment==0
	}

*enrollment variables based on suppression	
	foreach var in homeless {
	gen enroll_nonsupp_`var' = enrollment if supp_`var'!=1
	gen enroll_supp_`var' = enrollment if supp_`var'==1
	}

*city_location is all caps for some observations
	gen city_name=lower(city_location)
	replace city_name = proper(city_name)

*collapse to city level
	collapse (sum) *homeless* enrollment, by(year state city_name)

*rename variables to count/lowerbound/upperbound/etc
	foreach var in homeless  {
	rename `var' `var'_count
	rename `var'_lower_ci `var'_count_lb
	rename `var'_upper_ci `var'_count_ub
	rename supp_`var' `var'_districts_suppress
	}

*create shares variables
	gen homeless_share = homeless_count/enrollment
	gen coverage_homeless = enroll_nonsupp_homeless/enrollment

*Create quality variables with aggregated data - use homeless/total
	foreach var in homeless {
	gen `var'_quality_count = 1 if `var'_count_ub / `var'_count_lb <=1.05 // ratio of upperbound vs lowerbound is less than or equal to 1.05
	replace `var'_quality_count = 2 if `var'_count_ub / `var'_count_lb > 1.05 & `var'_count_ub / `var'_count_lb <=1.1 // ratio of upperbound vs lowerbound is between 1.05 and 1.1 than or equal to 1.05
	replace `var'_quality_count = 3 if `var'_quality==. & `var'_count!=. // if remaining counts are missing
	}
	*if aggregated enrollment is less than 30, quality of the variable is 3
	replace homeless_quality = 3 if enrollment<30 
	
*replace total homeless =-1 (NA) for homeless_count<10 
	foreach var in homeless {
	replace `var'_count=-1  if homeless_count<10 
	replace `var'_count_lb=-1 if homeless_count<10
	replace `var'_count_ub=-1 if homeless_count<10
	replace `var'_share=-1 if homeless_count<10
	replace `var'_quality=-1 if homeless_count<10
	replace `var'_quality=3 if homeless_count>=10 & homeless_count<30 
	}
	
*foreach homeless metric, set all = -1 (NA) if share>1 and isn't missing
	foreach var in homeless {
	replace `var'_count=-1  if `var'_share>1 & `var'_share!=.
	replace `var'_count_lb=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_count_ub=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_share=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_quality=-1 if `var'_share>1 & `var'_share!=.
	}
	
*for cell sizes <=2, set all variables to -1 (N/A) - reapplies suppression rules from before
	foreach var in homeless  {
	replace `var'_count_lb=-1 if `var'_count<=2
	replace `var'_count_ub=-1 if `var'_count<=2
	replace `var'_share=-1 if `var'_count<=2
	replace `var'_quality=-1 if `var'_count<=2
	replace `var'_count=-1 if `var'_count<=2
	}
		
*merge to crosswalk of places/cities
	merge 1:1 year state city_name using "intermediate/cityfile.dta"
	tab year _merge
		drop if _merge==1 // drop cities that don't merge to the crosswalk
		keep if year<=2018
		drop _merge
		
****************
*Quality Checks
****************

*check quality - how good is coverage of homeless students (based on nonsuppresion) by quality variables
	sum coverage*, d, if homeless_quality==1
	sum coverage*, d, if homeless_quality==2
	sum coverage*, d, if homeless_quality==3

drop enrollment coverage* enroll_* *_districts_suppress min_* count_supp_* 
order year state city_name *homeless* 
gsort -year state city_name
		
*summary stats to see possible outliers across years/times, comaring means and min/max values across years
	bysort year: sum // Beaumont TX in 2017 had really high share homeless (Hurricane Harvey)
	bysort state: sum

bysort year: count // total of 2014-2017:485 2018:486 cities possible
tab year if homeless_count==. // 2014:62/485 2015:62/485 2016:59/485 2017:60/485 2018:58/486

drop city_name state_name
order year state place
gsort -year state place

*data quality check - is homeless count ever less than lower bound or higher than upperbound
	gen check1 = 1 if homeless_count<homeless_count_lb
	gen check2 = 1 if homeless_count>homeless_count_ub
	assert check1==.
	assert check2==.
	drop check*

*are all quality flags missing if metric is missing
assert homeless_quality==. if homeless_share==.
assert homeless_quality==. if homeless_count==.

**************
*Visual Checks
**************
*look to see if, by homeless quality, the distributions are relatively normal
twoway histogram homeless_share, frequency by(year)
twoway histogram homeless_share  if homeless_quality==1, frequency by(year)
twoway histogram homeless_share  if homeless_quality==2, frequency by(year)
twoway histogram homeless_share  if homeless_quality==3, frequency by(year)

bysort year: assert homeless_share==-1 if homeless_quality==-1

*tostring variables, and replace -1 with NA & . with blank	
	*tostring the rest of the variables
	tostring *share, replace force
	tostring *count* *share *quality*, replace
	foreach group in homeless {
	foreach var in count count_lb count_ub quality share {
	replace `group'_`var' = "NA" if  `group'_`var'=="-1"
	replace `group'_`var' = "" if  `group'_`var'=="."
	}
	}

*rename variables
	foreach var in homeless  {
		gen `var'_quality_share = `var'_quality_count
	}
	foreach var in homeless  {
		ren `var'_count count_`var'
		ren `var'_share share_`var'
		ren `var'_count_lb count_`var'_lb
		ren `var'_count_ub count_`var'_ub
		ren `var'_quality_count count_`var'_quality
		ren `var'_quality_share share_`var'_quality
	}

keep year state place count_homeless count_homeless_lb count_homeless_ub share_homeless count_homeless_quality share_homeless_quality

export delimited using "final/homelessness_2014-2018_city.csv", replace
