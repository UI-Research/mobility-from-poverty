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
* Year(s): 2015 (2015-16 school year)
* Notes:
    * Limitations: Not all counties report assessments for all grades, so some estimates
	may be based on fewer than 6 data points; underlying data have been manipulated by SEDA
	to introduce noise to ensure confidentiality; migration into or out of a county may
	result in the "cohort" not being exactly the same between third and eigth grades.
    * Missingness: 80/3,142 missing counties

Outline the process for creating the data: SEDA data were manually downloaded
and read in, and a regression of mean assessment scores was run on grade (as a continuous
variable) interacted with each county in order to obtain county-specific grade slopes.
Regressions were weighted by the number of test-takers for each year, grade, and county. 
95% confidence intervals are calculated as the slope estimate plus or minus 1.96 times
the standard error of the estimate. A flag indicates how many grades are included in
each estimate.   

# Share of students in high-poverty schools

Brief description: This metric reflects the fraction of students in each county who attend
schools where 40 percent or more of students receive free or reduced-price lunch (FRPL). 

* Final data name(s): FRPL
* Analyst(s): Erica Blom
* Data source(s): Common Core of Data via Education Data Portal
* Year(s): 2018 (2018-19 school year)
* Notes:
    * Limitations: Not all states report FRPL; some instead report the number of students
	directly certified (DC). These states are Massachusetts, Tennessee, Delaware, and the 
	District of Columbia. In addition, Alaska and Ohio report either FRPL or DC.
    * Missingness: 4/3,142 counties

Outline the process for creating the data: Schools were flagged as having 40% or more FRPL
if either the number of students receiving FRPL or the number of DC students was greater than
40%. Total enrollment (by race) was summed in these schools and divided by total enrollment 
(by race) in the county. 
