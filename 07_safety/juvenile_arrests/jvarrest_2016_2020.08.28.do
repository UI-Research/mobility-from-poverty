*********************************
*	Safety Metrics				*
*	Arrests JV - County 2018	*
*	Lily Robin, 2019.8.01		*
*********************************

///// 1.UPDATE FILE DIRECTORY

cd "C:\Users\lrobin\Box Sync\Metrics Database\Safety\Juvenile_Arrest"


///// 2. IMPORT DATA

***crosswalk file for county FIPS to ORI
clear 
use fbi_crosswalk
rename *, lower
rename ori7 ori
*to make sure it is okay to use the ori9 number when ori7 is -1 I will spot check a few of these counties for arrest counts after merging
gen spot_check = (ori == "-1")
replace ori = substr(ori9,1,7) if ori == "-1"
count if ori == "-1"
drop if ori == "-1"
*check for duplicates overall and by ORI, and get to one obs per ORI
duplicates r
duplicates r ori
*br if spot_check == 1
keep fstate fcounty fplace fips_st fips_county fips ori ua statename countyname

foreach var in fips_st fips_county fips ori statename countyname {
	
	replace `var' = trim(`var')
}
duplicates r
duplicates drop
duplicates r ori
duplicates tag ori, gen(dup)
*br if dup > 0
replace fplace = . if dup > 0
duplicates r
duplicates drop
duplicates r ori

save fbi_crosswalk_clean, replace

***crosswalk file for county population aged 10 - 17
clear
import delimited "children_10_17.csv"

*add "0" to beggining of countyfips as needed
*can revise to cleaner substr code if desired
tostring countyfips, replace
gen fip_len = length(countyfips)
gen zero = "0"
egen fip2 = concat(zero countyfips) if fip_len == 4
replace countyfips = fip2 if fip_len == 4
drop fip_len zero fip2

save pop_10_17, replace

***2016 arrests by county
clear
use 2016_arrest

*update missing values - code provided in ICPSR files
replace MSA = . if (MSA == 998)
replace SEQNO = . if (SEQNO == 99998)
replace SUB = . if (SUB == 9)
replace CORE = "" if (CORE == "9")
replace COVBY = . if (COVBY == 9)
replace MONTH = . if (MONTH == 98)
replace MOHEADER = . if (MOHEADER == 998)
replace BREAK = "" if (BREAK == "8")
replace AREO = "" if (AREO == "8")
replace ZERO = . if (ZERO == 8)
replace DTLASTUP = . if (DTLASTUP == 999998)
replace DTPRUP1 = . if (DTPRUP1 == 999998)
replace DTPRUP2 = . if (DTPRUP2 == 999998)
replace JUVDISP = "" if (JUVDISP == "8")
replace JDHANDDP = . if (JDHANDDP == 99998)
replace JDREFJC = . if (JDREFJC == 99998)
replace JDREFWA = . if (JDREFWA == 99998)
replace JDREFOPA = . if (JDREFOPA == 99998)
replace JDREFCC = . if (JDREFCC == 99998)
replace OFFENSE = "" if (OFFENSE == "998")
replace OCCUR = . if (OCCUR == 998)
replace M0_9 = . if (M0_9 == 99998 | M0_9 == 99999)
replace M10_12 = . if (M10_12 == 99998 | M10_12 == 99999)
replace M13_14 = . if (M13_14 == 99998 | M13_14 == 99999)
replace M15 = . if (M15 == 99998 | M15 == 99999)
replace M16 = . if (M16 == 99998 | M16 == 99999)
replace M17 = . if (M17 == 99998 | M17 == 99999)
replace M18 = . if (M18 == 99998 | M18 == 99999)
replace M19 = . if (M19 == 99998 | M19 == 99999)
replace M20 = . if (M20 == 99998 | M20 == 99999)
replace M21 = . if (M21 == 99998 | M21 == 99999)
replace M22 = . if (M22 == 99998 | M22 == 99999)
replace M23 = . if (M23 == 99998 | M23 == 99999)
replace M24 = . if (M24 == 99998 | M24 == 99999)
replace M25_29 = . if (M25_29 == 99998 | M25_29 == 99999)
replace M30_34 = . if (M30_34 == 99998 | M30_34 == 99999)
replace M35_39 = . if (M35_39 == 99998 | M35_39 == 99999)
replace M40_44 = . if (M40_44 == 99998 | M40_44 == 99999)
replace M45_49 = . if (M45_49 == 99998 | M45_49 == 99999)
replace M50_54 = . if (M50_54 == 99998 | M50_54 == 99999)
replace M55_59 = . if (M55_59 == 99998 | M55_59 == 99999)
replace M60_64 = . if (M60_64 == 99998 | M60_64 == 99999)
replace M65 = . if (M65 == 99998 | M65 == 99999)
replace F0_9 = . if (F0_9 == 99998 | F0_9 == 99999)
replace F10_12 = . if (F10_12 == 99998 | F10_12 == 99999)
replace F13_14 = . if (F13_14 == 99998 | F13_14 == 99999)
replace F15 = . if (F15 == 99998 | F15 == 99999)
replace F16 = . if (F16 == 99998 | F16 == 99999)
replace F17 = . if (F17 == 99998 | F17 == 99999)
replace F18 = . if (F18 == 99998 | F18 == 99999)
replace F19 = . if (F19 == 99998 | F19 == 99999)
replace F20 = . if (F20 == 99998 | F20 == 99999)
replace F21 = . if (F21 == 99998 | F21 == 99999)
replace F22 = . if (F22 == 99998 | F22 == 99999)
replace F23 = . if (F23 == 99998 | F23 == 99999)
replace F24 = . if (F24 == 99998 | F24 == 99999)
replace F25_29 = . if (F25_29 == 99998 | F25_29 == 99999)
replace F30_34 = . if (F30_34 == 99998 | F30_34 == 99999)
replace F35_39 = . if (F35_39 == 99998 | F35_39 == 99999)
replace F40_44 = . if (F40_44 == 99998 | F40_44 == 99999)
replace F45_49 = . if (F45_49 == 99998 | F45_49 == 99999)
replace F50_54 = . if (F50_54 == 99998 | F50_54 == 99999)
replace F55_59 = . if (F55_59 == 99998 | F55_59 == 99999)
replace F60_64 = . if (F60_64 == 99998 | F60_64 == 99999)
replace F65 = . if (F65 == 99998 | F65 == 99999)
replace AW = . if (AW == 99998 | AW == 99999)
replace AB = . if (AB == 99998 | AB == 99999)
replace AI = . if (AI == 99998 | AI == 99999)
replace AA = . if (AA == 99998 | AA == 99999)
replace JW = . if (JW == 99998 | JW == 99999)
replace JB = . if (JB == 99998 | JB == 99999)
replace JI = . if (JI == 99998 | JI == 99999)
replace JA = . if (JA == 99998 | JA == 99999)
replace AH = . if (AH == 99998 | AH == 99999)
replace AN = . if (AN == 99998 | AN == 99999)
replace JH = . if (JH == 99998 | JH == 99999)
replace JN = . if (JN == 99998 | JN == 99999)

rename *, lower


///// 3. CREATE/CROSSWALK COUNTY FIPS

merge m:1 ori using fbi_crosswalk_clean
*with only ori7: 1,423,051 matched, 14,087 not matched from master
*with ori7 and suplemented ori9: 1,431,801 matched, 5,337 not matched from master

*12,991 obs not matched from using, likely to include ori9 that were not ucr counties in 2016, therefore, chosing to drop
drop if _merge == 2
*5,337 obs (215 agencies) not matched in master will not be able to be matched to counties so these will be dropped. Appears to include a number of tribal, school, and specialized agencies
preserve
keep if _merge == 1
egen master_unmatched = group(ori)
sum master_unmatched
restore
drop if _merge == 1

*formerly independant city of Bedford, Virginia, change to county of Bedford (51019)
*br if fips == "51515"
replace fcounty = 019 if fips == "51515" 
replace fips_county = "019" if fips == "51515"
replace fips = "51019" if fips == "51515"

///// 4. IDENTIFY NON REPORTING AGENCIES AND OVERLAPPING AGENCIES

*nonreporting agencies
tab zero, m
tab areo if zero == .
tab covby, m

gen nonreport = 0
replace nonreport = 1 if (zero == 1 & covby == 0) | (zero == . & covby == 0)


///// 5. CALCULATE JV ARRESTS

*number of arrests age 10 to 17
egen arrest_10to17 = rowtotal(m10_12 m13_14 m15 m16 m17 f10_12 f13_14 f15 f16 f17)

sum arrest_10to17

*number of children under 10 arrested
egen arrest_under10 = rowtotal (m0_9 f0_9)

sum arrest_10to17 arrest_under10


///// 6. AGGREGATE TO COUNTY

*total # of juvenile arrests by county

gen obs = 1

collapse (sum) arrest_10to17 arrest_under10 nonreport (mean) year fstate fcounty (count) obs, by(fips)
rename (fstate fcounty) (state county)

gen coverage_indicator_jjarrest = 1 - (nonreport/obs)
sum coverage_indicator_jjarrest



///// 7. IDNETIFY STATES WITH AGE OF ADULT CRIMINAL LIBABILITY BELOW 18

*age of adult criminal liability (http://www.jjgps.org/jurisdictional-boundaries) 18 except: 
	*Georgia (13), Louisiana (22), Michigan (26), Missouri (29), South Carolina (45), Texas (48), Wisconsin (55): 17
	*New York (36), North Carolina (37): 16
gen adult_17 = 0
replace adult_17 = 1 if state == 13 | state == 22 | state == 26 | state == 29 | state == 45 | state == 48 | state == 55
gen adult_16 = 0
replace adult_16 = 1 if state == 36 | state == 37
gen adult_under18 = 0
replace adult_under18 = 1 if adult_17 == 1 | adult_16 == 1

///// 8. CROSSWALK POPULATION

rename fips countyfips

merge m:1 countyfips using pop_10_17
*br if _merge == 1
*br if _merge == 2
drop if _merge != 3
rename child_10_17 pop_10to17

*generate juvenile arrest rate
gen juvenile_arrest_rate = (arrest_10to17/pop_10to17)*100000
sum juvenile_arrest_rate
*jhttps://www.ojjdp.gov/ojstatbb/crime/jar_display.asp#:~:text=Juvenile%20Arrest%20Rate%20Trends&text=The%20juvenile%20arrest%20rate%20for,then%20declined%2074%25%20by%202018.&text=Note%3A%20Rates%20are%20arrests%20of,17%20in%20the%20resident%20population

*br if juvenile_arrest_rate > 100000
*A lot of status offenses. Maybe that's why?

drop _merge

save 2016_arrest_by_county_working, replace


///// 9. CROSSWALK TO ALL COUNTIES

clear
import delimited county_crosswalk.csv, varnames(1) 

keep if year == 2016

save county_crosswalk_2016, replace

clear
use 2016_arrest_by_county_working
*46113: Lakota county was changed to be 46102 in 2015 (see note below)
replace county = 102 if countyfips == "46113"

merge 1:1  state county using county_crosswalk_2016

*br if _merge == 1
*02270: Wade Hampton Census Area, Alaska
*46113: Lakota county was changed to be 46102 in 2015 (change replected above)
*br if _merge == 2

///// 10. FINALIZE DATA and EXPORT

*create data quality index
sum coverage_indicator_jjarrest
gen jjarrest_rate_quality = .
replace jjarrest_rate_quality = 1 if coverage_indicator_jjarrest == 1 & coverage_indicator_jjarrest != .
replace jjarrest_rate_quality = 2 if coverage_indicator_jjarrest < 1 & coverage_indicator >= 0.8 & coverage_indicator_jjarrest != .
replace jjarrest_rate_quality = 3 if coverage_indicator_jjarrest < 0.8 & coverage_indicator_jjarrest != .
replace jjarrest_rate_quality = 3 if juvenile_arrest_rate > 100000 & coverage_indicator_jjarrest != .
replace jjarrest_rate_quality = . if juvenile_arrest_rate == .
tab jjarrest_rate_quality

*fips as string
gen state1 = string(state, "%02.0f")
gen county1 = string(county, "%03.0f")

*drop unneeded variables
drop countyfips _merge state_name county_name population nonreport obs state county 

rename (state1 county1 arrest_under10) (state county juvenile_arrests_under10)

*add labels
label var juvenile_arrest_rate "rate of juvenile (age 10 - 17) arrests per 100,000 juveniles in county"
label var juvenile_arrests_under10 "number of arrests of people under 10 in a county"
label var arrest_10to17 "number of arrests of people 10 to 17 in a county"
label var adult_under18 "county in state with criminal liability under 18"
label var pop_10to17 "population of people 10 to 17 in a county"

*save interim dataset
save 2016_arrest_by_county_interim, replace

*drop variables for final dataset
drop pop_10to17 adult_17 adult_16 arrest_10to17

*order variables appropriatly and sort dataset
order year state county juvenile_arrest_rate  juvenile_arrests_under10 coverage_indicator_jjarrest adult_under18, first

gsort year state county

save 2016_arrest_by_county, replace

tabmiss

codebook

*note, the number of juvenile arrests in my file (913,019) is over the estimated number by BJS for 2016 (856,130). I suspect this is just because I am counting 16 and 17 year olds that should not be counted as juvenile in several states and not counting under 10 only accunts for 5,677 arrests according to my file. 

*export as CSV
cd "H:\gates-mobility-metrics\07_safety\juvenile_arrests"

export delimited using "jvarrestrate_county_2016.csv", replace
