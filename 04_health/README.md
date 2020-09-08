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
    * lbw_flag indicates "Unidentified Counties" and data for these counties reflect the pooled share low birthweight for all counties in the state with populations under 100,000 and are not county-specific

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

