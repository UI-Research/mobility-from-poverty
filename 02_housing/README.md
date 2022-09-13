# Housing afforability

* Final data name(s): metrics_housing
* Analyst(s): Paul Johnson and Kevin Werner
* Data source(s): ACS 1-year
* Year(s): 2018
* Notes:
		Metrics are missing for county 05 in Hawaii.
		
		Counties 89 and 119 in state 36 (NY) had some missing data and may not be reliable. 

From Paul:
First of all, it requires extra data --- Section-8 FMR area income levels, and the population 
of each FMR area.  This info is imported at the beginning of the program (I’m not sure where this 
data was obtained, but I think it came from HUD’s website), and then combined and made ready for 
merging with the microdata file.  Once it is merged we can determine which households have 
incomes under 80% and under 40% of the AMI, and which live in “affordable” housing.   Note that, 
regardless of the household size, the AMI for a family of 4 is always used. After this, we also
need to account for the affordability of vacant units.  This uses a file (“vacant”) produced by 
the program “prepare_vacant macro”.  The final metrics are a combination of the results from 
the microdata file and the results from the vacant file.   

# Homelessness

Brief description: This metric is the total number and share of students experiencing homelessness at some
point during the school year.from 2014-15 through 2019-20. The total number and the share of students
 experiencing homelessness by race/ethnicity is available beginning in 2019-20. Race/ethnicity includes Black, 
Hispanic, White, and Other: (American Indian/Alaskan Native, two/more, Native Hawaiian/Pacific Islander, 
and Asian). Race/ethnicity shares are created as shares of each race/ethnicity’s total enrollment. 

* Final data name(s): Homelessness
* Analyst(s): Erica Blom and Emily Gutierrez
* Data source(s): EDFacts homelessness data; Common Core of Data (CCD) to identify counties and cities.
* Year(s): 2014-15 school year through 2019-20 school year
* Notes:
    * Limitations: Data suppression
    * Missingness: 323/3,142 counties in 2014, 312/3,142 counties in 2015, 267/3,142 counties in 2016, 
305/3,142 counties in 2017, 286/3,142 counties in 2018, 295/3,142 counties in 2019. 

Outline the process for creating the data: Counts of students experiencing homelessness are downloaded from the EDFacts website,
including by race/ethnicity subgroups for 2019.
Supressed data are replaced with 1 for the main estimate and 0 for the lower bound. For the upper
bound, suppressed data are replaced with the smallest non-suppressed value by state and subgrant
status if there are two or fewer suppressed values by state and subgrant status, per the documentation,
and 2 otherwise. Four county level data, districts are assigned to the county where the district office is located (obtained
from the CCD data). For city level data, districts are assigned to the city where the district offices is located (obtained 
from the CCD data). Shares are calculated by dividing by total enrollment in the county (again based on)
the location of the district office, with enrollment counts also from CCD data). A flag indicates the
number of districts with suppressed data that are included in each county's estimate.

Data quality flag: Data quality of "1" requires the ratio of the upper bound (homeless_count_ub) to the
lower bound (homeless_count_lb) to be less or equal to than 1.05. Data quality of "2" requires this ratio
to be greater than 1.05 and less than or equal to 1.1. Data quality of 3 is the remainder. Note that the 
largest value of this ratio is 3.5 and that only 6 counties in 2018 and 13 in 2014, each with estimated 
homeless populations of less than 20, have ratio values at or between 2 to 3.5.

