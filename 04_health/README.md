# Metric template

Brief description

* Years: 2020 (A date is generated when the data are downloaded, so the official year will be whatever the current year is when you download the data from the Data Warehouse - see the record create date). Data are updated by HRSA daily, as noted here: https://data.hrsa.gov/data/about
* Final data name(s): HPSA_2020.csv
* Analyst(s): Claudia Solari (started by Fred Blavin, Diane Arnos)
* Programmer: Claudia Solari
* Data source(s): HRSA for Primary Care(https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv)
* Notes: Health Professional Shortage Areas (HPSAs) are specified geographic areas (or populations) with recognized shortages of health care providers. HPSA scores describe the extent of the shortage in a particular area. For this metric, we are examining HPSA scores for primary care. We only keep currently designated geographic HPSAs and high needs geographic HPSAs ("high needs" referes to patient needs). We keep only geographic designation types because we are interested in shortages of providers for the entire population within a designated geographic area. Designations of geographic areas as HPSAs change over time, so HPSAs that are proposed with withdrawl are not included since they will be removed from the next round of updated data. HPSA score ranges from 0-25. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA). * Data Quality Index: quality indicators for HPSA score are set to one because scores are constructed by HRSA.
    * Limitations: Only counties that are designated as HPSA are in the dataset, making the assumption that all other counties have zero values for HPSA score. 
    * Missingness: The dataset has a history of those who were once a health professional shortage area (HPSA) and have since had that status withdrawn. It also has those who are currently designated as an HPSA, which is our primary focus. But, counties who were never designated as an HPSA will not have a record in this file. Dates of when they were originally designated and when their record was last changed are included in the file. We will assume that counties that are not in this file are NOT designated as an HPSA. Of the 3,145 counties, only 1,111 have a score. The rest are missing, but the assumption is that they would be a value of zero. This is a strong assumption, as it appears 
More documentation around the hpsa score calculation for primary care can be found here: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
Documentation around HPSA designation types is here: https://bhw.hrsa.gov/shortage-designation/types

Outline the process for creating the data:    

1. Import csv file from HRSA website
3. Limit data to only those facilities that are still "designated" as an HPSA
4. Limit to designated geographic HPSAs and high needs geographic HPSAs
   *hpsascore is the key metric variable and ranges from 0-25. 
4. Using designationtype variable, only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
   *Assumption: Proposed with Withdrawal HPSAs are NOT included since they will be removed in next round of updates. Those already withdrawn are not included. 
5. Drop duplicate observations, based on hpsaid, and confirm that all duplicate observations have the same hpsascore value
6. Some counties still have multiple hpsascore values within a county. The scores are weighted accourding to the hpsadesignationpopulation size. Population-weighted averages of scores are calculated within counties, and then counties are deduplicated
6. Merge the weighted hpsa score dataset into our master county crosswalk to a full set of counties, with missing values for those counties not wiht an HPSA score. Set HPSA score to zero for counties not in the HPSA dataset.

