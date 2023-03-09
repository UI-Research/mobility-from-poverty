** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** Updated by: Emily Gutierrez **
** 2020/08/04 **
** this file creates METRO LEVEL learning rate estimates for years (fall) 2013 - 2017 and subgroups by economic disadvantage, race, and gender. 
** however, for the purposes of creating the community dashboards we focus on the 2015 race and economic disadvantage subgroups only. **
** 2017-18 is most recently available year from SEDA as of 9/12/22

clear all
set maxvar 10000
set matsize 10000

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global year=2018 // refers to spring of the school year (2017-2018)

global cityfile "${gitfolder}\geographic-crosswalks\data\place-populations.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

***********************************************************
** Import county file **
import delimited  ${cityfile}, clear

tostring stateplacefp, replace
replace stateplacefp = "0" + stateplacefp if strlen(stateplacefp)<7
assert strlen(stateplacefp)==7

tostring statefips, replace
replace statefips = "0" + statefips if strlen(statefips)==1
assert strlen(statefips)==2

rename city city_name
rename statefips state
drop geographicarea cityname population 

gen city_name_edited = city_name
replace city_name_edited = subinstr(city_name_edited, " town", "", .)
replace city_name_edited = subinstr(city_name_edited, " village", "", .)
replace city_name_edited = subinstr(city_name_edited, " municipality", "", .)
replace city_name_edited = subinstr(city_name_edited, " urban county", "", .)

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
***********************************************************


** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
** exact file: "https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_4.1.dta" for 2009-2018 **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:db586ns4974/seda_metro_long_gcs_4.1.dta" "raw/seda_metro_long_gcs_4.1.dta"
use "raw/seda_metro_long_gcs_4.1.dta", clear

keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015,
** in 6th grade in 2014, etc **
gen cohort = year - grade + 8
keep if cohort>=2014 & cohort!=.

gen metro = sedametro

egen totgyb_oth = rowtotal(totgyb_asn totgyb_nam)
gen temp_asn = gcs_mn_asn*totgyb_asn
gen temp_nam = gcs_mn_nam*totgyb_nam
egen gcs_mn_oth = rowtotal(temp_asn temp_nam)
replace gcs_mn_oth = gcs_mn_oth/totgyb_oth

** calculate growth estimates for each subgroup **
** NOTE: This loop takes a long time to run (4-8+ hours or more).
foreach subgroup in all wht blk hsp nec ecd mal fem {
	gen learning_rate_`subgroup'=.
	gen se_`subgroup'=.

	qui levelsof metro, local(metros)
	local year=${year}
	forvalues cohort = 2014/`year' { 
	    ** calculate learning rate as metro-specific grade coefficient for each subgroup and cohort ** 
		reg gcs_mn_`subgroup' c.grade#metro i.metro if cohort==`cohort' [aw=totgyb_`subgroup']
		foreach metro of local metros {
			cap n replace learning_rate_`subgroup' = _b[c.grade#`metro'.metro] if metro==`metro' & cohort==`cohort'
			cap n replace se_`subgroup' = _se[c.grade#`metro'.metro] if metro==`metro' & cohort==`cohort'
		}
	}

	** count number of grades included in each regression **
	bysort cohort metro: egen num_grades_included_`subgroup' = count(gcs_mn_`subgroup')
	
	** determine smallest class size used in each regression **
	bysort cohort metro: egen min_sample_size_`subgroup' = min(totgyb_`subgroup')

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
save "intermediate/seda_race_postreg_metro.dta", replace
use "intermediate/seda_race_postreg_metro.dta", clear
	
drop year
rename cohort year
replace year = year - 1 // changed so that the year reflects the fall of the academic year 

keep sedametro year learning_rate_* sedametroname

duplicates drop

rename sedametro metro
gsort -year metro

drop if year<2013 | year>$year - 1

*******************************************
*fix names 
gen state = substr(sedametroname, -2, 2)
statastates, abbreviation(state)
drop _merge state_name state
tostring(state_fips), replace
replace state_fips = "0"+state_fips if strlen(state_fips)==1
rename state_fips state

gen city_name = substr(sedametroname, 1, strpos(sedametroname,",")-1)

merge 1:1  city_name state year using "intermediate/cityfile.dta"
tab year _merge
	keep if year==2016 | year==2017 // city crosswalk is 2016-2020, and this data spans 2013-2017 - keeping 16 & 17
	drop if _merge==1
*******************************************

gen place = substr(stateplacefp, -5, 5)
drop city_name stateplacefp statename state_abbr _merge sedametro metro

** make the data long **
reshape long learning_rate learning_rate_lb learning_rate_ub learning_rate_quality, i(year place state) j(subgroup) string

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

gsort -year state place  subgroup_type subgroup


** export data **
export delimited using "built/SEDA_all_subgroups_metro.csv", replace // 2013,14,15 don't exactly match but its updated underlying data

keep if subgroup_type=="all"
drop subgroup_type subgroup

export delimited using "built/SEDA_all_metro.csv", replace


