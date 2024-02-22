/***************************
This file imports the 2022 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary)

Programmed by Kevin Werner + updated by Kassandra Martinchek in 2023

2/7/2024

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

/* keep only county totals */
keep if areatype == "County" & ownership == "Total Covered"

keep st cnty annualaverageweeklywage annualaverageestablishmentcount

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

*rename ratio_average_to_living_wage average_to_living_wage_ratio
rename wage_ratio_quality ratio_living_wage_quality

/* export files */

order year state county average_to_living_wage_ratio ratio_living_wage_quality

export delimited using metrics_wage_ratio_2022.csv, replace

save "wage_ratio_final_2022.dta", replace

** add in county name and state name
global crosswalk "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\geographic-crosswalks\data"

import delimited using "$crosswalk\county-populations.csv", stringcols(2 3 4 5) varnames(1) clear

merge 1:1 year state county using "wage_ratio_final_2022.dta"

** correct CT counties -- this an issue since they switched to county equilvalents in 2022 -- and this data (QECW) uses the old (2020) FIPS
replace state_name = "Connecticut" if state == "09"
replace state_name = "Alaska" if state == "02"

replace county_name = "Fairfield County" if state == "09" & county == "001"
replace county_name = "Hartford County" if state == "09" & county == "003"
replace county_name = "Litchfield County" if state == "09" & county == "005"
replace county_name = "Middlesex County" if state == "09" & county == "007"
replace county_name = "New Haven County" if state == "09" & county == "009"
replace county_name = "New London County" if state == "09" & county == "011"
replace county_name = "Tolland County" if state == "09" & county == "013"
replace county_name = "Windham County" if state == "09" & county == "015"
replace county_name = "Valdez-Cordova Census Area" if state == "02" & county == "261"

drop if _merge == 1 & state != "09"

*** also want to drop old counties and impute missing values 
generate flag = 1 if state == "09" & average_to_living_wage_ratio == "NA"
drop if flag == 1

*** make missing
replace average_to_living_wage_ratio = "NA" if state == "09"
replace ratio_living_wage_quality = 3 if state == "09"


/* export final dataset */

keep if year == 2022

keep year state county state_name county_name average_to_living_wage_ratio ratio_living_wage_quality

order year state county state_name county_name average_to_living_wage_ratio ratio_living_wage_quality

export delimited using metrics_wage_ratio_2022.csv, replace



save "wage_ratio_final_2022.dta", replace