** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** Updated 2020/08/04 by E Gutierrez **
	** this file creates METRO LEVEL learning rate estimates for years (fall) 2013 - 2017 and subgroups by economic disadvantage, race, and gender. 
	** however, for the purposes of creating the community dashboards we focus on the 2015 race and economic disadvantage subgroups only. **
	** 2017-18 is most recently available year from SEDA as of 9/12/22
** Updated 12/19/2024 by E Gutierrez **
	** SEDA Version 5.0 provides years 2009-2019 (2008-09 through 2018-19)

	
**Housekeeping: install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*Set up globals and directories
clear all
set maxvar 10000
set matsize 10000

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
global year=2019 // refers to spring of the school year (2018-19)
global latestyear=2018 // needs to be fall of the current SEDA year (2018-19)

global countyfile "${gitfolder}\geographic-crosswalks\data\county-populations.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

************************************
*Import, edit, and save needed data*
************************************
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

** create additional older years **
preserve
replace year = year - 4
drop if year>2013
tempfile additionalyears
save `additionalyears'
restore

append using `additionalyears' 

save "intermediate/countyfile.dta", replace


*****************************
*****Download SEDA Data******
*****************************
	** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
	** exact file: "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_geodist_long_gcs_5.0_updated_20240319.dta" for 2009-2019 **
	** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:cs829jn7849/seda_county_long_gcs_5.0.dta" "raw/seda_county_long_gcs_5.0.dta"
	use "raw/seda_county_long_gcs_5.0.dta", clear

keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015, in 6th grade in 2014, etc
	gen cohort = year - grade + 8
	keep if cohort>=2014 & cohort!=.

	gen county = sedacounty

*combine asian and native american students to "other"
	egen tot_asmt_oth = rowtotal(tot_asmt_asn tot_asmt_nam)
	gen temp_asn = gcs_mn_asn*tot_asmt_asn
	gen temp_nam = gcs_mn_nam*tot_asmt_nam
	egen gcs_mn_oth = rowtotal(temp_asn temp_nam)
	replace gcs_mn_oth = gcs_mn_oth/tot_asmt_oth

*******************************************************
*Clean and Calculate Growth Estimates for each subgroup
*******************************************************
	** NOTE: This loop takes a about 12:46 minutes to run.
foreach subgroup in all wht blk hsp nec ecd mal fem {
	gen learning_rate_`subgroup'=.
	gen se_`subgroup'=.

	qui levelsof county, local(counties)
	local year=${year}
	forvalues cohort = 2014/`year' { 
	    ** calculate learning rate as county-specific grade coefficient for each subgroup and cohort ** 
		reg gcs_mn_`subgroup' c.grade#county i.county if cohort==`cohort' [aw=tot_asmt_`subgroup']
		foreach county of local counties {
			cap n replace learning_rate_`subgroup' = _b[c.grade#`county'.county] if county==`county' & cohort==`cohort'
			cap n replace se_`subgroup' = _se[c.grade#`county'.county] if county==`county' & cohort==`cohort'
		}
	}

	** count number of grades included in each regression **
	bysort cohort county: egen num_grades_included_`subgroup' = count(gcs_mn_`subgroup')
	
	** determine smallest class size used in each regression **
	bysort cohort county: egen min_sample_size_`subgroup' = min(tot_asmt_`subgroup')

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
save "intermediate/seda_race_postreg", replace
use "intermediate/seda_race_postreg", clear

*drop year and rename cohort to year (reminder cohort is the ELA rate for 3-8th grade for 8th graders in that year)	
	drop year
	rename cohort year
	replace year = year - 1 // changed so that the year reflects the fall of the academic year - did this previously with year variable, not cohort

** generate fips county and state codes to merge onto crosswalk **
	tostring sedacounty, replace
	replace sedacounty = "0" + sedacounty if strlen(sedacounty)==4
	replace sedacounty = substr(sedacounty,3,5)
	assert strlen(sedacounty)==3
	tostring fips, replace
	replace fips = "0" + fips if strlen(fips)==1
	assert strlen(fips)==2
	keep fips sedacounty year learning_rate_* 

	duplicates drop
	rename fips state
	rename sedacounty county
	gsort -year state county

** merge on crosswalk **
	merge 1:1 year state county using "intermediate/countyfile.dta"
	tab year _merge
	drop if _merge==1 // drop anything that doesn't match city crosswalk (these were used to create the city data but not needed in the final year
	drop _merge
	
** 2014 because that is the earliest year we have for county crosswalk
	drop if year<2014 | year>$year - 1

** make the data long **
reshape long learning_rate learning_rate_lb learning_rate_ub learning_rate_quality, i(year state county) j(subgroup) string

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

	order year state county subgroup_type subgroup learning_rate learning_rate_lb learning_rate_ub
	gsort -year state county subgroup_type subgroup

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
export delimited using "built/SEDA_all_subgroups_county_2014-2018.csv", replace 

keep if subgroup_type=="all"
drop subgroup_type subgroup

** export "all data data **
export delimited using "built/SEDA_all_county_2014-2018.csv", replace
