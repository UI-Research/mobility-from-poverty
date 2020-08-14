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
