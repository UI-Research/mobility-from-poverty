/***************************
This file imports the QCEW data and exports average weekly wage for each county and industry subgroups. It merges MIT Living Wage data onto QCEW data and calculates the living wage ratio metric, and generates quality measures. 

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary). Save the file as a CSV UTF-8 titled "YEAR_data.csv". Years 2014, 2018, 2021, 2022, and 2023 are covered in this current file.

The overall county metric was originally programmed by Kevin Werner + this file was further developed by Kassandra Martinchek in 2024 and 2025, including adding additional years, programming the metrics across years, and adding subgroups.

Current update date: 3/6/2025

****************************/
*/

ssc install distinct

/***** update these directories *****/
global raw "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global wages "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global crosswalk "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\geographic-crosswalks\data"

/*
Read data  

The data from MIT and QECW cannot be easily read directly into this program. 

Before running, please download the files below from the following [Box folder] https://urbanorg.app.box.com/folder/298586735341 into the repository folder  

"mobility-from-poverty\09_employment"

Import all the files in the Box folder here.

*/

/***** save living wage as .dta *****/

foreach year in 2014 2018 {
	
	clear
	import delimited using "$wages/mit-living-wage.csv", clear // remember the MIT data here is 2019 (important for inflation/deflation step later)

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage
			replace wage_adj = wage *  251.107/255.657 if year == 2018
			replace wage_adj = wage *  236.736/255.657 if year == 2014

		/* duplicates are an issue here because they repeat two counties */	
		duplicates report state county
		duplicates tag state county, generate(dup_tag)
		
		bysort state county (dup_tag): keep if (_n == 1 & dup_tag == 1) | dup_tag == 0 // doesn't work, deletes all observations
		drop dup_tag
		
	save "mit_living_wage-`year'.dta", replace 

}

foreach year in 2021 2022 {
	
	clear
	import delimited using "$wages/mit-living-wage-2022.csv", clear // remember the MIT data here is 2022 

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage 
			replace wage_adj = wage if year == 2022 // no need to deflate 2022 data because this is the data year
			replace wage_adj = wage * 270.970/288.347 if year == 2021
		
		duplicates report state county

	save "mit_living_wage-`year'.dta", replace 

}

foreach year in 2023 {
	
	clear
	import delimited using "$wages/mit-living-wage-2023.csv", clear // remember the MIT data here is 2023 
	mdesc hourly_living_wage // check missingness

	replace year = `year' // correct to proper year
	
	/* we only have 1 adult, 2 children data and don't need to make inflation adjustment for this year but need to align variables */

		generate wage_adj = hourly_living_wage
		
		rename county_fips_short county
		rename state_fips state
		keep year county state wage_adj
		
		duplicates report state county

	save "mit_living_wage-`year'.dta", replace 

}

/***** import QCEW data *****/

*** overall
foreach year in 2014 2018 2021 2022 2023 {
	
	clear
	import delimited using "$raw/`year'_data.csv", numericcols(14 15 16 17 18) varnames(1) clear

	/* keep only county totals */
	keep if areatype == "County" & ownership == "Total Covered"

	keep st cnty annualaverageweeklywage annualaverageestablishmentcount

	rename st state

	rename cnty county

	destring state, replace // make numeric for merging with MIT data
	
	di `year'
	mdesc // check missingness -- high missingness could indicate an error
	
	save "temp-qecw-`year'.dta", replace 
	
}

*** subgroup: industry
foreach year in 2014 2018 2021 2022 2023 {
	
	import delimited using "$raw/`year'_data.csv", numericcols(14 15 16 17 18) varnames(1) clear
	
	/* keep industry level data and create subgroups */
	keep if areatype == "County" 

	** recode industries into MM categories
		// see ownership codes here (own variable): https://www.bls.gov/cew/classifications/ownerships/ownership-titles.htm 
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

*** overall
foreach year in 2014 2018 2021 2022 2023 {
	
	clear
	use "$raw/temp-qecw-`year'.dta", clear
	
	merge 1:m state county using "mit_living_wage-`year'.dta"

	di `year'
	di "overall"
	tab county state if _merge == 1 

	/* drop statewide obs because we are calculating metrics at the county level, 999 county is statewide observations */
	drop if _merge == 1 & county == 999
	
	/* drop duplicates (first two counties repeated) */
	duplicates drop

	/* check observations and cross reference with the required numbers in the Wiki -- there will be some inconsistencies at this stage until we make final county corrections in the next loop -- this is just to check what adjustments could be needed */
	tab year
	count 

	save "temp-merged-`year'.dta", replace
}
	
*** subgroup: industry	
foreach year in 2014 2018 2021 2022 2023 {
	
	clear
	use "$wages/temp-qecw-industry-`year'.dta", clear
	duplicates report state county industry_type // want 0 surplus
	
	merge m:1 state county using "$wages/mit_living_wage-`year'.dta"

	/* test the merge */
	di `year'
	tab county state if _merge == 1 
	** Alaska non-merge is as expected, in 2015 there are some additional non-merges (county 113 and 270) but these are corrected
	
	save "$wages/temp-merged-industry-`year'.dta", replace

}


/* calculate metric and quality flag */ 

*** overall 
foreach year in 2014 2018 2021 2022 2023 {
	clear
	use "temp-merged-`year'.dta", clear

	/* convert living hourly wage to weekly */
	gen weekly_living_wage = wage_adj * 40

	/* get ratio (main metric) */
	gen ratio_living_wage = annualaverageweeklywage/weekly_living_wage

	/* create data quality flag 
	per discussion with Greg, >= 30 is 1, <30 is 3 */
	gen ratio_living_wage_quality = 1 if annualaverageestablishmentcount >= 30 & annualaverageestablishmentcount != .
	replace ratio_living_wage_quality = 3 if annualaverageestablishmentcount < 30 & annualaverageestablishmentcount != .
	replace ratio_living_wage_quality = . if annualaverageestablishmentcount == .

	/* tab quality */
	tab ratio_living_wage_quality, missing
	
	/* put state and county in string with leading 0s */
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

	keep state county year ratio_living_wage ratio_living_wage_quality

	save "wage_ratio_final_`year'.dta",replace

	** add in county name and state name
	import delimited using "$crosswalk\county-populations.csv", stringcols(2 3 4 5) varnames(1) clear

	merge 1:1 year state county using "wage_ratio_final_`year'.dta"

	keep if year == `year'
	
	/* connecticut adjustment in 2022 and 2023 -- zero out CT new planning regions because we don't have data on them, as MIT and QECW data is reported for old counties */
	drop if state == "09" & (county == "001" | county == "003" | county == "005" | county == "007" | county == "009" | county == "011" | county == "013" | county == "015") & (year == 2022 | year == 2023)
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "09"
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "09"
	
	/* Alaska adjustment in 2021 and 2022 */
	drop if state == "02" & county == "261" & (year == 2021 | year == 2022) 
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)
	
	*** assert 
	assert ratio_living_wage_quality == "NA" if ratio_living_wage == "NA"
	
	/* export final dataset -- by year */
	keep year state county ratio_living_wage ratio_living_wage_quality
	order year state county ratio_living_wage ratio_living_wage_quality

	export delimited using "metrics_wage_ratio_`year'.csv", replace

	save "wage_ratio_final_`year'.dta", replace

	/* count obs -- this should match the Wiki numbers for each year */
	tab year
	count
	
}

*** subgroup: industry
foreach year in 2014 2018 2021 2022 2023 {
	
	use "$wages/temp-merged-industry-`year'.dta", clear
	drop _merge	
	
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

	/* tab quality */
	tab ratio_living_wage_quality, missing

	/* put state and county in string with leading 0s */
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
	drop if state == "09" & (county == "001" | county == "003" | county == "005" | county == "007" | county == "009" | county == "011" | county == "013" | county == "015") & (year == 2022 | year == 2023)
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "09" & (year == 2022 | year == 2023)
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "09" & (year == 2022 | year == 2023)
	replace subgroup_type = 1 if state == "09" & (year == 2022 | year == 2023)
	replace subgroup = 1 if state == "09" & (year == 2022 | year == 2023)
	
	/* Alaska adjustment in 2021 and 2022 */
	drop if state == "02" & county == "261" & (year == 2021 | year == 2022) 
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)

	replace subgroup_type = 1 if state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)
	replace subgroup = 1 if state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2022)
	
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

	fillin fips_code subgroup // this ensures that there is a row for each industry for each county to create a balanced dataset

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

*** overall
{
use "$wages/wage_ratio_final_2014.dta", clear
	append using "wage_ratio_final_2018.dta"
	append using "wage_ratio_final_2021.dta"
	append using "wage_ratio_final_2022.dta"
	append using "wage_ratio_final_2023.dta"

save "$wages/wage_ratio_overall_allyears.dta", replace

// final counts
count // should be 15,715
bysort year: count

*** assert 
assert ratio_living_wage_quality == "NA" if ratio_living_wage == "NA"

bysort year: count if ratio_living_wage == "NA"

// export final file
export delimited using "$wages/data/final/living_wage_county_all_longitudinal.csv", replace

// summarize the final variable -- need to make some changes before doing so
gen living_wage_test = ratio_living_wage
	replace living_wage_test = "" if ratio_living_wage == "NA"
	destring living_wage_test, replace

hist living_wage_test
summarize living_wage_test, detail	
}

*** subgroup: industry
{
use "$wages/wage_ratio_final_2014_subgroup.dta", clear
	append using "$wages/wage_ratio_final_2018_subgroup.dta"
	append using "$wages/wage_ratio_final_2021_subgroup.dta"
	append using "$wages/wage_ratio_final_2022_subgroup.dta"
	append using "$wages/wage_ratio_final_2023_subgroup.dta"

save "$wages/wage_ratio_overall_allyears_subgroup.dta", replace

// final counts
distinct state county subgroup, joint // to confirm there are 8 obs for county
count // should be 15,715 (times 8!) so 125,720
bysort year: count

*** assert 
assert ratio_living_wage_quality == "NA" if ratio_living_wage == "NA"

bysort year: count if ratio_living_wage == "NA"

// export final dataset
export delimited using "$wages/data/final/living_wage_county_industry_longitudinal.csv", replace	

// summarize the final variable -- need to make some changes before doing so
gen living_wage_test = ratio_living_wage
	replace living_wage_test = "" if ratio_living_wage == "NA"
	destring living_wage_test, replace

hist living_wage_test
bysort subgroup: summarize living_wage_test, detail	
}

/* delete unneeded files -- do this as a last step */
erase "$wages\wage_ratio_overall_allyears.dta"
erase "$wages\wage_ratio_overall_allyears_subgroup.dta"

foreach year in 2014 2018 2021 2022 2023 {
	erase "$wages\wage_ratio_final_`year'.dta"
	erase "$wages\wage_ratio_final_`year'_subgroup.dta"
	erase "$wages\temp-merged-`year'.dta"
	erase "$wages\temp-merged-industry-`year'.dta"
	erase "$wages\temp-qecw-`year'.dta"
	erase "$wages\temp-qecw-industry-`year'.dta"
	erase "$wages\metrics_wage_ratio_`year'.csv"
	erase "$wages\metrics_wage_ratio_`year'_subgroup.csv"
	erase "$wages\mit_living_wage-`year'.dta"
}