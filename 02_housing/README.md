# Metric template

Brief description: This metric is the total number of students experiencing homelessness at some
point during the school year.

* Final data name(s): Homelessness
* Analyst(s): Erica Blom
* Data source(s): EDFacts homelessness data; Common Core of Data (CCD) to identify counties.
* Year(s): 2018 (2018-19 school year)
* Notes:
    * Limitations: Data suppression
    * Missingness: 264/3,142 counties

Outline the process for creating the data: Homelessness data are downloaded from the EDFacts website.
Supressed data are replaced with 1 for the main estimate and 0 for the lower bound. For the upper
bound, suppressed data are replaced with the smallest non-suppressed value by state and subgrant
status if there are two or fewer suppressed values by state and subgrant status, per the documentation,
and 2 otherwise. Using the school-level CCD data, I create a school district-county crosswalk by
calculating the share of each district's enrollment that belongs to a certain county. Not all districts
are captured by this crosswalk; for the remaining districts, I simply assign them to the county
where the district office is located. I use these shares to assign students experiencing homelessness
proportionally to each county. 

<Repeat above information for additional metrics>
