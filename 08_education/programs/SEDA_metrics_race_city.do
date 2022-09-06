** ELA LEARNING GROWTH: average annual learning growth between 3rd and 8th grade **
** E Blom **
** 2020/08/04 **
** Instructions: lines 11-13 need to be edited for the latest year of data, and new data downloaded manually to the data/raw folder (currently saved on Box in the education folder) **
** this file creates learning rate estimates for years 2013, 2014, 2015 and subgroups by economic disadvantage, race, and gender. however, for the purposes of creating the community dashboards we focus on the 2015 race and economic disadvantage subgroups only. **
*2018 is most recently available year from SEDA as of 8/11/2022

clear all
set maxvar 10000
set matsize 10000

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
*global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Education"
global year=2018

global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"

cap n mkdir "${gitfolder}\08_education\data"
cd "${gitfolder}\08_education\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

*EG ADD 2012 TO THIS
*bring in gleaid city_location crosswalk - uses fall so 2017 instead of 2018
clear
educationdata using "school nhgis census-2010", sub(year=2012:2017) csv
save "intermediate/gleaid_13-17.dta", replace

*THURSDAY
use "intermediate/gleaid_13-17.dta", clear
*are cities consistent within gleaids?
gen num_diff_cities = 0
tab year if gleaid=="" // individual schools missing gleaids
drop if gleaid==""
tab year if city_location==""
drop if city_location==""
sort year gleaid city_location
bysort year gleaid: replace num_diff_cities=1 if city_location!=city_location[_n+1]
*brow year gleaid city_location num_diff_cities

preserve
collapse (sum) num_diff_cities, by(year gleaid fips)
replace num_diff_cities=num_diff_cities-1 if num_diff_cities!=0 // to account for the last observation
replace num_diff_cities =4 if num_diff_cities>=4 & num_diff_cities<.
tab num

/*    (sum) |
num_diff_ci |
       ties |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     45,206       68.01       68.01 68% have same city within gleaid
          1 |     11,271       16.96       84.96 17% have more than 1
          2 |      4,618        6.95       91.91  7% have more than 2
          3 |      2,111        3.18       95.08  3% have more than 3
          4 |      3,268        4.92      100.00  5% have more than 4 or more
------------+-----------------------------------
      Total |     66,474      100.00
*/

tab num year, col
restore

*keep year gleaid city_location //add the city most used city name if we can use gleaids
*save "intermediate/gleaid_13-17_edited.dta", replace

*keep the name that appears most often
keep year gleaid city_location state_fips_geo 
bysort year gleaid city_location: gen num_city_obs=_N
bysort year gleaid: egen num_city_obs_max = max(num_city_obs)
keep if num_city_obs==num_city_obs_max

collapse  num_city_obs num_city_obs_max, by(year gleaid city_location state_fips_geo )

*merge later

/*
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
tempfile additionalyears
save `additionalyears'
restore

append using `additionalyears'

save "intermediate/countyfile.dta", replace
*/
** NOTE: If the following doesn't work, download data in manually from SEDA website: https://edopportunity.org/get-the-data/seda-archive-downloads/ **
** exact file: "https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_4.1.dta" for 2009-2018 **
** SEDA data standardize EDFacts assessments data across states and years using NAEP data **
cap n copy "https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_4.1.dta" "raw/seda_county_long_gcs_4.1.dta"
use "raw/seda_county_long_gcs_4.1.dta", clear

keep if subject=="rla"

** define cohort as the year a cohort reaches 8th grade. Eg, the 2016 cohort is the cohort that is in 8th grade in 2016, in 7th grade in 2015,
** in 6th grade in 2014, etc **
gen cohort = year - grade + 8
keep if cohort>=2014 & cohort!=.

gen county = sedacounty

** create "other" group as sum of Asian students and Native Americans **
count if gcs_mn_asn==. & totgyb_asn!=.
assert `r(N)'==0

count if gcs_mn_nam==. & totgyb_nam!=.
assert `r(N)'==0

egen totgyb_oth = rowtotal(totgyb_asn totgyb_nam)
gen temp_asn = gcs_mn_asn*totgyb_asn
gen temp_nam = gcs_mn_nam*totgyb_nam
egen gcs_mn_oth = rowtotal(temp_asn temp_nam)
replace gcs_mn_oth = gcs_mn_oth/totgyb_oth

******
*do the city level weighting magic 





** calculate growth estimates for each subgroup **
** NOTE: This loop takes a long time to run (4-8 hours or more).
foreach subgroup in all wht blk hsp nec ecd mal fem {
	gen learning_rate_`subgroup'=.
	gen se_`subgroup'=.

	qui levelsof county, local(counties)
	local year=${year}
	forvalues cohort = 2014/`year' { 
	    ** calculate learning rate as county-specific grade coefficient for each subgroup and cohort ** 
		reg gcs_mn_`subgroup' c.grade#county i.county if cohort==`cohort' [aw=totgyb_`subgroup']
		foreach county of local counties {
			cap n replace learning_rate_`subgroup' = _b[c.grade#`county'.county] if county==`county' & cohort==`cohort'
			cap n replace se_`subgroup' = _se[c.grade#`county'.county] if county==`county' & cohort==`cohort'
		}
	}

	** count number of grades included in each regression **
	bysort cohort county: egen num_grades_included_`subgroup' = count(gcs_mn_`subgroup')
	
	** determine smallest class size used in each regression **
	bysort cohort county: egen min_sample_size_`subgroup' = min(totgyb_`subgroup')

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
	
drop year
rename cohort year
replace year = year - 1 // changed so that the year reflects the fall of the academic year 

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

drop if _merge==1 | year<2013 | year>=$year
drop _merge

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


order year state county subgroup_type subgroup learning_rate learning_rate_lb learning_rate_ub

gsort -year state county subgroup_type subgroup

** export data **
*export delimited using "built/SEDA_all_subgroups.csv", replace
*export delimited using "${boxfolder}/SEDA_all_subgroups.csv", replace
export delimited using "${gitfolder}\08_education\SEDA_all_subgroups_2018.csv", replace

keep if subgroup_type=="all"
drop subgroup_type subgroup

*export delimited using "built/SEDA_years_only.csv", replace
*export delimited using "${boxfolder}/SEDA_years_only.csv", replace
export delimited using "${gitfolder}\08_education\SEDA_years_only.csv", replace


