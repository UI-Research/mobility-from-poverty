** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** Updated 2020/08/04 by E Gutierrez **
	** this file creates city/places level learning rate estimates for years (fall) 2013 - 2017 and subgroups by economic disadvantage, race, and gender. 
	** however, for the purposes of creating the community dashboards we focus on the 2015 race and economic disadvantage subgroups only. **
	** 2017-18 is most recently available year from SEDA as of 9/12/22
** Updated 12/19/2024 by E Gutierrez **
	** SEDA Version 5.0 provides years 2009-2019 (2008-09 through 2018-19)
	
**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")
	
*Set up globals and directories
clear all
set maxvar 32767
set matsize 11000, perm
set emptycells drop

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global year=2019 // refers to spring of the school year (2018-19)
global latestyear=2018 // needs to be fall of the current SEDA year (2018-19)

global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

************************************
*Import, edit, and save needed data*
************************************
** Import city crosswalk file to edit names of city crosswalk to match city location strings in CCD school district data
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
replace city_name="Boise" if city_name=="Boise City"
replace city_name="Lexington" if city_name=="Lexington-Fayette"
replace city_name="Louisville" if city_name=="Louisville/Jefferson County metro government (balance)"
replace city_name="Lees Summit" if city_name=="Lee's Summit"
replace city_name="Nashville" if city_name=="Nashville-Davidson metropolitan government (balance)"
replace city_name="Ofallon" if city_name=="O'Fallon"
replace city_name="Mcallen" if city_name=="McAllen"
replace city_name="Mckinney" if city_name=="McKinney"

save "intermediate/cityfile.dta", replace

*****************************
*****CCD District Data*******
*****************************
** Download CCD district data from Urban's Education Data Portal - city location**
	*will match leaid to SEDA data, then match city_location to city crosswalk
	educationdata using "district ccd directory ", sub(year=2008:$latestyear) col(year leaid city_location fips) csv clear // global won't work here for some reason, hardcode 2018

	gen state = substr(leaid, 1, 2)  // create string fips variable
	
	save "intermediate/ccd_lea_city_2008-$latestyear.dta", replace

*****************************
*****Download SEDA Data******
*****************************
	** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
	** exact file: "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_geodist_long_gcs_5.0_updated_20240319.dta" for 2009-2019 **
	** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_geodist_long_gcs_5.0_updated_20240319.dta" "raw/seda_geodist_long_gcs_5.0.dta"
	use "raw/seda_geodist_long_gcs_5.0.dta", clear

	keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015, in 6th grade in 2014, etc
	gen cohort = year - grade + 8
	keep if cohort>=2014 & cohort!=.
	replace year= year-1 // to match to other dataset that use fall of school year

*combine asian and native american students to "other"
	egen tot_asmt_oth = rowtotal(tot_asmt_asn tot_asmt_nam)
	gen temp_asn = gcs_mn_asn*tot_asmt_asn
	gen temp_nam = gcs_mn_nam*tot_asmt_nam
	egen gcs_mn_oth = rowtotal(temp_asn temp_nam)
	replace gcs_mn_oth = gcs_mn_oth/tot_asmt_oth

*clean to merge
	rename sedalea leaid
	tostring(leaid), replace
	replace leaid = "0"+leaid if strlen(leaid)==6
	gen state = substr(leaid, 1, 2)

*merge to common core data to get city location
	merge m:1 leaid state year using "intermediate/ccd_lea_city_2008-$latestyear.dta"
	tab year _merge
	
	*figure out which of the SEDA observations do exist in other years & fill in
	sort state leaid year
	brow state leaid year _merge sedaleaname city_location if _merge!=3
	*search for master only (1) - some leaids that don't match are from different years.
	gen match=1 if _merge==3
	bysort leaid: egen ever_match=max(match)
	keep if ever_match==1
	drop if _merge==2
	gsort  state leaid -city_location
	bysort leaid: replace city_location=city_location[_n-1] if missing(city_location)
	drop _merge *match
	
	rename city_location city_name
	replace city_name = proper(city_name)

*merge to city crosswalk data
	merge m:1 city_name state year using "intermediate/cityfile.dta"
	tab year _merge // crosswalk only goes back to 2015
	keep if cohort >=2014  // earliest cohort starts with 2014

	
*hard code/look for accidental missmataches
	sort state city_name year
	*brow state city_name _merge year if _merge!=3  // _merge=2 means its in city but not seda
	*searched the _merge column for 2s and look above and below to see if cities are spelled differently 

	gen final_files = 1 if _merge!=1
	bysort leaid: egen final=max(final_files)
	keep if final==1
	drop if year>2018

	drop _merge final*
	destring leaid, replace

*******************************************************
*Clean and Calculate Growth Estimates for each subgroup
*******************************************************
	** NOTE: This loop takes a about 25 minutes to run.
foreach subgroup in all wht blk hsp nec ecd mal fem {
	gen learning_rate_`subgroup'=.
	gen se_`subgroup'=.

	qui levelsof leaid, local(leaids)
	local year=${year}
	forvalues cohort = 2014/`year' { 
	    ** calculate learning rate as leaid-specific grade coefficient for each subgroup and cohort ** 
		reg gcs_mn_`subgroup' c.grade#leaid i.leaid if cohort==`cohort' [aw=tot_asmt_`subgroup']
		foreach leaid of local leaids {
			cap n replace learning_rate_`subgroup' = _b[c.grade#`leaid'.leaid] if leaid==`leaid' & cohort==`cohort'
			cap n replace se_`subgroup' = _se[c.grade#`leaid'.leaid] if leaid==`leaid' & cohort==`cohort'
		}
	}

	** count number of grades included in each regression **
	bysort cohort leaid: egen num_grades_included_`subgroup' = count(gcs_mn_`subgroup')
	
	** determine smallest class size used in each regression **
	bysort cohort leaid: egen min_sample_size_`subgroup' = min(tot_asmt_`subgroup')

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
*drop year and rename cohort to year (reminder cohort is the ELA rate for 3-8th grade for 8th graders in that year)	
	drop year
	rename cohort year
	replace year = year - 1 // changed so that the year reflects the fall of the academic year  - did this previously with year variable, not cohort
	keep year fips city_name state place leaid learning_rate_* tot*

*collapse to city level and weight by each subgroups total subgroup count
	foreach var in _all _blk _hsp _wht _mal _fem _ecd _nec {
	preserve
	collapse learning_rate`var' learning_rate_lb`var' learning_rate_ub`var' learning_rate_quality`var' [fw=tot_asmt`var'], by(state city_name year)
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
	drop if _merge==1 // drop anything that doesn't match city crosswalk (these were used to create the city data but not needed in the final year

*2014 because that is the earliest year we have for the city crosswalk
	drop if year<2014 | year>$year -1
	drop state_name  _merge city_name
	gsort -year state place
	order year state place

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

****************
*Quality Checks
****************
sum learning_rate, d, if learning_rate_quality==1
sum learning_rate, d, if learning_rate_quality==2
sum learning_rate, d, if learning_rate_quality==3
sum learning_rate, d, if learning_rate_quality==.

bysort year: sum
bysort state: sum

*missingness
bysort year: count // 3,880:2014-2017 3,888:2018
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

*data quality check - is learning rate ever less than lower bound or higher than upperbound
	gen check1 = 1 if learning_rate<learning_rate_lb
	gen check2 = 1 if learning_rate>learning_rate_ub
	tab check1, m
	tab check2, m 
	drop check*

*are quality flags missing if metric is missing
	tab learning_rate_quality if learning_rate==.
	
**************
*Visual Checks
**************
	twoway histogram learning_rate if subgroup=="All", frequency by(year)
	twoway histogram learning_rate if subgroup=="All" & learning_rate_quality==1, frequency by(year)
	twoway histogram learning_rate if subgroup=="All" & learning_rate_quality==2, frequency by(year)
	twoway histogram learning_rate if subgroup=="All" & learning_rate_quality==3, frequency by(year)

	twoway histogram learning_rate if subgroup=="Black, Non-Hispanic", frequency by(year)
	twoway histogram learning_rate if subgroup=="Black, Non-Hispanic" & learning_rate_quality==1, frequency by(year)
	twoway histogram learning_rate if subgroup=="Black, Non-Hispanic" & learning_rate_quality==2, frequency by(year)
	twoway histogram learning_rate if subgroup=="Black, Non-Hispanic" & learning_rate_quality==3, frequency by(year)

** export subgroup data **
export delimited using "built/SEDA_all_subgroups_city_2014-2018.csv", replace 

keep if subgroup_type=="all"
drop subgroup_type subgroup

** export "all data data **
export delimited using "built/SEDA_all_city_2014-2018.csv", replace
