************************************************************************
* Ancestor program: $gitfolder\neonatal_health_code.do 				   
* Original data: all_births_by_county.txt, lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder\04_health\data      				   
* Description: Program to create gates mobility metrics on neonatal health  
* Author: Emily M. Johnston												   
* Date: August 14, 2020; Updated September 16, 2020	
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

global gitfolder = "K:\Hp\EJohnston\Git\gates-mobility-metrics"	// update path as necessary to the local mobility metrics repository folder
cd "${gitfolder}"

*(1) download data from CDC WONDER

* access instructions for completing the CDC WONDER data query in README	
* data query results are saved as all_births_by_county.txt, lbw_births_by_county.txt, nomiss_bw_by_county.txt available in $gitfolder\04_health\data 

*(2) open, clean, and merge CDC WONDER files

*all births
import delimited using "$gitfolder\04_health\data\all_births_by_county.txt", clear
	keep county countycode births									// do not need CDC notes
	drop if births=="Missing County"								// only keeping observations with birth data	
		rename county county_name
		rename countycode fips
		rename births all_births
	destring all_births, replace
	sort fips county_name												
	keep if fips!=.													// only keeping observations with data	
save "$gitfolder\04_health\data\all_births_by_county.dta", replace

*low birth weight births
import delimited using "$gitfolder\04_health\data\lbw_births_by_county.txt", clear
	keep county countycode births									// do not need CDC notes
	drop if births=="Missing County"								// only keeping observations with birth data	
		rename county county_name
		rename countycode fips
		rename births lbw_births
	destring lbw_births, replace
	sort fips county_name											// count of low birthweight births
	keep if fips!=.													// only keeping observations with data
save "$gitfolder\04_health\data\lbw_births_by_county.dta", replace

*nonmissing birth weight births
import delimited using "$gitfolder\04_health\data\nomiss_bw_by_county.txt", clear
	keep county countycode births									// do not need CDC notes	
	drop if births=="Missing County"								// only keeping observations with birth data	
	destring births, replace
		rename county county_name
		rename countycode fips
		rename births nomiss_births 								// count of births with nonmissing birth weight data
	destring nomiss_births, replace
	sort fips county_name
	keep if fips!=.													// only keeping observations with county data	
save "$gitfolder\04_health\data\nomiss_bw_by_county.dta", replace

*merge files
use "$gitfolder\04_health\data\all_births_by_county.dta", clear
	merge 1:1 fips county_name using "$gitfolder\04_health\data\lbw_births_by_county.dta"
		tab _merge
		drop _merge
	merge 1:1 fips county_name using "$gitfolder\04_health\data\nomiss_bw_by_county.dta"
		tab _merge
		drop _merge
	save "$gitfolder\04_health\data\neonatal_health_intermediate.dta", replace

*(3) intermediate file data cleaning	

*year
generate year = 2018												// all data are 2018

*state and county fips
	format fips %05.0f												// adds leading zero, fips is now consistently 5 digits
gen state_s = substr(string(fips,"%05.0f"),-5,2)					// generates state-only fips,
gen county_s = substr(string(fips,"%05.0f"),-3,3)					// generates county-only fips
destring state_s county_s, generate (state county)					// converts new fips variables to integer variables
	format state %02.0f												// formats state fips as 2 digits
	format county %03.0f											// formats county fips as 3 digits
	drop state_s county_s fips

	label var year "year" 
	label var state "state fips"
	label var county "county fips"
	label var county_name "county name"
	label var all_births "count of all births"
	label var lbw_births "count of lbw births"
	label var nomiss_births "count of all births with nonmissing bw data"

*order, sort, and save
order year state county
sort state county
save "$gitfolder\04_health\data\neonatal_health_intermediate.dta", replace


* (4) use crosswalk to add missing counties to data file

* clean crosswalk
import delimited using "$gitfolder\geographic-crosswalks\data\county-file.csv", clear
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
save "$gitfolder\04_health\data\clean_county_crosswalk.dta", replace

* merge crosswalk and analytic file
use "$gitfolder\04_health\data\neonatal_health_intermediate.dta", clear
merge 1:1 state county using "$gitfolder\04_health\data\clean_county_crosswalk.dta"
tab _merge															
// correct to have master only and using only observations because of the pooled "unidentified counties" in the CDC WONDER data
save "$gitfolder\04_health\data\neonatal_health_intermediate.dta", replace

* (5) assign "unidentified county" values to counties with missing values

* generate flag for "unidentified county"
gen unidentified_county_flag=.
	replace unidentified_county_flag=1 if _merge==2		// observations only in CDC WONDER data and not in crosswalk (unidentified counties)
	label var unidentified_county_flag "indicator that data represent pooled unidentified counties in state"
	drop _merge

* test flag	
assert all_births==. if unidentified_county_flag==1
assert lbw_births==. if unidentified_county_flag==1
assert nomiss_births==. if unidentified_county_flag==1
assert all_births!=. if unidentified_county_flag==.
assert lbw_births!=. if unidentified_county_flag==.
assert nomiss_births!=. if unidentified_county_flag==.

* assign unidentified county value to missing counties: all births
sort state county
by state: gen unidentified_all=all_births if county==999		//create new variable with unidentified counties value

forvalues i = 1/255 {
by state: replace unidentified_all=unidentified_all[_n+1] if unidentified_all==.
}											
//loop replaces the value of new variable with the value from the unidentified counties within a state
//repeated 255 times because that is the maximum number of counties in a state
//end result is a single variable with unidentified counties value for every observation											

replace all_births=unidentified_all if unidentified_county_flag==1	//replaces all_birth with value from unidentified counties if an unidentified county

assert all_births!=. if unidentified_county_flag==1 		//test to confirm no missing values for unidentified counties
	drop unidentified_all

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

*(6) create neonatal health share lowbirthweight metric

*share lbw among nonmissing bw births 			// primary measure of lbw limiting the denominator to births with nonmissing birthweight data
generate share_lbw_nomiss = lbw_births/nomiss_births
	sum share_lbw_nomiss, detail
	assert share_lbw_nomiss<1
	assert share_lbw_nomiss>0 
	 
*share lbw among all births						// alternate measure of lbw	including all births in denominator	
generate share_lbw_all = lbw_births/all_births
	sum share_lbw_all, detail
	assert share_lbw_all<1 
	assert share_lbw_all>0 

*(7) assess data quality

*rates of missing by county						// checking county level rates of missing birthweight data
generate share_miss = 1-(nomiss_births/all_births)
	sum share_miss, detail						// highest county-level rate of missing: 3.8% - does not warrant change in quality flag
	
*difference by denominator						// assessing how different share lbw is between the two denominators	
generate miss_diff = share_lbw_nomiss - share_lbw_all
	sum miss_diff, detail						// greatest county-level difference when omitting births with missing data: 0.2% - not concerning
	
*generate data quality flag						// based on whether metric is county level (quality score = 1) or pooled across all small counties (quality score = 3)
gen lbw_quality = .
	replace lbw_quality = 1 if unidentified_county_flag==.		// assigning a quality score of 1 to all counties *not* flagged as "unassigned counties"
	replace lbw_quality = 3 if unidentified_county_flag==1		// assigning a quality score of 3 to all counties flagged as "unassigned counties"
		label var lbw_quality "share low birthweight births: quality flag"

*(8) construct 95 percent confidence intervals
* note: confidence intervals are constructed following the User Guide to the 2010 Natality Public Use File, linked in the README and saved on Box 	
* for more information, see README

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


* (9) final file cleaning and export to csv file
keep year state county share_lbw_nomiss lbw_lb lbw_ub lbw_quality	// keep only variables needed for final file
	rename share_lbw_nomiss lbw							// final name		
		label var lbw "share low birth weight births among births with nonmissing birth weight data"
		label var lbw_lb "share low birthweight births: lower bound 95 percent confidence interval"
		label var lbw_ub "share low birthweight births: upper bound 95 percent confidence interval"
	format lbw %04.2f									// formate to include leading zero and limit to two decimal places per guidance 
	format lbw_lb  %04.2f								// formate to include leading zero and limit to two decimal places per guidance
	format lbw_ub  %04.2f								// formate to include leading zero and limit to two decimal places per guidance
order year state county lbw lbw_lb lbw_ub lbw_quality	// order
sort year state county

save "$gitfolder\04_health\data\neonatal_health.dta", replace
export delimited using "$gitfolder\04_health\final_data\neonatal_health.csv", replace
