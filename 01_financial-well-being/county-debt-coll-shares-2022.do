
/************************************************
* Debt in Collections County-Level Shares 2022 *
* Data & Program Source: Debt in America
* Description: Process county-level debt in collections shares, overall and by race subgroups
[1] Import and process Urban Data Catalog file
[2] Export
************************************************/

global output "" // USER: must set output path here
assert !mi("$output")

**# [1] Import and process Urban Data Catalog file -----------------------------------
* source: Debt in America
import excel using "https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2022/06/16/county_dia_delinquency_%207%20Jun%202022.xlsx", clear

* keep only debt in collections metrics
gen state = substr(B, 1, 2)
gen county = substr(B, 3, 3)
ren (D E F) ///
	(share_debt_coll_all share_debt_coll_majnonwhite share_debt_coll_majwhite)
keep state county share_debt_coll*

drop if county == "OID"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(county state) j(subgroup) string

replace subgroup = "All" if subgroup == "_all"
replace subgroup = "Majority Non-White" if subgroup == "_majnonwhite"
replace subgroup = "Majority White" if subgroup == "_majwhite"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "" if inlist(share_debt_coll, "n/a*", "n/a**")
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

**# [2] Export -----------------------------------
gen year = 2022

compress
order year state county share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state county subgroup

export delimited using "$output\county-debt-coll-shares-2022.csv", datafmt replace
