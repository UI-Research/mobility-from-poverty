# Safety - Crime Rate

These metrics use a clean county level crime dataset that can be found on ICPSR (https://www.openicpsr.org/openicpsr/project/108164/version/V3/view?path=/openicpsr/108164/fcr:versions/V3). This file was created using agency level data with ORI codes that were crosswalked with county FIPS codes. This file is not complete, but includes a coverage indicator to show how much of a county is covered in the crime counts captured. The coverage indicator is calcualted as follows. 

	CI_x = 100 * ( 1 - SUM_i { [ORIPOP_i/COUNTYPOP] * [ (12 - MONTHSREPORTED_i)/12 ] } )
 		where CI = Coverage Indicator
 		x = county
 		i = ORI within county

The file also uses imputation to estimate crime counts for months of missing data by agency. More information on the dataset can be found here (https://www.openicpsr.org/openicpsr/project/108164/version/V3/view). 

The metrics of interest from these data are violent crime (murder and nonnegligent manslaughter, forcible rape, robbery, and aggravated assault) and property crime (burglary, larceny-theft, motor vehicle theft, and arson). Rates are calculated as the number of crimes per 100,000 people using ACS county populations.  

	county crime rate = (county crime count / county population) * 100,000

This file reports crime counts for all of New York City in the New York County observation. For this reason, data from New York State (https://www.criminaljustice.ny.gov/crimnet/ojsa/countycrimestats.htm) was used for the five counties in New York City instead. 

When using county level crime statistics, it is important to keep in mind that they are generally incomplete. The Federal Bureau of Investigations (FBI) Uniform Crime Statistic (UCR) Crime in the United States data series (https://ucr.fbi.gov/crime-in-the-u.s) provides county level crime data that represents all crimes that occured within the county law enforcment agency's juristiction, outside of city juristitction. These data are missing crimes that occured in counties outside of the juristiction of the county. This exclused any crimes that take place within a county but in the juristiction of a city, tribal, univeristy, or other law enofrcmnet agency within the couty. These data also exclude any crimes that occured in the county under the juristiction of the state law enforcment agency. Documentation of the FBI UCR county crime data can be found here (https://www.fbi.gov/file-repository/ucr/ucr-srs-user-manual-v1.pdf/view). For this reason we have chosen to use an already cleaned county crime file created using agency level data. 

* Final data name(s): crimerate_county_2017.csv
* Analyst(s): Lily Robin
* Data source(s):
	county_crosswalk.csv: county FIPS and county populations
	county_ucr_offenses_known_yearly_1960_2017.dta: county crime counts for 1960 to 2017 (https://www.openicpsr.org/openicpsr/project/108164/version/V3/view)
	ny_county_indexcrime_2017.xls: new york state index crimes by county (https://www.criminaljustice.ny.gov/crimnet/ojsa/countycrimestats.htm)
* Year(s): 2017
* Notes: This dataset is not inclusive of all counties and many counties are missing data from agencies that reside within that county. 
    * Limitations: Some agencies change reporting practices year to year. Therefore, year to year comparisons should be used with caution and a knowledge of agency reporting practices (UCR data from the web has footnotes that I can merge in, but this data does not). Imputation was used to estimate crime rates in unreported months, using the NACJD method. The coverage indicator provides an estimate of the amount of the population coverage by reporting agencies. The data quality index is used to assess the quality of data for each county using the coverage indicator variable.

Counties with 100% coverage are marked as a 1, counties with between 100 and 80% coverage are marked as a 2, and counties with less then 80% coverage are marked as a 3. ~43% of counties have a data quality index of 1, ~40% have a data quality measure of 2, and ~17% have a data quality measure of 3. Data for the five counties that reside in NYC was pulled from NYS data. These data are likely very accurate, and have been given a quality index measure of 1, but they do not come from the same dataset as the rest of the counties. 

    * Missingness: ~0.22% (7) of counties are missing all crime data.~0.39% (12) counties are missing coverage information. 

1. Change the file directory
2. Import and clean all files
3. Merge crime counts to counties
4. Clean merged data and generate rate3
5. Finalize and export data

----------------

# Safety - Juvenile Arrest Rate

This dataset contains arrest rates of children age 10 to 17 by county in 2016 using counts of arrests provided by Federal Bureau of Investigations (FBI) Uniform Crime Reporting program (UCR) data and population data for all children age 10 to 17 from the ACS 2016 1-year extract from IPUMS. This age bracket was chosen because the majority of states have an age of adulat criminal liability of 18 and at least one state has a minimum age of crminal liability of 12, and arrests of very young children are unlikely. The UCR data is split by children age 0-9, 10 - 12, 13 - 14, and then by individual year. Starting at age 10 was a natural split in the data and anything older then 17 is considered adult in all states. 

* Final data name(s): 2016_arrest_by_county
* Analyst(s): Lily Robin
* Data source(s):
	2016_arrest.dta: arrests by agency in 2016 (https://www.icpsr.umich.edu/web/ICPSR/studies/37056)
	children_10_17.csv: population of children age 10 to 17 by county in 2016 (created by Kevin Werner)
	fbi_crosswalk.dta: county FIPS to agency Originating Reporting Agency Identifier (ORI) crosswalk (https://www.icpsr.umich.edu/web/ICPSR/series/366)
	county_crosswalk.csv: county FIPS and county populations (provided by Kevin)
* Year(s):2016
* Notes: 
    * Limitations: Children age 10 - 17 is the best match of numerator and denominator across states, but not necassarily reflective of definitions of juvenile by state. Variables are included to identify states that have adult criminal liability ages below 18 and for the number of arrests of children under 10 by county. The data does not distinuish between no arrests in an age catagory and a non-report on the catagory so some 0s may actually be non-reports. The data quality index is used to assess the quality of data for each county using the coverage indicator.

The coverage indicator is calculated using an indicator of whether data was reported for each month and offense for an agency in 2016. The coverage indicator is calculated as: 1 - (observations with non reported data for a county / total observations for a county). Where each observation is a arrests reported by an agency for a month for a specific offense catagory. There are also agencies that have overlapping juritsictions. In this senario, arrests should be attributed to only one of the agencies in the juristictional area per FBI data standards. If a juristiction is indicated as being covered by another juristiction, it is not included in the count of non-reporting agencies in a county. This is the best available estimate of how many arrests within a county are actually covered by the statistic provided in the final dataset for a county, but it is not complete. There are 215 agencies in the file that cannot be matched to a county. Additionally population of each county versus the population for missing data is not accounted for. 

Counties with 100% coverage are marked as a 1, counties with between 100 and 80% coverage are marked as a 2, and counties with less then 80% coverage are marked as a 3. ~31% of counties have a data quality index of 1, ~57% have a data quality measure of 2, and ~13% have a data quality measure of 3. 

    * Missingness: 7 counties are missing arrest data. 

1. change the file directory listed after the "cd" command on line 8 and copy all source files to the file directory location you chose. Files can be found in the Box folder: Box Sync\Metrics Database\Safety\juvenile_arrest
2. import all files
3. crosswalk county FIPS (fbi_crosswalk.dta) to the 2016 agency arrests file (2016_arrest) matching on ORI number
4. check 2016 agency arrests file (2016_arrest) for missing values and create non-reporting variable to account for non-reporting agencies in a county
5. Calculate total juvenile arrests per agency
6. Aggregate to County
7. Identify states with age of adult criminal liability below 18
8. crosswalk arrest file (2016_arrest) to county population file (children_10_17.csv)
9. crosswalk arrest file (2016_arrest) to county FIPS file (county_crosswalk.csv) with all counties to add in counties with missing data
10. Finalize and export data