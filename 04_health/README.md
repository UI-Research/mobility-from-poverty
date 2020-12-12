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
	* County-level data for some racial/ethnic groups are suppressed when the figure represents fewer than 10 persons 
	* lbw_quality is a quality flag for the low birthweight metric
        * A score of 1 indicates a high-quality calculated metric for the observation
		* All counties with populations of 100,000 persons or more for which the metric is county-specific and not suppressed have a quality score of 1
	* A score of 2 indicates limited issues for the calculated metric for the observation
		* No counties have a quality score of 2
	* A score of 3 indicates serious issues for the calculated metric for the observation
		* All counties with populationess under 100,000 for which the metric reflects the pooled share low birthweight for all "Unidentified Counties" in the state and are not county-specific have a quality score of 3
 		* All counties with suppressed estimates have a quality score of 3


## Process for creating the data

1. Download data from CDC WONDER (see detailed process below)
    * County-level counts of:
	* Births among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
	* Births with nonmissing birthweight data among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
	* Low birthweight births among all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
2. Merge CDC WONDER data with crosswalk to create county-level file
3. Assign counties missing from CDC WONDER data the values for their state's "Unidentified Counties" in CDC WONDER data for each variables
4. Construct the share low birthweight
    * Divide the number of low birthweight births in a county by the number of births with nonmissing birthweight data for all women, non-Hispanic white women, non-Hispanic Black women, and Hispanic women
5. Calculate 95 percent confidence intervals (see detailed process below)

## Limitations
* County-level data are not available for counties with fewer than 100,000 residents based on the 2010 Census. Instead, these counties are assigned the share of low birthweight births among all births for *all unidentified counties combined*
* County-level data for some racial/ethnic groups are *suppressed* when the figure represents fewer than 10 persons 

## Process for downloading the data
1. Begin at https://wonder.cdc.gov/
2. Select Births (https://wonder.cdc.gov/natality.html)
3. Select Natality for 2007-2019 
    * The process below can be repeated for other available periods
        * 2003-2006
        * 1995-2002
4. Agree to terms of data use
5. Run queries for county-level metrics in 2018 for all births
    * Select the following options to run query for births with nonmissing birth weight information
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
    * Select the following options to run query for low birth weight births to non-Hispanic whitemothers
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

These steps are repeated for births to all mothers, non-Hispanic white mothers, non-Hispanic Black mothers, Hispanic mothers, and mothers with other races or ethnicities