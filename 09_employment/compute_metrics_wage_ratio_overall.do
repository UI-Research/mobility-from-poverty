/***************************
This file imports the QCEW data and exports average weekly wage for each county and industry subgroups. It merges MIT Living Wage data onto QCEW data and calculates the living wage ratio metric, and generates quality measures. 

****These metrics are for OVERALL, subgroup specific metrics are generated in a separate do file.****

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary). Save the file as a CSV UTF-8 titled "YEAR_data.csv". Years 2015 to 2023 are covered in this current file.

The overall county metric was originally programmed by Kevin Werner + this file was further developed by Kassandra Martinchek in 2024 and 2025, including adding additional years and programming the metrics across years.

Current update date: 12/10/2024

To dos:
** Need 2023 data from MIT to finalize this update. For 2023, will need to make the CT planning region correction and possibly the Alaska correction.
** Implement file deletion step
** Add QC code
** Combine overall and subgroup do files? -- REQUIRES HARMONIZATION

****************************/


/***** update these directories *****/
global raw "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global wages "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\09_employment"
global crosswalk "C:\Users\KMartinchek\Documents\upward-mobility-2025\mobility-from-poverty\geographic-crosswalks\data"

/***** save living wage as .dta *****/

foreach year in 2015 2016 2017 2018 2019 2020 2021 {
	
	clear
	cd `wages'
	import delimited using "mit-living-wage.csv", clear // remember the MIT data here is 2019 (important for inflation/deflation step later)

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage
			replace wage_adj = wage *  251.107/255.657 if year == 2018
			replace wage_adj = wage *  245.120/255.657 if year == 2017
			replace wage_adj = wage *  240.007/255.657 if year == 2016
			replace wage_adj = wage *  237.017/255.657 if year == 2015
			
			replace wage_adj = wage *  258.811/255.657 if year == 2020
			replace wage_adj = wage *  270.970/255.657 if year == 2021

	save "mit_living_wage-`year'.dta", replace 

}

foreach year in 2022 {
	
	clear
	cd `wages'
	import delimited using "mit-living-wage-2022.csv", clear // remember the MIT data here is 2022 

	replace year = `year' // correct to proper year
	
	/* only keep 1 adult, 2 children row */
	keep if adults == "1 Adult" & children == "2 Children"
	
		/* inflate/deflate MIT data, depending on year */
		** using the first table from here (CPI-U, US City Average, Annual Average column): https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm 
		generate wage_adj = wage

	save "mit_living_wage-`year'.dta", replace 

}

/***** import QCEW data *****/

foreach year in 2015 2016 2017 2018 2019 2020 2021 2022 {
	
	clear
	cd `raw'
	import delimited using "`year'_data.csv", numericcols(14 15 16 17 18) varnames(1) clear

	/* keep only county totals */
	keep if areatype == "County" & ownership == "Total Covered"

	keep st cnty annualaverageweeklywage annualaverageestablishmentcount

	rename st state

	rename cnty county

	destring state, replace // make numeric for merging with MIT data
	
	save "temp-qecw-`year'.dta", replace 
	
}

/* merge living wage and QCEW data */

foreach year in 2015 2016 2017 2018 2019 2020 2021 2022 {
	
	clear
	cd `raw'
	use "temp-qecw-`year'.dta", clear
	
	merge 1:m state county using "mit_living_wage-`year'.dta"

	di `year'
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

/* calculate the metric */ 

foreach year in 2015 2016 2017 2018 2019 2020 2021 2022 {

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

	/* test flag */
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
	drop if state == "09" & (county == "001" | county == "003" | county == "005" | county == "007" | county == "009" | county == "011" | county == "013" | county == "015") & year == 2022
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "09"
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "09"
	
	/* Alaska adjustment in 2020 and 2021 and 2022 */
	drop if state == "02" & county == "261" & (year == 2020 | year == 2021 | year == 2022) 
	
	replace ratio_living_wage = "NA" if ratio_living_wage == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)
	replace ratio_living_wage_quality = "NA" if ratio_living_wage_quality == "" & state == "02" & (county == "063" | county == "066") & (year == 2021 | year == 2020 | year == 2022)
	
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

/* merge into one file and export */
use "wage_ratio_final_2015.dta", clear
	append using "wage_ratio_final_2016.dta"
	append using "wage_ratio_final_2017.dta"
	append using "wage_ratio_final_2018.dta"
	append using "wage_ratio_final_2019.dta"
	append using "wage_ratio_final_2020.dta"
	append using "wage_ratio_final_2021.dta"
	append using "wage_ratio_final_2022.dta"

save "wage_ratio_overall_allyears.dta", replace

// final count
count // should be 25,140 thru 2022 and 28,284 thru 2023

export delimited using "metrics_wage_ratio_overall.csv", replace	
	
/* delete unneeded files -- do this as a last step */
/*
erase "wage_ratio_final_*.dta"
erase "temp-merged-*.dta"
erase "temp-qecw-*.dta"
*/