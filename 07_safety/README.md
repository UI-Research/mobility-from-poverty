# Safety - Crime Rate

When using county level crime statistics, it is important to keep in mind that they are generally incomplete. The Federal Bureau of Investigations (FBI) Uniform Crime Statistic (UCR) Crime in the United States data series (https://ucr.fbi.gov/crime-in-the-u.s) provides county level crime data that represents all crimes that occured within the county law enforcment agency's juristiction, outside of city juristitction. These data are missing crimes that occured in counties outside of the juristiction of the county. This exclused any crimes that take place within a county but in the juristiction of a city, tribal, univeristy, or other law enofrcmnet agency within the couty. These data also exclude any crimes that occured in the county under the juristiction of the state law enforcment agency.Documentation of the FBI UCR county crime data can be found here (https://www.fbi.gov/file-repository/ucr/ucr-srs-user-manual-v1.pdf/view).To combat this problem, the final dataset includes crimes tracked by county and city law enforcment agencies reporting to FBI UCR, aggregating crime data to the county level.

* Final data name(s): crimerate_county_2018.csv
* Analyst(s): Lily Robin
* Data source(s):
	2018_county.xls: county level crime data for 2018 (this file required some cleaning in excel to remove headers and footers) (source: https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-10/table-10.xls/view)
	2018_city.xls: city level crime data for 2018 (this file required some cleaning in excel to remove headers and footers) (source: https://ucr.fbi.gov/crime-in-the-u.s/2018/crime-in-the-u.s.-2018/tables/table-8/table-8.xls/view)
	county_crosswalk.csv: county FIPS and county populations
	zip_code_database.csv: USPS county and city names and zip codes (source: https://www.unitedstateszipcodes.org/zip-code-database/)
* Year(s): 2018
* Notes: This dataset is not inclusive of all counties and many counties are missing data from cities that reside within that county. Additionally, crimes that occured under the juristiction of agencies other then city and county law enforcment (ex. triable, university, state) are not included in crime counts for each county. Variables have been created to approximate the amount of missingness for a county. 
    * Limitations
    * Missingness

1. change the file directory listed after the "cd" command on line 8 and copy all source files to the file directory location you chose
2. import all files
3. identify counties cities are in (using city and county names) by mergeing 2018_city.xls with zip_code_database.csv
4. clean county crime file ((2018_county.xls), this includes cleaning names of counties to match the county_crosswalk.csv file
5. crosswalk county crime data (2018_county.xls) with county FIPS and population data (county_crosswalk.csv)
6. Add city crime data to counties
7. Aggergate data to the county level with one observation per county - calculating crime rates and statstics about missingness
8. Finalize and export data

----------------

# Safety - Juvenile Arrest Rate

This dataset contains juvenile arrest rates by county in 2016 using counts of arrests provided by FBI UCR data and population data for all children age 12 to 17. This age brakcet was chosen because the majority of states have an age of adulat criminal liability of 18 and at least one state has a minimum age of crminal liability of 12. 

* Final data name(s): 2016_arrest_by_county
* Analyst(s): Lily Robin
* Data source(s):
	2016_arrest.dta: arrests by agency in 2016
	children_12_17_v2.csv: population of children age 12 to 17 by county in 2016
	fbi_crosswalk.dta: county FIPS to county/agency ORI crosswalk
	county_crosswalk.csv: county FIPS and county populations
* Year(s):2016
* Notes: This dataset is not inclusive of all counties and agencies are missing from county arrest counts. The denominator is the best match for consistency across states, but is not fully accurate of the numerator in all states. Variables are included to identify states that have adult criminal liability ages below 18 and for counties with at least one arrest of a child 12 or under (the data could not be split to count only arrests of children under 12). 
    * Limitations
    * Missingness

1. change the file directory listed after the "cd" command on line 8 and copy all source files to the file directory location you chose
2. import all files
3. crosswalk county FIPS (fbi_crosswalk.dta) to the 2016 agency arrests file (2016_arrest) matching on ORI number
4. check 2016 agency arrests file (2016_arrest) for missing values in count of juvenile arrests by demographic group
5. Idnetify states with age of adult criminal liability below 18
6. Calculate total juvenile arrests per agency
7. Aggregate to County
	7a. Reduce observations to one per agency
	7b. Reduce observations to one per county
8. crosswalk arrest file (2016_arrest) to county population file (children_12_17_v2.csv)
9. crosswalk arrest file (2016_arrest) to county FIPS file (county_crosswalk.csv) with all counties to add in counties with missing data
10. Finalize and export data