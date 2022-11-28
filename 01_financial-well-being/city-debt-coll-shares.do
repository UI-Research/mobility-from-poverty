
/************************************************
* Debt in Collections City-Level Shares *

* Data & Program Source: credit bureau data, financial health dashboard
* Description: Calculate city-level debt in collections shares, overall and by race subgroups
[1] Setup
[2] Prep PUMA-City crosswalk
[3] Import and prep microdata
[4] Create city-level shares
[5] Export
************************************************/

**# [1] Setup -----------------------------------
clear all
set more off
capture program drop _all

* set directory path (STATA3)
* credit bureau microdata must remain on and be accessed via STATA3
global root "" // removed - fill in path here
assert "$root" != ""

* set data pull (2021 = August 2021)
global pull 2021


**# [2] Prep PUMA-City crosswalk ----------------
import excel "$root\Data\city_puma_crosswalk_all_cities.xlsx", firstrow clear

* keep cities with 2+ best matching PUMAs, parse PUMAs
keep if CountofBestMatchingPUMAsw >= 2
split BestMatchingPUMAs, p(", ") gen("puma")

* reshape long 
keep StateFIPSCode IPUMSCITYLabel puma*
reshape long puma, i(StateFIPSCode IPUMSCITYLabel) j(count) string
drop if mi(puma)

* clean, prep for merge
gen state_puma = StateFIPSCode + puma
ren IPUMSCITYLabel city_name
replace city_name = strtrim(stritrim(city_name))
keep state_puma city_name

* save tempfile
tempfile xw
save `xw', replace


**# [3] Import and prep microdata ---------------
use "$root\Temp\debt01a_$pull.dta", clear

* apply puma-city crosswalk
merge m:1 state_puma using `xw', keep(3) nogen

* create non-white share
gen comcol_share = black_share + hispanic_share + asian_share + pacific_share + other_share + aian_share + mixed_share
assert round(comcol_share + white_share) == 1 if comcol_share != .

* apply 50% zip code threshold for each race subgroup, append subgroups for long format
gen race = "all"
local races white comcol
foreach race of local races{
	preserve
	
	keep if `race'_share > 0.5 & `race'_share != . // 50% threshold
	replace race = "`race'"
	
	tempfile temp_`race'
	save `temp_`race'', replace
	
	restore	
	
	append using `temp_`race''
}


**# [4] Create city-level shares ---------------- 
gen share_debt_coll = has_tot_collect
gen share_debt_coll_n = has_tot_collect
collapse (count) share_debt_coll_n (mean) share_debt_coll, by(state_cd city_name race)

* suppress small sample sizes
replace share_debt_coll = . if share_debt_coll_n < 50

* create data quality flag: 3 for small sample size, else 1
gen share_debt_coll_quality = 3 if share_debt_coll_n < 50
	replace share_debt_coll_quality = 1 if share_debt_coll_n >= 50
drop share_debt_coll_n


**# [5] Export ----------------------------------
* prep fields
gen year = $pull
gen subgroup_type = "race-ethnicity"
gen subgroup = "All"
	replace subgroup = "Majority white" if race == "white"
	replace subgroup = "Majority non-white" if race == "comcol"
drop race
ren (state_cd city_name) (state city)

format share_debt_coll %06.5f

order year state city share_debt_coll share_debt_coll_quality subgroup_type subgroup
gsort year state city subgroup_type subgroup

* export
export delimited using "$root\Output\city-debt-coll-shares.csv", datafmt replace


