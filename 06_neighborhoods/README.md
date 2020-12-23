# Transit Cost and Transit Trips Index

The Low Transportation Cost Index and Transit Trips Index are both calculated "for a 3-person single-parent family with income at 50% of the median income for renters in the region (ie CBSA)." They are available in the HUD AFFH dataset at the tract level. Both indexes are values on a scale from 0 - 100 and ranked nationally. For transit cost, higher index values means lower cost; for transit trips, higher index values means greater likelihood residents use transit.   

* Final data name(s): county_level_transit_indexes.csv
* Analyst(s): Nicole DuBois
* Data source(s): HUD AFFH Data (AFFHT0006). Note that the transit cost and transit trips indexes are based on Location Affordability Index data, using National Transit Database data.
* Year(s): 2016 (2012-2016)
* Notes:
    * Limitations: 
      (1) Both indexes are calculated based on a certain family type. Ideally, we would probably use the number of that type of household to create the population-weighted county average index values. This information is not available so we used the number of families <50% AMI as a proxy.
      (2) 149 tracts have 0 of the household type we used for weighting but do have transit index information. Meaning we effectively zero out the values during the county average calculation. 5 of these tracts make up more than 10% of the county population, which could skew the county values. These tracts were flagged with a 2 for data quality.
      
    * Missingness: 
      (1) Logically, tracts do not have index values if they do not have population.
      (2) There are 179 tracts with population but "N/A" index values for both indexes. Typically, these tracts do not represent a signiticant amount of the population. 6 counties have N/A tracts that make up more than 10% of the county population. These tracts were flagged with a 2 for data quality.

Outline the process for creating the data 
(1) Download the AFFH data from HUD and import into R, saving the variables of interest: the geographic variables, the two transit indexes, and the number of households < 50% AMI.
(2) Perform a variety of checks on the data to flag places where data quality might not be the highest. See limitations and missingness descriptions above and the R script for more detail.
(3) Generate county-level average index values from the tract-level data. Use the number of households < 50% AMI as the weight.

Additional notes for adding the breakdown by race:
The AFFH dataset contains several different race variables - for the total population,
for households, and for households at various income brackets. To most closely 
align with the transit indexes and the initial population-weighted calculation we
did, we chose to use the race variables for households at 50% AMI.

There are several limitations to this choice. There is no 'other' race category, 
so it is unclear if missing data is due to not fitting into the limited options 
(white, Black, Hispanic, Asian) or if it is, in fact, missing data.
There are 328 tracts with no race data because the number of households at 50% AMI is zero. 
20 tracts have 0 values in all race categories.
In 223 tracts, we have race information on less than <50% of 50%AMI households. 
In 342 tracts, we have race information on more than 105% of 50%AMI households 
(meaning there must be some overlap or data issue). We tried to account for this
by taking a similar approach to data quality standards as for the larger dataset - 
noting these issues if a tract makes up a certain percentage of its county.


# Environmental Quality

Brief description

* Final data name(s):
* Analyst(s): 
* Data source(s): 
* Year(s):
* Notes:
    * Limitations
    * Missingness

Outline the process for creating the data  
