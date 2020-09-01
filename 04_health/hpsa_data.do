/*******************************************************************************
Gates Mobility Metrics - Health Professional Shortage Areas

Author: Diane Arnos
Date: Aug 27, 2020

Notes: Not including standard errors or quality flags, since measures are 
contstructed by HRSA and we did not calculate them.
HPSA scores exist only for designated shortage areas, which is why many counties
have missing values in this dataset

Documentation: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
*download raw data here: : https://data.hrsa.gov/data/download
*Most recent dowload/update: August 2020
*Data Warehouse Record Create Date: 06/15/2020 (last field in raw data)

*******************************************************************************/
clear all

*change the file directory here if necessary
global data "C:\Users\DArnos\Box\Metrics Database\Health\HPSA data and program"

import delimited "https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv", case(lower)

*Only keep relevant variables.
*hpsascore is the metric variable 
*HPSA score ranges from 0-26. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA)
keep designationtype hpsastatus hpsascore hpsaid commonstatecountyfipscode

g year = "2020"
gen state = substr(commonstatecountyfipscode, 1, 2)
gen county = substr(commonstatecountyfipscode, 3, 3)

drop commonstatecountyfipscode

*Only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
*Assumption: Proposed with Withdrawal HPSAs are NOT included since they will be removed in next round of updates

keep if designationtype == "Geographic HPSA" | designationtype == "High Needs Geographic HPSA"

keep if hpsastatus == "Designated" 

* flagging duplicates and assuring that duplicates do not have different HPSA scores
bys hpsaid: gen dupe = _n
bys hpsaid (hpsascore): gen diff = hpsascore[1] != hpsascore[_N]
assert diff ==0
drop diff

* drop duplicates
drop if dupe > 1
drop dupe

preserve
global gitfolder "C:\Users\DArnos\Documents\gates-mobility-metrics"
global countyfile "${gitfolder}\geographic-crosswalks\data\county-file.csv"  

import delimited ${countyfile}, clear
drop population state_name county_name

tostring county, replace
replace county = "0" + county if strlen(county)<3
replace county = "0" + county if strlen(county)<3
assert strlen(county)==3

tostring state, replace
replace state = "0" + state if strlen(state)==1
assert strlen(state)==2

tempfile counties
save "`counties'"
restore

merge m:1 statefips countyfips using "`counties'"
drop _merge

g hpsascore_quality = 1

*Set HPSA scores for counties not included in the data set as zeros, since HPSA scores range from 4-26
replace hpsascore = 0 if hpsascore == .

drop designationtype hpsastatus

order year statefips countyfips hpsaid hpsascore hpsascore_quality

export delimited using "${data}\hpsa_metrics_2020-08-31.csv", replace
