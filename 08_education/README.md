# Metric template

Brief description

* Final data name(s):
* Analyst(s):
* Data source(s):
* Year(s):
* Notes:
    * Limitations
    * Missingness

Outline the process for creating the data    

<Repeat above information for additional metrics>

* Final data name(s): metrics_preschool
* Analyst(s): Kevin Werner
* Data source(s): ACS
* Year(s): 2018
* Notes:
		Hawaii county 05 is missing. It is very low population.
		This metric uses Paul Johnson's method of finding county FIPS code from PUMAs.
		PUMAs can sometimes span counties, which is adjusted for with weights.

Data was downloaded from IPUMS. Then cleaned with the IPUMS .sas program. Then I created
county FIPS using Paul's method. Then, I calculated the number of 3 and 4 year olds, 
the number of children in pre school, and divided them. 


* Final data name(s): metrics_college
* Analyst(s): Kevin Werner and Paul Johnson
* Data source(s): ACS
* Year(s): 2018
* Notes:
	The compute_ code computes the metrics. The finalize_ code computes the
	confidence intervals and outputs the .csv.
	
	NOTE: must run the 1_, 2_, and 3_ code in the income subfolder first.

Data was downloaded from IPUMS. Then cleaned with the IPUMS .sas program. Then I created
county FIPS using Paul's method. Then, we calculated the number of 19-20 year olds, 
the number with a high school degree and divided them. 
