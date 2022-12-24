
* Creating a version of the city file that has unique identifier called "stateplacefp" (concatenation of state FIP and census place FIP)
* By Tina Chelidze on 11.21.22

* Set your directory to the project's GitHub
	global mobility "C:\Users\tchelidze\Documents\GitHub\mobility-from-poverty"


* Import the original population-based city file (and save as temp in order to merge it in later to double check everything)
	import delimited "${mobility}\geographic-crosswalks\data\city_state_2020_population.csv", clear
	tempfile og_cityfile
	save "`og_cityfile'"

* Import one of the Census-based crosswalks (because these all have the Census Place FIPS codes)
* Note that the one I've chosen (below) has a variable called GEOID which is already a concat of state+place FIPS
* but I am recreating one from scratch to have the process written down & also as a double check
	import delimited "${mobility}\geographic-crosswalks\data\2010_ZCTA_2021_Census_Places_Crosswalk.csv", clear
* clean up to prepare for merge
	rename namelsad cityname
	rename name city
	rename stusps state_abbr
	keep statefp placefp geoid city cityname state_abbr state_name
* merge in the original city file so we have all the variables we want/need
	merge m:1 cityname state_abbr using "`og_cityfile'"
	keep if _merge == 3 | state_name == "District of Columbia"
	drop _merge
	drop fips

* prep the variables we need to make our concatenated variable
* add leading zeroes to the FIPS codes (2 for state, 5 for Place)
	gen fips = string(statefp,"%02.0f")
	gen placefips = string( placefp ,"%05.0f")
* Create the unique STATEPLACEFP concatenated FIPS code that will ID each city
	egen stateplacefp = concat(fips placefips)

* clean up (remove all the leftover duplicates - we want our original 486 cities only)
	sort fips placefips stateplacefp
	quietly by fips placefips stateplacefp :  gen dup = cond(_N==1,0,_n)
	drop if dup>1

	drop geoid state_name dup
	sort fips placefips
	order geographicarea cityname city statename state_abbr population2020 statefp placefp fips placefips stateplacefp
	rename fips statefips
	
* add in YEAR variable (to ID the year the Census Places were defined -- 2020)
	gen year = 2020
	order year geographicarea cityname city statename state_abbr population2020 statefp placefp statefips placefips stateplacefp

* Save the updated final city file as both Stata and CSV data files
*	save "${mobility}\geographic-crosswalks\data\census_place_2020population_allFIPS.dta"
	export delimited using "${mobility}\geographic-crosswalks\data\census_place_2020population_allFIPS.csv", replace
