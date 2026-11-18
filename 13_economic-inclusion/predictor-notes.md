---
metric: Poverty exposure (share of people in poverty living in high-poverty neighborhoods)
predictor: 13_economic-inclusion
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Aaron R. Williams, Vincent Pancini, Manu Alcalá Kovalski]
variables: [share_poverty_exposure, share_poverty_exposure_quality]
geographies:
  county: 2014, 2016, 2018, 2021, 2023
  place: 2014, 2016, 2018, 2021, 2023
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - poverty-exposure-county.qmd
  - poverty-exposure-city.qmd
final_files:
  - final/poverty-exposure_county.csv
  - final/poverty-exposure_race-ethnicity_county.csv
  - final/poverty-exposure_city.csv
  - final/poverty-exposure_race-ethnicity_city.csv
sources:
  - name: American Community Survey (ACS) 5-year estimates, tract-level table B17001 (poverty status) and race and ethnicity tables B17001B-B17001I
    provider: US Census Bureau
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, and 2019-2023 5-year estimates
    access: API (censusapi::getCensus(), needs a Census API key)
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/geocorr2018_2010tract_to_2014place.csv
  - geographic-crosswalks/data/tract-place-crosswalk_2020.csv
  - geographic-crosswalks/data/tract_crosswalk_2022_connecticut.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Share of people in poverty in a county or city who live in census tracts where more than 40 percent of people are in poverty. A value of 0 means no one in poverty lives in a high-poverty tract; a value of 1 means everyone in poverty does. The race-ethnicity files repeat the calculation for four groups.

## Methodology
- **Universe**: people for whom poverty status is determined in American Community Survey (ACS) table B17001 (`B17001_001`). The Census Bureau doesn't determine poverty status for people in institutional group quarters, military group quarters, or college dormitories, or for unrelated individuals under age 15 ([How the Census Bureau measures poverty](https://www.census.gov/topics/income-poverty/poverty/guidance/poverty-measures.html)). Tracts with no one in this universe are dropped.
- **High-poverty tract**: a census tract where more than 40 percent of the poverty universe is below the poverty line. The tract's overall poverty rate decides this for every race-ethnicity group, so a group's members count as living in a high-poverty tract based on the whole tract, not on the group's own rate.
- **Numerator and denominator**: people in poverty who live in high-poverty tracts, divided by all people in poverty in the county or city. Both are sums of tract counts.
- **Year**: `year` is the end year of an ACS 5-year sample, so `2014` is 2010–2014.
- **Subgroups**: each group uses its own B17001 iteration. Black is B17001B (Black alone) and Hispanic is B17001I. White, Non-Hispanic is B17001H. Other Races and Ethnicities is the sum of B17001C–G (American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races). The race tables other than B17001H include Hispanic people, so Hispanic people are also counted in Black or Other Races and Ethnicities. A group with no people in poverty gets 0 before suppression.
- **Margins of error**: the Other Races and Ethnicities margin of error combines the five group margins as a root sum of squares, counting only the largest margin among groups with a zero estimate, as the [Census Bureau recommends](https://www.census.gov/content/dam/Census/programs-surveys/acs/guidance/training-presentations/20180418_MOE_Webinar_Transcript.pdf). These margins feed the quality flag only; the exposure share has no confidence interval.
- **Geography**: counties sum the tracts inside them. Cities allocate tract counts to places with the Geocorr population allocation factor (`afact`, the share of a tract's population in the place): the 2010-tract-to-2014-place crosswalk for 2014–2018, the 2020 crosswalk for 2021, and the 2020 crosswalk with Connecticut tracts recoded to planning regions for 2023. A tract partly in a city is classified as high poverty using the whole tract's rate.
- **Small counts**: a value is suppressed when the group's estimated number of people in poverty in the county or city is 30 or less.

## Data quality flag
Based on the coefficient of variation (CV) of the group's poverty count in the county or city, not of the exposure share itself:
- `1`: CV below 0.2
- `2`: CV from 0.2 to below 0.4
- `3`: CV of 0.4 or more
- `NA`: the value is suppressed

Tallies:
- County all file: 14,472 rows are `1`, 1,145 are `2`, 63 are `3`, and 33 are `NA`. Rows rated `2` rise from 180 in 2014 to 280–294 in 2021 and 2023.
- County race-ethnicity file, `3` share of nonmissing rows: Black 31 percent, Hispanic 34 percent, Other Races and Ethnicities 29 percent, White, Non-Hispanic 2 percent.
- City all file: 2,316 rows are `1` and 111 are `2`. No city is ever `3`.
- City race-ethnicity file: Black 839 of 2,404 nonmissing rows are `3` (35 percent); Hispanic 361, Other Races and Ethnicities 240, White, Non-Hispanic 50.

## Missing values
County all file (6–7 counties a year, all suppressed or with no populated tracts):
- Kalawao County, HI (15005) and Loving County, TX (48301): every year
- Borden County, TX (48033): 2014–2021
- King County, TX (48269): 2014–2018 and 2023
- Kenedy County, TX (48261): 2021 and 2023
- San Juan County, CO (08111) and Daggett County, UT (49009): 2016 and 2018
- Roberts County, TX (48393): 2014 and 2016
- One year each: Yakutat, AK (02282, 2014); Rio Arriba, NM (35039, 2018); Bristol Bay, AK (02060, 2021); Banner and Blaine, NE (31007, 31009, 2021); Petroleum, MT (30069, 2023); Thomas, NE (31171, 2023)

County race-ethnicity file, counties missing per year:
- Black: 997–1,079
- Hispanic: 538–608
- Other Races and Ethnicities: 410–427 in 2014–2018, 323 in 2021, 251 in 2023
- White, Non-Hispanic: 11–28

City files:
- South Fulton city, GA (1372122) is missing in 2018. It is in `place-populations.csv` from 2018 on but not in the 2014-place crosswalk. The all file drops the row (485 cities in 2018); the race-ethnicity file keeps it with `NA` for every group (486).
- Black: 2–7 cities a year (e.g., 4848768, 4944320, 4970850 in several years)
- Hispanic: Rochester Hills, MI (2669035) in 2021

## Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (for example, 2010–2014 and 2012–2016). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2014–2018 use 2010 tract boundaries and 2021–2023 use 2020 boundaries, so which tracts cross the 40 percent line can change between 2018 and 2021 because of the redrawn tracts alone.
- City values for 2014–2018 come from a 2010-tract-to-2014-place crosswalk and later values from a 2020 crosswalk.
- Connecticut: the 2014–2021 county files use the eight old counties, and 2023 uses the nine planning regions (09110–09190), so there are 3,144 county rows in 2023.
