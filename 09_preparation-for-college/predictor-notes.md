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

## Process
1. You need an IPUMS application programming interface (API) key. Internal users with Amazon Web Services (AWS) access also read and write cached extracts and intermediate files in the `mobility-from-poverty-test` S3 bucket (`metric_name/data/acs/`).
2. Render `college_metrics_county.qmd` and `college_metrics_place.qmd` once per year, setting `params$year`. Set `single_year_update = "Yes"` to stop after the year's intermediate files are written. Then render once with `single_year_update = "No"` and every year listed in `existing_years` to combine the years, run the checks, and write the final files. `run_college.qmd` renders both .qmd files for 2014, 2016, 2018, and 2021.
3. Data: `extract_ipums_aws()` pulls the 5-year sample `us{year}c`, and the code keeps ages 19 and 20. `ipums_repwt_college_aws()` pulls the 80 person replicate weights (`REPWTP`) for the same ages, which are joined on `unique_person_id`. Both households and group quarters are kept.
4. Variables:
   - `EDUCD` codes 0, 1, and 999 are set to `NA`. `college_ready = 1` when `EDUCD >= 62` (high school graduate or GED, or more).
   - Race and ethnicity: Hispanic (any race), then White, Non-Hispanic; Black, Non-Hispanic; and Other Races and Ethnicities.
   - Gender from `SEX`.
   - With Disability if the person reports any of the five difficulty variables (`DIFFCARE`, `DIFFSENS`, `DIFFMOB`, `DIFFPHYS`, `DIFFREM`).
5. Crosswalk: join the PUMA crosswalk on `crosswalk_period`, `statefip`, and `puma` (`"pre-2022"` before 2022, `"2022"` after), drop rows with `afact` missing or 0, and multiply the person weight and all 80 replicate weights by `afact`.
6. Suppression: the effective sample is the sum of `afact` over person records in the geography (or geography and subgroup). Cells with an effective sample under 30 are dropped before estimation and come back as `NA`.
7. Estimate: `survey_mean()` on a JK1 replicate design (`scale = 4/80`, `calc_survey_mean_college.R`), with 95 percent confidence intervals. `finalize_metric_college.R` clamps the bounds to 0 and 1.
8. Expand to the full geography list: counties from the crosswalk (Puerto Rico dropped), checked against 3,143 rows a year before 2022 and 3,144 after; places from the crosswalk, checked against 486.
9. Each .qmd ends with `evaluate_final_data()` against its forms in `99a_final-evaluation/` (`evaluation_form_college_*`), then writes four files to `data/final/`. The race-ethnicity, gender, and disability files each include the `All` rows.

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

## Known issues
- Counties that share the same PUMAs get the same estimate. In the county all file, 2,426 of 8,664 nonmissing rows (28 percent) have the same value and confidence interval as at least one other county in the same year (data check). For example, Coshocton and Guernsey counties, OH (39031, 39059), are both 0.655 in 2016.
- Some subgroup values are exactly 1 with a confidence interval of 1 to 1, because every sampled person has a diploma and the replicate weights then give no variance (data check): 173 rows in the county race-ethnicity file (103 of them Other Races and Ethnicities), 21 in county gender, 9 in county disability, and 112, 16, and 6 in the place files. Mountain View, CA (0649670) is 1 for All in 2014.
- The quality flag reflects crosswalk fit only, not sample size (`calc_survey_mean_college.R` takes `geographic_allocation_quality` and nothing else). The old `documentation/overview.md` described a flag that also set small samples to `3`.
- The 2014–2018 county rows use later FIPS codes: 02063, 02066, 02158, and 46102 instead of 02261, 02270, and 46113. That gives 3,143 counties a year, while `county-populations.csv` has 3,142 for those years (data check). The county list comes from the crosswalk, not from `county-populations.csv`.
- Low values: the lowest county value is Highlands County, FL (12055), 0.633 in 2014; the lowest place values are Flint, MI (0.633 in 2023) and Yakima, WA (0.661 in 2014).

## Comparability across years
- The years are overlapping 5-year samples: 2014 (2010–2014), 2016 (2012–2016), 2018 (2014–2018), 2021 (2017–2021), and 2023 (2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)). Nonoverlapping pairs are 2014 and 2021, 2016 and 2021, 2014 and 2023, 2016 and 2023, and 2018 and 2023.
- 2023 uses 2020 PUMAs and the 2022 crosswalk period. Place quality flags shift sharply: 125 places are `3` in 2021 and 7 in 2023.
- Connecticut uses its eight old counties through 2021 and its nine planning regions (09110–09190) in 2023.

## Open questions
- The PUMA crosswalks now have `crosswalk_period` values `2k`, `2012`, and `2022` (since #606), but both .qmd files still assign `"pre-2022"`. Rerunning any year before 2022 would match no PUMAs; in the county .qmd, `county_list` would also be empty and the row-count check would fail. The crosswalk notes say 2012 PUMAs cover 2012–2021 ACS data and 2000 PUMAs cover earlier years, so the 2014 5-year sample (2010–2014) may need both.
- The .qmd text says suppressed counties get a quality flag of `3`, but the code sets their flag to `NA`.
- Intermediate files are only written to S3, and only if the file isn't already there, so a rerun of the same year doesn't overwrite it. Without S3, `read_intermediate()` reads local files that nothing writes, with a different name (`metrics_education_*` instead of `metrics_college_*`) and folder (`data/intermediate/preschool/` for counties, `data/intermediate/college/` for places).
- `run_college.qmd` renders 2014–2021 but not 2023, while both .qmd files list 2023 in `existing_years`. Its text also refers to the preschool place file.
- `programs/` holds the old English Language Arts (ELA) Stata code (`SEDA_metrics_race_county.do`, `SEDA_metrics_race_city.do`) and `SEDA Final Data Evaluation.qmd`. They read and write `09_preparation-for-college/data/built/`, which doesn't exist, and the ELA metric now lives in `07_effective-public-education/` as .qmd files. Can they be removed?
- The rendered `college_metrics_county.html`, `college_metrics_place.html`, and `programs/SEDA Final Data Evaluation.html` are committed next to the .qmd files. Are they still needed?
