
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
*replace city_name = subinstr(city_name, " ", "", .)
*replace city_name = proper(city_name)

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
save crime_city_2018_set0_EB.dta, replace
restore

*save set 1 for merging
drop if county_name!=""

save crime_city_2018_1_EB, replace

use crime_city_2018_1_EB, clear

replace state_name = upper(state_name)

gen idmaster=_n

reclink state_name city_name using city_to_county_geocorr_EB, idmaster(idmaster) idusing(idusing) gen(matchquality) required(state_name)


