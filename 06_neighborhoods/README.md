# Metric template

Brief description

* Final data name(s): county_level_enviro.csv
* Analyst(s): Peace Gwam
* Data source(s): Affirmatively Furthering Fair Housing (AFFH) & ACS
* Year(s): 2014
* Notes:
    * Limitations : AFFH data are old and are not currently updated under the current administration. Codebooks and access to the data are no longer available online. 
    * Missingness : Missing observations for all territories except for Puerto Rico. More than 98% of tracts with population are represented. This is documented in the code.

Outline the process for creating the data  
* Downloaded AFFH data and kept relevant variables on air quality
* Merged in total population from the 5-yr ACS for the United States, including DC and Puerto Rico
* Validated data: checked if merge worked using `<anti-join>` and `<stopifnot>`
* Dropped all tracts with a population of zero and all tracts without hazard indicies 
* Weighed air quality indicators by county level population

<Repeat above information for additional metrics>
