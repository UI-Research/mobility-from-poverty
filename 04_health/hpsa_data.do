clear all

*download raw data here: : https://data.hrsa.gov/data/download
*Most recent dowload/update: August 2020
*Data Warehouse Record Create Date: 06/15/2020 (last field in raw data)
*Import excel file into Stata

import excel "C:\Users\DArnos\Box\Hospital payment data\BCD_HPSA_FCT_DET_PC.xlsx", sheet("BCD_HPSA_FCT_DET") firstrow case(lower)

*Only keep relevant variables.
*hpsascore is the metric variable 
*HPSA score ranges from 0-26. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA)

keep designationtype hpsastatus hpsascore hpsaid commonstatecountyfipscode commonstatefipscode

*Only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
*Assumption: Proposed with Withdrawal HPSAs are NOT included since they will be removed in next round of updates

keep if designationtype == "Geographic HPSA" | "High Needs Geographic HPSA"
keep if hpsastatus == "Designated"

*Drop duplicate observations and confirm that all duplicate observations have the same hpsascore value

bys hpsaid: gen dupe = _n

bys hpsaid (hpsascore): gen diff = hpsascore[1] != hpsascore[_N]
su diff

drop if dupe > 1
drop dupe


save "C:\Users\DArnos\Box\Hospital payment data\hpsa_data.dta", replace