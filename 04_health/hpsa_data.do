/*******************************************************************************
Gates Mobility Metrics - Health Professional Shortage Areas

Author: Claudia Solari 
Date: Oct 1, 2020
Data year: 2020 (pulling the data from online autogenerates a date. Data are updated daily, so I fixed the dataset from what was pulled on Sept 29, 2020)

HRSA Documentation: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
*download raw data here: : https://data.hrsa.gov/data/download
	*We will take the Primary Care file only. Other files include Dental Health and Mental Health
	*Data Warehouse Record Create Date: 09/29/2020 (last field in raw data)
	*hpsascore is the basis of the metric variable 
	*HPSA score ranges from 0-25. Has a range of records, even those who are curretly designated, 		withdrawn, or proposed for withdrawl. Within those currently designated as an HPSA, the values ranged from 4-25. HPSAs are designated as a geography, population, or facility. We focus on the geography for the purpose of getting a county-level hpsa flag. 
Limitations: Counties who were never designated as an HPSA will not have a record in this file. Dates of when they were originally designated and when their record was last changed are included in the file. We will assume that counties that are not in this file are NOT designated as an HPSA. Some HPSAs might have determined that they can get more grant money as an hpsa if they designate a population-specific hpsa and they might withdraw from being a geographic hpsa for that reason. That means, it is possible to have a county that is not an hpsa based on geography, but it is an hpsa based on a vulnerable population. 
	*The file has multiple hpsa scores within the same county, and the score varies by hpsaid. We have the population of that ID, so it is possible to create a population weighted score for the hpsa within counties, but the HRSA statistician does not recommend this. 

Notes: Standard errors are not calculated because measures are contstructed by HRSA directly.
*******************************************************************************/
clear all

*change the file directory here if necessary
global gitfolder "K:\Metro\CSolari\gates-mobility-metrics"
global boxfolder "D:\Users\csolari\Box Sync\Gates Dramatically Increasing Mobility from Poverty\Metrics Database\Health\"
global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"
*create a folder structure to create a home for the data we will use
cap n mkdir "${gitfolder}\04_health\data"
cd "${gitfolder}\04_health\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"


/*Import the Primary Care file only*/
/*last updated the raw data from HRSA on Sept 30, 2020*/
/*
cd "${gitfolder}\04_health\data\raw"
import delimited "https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv", case(lower)
save "BCD_HPSA_FCT_DET_PC.csv", replace 
*/
/*export the dataset from Sept 29, 2020 to our team's box folder and keep this untouched*/
/*
use "${gitfolder}\04_health\data\raw\BCD_HPSA_FCT_DET_PC.csv"
export delimited using "${boxfolder}\hpsa\raw_data\BCD_HPSA_FCT_DET_PC.csv", replace
*/
 /*keep a version of this dataset and use this for our current year file. This dataset is updated daily and there is an RFI out to change the scoring criteria. Preserving the file for this reason.*/
 /*Note: for some reason, this loses the variable lables*/
 
/*use the dataset saved in our team's box folder for the current exercise*/
import delimited using  "${boxfolder}\hpsa\raw_data\BCD_HPSA_FCT_DET_PC.csv"

/*Test the data. Start with only looking at geographic designation types. It was recommended to see how the counties would look if I added the population-based types*/
	/*first, remove territories and restrict to only designation type we need*/
drop if primarystatefipscode>56 /*This removes territories (drops 374 records)*/
drop if hpsastatus != "Designated"	/* removes withdrawn and proposed for withdrawl (drops 35,933 records). Those who are withdrawn or proposed for withdrawl means that they are not an HPSA according to the statistician at HRSA*/

keep if designationtype == "Geographic HPSA" | designationtype == "High Needs Geographic HPSA" /*keeps only the records we want for overall county records. We'll need a different dataset for past years (removes 16,190 records)*/

/*how many county-level records do I have? The HPSAcomponenttypecode indicates SCTY = Single County, CSD = County Subdivision, and CT = census tract*/
tab hpsacomponenttypecode /*have 872 total county records that can stand alone; 1,374 are CSD and 3,455 are CT*/ 
/*Note that HRSA statistician Brandon said it may be that all of the county is included, but is not the single county level, but instead it is all the county subdivisions and hasn't been changed to single county status.*/

/*I have duplicate records that I need to trim down so it gives me one relevant HPSA record per HPSAID. I is true that for some HPSAIDs I will have different HPSA scores, but we determined with the statistician that we would consider an area an HPSA (1) or not (0) if any geography is on the list. But, I will calculate a coverage rate by summing the population size, "HPSA Designation Population," and merge it with the population size in the county file to get the denominator. Note that the population size is repeated, so I need to deduplicate by HPSAID. The populations considered for these areas is the poulation minus those in group homes and in institutions. So, we will under-estimate coverage*/

/*keep all the cases where it is the full county. Note that some HPSAIDs are based on two counties (e.g. HPSAID=1516238772). So, if you want to keep those separate, we need to keep the state and county indicator*/
/*sort on hpsaid and something else that creates a unique ordering, and keep the first one. */
bysort commonstatecountyfipscode hpsacomponenttypecode hpsaid: keep if _n==1 /*4,283 observations deleted*/

/*make sure I kept all my 872 single county records*/
tab hpsacomponenttypecode /*yes, it is good*/

/*I just want to look at my new dataset and make sure it is sound*/
save "${gitfolder}\04_health\data\intermediate\hpsa_bysort1.dta", replace
export excel "${gitfolder}\04_health\data\intermediate\test1.xlsx" /*for some reason, this does't include variable names. As a short-cut, I copied the variable names from the original dataset. They are all in proper order*/
/*NOTE: we have counties with the same HPSAID, but they are in different counties, but the population size is identical because it is for the whole HPSAID. In the case of HPSAID = 1175310412, it is a county subdivision with two records, one in La Salle County, IL, and the other in aLee County, IL. La Salle has another county subdivision record of a different HPSAID (1173136549). Because the HPSA Designation Population is based on the HPSAID, it means when I calculate coverage rates, I might exceed 100% per county. I can't tell how much of the population is in which county. */

/*NOTE: we still have multiple records in a county for the county subdivision and census tract types. We want to sum the hpsa population for records within the same county. */ 
	*generate a sum of the population counts within each state and county
bysort commonstatecountyfipscode: egen hpsapopsum = total(hpsadesignationpopulation)

/*Confirm that the sum worked. Look at commonstatecountyfipscode=="04003"*/
tab hpsapopsum if commonstatecountyfipscode=="04003"	/*That works. It is based on 5 census tracts and they sum to the amount specified in hpsapopsum*/
/*now I can reduce the sample so I have one record per county. If they are on this list, they are an hpsa county*/
bysort commonstatecountyfipscode: keep if _n==1 /*219 observations are deleted*/
/*Note: I should still have a distribution of records that are full county, but also tract subdivisions. It is possible that some counties had both subdivisions and census tracts, and those should have all summed the populations together, so we can still calculate coverage within the county*/
tab hpsacomponenttypecode /*yes, this is confirmed. I still have all 872 full county records, and 167 CSD and 160 CT*/
/* create an hpsa flag*/
gen hpsa_yn=1
/*generate state and county variables for merging in the county file*/
gen state = substr(commonstatecountyfipscode, 1, 2) 
gen county = substr(commonstatecountyfipscode, 3, 3)

/*confirm I don't have any duplicate county records*/
duplicates report commonstatecountyfipscode /*great, no duplicates*/

/*save this county-level file, one record per county*/
save "${gitfolder}\04_health\data\intermediate\hpsacounty_pc.dta", replace


***********************
** Import county file **
import delimited ${countyfile}, clear
drop state_name county_name
/*Keep only the year we're going to use. Note that the HPSA file is 2020 counties, but we only have 2018 counties in the crosswalk*/
keep if year==2018 /*3,142 total records left*/

tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

save "${gitfolder}\04_health\data\intermediate\countyfile.dta", replace

/*MERGE hpsa data into the county crosswalk*/

/*The countyfile crosswalk file doesn't include territories but the HPSA file does. We also have a lot of missing counties in the HPSA, so we need to keep those that are in the crosswalk file*/
merge 1:m state county using "${gitfolder}\04_health\data\intermediate\hpsacounty_pc.dta"
/*look at the county that doesn't merge. This could be because a new county code was tweaked between 2018 and 2020*/
tab countyequivalentname if _merge==2 /*it is Wade Hampton (former census area), hpsaid = 1023212062, it is a record in Alaska. We had two records for this HPSAID originally. The state is 02 and county is 270*/

drop if _merge==2 /*drop this one county so the overall metrics merge is smooth*/
tab _merge /*leaves me with 1,198 that are matched, so should be hpsa_yn==1; the remaining 1,944 will not be an hpsa*/
tab hpsa_yn _merge, miss
/*Set HPSA yn for counties not included in the data set as zeros*/
replace hpsa_yn = 0 if hpsa_yn == . /* no hpsa designation in N=1,944 counties*/
tab hpsa_yn _merge, miss
/*change the year to actually represent the year of the hpsa data*/
replace year = 2020 if year == 2018

/*calculate a population coverage estimate only for those records that are hpsa counties and that are not hpsacomponenttypecode!=SCTY */
gen coverage = hpsapopsum/population if hpsacomponenttypecode=="CT" | hpsacomponenttypecode=="CSD"

/*explore this coverage varaible. I know I should have coverages that exceed 1*/
sum coverage, detail /*327 counties with some coverage value. The 50% percentile is .24 and the 75th is .53. I will give a data quality of 3 for cases where coverage <.5. I will assign a data quality of 2 if it is =>.5 and <=1. But, if it is greater than 1, I will also consider this a data quality of 3 because that includes population size from another county and we can't tell how much of that is in each*/
tab coverage if hpsacomponenttypecode=="CSD" & coverage>1 /*26 cases*/
tab coverage if hpsacomponenttypecode=="CT" & coverage>1 /*12 cases here that I wouldn't have expected because CTs should be nested in counties. But, it could be that these were geographies that also had CSDs in the same county*/
tab hpsaid if hpsacomponenttypecode=="CT" & coverage>1 
/*in looking at hpsaid = 1017860702, these are only CTs. The populations should have been as of 2017, so that could explain a difference, if the 2018 population declined in Tallassee, AL. THe coverage level for this one is: */
tab coverage if hpsaid == "1017860702" /*this covers 3 counties, including Macon which has lots of records (all rural), Tallapoosa County, AL (with one record) and Elmore County, AL which is both rural and non-rural. What happens is that because it is all the same HPSAID, the pop size was the same across them all*/
tab commoncountyname coverage if hpsaid == "1017860702" /*This doesn't look right. Becuase we have a county with one census tract but it looks like coverage is high because the population includes the population of all the other CTs from the other counties. I should identify cases were the HPSAID crosses counties and set those to data quality of 3*/
duplicates report hpsaid if hpsa_yn==1 & (hpsacomponenttypecode=="CT" | hpsacomponenttypecode=="CSD") /*209 of them are within the same county, 74 cross two counties, 24 cross 3, and 20 cross 4. I should set those duplicates to data quality of 3*/
duplicates tag hpsaid if hpsa_yn==1 & (hpsacomponenttypecode=="CT" | hpsacomponenttypecode=="CSD"), gen(dup_hpsaid) 
tab dup_hpsaid /*Now I can set those of dup_hpsaid>=1 & dup_hpsaid<=3 to be data quality of 3*/
/*now look at coverate over 1 if the dup_hpsaid is 0*/
sum coverage if dup_hpsaid==0, detail /*it looks like we still have a range of coverage, and even at the 75th percentile, the coverage is .4. So, of these partial county records, most will be of data quality=3. What might be within reason is a population change of 5% in a short amount of time. So, coverage can be >=.5 to <=1.05 and still be a data quality of 2. Otherwise, it is a data quality of 3. */


/*Data quality Index*/
gen hpsa_yn_quality = .
/*assign the poorest values as specified above*/
replace hpsa_yn_quality=3 if (dup_hpsaid>=1) & (dup_hpsaid<=3) /*recodes 118 cases*/
replace hpsa_yn_quality=3 if (coverage>0 & coverage <.5) /*167 cases*/
replace hpsa_yn_quality=3 if (coverage>1.05 & coverage <20) /*11 changes*/
/*data quality of 2 is if among the less than full counties, their coverage is .5 to 1.05*/
replace hpsa_yn_quality= 2 if (coverage>=.5 & coverage <=1.05) /*59 changes*/
/*if the hpsa_yn is zero then the data quality is 1 and if the hpsacomponenttypecode=="SCTY" the data quality is 1*/
replace hpsa_yn_quality=1 if hpsacomponenttypecode=="SCTY" /*871 changes*/
replace hpsa_yn_quality=1 if hpsa_yn==0 /*1944 changes*/
/*confirm it gets all the records*/
tab hpsa_yn_quality, miss /*yes, it works. 2815 have quality 1, 59 with quality 2, and 268 with quality 3*/
/*save a version of this intermediate data*/
save "${gitfolder}\04_health\data\intermediate\hpsacounty_allvars.dta", replace
/*Keep only the variables I need in the final dataset*/
keep year state county hpsa_yn hpsa_yn_quality 

order year state county hpsa_yn hpsa_yn_quality
gsort -year state county

export delimited using "${gitfolder}\04_health\data\built\hpsa_2020.csv", replace
export delimited using "${boxfolder}\hpsa\hpsa_2020.csv", replace

