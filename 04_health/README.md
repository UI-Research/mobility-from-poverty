# HPSA

* Years: 2020 (A date is generated when the data are downloaded, so the official year will be whatever the corrent year is when you download the data from the Data Warehouse - see the record create date)
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

# Neonatal Health

This metric captures the share of low birthweight infants out of all births

* Final data name(s): neonatal_health.csv
* Analyst(s): Emily M. Johnston
* Data source(s): United States Department of Health and Human Services (US DHHS), Centers for Disease Control and Prevention (CDC), National Center for Health Statistics (NCHS), Divison of Vital Statistics, Natality public-use data 2007-2018, on CDC WONDER Online Database, September 2019 
* Year(s): 2018
* Notes:
    * Low birthweight is defined as less than 2,500 grams
    * County refers to county of mother's legal residence at the time of birth
    * Counties with populations under 100,000 persons based on the 2010 Census are grouped into pooled "Unidentified Counties" in the CDC WONDER data
        * All counties with populations under 100,000 in a given state have the same value for lbw
    * lbw_quality is a quality flag for the low birthweight metric
        * A score of 1 indicates a high-quality calculated metric for the observation
		* All counties with populations of 100,000 persons or more for which the metric is county-specific have a quality score of 1
	* A score of 2 indicates limited issues for the calculated metric for the observation
		* No counties have a quality score of 2
	* A score of 3 indicates serious issues for the calculated metric for the observation
		* All counties with populationess under 100,000 for which the metric reflects the pooled share low birthweight for all "Unidentified Counties" in the state and are not county-specific have a quality score of 3
 

## Process for creating the data

1. Download data from CDC WONDER (see detailed process below)
    * County-level counts of:
	* Births
	* Births with nonmissing birthweight data
	* Low birthweight births
2. Merge CDC WONDER data with crosswalk to create county-level file
3. Assign counties missing from CDC WONDER data the values for their state's "Unidentified Counties" in CDC WONDER data
4. Construct the share low birthweight
    * Divide the number of low birthweight births in a county by the number of births with nonmissing birthweight data
5. Calculate 95 percent confidence intervals (see detailed process below)

## Limitations
* County-level data are not available for counties with fewer than 100,000 residents based on the 2010 Census. Instead, these counties are assigned the share of low birthweight births among all births for *all unidentified counties combined*

## Process for downloading the data
1. Begin at https://wonder.cdc.gov/
2. Select Births (https://wonder.cdc.gov/natality.html)
3. Select Natality for 2007-2018 (data query will be automatically limited to the most recent year of data, 2018)
    * The process below can be repeated for other available periods
        * 2003-2006
        * 1995-2002
4. Agree to terms of data use
5. Run queries for county-level metrics in 2018
    * Select the following options to run query for all births 
        * Section 1. Group Results by County
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "all_births_by_county.txt"
    * Select the following options to run query for birth with nonmissing birth weight information
        * Section 1. Group Results by County
        * Section 4. Infant Birth Weight 12 [select all options except (all weights) and (unknown or not stated)]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "nomiss_bw_by_county.txt"
        * Select the following options to run query for low birth weight births
        * Section 1. Group Results by County
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county.txt"


## Process for calculating 95 percent confidence intervals

Following the guidance provided in the User Guide to the [2010 Natality Public Use File](ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/natality/UserGuide2010.pdf), we use the following process to compute 95 percent confidence intervals for the neonatal health measure.

The neonatal health measure is share low birthweight births in a county. Because this is a percentage, we follow the guidelines for computing 95-percent confidence intervals for percents and proportions.

First, we confirm that the conditions are met:

B*p≥5 and B*q≥5
Where:
B = number of all births with nonmissing birthweight data in the denominator
p = percent of low birthweight births divided by 100
q = 1 – p

If these conditions are met, we compute the confidence intervals using the following formulas:

Lower Limit =p-1.96 (√((p×q)/B))
Upper Limit =p+1.96 (√((p×q)/B))
Where:
p = percent of low birthweight births divided by 100
q = 1 – p
B = number of all births with nonmissing birthweight data in the denominator
