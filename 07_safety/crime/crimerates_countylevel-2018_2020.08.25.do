*********************************
*	Safety Metrics				*
*	Crime Rates - County 2018	*
*	Lily Robin, 2019.6.25		*
*********************************

///// 1.UPDATE FILE DIRECTORY

cd "C:\Users\lrobin\Box Sync\Metrics Database\Safety\crime_rate"

///// 2. IMPORT DATA

*****County FIPS
clear
import delimited county_crosswalk.csv, varnames(1) 

keep if year == 2018

save county_fipspop_2018, replace


*****County crime 2018
clear
copy "https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-10/table-10.xls" crime_county_2018.xls, replace

import excel crime_county_2018.xls, cellrange(A5) firstrow case(lower)

*drop unneeded variables
keep state county violentcrime propertycrime

*fix/carryforward state names
replace state = state[_n-1] if state=="" & state[_n-1]!=""

*drop footnotes
*there are no included counties for Iowa
tab state if county == "" & violentcrime == . & propertycrime == .
drop if county == "" & violentcrime == . & propertycrime == .
	
*dataset does not include year - adding
gen year = 2018
	
*rename variables to camel case to match other datasets
rename (violentcrime propertycrime) (violent_crime property_crime)

save crime_county_2018, replace


*****City crime 2018 (county crime file is non-inclusive of cities in counties)
clear

copy "https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-8/table-8.xls" crime_city_2018.xls, replace

import excel crime_city_2018.xls, cellrange(A4) firstrow case(lower)

*drop all unneeded variables
keep state city population violentcrime propertycrime

*fix/carryforward state names
replace state = state[_n-1] if state=="" & state[_n-1]!=""

*drop footnotes
*there are no included cities for Iowa
tab state if city == "" & population == . & violentcrime == . & propertycrime == .
drop if city == "" & population == . & violentcrime == . & propertycrime == .

*dataset does not include year - adding
gen year = 2018

*rename variables to camel case to match other datasets
rename (violentcrime propertycrime) (violent_crime_city property_crime_city)

*rename population for clarity with county populations
rename population pop_city	

*remove endnotes
gen annual_reporting_change = (strmatch(state, "*4*"))
replace annual_reporting_change = 1 if (strmatch(city, "*4*"))

forval i = 0/9 {
    
	replace state = subinstr(state, "`i'", "",.)
	replace city = subinstr(city, "`i'", "",.)
}

replace city = subinstr(city, ",", "",.)
/*
*create merge variable
*check duplicates to ensure changes dont make fake duplicates
duplicates r city state
*Remove endings
gen city_test = city
replace city_test = subinstr(city_test, " Township", "",.)
replace city_test = subinstr(city_test, " City", "",.)
replace city_test = subinstr(city_test, " Borough", "",.)
replace city_test = subinstr(city_test, " Village", "",.)
*make all proper case and remove spaces
replace city_test = subinstr(city_test, " ", "", .)
replace city_test = proper(city_test)
*There are duplicates when this is done. Many with and without "Township" ending mostly. Unclear if these are the same or different cities. 
duplicates r city_test state
duplicates tag city_test state, gen(dup)
br if dup > 0
*/
*make all proper case and remove spaces
replace city = subinstr(city, " ", "", .)
replace city = proper(city)

*create merge variable
gen state_name = trim(state)
gen city_name = trim(city)

drop city state
egen citystate = concat(city_name state_name), p(-)

save crime_city_2018, replace	


*****Crosswalk files to match cities and counties
*copy "https://www.unitedstateszipcodes.org/zip-code-database/#" zip_code_database.csv, replace
*this website requires filing out a questionair to download, so I think it has to be downloaded manually

import delimited "zip_code_database.csv", clear

rename county county_name

*change state abbreviations to state names to match merge files (requires instalation of statastates package)
statastates, abbreviation(state)
tab state if _merge == 1
*these are all US territories that are not included in the crime files - can be dropped
drop if _merge != 3

keep primary_city state state_name state_fips county_name irs_estimated_population_2015

*make all proper case and remove spaces
replace primary_city = subinstr(primary_city, " ", "", .)
replace primary_city = proper(primary_city)

*create merge variable
replace state_name = trim(state_name)
gen city_name = trim(primary_city)

egen citystate = concat(city_name state_name), p(-)

*drop duplicates and missing
drop if citystate == "-"
drop if county == ""

*drop any variables in teritories not included in city file
gen state_length = length(state_name)
drop if state_length == 2
tab state_name

*identify duplicates
duplicates tag city_name state_name, gen(city_dup)
duplicates tag city_name county_name state_name, gen(dup)
tab city_dup
tab dup
*br if city_dup > 0 & dup == 0

*use largest pop for duplicates and drop full duplicates
bysort citystate: egen city_pop = total(irs_estimated_population_2015)
replace irs_estimated_population_2015 = city_pop if dup > 0
rename irs_estimated_population_2015 city_pop_in_county
drop state_length city_pop primary_city dup city_dup

duplicates r
duplicates drop

*identify duplicates of cities in multiple counties
duplicates tag city_name county_name state_name, gen(dup)
tab dup
drop dup

*identify cities in multiple counties
duplicates r citystate
duplicates tag citystate , gen(multi_county)

save city_to_county, replace


///// 3. CROSSWALK CITY DATA TO MATCH TO COUNTIES
clear 
use crime_city_2018

merge 1:m citystate using city_to_county

gen missing_city = (_merge == 2)
 
gsort citystate
*br if _merge < 3

drop _merge state

replace state_name = proper(state_name)

*remove county/parish/burough endings
replace county_name = subinstr(county_name, " County", "", .)
replace county_name = subinstr(county_name, " Parish", "", .)
replace county_name = subinstr(county_name, " Borough", "", .)
replace county_name = subinstr(county_name, " Census Area", "", .)
replace county_name = subinstr(county_name, " Municipality", "", .)
*not removing city because there are places like St. Louis county, MO and St. Louis city, MO that are both in the file, and different

*make all proper case and remove spaces
replace county_name = subinstr(county_name, " ", "", .)
replace county_name = proper(county_name)

save crime_city_2018_working, replace


///// 4. CLEAN COUNTY CRIME DATA
clear
use crime_county_2018

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

*create county name with consistent capitalization and spacing
replace county = subinstr(county, " ", "", .)
replace county = proper(county)

rename county county_name
rename state state_name

*Fix mispellings in county names (this is for 2015 - 2018, just wont make changes that dont apply to 2018)
replace county_name = "Bartholomew" if county_name == "Bartholemew" & state_name == "Indiana"
replace county_name = "Doñaana" if county_name == "Donaana" & state_name == "New Mexico"
replace county_name = "Dutchess" if county_name == "Duchess" & state_name == "New York"
replace county_name = "Storey" if county_name == "Story" & state_name == "Nevada"
replace county_name = "Sanborn" if county_name == "Shannon" & state_name == "South Dakota"
replace county_name = "Trousdale" if county_name == "Hartsville/Trousdale" & state_name == "Tennessee"
replace county_name = "Richmond" if county_name == "Augusta-Richmond" & state_name == "Georgia"

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
save crime_county_2018_working, replace


///// 5. CROSSWALK COUNTY CRIME DATA TO FIPS and POPULATION DATA 
clear
use county_fipspop_2018

*remove county/parish/burough endings
replace county_name = subinstr(county_name, " County", "", .)
replace county_name = subinstr(county_name, " Parish", "", .)
replace county_name = subinstr(county_name, " Borough", "", .)
replace county_name = subinstr(county_name, " Census Area", "", .)
replace county_name = subinstr(county_name, " Municipality", "", .)
*not removing city because there are places like St. Louis county, MO and St. Louis city, MO that are both in the file, and different

*make all proper case and remove spaces
replace county_name = subinstr(county_name, " ", "", .)
replace county_name = proper(county_name)

*Fix mispellings in county names (this is for 2015 - 2018, just wont make changes that dont apply to 2018)
replace county_name = "Doñaana" if county_name == "DoñAana" & state_name == "New Mexico"

save county_crosswalk_2018, replace

clear
use crime_county_2018_working

merge 1:1 state_name county_name year using county_crosswalk_2018

drop _merge

save crime_county_2018_working, replace
/*
I have made all change in states below in the code above (this is for 2015 - 2018) 

*tab county_name state_name if _merge == 1
*In Master
	*change Bartholemew, IN to Bartholomew, IN; Dona Ana to Don(~)aana, NM; Duchess to Dutchess, NY; story to storey, NV
	*Looks like shannon should be sanborn, SD in 2015 but all 0 values anyways so better to drop?
	*check if Hartsville/Trousdal can be changed to just Trousdale, TN
	*check if Augusta-Richmond can be changed to just Richmond, GA
*/


///// 6. ADD CITIES TO THE COUNTYS DATA
*"These data do not represent county totals as they exclude crime counts for city agencies and other types of agencies that have jurisdiction within each county."

clear 
use crime_county_2018_working

merge 1:m county_name state_name using crime_city_2018_working

*br if _merge == 2 & county_name != ""

/*
Alaska, Kusilvak - not in city file
District of Columbia, Districtofcolumbia - state name is District Of Columbia in city file
New Mexico, Doñaana - add ñ to city file
South Dakota, Oglalalakota - not in city file
Virginia, Covingtoncity - not in city file
Virginia, Emporiacity - not in city file
Virginia, Lexingtoncity - not in city file
Virginia, Manassasparkcity - not in city file

*/

*
drop if _merge == 2 & state_name != "District Of Columbia"
drop if state_name == "District Of Columbia" & year == .

save 2018_countycity_crimerate_working, replace


///// 7. COLLAPSE TO COUNTY LEVEL

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
bysort state county: egen violent_crime_cities = total(violent_crime_city)
egen violent_crime = rowtota(violent_crime_cities county_agency_violent_crime)
bysort state county: egen property_crime = total(property_crime_city)
egen property_crime = rowtota(property_crime_cities county_agency_property_crime)

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



///// 8. FINALIZE DATA and EXPORT

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