
import delimited "zip_code_database.csv", clear

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
/*
*make all proper case and remove spaces and make other changes for consistency
replace city = subinstr(city, "-", "", .)
replace city = subinstr(city, "'", "", .)
replace city = subinstr(city, "Ft ", "Fort ", .)
replace city = subinstr(city, " ", "", .)
replace city = proper(city)
*/
*create merge variable
replace state_name = trim(state_name)
gen city_name = trim(city)

/*
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
*/

rename city city_from_crosswalk

save city_to_county_EB, replace

replace city_name = lower(city_name)
replace city_name = subinstr(city_name," ","",.)
replace city_name = subinstr(city_name,"-","",.)
replace city_name = subinstr(city_name,"'","",.)

save city_to_county_EB_lower, replace
