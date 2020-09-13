# Metric template

Brief description

* Final data name(s): county_level_enviro.csv
* Analyst(s): Peace Gwam
* Data source(s): Affirmatively Furthering Fair Housing (AFFH) & ACS
* Year(s): 2014
* Notes:
    * Limitations : AFFH data are old and are not currently updated under the current administration. Codebooks and access to the data are only available via the Urban Institute data catalog
    * Missingness : All 3,142 counties in the United States are represented.

Outline the process for creating the data  
* Downloaded tract-level 2014 AFFH data
* Cleaned AFFH data, inclduing the removal of variables and geographies not relevant to this analysis
* Merged tract-level total population from the 2014 5-yr ACS for the United States with cleaned AFFH data
* Validated data: checked if merge worked using `<anti-join>` and `<stopifnot>`
* Weighted air quality indicators by county level population

<Repeat above information for additional metrics>
