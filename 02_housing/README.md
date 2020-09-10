# Metric template

Brief description

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

<Repeat above information for additional metrics>
