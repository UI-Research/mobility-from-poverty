---
metric: College readiness
predictor: 09_preparation-for-college
pillar: High-Quality Education
metric_lead: [JP Walsh]
variables: [share_hs_degree, share_hs_degree_lb, share_hs_degree_ub, share_hs_degree_quality]
geographies:
  county: 2014, 2016, 2018, 2021, 2023
  place: 2014, 2016, 2018, 2021, 2023
subgroups: [race-ethnicity, gender, disability]
confidence_intervals: true
code:
  - college_metrics_county.qmd
  - college_metrics_place.qmd
  - run_college.qmd
  - R/calc_survey_mean_college.R
  - R/calc_survey_mean_subgroup_college.R
  - R/finalize_metric_college.R
final_files:
  - data/final/metrics_college_county_all_longitudinal.csv
  - data/final/metrics_college_county_race-ethnicity_longitudinal.csv
  - data/final/metrics_college_county_gender_longitudinal.csv
  - data/final/metrics_college_county_disability_longitudinal.csv
  - data/final/metrics_college_place_all_longitudinal.csv
  - data/final/metrics_college_place_race-ethnicity_longitudinal.csv
  - data/final/metrics_college_place_gender_longitudinal.csv
  - data/final/metrics_college_place_disability_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 5-year microdata, person records and person replicate weights
    provider: IPUMS USA
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, and 2019-2023 5-year samples (IPUMS us2014c, us2016c, us2018c, us2021c, us2023c); extracts dated 02_28_25 (persons) and 03_06_25 (replicate weights)
    access: API (ipumsr), cached on S3 for internal users
    url: https://usa.ipums.org/usa/
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Share of 19- and 20-year-olds with a high school diploma or General Educational Development (GED) credential, from American Community Survey (ACS) 5-year microdata. The subgroup files repeat the calculation by race and ethnicity, gender, and disability status.

## Methodology
- **Population**: people ages 19 and 20 in the ACS 5-year sample, in households and in group quarters (e.g., college dormitories).
- **Numerator**: people whose highest level of schooling is a high school diploma, a GED, or more (IPUMS `EDUCD` code 62 or higher). Records with missing educational attainment are set to missing.
- **Denominator**: all people ages 19 and 20 in the geography, weighted by the ACS person weight.
- **Geography**: the ACS identifies Public Use Microdata Areas (PUMAs), not counties or places. Each person is assigned to every county or place their PUMA overlaps, and the person weight and replicate weights are multiplied by the allocation factor (`afact`), the share of the PUMA's population that lives in that county or place. Counties and places that share the same PUMAs can get the same value. Years through 2021 use the 2010 PUMA crosswalk and 2023 uses the 2020 PUMA crosswalk.
- **Subgroups**: each person is assigned by their own characteristics.
  - Race and ethnicity: anyone Hispanic is Hispanic, regardless of race. Non-Hispanic people are White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities (all other races, including two or more races).
  - Gender: Male or Female, from `SEX`.
  - Disability: With Disability if the person reports any of five difficulties (self-care, vision or hearing, independent living, ambulatory, or cognitive); everyone else is Without Disability.
- **Small samples**: the effective sample is the sum of `afact` over the person records in a geography, or a geography and subgroup. Cells with an effective sample under 30 are not estimated and are reported as missing.
- **Confidence intervals**: `share_hs_degree_lb` and `share_hs_degree_ub` are 95 percent confidence intervals from the 80 ACS person replicate weights (variance is 4/80 times the sum of squared differences between each replicate estimate and the full-sample estimate). They reflect sampling error only, and bounds outside 0 to 1 are capped at 0 and 1.

## Data quality flag
- The flag is the crosswalk's `geographic_allocation_quality` for the geography, averaged over its records (`calc_survey_mean_college.R`). It measures how much of the geography's data comes from PUMAs that lie mostly inside it (`sum_products` in `geographic-crosswalks/generate_puma_county_crosswalks.qmd`):
  - `1`: `sum_products` of 0.75 or more
  - `2`: 0.35 to 0.75
  - `3`: under 0.35
- Sample size doesn't enter the flag. Small cells are `NA` instead, and their flag is `NA` too.
- The flag is the same for every subgroup in a geography-year (checked in all six subgroup files).
- County all file: 2,822 rows are `1`, 2,241 are `2`, 3,601 are `3`, and 7,052 are `NA`. Place all file: 643 are `1`, 1,266 are `2`, 500 are `3`, and 21 are `NA`.

## Missing values
County all file, missing per year: 1,421 (2014), 1,398 (2016), 1,410 (2018), 1,422 (2021), and 1,401 (2023), about 45 percent of counties each year.
- 1,225 counties are missing every year, 1,563 are never missing, and 364 are missing in some years.
- In 2023 the largest county with a missing value has 54,381 people (08037), and the missing counties hold 4.6 percent of the US population.

County subgroups, missing per year (2014–2023 range):
- White, Non-Hispanic: 1,712–1,769
- Black, Non-Hispanic: 2,811–2,831
- Hispanic: 2,764–2,864
- Other Races and Ethnicities: 2,820–2,935
- Male: 1,970–2,042; Female: 2,054–2,119
- Without Disability: 1,477–1,507; With Disability: 2,846–2,994

Place all file:
- South Fulton, GA (1372122): 2014–2021. It has rows only in the 2022 period of the PUMA-to-place crosswalk.
- North Port, FL (1249675): 2014–2018
- Plymouth and Woodbury, MN (2751730, 2771428): 2018 and 2021
- 2014 only: San Ramon, CA; Sandy Springs, GA; Arlington Heights, IL; Carmel and Fishers, IN; Bloomington, MN; Mount Pleasant, SC; Cedar Park, TX; Lehi, UT; and Racine, WI
- None in 2023

Place subgroups, missing per year (2014–2023 range):
- White, Non-Hispanic: 87–150
- Black, Non-Hispanic: 345–368
- Hispanic: 199–281
- Other Races and Ethnicities: 311–391
- Male: 29–100; Female: 48–121
- Without Disability: 0–18; With Disability: 382–447

## Comparability across years
- The years are overlapping 5-year samples: 2014 (2010–2014), 2016 (2012–2016), 2018 (2014–2018), 2021 (2017–2021), and 2023 (2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)). Nonoverlapping pairs are 2014 and 2021, 2016 and 2021, 2014 and 2023, 2016 and 2023, and 2018 and 2023.
- 2023 uses 2020 PUMAs and the 2022 crosswalk period. Place quality flags shift sharply: 125 places are `3` in 2021 and 7 in 2023.
- Connecticut uses its eight old counties through 2021 and its nine planning regions (09110–09190) in 2023.
