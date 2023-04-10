/***************************
This file imports the 2020 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

This handles the special request on 4/29/21 from Riverside, CA to show the living 
wage as broken out by industry

Programmed by Kevin Werner

4/29/21
****************************/


/**************

IMPORTANT NOTE FOR FUTURE: 
Make sure you change the QCEW csv format so that there are no commans in the
numbers. If you don't, they will not read in properly

***************/

local raw "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"
local wages "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"


/***** import 2020 QCEW data *****/

cd `raw'

import delimited using "2020_data.csv", numericcols(14 15 16 17 18) clear

/* keep only county totals in county that we want */
keep if areatype == "County" & areacode == "6065"

keep st cnty annualaverageweeklywage annualaverageestablishmentcount annualaverageemployment ownership industry

rename st state

rename cnty county

destring state, replace

gen subgroup = 2020

tempfile qcew_2020
save `qcew_2020'

/* create living wage for 1 adult and 2 kids. from here https://livingwage.mit.edu/counties/06065 */

gen wage= 45.27

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

/* replace 0 ratio with missing and replace data quality as missing */
replace average_to_living_wage_ratio = . if average_to_living_wage_ratio == 0
replace wage_ratio_quality = . if average_to_living_wage_ratio == .

save "wage_ratio_riverside_2_year.dta",replace


keep state county subgroup ownership industry average_to_living_wage_ratio wage_ratio_quality annualaverageemployment

order state county subgroup ownership industry average_to_living_wage_ratio wage_ratio_quality annualaverageemployment

sort state county subgroup

export delimited using metrics_wage_ratio_years_riverside_2020.csv, replace