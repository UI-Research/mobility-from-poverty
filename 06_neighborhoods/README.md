# Race/Ethnicity Exposure

Brief description

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

Brief description

* Final data name(s):
* Analyst(s): Aaron R. Williams
* Data source(s):
* Year(s):
* Notes:
    * Limitations
    * Missingness

Outline the process for creating the data including assumptions and methodology  
