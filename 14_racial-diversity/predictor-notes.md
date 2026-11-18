---
metric: Racial diversity (exposure to other race-ethnicity groups)
predictor: 14_racial-diversity
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Aaron R. Williams, Vincent Pancini, Manu Alcalá Kovalski]
variables: [share_black_nh_exposure, share_black_nh_exposure_quality, share_hispanic_exposure, share_hispanic_exposure_quality, share_other_nh_exposure, share_other_nh_exposure_quality, share_white_nh_exposure, share_white_nh_exposure_quality]
geographies:
  county: 2016, 2018, 2021, 2023
  place: 2016, 2018, 2021, 2023
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - race-ethnicity-exposure-county.qmd
  - race-ethnicity-exposure-city.qmd
final_files:
  - final/race-ethnicity-exposure-county.csv
  - final/race-ethnicity-exposure-city.csv
sources:
  - name: American Community Survey (ACS) 5-year estimates, tract-level data profile table DP05 (race and Hispanic origin) and table B01003 (total population)
    provider: US Census Bureau
    vintage: 2012-2016, 2014-2018, 2017-2021, and 2019-2023 5-year estimates
    access: API (censusapi::getCensus(), needs a Census API key)
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/geocorr2018_2010tract_to_2014place.csv
  - geographic-crosswalks/data/tract-place-crosswalk_2020.csv
  - geographic-crosswalks/data/tract_crosswalk_2022_connecticut.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
---

## Summary
For four race-ethnicity groups (Black, Non-Hispanic; Hispanic; Other Races and Ethnicities; and White, Non-Hispanic), the share of the average group member's census tract neighbors who belong to one of the other three groups. A value near 1 means the average group member lives in tracts made up almost entirely of other groups; a value of 0 means the group lives only in tracts made up entirely of its own group. Each group is its own column (wide format); there is no "All" value.

## Methodology
- **Groups**: four mutually exclusive groups built from American Community Survey (ACS) 5-year data profile table DP05: Hispanic (any race); Black, Non-Hispanic; White, Non-Hispanic; and Other Races and Ethnicities, the sum of non-Hispanic American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races. The four groups add up to total population (B01003) in every tract, and that total is the tract denominator. The DP05 variable codes change across years, so each year maps its own codes to the groups.
- **Measure**: for each group, the average share of a group member's census tract neighbors who belong to the other three groups. Each tract's other-groups share is weighted by the share of the county's or city's group members who live in that tract. For example, if 80 percent of a county's White, Non-Hispanic residents live in a tract that is 10 percent other groups and 20 percent live in a tract that is 50 percent other groups, `share_white_nh_exposure` is 0.8 × 0.1 + 0.2 × 0.5 = 0.18.
- **Neighborhood**: the census tract. The other-groups share divides by the tract's full population, including the group's own members.
- **Year**: `year` is the end year of an ACS 5-year sample, so `2016` is 2012–2016.
- **Geography**: county values use the tracts inside each county. City values allocate tract group counts to places with the Geocorr population allocation factor (`afact`, the share of a tract's population in the place): the 2010-tract-to-2014-place crosswalk for 2016 and 2018, the 2020 crosswalk for 2021, and the 2020 crosswalk with Connecticut tracts recoded to planning regions for 2023. A tract's other-groups share is the same whether all or part of the tract is in the city.
- **Margins of error**: the Other Races and Ethnicities margin of error combines the five group margins as a root sum of squares, counting only the largest margin among groups with a zero estimate, as the [Census Bureau recommends](https://www.census.gov/content/dam/Census/programs-surveys/acs/guidance/training-presentations/20180418_MOE_Webinar_Transcript.pdf). Hispanic margins for controlled estimates, which the Census Bureau reports as `-555555555`, are set to 0. These margins feed the quality flag only; the exposure shares have no confidence intervals.
- **Small counts**: a group's value is suppressed when the group's estimated count in the county or city is 30 or less.

## Data quality flag
Based on the coefficient of variation (CV) of the group's count in the county or city, not of the exposure share itself:
- `1`: CV below 0.2
- `2`: CV from 0.2 to below 0.4
- `3`: CV of 0.4 or more
- `NA`: the value is suppressed or the group has no members

County standard errors are `sqrt(sum(moe^2)) / 1.645` over the county's tracts (county line 517). City standard errors are `sqrt(sum(afact * moe^2)) / 1.645` (city line 681).

Tallies:
- County file (12,571 rows): Black, Non-Hispanic 6,728 `1`, 2,691 `2`, 1,333 `3` (12 percent of nonmissing), 1,819 `NA`. Hispanic 8,727, 2,802, 674, and 368 `NA`. Other Races and Ethnicities 8,052, 3,460, 727, and 332 `NA`. White, Non-Hispanic 12,517, 43, 5, and 6 `NA`.
- City file (1,943 rows): almost all `1`. Black, Non-Hispanic has 150 `2` and 11 `3`; Other Races and Ethnicities 20 `2` and 2 `3`; Hispanic 5 `2`; White, Non-Hispanic 1 `2`.
- The 11 city `3`s for Black, Non-Hispanic are Meridian, ID (1652120), Lehi, UT (4944320), and South Jordan, UT (4970850) in 2016 and 2018; Mission, TX (4848768) in 2016, 2018, and 2021; and Pharr, TX (4857200) in 2021 and 2023.

## Missing values
Both files have one row for every county and place in `county-populations.csv` and `place-populations.csv` for the four years: 3,142 counties in 2016 and 2018, 3,143 in 2021, and 3,144 in 2023 (nine Connecticut planning regions); 485 places in 2016 and 486 from 2018.

County file, counties missing per year:
- Black, Non-Hispanic: 441–474. Of these, 92–104 a year have no Black, Non-Hispanic residents (checked in `data/tracts.csv`); the rest have 30 or fewer. 281 counties are missing in all four years.
- Hispanic: 87–98 (30 counties in all four years)
- Other Races and Ethnicities: 111 (2016), 108 (2018), 65 (2021), 48 (2023)
- White, Non-Hispanic: Kalawao County, HI (15005) every year, and Kenedy County, TX (48261) in 2021 and 2023 (1 and 2 White, Non-Hispanic residents)

City file:
- South Fulton, GA (1372122): every group in 2018. It's in `place-populations.csv` from 2018 but not in the 2010-tract-to-2014-place crosswalk; the city .qmd says so.
- Pharr, TX (4857200): Black, Non-Hispanic in 2016 and 2018

## Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (2012–2016 and 2014–2018 share three years). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2016 and 2018 use 2010 tract boundaries, and 2021 and 2023 use 2020 boundaries. Because exposure depends on how people are split across tracts, redrawn tracts alone can change values between 2018 and 2021. City values also switch from the 2010-tract-to-2014-place crosswalk to the 2020 crosswalk.
- Connecticut uses its eight old counties through 2021 and the nine planning regions (09110–09190) in 2023.
- Average White, Non-Hispanic exposure rises every year, from 0.204 (2016) to 0.229 (2023) across counties and from 0.429 to 0.473 across cities (checked in the final files).
