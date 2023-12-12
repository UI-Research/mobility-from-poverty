
/************************************************
* Debt in Collections City-Level Shares *
* Data & Program Source: Financial Health & Wealth Dashboard
*						 State FIPS codes from US Census Bureau
*						 CDP FIPS codes from IPUMS
* Description: Process city-level debt in collections shares, overall and by race subgroups
[1] Prep state FIPS codes and CDP FIPS codes
[2] Import and process Urban Data Catalog file
[3] Export
************************************************/

global output "" // USER: must set output path here
assert !mi("$output")

**# [1] Prep FIPS codes -----------------------------------
* import and prep state abbreviations & FIPS codes from US Census Bureau
import delimited using "https://www2.census.gov/geo/docs/reference/state.txt", clear
tostring state, format("%02.0f") replace
keep state stusab
tempfile statefips
save `statefips', replace

* import and prep place FIPS codes from IPUMS
import excel using "https://usa.ipums.org/usa/resources/volii/large_place_PUMA2010_match_summary.xlsx", firstrow clear
ren (PlaceFIPS IPUMSCITYLabel) ///
	(place_fips city)
replace city = "Gilbert, AZ" if StateName == "Arizona" & CensusPlaceName == "Gilbert town"
replace city = "Honolulu, HI" if StateName == "Hawaii" & CensusPlaceName == "Urban Honolulu CDP"
replace city = "Overland Park, KS" if StateName == "Kansas" & CensusPlaceName == "Overland Park city"
replace city = "Paradise, NV" if StateName == "Nevada" & CensusPlaceName == "Paradise CDP"
replace city = "Scottsdale, AZ" if StateName == "Arizona" & CensusPlaceName == "Scottsdale city"
replace city = "Sunrise Manor, NV" if StateName == "Nevada" & CensusPlaceName == "Sunrise Manor CDP"
drop if city == "[Not identified in any sample]"
keep place_fips city
tempfile placefips
save `placefips', replace

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
replace subgroup = "Majority Non-White" if subgroup == "residentsofcolor"
replace subgroup = "Majority White" if subgroup == "white"

gen subgroup_type = "race-ethnicity"

* create data quality fields - most 1, some 3 for missing/suppression
replace share_debt_coll = "" if share_debt_coll == "NA"
destring share_debt_coll, replace
gen share_debt_coll_quality = .
	replace share_debt_coll_quality = 1 if !mi(share_debt_coll)
	replace share_debt_coll_quality = 3 if mi(share_debt_coll) // suppressed or no subgroup

* merge state FIPS codes from US Census Bureau
merge m:1 stusab using `statefips', assert(2 3) keep(3) nogen
drop stusab

* merge place FIPS codes from IPUMS
merge m:1 city using `placefips', assert(2 3) keep(3) nogen

**# [3] Export -----------------------------------
gen year = 2021

compress
order year place_fips state city share_debt_coll share_debt_coll_quality subgroup_type subgroup 
gsort year place_fips state city subgroup

export delimited using "$output\city-debt-coll-shares-2021.csv", datafmt replace
