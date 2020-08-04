# Metric template

Brief description

* Final data name(s): metrics_employment
* Analyst(s): Kevin Werner and Paul Johnson
* Data source(s): ACS 1-yr
* Year(s): 2018
* Notes:
	County 05 in HI is missing
	NOTE: must run the 1_, 2_, and 3_ code in the income subfolder first.
	
The data are downloaded from IPUMS and cleaned with the 1_, 2_, and 3_ code. That
code also adds the the county FIPS. The compute_ code finds the employment rate of
25-54 year olds. The finalize_ code calculates the confidence intervals and outputs
the csv.  

<Repeat above information for additional metrics>
