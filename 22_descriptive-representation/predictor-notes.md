---
metric: Descriptive representation (population share by race and ethnicity, the denominator)
predictor: 22_descriptive-representation
pillar: Responsive and Just Governance
metric_lead: [JP Walsh]
variables: [share_desc_rep_other, share_desc_rep_other_quality, share_desc_rep_black_nonhispanic, share_desc_rep_black_nonhispanic_quality, share_desc_rep_hispanic, share_desc_rep_hispanic_quality, share_desc_rep_white_nonhispanic, share_desc_rep_white_nonhispanic_quality]
geographies:
  county: 2014, 2016, 2018, 2021, 2023
  place: 2014, 2016, 2018, 2021, 2023
subgroups: none
confidence_intervals: false
code:
  - descriptive_representation_denom.qmd
final_files:
  - data/final/descriptive_rep_denominator_county_all.csv
  - data/final/descriptive_rep_denominator_city_all.csv
sources:
  - name: American Community Survey (ACS) 5-year estimates, tables B01003, B03002, and B03003
    provider: US Census Bureau
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, and 2019-2023
    access: Census API through tidycensus get_acs(), key in CENSUS_API_KEY
    url: https://www.census.gov/programs-surveys/acs/data.html
crosswalks: [geographic-crosswalks/data/county-populations.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
---

## Summary
Share of the county or city population in each of four race and ethnicity groups, from the ACS 5-year estimates: Black non-Hispanic, Hispanic (any race), white non-Hispanic, and other (non-Hispanic Asian, American Indian and Alaska Native, Native Hawaiian and Other Pacific Islander, some other race, and two or more races). The four shares sum to 1. These are the denominator of the descriptive representation ratio (share of local elected officials in a group divided by the group's share of residents). The published variables are only these population shares; no ratio with elected officials is computed for any of the five years.

## Process
1. Set `CENSUS_API_KEY` in `.Renviron`. The .qmd calls `census_api_key(Sys.getenv("CENSUS_API_KEY"))`.
2. Set `update_years` at the top of `descriptive_representation_denom.qmd` (currently `c(2014, 2016, 2018, 2021, 2023)`) and render it. For each year it pulls the ACS 5-year estimates for all places and all counties with `get_acs(output = "wide")`. If `load_variables()` can't find the 5-year tables for a year, it pulls the 1-year estimates instead and prints a notice.
3. Variables: total population (`B01003_001`), Hispanic or Latino (`B03003_003`), and the non-Hispanic race counts (`B03002_003` to `B03002_009`). The margins of error are dropped.
4. Other = non-Hispanic Asian + American Indian and Alaska Native + Native Hawaiian and Other Pacific Islander + some other race + two or more races. A check stops the render if the four groups don't add up to the total population (county data only).
5. `left_join()` the ACS data onto `county-populations.csv` and `place-populations.csv` for the update years, on the five-digit county or seven-digit place GEOID, so the target geography list sets the rows.
6. Divide each group by total population. Checks stop the render if any share is outside 0–1 or the four shares don't sum to 1.
7. Set every quality flag to `1`, rename to `share_desc_rep_*`, run `evaluate_final_data()` against `99a_final-evaluation/evaluation_form_desc_rep_overall_place.csv` and `..._county.csv`, and write the two files in `data/final/`.

## Data quality flag
- `1` for every row and variable. The .qmd sets this because the values come from published Census summary tables.
- County file: all 15,713 rows are `1`. City file: all 2,428 rows are `1`.

## Missing values
No values are missing in either file.

Rows per year:
- County: 3,142 in 2014, 2016, and 2018; 3,143 in 2021; 3,144 in 2023 (the nine Connecticut planning regions), matching `county-populations.csv`
- City: 485 in 2014 and 2016, 486 from 2018 on. South Fulton, GA (13 72122) isn't in `place-populations.csv` before 2018.

Values of exactly 0 or 1 (counties):
- Black non-Hispanic share is 0 in 92–104 counties a year (487 county-years)
- Hispanic share is 0 in 8–15 counties a year (65 county-years)
- Other share is 0 in 4–15 counties a year (50 county-years)
- White non-Hispanic share is 1 in five county-years: 30069 (2016), 31009 (2018, 2021, 2023), and 38007 (2021)

Cities: Mission city, TX (48 48768) has a Black non-Hispanic share of 0 in 2018, and 0.3–0.9 percent in the other years.

## Known issues
- The quality flag ignores sampling error. Every row is `1` (`descriptive_representation_denom.qmd`, "Create quality flag"), but the margins of error are dropped before the shares are computed. Small counties get shares of exactly 0 or 1 (see Missing values), which are 5-year sample estimates, not counts.
- The other group combines five Census groups, including two or more races (`descriptive_representation_denom.qmd`, "Clean data"). Changes in the other share can't be split into those groups from the final files.
- The 1-year fallback in `read_places()` and `read_counties()` would pull 1-year estimates, which the Census Bureau publishes only for areas of 65,000 people or more ([When to use 1-year or 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/estimates.html)), so most counties would have no data. The check in step 4 only covers counties, and the `left_join()` in step 5 would leave those counties `NA` without stopping the render. The fallback isn't used for any current year.
- The population share check in step 4 runs on the county data only; there is no matching check on the place data before the shares are computed.

## Comparability across years
- The five years are overlapping 5-year periods (2010–2014, 2012–2016, 2014–2018, 2017–2021, 2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
- The other share grows faster after 2018: the median county share is 2.7 percent in 2014, 3.0 percent in 2018, 3.9 percent in 2021, and 4.8 percent in 2023, with the white non-Hispanic share falling by about the same amount.
- There are no values for 2015, 2017, 2019, 2020, 2022, or 2024.

## Open questions
- The predictor publishes only the denominator. `descriptive-representation.Rmd` is the older numerator code: it builds the full ratio for 2018 from the purchased ICMA Municipal Form of Government 2018 Survey (on Box, not publicly shareable). It reads and writes paths under `05_local-governance/`, which no longer exists, sources `05_local-governance/R/census_api_key.R` and `get_vars.R`, which aren't in the repo, and reads `geographic-crosswalks/data/county-file.csv`, which doesn't exist. Its `author:` field is blank. Is the plan to bring back the ratio, and is this file still needed?
- `descriptive-representation.csv` at the folder root is the output of that .Rmd: 2018 county ratios from the ICMA survey, with values for 1,521 of 3,142 counties. It isn't read by any code. Should a file derived from licensed survey data stay in the public repo?
- `fips/all-geocodes-v2018.xlsx` is read only by `descriptive-representation.Rmd`.
- The rendered `descriptive-representation.html` (from the .Rmd) and `descriptive_representation_denom.html` are committed. Are they still needed?
- The .qmd text says the place population file has no 2014 data and 2015 is used instead, but `place-populations.csv` has 2014 rows and the code uses them. It also gives the final data folder as `05_local-governance/descriptive-representation/data/final`.
- `99_construct-database/medians-raceeth.qmd` says "No quality variables for these" for `share_desc_rep_*`, but the final files and the evaluation forms have them.
- Does the faster growth in the other share after 2018 come from the Census Bureau's 2020 changes to race and ethnicity coding, or from population change?
