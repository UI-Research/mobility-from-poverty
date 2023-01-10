************************************************************************
* Ancestor program: $gitfolder/neonatal_health_code.do 				   
* Original data: all_births_by_county.txt, lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder/04_health/data      				   
* Description: Program to create gates mobility metrics on neonatal health  
* Author: Emily M. Johnston												   
* Date: August 14, 2020; Updated October 26, 2022; September 16, 2020; Updated December 11, 2020; Updated December 21, 2020.	
* (1)  download data from CDC WONDER											
* (2)  import, clean, and merge CDC WONDER files					   
* (3)  intermediate file data cleaning										   
* (4)  use crosswalk to add missing counties to data file		
* (5)  assign "unidentified county" values to counties with missing values
* (6)  create neonatal health share lowbirthweight metric
* (7) assess data quality
* (8) construct 95 percent confidence intervals
* (9) final file cleaning and export to csv file									   
****************************************************************************

global gitfolder = "C:/mobility-from-poverty"	// update path as necessary to the local mobility metrics repository folder
global sub = "nhblack hisp nhother nhwhite"
global data = "all raceth"

cd "${gitfolder}"

*(1) download data from CDC WONDER

* access instructions for completing the CDC WONDER data query in README	
* data query results are saved as lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder/04_health/data 

*(2) open, clean, and merge CDC WONDER files

/// open and clean data: all births
*low birth weight births
import delimited using "$gitfolder/04_health/data/lbw_births_by_county_18.txt", clear
	keep county countycode births									// do not need CDC notes
	drop if births=="Missing County"								// only keeping observations with birth data	
		rename county county_name
		rename countycode fips
		rename births lbw_births
	destring lbw_births, replace force
	sort fips county_name											// count of low birthweight births
	keep if fips!=.													// only keeping observations with data
save "$gitfolder/04_health/data/lbw_births_by_county_18.dta", replace

*nonmissing birth weight births
import delimited using "$gitfolder/04_health/data/nomiss_bw_by_county_18.txt", clear
	keep county countycode births									// do not need CDC notes	
	drop if births=="Missing County"								// only keeping observations with birth data	
	destring births, replace
		rename county county_name
		rename countycode fips
		rename births nomiss_births 								// count of births with nonmissing birth weight data
	destring nomiss_births, replace force
	sort fips county_name
	keep if fips!=.													// only keeping observations with county data	
save "$gitfolder/04_health/data/nomiss_bw_by_county_18.dta", replace

/// open and clean data: race/ethnicity
*low birth weight births
foreach sub in $sub{
import delimited using "$gitfolder/04_health/data/lbw_births_by_county_`sub'_18.txt", clear
	keep county countycode births									// do not need CDC notes
	drop if births=="Missing County"								// only keeping observations with birth data	
		rename county county_name
		rename countycode fips
		rename births lbw_births
	destring lbw_births, replace force
	gen subgroup_type = "race-ethnicity"	
	sort fips county_name											// count of low birthweight births
	keep if fips!=.													// only keeping observations with data
save "$gitfolder/04_health/data/lbw_births_by_county_`sub'_18.dta", replace
}

*nonmissing birth weight births
foreach sub in $sub{
	import delimited using "$gitfolder/04_health/data/nomiss_bw_by_county_`sub'_18.txt", clear
	keep county countycode births									// do not need CDC notes	
	drop if births=="Missing County"								// only keeping observations with birth data	
	destring births, replace
		rename county county_name
		rename countycode fips
		rename births nomiss_births 								// count of births with nonmissing birth weight data
	destring nomiss_births, replace force
	gen subgroup_type = "race-ethnicity"	
	sort fips county_name
	keep if fips!=.													// only keeping observations with county data	
save "$gitfolder/04_health/data/nomiss_bw_by_county_`sub'_18.dta", replace
}


/// merge files: all births
use "$gitfolder/04_health/data/lbw_births_by_county_18.dta", clear
	merge 1:1 fips county_name using "$gitfolder/04_health/data/nomiss_bw_by_county_18.dta"
		tab _merge
		drop _merge
	save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace
	
/// merge files: race/ethnicity
foreach sub in $sub{	
use "$gitfolder/04_health/data/lbw_births_by_county_`sub'_18.dta", clear
	merge 1:1 fips county_name using "$gitfolder/04_health/data/nomiss_bw_by_county_`sub'_18.dta"
		tab _merge
		drop _merge
		gen `sub'=1
	save "$gitfolder/04_health/data/neonatal_health_intermediate_`sub'_18.dta", replace
}

/// append data: race/ethnicity 
use "$gitfolder/04_health/data/neonatal_health_intermediate_nhwhite_18.dta", replace
	append using "$gitfolder/04_health/data/neonatal_health_intermediate_nhblack_18.dta"
	append using "$gitfolder/04_health/data/neonatal_health_intermediate_hisp_18.dta"
	append using "$gitfolder/04_health/data/neonatal_health_intermediate_nhother_18.dta"
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace

*(3) intermediate file data cleaning	

/// all births and by race/ethnicity
foreach data in $data {
use "$gitfolder/04_health/data/neonatal_health_intermediate_`data'_18.dta", clear

*year
generate year = 2018												// all data are 2018

*state and county fips
	format fips %05.0f												// adds leading zero, fips is now consistently 5 digits
gen state_s = substr(string(fips,"%05.0f"),1,2)					// generates state-only fips,
gen county_s = substr(string(fips,"%05.0f"),3,3)					// generates county-only fips
destring state_s county_s, generate (state county)					// converts new fips variables to integer variables
	format state %02.0f												// formats state fips as 2 digits
	format county %03.0f											// formats county fips as 3 digits
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
save "$gitfolder/04_health/data/neonatal_health_intermediate_`data'_18.dta", replace
}


/// create subgroups: race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear
gen subgroup = .
	replace subgroup = 1 if nhblack==1
	replace subgroup = 2 if hisp==1
	replace subgroup = 3 if nhother==1
	replace subgroup = 4 if nhwhite==1
label define subl 0 "All" 1 "Black, Non-Hispanic" 2 "Hispanic" 3 "Other Races and Ethnicities" 4 "White, Non-Hispanic"
	label val subgroup subl
drop nhblack hisp nhother nhwhite

*order, sort, and save
order year state county subgroup_type subgroup
sort state county subgroup_type subgroup
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace

* (4) use crosswalk to add missing counties to data file

/// all births
* clean crosswalk
import delimited using "$gitfolder/geographic-crosswalks/data/county-populations.csv", clear
	keep year state county county_name				// keep only variables needed to crosswalk 
	keep if year==2018								// keep only current year
		format state %02.0f		
		format county %03.0f	
keep year state county county_name	
rename county_name county_cross_name
	label var year "year"
	label var state "state fips"
	label var county "county fips"
	label var county_cross_name "county name from crosswalk"

save "$gitfolder/04_health/data/clean_county_crosswalk_18.dta", replace

/// add observations for each subgroup: race/ethnicity
	gen sub1 = 1		// column for subgroup_type==1
	gen sub2 = 2		// column for subgroup_type==2
	gen sub3 = 3		// column for subgroup_type==3
	gen sub4 = 4		// column for subgroup_type==4	
	reshape long sub, i(state county) j(subgroup)			// convert columns to rows of observations 
		drop sub			// drop old column
	gen subgroup_type = "race-ethnicity"
		sort state county subgroup		
		
save "$gitfolder/04_health/data/clean_county_crosswalk_raceth_18.dta", replace

* merge crosswalk and analytic file
//// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear
merge 1:1 state county using "$gitfolder/04_health/data/clean_county_crosswalk_18.dta"
tab _merge															
// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data
save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace

//// race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear
merge 1:1 state county subgroup using "$gitfolder/04_health/data/clean_county_crosswalk_raceth_18.dta"
tab _merge															
// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace

* (5) assign "unidentified county" values to counties with missing values

/// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear

* generate flag for "unidentified county"
gen unidentified_county_flag=.
	replace unidentified_county_flag=1 if _merge==2		// observations only in CDC WONDER data and not in crosswalk (unidentified counties)
	label var unidentified_county_flag "indicator that data represent pooled unidentified counties in state"
	drop _merge

* test flag	
assert lbw_births==. if unidentified_county_flag==1
assert nomiss_births==. if unidentified_county_flag==1
assert lbw_births!=. if unidentified_county_flag==.
assert nomiss_births!=. if unidentified_county_flag==.


* assign unidentified county value to missing counties: lbw births
sort state county
by state: gen unidentified_lbw=lbw_births if county==999		//create new variable with unidentified counties value

forvalues i = 1/255 {
by state: replace unidentified_lbw=unidentified_lbw[_n+1] if unidentified_lbw==.
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace lbw_births=unidentified_lbw if unidentified_county_flag==1  //replaces all_birth with value from unidentified counties if an unidentified county

assert lbw_births!=. if unidentified_county_flag==1		//test to confirm no missing values for unidentified counties
	drop unidentified_lbw

* assign unidentified county value to missing counties: nomiss births
sort state county
by state: gen unidentified_nomiss=nomiss_births if county==999		//create new variable with unidentified counties value

forvalues i = 1/255 {
by state: replace unidentified_nomiss=unidentified_nomiss[_n+1] if unidentified_nomiss==.
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace nomiss_births=unidentified_nomiss if unidentified_county_flag==1  //replaces all_birth with value from unidentified counties if an unidentified county

assert nomiss_births!=. if unidentified_county_flag==1	//test to confirm no missing values for unidentified counties
	drop unidentified_nomiss

*drop unidentified county observations because each unidentified county now has its own observation
drop if county==999
drop county_name							// no longer need two county name variables
	rename county_cross_name county_name
	
save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace	
	

/// race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear

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
assert lbw_births==. if unidentified_county_flag==1
assert nomiss_births==. if unidentified_county_flag==1
assert (lbw_births==.|nomiss_births==.) if suppressed_county_flag==1
assert lbw_births!=. if unidentified_county_flag==. & suppressed_county_flag==.
assert nomiss_births!=. if unidentified_county_flag==. & suppressed_county_flag==.


* assign unidentified county value to missing counties: lbw births
sort subgroup state county 
by subgroup state: gen unidentified_lbw=lbw_births if county==999		//create new variable with unidentified counties value

forvalues i = 1/255 {
by subgroup state: replace unidentified_lbw=unidentified_lbw[_n+1] if unidentified_lbw==.
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace lbw_births=unidentified_lbw if unidentified_county_flag==1  //replaces all_birth with value from unidentified counties if an unidentified county, some remain missing due to suppressed data
	drop unidentified_lbw

* assign unidentified county value to missing counties: nomiss births
sort subgroup state county
by subgroup state: gen unidentified_nomiss=nomiss_births if county==999		//create new variable with unidentified counties value

forvalues i = 1/255 {
by subgroup state: replace unidentified_nomiss=unidentified_nomiss[_n+1] if unidentified_nomiss==.
}
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace nomiss_births=unidentified_nomiss if unidentified_county_flag==1  //replaces all_birth with value from unidentified counties if an unidentified county, some remain missing due to suppressed data

*drop unidentified county observations because each unidentified county now has its own observation
drop if county==999
drop county_name							// no longer need two county name variables
	rename county_cross_name county_name
	
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace

*(6) create neonatal health share low birthweight metric

/// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear
*share lbw among nonmissing bw births 			// primary measure of lbw limiting the denominator to births with nonmissing birthweight data
generate share_lbw_nomiss = lbw_births/nomiss_births
	sum share_lbw_nomiss, detail
	assert share_lbw_nomiss<1
	assert share_lbw_nomiss>0 
save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace
	
/// race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear
*share lbw among nonmissing bw births 			// primary measure of lbw limiting the denominator to births with nonmissing birthweight data
generate share_lbw_nomiss = lbw_births/nomiss_births
	sum share_lbw_nomiss, detail
	assert share_lbw_nomiss<1 if suppressed_county_flag==. & unidentified_county_flag==.
	assert share_lbw_nomiss>0 
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace	
	
*(7) assess data quality

/// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear

*generate data quality flag						// based on whether metric is county level (quality score = 1) or pooled across all small counties (quality score = 3). County level estimates based on 10-29 low birthweight births are given a data quality score of 2.
gen lbw_quality = .
	replace lbw_quality = 1 if unidentified_county_flag==.		// assigning a quality score of 1 to all counties *not* flagged as "unassigned counties"
	replace lbw_quality = 2 if lbw_births<30												// assigning a quality score of 2 to all counties with fewer than 30 observed low birthweight births
	replace lbw_quality = 3 if unidentified_county_flag==1		// assigning a quality score of 3 to all counties flagged as "unassigned counties"
		label var lbw_quality "share low birthweight births: quality flag"
save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace

/// race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear

*generate data quality flag						// based on whether metric is county level (quality score = 1) or pooled across all small counties (quality score = 3). County level estimates based on 10-29 low birthweight births are given a data quality score of 2.
gen lbw_quality = .
	replace lbw_quality = 1 if unidentified_county_flag==. & suppressed_county_flag==.		// assigning a quality score of 1 to all counties *not* flagged as "unassigned counties" or "suppressed"
	replace lbw_quality = 2 if lbw_births<30												// assigning a quality score of 2 to all counties with fewer than 30 observed low birthweight births
	replace lbw_quality = 3 if unidentified_county_flag==1 | suppressed_county_flag==1	// assigning a quality score of 3 to all counties flagged as "unassigned counties" or "suppressed"
		label var lbw_quality "share low birthweight births: quality flag"
save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace


*(8) construct 95 percent confidence intervals
* note: confidence intervals are constructed following the User Guide to the 2010 Natality Public Use File, linked in the README and saved on Box 	
* for more information, see README

/// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear

*generate and test conditions from User Guide:
gen test_1=share_lbw_nomiss*nomiss_births
gen test_2=(1-share_lbw_nomiss)*nomiss_births 
	assert test_1>=5  					// confirms data meet condition #1; if failures, need to flag failed observations
	assert test_2>=5  					// confirms data meet condition #2; if failures, need to flag failed observations

*generate and test confidence intervals for primary indicator
gen lbw_lb= (share_lbw_nomiss) - (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))
	sum lbw_lb, detail
	assert lbw_lb<1 	// confirms lower bound is a percentage
	assert lbw_lb>0 	// confirms lower bound is a percentage
	assert lbw_lb<share_lbw_nomiss  // confirms lower bound is less than estimate
gen lbw_ub= (share_lbw_nomiss) + (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))
	sum lbw_ub, detail
	assert lbw_ub<1  	// confirms upper bound is a percentage
	assert lbw_ub>0 	// confirms upper bound is a percentage
	assert lbw_ub>share_lbw_nomiss 	// confirms upper bound is greater than estimate
	
*generate 95 confidence interval range to check reliability of estiates
gen lbw_ci_range=lbw_ub-lbw_lb
	sum lbw_ci_range 
	assert lbw_ci_range<1 	// confirms range is a percentage
	assert lbw_ci_range>0 	// confirms range is a percentage

save "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", replace

/// race/ethnicity 
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear

*generate and test conditions from User Guide:
gen test_1=share_lbw_nomiss*nomiss_births
gen test_2=(1-share_lbw_nomiss)*nomiss_births 
	assert test_1>=5  					// confirms data meet condition #1; if failures, need to flag failed observations
	assert test_2>=5  					// confirms data meet condition #2; if failures, need to flag failed observations

*generate and test confidence intervals for primary indicator
gen lbw_lb= (share_lbw_nomiss) - (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))
	sum lbw_lb, detail
	assert lbw_lb<1 if suppressed_county_flag==. & unidentified_county_flag==.	// confirms lower bound is a percentage
	assert lbw_lb>0 	// confirms lower bound is a percentage
	assert lbw_lb<share_lbw_nomiss if suppressed_county_flag==. & unidentified_county_flag==. // confirms lower bound is less than estimate
gen lbw_ub= (share_lbw_nomiss) + (1.96*sqrt(share_lbw_nomiss*(1-share_lbw_nomiss)/nomiss_births))
	sum lbw_ub, detail
	assert lbw_ub<1 if suppressed_county_flag==. & unidentified_county_flag==.	// confirms upper bound is a percentage
	assert lbw_ub>0 	// confirms upper bound is a percentage
	assert lbw_ub>share_lbw_nomiss if suppressed_county_flag==.	& unidentified_county_flag==. // confirms upper bound is greater than estimate
	
*generate 95 confidence interval range to check reliability of estiates
gen lbw_ci_range=lbw_ub-lbw_lb
	sum lbw_ci_range 
	assert lbw_ci_range<1 if suppressed_county_flag==. & unidentified_county_flag==.	// confirms range is a percentage
	assert lbw_ci_range>0 if suppressed_county_flag==. & unidentified_county_flag==.	// confirms range is a percentage

save "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", replace

* (9) final file cleaning and export to csv file

// all births
use "$gitfolder/04_health/data/neonatal_health_intermediate_all_18.dta", clear
keep year state county share_lbw_nomiss lbw_lb lbw_ub lbw_quality	// keep only variables needed for final file
	rename share_lbw_nomiss lbw							// final name		
		label var lbw "share low birth weight births among births with nonmissing birth weight data"
		label var lbw_lb "share low birthweight births: lower bound 95 percent confidence interval"
		label var lbw_ub "share low birthweight births: upper bound 95 percent confidence interval"
	format lbw %04.2f									// format to include leading zero and limit to two decimal places per guidance 
	format lbw_lb  %04.2f								// format to include leading zero and limit to two decimal places per guidance
	format lbw_ub  %04.2f								// format to include leading zero and limit to two decimal places per guidance
gen str3 new_county = string(county, "%03.0f")			// fix to include leading zeroes in county variables
	tab county new_county if county<10					// quick check to confirm leading zeroes
	drop county
	rename new_county county
gen str2 new_state = string(state, "%02.0f")			// fix to include leading zeroes in state variable
	tab state new_state if state<10						// quick check to confirm leading zeroes
	drop state
	rename new_state state
order year state county lbw lbw_lb lbw_ub lbw_quality	// order
sort year state county									// sort

save "$gitfolder/04_health/data/neonatal_health_2018.dta", replace
export delimited using "$gitfolder/04_health/final_data/neonatal_health_2018.csv", replace



// race/ethnicity
use "$gitfolder/04_health/data/neonatal_health_intermediate_raceth_18.dta", clear
keep year state county share_lbw_nomiss lbw_lb lbw_ub lbw_quality subgroup_type subgroup	// keep only variables needed for final file
	rename share_lbw_nomiss lbw							// final name		
		label var lbw "share low birth weight births among births with nonmissing birth weight data"
		label var lbw_lb "share low birthweight births: lower bound 95 percent confidence interval"
		label var lbw_ub "share low birthweight births: upper bound 95 percent confidence interval"
	format lbw %04.2f									// format to include leading zero and limit to two decimal places per guidance 
	format lbw_lb  %04.2f								// format to include leading zero and limit to two decimal places per guidance
	format lbw_ub  %04.2f								// format to include leading zero and limit to two decimal places per guidance
gen str3 new_county = string(county, "%03.0f")			// fix to include leading zeroes in county variable
	tab county new_county if county<10					// quick check to confirm leading zeroes
	drop county
	rename new_county county
gen str2 new_state = string(state, "%02.0f")			// fix to include leading zeroes in state variable
	tab state new_state if state<10						// quick check to confirm leading zeroes
	drop state
	rename new_state state
order year state county subgroup_type subgroup lbw lbw_lb lbw_ub lbw_quality 	// order
sort year state county subgroup_type subgroup

append using "$gitfolder/04_health/data/neonatal_health_2018.dta"					// append aggregate county-level estimates to subgroup file

replace subgroup_type = "all" if subgroup_type==""								// label aggregate county-level estimates as "all" 
replace subgroup = 0 if subgroup==.												// label aggregate county-level estimates as "all"
	label val subgroup subl


sort subgroup
by subgroup: sum lbw															// checking share lowbirthweight by subgroup

sort year state county subgroup_type subgroup									// final sort

save "$gitfolder/04_health/data/neonatal_health_subgroup_2018.dta", replace
export delimited using "$gitfolder/04_health/final_data/neonatal_health_subgroup_2018.csv", replace