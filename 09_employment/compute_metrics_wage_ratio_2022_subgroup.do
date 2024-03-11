/***************************
This file imports the 2022 QCEW data and exports average weekly wage for each county and creating industry subgroups. The file can be edited to read in data from any other year.

Before using this file, download the relevant year of data from QCEW NAICS-Based Data Files, County High-Level (and select the annual summary)

Programmed by Kevin Werner + updated by Kassandra Martinchek in 2023, adding subgroups

2/29/2024

****************************/

*** uncomment command below to install package if needed
*ssc install distinct

local raw "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\09_employment"
local wages "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\09_employment"
local crosswalk "C:\Users\KMartinchek\Documents\umf-2024\mobility-from-poverty\geographic-crosswalks\data"

/***** save living wage as .dta *****/
cd `wages'
import delimited using "mit-living-wage-2022.csv", clear // because this is 2022 data, this does not need to be inflated or deflated

replace year = 2022 // correct to proper year

keep if adults == "1 Adult" & children == "2 Children"

save "mit_living_wage-2022.dta", replace

clear

/***** import QCEW data *****/

cd `raw'

import delimited using "2022_data.csv", numericcols(14 15 16 17 18) varnames(1) clear

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

drop if industry_type == . // drop super-sections and "unclassified" naics codes 

** because some naics codes are combined into industries, we need to collapse
** we average the average weekly wage across both
** but sum the establishment counts 
collapse (mean) avgwkwage=annualaverageweeklywage (sum) avgestct=annualaverageestablishmentcount, by(st cnty industry_type)

** check for duplicates
duplicates report st cnty industry_type

/* test whether all counties have needed codes-- answer is no, which means need to do data expansion later on */ 
egen obs_per_cnty = count(industry_type), by(st cnty)
tab obs_per_cnty

** count zeros -- will generate this many zeros in final dataset
count if avgwkwage == 0

** keep variables pre-merge

keep st cnty avgwkwage avgestct industry_type

rename st state

rename cnty county

destring state, replace // make numeric for merging with MIT data

cd `wages'

/* merge living wage and QCEW data */
merge m:1 state county using mit_living_wage-2022.dta

/* drop statewide obs because we are compiling data at the county level */
drop if _merge == 1

/* drop duplicates (two counties repeated) */
duplicates drop

/* convert living hourly wage to weekly */
gen weekly_living_wage = wage * 40

/* get ratio (main metric) */
gen ratio_living_wage = avgwkwage/weekly_living_wage

assert avgwkwage == 0 if ratio_living_wage == 0 // assert ratio is missing if avgwkwage is zero in raw dataset

/* create data quality flag 
per discussion with Greg, >= 30 is 1, <30 is 3 */
gen ratio_living_wage_quality = 1 if avgestct >= 30 & avgestct != .
replace ratio_living_wage_quality = 3 if avgestct < 30 & avgestct != .
replace ratio_living_wage_quality = . if avgestct == .

/* test flag */
tab ratio_living_wage_quality, missing

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
/*sum ratio_living_wage, det
hist ratio_living_wage */
/*tab county state if ratio_living_wage == 0 */

gen new_ratio = string(ratio_living_wage)
drop ratio_living_wage
rename new_ratio ratio_living_wage

/* replace 0 ratio with missing and replace data quality as missing */
replace ratio_living_wage = "NA" if ratio_living_wage == "."
replace ratio_living_wage_quality = . if ratio_living_wage == "NA" /* changed this from data quality 3 */

gen new_ratio_quality = string(ratio_living_wage_quality)
drop ratio_living_wage_quality
rename new_ratio_quality ratio_living_wage_quality

replace ratio_living_wage_quality = "" if ratio_living_wage_quality == "."

save "wage_ratio_final_2022_subgroup.dta",replace


keep state county year ratio_living_wage ratio_living_wage_quality industry_type

/* rename final variable here */
rename industry_type subgroup

generate subgroup_type = 1 if subgroup == 1
replace subgroup_type = 2 if subgroup != 1

label define subg_type_lab 1 "all" 2 "industry"

label values subgroup_type subg_type_lab

/* export files */

order year state county subgroup_type subgroup ratio_living_wage ratio_living_wage_quality

export delimited using metrics_wage_ratio_2022_subgroup.csv, replace

save "wage_ratio_final_2022_subgroup.dta",replace

** add in county name and state name
import delimited using "`crosswalk'\county-populations.csv", stringcols(2 3 4 5) varnames(1) clear

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

drop if _merge == 1 & state != "09"

*** drop old counties that don't match 2022 units-- QCEW data does not use most up to date census units in 2022
drop if _merge == 2 & state == "09"

*** also want to drop old counties and impute missing values 
generate flag = 1 if state == "09" & ratio_living_wage == "NA"
drop if flag == 1

*** make missing
replace ratio_living_wage = "NA" if state == "09"
replace ratio_living_wage_quality = "" if state == "09"

*** assert 
assert ratio_living_wage_quality == "" if ratio_living_wage == "NA"

*** correct subgroup variables
replace subgroup_type = 1 if state == "09"
label values subgroup_type subg_type_lab

replace subgroup = 1 if state == "09"
label values subgroup industry_labels_mm

/* export final dataset */

keep if year == 2022

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

replace year = 2022

tab subgroup if _fillin == 1, m  // confirm no all values were filled in
replace subgroup_type = 2 if _fillin == 1

replace ratio_living_wage = "NA" if _fillin == 1
replace ratio_living_wage_quality = "" if _fillin == 1 

*** assert number of counties
distinct state county, joint // to confirm there are 3143 counties in the dataset
distinct state county subgroup, joint // to confirm there are 8 obs for each of the 3143 counties (or 25144)
distinct state county subgroup if subgroup_type == 2, joint // to confirm there are 7 obs for each of the 3143 counties (or 22001)

*count if ratio_living_wage == "0"
count if missing(subgroup)
count if missing(subgroup_type)

keep year state county state_name county_name subgroup_type subgroup ratio_living_wage ratio_living_wage_quality

order year state county state_name county_name subgroup_type subgroup ratio_living_wage ratio_living_wage_quality

sort year state county subgroup

export delimited using metrics_wage_ratio_2022_subgroup.csv, replace

save "wage_ratio_final_2022_subgroup.dta", replace

/* delete unneeded files */

erase "wage_ratio_final_2022_subgroup.dta"
erase "mit_living_wage-2022.dta"
