# Metric template

Brief description

* Years: 2020 (A date is generated when the data are downloaded, so the official year will be whatever the current year is when you download the data from the Data Warehouse - see the record create date). Data are updated by HRSA daily, as noted here: https://data.hrsa.gov/data/about
* Final data name(s): hpsa_2020.csv
* Analyst & Programmer: Claudia Solari 
* Data source(s): HRSA for Primary Care(https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv)
* Notes: Health Professional Shortage Areas (HPSAs) are specified geographic areas (or populations) with recognized shortages of health care providers. HPSA scores describe the extent of the shortage in a particular area. For this metric, we are examining HPSA scores for primary care. We only keep currently designated geographic HPSAs and high needs geographic HPSAs ("high needs" referes to patient needs). The other types we exclude are facility hpsas and population hpsas.
     *We keep only geographic designation types because we are interested in shortages of providers for the entire population within a designated geographic area. Designations of geographic areas as HPSAs change over time, so HPSAs that are proposed with withdrawl are not included since they will be removed from the next round of updated data. 
      *Among the geographic designation types, the record can either be a SCTY = Single County, CSD = County Subdivision, and CT = census tract. Records for a single county are already at the county level. HPSAIDs that are at CSD or CT can fall within one county or cut across more than one county. 
     *HPSA score ranges from 0-25. Within those that are currently designated, the hpsa score values range from 4-25. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA). 
      *Becuase of the fact that an HPSA score can vary within HPSAs within a county, but some cut across counties, the HRSA statistician suggests that we do not try to create a metric that is based on a population-weighted score. Instead, he suggests that if any hpsaid is designated as an hpsa (hpsascore>0) within a county, then that county should be considered an hpsa.
	*Another reason we might not rely heavily on the score is because we cannot fully tease apart the source of the score. We know how points are assigned generally, but not how they are assiged for each hpsa. Plus, some pieces of the score are based on other metrics - poverty (measured here as % population below 100% FPL) and infant health (based on infant mortality rate, which we don't include as a metri, and low birth weight, which we do include as a metric).   
	*Alternatives: an alternative to this approach is to consider any geography OR population within a county that is designated as an hpsa would be flagged as one.  
* Data Quality Index: based on a population size for the hpsa, each county sums up the population for each hpsaid that is assigned to that county. Becuase some hpsaids cut across counties, the total poulation can be artifically higher and it is unclear how the population would be allocated within those geographies within the hpsaid.
	*Alternatives: An alternative approach to the data quality is to merge in a county subdivision and census tract file to get a population size that way. Only trick is that county subdivisions still do not fall in the bounds of a county (despite what the name suggests).     

* Limitations: Only counties that are designated as HPSA are in the dataset, making the assumption that all other counties have zero values for HPSA score. 

* Missingness: No counties are considered missing because those that are not a designated hpsa county are considered not an hpsa. This was noted as a common approach by researchers according to the HRSA statistician. The dataset has a history of those who were once a health professional shortage area (HPSA) and have since had that status withdrawn. Those are considered as not being an hpsa. It also has those who are currently designated as an HPSA, which is our primary focus. 
       *But, counties who were never designated as an HPSA will not have a record in this file. Dates of when they were originally designated and when their record was last changed are included in the file. We will assume that counties that are not in this file are NOT designated as an HPSA. The rest are missing, but the assumption is that they would be a value of zero. This is a strong assumption, as it appears 

*More documentation around the hpsa score calculation for primary care can be found here: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
*Documentation around HPSA designation types is here: https://bhw.hrsa.gov/shortage-designation/types
	 

Outline the process for creating the data:    

1. Import csv file from HRSA website
2. Limit data to only those facilities that are still "designated" as an HPSA
3. Limit to designated geographic HPSAs and high needs geographic HPSAs
   *hpsascore is the key metric variable and ranges from 0-25. 
   *Using designationtype variable, only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
   *Note: those hpsaids that are Proposed for Withdrawal HPSAs are NOT included since they will be removed in next round of updates. Those already withdrawn are not included. 
4. Drop duplicate observations, based on hpsaid within counties and the county designation (single county, county subdivision, census tract)
5. For those that are county subdivisions and census tracts, sum up the populations for those hpsaids. We know these are likely covering less than the county level. Then deduplicate again so that we only retain one record per county. 
6. Merge in the master county crosswalk for those counties in 2018 (most recent file) to get a full set of counties that also includes the county population in 2018. 
7. For the purposes of designing the data quality index, generate a coverage varaible for CSD & CT records. Coverage is the ratio of the summed hpsa population over the county population. 
8. Data quality is set to 3 if the county records of CSD or CT have a coverage <.5 or >1.05. Data quality is set to 2 if CSD or CT records have coverage >=.5 to 1.05. Data quality is set to 1 if the record is a single county or if a county was set to an hpsa indicator of zero, which is basically any county that is not among the counties in the hpsa file for georgraphic hpsas and were currently designated.

