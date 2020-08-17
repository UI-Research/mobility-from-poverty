*********************************
*	Safety Metrics				*
*	Crime Rates - County 2018	*
*	Lily Robin, 2019.6.25		*
*********************************


cd "C:\Users\lrobin\Box Sync\Metrics Database\Safety\crime_rate"

///// IMPORT DATA


*****County FIPS
clear
import delimited county_crosswalk.csv, varnames(1) 

keep if year == 2018

save county_fipspop_2018, replace


*****County crime 2018
clear
import excel 2018_county.xls, sheet("Sheet1") firstrow case(lower)

*some blank rows got imported - drop those
drop if county == ""
	
*datasets do not include year - adding to each file
gen year = 2018

*drop all unneeded variables
keep year state county violentcrime propertycrime
	
*rename variables to camel case to match other datasets
rename (violentcrime propertycrime) (violent_crime property_crime)

save 2018_county_crimerate, replace


*****City crime 2018 (county crime file is non-inclusive of cities in counties)
clear
import excel 2018_city.xls, sheet("Sheet1") firstrow case(lower)

*some blank rows got imported - drop those
drop if city == ""

*datasets do not include year - adding to each file
gen year = 2018

*drop all unneeded variables
keep propertycrime violentcrime state city population year

*rename variables to camel case to match other datasets
rename (violentcrime propertycrime) (violent_crime_city property_crime_city)

*rename population for clarity with county populations
rename population pop_city	

save 2018_city_crimerate, replace	


*****Crosswalk files to match cities and counties
import delimited "zip_code_database.csv", clear

rename county county_name

save city_to_countyname, replace

clear
use city_to_countyname

keep primary_city state county_name irs_estimated_population_2015

*change state abbreviations to state names to match merge files
replace state = "ALABAMA" if state == "AL"
replace state = "ALASKA" if state == "AK"
replace state = "ARIZONA" if state == "AZ"
replace state = "ARKANSAS" if state == "AR"
replace state = "CALIFORNIA" if state == "CA"
replace state = "COLORADO" if state == "CO"
replace state = "CONNETICUT" if state == "CT"
replace state = "DELAWARE" if state == "DE"
replace state = "FLORIDA" if state == "FL"
replace state = "GEORGIA" if state == "GA"
replace state = "HAWAII" if state == "HI"
replace state = "IDAHO" if state == "ID"
replace state = "ILLINOIS" if state == "IL"
replace state = "INDIANA" if state == "IN"
replace state = "IOWA" if state == "IA"
replace state = "KANSAS" if state == "KS"
replace state = "KENTUCKY" if state == "KY"
replace state = "LOUISIANA" if state == "LA"
replace state = "MAINE" if state == "ME"
replace state = "MARYLAND" if state == "MD"
replace state = "MASSACHUSETTS" if state == "MA"
replace state = "MICHIGAN" if state == "MI"
replace state = "MINNESOTA" if state == "MN"
replace state = "MISSISSIPPI" if state == "MS"
replace state = "MISSOURI" if state == "MO"
replace state = "MONTANA" if state == "MT"
replace state = "NEBRASKA" if state == "NE"
replace state = "NEVADA" if state == "NV"
replace state = "NEW HAMPSHIRE" if state == "NH"
replace state = "NEW JERSEY" if state == "NJ"
replace state = "NEW MEXICO" if state == "NM"
replace state = "NEW YORK" if state == "NY"
replace state = "NORTH CAROLINA" if state == "NC"
replace state = "NORTH DAKOTA" if state == "ND"
replace state = "OHIO" if state == "OH"
replace state = "OKLAHOMA" if state == "OK"
replace state = "OREGON" if state == "OR"
replace state = "PENNSYLVANIA" if state == "PA"
replace state = "ROADE ISLAND" if state == "RI"
replace state = "SOUTH CAROLINA" if state == "SC"
replace state = "SOUTH DAKOTA" if state == "SD"
replace state = "TENNESSEE" if state == "TN"
replace state = "TEXAS" if state == "TX"
replace state = "UTAH" if state == "UT"
replace state = "VERMONT" if state == "VT"
replace state = "VIRGINIA" if state == "VA"
replace state = "WASHINGTON" if state == "WA"
replace state = "WEST VIRGINIA" if state == "WV"
replace state = "WISCONSIN" if state == "WI"
replace state = "WYOMING" if state == "WY"
replace state = "DISTRICT OF COLUMBIA" if state == "DC"

*create merge variable
gen state_name = trim(state)
gen city_name = trim(primary_city)

egen citystate = concat(city_name state_name), p(-)

*drop duplicates and missing
drop if citystate == "-"
drop if county == ""

*drop any variables in teritories not included in city file
gen state_length = length(state_name)
drop if state_length == 2
tab state_name

*drop duplicates
bysort citystate: egen city_pop = total(irs_estimated_population_2015)
drop state_length irs_estimated_population_2015 primary_city

duplicates r
duplicates drop

*identify cities in multiple counties
duplicates r citystate
duplicates tag citystate , gen(multi_county)

save city_to_county, replace


///// CROSSWALK CITY DATA TO MATCH TO COUNTIES
clear 
use 2018_city_crimerate

*remove endnotes
forval i = 0/9 {
    
	replace state = subinstr(state, "`i'", "",.)
	replace city = subinstr(city, "`i'", "",.)
}

replace city = subinstr(city, ",", "",.)

gen state_name = trim(state)
gen city_name = trim(city)

drop city state

egen citystate = concat(city_name state_name), p(-)

merge 1:m citystate using city_to_county

gen missing_city = (_merge == 2)
 
gsort citystate
*br if _merge < 3

drop _merge state

replace state_name = proper(state_name)

save 2018_city_crimerate_working, replace


///// CLEAN COUNTY DATA

clear
use 2018_county_crimerate

*datasets include endnotes that disrupt state and county names - remove endnotes
forval i = 0/9 {
    
	replace state = subinstr(state, "`i'", "",.)
	replace county = subinstr(county, "`i'", "",.)
}

*state includes metropolitan county or nonmetropolitan county in the name - split into seperate variables 
split state, p(-)
drop state
rename (state1 state2) (state county_type)
replace county_type = trim(county_type)
tab county_type, m
tab state, m

*most counties are the county name, some include "county" or information like "police department" which needs to be removed - using split to cover various names that start with the same word
split county, p(County)
drop county2
split county1, p(Police)
drop county1 county12
rename county11 county2
split county2, p(Public)
drop county2 county22
rename county county_raw
rename county21 county

*some county values end in commas - remove
replace county = subinstr(county, ",", "",.)

*ran the below code to check for any other weird endings to county names
/*
split county, p(" ")
tab county2
tab county3
tab county4
drop county1 county2 county3 county4
*/

tab county

*after alterations, state and county variables include extra spaces, and state values need to be in proper case to match crosswalk file
replace state = trim(state)
replace state = proper(state)
replace county = trim(county)

*renaming state and county variables to match the crosswalk file with FIPS and Population data to end in County or Parish
gen county_name_end = " County"
gen county_name_end_la = " Parish"
egen county_name = concat(county county_name_end) if state != "Louisiana"
egen county_name1 = concat(county county_name_end_la) if state == "Louisiana"
replace county_name = county_name1 if state == "Louisiana"
drop county county_name_end county_name_end_la county_name1

rename state state_name

*Fix mispellings in county names (this is for 2015 - 2018, just wont make changes that dont apply to 2018)
replace county_name = "Bartholomew County" if county_name == "Bartholemew County" & state_name == "Indiana"

replace county_name = "Dekalb County" if county_name == "De Kalb County" & state_name == "Indiana"

replace county_name = "Dekalb County" if county_name == "DeKalb County" & state_name == "Indiana"

replace county_name = "Dekalb County" if county_name == "De Kalb County" & state_name == "Illinois"

replace county_name = "Dekalb County" if county_name == "DeKalb County" & state_name == "Illinois"

replace county_name = "De Witt County" if county_name == "DeWitt County" & state_name == "Illinois"

replace county_name = "Doña Ana County" if county_name == "Dona Ana County" & state_name == "New Mexico"

replace county_name = "Dutchess County" if county_name == "Duchess County" & state_name == "New York"

replace county_name = "LaSalle County" if county_name == "La Salle County" & state_name == "Illinois"

replace county_name = "LaSalle Parish" if county_name == "La Salle Parish" & state_name == "Louisiana"

replace county_name = "LaMoure County" if county_name == "Lamoure County" & state_name == "North Dakota"

replace county_name = "Storey County" if county_name == "Story County" & state_name == "Nevada"

replace county_name = "LaPorte County" if county_name == "La Porte County" & state_name == "Indiana"

replace county_name = "Lac qui Parle County" if county_name == "Lac Qui Parle County" & state_name == "Minnesota"

replace county_name = "Sanborn County" if county_name == "Shannon County" & state_name == "South Dakota"

replace county_name = "Trousdale County" if county_name == "Hartsville/Trousdale County" & state_name == "Tennessee"

replace county_name = "Richmond County" if county_name == "Augusta-Richmond County" & state_name == "Georgia"

replace county_name = "Carson City" if county_name == "Carson City County" & state_name == "Nevada"

*check missing
tabmiss

*check for duplicates
duplicates tag state_name county_name year, gen(dup)
*br if dup > 0
*many duplicate observations have "police department" or other modifier in the county name and observatiosn with just the county name. I am not sure if these should be added or default to the larger number which appears to be the observation with a modifier to the county name. I am using the later option. 
gsort state_name county_name year -violent_crime
by state_name county_name year: gen obs = _n

*check # of unique values to retain - 2,338 and drop duplicates
tab obs

drop if dup > 0 & obs > 1

drop dup obs county_raw

duplicates r state_name county_name year

*save clean
save 2018_county_crimerate_working, replace


///// CROSSWALK

use county_fipspop_2018

*Dekalb Illinois is spelled 2 ways in using so correcting to the lower case "k" version (this is for 2015 to 2018, want to keep 2018 consistent for multi-year)
replace county_name = "Dekalb County" if county_name == "DeKalb County" & state_name == "Illinois"
replace county_name = "Dekalb County" if county_name == "DeKalb County" & state_name == "Indiana"

save county_crosswalk_2018, replace

clear
use 2018_county_crimerate_working

merge 1:1 state_name county_name year using county_crosswalk_2018

tab county_name if _merge == 1

save 2018_county_crimerate_working, replace
/*
I have made all change in states below in the code above (this is for 2015 - 2018) 

*check Louisiana (Parish) and Alaska (Bureau)
tab county_name if _merge == 1 & state_name == "Louisiana"
tab county_name if _merge == 2 & state_name == "Louisiana"
tab county_name if _merge == 1 & state_name == "Alaska"
*looks like all Louisiana counties need to be changes from "county" to "parish." Alaska looks correct

*tab county_name state_name if _merge == 1
*In Master
	*change Bartholemew, IN to Bartholomew, IN; De Kalb, IN to Dekalb; DeWitt to De Witt ; Dona Ana to Don(~)a Ana, NM; Duchess to Dutchess, NY; La Salle County to LaSalle County, IL; La Salle Parish to LaSalle Parish, LA; Lamoure to LaMoure, ND; story to storey, NV; La Porte to LaPorte, IN; Lac Qui Parle to Lac qui Parle, MN; Carson City County to Carson City, NV
	*Looks like if shannon should be sanborn, SD in 2015 but all 0 values anyways so better to drop?
	*check if Hartsville/Trousdal can be changed to just Trousdale, TN
	*check if Augusta-Richmond can be changed to just Richmond, GA
*/

*using has Bureau, Census Area, Municipality


///// ADD CITIES TO THE COUNTYS DATA
*"These data do not represent county totals as they exclude crime counts for city agencies and other types of agencies that have jurisdiction within each county."

clear 
use 2018_county_crimerate_working

drop _merge

merge 1:m county_name state_name using 2018_city_crimerate_working, force

*could potentially do more cleaning at this point to identfy if any of the 27 unmatched from master match any of the 2,853 unmatched from using
drop if _merge == 2

save 2018_countycity_crimerate_working, replace


///// COLLAPSE TO COUNTY LEVEL

*by county: # of cities, pop, # reporting, reporting pop
bysort state county: gen obs = _n
bysort state county: gen cities = _N
bysort state county: egen cities_pop = total(city_pop)
gen city_reporting = 1 if violent_crime_city != . | property_crime_city != .
bysort state county: egen cities_reporting = total(city_reporting)
gen city_reporting_pop = city_pop if city_reporting == 1
bysort state county: egen cities_reporting_pop = total(city_reporting_pop)

*county and total county/city rates
rename (violent_crime property_crime) (county_agency_violent_crime county_agency_property_crime)
bysort state county: egen violent_crime = total(violent_crime_city)
replace violent_crime = violent_crime + county_agency_violent_crime
bysort state county: egen property_crime = total(property_crime_city)
replace violent_crime = property_crime + county_agency_property_crime

*calculate rates
gen violent_crime_rate = (violent_crime/population)*100000
gen property_crime_rate = (property_crime/population)*100000

*missingness and overlap
gen pop_missing = (cities_pop - cities_reporting_pop)/population
gen cities_missing = cities_reporting/cities
*is any city within this county also in another county
bysort state county: egen any_multi_county = max(multi_county)
gen missing = (county_agency_violent_crime == . & county_agency_property_crime == .)

*reduce to one observation per county
drop pop_city violent_crime_city property_crime_city city_name citystate city_pop _merge obs city_reporting city_reporting_pop missing_city multi_county

duplicates drop

duplicates r state county



///// FINALIZE DATA and EXPORT

*add leading 00s to FIPS
gen state_new = string(state, "%02.0f")
gen county_new = string(county, "%03.0f")
drop state county
rename (state_new county_new) (state county)

*order variables appropriatly and sort dataset
order year state county state_name county_name county_type population violent_crime property_crime violent_crime_rate property_crime_rate cities cities_pop cities_reporting cities_reporting_pop cities_missing pop_missing any_multi_county county_agency_violent_crime county_agency_property_crime missing , first

gsort year state county

save crimerate_county_2018, replace

*export as CSV
export delimited using "crimerate_county_2018.csv", replace


/*
foreach var in population violent_crime property_crime violent_crime_rate property_crime_rate {
	
	tostring `var', replace force
	replace `var' = "" if `var' == "."
}

export delimited using "C:\Users\lrobin\Box Sync\Metrics Database\Safety\test_string.csv", replace
*/