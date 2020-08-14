************************************************
*Creating Mobility from Poverty Delinquent Debt Dataset*

*Original data: Debt in America 2018 delinquent debt data (add github file path when have)
*Description: Reformat data to match code standards; merge in 95% confidence interval data; merge to county crosswalk to add any missing counties
*Author: Alex Carther
*Last updated: 8/6/20
*Uses StataMP 16
************************************************


*Setting directory
local dir "H:\"

*Importing 2018 county crosswalk file from GitHub
	import delimited "https://raw.githubusercontent.com/UI-Research/gates-mobility-metrics/master/geographic-crosswalks/data/county-file.csv?token=AQLEERC7OEPEDIALLMXB4ZS7H7T6I", stringcols(_all) clear
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
	
	save "`dir'/county-file.dta", replace

*Importing Debt in America data
	import excel "H:\Overall_Delinquent_Debt_county.xlsx", sheet("Sheet1") allstring firstrow case(l) clear
		rename state state_name
		rename fullcountynamefromcensus county_name
		rename countyfips county_fips

	*Merging in confidence intervals
		merge 1:1 county_fips using "`dir'/county_coll_95_inter.dta"
		drop if _merge==2
		//Drops 2 counties in Alaska which are no longer in use
		
		
	*Breaking down countyfips into separate state and county variables per data standards
		gen state = substr(county_fips, 1,2)
		gen county = substr(county_fips, 3,5)

		drop county_fips _merge
		

*Cleaning variable and reformatting missing observations
	rename sharewithanydebtincollectio share_debt_coll
	replace share_debt="" if share_debt=="n/a*"
	rename upper_95 share_debt_coll_ub
	rename lower_95 share_debt_coll_lb

*Destring and format for leading zeros
	*Destring string vars
		foreach var of varlist state county share_debt_coll {
		destring `var', replace
		}	
	
	*Format numeric vars
		format state %02.0f
		format county %03.0f
		foreach var of varlist share_debt* totcollbin {
			format `var' %8.7f
		}

	*Checking merge
	assert inrange(totcollbin, share_debt_coll-.0000001, share_debt_coll+0.0000001) | share_debt_coll==. | totcollbin==.
	//Should be true; this is the same variable in both original data and confidence interval file. Using inrange as share_debt is rounded up one decimal place from totcollbin. Using to check merge.

	*Keeping relevant variables
	keep state county share_debt_coll share_debt_coll_lb share_debt_coll_ub

*Merging with county crosswalk to add any missing counties
	merge 1:1 county state using "`dir'/county-file.dta
	list county if _merge==2
	//6 counties added
	assert _merge==3 if share_debt_coll != .
	//all counties with data should be matched
	duplicates report state county
	//should not have any duplicates
	
*Ordering and sorting data
	drop state_name county_name population _merge
	order year state county share_debt_coll
	sort year state county

*Exporting as CSV
	export delimited using "`dir'\share_debt_2018.csv", datafmt replace
	//Exporting as display format to retain leading zeros

