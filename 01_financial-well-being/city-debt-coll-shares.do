
/************************************************
* Debt in Collections City-Level Shares *
* Data & Program Source: Financial Health & Wealth Dashboard
*						 State FIPS codes from US Census Bureau
* Description: Process city-level debt in collections shares, overall and by race subgroups
[1] Prep state FIPS codes
[2] Import and process Urban Data Catalog file
[3] Export
************************************************/


global output "" // set output path
assert !mi("$output")

**# [1] Prep state FIPS codes -----------------------------------
* import and prep state abbreviations & FIPS codes from US Census Bureau
import delimited using "https://www2.census.gov/geo/docs/reference/state.txt", clear
tostring state, format("%02.0f") replace
keep state stusab
tempfile fips
save `fips', replace


**# [2] Import and process Urban Data Catalog file -----------------------------------
* source: Financial Health & Wealth Dashboard
import excel using "https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2022/12/05/3_city_financial_health_metrics_b.xlsx", clear

* keep only city-level debt in collections metrics
drop if mi(B)
keep A C AH AI AJ
ren (A C AH AI AJ) ///
	(city stusab share_debt_colloverall share_debt_collresidentsofcolor share_debt_collwhite)
drop if city == "city name"

* format long and adjust subgroups to match standard
reshape long share_debt_coll, i(city stusab) j(subgroup) string

replace subgroup = "All" if subgroup == "overall"
replace subgroup = "Majority non-white" if subgroup == "residentsofcolor"
replace subgroup = "Majority white" if subgroup == "white"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "" if share_debt_coll == "NA"
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

* merge FIPS codes from US Census Bureau
merge m:1 stusab using `fips', assert(2 3) keep(3) nogen
drop stusab


**# [3] Export -----------------------------------
gen year = 2021

compress
order year state city share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year state city subgroup

export delimited using "$output\city-debt-coll-shares.csv", datafmt replace

