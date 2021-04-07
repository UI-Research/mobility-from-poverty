<style type="text/css" rel="stylesheet">
h2 {
  color: #1696d2;
}
</style>

# <ins>Index</ins>

* [Income](#income)
* [Financial Security](#financial-security)
* [Affordable housing](#affordable-housing)
* [Housing instability and homelessness](#housing-instability-and-homelessness)
* [Family structure and stability](#family-structure-and-stability)
* [Access to and utilization of health services](#access-to-and-utilization-of-health-services)
* [Neonatal health](#neonatal-health)
* [Political participation](#political-participation)
* [Economic inclusion](#economic-inclusion)
* [Racial diversity](#racial-diversity)
* [Transportation access](#transportation-access)
* [Environmental quality](#environmental-quality)
* [Exposure to crime](#exposure-to-crime)
* [Overly punitive policing](#overly-punitive-policing)
* [Access to preschool](#access-to-preschool)
* [Effective public education](#effective-public-education)
* [Student poverty concentration](#student-poverty-concentration)
* [College readiness](#college-readiness)
* [Employment](#employment)
* [Access to jobs paying a living wage](#access-to-jobs-paying-a-living-wage)

---

# <ins>Metrics</ins>

## Income

### Overview

* **Analyst & Programmer:** Kevin Werner and Paul Johnson
* **Year(s):** 2018
* **Final data name(s):** `metrics_income.csv`
* **Data Source(s):** ACS 1-yr for original and ACS 5-yr for subgroup.
* **Notes:** I used the `quantreg` procedure to get the percentiles. The three programs beginning `1_`, `2_`, and `3_` must be run before computing these metrics. These programs `infile` some .csv files which can be found on Box under "ACS-based metrics." For the subgroup analysis, I have changed from the `quantreg` procedure to `proc means`. I get the percentiles for each state-county-race combination with proc means. To run the subgroup programs, you must run the programs `1_`, `2_`, and then `3_prepate_microdata_5_year`. 
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** 

### Process

The data comes from IPUMS. It is cleaned and counties are added with Paul's method. Then I use the `quantreg` procedure to get the needed percentiles. Finally it is output as a .csv. The process for the subgroup analysis is the same, except I create the percentiles with proc means. I do not create confidence intervals. 

---

## Financial security

---

## Affordable housing

### Overview

* **Analyst & Programmer:** Paul Johnson and Kevin Werner
* **Year(s):** 2018
* **Final data name(s):** `metrics_housing.csv`
* **Data Source(s):** ACS 1-year
* **Notes:**
* **Data Quality Index:**
* **Limitations:** Counties 89 and 119 in state 36 (NY) had some missing data and may not be reliable. 
* **Missingness:** Metrics are missing for county 05 in Hawaii.

### Process

First of all, it requires extra data --- Section-8 FMR area income levels, and the population of each FMR area.  This info is imported at the beginning of the program (I'm not sure where this data was obtained, but I think it came from HUD's website), and then combined and made ready for merging with the microdata file. Once it is merged we can determine which households have incomes under 80% and under 40% of the AMI, and which live in "affordable" housing. Note that, regardless of the household size, the AMI for a family of 4 is always used. After this, we also need to account for the affordability of vacant units.  This uses a file ("vacant") produced by the program `prepare_vacant` macro. The final metrics are a combination of the results from the microdata file and the results from the vacant file.

---

## Housing instability and homelessness

### Overview

* Brief description: This metric is the total number of students experiencing homelessness at some point during the school year.
* **Analyst & Programmer:** Erica Blom
* **Year(s):** 2018 (2018-19 school year); 2014 (2014-15 school year)
* **Final data name(s):** `homelessness.csv`
* **Data Source(s):** EDFacts homelessness data; Common Core of Data (CCD) to identify counties.
* **Notes:**
* **Data Quality Index:** Data quality of "1" requires the ratio of the upper bound (`homeless_count_ub`) to the lower bound (`homeless_count_lb`) to be less or equal to than 1.05. Data quality of "2" requires this ratio to be greater than 1.05 and less than or equal to 1.1. Data quality of 3 is the remainder. Note that the  largest value of this ratio is 3.5 and that only 6 counties in 2018 and 13 in 2014, each with estimated homeless populations of less than 20, have ratio values at or between 2 to 3.5.
* **Limitations:** Data suppression
* **Missingness:** 286/3,142 counties in 2018; 323/3,142 counties in 2014

### Process

Counts of students experiencing homelessness are downloaded from the EDFacts website. Suppressed data are replaced with 1 for the main estimate and 0 for the lower bound. For the upper bound, suppressed data are replaced with the smallest non-suppressed value by state and subgrant status if there are two or fewer suppressed values by state and subgrant status, per the documentation, and 2 otherwise. Districts are assigned to the county where the district office is located (obtained from the CCD data). Shares are calculated by dividing by total enrollment in the county (again based on) the location of the district office, with enrollment counts also from CCD data). A flag indicates the number of districts with suppressed data that are included in each county's estimate.

---

## Family structure and stability

### Overview

* **Analyst & Programmer:** Kevin Werner and Paul Johnson
* **Year(s):** 2018
* **Final data name(s):** `metrics_famstruc.csv`
* **Data Source(s):** ACS 1-yr and ACS 5-yr for subgroup. 
* **Notes:** 
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** 

### Process

The `compute_` program calculates the percent of children in each family structure, while the finalize_ calculates the confidence intervals and outputs the .csv. NOTE: to run this code, you must first run the `1_`, `2_`, and `3_` programs in the income folder. (For the subgroup analysis, run `3_create_microdata_5_year`.)

The data comes from IPUMS. It is cleaned and counties are added with Paul's method. The `compute_` code then finds the percent of children in each family structure. The `finalize_` program then calculates confidence intervals a outputs as a .csv.

The process for the subgroup analysis is the same as above, except every county has four rows,
one for each race/ethnicity subgroup.

---

## Access to and utilization of health services

### Overview

* **Analyst & Programmer:** Claudia Solari 
* **Year(s):** 2020 (A date is generated when the data are downloaded, so the official year will be whatever the current year is when you download the data from the Data Warehouse - see the record create date). Data are updated by HRSA daily, as noted here: https://data.hrsa.gov/data/about
* **Final data name(s):** `hpsa_2020.csv`
* **Data Source(s):** HRSA for Primary Care (https://data.hrsa.gov//DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv)
* **Notes:** Health Professional Shortage Areas (HPSAs) are specified geographic areas (or populations) with recognized shortages of health care providers. HPSA scores describe the extent of the shortage in a particular area. For this metric, we are examining HPSA scores for primary care. We only keep currently designated geographic HPSAs and high needs geographic HPSAs ("high needs" refers to patient needs). The other types we exclude are facility hpsas and population hpsas.
     * We keep only geographic designation types because we are interested in shortages of providers for the entire population within a designated geographic area. Designations of geographic areas as HPSAs change over time, so HPSAs that are proposed with withdrawal are not included since they will be removed from the next round of updated data. 
      * Among the geographic designation types, the record can either be a SCTY = Single County, CSD = County Subdivision, and CT = census tract. Records for a single county are already at the county level. `HPSAID`s that are at CSD or CT can fall within one county or cut across more than one county. 
     * HPSA score ranges from 0-25. Within those that are currently designated, the hpsa score values range from 4-25. If a county is not in this data set, they are NOT a designated health professional shortage area (HPSA). 
      * Because of the fact that an HPSA score can vary within HPSAs within a county, but some cut across counties, the HRSA statistician suggests that we do not try to create a metric that is based on a population-weighted score. Instead, he suggests that if any hpsaid is designated as an hpsa (hpsascore>0) within a county, then that county should be considered an hpsa.
	* Another reason we might not rely heavily on the score is because we cannot fully tease apart the source of the score. We know how points are assigned generally, but not how they are assigned for each hpsa. Plus, some pieces of the score are based on other metrics - poverty (measured here as % population below 100% FPL) and infant health (based on infant mortality rate, which we don't include as a metric, and low birth weight, which we do include as a metric).   
	* Alternatives: an alternative to this approach is to consider any geography OR population within a county that is designated as an hpsa would be flagged as one.  
* **Data Quality Index:** Data quality is set to 3 if the county records of CSD or CT. Data quality is set to 1 if the county is SCTY or if the hpsa_yn is zero
	* Alternatives: 1. based on a population size for the hpsa, each county sums up the population for each hpsaid that is assigned to that county. Because some `hpsaids` cut across counties, the total population can be artificially higher and it is unclear how the population would be allocated within those geographies within the hpsaid. Generate a coverage variable for CSD & CT records. Coverage is the ratio of the summed hpsa population over the county population. 
	Data quality is set to 3 if the county records of CSD or CT have a coverage <.5 or >1.05. Data quality is set to 2 if CSD or CT records have coverage >=.5 to 1.05. Data quality is set to 1 if the record is a single county or if a county was set to an hpsa indicator of zero, which is basically any county that is not among the counties in the hpsa file for geographic hpsas and were currently designated.	
	2. An alternative approach to the data quality is to merge in a county subdivision and census tract file to get a population size that way. Only trick is that county subdivisions still do not fall in the bounds of a county (despite what the name suggests).   
  * More documentation around the hpsa score calculation for primary care can be found here: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa
  * Documentation around HPSA designation types is here: https://bhw.hrsa.gov/shortage-designation/types
* **Limitations:** Only counties that are designated as HPSA are in the data set, making the assumption that all other counties have zero values for HPSA score.
* **Missingness:** No counties are considered missing because those that are not a designated hpsa county are considered not an hpsa. This was noted as a common approach by researchers according to the HRSA statistician. The data set has a history of those who were once a health professional shortage area (HPSA) and have since had that status withdrawn. Those are considered as not being an hpsa. It also has those who are currently designated as an HPSA, which is our primary focus. But, counties who were never designated as an HPSA will not have a record in this file. Dates of when they were originally designated and when their record was last changed are included in the file. We will assume that counties that are not in this file are NOT designated as an HPSA. The rest are missing, but the assumption is that they would be a value of zero. This is a strong assumption, as it appears 

### Process

Outline the process for creating the data:    

1. Import csv file from HRSA website
2. Limit data to only those facilities that are still "designated" as an HPSA
3. Limit to designated geographic HPSAs and high needs geographic HPSAs
   * `hpsascore` is the key metric variable and ranges from 0-25. 
   * Using designation type variable, only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
   * Note: those `hpsaids` that are Proposed for Withdrawal HPSAs are NOT included since they will be removed in next round of updates. Those already withdrawn are not included. 
4. Drop duplicate observations, based on hpsaid within counties and the county designation (single county, county subdivision, census tract)
5. For those that are county subdivisions and census tracts, sum up the populations for those `hpsaids`. We know these are likely covering less than the county level. Then deduplicate again so that we only retain one record per county. 
6. Merge in the master county crosswalk for those counties in 2018 (most recent file) to get a full set of counties that also includes the county population in 2018. 
7. For the purposes of designing the data quality index, generate a coverage variable for CSD & CT records. Coverage is the ratio of the summed hpsa population over the county population. 
8. Data quality is set to 3 if the county records of CSD or CT. Data quality is set to 1 if the record is a single county or if a county was set to an hpsa indicator of zero, which is basically any county that is not among the counties in the hpsa file for geographic hpsas and were currently designated.

---

## Neonatal health

### Overview

* **Analyst & Programmer:** Emily M. Johnston
* **Year(s):** 2018
* **Final data name(s):** `neonatal_health.csv`
* **Data Source(s):** United States Department of Health and Human Services (US DHHS), Centers for Disease Control and Prevention (CDC), National Center for Health Statistics (NCHS), Division of Vital Statistics, Natality public-use data 2007-2019, on CDC WONDER Online Database, available October 2020. Accessed December 2020. 
* **Notes:**
  * Low birthweight is defined as less than 2,500 grams
  * County refers to county of mother's legal residence at the time of birth
  * Counties with populations under 100,000 persons based on the 2010 Census are grouped into pooled "Unidentified Counties" in the CDC WONDER data
  * All counties with populations under 100,000 in a given state have the same value for lbw
	* County-level data for some racial/ethnic groups are suppressed when the figure represents fewer than 10 persons 
* **Data Quality Index:**
  * `lbw_quality` is a quality flag for the low birthweight metric
  * A score of 1 indicates a high-quality calculated metric for the observation
		* All counties with populations of 100,000 persons or more for which the metric is county-specific and not suppressed have a quality score of 1
	* A score of 2 indicates limited issues for the calculated metric for the observation
		* All counties with between 10 and 29 low birthweight births have a quality score of 2
	* A score of 3 indicates serious issues for the calculated metric for the observation
		* All counties with populations under 100,000 for which the metric reflects the pooled share low birthweight for all "Unidentified Counties" in the state and are not county-specific have a quality score of 3
 		* All counties with suppressed estimates (indicating fewer than 10 low birthweight births) have a quality score of 3
* **Limitations:**
* **Missingness:** 
  * County-level data are not available for counties with fewer than 100,000 residents based on the 2010 Census. Instead, these counties are assigned the share of low birthweight births among all births for *all unidentified counties combined*
  * County-level data for some racial/ethnic groups are *suppressed* when the figure represents fewer than 10 persons 

### Process

1. Download data from CDC WONDER (see detailed process below)
    * County-level counts of:
	* Births among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
	* Births with non-missing birthweight data among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
	* Low birthweight births among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
2. Merge CDC WONDER data with crosswalk to create county-level file
3. Assign counties missing from CDC WONDER data the values for their state's "Unidentified Counties" in CDC WONDER data for each variables
4. Construct the share low birthweight
    * Divide the number of low birthweight births in a county by the number of births with non-missing birthweight data for all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
5. Calculate 95 percent confidence intervals (see detailed process below)

### Process for downloading the data

1. Begin at https://wonder.cdc.gov/
2. Select Births (https://wonder.cdc.gov/natality.html)
3. Select Natality for 2007-2019 
    * The process below can be repeated for other available periods
        * 2003-2006
        * 1995-2002
4. Agree to terms of data use
5. Run queries for county-level metrics in 2018 for all births
    * Select the following options to run query for births with non-missing birth weight information
        * Section 1. Group Results by County
	* Section 4. Year [select 2018]
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
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county.txt"
6. Run queries for county-level metrics in 2018 by race/ethnicity
    * Select the following options to run query for births to non-Hispanic white mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select White]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options except (all weights) and (unknown or not stated)]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "nomiss_bw_by_county_nhwhite.txt"
    * Select the following options to run query for births to non-Hispanic Black mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select Black or African American]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options except (all weights) and (unknown or not stated)]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "nomiss_bw_by_county_nhblack.txt"
    * Select the following options to run query for births to Hispanic mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Hispanic or Latino]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options except (all weights) and (unknown or not stated)]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "nomiss_bw_by_county_hisp.txt"
    * Select the following options to run query for births to mothers with other races or ethnicities
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select American Indian or Alaska Native; Asian; Native Hawaiian or Other Pacific Islander; More than one race] 
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options except (all weights) and (unknown or not stated)]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "nomiss_bw_by_county_nhother.txt"
    * Select the following options to run query for low birth weight births to non-Hispanic white mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select White]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county_nhwhite.txt"
    * Select the following options to run query for low birth weight births to non-Hispanic Black mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select Black or African American]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county_nhblack.txt"
    * Select the following options to run query for low birth weight births to Hispanic mothers
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Hispanic or Latino]
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county_hisp.txt"
    * Select the following options to run query for low birth weight births to mothers with other races or ethnicities
        * Section 1. Group Results by County
	* Section 3. Mother's Hispanic Origin [select Not Hispanic or Latino]
	* Section 3. Mother's Single Race [select American Indian or Alaska Native; Asian; Native Hawaiian or Other Pacific Islander; More than one race] 
	* Section 4. Year [select 2018]
        * Section 4. Infant Birth Weight 12 [select all options <2500 grams]
        * Section 6. Other Options
            * Export Results
            * Show Totals
            * Show Zero Values
            * Show Suppressed Values
        * Click Send
        * Once downloaded, rename file "lbw_births_by_county_nhother.txt"

### Process for calculating 95 percent confidence intervals

Following the guidance provided in the User Guide to the [2010 Natality Public Use File](ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/natality/UserGuide2010.pdf), we use the following process to compute 95 percent confidence intervals for the neonatal health measure.

The neonatal health measure is share low birthweight births in a county. Because this is a percentage, we follow the guidelines for computing 95-percent confidence intervals for percents and proportions.

First, we confirm that the conditions are met:

$Bp ≥ 5$ and $Bq ≥ 5$

Where:

* B = number of all births with non-missing birthweight data in the denominator
* p = percent of low birthweight births divided by 100
* q = 1 – p

If these conditions are met, we compute the confidence intervals using the following formulas:

Lower Limit = $p-1.96 (√((p×q)/B))$

Upper Limit = $p+1.96 (√((p×q)/B))$

Where:

* p = percent of low birthweight births divided by 100
* q = 1 – p
* B = number of all births with non-missing birthweight data in the denominator

These steps are repeated for births to all mothers, non-Hispanic white mothers, non-Hispanic Black mothers, Hispanic mothers, and mothers with other races or ethnicities

---

## Political participation

### Overview

This metric is a county-level estimate of voter turnout. We use Presidential Election turnout as a measure of "Highest Office" for the numerator. We use the Citizen Voting Age Population (CVAP) for the denominator.

* **Analyst & Programmer:** Aaron R. Williams
* **Year(s):** 2016
* **Final data name(s):** `voter-turnout.csv`
* **Data Source(s):** [MIT Election Data and Science Lab](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ), [Citizen Voting Age Population (CVAP) Special Tabulation From the 2012-2016 5-Year American Community Survey (ACS)](https://www.census.gov/programs-surveys/decennial-census/about/voting-rights/cvap.html)
* **Notes:**
* **Data Quality Index:** `1` No issue, `2` Coefficient of Variation >= 0.05, `3` Coefficient of Variation >= 0.15
* **Limitations:** Small counties have very large coefficients of variation for the denominator
* **Missingness:** 31 counties are missing. Alaska is missing. Several other counties are missing. 

### Process

1. Calculate votes in the 2016 Presidential election
2. Calculate the Citizen Voting Age Population
3. Divide 1. by 2. to calculate voter turnout
4. Add data quality flags
5. Save the data  

The .Rmd file for this metric contains detailed steps in notebook for literate statistical programming. 

---

## Economic inclusion

This metric is the share of the poor in a county who live in census tracts with poverty rates over 40%.

### Overview

* **Analyst & Programmer:** Aaron R. Williams
* **Year(s):** 2018
* **Final data name(s):** `poverty-exposure.csv`, `poverty-exposure_race-ethnicity.csv`
* **Data Source(s):** 2014-2018 5-year American Community Survey (via API)
* **Notes:**
* **Data Quality Index:** `1` if the coefficient of variation in race/ethnicity group is less than 0.2. `2` if the coefficient of variation in race/ethnicity group is less than 0.4. `3` otherwise.
* **Limitations:** The margins of error for some tracts and counties are massive. 
* **Missingness:** The metric is only missing if the referenced race/ethnicity group has <=30 observations.

### Process

1. Pull people and poverty rates for Census tracts. 
2. Create the "Other Races and Ethnicities" subgroup. 
3. Count the number of people in poverty who live in Census tracts with poverty > 40% in each county. 
4. Summarize the tract data to the county-level.
5. Divide the number from 2. by the total number of people in poverty in each Census tract. 
6. Split the data into an "All" file and a "Subgroups" file
7. Validation
8. Data quality flags

The .Rmd file for this metric contains detailed steps in notebook for literate statistical programming. 

---

## Racial diversity

This metric measures the exposure of a given race/ethnicity group to other race/ethnicity groups.

### Overview

* **Analyst & Programmer:** Aaron R. Williams
* **Year(s):** 2018
* **Final data name(s):** `race-ethnicity-exposure.csv`
* **Data Source(s):** 2014-2018 5-year American Community Survey (via API)
* **Notes:** 2018
* **Data Quality Index:** `1` if the coefficient of variation in race/ethnicity group is less than 0.2. `2` if the coefficient of variation in race/ethnicity group is less than 0.4. `3` otherwise.
* **Limitations:** The margins of error for some tracts and counties are massive. 
* **Missingness:** The metric is only missing if the referenced race/ethnicity group has <=30 observations.

### Process

1. Pull all non-overlapping race/ethnicity groups needed to create Hispanic, non-Hispanic Black, non-Hispanic white, and Other Races and Ethnicities.
2. Collapse the detailed groups to the four groups of interest. 
3. Calculate the share of a county's racial/ethnic group in each tract.
4. Calculate exposure to other racial/ethnic groups:
    * Calculate Hispanic exposure to other three groups.
    * Calculate non-Hispanic Black exposure to other three groups.
    * Calculate non-Hispanic white exposure to other three groups.
    * Calculate Other Races and Ethnicities exposure to other three groups.
5. Validation 
6. Add data quality flags
7. Save the data

The .Rmd file for this metric contains detailed steps in notebook for literate statistical programming. 

---

## Transportation access

The Low Transportation Cost Index and Transit Trips Index are both calculated "for a 3-person single-parent family with income at 50% of the median income for renters in the region (i.e. CBSA)." They are available in the HUD AFFH data set at the tract level. Both indexes are values on a scale from 0 - 100 and ranked nationally. For transit cost, higher index values means lower cost; for transit trips, higher index values means greater likelihood residents use transit.   

### Overview

* **Analyst & Programmer:** Nicole DuBois
* **Year(s):** 2016 (2012-2016)
* **Final data name(s):** `county_level_transit_indexes.csv`
* **Data Source(s):** HUD AFFH Data (AFFHT0006). Note that the transit cost and transit trips indexes are based on Location Affordability Index data, using National Transit Database data.
* **Notes:**
* **Data Quality Index:**
* **Limitations:**
  1. Both indexes are calculated based on a certain family type. Ideally, we would probably use the number of that type of household to create the population-weighted county average index values. This information is not available so we used the number of families <50% AMI as a proxy.
  2. 149 tracts have 0 of the household type we used for weighting but do have transit index information. Meaning we effectively zero out the values during the county average calculation. 5 of these tracts make up more than 10% of the county population, which could skew the county values. These tracts were flagged with a 2 for data quality.
* **Missingness:** 
  1. Logically, tracts do not have index values if they do not have population.
  2. There are 179 tracts with population but "N/A" index values for both indexes. Typically, these tracts do not represent a significant amount of the population. 6 counties have N/A tracts that make up more than 10% of the county population. These tracts were flagged with a 2 for data quality.

### Process

1. Download the AFFH data from HUD and import into R, saving the variables of interest: the geographic variables, the two transit indexes, and the number of households < 50% AMI.
2. Perform a variety of checks on the data to flag places where data quality might not be the highest. See limitations and missingness descriptions above and the R script for more detail.
3. Generate county-level average index values from the tract-level data. Use the number of households < 50% AMI as the weight.

Additional notes for adding the breakdown by race:

The AFFH data set contains several different race variables - for the total population, for households, and for households at various income brackets. To most closely  align with the transit indexes and the initial population-weighted calculation we did, we chose to use the race variables for households at 50% AMI.

There are several limitations to this choice. There is no 'other' race category, so it is unclear if missing data is due to not fitting into the limited options (white, Black, Hispanic, Asian) or if it is, in fact, missing data.There are 328 tracts with no race data because the number of households at 50% AMI is zero. 20 tracts have 0 values in all race categories. In 223 tracts, we have race information on less than <50% of 50%AMI households. In 342 tracts, we have race information on more than 105% of 50%AMI households (meaning there must be some overlap or data issue). We tried to account for this by taking a similar approach to data quality standards as for the larger data set - noting these issues if a tract makes up a certain percentage of its county.

---

## Environmental quality

### Overview

* **Analyst & Programmer:** Peace Gwam
* **Year(s):** 2014 (2010-2014 ACS)
* **Final data name(s):** `county_enviro_all.csv`, `county_enviro_subgroups.csv`
* **Data Source(s):** Affirmatively Furthering Fair Housing (AFFHT0006) & 2010-2014 ACS. 
* **Notes:**
* **Data Quality Index:** `1` for main environmental index. All counties are represented, and of the tracts with missing `haz_idx`, they represent at most 0.029% of the overall population for the county (see variable `na_perc` for the `All` subgroup type in `county_level_enviro.csv`). There are 147 census tracts with missing poverty information and a population > 0. For the `Poverty` subgroup type, counties with missing hazard or poverty information of more than 5 percent of the county were given a quality flag of `2`. This calculation was done using people in poverty for the `high_poverty` subgroup and people not in poverty for the `low_poverty` subgroup. There was one county  for the `Poverty` subgroup type with a quality flag of `2`. Similarly, for the `Race` subgroup type, counties with missing hazard or race information of more than 5 percent of the county were given a quality flag of `2`, and the indicator used to weight the metric was used to generate the quality flag. There was one county with the `Race` subgroup type that had a quality flag of `2`. 
* **Limitations:** AFFH data are old and are not currently updated under the current administration. Codebooks and access to the data are only available via the Urban Institute data catalog
* **Missingness:** All 3,142 counties in the United States are represented. There are, however, some caveats: 
  1. There are 618 tracts without populations. Logically, most do not have hazard, race and income indices: 508 of the 618 tracts with zero population do not have a `haz_idx`. All tracts with a population = 0 are dropped in the data sets.
  2. There are 22 tracts with populations > 0 with missing `haz_idx`. This represents 0.015% of all observations in the data set. 6 tracts have populations > 100 with missing `haz_idx`. 
  3. There are 147 additional tracts without populations that count for poverty estimates. 10 of the 147 tracts with zero population for the people that are counted for the poverty metric do not have a `haz_idx`. Tracts with a population = 0 for the poverty metric are dropped for the poverty subgroup data set.

### Process

1. Downloaded 2010-2014 5-year ACS tract level total_population, race, and poverty information and cleaned.  
2. Created Indicators for Race and Poverty based on ACS information. For Race, the indicator is valued at "Predominantly People of Color" if the number of people of color was at or more than 60 percent of the total population of the tract, "Predominantly White, Non-Hispanic" if the number of White, Non-Hispanic people were more than 60 percent of the total population, and "No Predominant Racial Group" if neither of the above were true. For the Poverty indicator, tracts were considered "high_poverty" if the poverty rate was at or higher than 40 percent in the tract, and was "low_poverty" otherwise.   
3. Downloaded tract-level 2014 AFFH, cleaned to conform with changing geography, and selected the hazard indicator relevant to this analysis  
4. Merged ACS data with cleaned AFFH data  
5. Checked Missingness  
6. Created county-level metrics  
  * Main metric: The weighted tract-level mean of the hazard index, weighted by total_population, grouped at the county level  
  * Poverty metric: The weighted tract-level mean of the hazard index, weighted by number of people in poverty for "high_poverty" tracts and by number of people not in poverty for "low_poverty tracts", grouped at the county level and whether or not the tract was "high_poverty" or "low_poverty"  
  * Race metric: The weighted tract-level mean of the hazard index, weighted by total population for tracts that have "No Predominant Racial Group", weighted by People of Color for tracts that are "Predominantly People of Color", and weighted by non-Hispanic White people for tracts that are "Predominantly White, Non-Hispanic".    
7. Expanded subgroup data to represent unique values for each subgroup and county  
8. Appended data together, cleaned, and wrote to `.csv`  

---

## Exposure to crime

This national data set of crimes at the county level provides the best possible estimates of crime by county at the national level, but local level data is likely to be more accurate and reliable. There is a lot of variation in definitions and reporting across counties making national data less reliable then local data for this purpose. Additionally, while the incentive of eligibility for federal grant funding exists, reporting of these data is not required and therefore is not available in a national repository for some jurisdictions. Additionally, as these data are missing additional contextual information about jurisdictions, the FBI cautions against using UCR data to rank or compare jurisdictions (https://ucr.fbi.gov/ucr-statistics-their-proper-use)

These metrics use a clean county level crime data set that can be found on ICPSR (https://www.openicpsr.org/openicpsr/project/108164/version/V4/view?path=/openicpsr/108164/fcr:versions/V3). This file was created using agency level data with ORI codes that were crosswalked with county FIPS codes. This file is not complete, but includes a coverage indicator to show how much of a county is covered in the crime counts captured. The coverage indicator is calculated as follows. 

$CI_x = 100 * ( 1 - SUM_i { [ORIPOP_i/COUNTYPOP] * [ (12 - MONTHSREPORTED_i)/12 ] } )$
 		
where 

* CI = Coverage Indicator
* x = county
* i = ORI within county

The file also uses imputation to estimate crime counts for months of missing data by agency. More information on the data set can be found here (https://www.openicpsr.org/openicpsr/project/108164/version/V4/view). 

Unfortunately, the variable `MONTHSREPORTED_i` was believed to be the number of months reported, but is actually the last month reported. For example, if an agency reported data in February and April, the value for MONTHSREPORTED_i for that agency would be 4 even though only 2 months were reported. We still believe there is value in this variable to highlight agencies with very very low coverage indicators and are therefore using the flawed variable to flag counties with low (3) data quality. Any county that is not flagged as low (3) data quality and does not have missing information is marked as medium (2) data quality. There are five counties in New York City that have a data quality measure of high (1) because they were pulled from a different data source. 

The metrics of interest from these data are violent crime (murder and non-negligent manslaughter, forcible rape, robbery, and aggravated assault) and property crime (burglary, larceny-theft, motor vehicle theft, and arson). Rates are calculated as the number of crimes per 100,000 people using ACS county populations.  

$\text{county crime rate} = (\text{county crime count} / \text{county population}) * 100,000$

This file reports crime counts for all of New York City in the New York County observation. For this reason, data from New York State (https://www.criminaljustice.ny.gov/crimnet/ojsa/countycrimestats.htm) was used for the five counties in New York City instead. 

When using county level crime statistics, it is important to keep in mind that they are generally incomplete. The Federal Bureau of Investigations (FBI) Uniform Crime Statistic (UCR) Crime in the United States data series (https://ucr.fbi.gov/crime-in-the-u.s) provides county level crime data that represents all crimes that occurred within the county law enforcement agency's jurisdiction, outside of city jurisdiction. These data are missing crimes that occurred in counties outside of the jurisdiction of the county. This excused any crimes that take place within a county but in the jurisdiction of a city, tribal, university, or other law enforcement agency within the county. These data also exclude any crimes that occurred in the county under the jurisdiction of the state law enforcement agency. Documentation of the FBI UCR county crime data can be found here (https://www.fbi.gov/file-repository/ucr/ucr-srs-user-manual-v1.pdf/view). For this reason we have chosen to use an already cleaned county crime file created using agency level data. 

### Overview

* **Analyst & Programmer:** Lily Robin
* **Year(s):** 2017 and 2015
* **Final data name(s):** `crimerate_county_2017.csv` and `crimerate_county_2015.csv`
* **Data Source(s):**
  * `county_crosswalk.csv`: county FIPS and county populations
	* `county_ucr_offenses_known_yearly_1960_2017.dta`: county crime counts for 1960 to 2017 (https://www.openicpsr.org/openicpsr/project/108164/version/V3/view)
	* `ny_county_indexcrime_2017.xls`: new york state index crimes by county (https://www.criminaljustice.ny.gov/crimnet/ojsa/countycrimestats.htm)
* **Notes:** This data set is not inclusive of all counties and many counties are missing data from agencies that reside within that county. 
* **Data Quality Index:** Counties with less then 80% coverage are marked as a 3, all other counties are marked as a 2 unless there are missing values (with the exception of the five New York City counties). 
	* 2017 data set, about 83% of counties have a data quality index of 2 and about 17% have a data quality measure of 3. Less then 1% (5) counties have a data quality measure of 1.
	* 2015 data set, about 85% of counties have a data quality index of 2 and about 15% have a data quality measure of 3. Less then 1% (5) counties have a data quality measure of 1. 
Data for the five counties that reside in NYC was pulled from NYS data. These data are likely very accurate, and have been given a quality index measure of 1, but they do not come from the same data set as the rest of the counties. 
* **Limitations:** Some agencies change reporting practices year to year. Therefore, year to year comparisons should be used with caution and a knowledge of agency reporting practices (UCR data from the web has footnotes that I can merge in, but this data does not). Imputation was used to estimate crime rates in unreported months, using the NACJD method. The coverage indicator provides an estimate of the amount of the population coverage by reporting agencies. The data quality index is used to assess the quality of data for each county using the coverage indicator variable. See notes about the flaws in this calculation above. 
* **Missingness:** 2017 data set: about 0.22% (7) of counties are missing all crime data. 2015 data set: about 0.22% (7) of counties are missing all crime data.

### Process

1. Change the file directory
2. Import and clean all files
3. Merge crime counts to counties
4. Clean merged data and generate rate3
5. Finalize and export data

---

## Overly punitive policing

This national data set of juvenile arrests at the county level provides the best possible estimates of juvenile arrests by county at the national level, but local level data is likely to be more accurate and reliable. There is a lot of variation in definitions and reporting across counties making national data less reliable then local data for this purpose. Additional, while the incentive of eligibility for federal grant funding exists, reporting of these data is not required and therefore is not available in a national repository for some jurisdictions. Additionally, as these data are missing additional contextual information about jurisdictions, the FBI cautions against using UCR data to rank or compare jurisdictions (https://ucr.fbi.gov/ucr-statistics-their-proper-use)

This data set contains arrest rates of children age 10 to 17 by county in 2016 using counts of arrests provided by Federal Bureau of Investigations (FBI) Uniform Crime Reporting program (UCR) data and population data for all children age 10 to 17 from the ACS 2016 1-year extract from IPUMS. This age bracket was chosen because the majority of states have an age of adult criminal liability of 18 and at least one state has a minimum age of criminal liability of 12, and arrests of very young children are unlikely. The UCR data is split by children age 0-9, 10 - 12, 13 - 14, and then by individual year. Starting at age 10 was a natural split in the data and anything older then 17 is considered adult in all states. 

Each instance of an arrest, citation, or summons for an offense is counted as an arrest. A detailed definition provided by the FBI can be found here: https://ucr.fbi.gov/crime-in-the-u.s/2016/crime-in-the-u.s.-2016/topic-pages/persons-arrested). Note that an individual can be arrested more then once and therefore, rates provided are of arrests not persons arrests. Offenses considered in these data include crimes (ex. aggravated assault and rape) and status offenses that are considered offenses due to the age of an individual  (ex. misrepresenting age to purchase alcohol, curfew violations, and runaway cases). More information on the offenses included can be found in the codebook for the FBI UCR arrest data found here: https://www.icpsr.umich.edu/web/ICPSR/studies/37056. 

Additionally, the data is split by race for juvenile arrest and includes Asian, Black, Indian, and White. We have used this information to make a data set of juvenile arrests by race in addition to the overall juvenile arrests file. Unlike the overall file, this file includes all juveniles as defined by the state each agency is in, but the denominator is still including children age 10 - 17, as there are not many arrests of children under 10. It is important to note that race is not necessarily defined consistently in the file with arrest counts as it is in the ACS file used for the denominator or the overall population (ex. self-report versus officer reported). 

Due to variation found in these data compared to national averages (https://www.ojjdp.gov/ojstatbb/crime/ucr.asp?table_in=1&selYrs=2016&rdoGroups=1&rdoData=r), we chose to suppress data we felt was unreliable. These data include all observations with an overall population (denominator) of less then 30 people and all observations with an arrest rate of over 150,000 arrests per 100,000, 1.5 times the arrests as the number of people. 

This file reports juvenile arrest counts for all of New York City in the New York County observation. For this reason, data from New York State (https://www.criminaljustice.ny.gov/crimnet/ojsa/jj-profiles.htm) was used for the five counties in New York City instead. These counts in New York City counties are for people age 7 to 15 and the denominator for New York counties has been adjusted to reflect this population of people age 7-15 in each New York City county. Data by race by county in New York City is not available. 

A codebook with definitions for the original arrest data used can be found here: https://www.icpsr.umich.edu/web/ICPSR/studies/37056. 

### Overview

* **Analyst & Programmer:** Lily Robin
* **Year(s):** 2016
* **Final data name(s):** `2016_juvenile_arrest_by_county.csv` and `2016_juvenile_arrest_by_county_race.csv`
* **Data Source(s):**
  * `2016_arrest.dta`: arrests by agency in 2016 (https://www.icpsr.umich.edu/web/ICPSR/studies/37056)
	* `children_10_17.csv`: population of children age 10 to 17 by county in 2016 (created by Kevin Werner)
	* `children_10_17_race.csv`: population of children age 10 to 17 by race by county in 2016 (created by Kevin Werner)
	* `fbi_crosswalk.dta`: county FIPS to agency Originating Reporting Agency Identifier (ORI) crosswalk (https://www.icpsr.umich.edu/web/ICPSR/series/366)
	* `county_crosswalk.csv`: county FIPS and county populations (provided by Kevin)
	* nyc county juvenile arrests: https://www.criminaljustice.ny.gov/crimnet/ojsa/jj-profiles.htm
* **Notes:**
* **Data Quality Index:**
  * The coverage indicator is calculated using an indicator of whether data was reported for each month and offense for an agency in 2016. The coverage indicator is calculated as: 1 - (observations with non reported data for a county / total observations for a county). Where each observation is a arrests reported by an agency for a month for a specific offense category. There are also agencies that have overlapping jurisdictions. In this scenario, arrests should be attributed to only one of the agencies in the jurisdictional area per FBI data standards. If a jurisdiction is indicated as being covered by another jurisdiction, it is not included in the count of non-reporting agencies in a county. This is the best available estimate of how many arrests within a county are actually covered by the statistic provided in the final data set for a county, but it is not complete. There are 215 agencies in the file that cannot be matched to a county. Additionally population of each county versus the population for missing data is not accounted for. 
  * Counties with 100% coverage are marked as a 1, counties with between 100 and 80% coverage are marked as a 2, and counties with less then 80% coverage are marked as a 3. 
	  * overall file: 34% of counties have a data quality index of 1, 64% have a data quality measure of 2, and 2.5% have a data quality measure of 3. 
	  * file by race: 31% of counties have a data quality index of 1, 65% have a data quality measure of 2, and 3% have a data quality measure of 3. 
* **Limitations:** Children age 10 - 17 is the best match of numerator and denominator across states, but not necessarily reflective of definitions of juvenile by state. Variables are included to identify states that have adult criminal liability ages below 18 and for the number of arrests of children under 10 by county. The data does not distinguish between no arrests in an age category and a non-report on the category so some 0s may actually be non-reports. The data quality index is used to assess the quality of data for each county using the coverage indicator.
* **Missingness:** overall file: 493 counties (16%) are missing arrest data. file by race: 4064 counties about (43%) are missing arrest data by race. 

### Process

1. change the file directory listed after the "cd" command on line 8 and copy all source files to the file directory location you chose. Files can be found in the Box folder: Box Sync\Metrics Database\Safety\juvenile_arrest
2. import all files
3. crosswalk county FIPS (`fbi_crosswalk.dta`) to the 2016 agency arrests file (2016_arrest) matching on ORI number
4. check 2016 agency arrests file (`2016_arrest`) for missing values and create non-reporting variable to account for non-reporting agencies in a county
5. Calculate total juvenile arrests per agency
6. Aggregate to County
7. Identify states with age of adult criminal liability below 18
8. crosswalk arrest file (`2016_arrest`) to county population file (`children_10_17.csv`)
9. crosswalk arrest file (`2016_arrest`) to county FIPS file (`county_crosswalk.csv`) with all counties to add in counties with missing data
10. Finalize and export data

---

## Access to preschool

### Overview

* **Analyst & Programmer:** Kevin Werner
* **Year(s):** 2018
* **Final data name(s):** `metrics_preschool.csv`
* **Data Source(s):** ACS 1-yr and ACS 5-yr for subgroup analysis. 
* **Notes:** This metric uses Paul Johnson's method of finding county FIPS code from PUMAs. PUMAs can sometimes span counties, which is adjusted for with weights.
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** Hawaii county 05 is missing. It is very low population.

### Process

Data was downloaded from IPUMS. Then cleaned in the main program. Then I created county FIPS using Paul's method. Then, I calculated the number of 3 and 4 year olds, the number of children in pre school, and divided them. 

The process for creating the subgroup metric is the same as the process for creating the original metric.

---

## Effective public education

This metric reflects the average annual learning growth in English/language arts (ELA) among public school students between third  grade and eighth grade. For the 2015 cohort (students who were in eighth  grade in the 2015-16 school year), this measure is the slope of the best fit line of the 2009-10 third grade assessment, the 2010-11 fourth grade assessment, etc. Assessments normed so that a typical third grade assessment would score 3, a typical fourth grade assessment would score 4, etc. Thus, typical learning growth is roughly 1 grade level per year. 1 indicates a county is learning at an average rate; below 1 is slower than average, and above 1 is faster than average. Assessments are  state- and year-specific, but the Stanford Education Data Archive (SEDA) has normed  these to be comparable over time and space.

### Overview

* **Analyst & Programmer:** Erica Blom
* **Year(s):** 2015 (2015-16 school year), 2014, and 2013
* **Final data name(s):** `SEDA.csv`
* **Data Source(s):** 
  * https://cepa.stanford.edu/content/seda-data
	* https://edopportunity.org/get-the-data/seda-archive-downloads/ 
	* exact file: https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_v30.dta
	* Reardon, S. F., Ho, A. D., Shear, B. R., Fahle, E. M., Kalogrides, D., Jang, H., Chavez, B., Buontempo, J., & DiSalvo, R. (2019). Stanford Education Data Archive (Version 3.0). http://purl.stanford.edu/db586ns4974.
* Subgroups: all; gender; race/ethnicity; income
* **Notes:**
* **Data Quality Index:** Data quality of "1" requires at least 5 or 6 years of data to be included, with at least 30 students tested in each year (a commonly used minimum  sample size for stability of estimates). Data quality of "2" requires at least 4 years  included with at least 30 students in each year. Data quality of "3" is assigned to the  remainder. These quality flags are determined separately for each subgroup, such that the quality flag for one subgroup in a county may differ from that of another subgroup.
* **Limitations:** Not all counties report assessments for all grades, so some estimates may be based on fewer than 6 data points; underlying data have been manipulated by SEDA to introduce noise to ensure confidentiality; migration into or out of a county may result in the "cohort" not being exactly the same between third and eighth grades.
* **Missingness:** missing observations by year and subgroup:

|                      subgroup | 2013 | 2014 | 2015|
|-------------------------------|-----:|-----:|----:|
|                           All |   80 |   87 |   80|
|           Black, Non-Hispanic | 1796 | 1825 | 1839|
|    Economically Disadvantaged |  199 |  211 |  205|
|                        Female |  216 |  216 |  223|
|                      Hispanic | 1778 | 1735 | 1717|
|                          Male |  199 |  209 |  205|
|Not Economically Disadvantaged |  308 |  324 |  333|
|           White, Non-Hispanic |  202 |  210 |  215|

### Process

SEDA data are manually downloaded and read in, and a regression of mean assessment scores was run on grade (as a continuous variable) interacted with each county in order to obtain county-specific grade slopes. Regressions are weighted by the number of test-takers for each year, grade, and county. 95% confidence intervals are calculated as the slope estimate plus or minus 1.96 times the standard error of the estimate. A flag indicates how many grades are included in each estimate.  

---

## Student poverty concentration

This metric reflects the fraction of students in each county who attend
schools where 40 percent or more of students receive free or reduced-price lunch (FRPL). 

### Overview

* **Analyst & Programmer:** Erica Blom
* **Year(s):** 2018 (2018-19 school year)
* **Final data name(s):** `FRPL.csv`
* **Data Source(s):** Common Core of Data via Education Data Portal
* **Notes:**
* **Data Quality Index:** Data quality of "1" requires at least 30 students in the county and for the poverty_measure_used to be either "FRPL" or "DC", but not "Both". Data quality of "2" requires at least 15 students in the county and a poverty_measure_used flag of "FRPL" or "DC". The remainder receive a data quality flag of "3".
* **Limitations:** Not all states report FRPL; some instead report the number of students directly certified (DC). FRPL is "The unduplicated number of students who are eligible  to participate in the Free Lunch and Reduced Price Lunch Programs under the National  School Lunch Act of 1946." DC is "The unduplicated count of students in membership  whose National School Lunch Program (NSLP) eligibility has been determined through  direct certification." (https://www2.ed.gov/about/inits/ed/edfacts/eden/non-xml/fs033-14-1.docx) In 2018, the states reporting DC instead of FRPL are Massachusetts, Tennessee, Delaware,  and the District of Columbia. In addition, Alaska and Ohio report either FRPL or DC  for a substantial number of schools in 2018. 
* **Missingness:** 4/3,142 counties

### Process

Outline the process for creating the data: Schools were flagged as having 40% or more FRPL if either the number of students receiving FRPL or the number of DC students was greater than 40%. Each county is assigned a flag (poverty_measure_used) that indicates whether all schools have a higher number of students reported under "FRPL" or "DC"; if there is a mix, the county is assigned "Both". Total enrollment (by race) was summed in these schools and divided by total  enrollment (by race) in the county. 

---

## College readiness

### Overview

* **Analyst & Programmer:** Kevin Werner and Paul Johnson
* **Year(s):** 2018
* **Final data name(s):** `metrics_college.csv`
* **Data Source(s):** ACS 1-yr and ACS 5-yr for subgroup analysis. 
* **Notes:**
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** 

### Process

The compute_ code computes the metrics. The finalize_ code computes the confidence intervals and outputs the .csv. NOTE: must run the `1_`, `2_`, and `3_` code in the income subfolder first.  For subgroup analysis, you must run the program `3_prepare_microdata_5_year`.

Data was downloaded from IPUMS. Then cleaned with the IPUMS .sas program. Then I created county FIPS using Paul's method. Then, we calculated the number of 19-20 year olds,  the number with a high school degree and divided them. 
The process for creating the subgroup metric is the same as the process for creating the
original metric. 

---

## Employment

### Overview

* **Analyst & Programmer:** Kevin Werner and Paul Johnson
* **Year(s):** 2018
* **Final data name(s):** `metrics_employment.csv`
* **Data Source(s):** ACS 1-yr and ACS 5-yr for subgroup analysis.
* **Notes:**
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** County 05 in HI is missing

### Process

NOTE: must run the `1_`, `2_`, and `3_` code in the income subfolder first.
	
The data are downloaded from IPUMS and cleaned with the `1_`, `2_`, and `3_` code. That code also adds the the county FIPS. The `compute_` code finds the employment rate of 25-54 year olds. The finalize_ code calculates the confidence intervals and outputs the csv.  

The process for the subgroup analysis is the same. You must run the file `3_prepare_microdata_5_year`.

---

## Access to jobs paying a living wage

### Overview

* **Analyst & Programmer:** Kevin Werner and Aaron Williams
* **Year(s):** 2018 and 2014
* **Final data name(s):** `metrics_wage_ratio.csv`
* **Data Source(s):** QCEW and MIT Living Wage Calculator 
* **Notes:**
* **Data Quality Index:**
* **Limitations:**
* **Missingness:** County 05 in HI is missing. County 3 in State 19 (Iowa) is missing average wage data, so it shows up as a 0 in the ratio.

### Process

This data comes from two sources. The average weekly wage comes from the QCEW: https://www.bls.gov/cew/downloadable-data-files.htm The row where the ownership variable equals "Total Covered" is used for each county. The living wage data is scraped from the MIT website using the scrape-living-wages R program. There are three .csvs: 2014 QCEW data, 2018 QCEW data, and the MIT living wage data Those .csvs are merged into one Stata file; the MIT wage is converted into weekly. For 2018, the ratio is just the 2018 QCEW data divided by the MIT data. For 2014, I first deflate the MIT data (because it is only available for 2018) to 2014, and then divide the QCEW by the  deflated value. 

The living wage is a FULL TIME worker wage, while the average weekly wage includes part time workers.

We use the living wage level for one adult and two children. 
