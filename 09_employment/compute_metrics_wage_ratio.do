/***************************
This file imports the 2018 QCEW data and exports average weekly wage for each
county. The file can be edited to read in data from any other year.

Programmed by Kevin Werner

5/28/20
****************************/

local raw "K:\Ibp\KWerner\Kevin\Mobility\raw"
local wages "K:\Ibp\KWerner\Kevin\Mobility\Wages"

/***** save living wage as .dta *****/
import delimited using "K:\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\mit-living-wage.csv"

save "`wages'\\mit_living_wages.dta", replace

clear

/***** import QCEW data *****/

cd `raw'

import delimited using "`raw'\\2018_data.csv", numericcols(14 15 16 17 18) clear

/* keep only county totals */
keep if areatype == "County" & ownership == "Total Covered"

keep st cnty annualaverageweeklywage

rename st state

rename cnty county

destring state, replace

cd `wages'

/* merge living wage and QCEW data */
merge 1:m state county using mit_living_wages.dta

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

/* check ratio */
sum average_to_living_wage_ratio, det
hist average_to_living_wage_ratio

/* Generally looks good. County 3 in State 19 (Iowa) is missing average wage 
data, so it shows up as a 0 in the ratio */

save "`wages'\\wage_ratio_final.dta",replace

keep state county year average_to_living_wage_ratio

order year state county average_to_living_wage_ratio

export delimited using metrics_wage_ratio.csv, replace