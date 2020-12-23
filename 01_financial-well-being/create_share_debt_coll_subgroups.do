************************************************
*Creating Mobility from Poverty Delinquent Debt Dataset*

*Original data: Debt in America 2018 delinquent debt data (add github file path when have)
*Description: Replicate existing measure of share with debt in collections by majority white and majority oc color communities
*Author: Alex Carther
*Last updated: 12.21.20
*Uses StataMP 16
************************************************


*Setting directory
global raw "H:" //directory should be Box folder with raw data (https://urbanorg.app.box.com/folder/121120671765)
global output "H:" //directory should be Box folder with Debt in America outputs (https://urbanorg.app.box.com/folder/118598368099)
global o_o_exper_data_temp "\\STATA3\O&O_Experian\Debt in America\2019\Temp Files" //directory for credit bureau data 
*NOTE: This data is raw credit bureau microdata and cannot be uploaded to Box per our contract; this data must remain on and be accessed via STATA3.

****IMPORTING COUNTY CROSSWALK*****

*Importing 2018 county crosswalk file from GitHub
	import delimited "$raw/county-file.txt", stringcols(_all) clear
	//file downloaded from Github at "/geographic-crosswalks/data/county-file.csv"
	*Keeping relevant year
		keep if year=="2018"
		
	*Destring numerical vars
	foreach var of varlist year state county {
	destring `var', replace
	}
	
	*Format to include leading zeros
	format year %04.0f
	format state %02.0f
	format county %03.0f
	
	save "$raw/county-file.dta", replace



*****CREATING 95% CONFIDENCE INTERVAL VARS*****
clear




*Open base data and creaste temp vars
	*open working version of microdata:
	use "$o_o_exper_data_temp\debt01a 2018.dta", clear
		gen  zipcode = ZIP_CD
		tostring year, replace format (%09.0f)
		merge m:1 zipcode using "$o_o_exper_data_temp\debt03ACS_zip.dta"
		tab _merge, m
	*drop ACS data with no zips:
		drop if _merge == 2
		drop _merge
		
		
	*Keep debt in collections + race data
		keep totcollbin county_fips_fixed whitenh_catsd
		
	*Gen totcollbin by race
		rename totcollbin totcollbin_all
			*Note: whitenh_catsd has the following categories: 1: <40% white; 2: 59% white; 3: 60% + white
		gen totcollbin_w = .
			replace totcollbin_w = totcollbin_all if whitenh_catsd == 3
		gen totcollbin_nw = .
			replace totcollbin_nw = totcollbin_all if whitenh_catsd == 1
	
	*Check means are reasonable
	mean totcollbin_w
	mean totcollbin_nw
	
	*Duplicate vars for standard error collapse
	gen stdm_totcollbin_all= totcollbin_all
	gen stdm_totcollbin_w = totcollbin_w
	gen stdm_totcollbin_nw = totcollbin_nw
	
	gen obs_all=1
	gen obs_w=.
	gen obs_nw=.
	replace obs_w=1 if totcollbin_w != .
	replace obs_nw=1 if totcollbin_nw != .


	collapse (mean) totcollbin* (semean) stdm_totcollbin* (sum) obs* , by( county_fips_fixed) 

	drop if county_fips_fixed==""
	
	
save "$output\sharedebt_temp.dta", replace
	
	*We did not identify the county fips code of 3,956 consumers out of more than 5 million in the data
	//either because the credit bureau data does not provide the appropriate county information for these consumers
	//or because they live in PETERSBURG, ALASKA, a county equivalent which was recently created and could not be incorporated into our analysis
	//In the future versions of Debt in America we hope to improve this issue
	
	
*Create individual files for all, white, non-white communities

foreach v in _all _w _nw {
	
use "$output\sharedebt_temp.dta", clear
	
*SUPPRESS n < 50
	
	replace totcollbin`v' = . if obs`v'<50
	replace stdm_totcollbin`v' = . if obs`v'<50


*Creating 95% confidence intervals 
	
	gen upper_95`v' = totcollbin`v' + 1.96*stdm_totcollbin`v'
	gen lower_95`v' = totcollbin`v' - 1.96*stdm_totcollbin`v'
	
	
*Setting 95% lower bounds to be equal to zero if lower than zero
	
	foreach var of varlist upper_95`v' lower_95`v' {
		replace `var' = 0 if `var' < 0
	}

	rename county_fips_fixed county_fips

save "$output/county_coll_95_inter`v'.dta",replace

	
	
*Importing Debt in America data
	import excel "$raw/Overall_Delinquent_Debt_county.xlsx", sheet("Sheet1") allstring firstrow case(l) clear
		rename state state_name
		rename fullcountynamefromcensus county_name
		rename countyfips county_fips

	*Merging in confidence intervals
		merge 1:1 county_fips using "$output/county_coll_95_inter`v'.dta"
		drop if _merge==2
		//Drops 2 counties in Alaska which are no longer in use
		
		
	*Breaking down countyfips into separate state and county variables per data standards
		gen state = substr(county_fips, 1,2)
		gen county = substr(county_fips, 3,5)

		drop county_fips _merge
		

*Cleaning variable and reformatting missing observations
	
	rename totcollbin`v' share_debt_coll`v'
	rename upper_95`v' share_debt_coll_ub
	rename lower_95`v' share_debt_coll_lb
	

*Destring and format for leading zeros
	*Destring string vars
		foreach var of varlist state county {
		destring `var', replace
		}	
	
	*Format numeric vars
		format state %02.0f
		format county %03.0f
		foreach var of varlist share_debt*  {
			format `var' %8.7f
		}

	*Keeping relevant variables
	keep state county share_debt_coll* obs* county_name

*Merging with county crosswalk to add any missing counties
	merge 1:1 county state using "$raw/county-file.dta"
	list county if _merge==2
	//6 counties added
	assert _merge==3 if share_debt_coll`v' != .
	//all counties with data should be matched
	duplicates report state county
	//should not have any duplicates
	
*Adding quality flag

		gen share_debt_coll_quality=.
		replace share_debt_coll_quality= 1 if obs`v' >= 50 &obs`v'!=.
		replace share_debt_coll_quality= 3 if obs`v' < 50 | obs`v'==. | _merge == 2 
		replace share_debt_coll_quality= . if obs`v'==. & share_debt_coll`v'==.
		tab share_debt_coll_quality, m
			//6 missing (added counties from merge)

*Creating subgroup tag
gen subgroup = "`v'"	

*Save
save "$output\share_debt_coll`v'", replace
}

*Appending to make data long
use "$output\share_debt_coll_all"
append using "$output\share_debt_coll_w"
append using "$output\share_debt_coll_nw"


*Subgroup indicator
gen subgroup_type = "race-ethnicity"

*Creating numeric variable to identify subgroups
replace subgroup = "1" if subgroup=="_all"
replace subgroup = "2" if subgroup=="_nw"
replace subgroup = "3" if subgroup=="_w"

destring subgroup, replace
label define race 1 "All" 2 "Majority non-white" 3 "Majority white"
label values subgroup race
tab subgroup

*Creating share_debt_coll measure overall with all 3 subgroups
gen share_debt_coll=.
replace share_debt_coll = share_debt_coll_all if subgroup==1
replace share_debt_coll = share_debt_coll_nw if subgroup==2
replace share_debt_coll = share_debt_coll_w if subgroup==3


*Ordering and sorting data
	drop state_name population obs* _merge share_debt_coll_all share_debt_coll_nw share_debt_coll_w
	order year state county share_debt_coll
	sort year state county
	
*Exporting as CSV
	export delimited using "$output\share_debt_2018_long.csv", datafmt replace //Exporting as display format to retain leading zeros
