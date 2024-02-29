/***************************
This file imports the 2023 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary)

Programmed by Kevin Werner + updated by Kassandra Martinchek in 2023, adding subgroups

2/12/2024

Living wage data is in 2022 dollars, so it is deflated. 
****************************/

local raw "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\09_employment"
local wages "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\09_employment"

/***** save living wage as .dta *****/
cd `wages'
import delimited using "mit-living-wage-2022.csv", clear // while in code review, please note that I did not change this, as updated data required a fee and there was a no-scraping notice

replace year = 2022 // correct to proper year

save "mit_living_wage-2022.dta", replace

/*
*inflate 2022 MIT to 2023 using BLS series CUUR0000SA0. Used first half for 2022, annual for 2021 (keeping this note for prior methods)
*because both 2022 and 2023 have full annual values, i use the annual here for both
*because QECW is not available annually for 2023 yet, will use 2022 data so likely won't need this inflation

replace wage = wage* 302.702/292.655 // 2023 CPI-U is first, then 2022 CPI-U	

save "mit_living_wage-2023.dta", replace
*/
clear

/***** import QCEW data *****/

cd `raw'

import delimited using "2022_data.csv", numericcols(14 15 16 17 18) varnames(1) clear

/* keep industry level data and assign to divisions */
keep if areatype == "County" & industry != "10 Total, all industries"

** recode industries into divisions
*gen new_industry= string(naics, "%04.0f")
generate division_d = .
	replace division_d = 1 if naics == 1011  // division a: ag, forestry, and fishing
	replace division_d = 2 if naics == 1021  // division b: mining
	replace division_d = 3 if naics == 1023  // division c: construction
	replace division_d = 4 if naics == 1031 | naics == 1032 | naics == 1033  // division d: manufacturing
	replace division_d = 5 if naics == 1022 | naics == 1048 | naics == 1049 | naics == 1056 // division e: transportation, comms, electric, gas +sanitary
	replace division_d = 6 if naics == 1042 // division f: wholesale trade
	replace division_d = 7 if naics == 1044 | naics == 1045 // division g: retail trade
	replace division_d = 8 if naics == 1052 | naics == 1053 // division h: finance, insurance and real estate
	replace division_d = 9 if naics == 1051 | naics == 1054 | naics == 1055 | naics == 1061 | naics == 1062 | naics == 1071 | naics == 1072 | naics == 1081 // division i: services
	replace division_d = 10 if naics == 1092 // division j: public admin

	** check for missing industries + ask claudia
	tab industry if division_d == .
	
** consolidated divisions for mobility metrics purposes
generate division_consol = .	
	replace division_consol = 1 if division_d == 1 | division_d == 2 // Division A: Agriculture, Forestry, And Fishing & Division B: Mining
	replace division_consol = 2 if division_d == 3 // Division C: Construction
	replace division_consol = 3 if division_d == 4 // Division D: Manufacturing
	replace division_consol = 4 if division_d == 5 // Division E: Transportation, Communications, Electric, Gas, And Sanitary Services
	replace division_consol = 5 if division_d == 6 | division_d == 7 // Division F: Wholesale Trade & Division G: Retail Trade
	replace division_consol = 6 if division_d == 8 // Division H: Finance, Insurance, And Real Estate
	replace division_consol = 7 if division_d == 9 // Division I: Services
	replace division_consol = 8 if division_d == 10 // Division J: Public Administration
	
** variable labels??

** keep variables pre-merge

keep st cnty annualaverageweeklywage annualaverageestablishmentcount division_consol

rename st state

rename cnty county

destring state, replace // make numeric for merging with MIT data

cd `wages'

/* merge living wage and QCEW data */
merge 1:m state county using mit_living_wage-2022.dta

*tab county state if _merge == 1*/// two AK counties missing from MIT data

/* drop statewide obs */
drop if _merge == 1

/* only keep 1 adult, 2 children row */
keep if adults == "1 Adult" & children == "2 Children"

/* drop duplicates (first two counties repeated) */
duplicates drop

/* convert living hourly wage to weekly */
gen weekly_living_wage = wage * 40

/* get ratio (main metric) */
gen average_to_living_wage_ratio = annualaverageweeklywage/weekly_living_wage

/* create data quality flag 
per discussion with Greg, >= 30 is 1, <30 is 3 */
gen wage_ratio_quality = 1 if annualaverageestablishmentcount >= 30 & annualaverageestablishmentcount != .
replace wage_ratio_quality = 3 if annualaverageestablishmentcount < 30 & annualaverageestablishmentcount != .
replace wage_ratio_quality = . if annualaverageestablishmentcount == .

/* test flag */
tab wage_ratio_quality, missing

/* put state and county in string with leading 0s */
gen new_state = string(state,"%02.0f")
drop state
rename new_state state

gen new_county= string(county,"%03.0f")
drop county
rename new_county county

/* check ratio */
/*sum average_to_living_wage_ratio, det
hist average_to_living_wage_ratio */
/*tab county state if average_to_living_wage_ratio == 0 */

gen new_ratio = string(average_to_living_wage_ratio)
drop average_to_living_wage_ratio
rename new_ratio average_to_living_wage_ratio

/* replace 0 ratio with missing and replace data quality as missing */
replace average_to_living_wage_ratio = "NA" if average_to_living_wage_ratio == "."
replace wage_ratio_quality = 3 if average_to_living_wage_ratio == "NA"

save "wage_ratio_final_2022.dta",replace


keep state county year average_to_living_wage_ratio wage_ratio_quality

/* rename final variable here */

rename ratio_average_to_living_wage average_to_living_wage_ratio

/* export files */

order year state county average_to_living_wage_ratio wage_ratio_quality

export delimited using metrics_wage_ratio_2022.csv, replace