# Environmental Quality Index
* Final data name(s): county_level_enviro.csv
* Analyst(s): Peace Gwam
* Data source(s): Affirmatively Furthering Fair Housing (AFFHT0006) & ACS. 
* Year(s): 2014
* Notes:
    * Limitations : AFFH data are old and are not currently updated under the current administration. Codebooks and access to the data are only available via the Urban Institute data catalog
    * Missingness : All 3,142 counties in the United States are represented. There are, however, some caveats: 
      (1) There are 618 tracts without populations. Logically, most do not have hazard indices: 508 of the 618 tracts with zero population do not have a `haz_idx`.
      (2) There are 22 tracts with populations > 0 with missing `haz_idx`. This represents 0.015% of all observations in the data set. 6 tracts have populations > 100 with missing `haz_idx`. 
    * Quality flags: `1` for all observations. All counties are represented, and of the tracts with missing `haz_idx`, they represent at most 0.02% of the overall population for the county (see variable `na_pop` in dataset). 

Outline the process for creating the data  
* Downloaded tract-level 2014 AFFH data
* Cleaned AFFH data, including the removal of variables and geographies not relevant to this analysis
* Merged tract-level total population from the 2014 5-yr ACS for the United States with cleaned AFFH data
* Validation 
* Weighted air quality indicators by county level population
* Add data quality flags
* Output data
