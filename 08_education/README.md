# Effective Public Education

Brief description: This metric reflects the average annual learning growth in English/language arts (ELA) 
among public school students between third grade and eighth grade. For the 2015 cohort (students who were in 
eighth grade in the 2015-16 school year), this measure is the slope of the best fit line of the 2009-10 third 
grade assessment, the 2010-11 fourth grade assessment, etc. Assessments normed so that a typical third grade 
assessment would score 3, a typical fourth grade assessment would score 4, etc. Thus, typical learning 
growth is roughly 1 grade level per year. 1 indicates a county or metro is learning at an average rate; below 1 is slower 
than average, and above 1 is faster than average. Assessments are state- and year-specific, but the 
Stanford Education Data Archive (SEDA) has normed these to be comparable over time and space.

* Final data name(s): SEDA_all_subgroups_county SEDA_all_subgroups_metro
* Analyst(s): Erica Blom and Emily Gutierrez
* Data source(s): https://cepa.stanford.edu/content/seda-data
https://edopportunity.org/get-the-data/seda-archive-downloads/
exact file: https://stacks.stanford.edu/file/druid:db586ns4974/seda_county_long_gcs_4.1.dta
Reardon, S. F., Ho, A. D., Shear, B. R., Fahle, E. M., Kalogrides, D., Jang, H., & Chavez, B. (2021). 
Stanford Education Data Archive (Version 4.1). Retrieved from http://purl.stanford.edu/db586ns4974.
* Year(s): 2013-14 school year through 2017-2018 school year
* Notes: 
    * Limitations: Data suppression
    * Missingness: The following years have the following missing data: 
						County					Metro
subgroup					2013	2014	2015	2016	2017								2013	2014	2015	2016	2017
All						81	85	76	75	102		All						0	1	0	0	10
Black, Non-Hispanic			1784	1812	1821	1844	1855		Black, Non-Hispanic			334	346	346	359	370
Economically Disadvantaged		211	212	219	223	278		Economically Disadvantaged		5	6	3	4	25
Female					207	202	207	210	245		Female					0	1	0	0	13
Hispanic					1757	1706	1694	1653	1659		Hispanic					221	207	205	198	193
Male						193	196	198	205	237		Male						0	1	0	0	13
Not Economically Disadvantaged	326	328	344	354	410		Not Economically Disadvantaged	6	7	6	5	30
White, Non-Hispanic			204	218	216	214	252		White, Non-Hispanic			10	14	12	9	22


Outline the process for creating the data: SEDA data are manually downloaded 
and read in, and a regression of mean assessment scores was run on grade 
(as a continuous variable) interacted with each county in order to obtain county-specific or metro-specific
grade slope. Regressions are weighted by the number of test-takers for each year, grade, 
and county or metro. 95% confidence intervals are calculated as the slope estimate plus or minus 
1.96 times the standard error of the estimate. A flag indicates how many grades are included in each estimate.

Data quality flag: Data quality of "1" requires at least 5 or 6 years of data to be included, 
with at least 30 students tested in each year (a commonly used minimum sample size for stability of estimates). 
Data quality of "2" requires at least 4 years included with at least 30 students in each year. 
Data quality of "3" is assigned to the remainder. These quality flags are determined separately for each subgroup, 
such that the quality flag for one subgroup in a county or metro may differ from that of another subgroup.

