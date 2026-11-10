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

## Process
1. Copy `R/census_api_key-template.R` to `R/census_api_key.R` and add a Census API key. Both .qmd files source it, and it sets `CENSUS_KEY`, which `censusapi` reads.
2. Set `years` in both .qmd files (now `c(2014, 2016, 2018, 2021, 2023)`). Each year is the end year of an ACS 5-year sample.
3. Render `poverty-exposure-county.qmd` and `poverty-exposure-city.qmd`, in either order. Whichever runs first pulls tract data for every state and DC (not Puerto Rico) and caches it in `data/tracts.csv`; the other reads the cache. The county file also caches `data/counties.csv` and the city file `data/places.csv`, which are only used for comparison checks.
4. Tracts: drop tracts with no people (`people > 0`, where `people` is B17001_001, the population for whom poverty status is determined). Build Other Races and Ethnicities as the sum of the American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races poverty counts. Its margin of error (MOE) combines the group MOEs, keeping only the largest MOE among groups with a zero estimate.
5. A tract is high poverty if `poverty / people > 0.4`. Each group's high-poverty count is its poverty count in those tracts, and 0 elsewhere. The tract's overall rate decides this for every group.
6. County: sum tracts to counties. City: allocate tracts to places with the Geocorr allocation factor `afact` and sum. The 2010-tract-to-2014-place crosswalk is used for 2014, 2016, and 2018, the 2020 crosswalk for 2021, and the 2020 crosswalk with Connecticut tracts recoded to the planning regions for 2023. Only places in `place-populations.csv` are kept.
7. `share_poverty_exposure = high_poverty / poverty`. For subgroups, a group with no people in poverty gets 0.
8. Suppress (set to `NA`) any estimate where the group's estimated poverty count is 30 or less, then assign the quality flag.
9. County files are `left_join()`ed onto `county-populations.csv` (expanded to all five subgroups in the race-ethnicity file). The city all file is written from the place summary without a join; the city race-ethnicity file is joined onto `place-populations.csv`.
10. Each .qmd ends with `evaluate_final_data()` against its forms in `99a_final-evaluation/` (`evaluation_form_exposure_poverty_*`).

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

## Known issues
- Most counties are exactly 0: 2,393–2,513 a year (76–80 percent) in the all file. In cities, 200–262 a year (41–54 percent) are 0. Checked in the final files.
- Values of exactly 1 occur in 2–8 counties a year, mostly in South Dakota (Corson 46031, Mellette 46095, Todd 46121, Ziebach 46137, which are 1 in most years). In the city race-ethnicity file, Black exposure is 1 in Pharr, TX (4857200) in 2021, with quality `3`. Checked in the final files.
- The race-ethnicity groups overlap. Black (B17001B), the five groups in Other Races and Ethnicities (B17001C–G), and Hispanic (B17001I) are race-alone or ethnicity tables, so Hispanic people are also counted in a race group. Only White, Non-Hispanic (B17001H) excludes Hispanic people. The labels in the files are "Black" and "Hispanic" (`recode()` in both .qmd files; the [ACS 5-year variable list](https://api.census.gov/data/2021/acs/acs5/variables.html) gives the table titles).
- The city CVs are on a different scale from the county CVs. The county standard error is `sqrt(sum(moe^2)) / 1.645`; the city standard error is `sqrt(sum(afact * moe^2))`, without dividing by 1.645 (`places_summary` in `poverty-exposure-city.qmd`). The [Census Bureau worked examples](https://www2.census.gov/programs-surveys/acs/tech_docs/accuracy/2018_ACS_Accuracy_Document_Worked_Examples.pdf) convert MOEs to standard errors with 1.645.
- The suppression threshold is applied to the weighted estimate of people in poverty (`suppress_county(race = poverty, ...)` and `suppress_place()`), not to an unweighted sample count.
- The tract cache isn't refreshed when `years` changes. Both .qmd files only call the API `if (!file.exists("13_economic-inclusion/data/tracts.csv"))`, so a new year is silently skipped unless the cached file is deleted first.
- A city tract counts as high poverty based on the whole tract's rate, even when only part of the tract is in the city (stated in `poverty-exposure-city.qmd`, step 3).

## Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (for example, 2010–2014 and 2012–2016). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2014–2018 use 2010 tract boundaries and 2021–2023 use 2020 boundaries, so which tracts cross the 40 percent line can change between 2018 and 2021 because of the redrawn tracts alone.
- City values for 2014–2018 come from a 2010-tract-to-2014-place crosswalk and later values from a 2020 crosswalk.
- Connecticut: the 2014–2021 county files use the eight old counties, and 2023 uses the nine planning regions (09110–09190), so there are 3,144 county rows in 2023.

## Open questions
- `R/census_api_key.R` is not in `.gitignore`. The ignore rules cover `R/census_api_key.R` at the repo root and `06_neighborhoods/R/census_api_key.R`, an old folder name, so a key added here as Process step 1 says could be committed. `13_economic-inclusion/data/` (the cached tract files) isn't ignored either.
- The county .qmd text says the latest data is the 2017–2021 ACS, but the code pulls through 2019–2023.
- The city .qmd says it suppresses estimates "with thirty or fewer unweighted observations", but the code uses the weighted poverty count. It also describes the place allocation as areal interpolation by area overlap, but the Geocorr crosswalks carry population columns (`pop10`, `pop20`); check which weighting the crosswalks used.
- The city .qmd says there are 485 cities through 2014–2018, but `place-populations.csv` has 486 in 2018 (South Fulton). Should the city all file be joined onto `place-populations.csv` like the other files, so 2018 has a row for South Fulton?
- `R/get_vars.R` is sourced by both .qmd files, but `get_vars()` is never called. Is it still needed?
- The county check that the summed tract poverty rates match the published county rates is `eval: false` and noted as failing for two New York counties (36103, 36111).
