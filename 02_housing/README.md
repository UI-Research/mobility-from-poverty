# Homelessness

Brief description: This metric is the total number of students experiencing homelessness at some
point during the school year.

* Final data name(s): Homelessness
* Analyst(s): Erica Blom
* Data source(s): EDFacts homelessness data; Common Core of Data (CCD) to identify counties.
* Year(s): 2018 (2018-19 school year)
* Notes:
    * Limitations: Data suppression
    * Missingness: 286/3,142 counties

Outline the process for creating the data: Counts of students experiencing homelessness are downloaded from the EDFacts website.
Supressed data are replaced with 1 for the main estimate and 0 for the lower bound. For the upper
bound, suppressed data are replaced with the smallest non-suppressed value by state and subgrant
status if there are two or fewer suppressed values by state and subgrant status, per the documentation,
and 2 otherwise. Districts are assigned to the county where the district office is located (obtained
from the CCD data). Shares are calculated by dividing by total enrollment in the county (again based on)
the location of the district office, with enrollment counts also from CCD data). A flag indicates the
number of districts with suppressed data that are included in each county's estimate.

Data quality flag: Data quality of "1" requires the ratio of the upper bound (homeless_count_ub) to the
lower bound (homeless_count_lb) to be less or equal to than 1.05. Data quality of "2" requires this ratio
to be less than or equal to 1.1. Data quality of 3 is the remainder.
