*********************************
*	Safety Metrics				*
*	Crime Rates - County 2018	*
*	Lily Robin, 2019.9.14		*
*********************************

clear

///// 1.UPDATE FILE DIRECTORY

global gitfolder = "H:\gates-mobility-metrics"	// update path to your local mobility metrics repository folder

cd "$gitfolder"


///// 2. IMPORT and CLEAN DATA

*****County Crosswalk

import delimited using "geographic-crosswalks\data\county-file.csv"

*keep only 2017
tab year, m
keep if year == 2017

save "07_safety/crime/county_crosswalk_2017", replace


*****County crime 2018
clear

cd "$gitfolder/07_safety/crime"

*cant get the zip to download, just go to site and manually download
*copy "https://www.openicpsr.org/openicpsr/project/108164/version/V3/download/terms?path=/openicpsr/108164/fcr:versions/V3/county_ucr_offenses_known_1960_2017_dta.zip" "county_ucr_offenses_known_1960_2017_dta.zip", replace

unzipfile "county_ucr_offenses_known_1960_2017_dta.zip", replace

use county_ucr_offenses_known_yearly_1960_2017

*keep only needed variables
keep year county_name state coverage_indicator state_abb fips_state_code fips_county_code fips_state_county county_population actual_index_property actual_index_violent 

*keep only most recent year
tab year, m
keep if year == 2017

*rename variables to match county crosswalk file
rename (state state_abb fips_state_code fips_county_code fips_state_county actual_index_violent actual_index_property) (state_name state_abv state county statecounty violent_crime_count property_crime_count)

*destring fips
destring state, replace
destring county, replace

*check for duplicates
duplicates r statecounty

save crime_county_2017, replace	



///// 3. MERGE

use county_crosswalk_2017, clear

merge 1:1 state county using crime_county_2017

*br if _merge != 3

drop if _merge == 2



///// 4. CLEAN AND GENERATE RATES

*non-manhattan new york city counties seem wrong, have zeros, and missing coverage indicators. I am changing them to missing
foreach var in violent_crime_count property_crime_count {
	
	foreach  num in 5 47 81 85 {
		
		replace `var' = . if state == 36 & county == `num'
		
	}
	
}

*check missingness
tabmiss //population is more complete and likely more accurate in the crosswalk file. 12 counties are missing crime counts and coverage indicator. 

drop county_population _merge

*generate rates
foreach var in violent property {
	
	gen `var'_crime_rate = (`var'_crime_count/population)*100000 if `var'_crime_count != . & population != .
	
}

*check values
sum violent_crime_rate property_crime_rate //property crime is a little low, probably because it is missing juristictions outside of counties including state juristictions
*use the FBI UCR website to check totals and spot check county values
*https://ucr.fbi.gov/crime-in-the-u.s/2017/crime-in-the-u.s.-2017/topic-pages/violent-crime



///// 5. FINALIZE DATA and EXPORT

*order variables appropriatly and sort dataset
order year state state_name county county_name population violent_crime_count violent_crime_rate property_crime_count property_crime_rate coverage_indicator, first

gsort year state county

*create data quality index
sum coverage_indicator
gen data_quality = 2
replace data_quality = 1 if coverage_indicator >= 95 & coverage_indicator != .
replace data_quality = 3 if coverage_indicator < 50 & coverage_indicator != .
replace data_quality = . if violent_crime_rate == . & property_crime_rate == .
tab data_quality, m

tabmiss

save 2017_crime_by_county, replace

*export as CSV
export delimited using "crimerate_county_2017.csv", replace
