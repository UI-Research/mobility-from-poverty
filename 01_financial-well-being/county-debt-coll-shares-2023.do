
/************************************************
Created by Mingli Zhong (mzhong@urban.org)
12-10-2023
* This do file is based on Jen Andre's do file county-debt-coll-shares-2022 in the same folder (C:\GitHub\mobility-from-poverty\01_financial-well-being). It generates county-level debt in collection results based on Debt in America data. 
* Debt in Collections County-Level Shares 2022 and 2023*
* Data & Program Source: Debt in America
* Description: Process county-level debt in collections shares, overall and by race subgroups
[1] Import and process Urban Data Catalog file
[2] Export
************************************************/

global output "C:\GitHub\mobility-from-poverty\01_financial-well-being\output" // USER: must set output path here
assert !mi("$output")

**# [1] Import and process Urban Data Catalog file -----------------------------------
*******************************************************************************
** Delinquent debt by debt category: overall, medical, auto, studnet loan debt 
*******************************************************************************
* source: Debt in America
* import excel using "https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2022/06/16/county_dia_delinquency_%207%20Jun%202022.xlsx", clear
foreach x in overall medical {
	import excel using "C:\GitHub\mobility-from-poverty\01_financial-well-being\dia-2023\dia_lbls_all_`x'_county_2023_1Jul2024.xlsx", clear firstrow 

/*
* keep only debt in collections metrics
gen state = substr(B, 1, 2)
gen county = substr(B, 3, 3)
ren (D E F) ///
	(share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)
*/	

keep CountyName - F
rename CountyName county 
rename StateName state
ren (Sharewith E F) (share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)

keep state county share_debt_coll*

drop if county == "OID"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(county state) j(subgroup) string

replace subgroup = "All" if subgroup == "_all"
replace subgroup = "Majority Non-White" if subgroup == "_majnonwhite"
replace subgroup = "Majority White" if subgroup == "_majwhite"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

export delimited using "$output\county-debt-coll-shares-2023-`x'.csv", datafmt replace
* save "output\county-debt-coll-shares-2023-`x'.dta", replace
}

********************
** student loan debt 
** variable names are different in these spreadsheets so will need to process them individually 
import excel using "C:\GitHub\mobility-from-poverty\01_financial-well-being\dia-2023\dia_lbls_all_student_county_2023_1Jul2024.xlsx", clear firstrow 

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
replace share_debt_coll = "" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

export delimited using "$output\county-debt-coll-shares-2023-student.csv", datafmt replace


********************
** Autoretail
** variable names are different in these spreadsheets so will need to process them individually 
import excel using "C:\GitHub\mobility-from-poverty\01_financial-well-being\dia-2023\dia_lbls_all_autoretail_county_2023_1Jul2024.xlsx", clear firstrow 

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
replace share_debt_coll = "" if inlist(share_debt_coll, "n/a*", "n/a**", "NA")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

export delimited using "$output\county-debt-coll-shares-2023-autoretail.csv", datafmt replace


/*
****
** DID NOT COMBINE AS COUNTY AND STATE NAMES IN 2022 FILES ARE NUMERIC BUT STRING WITH NAMES IN 2023
** DON'T KNOW WHAT 2022 NUMERIC COUNTY AND STATE NAMES STAND FOR 
***********************************************************
** Combine 2022 and 2023 county-level data in one csv file 
***********************************************************
import delimited using "$output\county-debt-coll-shares-2022.csv", clear 
save "$output\county-debt-coll-shares-2022.dta", replace

append using "$output\county-debt-coll-shares-2023.dta" 
*/
