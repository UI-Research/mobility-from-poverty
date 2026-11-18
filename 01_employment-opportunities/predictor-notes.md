---
metric: Employment opportunities
predictor: 01_employment-opportunities
pillar: Rewarding Work
metric_lead: [JP Walsh, Aaron R. Williams]
variables: [share_employed, share_employed_lb, share_employed_ub, share_employed_quality]
geographies:
  county: 2014-2019, 2021-2024
  place: 2014-2019, 2021-2024
subgroups: [race-ethnicity, gender, disability]
confidence_intervals: true
code:
  - employment_metrics_county_all.qmd
  - employment_metrics_county_sub.qmd
  - employment_metrics_place_all.qmd
  - employment_metrics_place_sub.qmd
  - historical_comparison_employment_metric_county.qmd
  - R/calc_survey_mean.R
  - R/calc_survey_mean_subgroup.R
  - R/finalize_metric.R
  - R/run_employment_years.qmd
final_files:
  - data/final/metrics_employment_county_all_longitudinal.csv
  - data/final/metrics_employment_county_race-ethnicity_longitudinal.csv
  - data/final/metrics_employment_county_gender_longitudinal.csv
  - data/final/metrics_employment_county_disability_longitudinal.csv
  - data/final/metrics_employment_place_all_longitudinal.csv
  - data/final/metrics_employment_place_race-ethnicity_longitudinal.csv
  - data/final/metrics_employment_place_gender_longitudinal.csv
  - data/final/metrics_employment_place_disability_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 1-year microdata, person records and person replicate weights
    provider: IPUMS USA
    vintage: 2014-2019, 2021-2024 (samples us{year}a)
    access: IPUMS API in code (extract_ipums_aws(), ipums_repwt_employment_aws()), cached on AWS S3
    url: https://usa.ipums.org/usa/acs.shtml
  - name: American Community Survey (ACS) 5-year microdata, person records and person replicate weights
    provider: IPUMS USA
    vintage: 2014, 2016, 2018, 2021, 2023 (samples us{year}c)
    access: IPUMS API in code (extract_ipums_aws(), ipums_repwt_employment_aws()), cached on AWS S3
    url: https://usa.ipums.org/usa/acs.shtml
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
Share of adults ages 25 to 54 who are employed, from American Community Survey (ACS) microdata via IPUMS, with 95 percent confidence intervals. The all files use the 1-year ACS; the subgroup files (race-ethnicity, gender, disability) use the 5-year ACS. Public Use Microdata Areas (PUMAs) are allocated to counties and places with the PUMA crosswalks.

## Methodology
- **Numerator and denominator**: people ages 25–54 who are employed (IPUMS `empstat` = employed), divided by all people ages 25–54. The denominator includes people who are unemployed or not in the labor force, so this is an employment-to-population ratio, not an unemployment rate.
- **Universe**: people living in households. People in group quarters, such as institutions, college dorms, and military barracks, are excluded.
- **Samples**: the all files use the 1-year American Community Survey (ACS) for each year. The subgroup files use the 5-year ACS, labeled by the last year of the period (e.g., `2014` is 2010–2014).
- **Geography**: ACS microdata identify Public Use Microdata Areas (PUMAs), not counties or places. Each person's weight is multiplied by the crosswalk's allocation factor (`afact`, the share of the PUMA's population in that county or place), so a person in a PUMA that spans several counties counts partly toward each. Survey years before 2022 use a crosswalk for the earlier PUMA boundaries; 2022 and later use one for the 2020 PUMA boundaries.
- **Subgroups**: each person is grouped by their own characteristics.
  - Race and ethnicity: Hispanic people of any race are Hispanic. Non-Hispanic people are White, Black, or Other Races and Ethnicities, which combines all other single races and people of two or more races.
  - Gender: Male or Female, from the ACS sex question.
  - Disability: With Disability if the person reports any of five difficulties (cognitive, ambulatory, independent living, self-care, or vision or hearing); Without Disability otherwise.
- **Small samples**: a geography, or a subgroup within it, is suppressed when its effective sample (the sum of `afact` across its survey records) is below 30.
- **Confidence intervals**: 95 percent intervals from the 80 ACS person replicate weights (successive difference replication), capped at 0 and 1.

## Data quality flag
- `share_employed_quality` is the crosswalk's `geographic_allocation_quality`, averaged over the records in the geography with `unweighted(mean())` (`R/calc_survey_mean.R`). The crosswalk sets it from `sum_products`: `1` if 0.75 or more, `2` if 0.35 or more, `3` otherwise (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`).
- Suppressed geographies (effective sample below 30) get `NA` for both the metric and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 16,042 are `3` (51 percent), and 5,191 are `NA`. Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.

## Missing values
- County all file: 488–544 counties a year (about 16–17 percent) are suppressed for an effective sample below 30. In 2014 and 2024, every suppressed county had a population of 15,000 or less (`county-populations.csv`).
- Place all file: South Fulton city, GA (1372122) in 2014–2021; no missing places from 2022 on.
- County subgroup files, pooled over the five years: Black, Non-Hispanic is missing for 64 percent of county-years, Hispanic for 60 percent, Other Races and Ethnicities for 63 percent, and White, Non-Hispanic for 4 percent. With Disability is missing for 31 percent; Female and Male for 5 percent each; All for 2 percent.
- Place subgroup files: Black, Non-Hispanic is missing for 18 percent of place-years; every other subgroup for 2 percent or less.

## Comparability across years
- No 2020: the all files skip 2020 (`existing_years`), so 2019 to 2021 is a two-year change.
- PUMA boundaries changed in 2022, and the crosswalk changes with them (`crosswalk_period`), so geographic allocation and quality flags can shift between 2021 and 2022.
- The subgroup files are 5-year estimates for 2014, 2016, 2018, 2021, and 2023; consecutive releases overlap in years.
