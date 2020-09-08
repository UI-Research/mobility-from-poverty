
import excel crime_city_2018.xls, cellrange(A4) firstrow case(lower) clear

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
/*
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
*/

*create merge variable
gen state_name = trim(state)
gen city_name = trim(city)
/*
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

*/

** minor edits **
replace city_name = subinstr(city_name,".","",.)
replace city_name = subinstr(city_name,",","",.)
replace city_name = subinstr(city_name,"'","",.)

save crime_city_2018_EB, replace

** First cut: remove counties explicitly labeled and some manual counties **
use crime_city_2018_EB, clear
compress
total violent_crime_city

split city_name, gen(city_part)

gen county_name = city_part5 + " " + city_part6 if city_part6=="County"
replace county_name = city_part4 + " " + city_part5 if city_part6=="" & city_part5=="County"
replace county_name = city_part3 + " " + city_part4 if city_part5=="" & city_part4=="County"
replace county_name = city_part2 + " " + city_part3 if city_part4=="" & city_part3=="County"

** manual counties **
replace county_name = "Berrien County" if inlist(city_name, "St Joseph", "St Joseph Township") & state_name=="MICHIGAN"
replace county_name = "Luzerne County" if inlist(city_name, "Wilkes-Barre", "Wilkes-Barre Township") & state_name=="PENNSYLVANIA"
replace county_name = "Clinton County" if inlist(city_name, "DeWitt", "DeWitt Township") & state_name=="MICHIGAN"
replace county_name = "Mahoning County" if inlist(city_name, "Poland Village", "Poland Township") & state_name=="OHIO"
replace county_name = "Greene County" if regexm(city_name, "Greene County")==1
replace county_name = "Camden County" if regexm(city_name, "Camden County")==1
replace county_name = "York County" if regexm(city_name, "Northeast")==1 & state_name=="PENNSYLVANIA"
replace county_name = city_name if regexm(city_name, "Borough")==1 & state_name=="ALASKA" 

** these are picking up biggest crime rate cities (violent crime >=100) that aren't picked up elsewhere
replace county_name = "Berrien County" if regexm(city_name, "Benton Township")==1 & state_name=="MICHIGAN" // this seemed like the best match given the population
replace county_name = "DeKalb County" if regexm(city_name, "Brookhaven")==1 & state_name=="GEORGIA" 
replace county_name = "St. Louis County" if regexm(city_name, "Vinita Park")==1 & state_name=="MISSOURI" // note populations seem inconsistent
replace county_name = "St. Louis County" if regexm(city_name, "Bellefontaine Neighbors")==1 & state_name=="MISSOURI"
replace county_name = "York County" if regexm(city_name, "York Area Regional")==1 & state_name=="PENNSYLVANIA" 
replace county_name = "Barnstable County" if regexm(city_name, "Yarmouth")==1 & state_name=="MASSACHUSETTS" 
replace county_name = "Jefferson County" if regexm(city_name, "Tarrant")==1 & state_name=="ALABAMA" 

drop city_part*

preserve
keep if county_name!=""
save city_set_1.dta, replace
restore

drop if county_name!=""

save crime_city_2018_EB_1, replace

** Second cut: perfect matches (aside from . , ') **
use crime_city_2018_EB_1, clear
merge 1:m city_name state_name using city_to_county_EB, update

preserve
keep if _merge==3 | _merge==4 | _merge==5
save city_set_2.dta, replace
restore

keep if _merge==1
drop _merge

save crime_city_2018_EB_2, replace

** Third cut: cities separated by hyphen or / ; fix "saint" **
use crime_city_2018_EB_2, clear

gen old_city_name=city_name
split city_name, gen(city_part) parse("-" "/")
replace city_name = city_part1 if ~inlist(city_name, "Bel-Nor", "Bel-Ridge","Wilkes-Barre", "Wilkes-Barre Township")

replace city_name = subinstr(city_name, "St ", "Saint ",1) if substr(city_name,1,3)=="St "

merge 1:m city_name state_name using city_to_county_EB, update

preserve
keep if _merge==3 | _merge==4 | _merge==5
save city_set_3.dta, replace
restore

keep if _merge==1
drop _merge
replace city_name = old_city_name
drop old_city_name city_part*

save crime_city_2018_EB_3, replace

** Fourth cut: remove hyphens and other punctuation **
use crime_city_2018_EB_3, clear

replace city_name = lower(city_name)
replace city_name = subinstr(city_name,"-","",.)
replace city_name = subinstr(city_name," ","",.)

merge 1:m city_name state_name using city_to_county_EB_lower, update

preserve
keep if _merge==3 | _merge==4 | _merge==5
save city_set_4.dta, replace
restore

keep if _merge==1
drop _merge

save crime_city_2018_EB_4, replace

** Fifth cut: remove extraneous endings **
use crime_city_2018_EB_4, clear

replace city_name = subinstr(city_name,"townandvillage","",.)
replace city_name = subinstr(city_name,"township","",.)
replace city_name = subinstr(city_name,"village","",.)
replace city_name = "redingtonbeach" if city_name=="redingtonbeaches"

merge 1:m city_name state_name using city_to_county_EB_lower, update

preserve
keep if _merge==3 | _merge==4 | _merge==5
save city_set_5.dta, replace
restore

keep if _merge==1
drop _merge

save crime_city_2018_EB_5, replace

** Fifth cut: remove extraneous endings **
use crime_city_2018_EB_5, clear

replace city_name = subinstr(city_name,"city","",1)
replace city_name = subinstr(city_name,"town","",1)
replace city_name = subinstr(city_name,"of","",.) if substr(city_name,1,2)=="of"
replace city_name = subinstr(city_name,"borough","",.) if regexm(city_name,"baldwin")!=1
replace city_name = subinstr(city_name,"regional","",.)
replace city_name = "nashville" if regexm(city_name,"nashville")==1
replace city_name = "lasvegas" if regexm(city_name,"lasvegas")==1
replace city_name = "eastsaintlouis" if city_name=="eaststlouis"

merge 1:m city_name state_name using city_to_county_EB_lower, update

total violent_crime_city if _merge==1



