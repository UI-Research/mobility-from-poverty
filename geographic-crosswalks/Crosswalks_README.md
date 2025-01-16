# Using Geographic Crosswalks

The crosswalks files found in the geographic crosswalks folder are resources available to you as you aggregate or disaggregate your data in service of calculating a given metric at larger or smaller geographic units than the original data sources provide. The main files, county-populations.csv & place-populations.csv, have the name, FIPS, and population data up to 2022 for the 3142 counties and 480 places that ought to be represented in all final datasets.
When choosing a crosswalk for a specific dataset, it is important to note the year of the geographies used in the crosswalk, and make sure that it is aligned with the year of data you are working with. This is because, definitions such as "tract", "county", "ZIP", and more, change over time as populations shift and new methodologies are implemented.
If you find that you need a crosswalk that does not already exist in this folder, or have questions about implementation, please reach out to team leadership and we will be happy to help.


place_population.csv
This file provides the Census estimated population for each incorporated place (e.g., "city") with a population over 75,000.
From 2014-2017, this has 485 observations.
From 2018-2023, this has 486 observations.

county_populations.csv
This file provides the Census estimated population for each county in the US.
NOTE: Connecticut stopped using its 8 historical counties as functional governmental units in 1960. In 2022, the Census Bureau updated its data reporting to align with Connecticut's governance structure, which divides the state into 9 planning regions that reflect the state’s 9 Regional Councils of Government (COGs). These regions are now used for reporting, replacing the old 8 historical counties. As new census data products will follow this structure, we will report data for the 8 counties through 2021, and we will report data for the 9 planning regions from 2022 onward.
From 2014-2019, this has 3142 observations.
From 2020-2021, this has 3143 observations.
From 2022-2023, this has 3143 observations.


