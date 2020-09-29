/*******************************************************************************
Gates Mobility Metrics - Health Professional Shortage Areas

Author: Claudia Solari (based on Diane Arnos)
Date: SEpt 11, 2020

HRSA Documentation: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
*download raw data here: : https://data.hrsa.gov/data/download
	*We will take the Primary Care file only. Other files include Dental Health and Mental Health
	*Data Warehouse Record Create Date: 06/15/2020 (last field in raw data)
	*hpsascore is the metric variable 
	*HPSA score ranges from 0-25. The file is historical. It has a history of those who were once a health
	professional shortage area (HPSA) and have since had that status withdrawn. It also has those who are currently
	designated as an HPSA. But, counties who were never designated as an HPSA will not have a record in this file. Dates of when they were originally designated and when their record was last changed are included in the file. We will assume that counties that are not in this file are NOT designated as an HPSA. 
	*The file has multiple hpsa scores within the same county, and the score varies by hpsaid. We have the population of that ID, and so I create a population weighted score for the hpsa within counties. 

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
cd "${gitfolder}\04_health\data\raw"
import delimited "https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv", case(lower)
save "BCD_HPSA_FCT_DET_PC.csv", replace

/*Test the data. Start with only looking at geographic designation types. It was recommended to see how the counties would look if I added the population-based types*/
	/*first, remove territories and restrict to only designation type we need*/
drop if primarystatefipscode>56 /*This removes territories (drops 374 records)*/
drop if hpsastatus != "Designated"	/* removes withdrawn and proposed for withdrawl (drops 35,933 records)*/
keep if designationtype == "Geographic HPSA" | designationtype == "High Needs Geographic HPSA" /*keeps only the records we want for overall county records. We'll need a different dataset for past years (removes 16,190 records)*/

/*how many county-level records do I have? The HPSAcomponenttypecode indicates SCTY = Single County, CSD = County Subdivision, and CT = census tract*/
tab hpsacomponenttypecode /*have 872 total county records that can stand alone; 1,374 are CSD and 3,455 are CT*/ 
/*Note that HRSA statistician Brandon said it may be that all of the county is included, but is not the single county level, but instead it is all the county subdivisions and hasn't been changed to single county status.*/

/*We determined with the statistician that we would consider an area an HPSA (1) or not (0) if any geography is on the list. But, I will calculate a coverage rate by summing the population size, "HPSA Designation Population," and merge it with the population size in the county file. Note that the population size is repeated, so I need to deduplicat by HPSAID. The populations considered for these areas is the poulation minus those in group homes and in institutions. So, we will under-estimate coverage*/


/*NOTE: Move this keep statement until later. It turned out we needed a lot more variables than what was originally determined*/	
*Only keep relevant variables. Need to keep the population in order to population-weight the scores
/*keep designationtype hpsastatus hpsascore hpsaid commonstatecountyfipscode hpsadesignationpopulation hpsageographyidentificationnumbe*/

gen state = substr(commonstatecountyfipscode, 1, 2) /* already have a state code
gen county = substr(commonstatecountyfipscode, 3, 3)

/*drop commonstatecountyfipscode*/

*Only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs).
	*We expect that we made need other designation types for the subgroup analysis, namely 
*Assumption: "Withdrawn" designation type is not included because they were once a shortage area, but are no longer upon later review. "Proposed with Withdrawal" designation type HPSAs are NOT included since they will be removed in next round of updates

keep if designationtype == "Geographic HPSA" | designationtype == "High Needs Geographic HPSA"

keep if hpsastatus == "Designated" 

* flagging duplicates and assuring that duplicates do not have different HPSA scores
bys hpsaid: gen dupe = _n
bys hpsaid (hpsascore): gen diff = hpsascore[1] != hpsascore[_N]
assert diff ==0
drop diff

* drop duplicates
drop if dupe > 1
drop dupe /*1,306 records remaining*/

/*NOTE: we still have duplicates within the dataset for counties that have multiple scores. Need to population-weight the scores so that we have one score for each county*/
	*generate a sum of the population counts within each state and county
bysort state county: egen popsum = total(hpsadesignationpopulation)	
	*generate a share of the population within counties. It should be 100% for those with only one record per county*/
gen popshare = hpsadesignationpopulation/popsum

/*Note: the hpsa file includes US territories*/
save "${gitfolder}\04_health\data\intermediate\HPSAdesignated_PC.dta", replace


/*Create a dataset of a weighted average of hpsa scores*/
collapse (mean) hpsascore [w=popshare] , by(state county) 
rename hpsascore whpsascore
save "${gitfolder}\04_health\data\intermediate\hpsa_weight.dta", replace /*N=1,111 no duplicated county values*/

/*MERGE this new weighted average hpsa score into the other dataset*/
merge 1:m state county using "${gitfolder}\04_health\data\intermediate\HPSAdesignated_PC.dta" /*back to 1306 cases*/
/*Remove duplicate records by state and county*/
duplicates drop state county, force /*195 drop, leaving 1,111 cases*/
/*Can remove variables I don't need from the weighted average process and the hpsaid is not applicable anymore*/
drop hpsaid popsum popshare _merge hpsascore
 
save "${gitfolder}\04_health\data\intermediate\whpsa_dedup.dta", replace


** Import county file **
import delimited ${countyfile}, clear
drop population state_name county_name
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
merge 1:m state county using "${gitfolder}\04_health\data\intermediate\whpsa_dedup.dta"
/*NOTE: we have more counties in the resulting file --- need to figure that out*/
drop if _merge==2 /*11 counties from the hpsa file were not found in our crosswalk because they are in territories (state codes between 60 and 78*/
drop _merge

/*Set HPSA scores for counties not included in the data set as zeros, since HPSA scores range from 4-25*/
replace whpsascore = 0 if whpsascore == . /* no hpsa designation in N=2,042 counties*/

/*change the year to actually represent the year of the hpsa data*/
replace year = 2020 if year == 2018

/*Data quality Index - it should all be of good quality*/
gen hpsascore_quality = 1

/*Keep only the variables I need in the final dataset*/
drop designationtype hpsastatus hpsadesignationpopulation 

order year state county whpsascore hpsascore_quality
gsort -year state county

export delimited using "${gitfolder}\04_health\data\built\HPSA_2020.csv", replace
export delimited using "${boxfolder}\HPSA_2020.csv", replace
