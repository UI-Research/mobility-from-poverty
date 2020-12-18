# ELA learning rate

Brief description: This metric reflects the average annual learning growth 
in English/language arts (ELA) among public school students between third 
grade and eigth grade. For the 2015 cohort (students who were in eighth 
grade in the 2015-16 school year), this measure is the slope of the best fit
line of the 2009-10 third grade assessment, the 2010-11 fourth grade assessment,
etc. Assessments normed so that a typical third grade assessment would score 3,
a typical fourth grade assessment would score 4, etc. Thus, typical learning growth
is roughly 1 grade level per year. 1 indicates a county is learning at an average rate;
below 1 is slower than average, and above 1 is faster than average. Assessments are 
state- and year-specific, but the Stanford Education Data Archive (SEDA) has normed 
these to be comparable over time and space.

* Final data name(s): SEDA
* Analyst(s): Erica Blom
* Data source(s): https://cepa.stanford.edu/content/seda-data
	https://edopportunity.org/get-the-data/seda-archive-downloads/ 
	exact file: https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_v30.dta
	
	Reardon, S. F., Ho, A. D., Shear, B. R., Fahle, E. M., Kalogrides, D., Jang, H., Chavez, B., 
	Buontempo, J., & DiSalvo, R. (2019). Stanford Education Data Archive (Version 3.0). 
	http://purl.stanford.edu/db586ns4974.
	
* Year(s): 2015 (2015-16 school year), 2014, and 2013
* Subgroups: all; gender; race/ethnicity; income
* Notes:
    * Limitations: Not all counties report assessments for all grades, so some estimates
	may be based on fewer than 6 data points; underlying data have been manipulated by SEDA
	to introduce noise to ensure confidentiality; migration into or out of a county may
	result in the "cohort" not being exactly the same between third and eigth grades.
    * Missingness: missing observations by year and subgroup:

-------------------------------------------------
                               |       year      
                      subgroup | 2013  2014  2015
-------------------------------+-----------------
                           All |   80    87    80
           Black, Non-Hispanic | 1796  1825  1839
    Economically Disadvantaged |  199   211   205
                        Female |  216   216   223
                      Hispanic | 1778  1735  1717
                          Male |  199   209   205
Not Economically Disadvantaged |  308   324   333
           White, Non-Hispanic |  202   210   215
-------------------------------------------------


Outline the process for creating the data: SEDA data are manually downloaded
and read in, and a regression of mean assessment scores was run on grade (as a continuous
variable) interacted with each county in order to obtain county-specific grade slopes.
Regressions are weighted by the number of test-takers for each year, grade, and county. 
95% confidence intervals are calculated as the slope estimate plus or minus 1.96 times
the standard error of the estimate. A flag indicates how many grades are included in
each estimate.  

Data quality flags: Data quality of "1" requires at least 5 or 6 years of data to be
included, with at least 30 students tested in each year (a commonly used minimum 
sample size for stability of estimates). Data quality of "2" requires at least 4 years 
included with at least 30 students in each year. Data quality of "3" is assigned to the 
remainder. These quality flags are determined separately for each subgroup, such that
the quality flag for one subgroup in a county may differ from that of another subgroup.

# Share of students in high-poverty schools

Brief description: This metric reflects the fraction of students in each county who attend
schools where 40 percent or more of students receive free or reduced-price lunch (FRPL). 

* Final data name(s): FRPL
* Analyst(s): Erica Blom
* Data source(s): Common Core of Data via Education Data Portal
* Year(s): 2018 (2018-19 school year)
* Notes:
    * Limitations: Not all states report FRPL; some instead report the number of students
	directly certified (DC). FRPL is "The unduplicated number of students who are eligible 
	to participate in the Free Lunch and Reduced Price Lunch Programs under the National 
	School Lunch Act of 1946." DC is "The unduplicated count of students in membership 
	whose National School Lunch Program (NSLP) eligibility has been determined through 
	direct certification." (https://www2.ed.gov/about/inits/ed/edfacts/eden/non-xml/fs033-14-1.docx)
	
	In 2018, the states reporting DC instead of FRPL are Massachusetts, Tennessee, Delaware, 
	and the District of Columbia. In addition, Alaska and Ohio report either FRPL or DC 
	for a substantial number of schools in 2018. 
	
    * Missingness: 4/3,142 counties

Outline the process for creating the data: Schools were flagged as having 40% or more FRPL
if either the number of students receiving FRPL or the number of DC students was greater than
40%. Each county is assigned a flag (poverty_measure_used) that indicates whether all schools 
have a higher number of students reported under "FRPL" or "DC"; if there is a mix, the county 
is assigned "Both". Total enrollment (by race) was summed in these schools and divided by total 
enrollment (by race) in the county. 

Data quality flags: Data quality of "1" requires at least 30 students in the county and for the
poverty_measure_used to be either "FRPL" or "DC", but not "Both". Data quality of "2" requires at 
least 15 students in the county and a poverty_measure_used flag of "FRPL" or "DC". The remainder
receive a data quality flag of "3".
