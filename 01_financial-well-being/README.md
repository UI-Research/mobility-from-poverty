# Metric template

Brief description

* Final data name(s): metrics_income
* Analyst(s): Kevin Werner and Paul Johnson
* Data source(s): ACS 1-yr for original and ACS 5-yr for subgroup.
* Year(s): 2018
* Notes:
    I used the quantreg procedure to get the percentiles and the confidence interals.
	The percentiles were the same as when done via the means procedure, but I cannot
	testify to the accuracy of the confidence intervals.

	The three programs beginning 1_, 2_, and 3_ must be run before computing these metrics.
	These programs infile some .csv files which can be found on Box under "ACS-based metrics."

	For the subgroup analysis, I have changed from the quantreg procedure to proc means. I get the
	percentiles for each state-county-race combination with proc means. To run the subgroup programs,
	you must run the programs 1_, 2_, and then 3_prepate_microdata_5_year. 

Outline the process for creating the data    
	The data comes from IPUMS. It is cleaned and counties are added with Paul's method.
	Then I use the quantreg procedure to get the needed percentiles and the confidence
	intervals. Finally it is output as a .csv.
	The process for the subgroup analysis is the same, except I create the percentiles with
	proc means. I do not create confidence intervals. 

Note: As of 9/10/20 I have removed the confidence interval code. 

<Repeat above information for additional metrics>

