** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** Updated 2020/08/04 by E Gutierrez **
	** this file creates METRO LEVEL learning rate estimates for years (fall) 2013 - 2017 and subgroups by economic disadvantage, race, and gender. 
	** however, for the purposes of creating the community dashboards we focus on the 2015 race and economic disadvantage subgroups only. **
	** 2017-18 is most recently available year from SEDA as of 9/12/22
** Updated 12/19/2024 by E Gutierrez **
	** SEDA Version 5.0 provides years 2009-2019
	

clear all
set maxvar 32767
set matsize 11000
set emptycells drop

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global year=2019 // refers to spring of the school year (2017-2018)

global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Match school district to city crosswalk to make the dataset smaller so it can run
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

save "intermediate/cityfile.dta", replace

*******************************************
** Get CCD district data - city_location** 
	*will match leaid to SEDA data, then match city_location to city crosswalk
local latestyear 2017
	educationdata using "district ccd directory ", sub(year=2008:`latestyear') col(year leaid city_location fips) csv clear

	gen state = substr(leaid, 1, 2)  // create string fips variable
	
	save "intermediate/ccd_lea_city.dta", replace
**********************************************

** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
** exact file: "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_geodist_long_gcs_5.0_updated_20240319.dta" for 2009-2019 **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_geodist_long_gcs_5.0_updated_20240319.dta" "raw/seda_geodist_long_gcs_5.0.dta"
use "raw/seda_geodist_long_gcs_5.0.dta", clear

keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015,
** in 6th grade in 2014, etc **
gen cohort = year - grade + 8
keep if cohort>=2014 & cohort!=.
replace year= year-1 // to match to other dataset that use fall of school year

egen totgyb_oth = rowtotal(totgyb_asn totgyb_nam)
gen temp_asn = gcs_mn_asn*totgyb_asn
gen temp_nam = gcs_mn_nam*totgyb_nam
egen gcs_mn_oth = rowtotal(temp_asn temp_nam)
replace gcs_mn_oth = gcs_mn_oth/totgyb_oth

*clean to merge
rename sedalea leaid
tostring(leaid), replace
replace leaid = "0"+leaid if strlen(leaid)==6

gen state = substr(leaid, 1, 2)

*merge to common core data to get city location
merge m:1 year leaid state using "intermediate/ccd_lea_city.dta"
tab year _merge
drop if _merge==2 // drop common core observationst that don't match SEDA
drop _merge

rename city_location city_name
replace city_name = proper(city_name)

*merge to city crosswalk data
merge m:1 city_name state year using "intermediate/cityfile.dta"
tab year _merge

*hard code/look for accidental missmataches
sort state city_name year
*brow state city_name _merge year if _merge!=3 & (year==2016 | year==2017) // _merge=2 means its in city but not seda
*searched the _merge column for 2s and look above and below to see if cities are spelled differently

*generate an indicator that if a district matched the city crosswalk in 2016/17 or if its a city in our city crosswalk, we keep the city/district for all years
gen final_files = 1 if _merge!=1
bysort leaid: egen final=max(final_files)

sort leaid city_name state year _merge final_files final
*brow leaid city_name state year _merge final_files final

keep if final==1
*SEDA data doesn't extend past 2017
*drop if year>2017
drop final* 

destring leaid, replace

******************************************************************

** calculate growth estimates for each subgroup **
** NOTE: This loop takes a long time to run (4-8+ hours or more).
foreach subgroup in all wht blk hsp nec ecd mal fem {
	gen learning_rate_`subgroup'=.
	gen se_`subgroup'=.

	qui levelsof leaid, local(leaids)
	local year=${year}
	forvalues cohort = 2014/`year' { 
	    ** calculate learning rate as leaid-specific grade coefficient for each subgroup and cohort ** 
		reg gcs_mn_`subgroup' c.grade#leaid i.leaid if cohort==`cohort' [aw=totgyb_`subgroup']
		foreach leaid of local leaids {
			cap n replace learning_rate_`subgroup' = _b[c.grade#`leaid'.leaid] if leaid==`leaid' & cohort==`cohort'
			cap n replace se_`subgroup' = _se[c.grade#`leaid'.leaid] if leaid==`leaid' & cohort==`cohort'
		}
	}

	** count number of grades included in each regression **
	bysort cohort leaid: egen num_grades_included_`subgroup' = count(gcs_mn_`subgroup')
	
	** determine smallest class size used in each regression **
	bysort cohort leaid: egen min_sample_size_`subgroup' = min(totgyb_`subgroup')

	** calculate upper and lower 95% confidence intervals **
	gen learning_rate_lb_`subgroup' = learning_rate_`subgroup' - 1.96 * se_`subgroup'
	gen learning_rate_ub_`subgroup' = learning_rate_`subgroup' + 1.96 * se_`subgroup'
	
	** remove false 0s **
	gen flag = 1 if learning_rate_`subgroup'==0 & learning_rate_lb_`subgroup'==0 & learning_rate_ub_`subgroup'==0
	replace learning_rate_`subgroup' = . if flag==1
	replace learning_rate_lb_`subgroup' = . if flag==1
	replace learning_rate_ub_`subgroup' = . if flag==1
	drop flag
	
	replace num_grades_included_`subgroup' = . if learning_rate_`subgroup' == .

	** calculate learning rate quality, based on number of grades included and number of students in each grade **
	gen learning_rate_quality_`subgroup'=1 if (num_grades_included_`subgroup'==6 | num_grades_included_`subgroup'==5) & ///
	min_sample_size_`subgroup'>=30 & min_sample_size_`subgroup'!=.
	replace learning_rate_quality_`subgroup'=2 if num_grades_included_`subgroup'==4 & min_sample_size_`subgroup'>=30 & ///
	min_sample_size_`subgroup'!=.
	replace learning_rate_quality_`subgroup'=3 if learning_rate_`subgroup'!=. & learning_rate_quality_`subgroup'==.

	drop min_sample_size_`subgroup' num_grades_included_`subgroup'
	
}
*EG: start here once have crosswalk
save "intermediate/seda_race_postreg_sedalea.dta", replace
use "intermediate/seda_race_postreg_sedalea.dta", clear

////////////////////////////////
*collapse district data to city level by weighting by each subgroup total individualy
///////////////////////////////
	
drop year
rename cohort year
replace year = year - 1 // changed so that the year reflects the fall of the academic year  - did this previously with year variable, not cohort

keep year fips city_name state place leaid learning_rate_* tot*


*collapse to city level and weight by each subgroups total subgroup count
foreach var in _all _blk _hsp _wht _mal _fem _ecd _nec {
preserve
collapse learning_rate`var' learning_rate_lb`var' learning_rate_ub`var' learning_rate_quality`var' [fw=totgyb`var'], by(state city_name year)
*round to flag to nearest integer
replace learning_rate_quality`var'=round(learning_rate_quality`var',1)
save "intermediate/collapse_city`var'_weighted.dta", replace
restore
}

*merge subgroup data together
use "intermediate/collapse_city_all_weighted.dta", clear
foreach var in _blk _hsp _wht _mal _fem _ecd _nec {
merge 1:1 state city_name year using "intermediate/collapse_city`var'_weighted.dta"
drop _merge
}

*merge one more time to city crosswalk to get the stplacefps
merge 1:1 city_name state year using "intermediate/cityfile.dta"
tab year _merge
drop if _merge==1 // drop anything that doesn't match city crosswalk

gsort -year state place
order year state place

*2016 because that is the earliest year we have for the city crosswalk
drop if year<2016 | year>$year - 1
drop state_name  _merge city_name

** make the data long **
reshape long learning_rate learning_rate_lb learning_rate_ub learning_rate_quality, i(year state place ) j(subgroup) string

** label subgroups **
gen subgroup_type=""
replace subgroup_type = "all" if subgroup=="_all"
replace subgroup_type = "race-ethnicity" if subgroup=="_wht"
replace subgroup_type = "race-ethnicity" if subgroup=="_blk"
replace subgroup_type = "race-ethnicity" if subgroup=="_hsp"
replace subgroup_type = "race-ethnicity" if subgroup=="_oth"
replace subgroup_type = "gender" if subgroup=="_mal"
replace subgroup_type = "gender" if subgroup=="_fem"
replace subgroup_type = "income" if subgroup=="_ecd"
replace subgroup_type = "income" if subgroup=="_nec"

replace subgroup = "All" if subgroup=="_all"
replace subgroup = "White, Non-Hispanic" if subgroup=="_wht"
replace subgroup = "Black, Non-Hispanic" if subgroup=="_blk"
replace subgroup = "Hispanic" if subgroup=="_hsp"
replace subgroup = "Asian, API, Native American, Other" if subgroup=="_oth"
replace subgroup = "Male" if subgroup=="_mal"
replace subgroup = "Female" if subgroup=="_fem"
replace subgroup = "Economically Disadvantaged" if subgroup=="_ecd"
replace subgroup = "Not Economically Disadvantaged" if subgroup=="_nec"

*missingness
tab year if subgroup=="All" & learning_rate==.
tab year if subgroup=="Black, Non-Hispanic" & learning_rate==.
tab year if subgroup=="Economically Disadvantaged" & learning_rate==.
tab year if subgroup=="Female" & learning_rate==.
tab year if subgroup=="Hispanic" & learning_rate==.
tab year if subgroup=="Male" & learning_rate==.
tab year if subgroup=="Not Economically Disadvantaged" & learning_rate==.
tab year if subgroup=="White, Non-Hispanic" & learning_rate==.

order year state place subgroup_type subgroup learning_rate learning_rate_lb learning_rate_ub
gsort -year state place subgroup_type subgroup

** export data **
export delimited using "built/SEDA_all_subgroups_city.csv", replace 

keep if subgroup_type=="all"
drop subgroup_type subgroup

export delimited using "built/SEDA_all_city.csv", replace


