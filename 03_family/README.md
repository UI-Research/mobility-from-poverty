# Family structure

Brief description

* Final data name(s): metrics_famstruc.csv
* Analyst(s): Kevin Werner and Paul Johnson
* Data source(s): ACS 1-yr and ACS 5-yr for subgroup. 
* Year(s): 2018
* Notes:
	The compute_ program calculates the percent of children in each family structure,
	while the finalize_ calculates the confidence intervals and outputs the .csv.
	
	NOTE: to run this code, you must first run the 1_, 2_, and 3_ programs in the income folder. (For the subgroup analysis, run 3_create_microdata_5_year.)

The data comes from IPUMS. It is cleaned and counties are added with Paul's method.
The compute_ code then finds the percent of children in each family structure. 
The finalize_ program then calculates confidence intervals a outputs as a .csv.

The process for the subgroup analysis is the same as above, except every county has four rows,
one for each race/ethnicity subgroup.

<Repeat above information for additional metrics>
