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
	*Creates the total number and share of homeless students by city for 2019-20 through 2022-23 (2019-2022)
	*Alters denominator for subgroup share (race/ethnicity) from total homeless to enrolled students of that race

**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Set up globals and directories
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global years 2019 2020 2021 2022 
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

*place variable is number and needs to be a string
tostring place, replace
*after stringing, place should have 5 characters, so add leading zeros where they are missing
replace place = "0" + place if strlen(place)==4
replace place = "00" + place if strlen(place)==3
assert strlen(place)==5

*state variable is numeric and needs to be a string
tostring state, replace
*add leading zeros where needed for a string length of 2
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
** Download CCD district data from Urban's Education Data Portal - total enrollment, city location, & county codes**
foreach year in $years {
	clear
	educationdata using "district ccd directory", sub(year=`year') col(year leaid county_code city_location enrollment) csv

	_strip_labels county_code
	tostring county_code, replace
	replace county_code = "0" + county_code if strlen(county_code)==4
	gen state = substr(county_code,1,2) // "fips" in data is jurisdictional and not geographic 
	drop county_code

	save "intermediate/ccd_lea_`year'_city.dta", replace
}

*Append ccd data
clear
foreach year in $years {
	append using "intermediate/ccd_lea_`year'_city.dta"
		}
save "intermediate/ccd_lea_recent_city.dta", replace


** Download CCD district enrollment data by race from Urban's Education Data Portal**
foreach year in $years {
	clear
	educationdata using "district ccd enrollment race", sub(year=`year') col(year leaid enrollment grade race sex) csv
	numlabel, add
	drop if race==99
	keep if grade==99
	keep if sex==99
	drop grade sex
	tab race
	reshape wide enrollment, i(year leaid) j(race)
	ren enrollment1 enroll_white
	ren enrollment2 enroll_black
	ren enrollment3 enroll_hispanic
	ren enrollment4 enroll_asian
	ren enrollment5 enroll_amin_an
	ren enrollment6 enroll_nh_pi
	ren enrollment7 enroll_twomore
	egen enroll_other = rowtotal(enroll_asian enroll_amin_an enroll_nh_pi enroll_twomore), missing
	keep enroll_white enroll_black enroll_hispanic enroll_other year leaid
	save "intermediate/ccd_lea_`year'_city_race.dta", replace
}

*Append ccd data
clear
foreach year in $years {
	append using "intermediate/ccd_lea_`year'_city_race.dta"
		}
save "intermediate/ccd_lea_recent_city_race.dta", replace

*merge two ccd datasets together
	use "intermediate/ccd_lea_recent_city.dta", clear
	merge 1:1 leaid year using "intermediate/ccd_lea_recent_city_race.dta"
	tab year _merge // this is expected, as some enrollment by race data is not collected for some districts
	drop _merge
	save "intermediate/ccd_lea_recent_city_merged.dta", replace


****************************
*Download EdDataExpress Data
****************************
*https://eddataexpress.ed.gov/download/data-library
*each zip file is named differently, but use Level: "LEA" & "Data Group": 655
*2019-20
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_6526/SY1920_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2019.zip", replace
*2020-21
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_8321/SY2021_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2020.zip", replace
*2021-22
copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_11718/SY2122_FS118_DG655_LEA_data_files.zip" "raw/EdDataEx Homelessness 2021.zip", replace

*unzips to current directory
	cd "${gitfolder}\02_housing\data\raw"
	foreach year in 2019 2020 2021 {
	unzipfile "EdDataEx Homelessness `year'.zip", replace
	}
	cd "${gitfolder}\02_housing\data"

*Due to changes in EdDataExpress website, 2022-23 data must be manually downloaded. Please follow the following steps.
	*Source: https://eddataexpress.ed.gov/download/data-builder/data-download-tool?f%5B1%5D=population%3AHomeless%20Students&f%5B2%5D=school_year%3A2022-2023&f%5B0%5D=level%3ALocal%20Education%20Agency 
	*Make sure the filters are set for Homeless Students, 2022-2023, and Local Education Agency
		*If they are not, go to the left-side menu and “deselect all” of the filters (school year, population, and level)
		*Then reselect school year: 2022-2023, population: homeless students, and level: local education agency
		*Make sure data group = 655, which refers to "Homeless students enrolled"
		*Click "download data" and save to raw folder
		*This csv can be found in the Metrics_2025_round box folder

	*import csvs
	*2019
	import delimited "raw/SY1920_FS118_DG655_LEA.csv", clear
	gen year=2019
	save "raw/edfacts_homelessness_2019.dta", replace

	*2020
	import delimited "raw/SY2021_FS118_DG655_LEA.csv", clear
	gen year=2020
	save "raw/edfacts_homelessness_2020.dta", replace

	*2021
	import delimited "raw/SY2122_FS118_DG655_LEA.csv", clear
	gen year=2021
	save "raw/edfacts_homelessness_2021.dta", replace
	
	*2022
	import delimited "raw/2022-23 LEA homeless student data.csv", clear // name of 2022-23 file
	gen year=2022
	save "raw/edfacts_homelessness_2022.dta", replace

	
**********************************
*Clean EdDataExporess Student Data
**********************************
*reshape long form 
	foreach year in $years {
	use "raw/edfacts_homelessness_`year'.dta", clear
		keep if datagroup==655 // this captures the measure for homeless students enrolled, rather than 818 which refers to "young homeless children served"
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
		replace subgroup="homeless" if subgroup=="All Students in LEA" 
		
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

*create/interpret suppression variables
	*suppressed observations have between 1 or 2 students, replacing here with 1 so that when aggregated to the city level, we have the best estimate
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

	*repeat the above creation/interpretation of supression variables for the "Other" category to mirror the other race categories.
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

** Using district office location to locate LEAs into cities/counties and calculate homelessness share **
	merge 1:1 year leaid using "intermediate/ccd_lea_recent_city_merged.dta"
	drop if _merge==2 | _merge==1 //  don't need ccd data that doesn't match eddataexpress data
	drop _merge

*replaces missing enrollments with zeros
	replace enrollment=0 if enrollment<0 | enrollment==.
	foreach var in homeless black white hispanic other {
	replace `var'=0 if enrollment==0
	replace `var'_upper_ci=0 if enrollment==0
	replace `var'_lower_ci=0 if enrollment==0
	replace supp_`var'=0 if enrollment==0
	}
	
*enrollment variables based on suppression	
	foreach var in homeless black white hispanic other {
	gen enroll_nonsupp_`var' = enrollment if supp_`var'!=1
	gen enroll_supp_`var' = enrollment if supp_`var'==1
	}

*city_location is all caps for some observations
gen city_name=lower(city_location)
replace city_name = proper(city_name)

*collapse to city level
collapse (sum) *homeless* *black* *hispanic* *other* *white* enrollment , by(year state city_name)

*rename variables to count/lowerbound/upperbound/etc
	foreach var in homeless black white hispanic other {
	rename `var' `var'_count
	rename `var'_lower_ci `var'_count_lb
	rename `var'_upper_ci `var'_count_ub
	rename supp_`var' `var'_districts_suppress
	}

*create shares variables
	gen homeless_share = homeless_count/enrollment
	gen coverage_homeless = enroll_nonsupp_homeless/enrollment

*denominator changed from total homeless back to total of each race
	foreach var in black white hispanic other{
	gen `var'_share = `var'_count/enroll_`var'
	gen coverage_`var' = enroll_nonsupp_`var'/enroll_nonsupp_`var'
	}

*Create quality variables with aggregated data - use homeless/total
	foreach var in homeless black white hispanic other {
	gen `var'_quality_count = 1 if `var'_count_ub / `var'_count_lb <=1.05 // ratio of upperbound vs lowerbound is less than or equal to 1.05
	replace `var'_quality = 2 if `var'_count_ub / `var'_count_lb > 1.05 & `var'_count_ub / `var'_count_lb <=1.1 // ratio of upperbound vs lowerbound is between 1.05 and 1.1 than or equal to 1.05
	replace `var'_quality = 3 if `var'_quality==. & `var'_count!=. // if remaining counts are missing
	}
	*if aggregated enrollment is less than 30, quality of the variable is 3
	replace homeless_quality = 3 if enrollment<30 
	
*replace total homeless =-1 (NA) for homeless_count<10 
	foreach var in homeless black white hispanic other {
	replace `var'_count=-1  if homeless_count<10 
	replace `var'_count_lb=-1 if homeless_count<10
	replace `var'_count_ub=-1 if homeless_count<10
	replace `var'_share=-1 if homeless_count<10
	replace `var'_quality=-1 if homeless_count<10
	replace `var'_quality=3 if homeless_count>=10 & homeless_count<30 
	}
	
*foreach homeless metric, set all = -1 (NA) if share>1 and isn't missing
	foreach var in homeless black white hispanic other {
	replace `var'_count=-1  if `var'_share>1 & `var'_share!=.
	replace `var'_count_lb=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_count_ub=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_share=-1 if `var'_share>1 & `var'_share!=.
	replace `var'_quality=-1 if `var'_share>1 & `var'_share!=.
	}

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

	*for cell sizes <=2, set all variables to -1 (N/A) - reapplies suppression rules from before
		foreach var in homeless black white hispanic other {
		replace `var'_count_lb=-1 if `var'_count<=2
		replace `var'_count_ub=-1 if `var'_count<=2
		replace `var'_share=-1 if `var'_count<=2
		replace `var'_quality=-1 if `var'_count<=2
		replace `var'_count=-1 if `var'_count<=2
		}

*merge to crosswalk of places/cities
merge 1:1 year state city_name using "intermediate/cityfile.dta"
*the city crosswalk file inlcudes years prior to 2019, and 2023, and are not needed. 
*We matched the universe of homeless student data to the city files, leaving thousands of cities out. 
tab year _merge
	drop if _merge==1 // drop cities that don't merge to the crosswalk
	keep if year>=2019 & year<=2022 // only updating 2019-2022 years
	tab year _merge, row // we have homeless student data for almost 90 percent of cities listed in our crosswalk
	drop _merge 
		
****************
*Quality Checks
****************
		
*check quality - how good is coverage of homeless students (based on nonsuppresion) by quality variables
sum coverage*, d, if homeless_quality==1
sum coverage*, d, if homeless_quality==2
sum coverage*, d, if homeless_quality==3

drop enrollment coverage* enroll_* *_districts_suppress min_* count_supp_* *_missing total_race 
order year state city_name *homeless* black* hispanic* other* white*
gsort -year state city_name

*summary stats to see possible outliers across years/times, comaring means and min/max values across years
bysort year: sum 
bysort state: sum

bysort year: count // total of 486 cities possible
tab year if homeless_count==. // 2019:58/486 2020:56/486 2021:55/486 2022:50/486
foreach var in black white hispanic other {
tab year if `var'_count==.
}

*check for race/ethnicity 
		sum share_race_total, detail
		sum share_race_total if black_count!=-1, detail // it says black but is really if any race count is set to -1
		gen missing = 0
		replace missing = 1 if share_race_total==.
		tab year missing, row
	
drop city_name state_name share_race_total missing
order year state place
gsort -year state place

*data quality check - is homeless count ever less than lower bound or higher than upperbound
foreach var in homeless black white hispanic other {
gen check1_`var' = 1 if `var'_count<`var'_count_lb
gen check2_`var' = 1 if `var'_count>`var'_count_ub
	assert check1==.
	assert check2==.
drop check*
}

*are all quality flags missing if metric is missing
foreach var in homeless black white hispanic other {
tab `var'_quality if `var'_share==.
tab `var'_quality if `var'_count==.
}


**************
*Visual Checks
**************
*look to see if, by homeless quality, the distributions are relatively normal
twoway histogram homeless_share, frequency by(year)
twoway histogram homeless_share  if homeless_quality==1, frequency by(year)
twoway histogram homeless_share  if homeless_quality==2, frequency by(year)
twoway histogram homeless_share  if homeless_quality==3, frequency by(year)

bysort year: assert homeless_share==-1 if homeless_quality==-1

foreach var in homeless black white hispanic other {
bysort year: tab `var'_share if `var'_quality==-1
}

*tostring variables, and replace -1 with NA & . with blank	
	*tostring the rest of the variables
	tostring *share, replace force
	tostring *count* *share *quality*, replace
	
foreach group in homeless black white hispanic other {
	foreach var in count count_lb count_ub quality share {
	replace `group'_`var' = "NA" if  `group'_`var'=="-1"
	replace `group'_`var' = "NA" if  `group'_`var'=="."
	}
	}

*rename variables
foreach var in homeless black white hispanic other {
	gen `var'_quality_share = `var'_quality_count
}

*save "all" or total homeless data separately
preserve
	*rename variables
	foreach var in homeless  {
		ren `var'_count count_`var'
		ren `var'_share share_`var'
		ren `var'_count_lb count_`var'_lb
		ren `var'_count_ub count_`var'_ub
		ren `var'_quality_count count_`var'_quality
		ren `var'_quality_share share_`var'_quality
	}
	keep year state place count_homeless count_homeless_lb count_homeless_ub share_homeless count_homeless_quality share_homeless_quality
	keep if year>=2019
	gsort -year
	export delimited using "final/homelessness_2019-2022_city.csv", replace
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

export delimited using "final/homelessness_2019-2022_subgroups_city.csv", replace 
