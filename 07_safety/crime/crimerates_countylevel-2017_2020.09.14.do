*********************************
*	Safety Metrics				*
*	Crime Rates - County 2017	*
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
*https://www.openicpsr.org/openicpsr/project/108164/version/V3/view
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

*account for some chenged/mismerged counties: change Shannon county to Oglola Lakota County (http://ddorn.net/data/FIPS_County_Code_Changes.pdf), combine Bedfor city (former independant city) with Bedford county

replace county = 102 if state == 46 & county == 113

replace county = 019 if state == 51 & county == 515
replace statecounty = "51019" if state == 51 & county == 019

foreach var in county_population violent_crime_count property_crime_count {
	
	bysort statecounty: egen `var'_bedford = total(`var')
	
	replace `var' = `var'_bedford if statecounty == "51019"
}

replace county_name = "Bedford County" if statecounty == "51019"

drop county_population_bedford violent_crime_count_bedford property_crime_count_bedford

duplicates drop

*save
save crime_county_2017, replace	



///// 3. MERGE

use county_crosswalk_2017, clear

merge 1:1 state county using crime_county_2017

*br if _merge != 3

drop if _merge == 2



///// 4. CLEAN AND GENERATE RATES

*county populations in crime file appear to be off, and not by the amount indicated by the coverage indicator. 
gen pop_check = county_population/population
sum pop_check
gen pop_coverage = pop_check - coverage_indicator
sum pop_coverage
drop pop_coverage pop_check

*new york county appears to have crime counts for whole city. Will apply these counts and entire city pop to each nyc county with a note (using row total to account for any counts in other counties just in case)
gen ny = 0
replace ny = 1 if (state == 36 & county == 5) | (state == 36 & county == 47) | (state == 36 & county == 81) | (state == 36 & county == 85) | (state == 36 & county == 61)

foreach var in violent_crime_count property_crime_count county_population {
		
	bysort ny: egen `var'_ny = total(`var')
	
}

foreach var in violent_crime_count property_crime_count county_population {
	
	replace `var' = `var'_ny if state == 36 & county == 61
			
}

foreach val in 5 47 81 85 {
		
		foreach var in violent_crime_count property_crime_count county_population {
	
			replace `var' = . if state == 36 & county == `val'
			
		}
		
		replace coverage_indicator = . if state == 36 & county == `val'
}

replace coverage_indicator = . if state == 36 & county == 61

drop ny violent_crime_count_ny property_crime_count_ny county_population_ny

*check missingness
tabmiss //population is more complete and likely more accurate in the crosswalk file. 11 counties are missing crime counts and coverage indicator. 

drop county_population _merge

*generate rates

/* cannot use this code because of imputation, not accounted for in coverage indicator
gen pop_covered = population*coverage_indicator
replace pop_covered = population if coverage_indicator == 0
*/

foreach var in violent property {
	
	gen `var'_crime_rate = (`var'_crime_count/population)*100000
	
}

*check values
sum violent_crime_rate property_crime_rate //property crime is a little low, probably because it is missing juristictions outside of counties including state juristictions
*use the FBI UCR website to check totals and spot check county values
*https://ucr.fbi.gov/crime-in-the-u.s/2017/crime-in-the-u.s.-2017/topic-pages/violent-crime



///// 5. FINALIZE DATA and EXPORT

drop state_name county_name population violent_crime_count property_crime_count 

*order variables appropriatly and sort dataset
rename coverage_indicator coverage_indicator_crime

order year state county violent_crime_rate property_crime_rate coverage_indicator_crime, first

gsort year state county

*create data quality index
sum coverage_indicator
gen crime_rate_quality = .
replace crime_rate_quality = 1 if coverage_indicator == 100 & coverage_indicator != .
replace crime_rate_quality = 2 if coverage_indicator < 100 & coverage_indicator >= 80 & coverage_indicator != .
replace crime_rate_quality = 3 if coverage_indicator < 80 & coverage_indicator != .
replace crime_rate_quality = . if violent_crime_rate == . & property_crime_rate == .

foreach val in 5 47 81 85 61 {
		
	replace crime_rate_quality = 3 if state == 36 & county == `val'
}

tab crime_rate_quality, m

tabmiss

save 2017_crime_by_county, replace

*export as CSV
export delimited using "crimerate_county_2017.csv", replace
