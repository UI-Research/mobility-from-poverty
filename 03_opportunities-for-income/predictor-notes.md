---
metric: Opportunities for income
predictor: 03_opportunities-for-income
pillar: Rewarding Work
metric_lead: [JP Walsh]
variables: [pctl_income_20, pctl_income_50, pctl_income_80]
geographies:
  county: 2014-2019, 2021-2024
  place: 2014-2019, 2021-2024
subgroups: [race-ethnicity, gender]
confidence_intervals: true
code:
  - income_metrics_county_all.qmd
  - income_metrics_county_sub.qmd
  - income_metrics_place_all.qmd
  - income_metrics_place_sub.qmd
  - R/calc_income_quantiles.R
  - R/calc_income_quantiles_subgroup.R
  - R/finalize_metric.R
  - R/run_income_years.qmd
final_files:
  - final/metrics_income_county_all_longitudinal.csv
  - final/metrics_income_county_gender_longitudinal.csv
  - final/metrics_income_county_race-ethnicity_longitudinal.csv
  - final/metrics_income_place_all_longitudinal.csv
  - final/metrics_income_place_gender_longitudinal.csv
  - final/metrics_income_place_race-ethnicity_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 1-year microdata
    provider: IPUMS USA
    vintage: 2014-2019, 2021-2024 (samples usYYYYa); used for the all files
    access: API (ipumsr via functions/API/extract_ipums_aws.R, cached on S3)
    url: https://usa.ipums.org/usa-action/samples/sample_ids
  - name: American Community Survey (ACS) 5-year microdata
    provider: IPUMS USA
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, 2019-2023 (samples usYYYYc); used for the subgroup files
    access: API (ipumsr via functions/API/extract_ipums_aws.R, cached on S3)
    url: https://usa.ipums.org/usa-action/samples/sample_ids
  - name: CPI-U adjustment factors (CPI99)
    provider: IPUMS USA and IPUMS CPS
    vintage: scraped at run time
    access: web scrape (rvest)
    url: https://usa.ipums.org/usa/cpi99.shtml
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
The 20th, 50th (median), and 80th percentiles of household income for each county and for the 486 places, from American Community Survey (ACS) microdata, with 95 percent confidence intervals. The all files use 1-year ACS data. The subgroup files use 5-year ACS data and split households by the race and ethnicity or the sex of the householder.

## Process
1. Set an IPUMS API key (`set_ipums_api_key()`). Internal users with AWS access read cached extracts and intermediate files from the `mobility-from-poverty-test` S3 bucket.
2. Each .qmd processes one ACS year, set in `params$year`, and saves a per-year intermediate file to S3. With `single_year_update = "Yes"` the program stops there. With `"No"` it reads every year in `existing_years`, runs the checks, and writes the longitudinal file to `final/`. To add a year: run with `"Yes"`, add the year to `existing_years`, then run again with `"No"`.
   - All files: 1-year samples (`usYYYYa`), `params$year = "2024"`
   - Subgroup files: 5-year samples (`usYYYYc`), `params$year = "2023"`; `R/run_income_years.qmd` renders the subgroup .qmd files for several years at once
3. Keep one record per household (`pernum == 1`), keep the three household group quarters codes (dropping institutions and other group quarters), and set `hhincome == 9999999` to `NA`.
4. Subgroups (subgroup files only), taken from the householder's record:
   - Race and ethnicity: `Hispanic` if `hispan != "Not Hispanic"`, otherwise `White, Non-Hispanic`, `Black, Non-Hispanic`, or `Other Races and Ethnicities`
   - Gender: `Male` or `Female` from `sex`
5. Join the PUMA crosswalk on `crosswalk_period`, `statefip`, and `puma`, with `crosswalk_period` set to `"pre-2022"` for survey years before 2022 and `"2022"` after. Drop rows with a missing or zero `afact`, then multiply `hhwt` and all 80 replicate weights by `afact`.
6. Inflation: multiply income by the IPUMS USA CPI99 factor for the survey year, then by the IPUMS CPS alternate factor for `params$inflation_year` (`"2024"` in all four .qmd files), then by `adjust`.
7. Suppress each county, place, or subgroup cell whose effective sample (the sum of `afact` across its records) is under 30.
8. `R/calc_income_quantiles.R` computes the three percentiles with `survey_quantile()` (JK1 replicate weights, `scale = 4/80`, `qrule = "hf3"`) and 95 percent confidence intervals.
9. Expand to the full county or place list so suppressed geographies appear as `NA`, add the quality flag, run `evaluate_final_data()` against the forms in `99a_final-evaluation/`, and write the CSVs to `final/`.

## Data quality flag
- The flag is the crosswalk's `geographic_allocation_quality`: the sum over PUMAs of `afact × afact2` is 0.75 or more for `1`, 0.35 to 0.75 for `2`, and under 0.35 for `3` (`geographic-crosswalks/generate_puma_county_crosswalks.qmd`, `generate_puma_place_crosswalks.qmd`). It is the same for all three percentiles.
- Suppressed cells (effective sample under 30) get `NA` for the estimate and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 17,705 are `3` (63 percent of rows with an estimate), and 3,528 are `NA`.
- Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.
- County race-ethnicity file: 13,478 are `1`, 8,273 are `2`, 26,020 are `3`, and 30,809 are `NA`. County gender file: 8,469, 6,801, 30,399, and 1,479.
- Place race-ethnicity file: 3,105, 5,900, 2,401, and 744. Place gender file: 1,932, 3,825, 1,521, and 12.

## Missing values
- County all file: 342–362 counties a year (about 11 percent), all because their effective sample is under 30.
- All three place files: South Fulton city, GA (1372122) is missing for 2014–2021, in every subgroup. It appears only in the 2022 period of `crosswalk_puma_to_place.csv`.
- County subgroup files, `All` rows: 41–47 counties a year (5-year data has more sample than 1-year).
- County race-ethnicity file, counties missing per year: Black, Non-Hispanic 1,940–1,975; Hispanic 1,977–2,179; Other Races and Ethnicities 1,607–2,220; White, Non-Hispanic 64–83.
- County gender file: Female 129–142 and Male 112–130 counties a year.
- Place race-ethnicity file, places missing per year: Black, Non-Hispanic 92–129; Hispanic 11–46; Other Races and Ethnicities 3–54; White, Non-Hispanic 1–2.
- Confidence intervals: 77 estimates in the county race-ethnicity file and 3 in the place race-ethnicity file have an estimate but a missing lower or upper bound.

## Known issues
- The quality flag measures only how well PUMAs line up with the geography, not how precise the estimate is (`R/calc_income_quantiles.R` passes through `geographic_allocation_quality`). In the county race-ethnicity file, 44 rows have a 20th percentile under $5,000, as low as $21 (Hispanic, county 23019, 2023), and 35 of them are quality `1`.
- The all files and the subgroup files come from different ACS samples (1-year versus 5-year), so the `All` rows in the subgroup files don't match the all files: the medians agree in 267 of 13,941 county-years compared. For example, the 2023 median for Cook County, IL (17031) is $81,592 in the race-ethnicity file and $83,273 in the all file.
- Subgroups describe the householder only: each .qmd keeps `pernum == 1` before the race-ethnicity and gender variables are built (`income_metrics_county_sub.qmd` line 123, `income_metrics_place_sub.qmd` line 116; [PERNUM](https://usa.ipums.org/usa-action/variables/PERNUM)).
- Intermediate files keep the dollars they were built with. The final step binds the per-year files without re-adjusting them, so if `inflation_year` changes, every earlier year has to be rerun to stay in the same dollars.

## Comparability across years
- There is no 2020: `existing_years` skips it in both all .qmd files.
- PUMA boundaries change in 2022, and the code switches crosswalks at that year (`crosswalk_period`).
- The subgroup years are 5-year samples that overlap: 2014 (2010–2014), 2016 (2012–2016), and 2018 (2014–2018) share survey years, so changes between them are smaller than year-to-year changes in the all files.

## Open questions
- The .qmd files still use `crosswalk_period == "pre-2022"`, but on this branch `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` only have the periods `2k`, `2012`, and `2022` (changed in `ecaab286`, 2026-06-24, after these final files were built on 2026-03-03). Rerunning any pre-2022 year would find no matching crosswalk rows (`income_metrics_county_all.qmd` lines 410 and 434, and the same lines in the other three files). The crosswalk notes say the `2k` period is for pre-2012 ACS data (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` line 62), so the 2014 subgroup files (2010–2014 sample) could use it for their 2010–2011 records.
- `income_metrics_place_all.qmd` is committed with `single_year_update = "Yes"` (line 156), so a full render stops before writing the final file.
- Intermediate files are only written to S3 (`put_object()`); nothing writes them locally, so the local fallback in `read_intermediate()` has nothing to read without AWS access. In `income_metrics_county_all.qmd` the fallback path is also missing an underscore (`"metrics_income", file_type`, line 838).
- The county all .qmd text expects 50–200 suppressed counties a year (line 978) and says quality `3` "should be less common" (line 963); the final data have 342–362 suppressed counties a year, and `3` is the most common flag.
- `R/geocorr2018_2503500948.csv` isn't read by any file in the repo.
- `R/run_income_years.qmd` lists 2014–2021 but not 2023, and its text refers to "the preschool place calculate file".
