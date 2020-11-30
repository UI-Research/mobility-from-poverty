/***************************
This file imports the 2018 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

Programmed by Kevin Werner

5/28/20
****************************/


/**************

IMPORTANT NOTE FOR FUTURE: 
Make sure you change the QCEW csv format so that there are no commans in the
numbers. If you don't, they will not read in properly

***************/

local raw "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"
local wages "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"

/***** save living wage as .dta *****/
cd `wages'
import delimited using "mit-living-wage.csv"

rename year subgroup

gen subgroup_type = "Year"

tempfile mit_2018
save `mit_2018'
clear

/*** deflate the 2018 amounts to 2014 ***/

import delimited using "mit-living-wage.csv"

rename year subgroup

gen subgroup_type = "Year"

replace subgroup = 2014 if subgroup == 2018

*deflator = 236.746/251.107 from  https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm *

replace wage = wage* 236.746/251.107 

/* append on 2018 wages */
append using `mit_2018'

save "mit_living_wage_2_year.dta", replace


/***** import 2018 QCEW data *****/

cd `raw'

import delimited using "2018_data.csv", numericcols(14 15 16 17 18) clear

/* keep only county totals */
keep if areatype == "County" & ownership == "Total Covered"

keep st cnty annualaverageweeklywage annualaverageestablishmentcount

rename st state

rename cnty county

destring state, replace

gen subgroup = 2018

tempfile qcew_2018
save `qcew_2018'

clear

/***** import 2014 QCEW data *****/

import delimited using "2014_data.csv", numericcols(14 15 16 17 18) clear

/* keep only county totals */
keep if areatype == "County" & ownership == "Total Covered"

keep st cnty annualaverageweeklywage annualaverageestablishmentcount

rename st state

rename cnty county

destring state, replace

gen subgroup = 2014

/* update fips codes that get changed */
replace county = 158 if state == 2 & county == 270
replace county = 102 if state == 46 & county == 113

/*** append the 2014 and 2018 QECW ***/

append using `qcew_2018'

gen subgroup_type = "Year"

cd `wages'

/* merge living wage and QCEW data
Note that county 05 (Kalawao) in Hawaii is missing */
merge 1:m state county subgroup using mit_living_wage_2_year.dta

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
sum average_to_living_wage_ratio, det
hist average_to_living_wage_ratio

twoway (histogram average_to_living_wage_ratio if subgroup==2014,  color(red%30)) ///        
       (histogram average_to_living_wage_ratio if subgroup==2018, color(green%30)), ///   
       legend(order(1 "2014" 2 "2018" ))
/* Generally looks good. County 3 in State 19 (Iowa) is missing average wage 
data, so it shows up as a 0 in the ratio */

/* replace 0 ratio with missing and replace data quality as missing */
replace average_to_living_wage_ratio = . if average_to_living_wage_ratio == 0
replace wage_ratio_quality = . if average_to_living_wage_ratio == .

save "wage_ratio_final_2_year.dta",replace


keep state county subgroup_type subgroup average_to_living_wage_ratio wage_ratio_quality

order state county subgroup_type subgroup average_to_living_wage_ratio wage_ratio_quality

sort state county subgroup

export delimited using metrics_wage_ratio_years.csv, replace