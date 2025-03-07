
/************************************************
Created by Mingli Zhong (mzhong@urban.org)
3-7-2025
* This do file is based on Jen Andre's do file county-debt-coll-shares-2022 in the same folder (C:\GitHub\mobility-from-poverty\01_financial-well-being). It generates county-level debt in collection results based on Debt in America data. 
* Debt in Collections County-Level Shares 2022 and 2023*
* Data & Program Source: Debt in America
* Description: Process county-level debt in collections shares, overall and by race subgroups

These files are used and produced for the 2025 version of the mobility metrics dashboard. All files can be found under this path: C:\GitHub\mobility-from-poverty\01_financial-well-being\

1.county-debt-coll-shares-2023.do generates all the udpated results: 
2. In the final folder: all the 2023 results at the county level are: 
	- metrics_overall_debt_coll_all_county_2023.csv, metrics_overall_debt_coll_race_ethnicity_county_2023.csv, metrics_medical_debt_coll_all_county_2023.csv, and metrics_medical_debt_coll_race_ethnicity_county_2023.csv. No city-level data is being updated for 2023, only county-level data are generated. 
2. Box\Data\Metrics_2025_round\debt_in_collections\dia-2023: this folder has all the raw data from Debt in America to help create the 2025 county-level data. The code is mostly to transform the data from dia-2023 in a format that is compatible with mobility metrics dashboard. 


/***
For the CT planning regions, DiA does not have data for the planning regions in the 2023 data. They only have data for the original counties. 
***/

************************************************/
clear all 
set more off 

global output "GitHub\mobility-from-poverty\01_financial-well-being\final" // USER: must set output path here
assert !mi("$output")

global raw "Box\Data\Metrics_2025_round\debt_in_collections"  // USER: must set raw data path here

global directory "GitHub\mobility-from-poverty\01_financial-well-being"
global master "GitHub\mobility-from-poverty"


**# [1] Import data 
*****************************************************
** Delinquent debt by debt category: overall, medical
*****************************************************
* source: Debt in America: raw data are direct download from DiA using 2023 data updated in 2024: https://datacatalog.urban.org/dataset/debt-america-2024 
* raw data saved here: Box\Data\Metrics_2025_round\debt_in_collections\dia-2023 

*** Use FIPS code in DiA 
foreach x in overall medical {
	import excel using "$raw\dia-2023\dia_lbls_all_`x'_county_2023_1Jul2024.xlsx", clear firstrow 

*Provide state and county FIPS instead of names 
keep CountyFIPS - F
rename CountyFIPS county 
gen state = substr(county, 1, 2)

* keep the leading zeros for both state and county FIPS
replace county = substr("00000" + county, -5, .)
replace state = substr("00" + state, -2, .)

drop CountyName StateName 

ren (Sharewith E F) (share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)

order state county share_debt_coll*
keep state county share_debt_coll*

* drop missing counties 
drop if county == "OID"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(county state) j(subgroup) string

replace subgroup = "All" if subgroup == "_all"
replace subgroup = "Majority Non-White" if subgroup == "_majnonwhite"
replace subgroup = "Majority White" if subgroup == "_majwhite"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "NA" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = "."
	replace share_debt_coll_quality = "1" if !mi(share_debt_coll)
	replace share_debt_coll_quality = "NA" if share_debt_coll == "NA" // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

export delimited using "$output\metrics_`x'_debt_coll_race_ethnicity_county_2023.csv", datafmt replace
* save "output\county-debt-coll-shares-2023-`x'.dta", replace

}


*****************************************************************************************************************************************
/* No need for student loan and auto loan but would like to keep the following code as we might include these two types for the next update
********************
** student loan debt 
** variable names are different in these spreadsheets so will need to process them individually 
import excel using "$directory\dia-2023\dia_lbls_all_student_county_2023_1Jul2024.xlsx", clear firstrow 

keep CountyName - SharewithstudentloandebtWh
rename CountyName county 
rename StateName state
ren (SharewithstudentloandebtAl SharewithstudentloandebtCo SharewithstudentloandebtWh) (share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)

keep state county share_debt_coll*

drop if county == "OID"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(county state) j(subgroup) string

replace subgroup = "All" if subgroup == "_all"
replace subgroup = "Majority Non-White" if subgroup == "_majnonwhite"
replace subgroup = "Majority White" if subgroup == "_majwhite"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "NA" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if share_debt_coll == "NA" // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

rename share_debt_coll share_student_debt_coll

export delimited using "$output\county-debt-coll-shares-2023-student.csv", datafmt replace


********************
** Autoretail
** variable names are different in these spreadsheets so will need to process them individually 
import excel using "$directory\dia-2023\dia_lbls_all_autoretail_county_2023_1Jul2024.xlsx", clear firstrow 

keep CountyName - F
rename CountyName county 
rename StateName state
ren (Autoretailloandelinquencyrat E F) (share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)

keep state county share_debt_coll*

drop if county == "OID"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(county state) j(subgroup) string

replace subgroup = "All" if subgroup == "_all"
replace subgroup = "Majority Non-White" if subgroup == "_majnonwhite"
replace subgroup = "Majority White" if subgroup == "_majwhite"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "NA" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if share_debt_coll == "NA" // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

rename share_debt_coll share_auto_debt_coll

export delimited using "$output\county-debt-coll-shares-2023-auto.csv", datafmt replace
**************************************************************************************************/


*****************************************
** Update the variable names for medical  
******************************************
import delimited using "$output\metrics_medical_debt_coll_race_ethnicity_county_2023.csv", clear

rename share_debt_coll share_medical_debt_coll
rename share_debt_coll_quality share_medical_debt_coll_quality 

export delimited using "$output\metrics_medical_debt_coll_race_ethnicity_county_2023.csv", datafmt replace



*******************************************
**A second csv file only with All data only
******************************************* 
foreach x in overall medical {
	import delimited using "$output\metrics_`x'_debt_coll_race_ethnicity_county_2023.csv", clear
	keep if subgroup == "All"

	drop subgroup_type subgroup

	export delimited using "$output\metrics_`x'_debt_coll_all_county_2023.csv", datafmt replace
}
