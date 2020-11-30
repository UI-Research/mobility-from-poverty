# Metric template

Brief description

* Final data name(s): metrics_employment
* Analyst(s): Kevin Werner and Paul Johnson
* Data source(s): ACS 1-yr and ACS 5-yr for subgroup analysis.
* Year(s): 2018
* Notes:
	County 05 in HI is missing
	NOTE: must run the 1_, 2_, and 3_ code in the income subfolder first.
	
The data are downloaded from IPUMS and cleaned with the 1_, 2_, and 3_ code. That
code also adds the the county FIPS. The compute_ code finds the employment rate of
25-54 year olds. The finalize_ code calculates the confidence intervals and outputs
the csv.  

The process for the subgroup analysis is the same. You must run the file 3_prepare_microdata_5_year.

<Repeat above information for additional metrics>

* Final data name(s): metrics_wage_ratio
* Analyst(s): Kevin Werner and Aaron Williams
* Data source(s): QCEW and MIT Living Wage Calculator 
* Year(s): 2018 and 2014
* Notes:
	County 05 in HI is missing
	County 3 in State 19 (Iowa) is missing average wage data, so it shows up as a 0 in the ratio
	
This data comes from two sources. The average weekly wage comes from the QCEW: https://www.bls.gov/cew/downloadable-data-files.htm
The row where the ownership variable equals "Total Covered" is used for each county.
The living wage data is scraped from the MIT website using the scrape-living-wages R program.
There are three .csvs: 2014 QCEW data, 2018 QCEW data, and the MIT living wage data
Those .csvs are merged into one Stata file; the MIT wage is converted into weekly.
For 2018, the ratio is just the 2018 QCEW data divided by the MIT data. For 2014, I first deflate
the MIT data (because it is only available for 2018) to 2014, and then divide the QCEW by the 
deflated value. 

The living wage is a FULL TIME worker wage, while the average weekly wage includes part time workers.

We use the living wage level for one adult and two children. 

<Repeat above information for additional metrics>
