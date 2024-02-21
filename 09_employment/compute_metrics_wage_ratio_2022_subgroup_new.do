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

keep if adults == "1 Adult" & children == "2 Children"

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
keep if areatype == "County" // & industry != "10 Total, all industries"

** recode industries into MM categories
generate industry_type = .
	replace industry_type = 1 if naics == 10 & own == 0 // all
	replace industry_type = 2 if naics == 101 // goods producing
	replace industry_type = 3 if naics == 1028 // public admin
	replace industry_type = 4 if naics == 1021 // trade transit utilities
	replace industry_type = 5 if naics == 1022 // info services
	replace industry_type = 6 if naics == 1023 | naics == 1024 // financial, prof, biz services
	replace industry_type = 7 if naics == 1025 // ed/health
	replace industry_type = 8 if naics == 1026 | naics == 1027 // leisure/hospitality/other
	
** variable labels 
label define industry_labels_mm 1 "All" 2 "Goods Producing" 3 "Public Administration" 4 "Trade, Transit, Utilities" 5 "Information Services" 6 "Professional Services" 7 "Education and Health" 8 "Leisure and Other"

label values industry_type industry_labels_mm

drop if industry_type == . // drop super-sections and "unclassified" naics codes

** keep variables pre-merge

keep st cnty annualaverageweeklywage annualaverageestablishmentcount industry_type

rename st state

rename cnty county

destring state, replace // make numeric for merging with MIT data

cd `wages'

/* merge living wage and QCEW data */
merge m:1 state county using mit_living_wage-2022.dta

*tab county state if _merge == 1*/// two AK counties missing from MIT data

/* drop statewide obs */
drop if _merge == 1

/* only keep 1 adult, 2 children row */
*keep if adults == "1 Adult" & children == "2 Children" // moved this earlier in the code to avoid a m:m merge in line 78

/* drop duplicates (two counties repeated) */
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
drop _merge

** generate county name and state name
*. countyfips, statefips(state) countyfips(county)

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

save "wage_ratio_final_2022_subgroup.dta",replace


keep state county year average_to_living_wage_ratio wage_ratio_quality industry_type

/* rename final variable here */

*rename ratio_average_to_living_wage average_to_living_wage_ratio
rename wage_ratio_quality ratio_living_wage_quality
rename industry_type subgroup

generate subgroup_type = 1 if subgroup == 1
replace subgroup_type = 2 if subgroup != 1

label define subg_type_lab 1 "all" 2 "industry"

label values subgroup_type subg_type_lab

/* export files */

order year state county subgroup_type subgroup average_to_living_wage_ratio ratio_living_wage_quality

export delimited using metrics_wage_ratio_2022_subgroup.csv, replace

save "wage_ratio_final_2022_subgroup.dta",replace

** add in county name and state name
global crosswalk "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\geographic-crosswalks\data"

import delimited using "$crosswalk\county-populations.csv", stringcols(2 3 4 5) varnames(1) clear

merge 1:m year state county using "wage_ratio_final_2022_subgroup.dta"

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

drop if _merge == 1

*** also want to drop new 2022 planning regions since they won't have data-- could also keep these as missing and drop the old county structure
*drop if state == "09" & (county == 110 | county == "120" | county == "130" | county == "140" | county == "150" | county == "160" | county == "170" | county == "180" | county == "190")
generate flag = 1 if state == "09" & average_to_living_wage_ratio == ""
drop if flag == 1

** drop the alaska census area to be coherent-- TBD


/* export final dataset */

keep if year == 2022

keep year state county state_name county_name subgroup_type subgroup average_to_living_wage_ratio ratio_living_wage_quality

order year state county state_name county_name subgroup_type subgroup  average_to_living_wage_ratio ratio_living_wage_quality

export delimited using metrics_wage_ratio_2022_subgroup.csv, replace

save "wage_ratio_final_2022_subgroup.dta", replace