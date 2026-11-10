---
metric: Access to preschool
predictor: 06_access-to-preschool
pillar: High-Quality Education
metric_lead: [JP Walsh]
variables: [share_in_preschool, share_in_preschool_lb, share_in_preschool_ub, share_in_preschool_quality]
geographies:
  county: 2014, 2016, 2018, 2021, 2023
  place: 2014, 2016, 2018, 2021, 2023
subgroups: [race-ethnicity, income]
confidence_intervals: true
code:
  - preschool_county.qmd
  - preschool_place.qmd
  - run_preschool_years.qmd
  - R/calc_survey_mean.R
  - R/calc_survey_mean_subgroup.R
  - R/finalize_metric.R
final_files:
  - data/final/metrics_preschool_county_all_longitudinal_all.csv
  - data/final/metrics_preschool_county_race-ethnicity_longitudinal.csv
  - data/final/metrics_preschool_county_income_longitudinal.csv
  - data/final/metrics_preschool_place_all_longitudinal_all.csv
  - data/final/metrics_preschool_place_race-ethnicity_longitudinal.csv
  - data/final/metrics_preschool_place_income_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 5-year microdata, person records and person replicate weights
    provider: IPUMS USA
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, and 2019-2023 samples (IPUMS us2014c, us2016c, us2018c, us2021c, us2023c); extracts dated 02_28_25
    access: IPUMS API in code (functions/API/extract_ipums_aws.R and functions/API/ipums_repwt_pre-k_aws.R), cached on S3; needs an IPUMS API key
    url: https://usa.ipums.org/usa-action/variables/GRADEATT
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
Share of 3- and 4-year-olds who attend nursery school or preschool, from American Community Survey (ACS) 5-year microdata. The county and place files have 95 percent confidence intervals, and the subgroup files split the share by race and ethnicity and by household income (below $50,000 versus $50,000 or more).

## Process
1. Set an IPUMS API key once (`set_ipums_api_key()`); never commit it. If you change an extract, update `ipums_extract_date` and `ipums_repwt_extract_date` in the Housekeeping chunk (both are `02_28_25`).
2. Each .qmd runs one ACS year, set by `params$year` (default `"2023"`). Render `preschool_county.qmd` and `preschool_place.qmd` once per year. `run_preschool_years.qmd` is meant to loop over `years` but doesn't run as written (see Open questions).
3. Pull person records (`extract_ipums_aws()`, sample `us{year}c`) and person replicate weights for 3- and 4-year-olds (`ipums_repwt_pre_k_aws()`, which filters age in the API call). Keep ages 3 and 4, join the replicate weights by person, and `stopifnot()` that row counts match and nothing is missing. Both households and group quarters are kept.
4. Build the subgroups:
   - Race and ethnicity: `hispan != "Not Hispanic"` is Hispanic; otherwise White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities.
   - Income: `hhincome` of 9999999 is set to `NA`; $50,000 or More versus Less than $50,000.
5. Join to the PUMA-to-county or PUMA-to-place crosswalk on `crosswalk_period`, `statefip`, and `puma`. Drop records with missing or zero `afact`, and multiply `perwt` and all 80 replicate weights by `afact`.
6. Keep children whose `grade_attending` is Nursery school/preschool, N/A, or Kindergarten. `preschool` is TRUE only for Nursery school/preschool.
7. Effective sample = sum of `afact` per geography (and per subgroup). Geographies under 30 are dropped before estimating, then added back as `NA`.
8. `share_in_preschool` = `survey_mean(preschool)` with JK1 replicate weights (`scale = 4/80`, `mse = TRUE`) in `R/calc_survey_mean.R`. `R/finalize_metric.R` caps the bounds to 0 and 1.
9. Each run writes intermediate files to S3 (`mobility-from-poverty-test`) or to `data/intermediate/`. With `single_year_update = "No"`, the .qmd reads every year in `existing_years` (2014, 2016, 2018, 2021, 2023), runs checks, calls `evaluate_final_data()` against the preschool forms in `99a_final-evaluation/`, and writes the six final files.

## Data quality flag
- `NA` when `share_in_preschool` is `NA` (effective sample under 30).
- Otherwise the crosswalk's `geographic_allocation_quality`, based on `sum_products`, the share of the geography's records that come from PUMAs inside it (`generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`):
  - `1`: `sum_products` is 0.75 or more
  - `2`: 0.35 to under 0.75
  - `3`: under 0.35
- Sample size only enters through suppression; a geography just over 30 can still be a `1`.
- County all file: 2,823 rows are `1`, 2,242 are `2`, 2,991 are `3`, and 7,660 are `NA`. Place all file: 644 are `1`, 1,273 are `2`, 503 are `3`, and 10 are `NA`.

## Missing values
- Counties: about half are suppressed each year (1,491–1,568 of 3,143 or 3,144).
- Places: Kissimmee, FL (1236950) and Palm Coast, FL (1254200) in 2014; North Port, FL (1249675) and South Fulton, GA (1372122) in 2014–2021; none in 2023.
- County subgroups, missing per year: White, Non-Hispanic 1,803–1,856; Black, Non-Hispanic 2,913–2,957; Hispanic 2,835–2,863; Other Races and Ethnicities 2,858–2,953; $50,000 or More 1,879–2,138; Less than $50,000 2,247–2,619.
- Place subgroups, missing per year: White, Non-Hispanic 95–166; Hispanic 235–291; Black, Non-Hispanic 369–397; Other Races and Ethnicities 345–410; $50,000 or More 4–75; Less than $50,000 148–295.

## Known issues
- 3- and 4-year-olds in kindergarten count in the denominator as not in preschool, and any in first grade or higher are dropped (`filter(grade_attending %in% c("Nursery school/preschool", "N/A", "Kindergarten"))` in both .qmd files).
- A `gradeatt` of N/A (code 0) is treated as not in school; the .qmd text states this as an assumption.
- The 2014–2018 county rows use later county codes, not that year's: they have 02063 and 02066 instead of 02261, and 2014 also has 02158 and 46102 instead of 02270 and 46113 (compared with `county-populations.csv`). The county list comes from the PUMA crosswalk, not the target county file, so those years have 3,143 rows instead of 3,142.
- Confidence intervals come from replicate weights (`R/calc_survey_mean.R`), while the old `documentation/overview.md` described a normal-approximation formula.

## Comparability across years
- Each year is a 5-year ACS sample, so neighboring years overlap (for example, 2014 and 2016 share 2012–2014).
- The code joins 2014–2021 to the pre-2022 crosswalk period and 2023 to the 2022 period (2020 PUMAs), so the county and place allocation changes in 2023.
- Connecticut has its 8 old counties through 2021 and its 9 planning regions in 2023.

## Open questions
- `run_preschool_years.qmd` builds the county output name from `params$metric_name`, but the file has no `params`, so it errors as written.
- Without S3 access, both .qmd files write intermediate files to `data/intermediate/` but read them back from `data/intermediate/preschool/`, so a local run with `single_year_update = "No"` can't find its own files.
- The code sets `crosswalk_period` to `"pre-2022"` for years before 2022, but `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` now use `"2k"`, `"2012"`, and `"2022"`. Re-running 2014–2021 would drop every record at the crosswalk join.
- The place .qmd text says suppressed places get a quality flag of 3; the code sets them to `NA`.
- The place .qmd describes the metric as "in pre-K or higher" and the county .qmd as "enrolled in pre-K"; both compute nursery school or preschool only.
- Four files in `data/final/` aren't written by the code or read by `99_construct-database/`: `metrics_preschool_county_all_longitudinal.csv` (2014–2021), `metrics_preschool_place_all_longitudinal.csv` (2018 and 2021), `metrics_preschool_place_all_longitudinal_2014_16.csv`, and `metrics_preschool_place_race-ethnicity_longitudinal_2014_16.csv`. Are they still needed?
