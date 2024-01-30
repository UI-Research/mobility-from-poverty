// SEDA Mobility Metrics Update
/*

Updated by: Jay Carter

This file creates city and county level achievement metrics
Data was manually downloaded from SEDA website
Uses SEDA 2022 - Major differences from past SEDA 
	- Administrative Districts 
	- No Grade Breakdown
	- No Gender Breakdown
	- Data provided for 2018-19 and 2021-22
	- Provides test score changes from 2018-19 to 2021-22 with SEs
	
*/

//# Preamble
version 18

clear all
set more off
set maxvar 32767
set matsize 11000
set emptycells drop

cap frame change default
cap frame drop working

//# Macros

// Folders
global gitfolder "C:\Users\jcarter\Documents\git_repos\mobility-from-poverty\"
global education "${gitfolder}08_education\"

global raw_data "${education}\data\raw\"
global intermediate_data "${education}\data\intermediate\"
global final_data "${education}\data\built\"


// Files
global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"
global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

//#TODO county_code in CCD Directory

// Other Variables
global frame_list "ccd seda cities counties"


// Frames
foreach fr of global frame_list {
	cap frame drop `fr'
	cap frame create `fr'
}

// Folder Structure
cap n mkdir "${education}data"


cd "${education}data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"


// Install educationdata command
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

//# City Crosswalk
{
frame change cities

** Import city file **
import delimited ${cityfile}, clear

tostring place, replace
replace place = "0" + place if strlen(place)==4
replace place = "00" + place if strlen(place)==3
assert strlen(place)==5

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

rename place_name city_name
drop population 

gen city_name_edited = city_name
replace city_name_edited = subinstr(city_name_edited, " town", "", .)
replace city_name_edited = subinstr(city_name_edited, " village", "", .)
replace city_name_edited = subinstr(city_name_edited, " municipality", "", .)
replace city_name_edited = subinstr(city_name_edited, " urban county", "", .)
replace city_name_edited = subinstr(city_name_edited, " city", "", .)

drop city_name
rename city_name_edited city_name

*hardcode fixes so names merge
replace city_name="Ventura" if city_name=="San Buenaventura (Ventura)"
replace city_name="Athens" if city_name=="Athens-Clarke County unified government (balance)"
replace city_name="Augusta" if city_name=="Augusta-Richmond County consolidated government (balance)"
replace city_name="Macon" if city_name=="Macon-Bibb County"
replace city_name="Honolulu" if city_name=="Urban Honolulu"
replace city_name="Boise" if city_name=="Boise City"
replace city_name="Indianapolis" if city_name=="Indianapolis city (balance)"
replace city_name="Lexington" if city_name=="Lexington-Fayette"
replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
replace city_name="Lees Summit" if city_name=="Lee's Summit"
replace city_name="Ofallon" if city_name=="O'Fallon"
replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
replace city_name="Ofallon" if city_name=="O'Fallon"
replace city_name="Mcallen" if city_name=="McAllen"
replace city_name="Mckinney" if city_name=="McKinney"
replace city_name="Anchorage" if city_name=="Anchorage municipality"


qui sum year
keep if year == `r(max)'

save "${intermediate_data}cityfile.dta", replace

}

//# Counties
{
	
frame change counties
** Import county file **
import delimited ${countyfile}, clear
drop population state_name county_name

tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

qui sum year
keep if year == `r(max)'

gen county_5digit = state + county
save "${intermediate_data}countyfile.dta", replace

}

//# CCD
{
frame change ccd

educationdata using "district ccd directory", sub(year=2021) col(year leaid city_location county_code county_name fips) csv clear

gen state = substr(leaid, 1, 2)  // create string fips variable

save "${intermediate_data}ccd_dir.dta", replace

}

//# SEDA
{
frame change seda
** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
** exact file: "https://stacks.stanford.edu/file/druid:db586ns4974/seda2022_admindist_poolsub_gys_2.0.dta" for 2021-22 **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:db586ns4974/seda2022_admindist_poolsub_gys_2.0.dta" "${raw_data}seda2022_admindist_poolsub_gys_2.0.dta"

use "${raw_data}seda2022_admindist_poolsub_gys_2.0.dta", clear

keep if subject=="rla"


rename sedaadmin leaid
tostring leaid, replace
replace leaid = "0"+leaid if strlen(leaid)==6

gen state = substr(leaid, 1, 2)

}


//# Merging

frame copy seda working

frame change working

unique leaid

// Merge to CCD
frame ccd: unique leaid

// LEA Variables
frlink m:1 leaid, frame(ccd) gen(link_ccd)
frget city_location county_code, from(link_ccd)

rename city_location city_name
replace city_name = proper(city_name)

// Merge to city crosswalk
frame cities: unique city_name state
frlink m:1 city_name state, frame(cities) gen(link_cities)

gen in_city_xwalk = !missing(link_cities)

// Merge to county crosswalk
gen county_5digit = string(county_code)
replace county_5digit = "0" + county_5digit if strlen(county_5digit) == 4

frlink m:1 county_5digit, frame(counties) gen(link_counties)

gen in_county_xwalk = !missing(link_counties)

destring leaid, replace


//# Metric Calculations

// Data is not provided by grade in the SEDA2022
//		- Cannot calculate a growth measure like the previous versions of the metric

gen achievement_change = gys_chg_eb

gen achievement_change_lb = gys_chg_eb - (gys_chg_eb_se * 1.96)
gen achievement_change_ub = gys_chg_eb + (gys_chg_eb_se * 1.96)


//# Quality Flag

count if missing(cell22)		// No missings
count if missing(cell19)		// No missings
count if missing(avg_asmt19)	// No missings
count if missing(avg_asmt22)	// No missings

gen achievement_change_quality = .

replace achievement_change_quality = 1 if cell22 > 4 & cell19 > 4 & ///
	avg_asmt22 >= 30 & avg_asmt19 >= 30

replace achievement_change_quality = 2 if cell22 == 4 & cell19 == 4 & ///
	avg_asmt22 >= 30 & avg_asmt22 >= 30

replace achievement_change_quality = 3 if missing(achievement_change_quality) ///
	& !missing(achievement_change)


// save intermediate file

frame copy working county_metric
frame copy working city_metric

//# City Level Metric
frame change city_metric

gen weight22 = round(avg_asmt22)
collapse achievement_change achievement_change_lb achievement_change_ub achievement_change_quality [fw=weight22], by(state city_name subgroup)

replace achievement_change_quality = round(achievement_change_quality, 1)

gen missing_outcome = missing(achievement_change)
tab subgroup missing_outcome

drop missing_outcome

// Reshape Wide for City Merge 
//	- Probably could skip this and use a fillforward type command
reshape wide achievement_change achievement_change_lb achievement_change_ub achievement_change_quality, i(state city_name) j(subgroup) string

merge 1:1 city_name state using "${intermediate_data}cityfile.dta"

tab _merge
drop if _merge == 1

reshape long achievement_change achievement_change_lb achievement_change_ub achievement_change_quality, i(state city_name) j(subgroup) string

gsort state place
order state place

// Fix subgroups
//# TODO: Make this a program so there's not code copying
/*
 - The ECD and NEC subgroups are not "income levels" but are categories for Federal accountability purposes. 
 - It's possible removing them would be less confusing in context of the rest of the metrics. 
 - I have left them in for now.
 
 - The commented out subgroup types are not in the SEDA2022 dataset but were in previous versions of the data.
*/

tab subgroup, mi 		// all blk ecd hsp nec wht

gen subgroup_type=""
replace subgroup_type = "all" if subgroup=="_all"
replace subgroup_type = "race-ethnicity" if subgroup=="wht"
replace subgroup_type = "race-ethnicity" if subgroup=="blk"
replace subgroup_type = "race-ethnicity" if subgroup=="hsp"
// replace subgroup_type = "race-ethnicity" if subgroup=="oth"		// Not in SEDA2022
// replace subgroup_type = "gender" if subgroup=="mal"				// Not in SEDA2022
// replace subgroup_type = "gender" if subgroup=="fem"				// Not in SEDA2022
replace subgroup_type = "income" if subgroup=="ecd"				// Remove for clarity??
replace subgroup_type = "income" if subgroup=="nec"				// Remove for clarity?

replace subgroup = "All" if subgroup=="all"
replace subgroup = "White, Non-Hispanic" if subgroup=="wht"
replace subgroup = "Black, Non-Hispanic" if subgroup=="blk"
replace subgroup = "Hispanic" if subgroup=="hsp"
// replace subgroup = "Asian, API, Native American, Other" if subgroup=="oth"	// Not in SEDA2022
// replace subgroup = "Male" if subgroup=="mal"									// Not in SEDA2022
// replace subgroup = "Female" if subgroup=="fem"								// Not in SEDA2022
replace subgroup = "Economically Disadvantaged" if subgroup=="ecd"
replace subgroup = "Not Economically Disadvantaged" if subgroup=="nec"


// Check Missingness
gen missing_outcome = missing(achievement_change)
tab subgroup missing_outcome


//# Export City Data
export delimited using "${final_data}SEDA22_all_subgroups_city.csv", replace 

keep if subgroup_type=="all"
drop subgroup_type subgroup

export delimited using "${final_data}SEDA22_all_city.csv", replace


//# County Level Metric

frame change county_metric

gen weight22 = round(avg_asmt22)

collapse achievement_change achievement_change_lb achievement_change_ub achievement_change_quality [fw=weight22], by(state county_5digit subgroup)

replace achievement_change_quality = round(achievement_change_quality, 1)

gen missing_outcome = missing(achievement_change)
tab subgroup missing_outcome

drop missing_outcome

// Reshape Wide for County Merge 
//	- Probably could skip this and use a fillforward type command
reshape wide achievement_change achievement_change_lb achievement_change_ub achievement_change_quality, i(state county_5digit) j(subgroup) string

merge 1:1 state county_5digit state using "${intermediate_data}countyfile.dta"

tab _merge
drop if _merge == 1

reshape long achievement_change achievement_change_lb achievement_change_ub achievement_change_quality, i(state county_5digit) j(subgroup) string

gsort state county
order state county

// Fix subgroups
//# TODO: Make this a program so there's not code copying
/*
 - The ECD and NEC subgroups are not "income levels" but are categories for Federal accountability purposes. 
 - It's possible removing them would be less confusing in context of the rest of the metrics. 
 - I have left them in for now.
 
 - The commented out subgroup types are not in the SEDA2022 dataset but were in previous versions of the data.
*/

tab subgroup, mi 		// all blk ecd hsp nec wht

gen subgroup_type=""
replace subgroup_type = "all" if subgroup=="_all"
replace subgroup_type = "race-ethnicity" if subgroup=="wht"
replace subgroup_type = "race-ethnicity" if subgroup=="blk"
replace subgroup_type = "race-ethnicity" if subgroup=="hsp"
// replace subgroup_type = "race-ethnicity" if subgroup=="oth"		// Not in SEDA2022
// replace subgroup_type = "gender" if subgroup=="mal"				// Not in SEDA2022
// replace subgroup_type = "gender" if subgroup=="fem"				// Not in SEDA2022
replace subgroup_type = "income" if subgroup=="ecd"				// Remove for clarity??
replace subgroup_type = "income" if subgroup=="nec"				// Remove for clarity?

replace subgroup = "All" if subgroup=="all"
replace subgroup = "White, Non-Hispanic" if subgroup=="wht"
replace subgroup = "Black, Non-Hispanic" if subgroup=="blk"
replace subgroup = "Hispanic" if subgroup=="hsp"
// replace subgroup = "Asian, API, Native American, Other" if subgroup=="oth"	// Not in SEDA2022
// replace subgroup = "Male" if subgroup=="mal"									// Not in SEDA2022
// replace subgroup = "Female" if subgroup=="fem"								// Not in SEDA2022
replace subgroup = "Economically Disadvantaged" if subgroup=="ecd"
replace subgroup = "Not Economically Disadvantaged" if subgroup=="nec"


// Check Missingness
gen missing_outcome = missing(achievement_change)
tab subgroup missing_outcome


//# Export County Data
export delimited using "${final_data}SEDA_all_subgroups_county.csv", replace 

keep if subgroup_type=="all"
drop subgroup_type subgroup

export delimited using "${final_data}SEDA_all_county.csv", replace

