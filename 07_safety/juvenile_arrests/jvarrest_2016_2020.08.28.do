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
drop if ori == "-1"
save fbi_crosswalk_clean, replace

***crosswalk file for county population aged 12 - 17
clear
import delimited "children_12_17_v2.csv"

*add "0" to beggining of countyfips as needed
*can revise to cleaner substr code if desired
tostring countyfips, replace
gen fip_len = length(countyfips)
gen zero = "0"
egen fip2 = concat(zero countyfips) if fip_len == 4
replace countyfips = fip2 if fip_len == 4
drop fip_len zero fip2

save pop_12-17_v2, replace

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

*generate temporary statecounty code
tostring state, gen(state_code) 
tostring county, gen(county_code) 

egen statecounty = concat(state_code county_code), p(-)

*# of non-reporting agencies by county
drop if _merge == 1 & zero == 1

count if _merge == 1


///// 4. CHECK MISSING VALUES

*86 with no race or ethinic origin reported, age reported in all, but jv varies by state
tab areo, m
tab statecounty if areo == "4"
tab state if state == 17
*check 17 (Louisiana) - (5 8 9 13 19 22 25 29 30 31 32 35 36 43 47 56 61 62 63)
*Louisiana age of adult criminal liability 16 as of 2016
tab zero, m


///// 5. IDNETIFY STATES WITH AGE OF ADULT CRIMINAL LIBABILITY BELOW 18

label list STATE
*age of adult criminal liability (http://www.jjgps.org/jurisdictional-boundaries) 18 except: 
	*Georgia (10), Louisiana (17), Michigan (21), Missouri (24), South Carolina (32), Texas (42), Wisconsin (48): 17
	*New York (31), North Carolina (32): 16
gen adult_under_18 = 0
replace adult_under_18 = 1 if state == 10 | state == 17 | state == 21 | state == 24 | state == 32 | state == 42 | state == 48 | state == 31 | state == 32

	
///// 6. CALCULATE JV ARRESTS

*combine each jv arrest by race catagory to calculate overall jv arrests
gen arrest_jv = jw + jb + ji + ja

*test for Louisiana which has missing race data
gen arrest_jv_test =(m0_9 + m10_12 + m13_14 + m15 + m16 + f0_9 + f10_12 + f13_14 + f15 + f16) if state == 17

gen test = (arrest_jv != arrest_jv_test) if state == 17

tab test
tab statecounty if test == 1
*br if test == 1
*3 counties have empty test values, the value combining jv arrests by race appear accurate

*Children under 12 (actually has to include 12)
gen arrest_12below =(m0_9 + m10_12 + f0_9 + f10_12)


///// 7. AGGREGATE TO COUNTY

*total # of juvenile arrests by county
bysort fips: egen juvenile_arrest = total(arrest_jv)
sum juvenile_arrest

bysort statecounty: egen juvenile_arrest_nofips = total(arrest_jv)
replace juvenile_arrest = juvenile_arrest_nofips if fips == ""
sum juvenile_arrest

*total # of juvenile arrests 12 and under by county
bysort fips: egen arrest_12under = total(arrest_12below)
sum arrest_12under

bysort statecounty: egen arrest_12under_nofips = total(arrest_12below)
replace arrest_12under = arrest_12under_nofips if fips == ""
sum arrest_12under


///// 7a. REDUCE TO ONE OBSERVATION BY AGENCY

*any non report or coverage overlap
bysort ori: egen nonreporting = max(zero)
bysort ori: egen overlap = max(covby)

* keep only necassry varaibles prior to dropping duplicates to allow for drop
keep year statecounty state state_code county county_code juvenile_arrest arrest_12under fstate fcounty fips_st fips_county fips nonreporting overlap ori adult_under_18

*drop duplicates
duplicates drop
duplicates r ori

*# of non-reporting agencies by county
bysort fips: egen nonreporting_agencies = total(nonreporting)
sum nonreporting_agencies

bysort statecounty: egen nonreporting_agencies_nofips = total(nonreporting)
replace nonreporting_agencies = nonreporting_agencies_nofips if fips == ""
sum nonreporting_agencies

*any overlapping juristictions in county
bysort fips: egen juristiction_overlap = total(overlap)
sum juristiction_overlap

bysort statecounty: egen juristiction_overlap_nofips = total(overlap)
replace juristiction_overlap = juristiction_overlap_nofips if fips == ""
sum juristiction_overlap


///// 7b. REDUCE TO ONE OBSERVATION BY COUNTY

keep year statecounty fstate fcounty fips_st fips_county fips juvenile_arrest arrest_12under nonreporting_agencies juristiction_overlap adult_under_18

gen fips_plus = fips
replace fips_plus = statecounty if fips == ""
drop statecounty

duplicates drop
duplicates r fips_plus


///// 8. CROSSWALK POPULATION

rename fips countyfips

merge m:1 countyfips using pop_12-17_v2
*br if _merge == 1
drop if _merge == 1
drop if _merge == 2
rename child_12_17 pop_12to17

*generate juvenile arrest rate
gen juvenile_arrest_rate = juvenile_arrest/pop_12to17

rename fcounty county

destring fips_st, gen(state)

drop fips_st fips_county

drop _merge

save 2016_arrest_by_county_working, replace


///// 9. CROSSWALK TO ALL COUNTIES

clear
import delimited county_crosswalk.csv, varnames(1) 

keep if year == 2016

save county_crosswalk_2016, replace

clear
use 2016_arrest_by_county_working

merge 1:1  state county using county_crosswalk_2016

*br if _merge == 2

///// 10. FINALIZE DATA and EXPORT

drop fstate

*order variables appropriatly and sort dataset
order year state state_name county county_name countyfips fips_plus juvenile_arrest juvenile_arrest_rate arrest_12under pop_12to17 nonreporting_agencies juristiction_overlap adult_under_18 population _merge, first

gsort year state county

save 2016_arrest_by_county, replace
