/***************************
This file imports the 2018 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

Programmed by Kevin Werner

12/16/22

Living wage data is in 2022 dollars, so it is deflated. 
****************************/

local raw "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"
local wages "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment"

/***** save living wage as .dta *****/
cd `wages'
import delimited using "mit-living-wage-2022.csv"

*deflate 2022 MIT to 2021 using BLS series CUUR0000SA0. Used first half for 2022, annual for 2021

replace wage = wage* 270.970/288.347	

save "mit_living_wages-2021.dta", replace

clear

/***** import QCEW data *****/

cd `raw'

import delimited using "2021_data.csv", numericcols(14 15 16 17 18) clear

/* keep only county totals */
keep if areatype == "County" & ownership == "Total Covered"

keep st cnty annualaverageweeklywage annualaverageestablishmentcount

rename st state

rename cnty county

destring state, replace

cd `wages'

/* merge living wage and QCEW data
Note that county 05 (Kalawao) in Hawaii is missing */
merge 1:m state county using mit_living_wages-2021.dta

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
*sum average_to_living_wage_ratio, det
*hist average_to_living_wage_ratio

gen new_ratio = string(average_to_living_wage_ratio)
drop average_to_living_wage_ratio
rename new_ratio average_to_living_wage_ratio

/* Generally looks good. County 3 in State 19 (Iowa) is missing average wage 
data, so it shows up as a 0 in the ratio */

/* replace 0 ratio with missing and replace data quality as missing */
replace average_to_living_wage_ratio = "NA" if average_to_living_wage_ratio == "."
replace wage_ratio_quality = 3 if average_to_living_wage_ratio == "NA"

save "wage_ratio_final_2021.dta",replace


keep state county year average_to_living_wage_ratio wage_ratio_quality

order year state county average_to_living_wage_ratio wage_ratio_quality

export delimited using metrics_wage_ratio_2021.csv, replace