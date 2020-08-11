# Local Governance

## Descriptive Representation

This metric compares the racial and ethnic characteristics of municipal 
councils with the racial and ethnic composition of the municipality.

* Final data name(s): descriptive-representation.csv
* Analyst(s): Aaron R. Williams
* Data source(s): ICMA Municipal Form of Government 2018 Survey, 2014-2018 5-year ACS
* Year(s): 2018
* Notes:
    * Limitations: The municipal data is more useful than the county data.
    * Missingness: The ICMA survey only reaches a subset of all municipalities. 
    Some counties have no observations and some counties are missing many 
    municipalities. 
    * Quality flags: `1` if > 80% of population is captured. `2` if > 50% of the population is captured. `3` otherwise.
    
Steps:

1. Get shares of 4 race/ethnicity groups at the council level from the ICMA survey
2. Pull demographics for Census places and Census County Subdivisions
3. Join the Census data to the ICMA data
4. Calculate the metrics
5. Aggregate to the county level
6. Identify issues
7. Create quality flags
8. Save the data

## Voter Turnout




Brief description

* Final data name(s):
* Analyst(s): Aaron R. Williams
* Data source(s):
* Year(s):
* Notes:
    * Limitations:
    * Missingness:

Outline the process for creating the data    


