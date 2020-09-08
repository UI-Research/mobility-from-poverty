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

tostring(state), gen(state_fips) format(%02.0f)
tostring(county), gen(county_fips) format(%03.0f)
egen countystate = concat(state_fips county_fips)

drop state_fips county_fips

save county_fipspop_2018, replace

*****Crosswalk files to match cities and counties

import delimited "geocorr2018.csv", varnames(1) clear 

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

drop in 1

rename (placefp14 county14 stab cntyname2 placenm14) (place countystate state_abbrev county_name_full place_name)

*change state abbreviations to state names to match merge files (requires instalation of statastates package)
statastates, abbreviation(state_abbrev)

keep state place countystate state_name state_abbrev county_name_full place_name pop10

destring state, replace
destring pop10, replace

*check St. and Fort
tab place_name if strmatch(place_name, "*St.*")
tab place_name if strmatch(place_name, "*Saint*")
tab place_name if strmatch(place_name, "*St *")
tab place_name if strmatch(place_name, "*Fort*")
tab place_name if strmatch(place_name, "*Ft.*")
tab place_name if strmatch(place_name, "*Ft *")

*make all proper case and remove spaces and make other changes for consistency
split place_name, p(",")

tab place_name2
tab place_name3
tab place_name1 place_name2 if place_name3!= ""
egen place_name4 = concat(place_name1 place_name2) if place_name3 != ""
tab place_name4
replace place_name1 = place_name4 if place_name3 != ""
gen city = place_name1
drop place_name1 place_name2 place_name3 place_name4

gen city_name = city

duplicates r city_name countystate
duplicates r city_name state

replace city_name = subinstr(city_name, "(balance)", "", .)
replace city_name = regexr(city_name, "city$", "")
replace city_name = regexr(city_name, "CDP$", "")
replace city_name = regexr(city_name, "city and borough$", "")
replace city_name = subinstr(city_name, "'", "", .)
replace city_name = subinstr(city_name, " ", "", .)
replace city_name = proper(city_name)

replace state_name = proper(state_name)

duplicates r city_name countystate
duplicates tag city_name countystate, gen(dup)
*br if dup > 0

*in the same county, can combine (using force because I am keeping origanol city/place names to check merges)
bysort city_name countystate: egen pop_tot = total(pop10)
replace pop10 = pop_tot if dup > 0

duplicates drop city_name countystate, force
drop dup city pop_tot

duplicates r city_name state

*create merge variable
replace state_name = trim(state_name)
replace city_name = trim(city_name)

drop if city_name == ""

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
renam state state_name
replace state_name = trim(state_name)

*add in state abbreviations
statastates, name(state_name)
tab state_name if _merge == 2
*there is no county data for Alaska, Connecticut, Iowa, Massachusettes, or Rhode Island. DC is in the city file.
drop if _merge == 2
drop _merge
rename state_fips state

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
replace state_name = trim(state_name)
replace state_name = proper(state_name)
replace county = trim(county)

*create county name with consistent capitalization and spacing
replace county = subinstr(county, " ", "", .)
replace county = proper(county)

rename county county_name

*Fix mispellings in county names (this is for 2015 - 2018, just wont make changes that dont apply to 2018)
*replace county_name = "Bartholomew" if county_name == "Bartholemew" & state_name == "Indiana"
*replace county_name = "Doñaana" if county_name == "Donaana" & state_name == "New Mexico"
*replace county_name = "Dutchess" if county_name == "Duchess" & state_name == "New York"
*replace county_name = "Storey" if county_name == "Story" & state_name == "Nevada"
*replace county_name = "Sanborn" if county_name == "Shannon" & state_name == "South Dakota"
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
compress
total violent_crime_city
*900777

rename state state_name

split city, gen(city_part)

gen county_name = city_part5 + " " + city_part6 if city_part6=="County"
replace county_name = city_part4 + " " + city_part5 if city_part6=="" & city_part5=="County"
replace county_name = city_part3 + " " + city_part4 if city_part5=="" & city_part4=="County"
replace county_name = city_part2 + " " + city_part3 if city_part4=="" & city_part3=="County"

tab county_name

** manual counties **
replace county_name = "Berrien County" if inlist(city, "St Joseph", "St Joseph Township") & state_name=="MICHIGAN"
replace county_name = "Luzerne County" if inlist(city, "Wilkes-Barre", "Wilkes-Barre Township") & state_name=="PENNSYLVANIA"
replace county_name = "Clinton County" if inlist(city, "DeWitt", "DeWitt Township") & state_name=="MICHIGAN"
replace county_name = "Mahoning County" if inlist(city, "Poland Village", "Poland Township") & state_name=="OHIO"
replace county_name = "Greene County" if regexm(city, "Greene County")==1
replace county_name = "Camden County" if regexm(city, "Camden County")==1
replace county_name = "York County" if regexm(city, "Northeast")==1 & state_name=="PENNSYLVANIA"
replace county_name = city if regexm(city, "Borough")==1 & state_name=="ALASKA" 

** these are picking up biggest crime rate cities (violent crime >=100) that aren't picked up elsewhere
replace county_name = "Berrien County" if regexm(city, "Benton Township")==1 & state_name=="MICHIGAN" // this seemed like the best match given the population
replace county_name = "DeKalb County" if regexm(city, "Brookhaven")==1 & state_name=="GEORGIA" 
replace county_name = "St. Louis County" if regexm(city, "Vinita Park")==1 & state_name=="MISSOURI" // note populations seem inconsistent
replace county_name = "St. Louis County" if regexm(city, "Bellefontaine Neighbors")==1 & state_name=="MISSOURI"
replace county_name = "York County" if regexm(city, "York Area Regional")==1 & state_name=="PENNSYLVANIA" 
replace county_name = "Barnstable County" if regexm(city, "Yarmouth")==1 & state_name=="MASSACHUSETTS" 
replace county_name = "Jefferson County" if regexm(city, "Tarrant")==1 & state_name=="ALABAMA" 

drop city_part*

*check St. and Fort
tab city if strmatch(city, "*St.*")
tab city if strmatch(city, "*Saint*")
tab city if strmatch(city, "*St *")
tab city if strmatch(city, "*Fort*")
tab city if strmatch(city, "*Ft.*")
tab city if strmatch(city, "*Ft *")

*make all proper case and remove spaces and make other changes for consistency
gen city_name = city

replace city_name = subinstr(city_name, "Sheriff", "", .)
replace city_name = subinstr(city_name, "Police Department", "", .)
replace city_name = subinstr(city_name, "Regional", "", .)
replace city_name = subinstr(city_name, "Metropolitan", "", .)
*replace city_name = regexr(city_name, "City$", "")
*replace city_name = regexr(city_name, "City $", "")
replace city_name = subinstr(city_name, "'", "", .)
replace city_name = subinstr(city_name, " ", "", .)
replace city_name = proper(city_name)

*create merge variable
replace state_name = proper(state_name)

replace state_name = trim(state_name)
replace city_name = trim(city_name)
egen citystate = concat(city_name state_name), p(-)

*check for duplicates
duplicates r citystate

duplicates tag citystate, gen(dup)
*br if dup > 0

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

*just using force so I can maintain the origanol city name variable which has regional for one of the duplicates and not for the other
duplicates drop city_name state_name, force

drop dup

*make set 0 of cities with county names for appends
preserve
keep if county_name!=""
duplicates r city_name state_name
save crime_city_2018_set0.dta, replace
restore

*save set 1 for merging
drop if county_name!=""

save crime_city_2018_1, replace


///// 3. CROSSWALK CITY DATA TO MATCH TO COUNTIES

*****FIRST MERGE

clear 
use crime_city_2018_1

duplicates r city_name state_name

merge 1:m city_name state_name using city_to_county, update

*save set 1 merged
preserve
keep if _merge >=3
duplicates r city_name state_name county_name
drop _merge
save crime_city_2018_set1.dta, replace
restore

*save set 2 for merging
keep if _merge == 1
drop _merge
duplicates r city_name state_name
save crime_city_2018_2, replace


*****SECOND MERGE
*cities separated by hyphen or /
use city_to_county

*remove "-"
tab city_name if strmatch(city_name, "*-*")
replace city_name = subinstr(city_name, "-", "", .)
replace city_name = proper(city_name)

tab city_name if strmatch(city_name, "*/*")
split city_name, p("/")
tab city_name2

replace city_name = city_name1 if city_name2 != ""
save city_to_county2, replace

*cities separated by hyphen or /
use crime_city_2018_2, clear

*remove "-"
tab city_name if strmatch(city_name, "*-*")
replace city_name = subinstr(city_name, "-", "", .)
replace city_name = proper(city_name)

tab city_name if strmatch(city_name, "*/*")
split city_name, p("/")
tab city_name2

replace city_name = city_name1 if city_name2 != ""
save crime_city_2018_2, replace

*merge 2 (names after "/" do not match)
use crime_city_2018_2
merge 1:m city_name state_name using city_to_county2, update

*save set 2 merged
preserve
keep if _merge >=3
duplicates r city_name state_name county_name
drop _merge
save crime_city_2018_set2.dta, replace
restore

*save set 3 for merging
keep if _merge == 1
drop _merge
duplicates r city_name state_name
save crime_city_2018_3, replace


*****THIRD MERGE
*remove extraneous endings for using
use city_to_county

merge 1:1 place countystate using crime_city_2018_set1
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set2
keep if _merge == 1
drop _merge

*remove extra city ending
tab city_name if strmatch(city_name, "*city")
replace city_name = regexr(city_name, "city$", "")

duplicates r city_name state_name countystate

save city_to_county3, replace

*remove extraneous endings for using
use crime_city_2018_3


*remove extra city ending
tab city_name if strmatch(city_name, "*city")
replace city_name = regexr(city_name, "city$", "")

duplicates r city_name state_name

*merge 3
merge 1:m city_name state_name using city_to_county3, update

*save set 3 merged
preserve
keep if _merge >=3
duplicates r city_name state_name county_name
drop _merge
save crime_city_2018_set3.dta, replace
restore

*save set 4 for merging
keep if _merge == 1
drop _merge
duplicates r city_name state_name
save crime_city_2018_4, replace


*****FOURTH MERGE
*remove extraneous endings for using
use city_to_county

merge 1:1 place countystate using crime_city_2018_set1
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set2
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set3
keep if _merge == 1
drop _merge

*remove town and township endings
duplicates r city_name state_name countystate
replace city_name = regexr(city_name, "village$", "")
tab city_name if strmatch(city_name, "*village*")
replace city_name = regexr(city_name, "village$", "")
replace city_name = regexr(city_name, "villagetown$", "")
replace city_name = regexr(city_name, "villageborough$", "")
duplicates tag city_name state_name countystate, gen(dup)

*br if dup > 0

*all in same counties, can be collapsed
bysort city_name state_name countystate: egen pop_total = total(pop10)
replace pop10 = pop_total if dup > 0
drop pop_total dup

*using force to keep origanol names
duplicates drop city_name state_name countystate, force

save city_to_county4, replace

*remove town and township endings in crime file
use crime_city_2018_4

duplicates r city_name state_name countystate
replace city_name = regexr(city_name, "village$", "")
tab city_name if strmatch(city_name, "*village*")
duplicates r city_name state_name countystate

*merge 4
merge 1:m city_name state_name using city_to_county4, update

*save set 4 merged
preserve
keep if _merge >=3
duplicates r city_name state_name county_name
drop _merge
save crime_city_2018_set4.dta, replace
restore

*save set 5 for merging
keep if _merge == 1
drop _merge
duplicates r city_name state_name
save crime_city_2018_5, replace


*****FIFTH MERGE
*remove extraneous endings for using
use city_to_county

merge 1:1 place countystate using crime_city_2018_set1
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set2a
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set3
keep if _merge == 1
drop _merge

merge 1:1 place countystate using crime_city_2018_set4
keep if _merge == 1
drop _merge

*remove town and township endings
duplicates r city_name state_name countystate
replace city_name = regexr(city_name, "town$", "")
tab city_name if strmatch(city_name, "*town*")
replace city_name = regexr(city_name, "townborough$", "")
replace city_name = regexr(city_name, "townvillage$", "")
replace city_name = regexr(city_name, "town$", "")
duplicates r city_name state_name countystate

save city_to_county5, replace

*remove town and township endings in creim file
use crime_city_2018_5

duplicates r city_name state_name countystate
replace city_name = regexr(city_name, "township$", "")
replace city_name = regexr(city_name, "town$", "")
tab city_name if strmatch(city_name, "*town*")
replace city_name = regexr(city_name, "townand$", "")
replace city_name = regexr(city_name, "town$", "")
duplicates tag city_name state_name countystate, gen(dup)

*doing some spot checking, it seems like all of these townships are actually parts of the cities and in the same counties, can collapse
foreach var in pop_city violent_crime_city property_crime_city {
	
	bysort city_name state_name countystate: egen `var'_tot = total(`var')
	replace `var' = `var'_tot if dup > 0
	drop `var'_tot
	
}

bysort city_name state_name countystate: egen annual_reporting_change_max = max(annual_reporting_change)
replace annual_reporting_change = annual_reporting_change_max if dup > 0
drop annual_reporting_change_max

*using force to maintain origanol names
duplicates drop city_name state_name countystate, force

*merge 5
merge 1:m city_name state_name using city_to_county5, update

*save set 5 merged
preserve
keep if _merge >=3
duplicates r city_name state_name county_name
drop _merge
save crime_city_2018_set5.dta, replace
restore

*save set 6 for merging
keep if _merge == 1
drop _merge
duplicates r city_name state_name
save crime_city_2018_6, replace


*****SIXTH MERGE
/*
use crime_city_2018_6

*check for more patterns
tab city_name if strmatch(city_name, "*town*")
tab city_name if strmatch(city_name, "*city*")
tab city_name if strmatch(city_name, "*village*")
tab city_name if strmatch(city_name, "*county*")
tab city_name if strmatch(city_name, "*borough*")


total violent_crime_city
*/



*****APPEND MERGES
use crime_city_2018_set1, clear

append using crime_city_2018_set2
append using crime_city_2018_set3
append using crime_city_2018_set4
append using crime_city_2018_set5

*check for actual duplicates
duplicates r place countystate

*adjust crime rates for cities in multiple counties
duplicates tag city_name state_name, gen(multicity)
tab multicity

gen share_of_pop = pop10/pop_city if multicity > 0
sum share_of_pop
bysort city_name state_name: egen percent_pop = total(share_of_pop)
sum percent_pop
br state_name city_name county_name_full pop_city pop10 share_of_pop percent_pop if percent_pop > 1

*****************stopped here. all below is from old code


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
