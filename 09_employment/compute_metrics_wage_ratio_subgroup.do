/***************************
This file imports the QCEW data and exports average weekly wage for each county and industry subgroups. It merges MIT Living Wage data onto QCEW data and calculates the living wage ratio metric, and generates quality measures.

****These metrics are for INDUSTRY SUBGROUPS, OVERALL metrics are generated in a separate do file.****

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary). Save the file as a CSV UTF-8 titled "YEAR_data.csv". Years 2015 to 2023 are covered in this current file.

The overall county metric was originally programmed by Kevin Werner + this file was further developed by Kassandra Martinchek in 2024 and 2025, including adding industry subgroups and additional years.

Current update date: 12/11/2024

To dos:
** Need 2023 data from MIT to finalize this update. For 2023, will need to make the CT planning region correction and possibly the Alaska correction.
** Implement file deletion step
** Add QC code
** Combine overall and subgroup do files? -- REQUIRES HARMONIZATION

****************************/

*** uncomment command below to install package if needed
*ssc install distinct

*** update these directories
global raw "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global wages "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global crosswalk "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\geographic-crosswalks\data"


/***** save living wage as .dta *****/
*** this is the same as the overall file -- could cut this code and suggest running the other do file first (or combine do files)
*** I made updates here that would need to be harmonized with the other do-file

foreach year in 2015 2016 2017 2018 2019 2020 2021 {
	
	clear
	import delimited using "$wages/mit-living-wage.csv", clear // remember the MIT data here is 2019 (important for inflation/deflation step later)

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
	/* drop duplicates (two counties repeated) */
	duplicates tag state county, generate(tag)
	tab state county if tag == 1
	duplicates drop
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage
			replace wage_adj = wage *  251.107/255.657 if year == 2018
			replace wage_adj = wage *  245.120/255.657 if year == 2017
			replace wage_adj = wage *  240.007/255.657 if year == 2016
			replace wage_adj = wage *  237.017/255.657 if year == 2015
			
			replace wage_adj = wage *  258.811/255.657 if year == 2020
			replace wage_adj = wage *  270.970/255.657 if year == 2021

	save "$wages/mit_living_wage-`year'.dta", replace 

}

foreach year in 2022 {
	
	clear
	import delimited using "$wages/mit-living-wage-2022.csv", clear // remember the MIT data here is 2022 

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
	/* drop duplicates (two counties repeated) */
	duplicates tag state county, generate(tag)
	tab state county if tag == 1
	duplicates drop
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage

	save "$wages/mit_living_wage-`year'.dta", replace 

}

/***** import QCEW data *****/

foreach year in 2015 2016 2017 2018 2019 2020 2021 2022 2023 {
	import delimited using "$raw/`year'_data.csv", numericcols(14 15 16 17 18) varnames(1) clear
	
	/* keep industry level data and create subgroups */
	keep if areatype == "County" 

	** recode industries into MM categories
	generate industry_type = .
		replace industry_type = 1 if naics == 10 & own == 0 // all
		replace industry_type = 2 if naics == 101 // goods producing
		replace industry_type = 3 if naics == 10 & (own == 1 | own == 2 | own == 3) // public admin
		replace industry_type = 4 if naics == 1021 // trade transit utilities
		replace industry_type = 5 if naics == 1022 // info services
		replace industry_type = 6 if naics == 1023 | naics == 1024 // financial, prof, biz services
		replace industry_type = 7 if naics == 1025 // ed/health
		replace industry_type = 8 if naics == 1026 | naics == 1027 // leisure/hospitality/other
		
	** variable labels 
	label define industry_labels_mm 1 "All" 2 "Goods Producing" 3 "Public Administration" 4 "Trade, Transit, Utilities" 5 "Information Services" 6 "Professional Services" 7 "Education and Health" 8 "Leisure and Other"

	label values industry_type industry_labels_mm
	
	// for 2022 codes: https://www.bls.gov/cew/classifications/industry/industry-titles.htm 
	tab naics if industry_type == .
	
	assert (naics == 10 | naics == 102 | naics == 1011 | naics == 1012 | naics == 1013 | naics == 1029) if industry_type == .
	
	drop if industry_type == . // drop super-sections and "unclassified" naics codes 

	// make some adjustments to account for the status codes
	generate statuscode = 0
		replace statuscode = 1 if annualaveragestatuscode == "N" // recode non-reportable wages this way so can collapse multi-row industries correctly
		// confirm that there are the same number of 1's as N's
		tab statuscode, m
		tab annualaveragestatuscode, m
	
	** because some naics codes are combined into industries, we need to collapse
	** we average the average weekly wage across both
	** but sum the establishment counts 
	collapse (mean) avgwkwage=annualaverageweeklywage (sum) avgestct=annualaverageestablishmentcount (max) statuscode, by(st cnty industry_type)

	** check for duplicates, you want a surplus of 0
	duplicates report st cnty industry_type

	/* test whether all counties have needed codes-- answer is no, which means need to do data expansion later on */ 
	egen obs_per_cnty = count(industry_type), by(st cnty)
	tab obs_per_cnty
	
	// drop statewide observations-- not needed // 
	drop if cnty == 999

	** count zeros -- and confirm zero wages are supressed according to BLS data suppression guidelines for non-reportable wages
	count if avgwkwage == 0
	assert statuscode == 1 if avgwkwage == 0

	** keep variables pre-merge

	keep st cnty avgwkwage avgestct industry_type statuscode

	rename st state

	rename cnty county

	destring state, replace // make numeric for merging with MIT data

	// save out for merge
	save "$wages/temp-qecw-industry-`year'.dta", replace

}


/* merge living wage and QCEW data */
foreach year in 2015 2016 2017 2018 2019 2020  2021 2022 {
	
	clear
	use "$wages/temp-qecw-industry-`year'.dta", clear
	
	merge m:1 state county using "$wages/mit_living_wage-`year'.dta"

	/* test the merge */
	di `year'
	tab county state if _merge == 1 
	** Alaska non-merge is as expected, in 2015 there are some additional non-merges (county 113 and 270) but these are corrected
	
	save "$wages/temp-merged-industry-`year'.dta", replace

}

/* generate metric and quality metric */
foreach year in 2015 2016 2017 2018 2019 2020 2021 2022 {
	
	use "$wages/temp-merged-industry-`year'.dta", clear
		
	/* convert living hourly wage to weekly */
	gen weekly_living_wage = wage * 40

	/* get ratio (main metric) */
	gen ratio_living_wage = avgwkwage/weekly_living_wage

	** then, replace ratio as missing due to BLS data suppression
	replace ratio_living_wage = . if statuscode == 1

	count if ratio_living_wage == 0 // confirm this replacement worked, this count should be 0

	/* create data quality flag 
	per discussion with Greg, >= 30 is 1, <30 is 3 and those with missing metrics due to BLS suppression and lack of industry (no establishments) are missing */
	gen ratio_living_wage_quality = 1 if avgestct >= 30 & avgestct != .
	replace ratio_living_wage_quality = 3 if avgestct < 30 & avgestct != .
	replace ratio_living_wage_quality = . if avgestct == .
	replace ratio_living_wage_quality = . if statuscode == 1

	/* test flag */
	tab ratio_living_wage_quality, missing

	/* put state and county in string with leading 0s */
	drop _merge

	** generate county name and state name
	gen new_state = string(state,"%02.0f")
	drop state
	rename new_state state

	gen new_county= string(county,"%03.0f")
	drop county
	rename new_county county

	gen new_ratio = string(ratio_living_wage)
	drop ratio_living_wage
	rename new_ratio ratio_living_wage

	/* replace 0 ratio with missing and replace data quality as missing */
	replace ratio_living_wage = "NA" if ratio_living_wage == "."
	replace ratio_living_wage_quality = . if ratio_living_wage == "NA" /* changed this from data quality 3 */

	gen new_ratio_quality = string(ratio_living_wage_quality)
	drop ratio_living_wage_quality
	rename new_ratio_quality ratio_living_wage_quality

	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "."

	keep state county year ratio_living_wage ratio_living_wage_quality industry_type

	/* rename final variable here */
	rename industry_type subgroup

	generate subgroup_type = 1 if subgroup == 1
	replace subgroup_type = 2 if subgroup != 1

	label define subg_type_lab 1 "all" 2 "industry"

	label values subgroup_type subg_type_lab

	/* export files */

	order year state county subgroup_type subgroup ratio_living_wage ratio_living_wage_quality

	export delimited using "$wages/metrics_wage_ratio_`year'_subgroup.csv", replace

	save "$wages/wage_ratio_final_`year'_subgroup.dta",replace

	** add in county name and state name
	import delimited using "$crosswalk/county-populations.csv", stringcols(2 3 4 5) varnames(1) clear

	merge 1:m year state county using "$wages/wage_ratio_final_`year'_subgroup.dta"

	/* connecticut adjustment in 2022 and 2023 -- zero out CT new planning regions because we don't have data on them, as MIT and QECW data is reported for old counties */
	drop if state == "09" & (county == "001" | county == "003" | county == "005" | county == "007" | county == "009" | county == "011" | county == "013" | county == "015") & year == 2022
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "09" & year == 2022
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "09" & year == 2022
	replace subgroup_type = 1 if state == "09" & year == 2022
	replace subgroup = 1 if state == "09" & year == 2022
	
	/* Alaska adjustment in 2020 and 2021 and 2022 */
	drop if state == "02" & county == "261" & (year == 2020 | year == 2021 | year == 2022) 
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)

	replace subgroup_type = 1 if state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)
	replace subgroup = 1 if state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)
	
	*** assert 
	assert ratio_living_wage_quality == "NA" if ratio_living_wage == "NA"

	*** add subgroup labels
	label values subgroup_type subg_type_lab	
	label values subgroup industry_labels_mm

	/* export final dataset */
	keep if year == `year'

	*** fill in needed observations so each county has a row for each industry subgroup
	*** including gernating all needed variables for the newly generated rows
	egen fips_code = concat(state county)

	drop _merge
	tab subgroup, m

	replace subgroup = 1 if subgroup == .
	label values subgroup industry_labels_mm

	fillin fips_code subgroup

	bysort fips_code: generate state_b = state[1]
	bysort fips_code: generate county_b = county[1]
	bysort fips_code: generate state_name_b = state_name[1]
	bysort fips_code: generate county_name_b = county_name[1]

	** confirm all counties have 8 observations
	bysort fips_code: gen obs_number = _N
	tab obs_number, m

	drop state county state_name county_name
	rename state_b state
	rename county_b county
	rename state_name_b state_name
	rename county_name_b county_name

	replace year = `year'

	tab subgroup if _fillin == 1, m  // confirm no all values were filled in
	replace subgroup_type = 2 if _fillin == 1

	replace ratio_living_wage = "NA" if _fillin == 1
	replace ratio_living_wage_quality = "NA" if _fillin == 1 

	*** assert number of counties
	di `year'
	distinct state county, joint // to confirm there are the right number of counties in the dataset
	distinct state county subgroup, joint // to confirm there are 8 obs for county
	distinct state county subgroup if subgroup_type == 2, joint // to confirm there are 7 obs for each county
	
	count if missing(subgroup)
	count if missing(subgroup_type)

	*** format file
	keep year state county subgroup_type subgroup ratio_living_wage ratio_living_wage_quality
	order year state county subgroup_type subgroup ratio_living_wage ratio_living_wage_quality
	sort year state county subgroup

	*** save out file
	export delimited using "$wages/metrics_wage_ratio_`year'_subgroup.csv", replace
	save "$wages/wage_ratio_final_`year'_subgroup.dta", replace

}


/* merge into one file and export */
use "$wages/wage_ratio_final_2015_subgroup.dta", clear
	append using "$wages/wage_ratio_final_2016_subgroup.dta"
	append using "$wages/wage_ratio_final_2017_subgroup.dta"
	append using "$wages/wage_ratio_final_2018_subgroup.dta"
	append using "$wages/wage_ratio_final_2019_subgroup.dta"
	append using "$wages/wage_ratio_final_2020_subgroup.dta"
	append using "$wages/wage_ratio_final_2021_subgroup.dta"
	append using "$wages/wage_ratio_final_2022_subgroup.dta"

save "$wages/wage_ratio_overall_allyears_subgroup.dta", replace

// final counts
distinct state county subgroup, joint // to confirm there are 8 obs for county
count // should be 25,140 thru 2022 and 28,284 thru 2023 (times 8!) so 201,120 thru 2022 and 226,272 thru 2023

export delimited using "$wages/metrics_wage_ratio_subgroup.csv", replace	
	
/* delete unneeded files -- do this as a last step */
/*
erase "wage_ratio_final_*.dta"
erase "temp-merged-*.dta"
erase "temp-qecw-*.dta"
*/
*/
