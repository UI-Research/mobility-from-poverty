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

## Process
1. Set an IPUMS API key once (`set_ipums_api_key()`). Internal users can cache extracts and intermediate files on the AWS S3 bucket `mobility-from-poverty-test`; without access, intermediate files are meant to go to `data/intermediate/`.
2. All files: render `employment_metrics_county_all.qmd` and `employment_metrics_place_all.qmd` once per year with `params$year`. Each run pulls the 1-year sample `us{year}a` and its person replicate weights and writes `metrics_employment_all_{county|place}_{year}.csv` to S3 or `data/intermediate/`. With `single_year_update = "No"`, the run then reads every year in `existing_years` (2014–2019 and 2021–2024) and writes the final longitudinal file. `R/run_employment_years.qmd` renders several years in a row (its `years` vector is currently 2017, 2018, 2019, 2021, 2022).
3. Subgroup files: render `employment_metrics_county_sub.qmd` and `employment_metrics_place_sub.qmd` for each 5-year sample (`us{year}c`); `existing_years` is 2014, 2016, 2018, 2021, and 2023.
4. Records: keep ages 25–54 and household records only (`gq` is one of the three "household" categories). `empstat == 0` (not in universe) becomes `NA`; `employed = empstat == 1`.
5. Subgroups (subgroup files only):
   - Race-ethnicity: Hispanic if `hispan != "Not Hispanic"`; otherwise White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities from `race`.
   - Gender: Male or Female from `sex`.
   - Disability: With Disability if any of `diffcare`, `diffsens`, `diffmob`, `diffphys`, or `diffrem` shows a difficulty; Without Disability otherwise.
6. Join the PUMA crosswalk on `crosswalk_period`, `statefip`, and `puma`; drop rows with missing or zero `afact`; multiply `perwt` and all 80 replicate weights by `afact`.
7. Suppress any geography (or geography-subgroup) whose effective sample, the sum of `afact`, is below 30.
8. `calc_survey_mean()` / `calc_survey_mean_subgroup()` build a replicate-weight design (`type = "JK1"`, `scale = 4/80`, `mse = TRUE`) and compute `survey_mean(employed, vartype = "ci")`, which uses the srvyr default 95 percent level. `finalize_metric()` caps the bounds at 0 and 1.
9. Expand to the full county list (3,143 a year before 2022, 3,144 from 2022) or the 486 places, so suppressed geographies have rows with `NA`.
10. Each .qmd ends with `evaluate_final_data()` against its forms in `99a_final-evaluation/` (`evaluation_form_employment_{overall|race_eth|gender|disability}_{county|place}.csv`).

`historical_comparison_employment_metric_county.qmd` is a one-time check of the 2018 results against an earlier release; it is not part of the build.

## Data quality flag
- `share_employed_quality` is the crosswalk's `geographic_allocation_quality`, averaged over the records in the geography with `unweighted(mean())` (`R/calc_survey_mean.R`). The crosswalk sets it from `sum_products`: `1` if 0.75 or more, `2` if 0.35 or more, `3` otherwise (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`).
- Suppressed geographies (effective sample below 30) get `NA` for both the metric and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 16,042 are `3` (51 percent), and 5,191 are `NA`. Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.

## Missing values
- County all file: 488–544 counties a year (about 16–17 percent) are suppressed for an effective sample below 30. In 2014 and 2024, every suppressed county had a population of 15,000 or less (`county-populations.csv`).
- Place all file: South Fulton city, GA (1372122) in 2014–2021; no missing places from 2022 on.
- County subgroup files, pooled over the five years: Black, Non-Hispanic is missing for 64 percent of county-years, Hispanic for 60 percent, Other Races and Ethnicities for 63 percent, and White, Non-Hispanic for 4 percent. With Disability is missing for 31 percent; Female and Male for 5 percent each; All for 2 percent.
- Place subgroup files: Black, Non-Hispanic is missing for 18 percent of place-years; every other subgroup for 2 percent or less.

## Known issues
- The 2014 place subgroup files have noninteger quality flags (for example, 2.35) for 113 places: 528 rows in the race-ethnicity file, 339 in gender, and 338 in disability. `employment_metrics_place_sub.qmd` joins both the 2000-PUMA (`2k`) and 2010-PUMA (`2012`) crosswalk rows to the 2014 5-year sample, and `calc_survey_mean_subgroup()` averages `geographic_allocation_quality` across them.
- The flag reflects only how well PUMAs line up with the geography, not sample size: it is copied from the crosswalk (`R/calc_survey_mean.R`), and small samples are handled by suppression instead. Half of county all rows are quality `3`.
- The all files (1-year ACS) and subgroup files (5-year ACS) come from different samples, so the All rows in the subgroup files don't match the all files (in 2018, 3,091 of 3,143 county All values differ).

## Comparability across years
- No 2020: the all files skip 2020 (`existing_years`), so 2019 to 2021 is a two-year change.
- PUMA boundaries changed in 2022, and the crosswalk changes with them (`crosswalk_period`), so geographic allocation and quality flags can shift between 2021 and 2022.
- The subgroup files are 5-year estimates for 2014, 2016, 2018, 2021, and 2023; consecutive releases overlap in years.

## Open questions
- Only `employment_metrics_place_sub.qmd` was updated for the new crosswalk periods. `employment_metrics_county_all.qmd`, `employment_metrics_county_sub.qmd`, and `employment_metrics_place_all.qmd` still assign `crosswalk_period = "pre-2022"` and filter on it, but the crosswalk files now only have `2012`, `2k`, and `2022`. Re-running any pre-2022 year with those three files would match no PUMAs.
- The local fallback for intermediate files calls `write_csv(paste0(...))` with a path and no data (`employment_metrics_county_all.qmd`, and the same pattern in the other three), so runs without S3 access would fail at that step.
- The .qmd text says suppressed geographies get a quality flag of `3` and that the flag combines crosswalk quality with sample size; the code sets suppressed rows to `NA` and uses crosswalk quality only. The data dictionary in `employment_metrics_county_all.qmd` also says the bounds are a 90 percent interval; `survey_mean()` uses its 95 percent default.
- `data/raw/employment_opp_1year.dat.gz` (about 43 MB, an IPUMS extract) and its `.xml` are committed but not read by any code. IPUMS [terms of use](https://www.ipums.org/about/terms) limit redistribution. Should they be removed? `data/intermediate/county_puma.csv` and `puma_county.csv` are also committed and unused.
- `historical_comparison_employment_metric_county.qmd` reads `data/00_mobility-metrics_longitudinal.csv` and `data/01_mobility-metrics_race-ethnicity_longitudinal.csv`, which no longer exist. Is it still needed?
