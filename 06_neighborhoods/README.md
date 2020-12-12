# Environmental Quality Index

* Final data name(s): county_level_enviro.csv, county_level_enviro_race.csv, county_level_enviro_poverty.csv
* Analyst(s): Peace Gwam
* Data source(s): Affirmatively Furthering Fair Housing (AFFHT0006) & ACS. 
* Year(s): 2014
* Notes:
    * Limitations : AFFH data are old and are not currently updated under the current administration. Codebooks and access to the data are only available via the Urban Institute data catalog
    * Missingness : All 3,142 counties in the United States are represented. There are, however, some caveats: 
      (1) There are 618 tracts without populations. Logically, most do not have hazard indices: 508 of the 618 tracts with zero population do not have a `haz_idx`.
      (2) There are 22 tracts with populations > 0 with missing `haz_idx`. This represents 0.015% of all observations in the data set. 6 tracts have populations > 100 with missing `haz_idx`. 
      (3) There are 163 census tracts with a population > 0 & missing poverty information in the AFFH data. ACS data could only fill 6/163 census tracts. The ACS was not used to calculate the poverty rate for the 6 tracts. 
    * Quality flags: `1` for all observations. All counties are represented, and of the tracts with missing `haz_idx`, they represent at most 0.02% of the overall population for the county (see variable `na_pop` in county_level_enviro dataset). For tracts with missing `poverty_type`, they represent at most 0.01% of the overall population

Outline the process for creating the data  
* Downloaded tract-level 2014 AFFH data
* Cleaned AFFH data, including the removal of variables and geographies not relevant to this analysis
* Merged tract-level total population from the 2014 5-yr ACS for the United States with cleaned AFFH data
* Validation 
* Weighted air quality indicators by county level population, race, and income level/poverty rate. 

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
      (2) There are 179 tracts with population but "N/A" index values for both indexes. Typically, these tracts do not represent a significant amount of the population. 6 counties have N/A tracts that make up more than 10% of the county population. These tracts were flagged with a 2 for data quality.

Outline the process for creating the data 
(1) Download the AFFH data from HUD and import into R, saving the variables of interest: the geographic variables, the two transit indexes, and the number of households < 50% AMI.
(2) Perform a variety of checks on the data to flag places where data quality might not be the highest. See limitations and missingness descriptions above and the R script for more detail.
(3) Generate county-level average index values from the tract-level data. Use the number of households < 50% AMI as the weights.

# Race/Ethnicity Exposure

This metric measures the exposure of a given race/ethnicity group to other race/ethnicity groups.

* Final data name(s): race-ethnicity-exposure.csv
* Analyst(s): Aaron R. Williams
* Data source(s): 2014-2018 5-year American Community Survey
* Year(s): 2018
* Notes:
    * Limitations: None
    * Missingness: The metric is only missing if the referenced race/ethnicity group has zero observations.
    * Quality flags: `1` if > 5 in race/ethnicity group. `3` otherwise.

1. Pull all non-overlapping race/ethnicity groups needed to create non-Hispanic white, non-Hispanic Black, and Hispanic.
2. Collapse the detailed groups to the three groups of interest. 
3. Calculate the share of a county's racial/ethnic group in each tract.
4. Calculate exposure to other racial/ethnic groups:
    * Calculate non-Hispanic white exposure to non-Hispanic Black and Hispanic.
    * Calculate non-Hispanic Black exposure to non-Hispanic white and Hispanic.
    * Calculate Hispanic exposure to non-Hispanic white and non-Hispanic Black.
5. Validation 
6. Add data quality flags
7. Save the data

# Poverty Exposure

This metric is the share of the poor in a county who live in census tracts with poverty rates over 40%.

* Final data name(s): poverty-exposure.csv
* Analyst(s): Aaron R. Williams
* Data source(s): 2014-2018 5-year American Community Survey
* Year(s): 2018
* Notes:
    * Limitations
    * Missingness: Rio Arriba County, NM is missing because of a data collection issue. 
    * Quality flags: * `1` - nothing, `2` - missing observations, `3` - > 5% missing observations

1. Pull people and poverty rates for Census tracts. 
2. Count the number of people in poverty who live in Census tracts with poverty > 40% in each county. 
3. Count the number of people in poverty who live in each county. 
4. Join and test the summarized tract data and the county data.
5. Divide the number from 2. by the total number of people in poverty in each Census tract. 
6. Validation
7. Data quality flags
