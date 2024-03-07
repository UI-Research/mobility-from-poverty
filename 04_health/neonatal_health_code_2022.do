************************************************************************
* Ancestor program: $gitfolder/neonatal_health_code_2018.do 				   
* Original data: all_births_by_county.txt, lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder/04_health/data      				   
* Description: Program to create gates mobility metrics on neonatal health  
* Authors: Emily M. Johnston, Julia Long 												   
* Date: September 2, 2022	
* (1)  download data from CDC WONDER											
* (2)  import, clean, and merge CDC WONDER files					   
* (3)  intermediate file data cleaning										   
* (4)  use crosswalk to add missing counties to data file		
* (5)  assign "unidentified county" values to counties with missing values
* (6)  create neonatal health share lowbirthweight metric
* (7) assess data quality
* (8) construct 95 percent confidence intervals
* (9) final file cleaning and export to csv file	
* more steps that start with taking the final county file
	*sum the numerators/denoms 
	*use the same confidence interval formula. 
****************************************************************************


/*

Description: Program to Update Gates Mobility Metrics on Neonatal Health
Author: Jay Carter
Date: Feb 21, 2024

Data from CDC Wonder - Instructions in Readme
	Download data from CDC Wonder into a folder //04_health/data/
*/
clear all 
pause on 

global gitfolder "C:\Users\jcarter\Documents\git_repos\mobility-from-poverty\"	// update path as necessary to the local mobility metrics repository folder
global health "${gitfolder}04_health\"
global health_data "${health}data\"
global health_data_final "${health}final_data\"
global geo_xwalk "${gitfolder}geographic-crosswalks\data\"

global sub = "nhblack hisp nhother nhwhite"
global ed_sub "lessthanhs hsgrad somecollege collegedegrees"
global data_types = "all raceth momed"

cd "${gitfolder}"

// cap n mkdir ${health_data}
cap n mkdir ${health_data_final}

local y2 = 22
local y4 = 2000 + `y2'

//# *(1) download data from CDC WONDER

* access instructions for completing the CDC WONDER data query in README	
* data query results are saved as lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder/04_health/data 

//# *(2) open, clean, and merge CDC WONDER files

//# open and clean data: all births
//# All Low Birthweight Births
import delimited using "${health_data}lbw_births_by_county_`y2'.txt", clear

keep countyofresidence countyofresidencecode births
	
	rename countyofresidence county_name
	rename countyofresidencecode fips
	rename births lbw_births
	sort fips county_name		// count of low birthweight births
	keep if !missing(fips)
	
save "${health_data}lbw_births_by_county_`y2'.dta", replace

//# All nonmissing birth weight births
import delimited using "${health_data}nomiss_bw_by_county_`y2'.txt", clear

keep countyofresidence countyofresidencecode births	// do not need CDC notes	
	
	rename countyofresidence county_name
	rename countyofresidencecode fips
	rename births nomiss_births					// count of births with nonmissing birth weight data
	
	sort fips county_name
	keep if !missing(fips)						// only keeping observations with county data	

save "${health_data}nomiss_bw_by_county_`y2'.dta", replace


//# open and clean data: race/ethnicity
//# Low Birthweight Births - By Race
foreach sub of global sub {
	import delimited using "${health_data}lbw_births_by_county_`sub'_`y2'.txt", clear
		codebook births
		keep countyofresidence countyofresidencecode births	// do not need CDC notes	
		drop if births=="Missing County"					// only keeping observations with birth data	
			
			rename countyofresidence county_name
			rename countyofresidencecode fips
			rename births lbw_births
			
	destring lbw_births, replace force
	
	gen subgroup_type = "race-ethnicity"	
	
	sort fips county_name								// count of low birthweight births
	keep if !missing(fips)								// only keeping observations with data
save "${health_data}lbw_births_by_county_`sub'_`y2'.dta", replace
}


//# Nonmissing birth weight births - By Race
foreach sub of global sub {
	import delimited using "${health_data}nomiss_bw_by_county_`sub'_`y2'.txt", clear
		keep countyofresidence countyofresidencecode births	// do not need CDC notes	
			
			rename countyofresidence county_name
			rename countyofresidencecode fips
			rename births nomiss_births 					// count of births with nonmissing birth weight data
	
	destring nomiss_births, replace force
	
	gen subgroup_type = "race-ethnicity"	
	
	sort fips county_name
	keep if !missing(fips)								// only keeping observations with data

save "${health_data}nomiss_bw_by_county_`sub'_`y2'.dta", replace
}

//# open and clean data: mother's education
//# Low Birthweight Births - By Mother's Education

foreach ed of global ed_sub {
	import delimited using "${health_data}lbw_births_by_county_`ed'_`y2'.txt", clear
	di "`ed'"
		codebook births
		keep countyofresidence countyofresidencecode births	// do not need CDC notes
		
		cap drop if births=="Missing County"					// only keeping observations with birth data	
			
			rename countyofresidence county_name
			rename countyofresidencecode fips
			rename births lbw_births
			
	destring lbw_births, replace force
	
	gen subgroup_type = "mothers-education"	
	
	sort fips county_name								// count of low birthweight births
	keep if !missing(fips)								// only keeping observations with data
save "${health_data}lbw_births_by_county_`ed'_`y2'.dta", replace
}

//# Nonmissing birth weight births - By Mother's Education

foreach ed of global ed_sub {
	import delimited using "${health_data}nomiss_bw_by_county_`ed'_`y2'.txt", clear
		keep countyofresidence countyofresidencecode births	// do not need CDC notes	
			
			rename countyofresidence county_name
			rename countyofresidencecode fips
			rename births nomiss_births 					// count of births with nonmissing birth weight data
	
	destring nomiss_births, replace force
	
	gen subgroup_type = "mothers-education"	
	
	sort fips county_name
	keep if !missing(fips)								// only keeping observations with data

save "${health_data}nomiss_bw_by_county_`ed'_`y2'.dta", replace
}

//# Merge Files
//# merge files: All births - Merging Non-Missing Births to Low Birthweight Births 
use "${health_data}lbw_births_by_county_`y2'.dta", clear
	merge 1:1 fips county_name using "${health_data}nomiss_bw_by_county_`y2'.dta"
		tab _merge
		drop _merge
save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace

//# merge files: Race/Ethnicity - Merging Non-Missing Births to Low Birthweight Births 
foreach sub of global sub {

	di "`sub'"
	use "${health_data}lbw_births_by_county_`sub'_`y2'.dta", clear
	merge 1:1 fips county_name using "${health_data}nomiss_bw_by_county_`sub'_`y2'.dta"
		tab _merge
		drop _merge
		gen `sub' = 1
	save "${health_data}neonatal_health_intermediate_`sub'_`y2'.dta", replace
}

//# merge files: Mother's Education  - Merging Non-Missing Births to Low Birthweight Births 
foreach ed of global ed_sub {
	di "`ed'"
	use "${health_data}lbw_births_by_county_`ed'_`y2'.dta", clear
		merge 1:1 fips county_name using "${health_data}nomiss_bw_by_county_`ed'_`y2'.dta"
		tab _merge
		drop _merge
		gen `ed' = 1
	save "${health_data}neonatal_health_intermediate_`ed'_`y2'.dta", replace

}

//# Append Data
//# append data: race/ethnicity 
use "${health_data}neonatal_health_intermediate_nhwhite_`y2'.dta", clear

	append using "${health_data}neonatal_health_intermediate_nhblack_`y2'.dta"
	append using "${health_data}neonatal_health_intermediate_hisp_`y2'.dta"
	append using "${health_data}neonatal_health_intermediate_nhother_`y2'.dta"

save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace

//# append data: mother's education
use "${health_data}neonatal_health_intermediate_lessthanhs_`y2'.dta", clear
	append using "${health_data}neonatal_health_intermediate_hsgrad_`y2'.dta"
	append using "${health_data}neonatal_health_intermediate_somecollege_`y2'.dta"
	append using "${health_data}neonatal_health_intermediate_collegedegrees_`y2'.dta"

save "${health_data}neonatal_health_intermediate_momed_`y2'.dta", replace

//# *(3) intermediate file data cleaning	

//# all births - all, race/ethnicity, and mother's education
foreach data_type of global data_types {
	di "`data_type'"
	use "${health_data}neonatal_health_intermediate_`data_type'_`y2'.dta", clear

	*year
	generate year = `y4'	// all data are 2022

	*state and county fips
		format fips %05.0f										// adds leading zero, fips is now consistently 5 digits

		gen state_s = substr(string(fips,"%05.0f"),1,2)			// generates state-only fips,
		gen county_s = substr(string(fips,"%05.0f"),3,3)		// generates county-only fips

			destring state_s county_s, generate (state county)	// converts new fips variables to integer variables
		
		format state %02.0f										// formats state fips as 2 digits
		format county %03.0f									// formats county fips as 3 digits
		
		drop state_s county_s fips

		label var year "year" 
		label var state "state fips"
		label var county "county fips"
		label var county_name "county name"
		label var lbw_births "count of lbw births"
		label var nomiss_births "count of all births with nonmissing bw data"

	*order, sort, and save
	order year state county
	sort state county

	save "${health_data}/neonatal_health_intermediate_`data_type'_`y2'.dta", replace
}

//# create subgroups: race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear
	gen subgroup = .
		
		replace subgroup = 1 if nhblack==1
		replace subgroup = 2 if hisp==1
		replace subgroup = 3 if nhother==1
		replace subgroup = 4 if nhwhite==1
	
	label define subl 0 "All" 1 "Black, Non-Hispanic" 2 "Hispanic" 3 "Other Races and Ethnicities" 4 "White, Non-Hispanic" 5 "Less than High School" 6 "GED/High School Degree" 7 "Some College" 8 "College Degree or Higher"
	label val subgroup subl
	
	drop nhblack hisp nhother nhwhite

	*order, sort, and save
	order year state county subgroup_type subgroup
	sort state county subgroup_type subgroup
	
save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace


//# create subgroups: mother's education
use "${health_data}neonatal_health_intermediate_momed_`y2'.dta", clear

	gen subgroup = .
		replace subgroup = 5 if lessthanhs == 1
		replace subgroup = 6 if hsgrad == 1
		replace subgroup = 7 if somecollege == 1
		replace subgroup = 8 if collegedegrees == 1
		
	label val subgroup sub1
		
	drop lessthanhs hsgrad somecollege collegedegrees
		
	*order, sort, and save
	order year state county subgroup_type subgroup
	sort state county subgroup_type subgroup
	
save "${health_data}neonatal_health_intermediate_momed_`y2'.dta", replace


//# * (4) use crosswalk to add missing counties to data file

/// all births
* clean crosswalk 
import delimited using "${geo_xwalk}county-populations.csv", clear
	
	keep year state county county_name				// keep only variables needed to crosswalk 
	keep if year == `y4'								// keep only current year
		format state %02.0f		
		format county %03.0f	
	
	keep year state county county_name	
	rename county_name county_cross_name
		
		label var year "year"
		label var state "state fips"
		label var county "county fips"
		label var county_cross_name "county name from crosswalk"

save "${health_data}clean_county_crosswalk_`y2'.dta", replace

/// add observations for each subgroup: race/ethnicity
	gen sub1 = 1		// column for subgroup_type==1
	gen sub2 = 2		// column for subgroup_type==2
	gen sub3 = 3		// column for subgroup_type==3
	gen sub4 = 4		// column for subgroup_type==4

	gen sub5 = 5		// column for subgroup_type==4
	gen sub6 = 6		// column for subgroup_type==4
	gen sub7 = 7		// column for subgroup_type==4
	gen sub8 = 8		// column for subgroup_type==4
	
	reshape long sub, i(state county) j(subgroup)			// convert columns to rows of observations 
		drop sub			// drop old column
	
	gen subgroup_type = "race-ethnicity"
	replace subgroup_type = "mothers-education" if subgroup > 4 & subgroup < 9
		sort state county subgroup		

// Race/Ethnicity
preserve 
	keep if subgroup < 5
	save "${health_data}clean_county_crosswalk_raceth_`y2'.dta", replace
restore 

// Mom's Education
preserve
	keep if subgroup > 4 & subgroup < 9
	save "${health_data}clean_county_crosswalk_momed_`y2'.dta", replace
restore

//# merge crosswalk and analytic file
//# merge crosswalk - all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear
	merge 1:1 state county using "${health_data}/clean_county_crosswalk_`y2'.dta"
	
	tab _merge		// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data

	

save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace

//# merge crosswalk - race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear
	merge 1:1 state county subgroup using "${health_data}clean_county_crosswalk_raceth_`y2'.dta"
	
	tab _merge		// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data

save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace

//# merge crosswalk - mother's education
use "${health_data}neonatal_health_intermediate_momed_`y2'.dta", clear
	merge 1:1 state county subgroup using "${health_data}clean_county_crosswalk_momed_`y2'.dta"
	
	tab _merge		// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data

save "${health_data}neonatal_health_intermediate_momed_`y2'.dta", replace

//# Append Education to Race Ethnicity - Keep the raceeth name the rest of the way
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear
	append using "${health_data}neonatal_health_intermediate_momed_`y2'.dta"
save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace


//# * (5) assign "unidentified county" values to counties with missing values

/// all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear

* generate flag for "unidentified county"
gen unidentified_county_flag = .
	replace unidentified_county_flag = 1 if _merge == 2		// observations only in CDC WONDER data and not in crosswalk (unidentified counties)
	label var unidentified_county_flag "indicator that data represent pooled unidentified counties in state"
	drop _merge

* test flag	
assert missing(lbw_births) 		if unidentified_county_flag == 1
assert missing(nomiss_births) 	if unidentified_county_flag == 1
assert !missing(lbw_births) 	if missing(unidentified_county_flag)
assert !missing(nomiss_births) 	if missing(unidentified_county_flag)

* assign unidentified county value to missing counties: lbw births
sort state county
by state: gen unidentified_lbw = lbw_births if county == 999		//create new variable with unidentified counties value

forvalues i = 1/255 {
	by state: replace unidentified_lbw = unidentified_lbw[_n+1] if missing(unidentified_lbw)
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace lbw_births = unidentified_lbw if unidentified_county_flag == 1  //replaces lbw_births with value from unidentified counties if an unidentified county

assert !missing(lbw_births) if unidentified_county_flag == 1		//test to confirm no missing values for unidentified counties
	drop unidentified_lbw


* assign unidentified county value to missing counties: nomiss births
sort state county
by state: gen unidentified_nomiss = nomiss_births if county == 999		//create new variable with unidentified counties value

forvalues i = 1/255 {
	by state: replace unidentified_nomiss = unidentified_nomiss[_n+1] if missing(unidentified_nomiss)
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace nomiss_births = unidentified_nomiss if unidentified_county_flag == 1  //replaces nomisss_births with value from unidentified counties if an unidentified county

assert !missing(nomiss_births) if unidentified_county_flag == 1	//test to confirm no missing values for unidentified counties
	drop unidentified_nomiss
	

*drop unidentified county observations because each unidentified county now has its own observation
drop if county == 999
drop county_name						// no longer need two county name variables
	rename county_cross_name county_name
	
save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace	



/// race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear

* generate flag for "unidentified county"
gen unidentified_county_flag=.
	replace unidentified_county_flag=1 if _merge==2		// observations only in CDC WONDER data and not in crosswalk (unidentified counties)
	label var unidentified_county_flag "indicator that data represent pooled unidentified counties in state"


* generate flag for "suppressed"
gen suppressed_county_flag=.
	replace suppressed_county_flag=1 if (lbw_births==. | nomiss_births==.) & _merge!=2
	label var suppressed_county_flag "indicator that data for county are suppressed"
	drop _merge
	
* test flags	
assert lbw_births == . if unidentified_county_flag == 1
assert missing(nomiss_births) if unidentified_county_flag == 1
assert (missing(lbw_births) | missing(nomiss_births)) if suppressed_county_flag == 1
assert !missing(lbw_births) if missing(unidentified_county_flag) & missing(suppressed_county_flag)
assert !missing(nomiss_births) if missing(unidentified_county_flag) & missing(suppressed_county_flag)



* assign unidentified county value to missing counties: lbw births
sort subgroup state county 
by subgroup state: gen unidentified_lbw = lbw_births if county == 999		//create new variable with unidentified counties value

forvalues i = 1/255 {
	by subgroup state: replace unidentified_lbw = unidentified_lbw[_n+1] if missing(unidentified_lbw)
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace lbw_births = unidentified_lbw if unidentified_county_flag == 1  //replaces all_birth with value from unidentified counties if an unidentified county, some remain missing due to suppressed data
	drop unidentified_lbw

* assign unidentified county value to missing counties: nomiss births
sort subgroup state county
by subgroup state: gen unidentified_nomiss = nomiss_births if county == 999		//create new variable with unidentified counties value

forvalues i = 1/255 {
	by subgroup state: replace unidentified_nomiss = unidentified_nomiss[_n+1] if missing(unidentified_nomiss)
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace nomiss_births = unidentified_nomiss if unidentified_county_flag == 1  //replaces all_birth with value from unidentified counties if an unidentified county, some remain missing due to suppressed data

*drop unidentified county observations because each unidentified county now has its own observation
drop if county == 999
drop county_name						// no longer need two county name variables
	rename county_cross_name county_name
	
save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace

//# *(6) create neonatal health share low birthweight metric

//# lbw metric -  all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear
*share lbw among nonmissing bw births 			// primary measure of lbw limiting the denominator to births with nonmissing birthweight data
generate share_lbw_nomiss = lbw_births / nomiss_births
	sum share_lbw_nomiss, detail
	
	assert share_lbw_nomiss < 1 if nomiss_births > 0 // There are 9 zero nomiss_births values that result in missing share_lbw_nomiss values
save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace
	
//# lbw metric -  race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear
*share lbw among nonmissing bw births 			// primary measure of lbw limiting the denominator to births with nonmissing birthweight data
	generate share_lbw_nomiss = lbw_births/nomiss_births
	
	sum share_lbw_nomiss, detail
	
	assert share_lbw_nomiss < 1 if missing(suppressed_county_flag) & missing(unidentified_county_flag) & !missing(share_lbw_nomiss)
	assert share_lbw_nomiss >= 0
save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace



//# *(7) assess data quality

//# Data Quality Flags - all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear

*generate data quality flag	// based on whether metric is county level (quality score = 1) or pooled across all small counties (quality score = 3). County level estimates based on 10-29 low birthweight births are given a data quality score of 2.
gen lbw_quality = .
	replace lbw_quality = 1 if missing(unidentified_county_flag)==.		// assigning a quality score of 1 to all counties *not* flagged as "unassigned counties"
	replace lbw_quality = 2 if lbw_births < 30					// assigning a quality score of 2 to all counties with fewer than 30 observed low birthweight births
	replace lbw_quality = 3 if unidentified_county_flag == 1		// assigning a quality score of 3 to all counties flagged as "unassigned counties"
		label var lbw_quality "share low birthweight births: quality flag"
save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace

//# Data Quality Flags - race/ethnicity
local y2 = 22
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear

*generate data quality flag	// based on whether metric is county level (quality score = 1) or pooled across all small counties (quality score = 3). County level estimates based on 10-29 low birthweight births are given a data quality score of 2.
gen lbw_quality = .
	replace lbw_quality = 1 if missing(unidentified_county_flag) & missing(suppressed_county_flag)	// assigning a quality score of 1 to all counties *not* flagged as "unassigned counties" or "suppressed"
	replace lbw_quality = 2 if lbw_births < 30											// assigning a quality score of 2 to all counties with fewer than 30 observed low birthweight births
	replace lbw_quality = 3 if unidentified_county_flag == 1 | suppressed_county_flag == 1	// assigning a quality score of 3 to all counties flagged as "unassigned counties" or "suppressed"
		label var lbw_quality "share low birthweight births: quality flag"
save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace

//# Confidence Intervals
*(8) construct 95 percent confidence intervals
* note: confidence intervals are constructed following the User Guide to the 2010 Natality Public Use File, linked in the README and saved on Box 	
* for more information, see README

//# 95% CI - all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear

*generate and test conditions from User Guide:
gen test_1 = share_lbw_nomiss * nomiss_births
gen test_2 = (1 - share_lbw_nomiss) * nomiss_births 

gen fail_test_1 = test_1 < 5
gen fail_test_2 = test_2 < 5

assert test_1 >= 5 				// confirms data meet condition #1; if failures, need to flag failed observations
assert test_2 >= 5  			// confirms data meet condition #2; if failures, need to flag failed observations

drop fail_test*

*generate and test confidence intervals for primary indicator
gen lbw_lb = (share_lbw_nomiss) - (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))

	sum lbw_lb, detail
	assert lbw_lb < 1 if !missing(lbw_lb) // confirms lower bound is a percentage
	assert lbw_lb > 0 	// confirms lower bound is a percentage
	assert lbw_lb < share_lbw_nomiss  if !missing(lbw_lb) // confirms lower bound is less than estimate
	
gen lbw_ub = (share_lbw_nomiss) + (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))

	sum lbw_ub, detail
	assert lbw_ub < 1  if !missing(lbw_ub) 	// confirms upper bound is a percentage
	assert lbw_ub > 0 	// confirms upper bound is a percentage
	assert lbw_ub > share_lbw_nomiss  if !missing(lbw_ub)	// confirms upper bound is greater than estimate
	
*generate 95 confidence interval range to check reliability of estiates
gen lbw_ci_range = lbw_ub - lbw_lb
	sum lbw_ci_range 
	assert lbw_ci_range < 1  if !missing(lbw_lb)	// confirms range is a percentage
	assert lbw_ci_range > 0 	// confirms range is a percentage

save "${health_data}neonatal_health_intermediate_all_`y2'.dta", replace

//# 95% CI - race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear

*generate and test conditions from User Guide:
gen test_1 = share_lbw_nomiss * nomiss_births
gen test_2 = (1-share_lbw_nomiss) * nomiss_births 

	assert test_1 >= 5  if share_lbw_nomiss != 0	// confirms data meet condition #1; if failures, need to flag failed observations - test_1 fails for 80 cases where lbw_births == 0
	assert test_2 >= 5  if share_lbw_nomiss != 0	// confirms data meet condition #2; if failures, need to flag failed observations - test_2 fails for 37 cases where lbw_births == 0

//// ASSERTIONS \\\\\\
// There are 15 failures of test_1 - all places with no low weight births
// There is 1 failure of test_2  - county with no births for Black mothers

gen fail_test_1 = test_1 >= 5
gen fail_test_2 = test_2 >= 5
	

*generate and test confidence intervals for primary indicator
gen lbw_lb = (share_lbw_nomiss) - (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))
	sum lbw_lb, detail
//There are 90 cases where lbw_births == 0 which would cause violations of the assert statements without adding that stipulation

	assert lbw_lb < 1 if missing(suppressed_county_flag) & missing(unidentified_county_flag) & lbw_births > 0	// confirms lower bound is a percentage - 1 case that violates b/c lbw_births == 0 (and nomiss_births also == 0)
	assert lbw_lb > 0 if lbw_births > 0 & !missing(lbw_births)	// confirms lower bound is a percentage - 43 cases that violate because lbw_births == 0
	assert lbw_lb < share_lbw_nomiss if missing(suppressed_county_flag) & missing(unidentified_county_flag) & lbw_births != 0 // confirms lower bound is less than estimate - 15 cases that violate because lbw_births == 0

gen lbw_ub = (share_lbw_nomiss) + (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))

	sum lbw_ub, detail
	assert lbw_ub < 1 if missing(suppressed_county_flag) & missing(unidentified_county_flag) & lbw_births > 0		// confirms upper bound is a percentage - 1 case that violates b/c lbw_births == 0 (and nomiss_births also == 0)
	assert lbw_ub > 0 if lbw_births > 0	// confirms upper bound is a percentage - 43 cases that violate because lbw_births == 0
	assert lbw_ub > share_lbw_nomiss if missing(suppressed_county_flag)	& missing(unidentified_county_flag) & lbw_births > 0  // confirms upper bound is greater than estimate - 14 cases that violate because lbw_births == 0

	
*generate 95 confidence interval range to check reliability of estiates
gen lbw_ci_range = lbw_ub - lbw_lb
sum lbw_ci_range 
	assert lbw_ci_range < 1 if missing(suppressed_county_flag) & missing(unidentified_county_flag) & lbw_births > 0	// confirms range is a percentage - 1 case that violates because lbw_births == 0
	assert lbw_ci_range > 0 if missing(suppressed_county_flag) & missing(unidentified_county_flag)	 & lbw_births > 0  // confirms upper bound is greater than estimate - 14 cases that violate because lbw_births == 0

save "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", replace

//# * (9) final file cleaning and export to csv file

// all births
use "${health_data}neonatal_health_intermediate_all_`y2'.dta", clear
keep year state county share_lbw_nomiss lbw_lb lbw_ub lbw_quality	// keep only variables needed for final file
	rename share_lbw_nomiss lbw							// final name		
		label var lbw "share low birth weight births among births with nonmissing birth weight data"
		label var lbw_lb "share low birthweight births: lower bound 95 percent confidence interval"
		label var lbw_ub "share low birthweight births: upper bound 95 percent confidence interval"
	format lbw %04.2f									// format to include leading zero and limit to two decimal places per guidance 
	format lbw_lb  %04.2f								// format to include leading zero and limit to two decimal places per guidance
	format lbw_ub  %04.2f								// format to include leading zero and limit to two decimal places per guidance
gen str3 new_county = string(county, "%03.0f")			// fix to include leading zeroes in county variables
	tab county new_county if county < 10					// quick check to confirm leading zeroes
	drop county
	rename new_county county
gen str2 new_state = string(state, "%02.0f")			// fix to include leading zeroes in state variable
	tab state new_state if state < 10						// quick check to confirm leading zeroes
	drop state
	rename new_state state
order year state county lbw lbw_lb lbw_ub lbw_quality	// order
sort year state county									// sort

rename lbw rate_low_birth_weight					// Rename per Aaron request
rename lbw_* rate_low_birth_weight_*				// Rename per Aaron request

save "${health_data}neonatal_health_`y4'.dta", replace
export delimited using "${health_data_final}neonatal_health_`y4'.csv", replace

// race/ethnicity
use "${health_data}neonatal_health_intermediate_raceth_`y2'.dta", clear
keep year state county share_lbw_nomiss lbw_lb lbw_ub lbw_quality subgroup_type subgroup	// keep only variables needed for final file
	rename share_lbw_nomiss lbw							// final name		
		label var lbw "share low birth weight births among births with nonmissing birth weight data"
		label var lbw_lb "share low birthweight births: lower bound 95 percent confidence interval"
		label var lbw_ub "share low birthweight births: upper bound 95 percent confidence interval"
	format lbw %04.2f									// format to include leading zero and limit to two decimal places per guidance 
	format lbw_lb  %04.2f								// format to include leading zero and limit to two decimal places per guidance
	format lbw_ub  %04.2f								// format to include leading zero and limit to two decimal places per guidance
gen str3 new_county = string(county, "%03.0f")			// fix to include leading zeroes in county variable
	tab county new_county if county < 10					// quick check to confirm leading zeroes
	drop county
	rename new_county county
gen str2 new_state = string(state, "%02.0f")			// fix to include leading zeroes in state variable
	tab state new_state if state < 10						// quick check to confirm leading zeroes
	drop state
	rename new_state state
order year state county subgroup_type subgroup lbw lbw_lb lbw_ub lbw_quality 	// order
sort year state county subgroup_type subgroup


rename lbw rate_low_birth_weight 				// Rename per Aaron request
rename lbw_* rate_low_birth_weight_*			// Rename per Aaron request

append using "${health_data}neonatal_health_`y4'.dta"				// append aggregate county-level estimates to subgroup file

replace subgroup_type = "all" if missing(subgroup_type)								// label aggregate county-level estimates as "all" 
replace subgroup = 0 if missing(subgroup)												// label aggregate county-level estimates as "all"
	label val subgroup subl


sort subgroup
by subgroup: sum rate_low_birth_weight											// checking share lowbirthweight by subgroup

sort year state county subgroup_type subgroup									// final sort

save "${health_data}neonatal_health_subgroup_`y4'.dta", replace
export delimited using "${health_data_final}neonatal_health_subgroup_`y4'.csv", replace 

