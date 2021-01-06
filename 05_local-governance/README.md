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

ASSUMPTIONS

`middle_eastern_or_north_african` from ICMA counts as `asian_other` from the Census

## Voter Turnout

This metric is a county-level estimate of voter turnout. We use Presidential Election turnout as a measure of "Highest Office" for the numerator. We use the Citizen Voting Age Population (CVAP) for the denominator. 

* Final data name(s): voter-turnout.csv
* Analyst(s): Aaron R. Williams
* Data source(s): MIT Election Data and Science Lab, Citizen Voting Age Population (CVAP) Special Tabulation From the 2012-2016 5-Year American Community Survey (ACS)
* Year(s): 2016
* Notes:
    * Limitations: Small counties have very large coefficients of variation for the denominator
    * Missingness: 31 counties are missing. Alaska is missing. Several other counties are missing. 
    * Quality flags: `1` No issue, `2` CV >= 0.05, `3` CV >= 0.15

1. Calculate votes in the 2016 Presidential election
2. Calculate the Citizen Voting Age Population
3. Divide 1. by 2. to calculate voter turnout
4. Add data quality flags
5. Save the data  
