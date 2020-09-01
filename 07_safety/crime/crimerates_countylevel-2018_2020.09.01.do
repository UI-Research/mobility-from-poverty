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

*****Crosswalk files to match cities and counties
*copy "https://www.unitedstateszipcodes.org/zip-code-database/#" zip_code_database.csv, replace
*this website requires filing out a questionair to download, so I think it has to be downloaded manually

import delimited "zip_code_database.csv", clear

save city_to_county, replace

*****County crime 2018
clear
copy "https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-10/table-10.xls" crime_county_2018.xls, replace

import excel crime_county_2018.xls, cellrange(A5) firstrow case(lower)

save crime_county_2018, replace

*****City crime 2018 (county crime file is non-inclusive of cities in counties)
clear

copy "https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-8/table-8.xls" crime_city_2018.xls, replace

import excel crime_city_2018.xls, cellrange(A4) firstrow case(lower)

save crime_city_2018, replace	


///// 3. CLEAN CROSSWALK FILE TO MATCH CITIES TO COUNTIES

use city_to_county, clear

rename county county_name

*change state abbreviations to state names to match merge files (requires instalation of statastates package)
statastates, abbreviation(state)
tab state if _merge == 1
*these are all US territories that are not included in the crime files - can be dropped
drop if _merge != 3

*keep county, city pop, city name, and alternate city names
keep primary_city acceptable_cities state state_name state_fips county_name irs_estimated_population_2015

*capture all alternate city names
split acceptable_cities, p(,) gen(city)
forval i = 1/31 {
	
	replace city`i' = trim(city`i')
}

rename primary_city city0

keep state county_name irs_estimated_population_2015 state_name state_fips city*

gen obs = _n

reshape long city, i(obs) j(city_num)

drop if city == ""

*make all proper case and remove spaces and make other changes for consistency
replace city = subinstr(city, "-", "", .)
replace city = subinstr(city, "'", "", .)
replace city = subinstr(city, "Ft ", "Fort ", .)
replace city = subinstr(city, " ", "", .)
replace city = proper(city)

*create merge variable
replace state_name = trim(state_name)
gen city_name = trim(city)

egen citystate = concat(city_name state_name), p(-)

*drop missing
drop if county == ""

*identify duplicates
duplicates tag city_name state_name, gen(city_dup)
duplicates tag city_name county_name state_name, gen(dup)
tab city_dup
tab dup
*br if city_dup > 0 & dup == 0

*use largest pop for duplicates and drop full duplicates
egen place = concat(city_name state_name county_name), p("-")
duplicates r place 

gen primary = (city_num == 0)
bysort place: egen primary_place = max(primary)
drop primary
tab primary_place, m

bysort place: egen city_pop = total(irs_estimated_population_2015)
replace irs_estimated_population_2015 = city_pop if dup > 0
rename irs_estimated_population_2015 city_pop_in_county
drop city_pop city dup city_dup obs city_num

duplicates r
duplicates drop

*identify cities in multiple counties
duplicates r citystate
duplicates tag citystate, gen(multi_county)

save city_to_county, replace


///// 4. CLEAN COUNTY CRIME DATA

use crime_county_2018, clear

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


*datasets include endnotes that disrupt state and county names - remove endnotes
gen annual_reporting_change = (strmatch(state, "*5*"))
replace annual_reporting_change = 1 if (strmatch(county, "*5*"))

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
*replace county_name = "Bartholomew" if county_name == "Bartholemew" & state_name == "Indiana"
*replace county_name = "Doñaana" if county_name == "Donaana" & state_name == "New Mexico"
*replace county_name = "Dutchess" if county_name == "Duchess" & state_name == "New York"
*replace county_name = "Storey" if county_name == "Story" & state_name == "Nevada"
*replace county_name = "Sanborn" if county_name == "Shannon" & state_name == "South Dakota"
replace county_name = "Trousdale" if county_name == "Hartsville/Trousdale" & state_name == "Tennessee"
*replace county_name = "Richmond" if county_name == "Augusta-Richmond" & state_name == "Georgia"

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


///// 5. CLEAN CITY CRIME DATA

use crime_city_2018, clear

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

*identify any with county noted
tab city if strmatch(city, "*County*")

gen city_testforcounty = city
split city_testforcounty, p("Township ") 
gen county_name_fromcity = ""
replace county_name_fromcity = city_testforcounty2 if strmatch(city, "*County*")
tab county_name_fromcity
drop city_testforcounty city_testforcounty1 city_testforcounty2

tab city if strmatch(city, "*County*") & county_name_fromcity == ""
gen county_test = city if strmatch(city, "*County*") & county_name_fromcity == ""
tab county_test
replace county_test = subinstr(county_test, " Regional", "", .)
replace county_test = subinstr(county_test, " Police Department", "", .)
replace county_test = subinstr(county_test, "Metro Police Authority of ", "", .)
replace county_test = subinstr(county_test, "Reno ", "", .)
replace county_test = subinstr(county_test, "Northern ", "", .)
replace county_test = subinstr(county_test, "Northwest ", "", .)
replace county_test = subinstr(county_test, "Southern ", "", .)
replace county_test = subinstr(county_test, "Southwest ", "", .)
replace county_test = subinstr(county_test, "North East ", "", .)
replace county_test = subinstr(county_test, "Lakeview ", "", .)
replace county_test = "Washington County" if county_test == "Washington Washington County"
tab county_test
replace county_name_fromcity = county_test if county_name_fromcity == ""
drop county_test

*make all proper case and remove spaces and make other changes for consistency
replace city = subinstr(city, "St.", "saint", .)
replace city = subinstr(city, "Sheriff", "", .)
replace city = subinstr(city, "Police Department", "", .)
replace city = subinstr(city, "Regional", "", .)
replace city = subinstr(city, "Metropolitan", "", .)
replace city = subinstr(city, "-", "", .)
replace city = subinstr(city, "'", "", .)
replace city = subinstr(city, " ", "", .)
replace city = proper(city)

replace city = "Charlotte" if city == "Charlottemecklenburg"

*create merge variable
gen state_name = trim(state)
gen city_name = trim(city)

drop city state
egen citystate = concat(city_name state_name), p(-)

*check for duplicates
duplicates tag citystate, gen(dup)	

tab citystate if dup > 0

*can collapse
foreach var in pop_city violent_crime_city property_crime_city {
	
	bysort citystate: egen `var'_total = total(`var')
	replace `var' = `var'_total if dup > 0
	drop `var'_total
}

foreach var in annual_reporting_change {
	
	bysort citystate: egen `var'_max = max(`var')
	replace `var' = `var'_max if dup > 0
	drop `var'_max
}

duplicates drop

drop dup

save crime_city_2018, replace

///// 3. CROSSWALK CITY DATA TO MATCH TO COUNTIES

*****FIRST MERGE

clear 
use crime_city_2018

merge 1:m citystate using city_to_county

gsort citystate
*br if _merge < 3

save crime_city_2018_working, replace

*****REMERGE 
*make alterations to city names to merge those that didnt match the first time
use crime_city_2018_working
keep if _merge == 1
drop if county_name_fromcity != ""
drop _merge

replace city_name = subinstr(city_name, "township", "", .) if citystate != "Saintclairtownship-PENNSYLVANIA"
replace city_name = subinstr(city_name, "village", "", .) if city_name != "Thevillages"
replace city_name = subinstr(city_name, "town", "", .)
replace city_name = subinstr(city_name, "boro", "", .)
replace city_name = subinstr(city_name, "city", "", .)
split city_name, p("/")
replace city_name = city_name1

drop citystate

egen citystate = concat(city_name state_name), p(-)

duplicates tag citystate, gen(dup)

tab citystate if dup > 0

*Poland, OH, Borden, NJ, Easthampton & Fishkill & Coshjen & Hamburg & Mamaoneck & Montgomery & Southhampton, NY duplicates in same county and can be collapsed
*there is no Middle New Jesey that I can find, but only middle township comes up so that should be fine to collapse
*Saintclair borogh appears to be in using and master based on county in using and google for one ending in boro in master, the other saint clairs dont match eachother: fixed above - line 334
* I cannot tell what different cities Whites, NY  is supposed to be, none of the origanol names match eachother and they belong to different counties and the populations dont match
drop if citystate == "Whites-NEW YORK"

gen collapse_dup = 0
replace collapse_dup = 1 if citystate == "Poland-OHIO" | citystate == "Easthampton-NEW YORK" | citystate == "Fishkill-NEW YORK" | citystate == "Goshen-NEW YORK" | citystate == "Hamburg-NEW YORK" | citystate == "Mamaroneck-NEW YORK" | citystate == "Montgomery-NEW YORK" | citystate == "Southampton-NEW YORK" | citystate == "Middle-NEW JERSEY" | citystate == "Borden-NEW JERSEY" 

foreach var in pop_city violent_crime_city property_crime_city city_pop_in_county {
	
	bysort citystate: egen `var'_total = total(`var')
	replace `var' = `var'_total if collapse_dup == 1
}

foreach var in annual_reporting_change multi_county {
	
	bysort citystate: egen `var'_max = max(`var')
	replace `var' = `var'_max if collapse_dup == 1
}

drop multi_county_max annual_reporting_change_max city_pop_in_county_total property_crime_city_total violent_crime_city_total pop_city_total

duplicates drop

save crime_city_2018_working_remerge, replace

merge 1:m citystate using city_to_county

*br if _merge == 1

*drop any unmerged from master that cannot be matched to counties
drop if _merge == 1
gen merge_2 = _merge
drop _merge

save crime_city_2018_working_remerge, replace


*****APPEND TWO MERGES
use crime_city_2018_working, clear

tab _merge

drop if _merge == 1 & county_name_fromcity == ""

append using crime_city_2018_working_remerge

save crime_city_2018_working_append, replace

***file with matched cities
use crime_city_2018_working_append

keep if _merge == 3 | merge_2 == 3 | county_name_fromcity != ""

replace county_name = county_name_fromcity if county_name == ""

*create variables for proportional share of crime by population for cities in multiple counties
*for cities where listed population for city in county if more then listed pop for whole city, split evenely across the number of counties a city falls in
gen percent_pop_county = (city_pop_in_county/pop_city) if pop_city != . & city_pop_in_county != .
sum percent_pop_county
tab multi_county

foreach var in violent property {
	
	gen `var'_crime_city_share = percent_pop_county*`var'_crime_city if percent_pop_county < 1
	
	replace `var'_crime_city_share = 0.5*`var'_crime_city if `var'_crime_city_share == . & multi_county == 1 & `var'_crime_city != .
	
	replace `var'_crime_city_share = 0.3333*`var'_crime_city if `var'_crime_city_share == . & multi_county == 2 & `var'_crime_city != .
	
	replace `var'_crime_city_share = 0.25*`var'_crime_city if `var'_crime_city_share == . & multi_county == 3 & `var'_crime_city != .
	
	replace `var'_crime_city_share = 0.2*`var'_crime_city if `var'_crime_city_share == . & multi_county == 4 & `var'_crime_city != .
	
	replace `var'_crime_city = `var'_crime_city_share if `var'_crime_city_share != .
	
}

sum violent_crime_city property_crime_city 

*update populations in cities
replace pop_city = city_pop_in_county if percent_pop_county < 1 & pop_city != .

replace pop_city = pop_city*0.5 if multi_county == 1 & percent_pop_county > 1 & pop_city != .

replace pop_city = pop_city*0.3333 if multi_county == 2 & percent_pop_county > 1 & pop_city != .

replace pop_city = pop_city*0.25 if multi_county == 3 & percent_pop_county > 1 & pop_city != .

replace pop_city = pop_city*0.2 if multi_county == 4 & percent_pop_county > 1 & pop_city != .

drop county_name_fromcity city_pop_in_county _merge city_name1 city_name2 dup collapse_dup merge_2 property_crime_city_share violent_crime_city_share percent_pop_county place

*check for duplicates

duplicates r
duplicates drop

egen place = concat(city_name state_name county_name), p("-")
duplicates r place

*prepare for merge to counties
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

save crime_city_2018_withcounties, replace

***file with unmatched cities
use crime_city_2018_working_append

keep if _merge == 2 | merge_2 == 2
drop if county_name_fromcity != ""

drop pop_city violent_crime_city property_crime_city year annual_reporting_change county_name_fromcity place _merge city_name1 city_name2 dup collapse_dup merge_2 state

duplicates r
duplicates drop

duplicates r state_name city_name county_name

tab primary_place
*note that many are likely to be duplicates with alternate names, will address when merged. 

*prepare for merge to counties
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

save extra_city_2018_withcounties, replace
