
/************************************************
Created by Mingli Zhong (mzhong@urban.org)
2-4-2025
* This do file is based on Jen Andre's do file county-debt-coll-shares-2022 in the same folder (C:\GitHub\mobility-from-poverty\01_financial-well-being). It generates county-level debt in collection results based on Debt in America data. 
* Debt in Collections County-Level Shares 2022 and 2023*
* Data & Program Source: Debt in America
* Description: Process county-level debt in collections shares, overall and by race subgroups
[1] Import and process Urban Data Catalog file
[2] Export
************************************************/
clear all 
set more off 

global output "C:\GitHub\mobility-from-poverty\01_financial-well-being\2025 output" // USER: must set output path here
assert !mi("$output")

global directory "C:\GitHub\mobility-from-poverty\01_financial-well-being"
global master "C:\GitHub\mobility-from-poverty"

**# [1] Import data 
*******************************************************************************
** Delinquent debt by debt category: overall, medical, auto, studnet loan debt 
*******************************************************************************
* source: Debt in America: raw data are direct download from DiA using 2023 data updated in 2024: https://datacatalog.urban.org/dataset/debt-america-2024 
foreach x in overall medical {
	import excel using "$directory\dia-2023\dia_lbls_all_`x'_county_2023_1Jul2024.xlsx", clear firstrow 

keep CountyName - F
rename CountyName county 
rename StateName state
ren (Sharewith E F) (share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)

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
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if share_debt_coll == "NA" // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2023

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

rename share_debt_coll share_`x'_debt_coll

export delimited using "$output\temp\county-debt-coll-shares-2023-`x'.csv", datafmt replace
* save "output\county-debt-coll-shares-2023-`x'.dta", replace
}

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

export delimited using "$output\temp\county-debt-coll-shares-2023-student.csv", datafmt replace


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

export delimited using "$output\temp\county-debt-coll-shares-2023-auto.csv", datafmt replace


**********************************************************************************
** Merge FIPS state and county codes to all the csv files
** Consistent with 2022 data files, only show FIPS code, no state or county names 
**********************************************************************************
/***
For the CT planning regions, DiA does not have data for the planning regions in the 2023 data. They only have data for the original counties. 
However, mobility would like to generate data for the planning regions starting in 2022. Data for the planning regions are not available so marked as missing in the final output.  
***/
foreach x in overall medical student auto {
	import delimited using "$output\temp\county-debt-coll-shares-2023-`x'.csv", clear 

	rename state state_name
	rename county county_name 
	sort state county

	* Remove extra info after "," in county_name 
	replace county_name = substr(county_name, 1, strpos(county_name, ",") - 1) ///
		if strpos(county_name, ",") > 0
		
	* Trim excess whitespace
	replace county_name = trim(county_name)

	save "$output\temp\county-debt-coll-shares-2023-`x'.dta", replace


	import delimited using "$master\geographic-crosswalks\data\county-populations.csv", clear

	sort state county 
	drop year population

	* keep only one observation per state-county pair 
	duplicates drop state_name county_name, force
	* Use state and county to check duplicates 
	duplicates tag state county, gen(dup)
	tab dup
	drop dup

	save "$output\temp\county-populations.dta", replace

	merge 1:n state_name county_name using "$output\temp\county-debt-coll-shares-2023-`x'.dta"
	
	sort state county 
	order year, before(state)
	
	** Drop CT counties and keep CT planning regions 
	expand 3 if _merge == 1
	replace subgroup = cond(mod(_n, 3) == 1, "All", ///
               cond(mod(_n, 3) == 2, "Majority Non-White", "Majority White")) if _merge == 1
	replace year = 2023 if _merge == 1 
	replace share_`x'_debt_coll = "NA" if _merge == 1 
	replace share_debt_coll_quality = 3 if _merge == 1 
	replace subgroup_type = "race-ethnicity" if _merge == 1
		
	drop if _merge == 2
	drop _merge
	drop state_name county_name 
	
	sort year state county subgroup 
	
	export delimited "$output\county-debt-coll-shares-2023-`x'-final.csv", replace
} 


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
