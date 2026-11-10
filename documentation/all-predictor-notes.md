# Predictor notes

This file is built by `functions/documentation/combine_predictor_notes.R` from each predictor folder's `predictor-notes.md`. Edit those files, not this one.

# 01_employment-opportunities

```yaml
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
```

### Summary
Share of adults ages 25 to 54 who are employed, from American Community Survey (ACS) microdata via IPUMS, with 95 percent confidence intervals. The all files use the 1-year ACS; the subgroup files (race-ethnicity, gender, disability) use the 5-year ACS. Public Use Microdata Areas (PUMAs) are allocated to counties and places with the PUMA crosswalks.

### Process
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

### Data quality flag
- `share_employed_quality` is the crosswalk's `geographic_allocation_quality`, averaged over the records in the geography with `unweighted(mean())` (`R/calc_survey_mean.R`). The crosswalk sets it from `sum_products`: `1` if 0.75 or more, `2` if 0.35 or more, `3` otherwise (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`).
- Suppressed geographies (effective sample below 30) get `NA` for both the metric and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 16,042 are `3` (51 percent), and 5,191 are `NA`. Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.

### Missing values
- County all file: 488–544 counties a year (about 16–17 percent) are suppressed for an effective sample below 30. In 2014 and 2024, every suppressed county had a population of 15,000 or less (`county-populations.csv`).
- Place all file: South Fulton city, GA (1372122) in 2014–2021; no missing places from 2022 on.
- County subgroup files, pooled over the five years: Black, Non-Hispanic is missing for 64 percent of county-years, Hispanic for 60 percent, Other Races and Ethnicities for 63 percent, and White, Non-Hispanic for 4 percent. With Disability is missing for 31 percent; Female and Male for 5 percent each; All for 2 percent.
- Place subgroup files: Black, Non-Hispanic is missing for 18 percent of place-years; every other subgroup for 2 percent or less.

### Known issues
- The 2014 place subgroup files have noninteger quality flags (for example, 2.35) for 113 places: 528 rows in the race-ethnicity file, 339 in gender, and 338 in disability. `employment_metrics_place_sub.qmd` joins both the 2000-PUMA (`2k`) and 2010-PUMA (`2012`) crosswalk rows to the 2014 5-year sample, and `calc_survey_mean_subgroup()` averages `geographic_allocation_quality` across them.
- The flag reflects only how well PUMAs line up with the geography, not sample size: it is copied from the crosswalk (`R/calc_survey_mean.R`), and small samples are handled by suppression instead. Half of county all rows are quality `3`.
- The all files (1-year ACS) and subgroup files (5-year ACS) come from different samples, so the All rows in the subgroup files don't match the all files (in 2018, 3,091 of 3,143 county All values differ).

### Comparability across years
- No 2020: the all files skip 2020 (`existing_years`), so 2019 to 2021 is a two-year change.
- PUMA boundaries changed in 2022, and the crosswalk changes with them (`crosswalk_period`), so geographic allocation and quality flags can shift between 2021 and 2022.
- The subgroup files are 5-year estimates for 2014, 2016, 2018, 2021, and 2023; consecutive releases overlap in years.

### Open questions
- Only `employment_metrics_place_sub.qmd` was updated for the new crosswalk periods. `employment_metrics_county_all.qmd`, `employment_metrics_county_sub.qmd`, and `employment_metrics_place_all.qmd` still assign `crosswalk_period = "pre-2022"` and filter on it, but the crosswalk files now only have `2012`, `2k`, and `2022`. Re-running any pre-2022 year with those three files would match no PUMAs.
- The local fallback for intermediate files calls `write_csv(paste0(...))` with a path and no data (`employment_metrics_county_all.qmd`, and the same pattern in the other three), so runs without S3 access would fail at that step.
- The .qmd text says suppressed geographies get a quality flag of `3` and that the flag combines crosswalk quality with sample size; the code sets suppressed rows to `NA` and uses crosswalk quality only. The data dictionary in `employment_metrics_county_all.qmd` also says the bounds are a 90 percent interval; `survey_mean()` uses its 95 percent default.
- `data/raw/employment_opp_1year.dat.gz` (about 43 MB, an IPUMS extract) and its `.xml` are committed but not read by any code. IPUMS [terms of use](https://www.ipums.org/about/terms) limit redistribution. Should they be removed? `data/intermediate/county_puma.csv` and `puma_county.csv` are also committed and unused.
- `historical_comparison_employment_metric_county.qmd` reads `data/00_mobility-metrics_longitudinal.csv` and `data/01_mobility-metrics_race-ethnicity_longitudinal.csv`, which no longer exist. Is it still needed?

# 02_jobs-paying-living-wages

```yaml
metric: Jobs paying a living wage
predictor: 02_jobs-paying-living-wages
pillar: Rewarding Work
metric_lead: [Kevin Werner, Kassandra Martincheck, Aaron R. Williams]
variables: [ratio_living_wage, ratio_living_wage_quality]
geographies:
  county: 2014-2024
  place: none
subgroups: [industry]
confidence_intervals: false
code:
  - jobs-paying-living-wages.qmd
  - jobs-paying-living-wages_industry.qmd
final_files:
  - data/final/living_wage_county_all_longitudinal.csv
  - data/final/living_wage_county_industry_longitudinal.csv
sources:
  - name: Quarterly Census of Employment and Wages (QCEW), county high-level files
    provider: Bureau of Labor Statistics (BLS)
    vintage: 2014-2024 annual averages
    access: downloaded in code
    url: https://www.bls.gov/cew/downloadable-data-files.htm
  - name: Living Wage Calculator
    provider: Living Wage Institute (LWI, MIT)
    vintage: 2018 file, 2022 file, 2023 file, and Benchmark Series (delivered 2025-10-10)
    access: Box only, not publicly shareable
    url: https://livingwage.mit.edu/
  - name: Consumer Price Index for All Urban Consumers (CPI-U), annual averages
    provider: Bureau of Labor Statistics (BLS)
    vintage: 2014-2024
    access: hardcoded in the .qmd files
    url: https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm
crosswalks: [geographic-crosswalks/data/county-populations.csv]
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
```

### Summary
Average weekly wage of jobs in the county, from the Quarterly Census of Employment and Wages (QCEW), divided by the weekly living wage for one adult with two children, from the Living Wage Institute (LWI). A value above 1 means average pay covers the living wage. The industry file repeats the calculation for seven industry groups.

### Process
1. Save the four LWI files from Box to `data/living-wage/`: `mit-living-wage.csv` (2018), `mit-living-wage-2022.csv`, `mit-living-wage-2023.csv`, and `LWI-BenchmarkSeries-County-Urban Institute-2025-10-10.xlsx`.
2. Render `jobs-paying-living-wages.qmd` (all) and `jobs-paying-living-wages_industry.qmd` (industry), in either order. They don't depend on each other. Each downloads the annual QCEW files to `data/qcew/` if they aren't there.
3. QCEW: keep county rows, drop county `999` (unknown area), and convert zero wages and establishment counts to `NA`. The all file keeps `ownership == "Total Covered"`. The industry file maps QCEW codes to seven groups:
   - Goods Producing: `naics == 101`
   - Trade, Transit, Utilities: `1021`
   - Information Services: `1022`
   - Professional Services: `1023` (Financial Activities) and `1024` (Professional and Business Services)
   - Education and Health: `1025`
   - Leisure and Other: `1026` (Leisure and Hospitality) and `1027` (Other Services)
   - Public Administration: `naics == 10` with ownership `1`, `2`, or `3` (federal, state, and local government)

   Groups built from more than one code take the `mean()` of the weekly wages and the sum of the establishment counts.
4. Living wage: keep `1 Adult, 2 Children`. Weekly living wage = hourly wage × 40. Years without their own LWI file are filled from another one:
   - 2014–2018: the 2018 file, adjusted to each year with the CPI-U
   - 2019–2022: the 2022 file, adjusted to each year with the CPI-U
   - 2023: the 2023 file
   - 2024: the Benchmark Series file, relabeled `mutate(year = 2024)`
5. `inner_join()` QCEW and the living wage on year, state, and county, then `ratio_living_wage = annual_average_weekly_wage / weekly_living_wage`.
6. `left_join()` onto `county-populations.csv` (expanded to every industry group in the industry file) so every county-year has a row.
7. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/`.

### Data quality flag
- `1`: annual average establishment count is 30 or more
- `3`: fewer than 30
- `2` is never assigned.
- All file: 34,392 rows are `1` and 132 are `3`. Industry file: 214,239 are `1` and 60,508 are `3` (22 percent).

### Missing values
All file (the `All` rows of the industry file are the same):
- Kalawao County, HI (15005): every year
- All nine Connecticut planning regions (09110–09190): 2022–2024, so there are no Connecticut values in those years
- Chugach and Copper River, AK (02063, 02066): 2020–2022
- 02270 and 46113 (2014, FIPS codes later replaced)
- Adams County, IA (19003): 2015 and 2018
- Eureka County, NV (32011): 2023

Industry file, counties missing per year:
- Information Services: 690–777 a year through 2023, 874 in 2024
- Leisure and Other: 341–396 a year through 2023, 510 in 2024
- Public Administration: 271–332 a year through 2021, 126–143 from 2022 on
- Professional Services: 248–339
- Education and Health: 107–169
- Goods Producing: 24–36
- Trade, Transit, Utilities: 8–24

### Known issues
- The QCEW average weekly wage includes part-time jobs. QCEW employment counts "filled jobs, whether full or part time" ([BLS Handbook of Methods](https://www.bls.gov/opub/hom/cew/concepts.htm)); the old `documentation/overview.md` noted the same.
- Every industry group except All and Public Administration covers private-sector jobs only. In the QCEW county files, codes `101` and `1021`–`1027` exist only for private ownership (`own == 5`; checked in the 2014 and 2024 files), so public school and public hospital jobs count toward Public Administration, not Education and Health.
- Public Administration here means all government-owned jobs (QCEW [ownership codes](https://www.bls.gov/cew/classifications/ownerships/ownership-titles.htm) 1–3), not the QCEW supersector of the same name (`1028`, [industry titles](https://www.bls.gov/cew/classifications/industry/industry-supersectors.htm)).
- Groups built from more than one code use an unweighted `mean()` of the weekly wages (`jobs-paying-living-wages_industry.qmd`), so a small code counts as much as a large one. This applies to Professional Services, Leisure and Other, and Public Administration (federal, state, and local).
- Industry ratios have a long right tail: 36 county-industry-years are above 3, with a max of 11.5 (Information Services, county 30057, 2020, quality `3`).

### Comparability across years
- The 2024 living wage comes from a different LWI product (the Benchmark Series) than 2023.
- Within 2014–2018 and within 2019–2022, the living wage comes from one file, so changes within those blocks reflect wage growth and the CPI-U only.
- Public Administration has far fewer missing counties from 2022 on.

### Open questions
- The .qmd text lists the 2022 file only for 2021, but the code also uses it for 2019, 2020, and 2022.
- `living_wage_county_all_longitudinal.csv` and `living_wage_county_industry_longitudinal.csv` at the folder root only have 2014, 2018, and 2021–2023. They look like stale copies of the `data/final/` files.
- `scrape-living-wages.R` sources `01_employment-opportunities/get_living_wages.R`, which doesn't exist (`get_living_wages.R` is in this folder). Neither script is called by the .qmd files. Are they still needed?
- Why did Public Administration missing values drop in 2022, and why did missing values rise across industries in 2024?
- Can we get living wages for the Connecticut planning regions?

# 03_opportunities-for-income

```yaml
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
```

### Summary
The 20th, 50th (median), and 80th percentiles of household income for each county and for the 486 places, from American Community Survey (ACS) microdata, with 95 percent confidence intervals. The all files use 1-year ACS data. The subgroup files use 5-year ACS data and split households by the race and ethnicity or the sex of the householder.

### Process
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

### Data quality flag
- The flag is the crosswalk's `geographic_allocation_quality`: the sum over PUMAs of `afact × afact2` is 0.75 or more for `1`, 0.35 to 0.75 for `2`, and under 0.35 for `3` (`geographic-crosswalks/generate_puma_county_crosswalks.qmd`, `generate_puma_place_crosswalks.qmd`). It is the same for all three percentiles.
- Suppressed cells (effective sample under 30) get `NA` for the estimate and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 17,705 are `3` (63 percent of rows with an estimate), and 3,528 are `NA`.
- Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.
- County race-ethnicity file: 13,478 are `1`, 8,273 are `2`, 26,020 are `3`, and 30,809 are `NA`. County gender file: 8,469, 6,801, 30,399, and 1,479.
- Place race-ethnicity file: 3,105, 5,900, 2,401, and 744. Place gender file: 1,932, 3,825, 1,521, and 12.

### Missing values
- County all file: 342–362 counties a year (about 11 percent), all because their effective sample is under 30.
- All three place files: South Fulton city, GA (1372122) is missing for 2014–2021, in every subgroup. It appears only in the 2022 period of `crosswalk_puma_to_place.csv`.
- County subgroup files, `All` rows: 41–47 counties a year (5-year data has more sample than 1-year).
- County race-ethnicity file, counties missing per year: Black, Non-Hispanic 1,940–1,975; Hispanic 1,977–2,179; Other Races and Ethnicities 1,607–2,220; White, Non-Hispanic 64–83.
- County gender file: Female 129–142 and Male 112–130 counties a year.
- Place race-ethnicity file, places missing per year: Black, Non-Hispanic 92–129; Hispanic 11–46; Other Races and Ethnicities 3–54; White, Non-Hispanic 1–2.
- Confidence intervals: 77 estimates in the county race-ethnicity file and 3 in the place race-ethnicity file have an estimate but a missing lower or upper bound.

### Known issues
- The quality flag measures only how well PUMAs line up with the geography, not how precise the estimate is (`R/calc_income_quantiles.R` passes through `geographic_allocation_quality`). In the county race-ethnicity file, 44 rows have a 20th percentile under $5,000, as low as $21 (Hispanic, county 23019, 2023), and 35 of them are quality `1`.
- The all files and the subgroup files come from different ACS samples (1-year versus 5-year), so the `All` rows in the subgroup files don't match the all files: the medians agree in 267 of 13,941 county-years compared. For example, the 2023 median for Cook County, IL (17031) is $81,592 in the race-ethnicity file and $83,273 in the all file.
- Subgroups describe the householder only: each .qmd keeps `pernum == 1` before the race-ethnicity and gender variables are built (`income_metrics_county_sub.qmd` line 123, `income_metrics_place_sub.qmd` line 116; [PERNUM](https://usa.ipums.org/usa-action/variables/PERNUM)).
- Intermediate files keep the dollars they were built with. The final step binds the per-year files without re-adjusting them, so if `inflation_year` changes, every earlier year has to be rerun to stay in the same dollars.

### Comparability across years
- There is no 2020: `existing_years` skips it in both all .qmd files.
- PUMA boundaries change in 2022, and the code switches crosswalks at that year (`crosswalk_period`).
- The subgroup years are 5-year samples that overlap: 2014 (2010–2014), 2016 (2012–2016), and 2018 (2014–2018) share survey years, so changes between them are smaller than year-to-year changes in the all files.

### Open questions
- The .qmd files still use `crosswalk_period == "pre-2022"`, but on this branch `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` only have the periods `2k`, `2012`, and `2022` (changed in `ecaab286`, 2026-06-24, after these final files were built on 2026-03-03). Rerunning any pre-2022 year would find no matching crosswalk rows (`income_metrics_county_all.qmd` lines 410 and 434, and the same lines in the other three files). The crosswalk notes say the `2k` period is for pre-2012 ACS data (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` line 62), so the 2014 subgroup files (2010–2014 sample) could use it for their 2010–2011 records.
- `income_metrics_place_all.qmd` is committed with `single_year_update = "Yes"` (line 156), so a full render stops before writing the final file.
- Intermediate files are only written to S3 (`put_object()`); nothing writes them locally, so the local fallback in `read_intermediate()` has nothing to read without AWS access. In `income_metrics_county_all.qmd` the fallback path is also missing an underscore (`"metrics_income", file_type`, line 838).
- The county all .qmd text expects 50–200 suppressed counties a year (line 978) and says quality `3` "should be less common" (line 963); the final data have 342–362 suppressed counties a year, and `3` is the most common flag.
- `R/geocorr2018_2503500948.csv` isn't read by any file in the repo.
- `R/run_income_years.qmd` lists 2014–2021 but not 2023, and its text refers to "the preschool place calculate file".

# 04_financial-security

```yaml
metric: Share with debt in collections
predictor: 04_financial-security
pillar: Rewarding Work
metric_lead: [Manuel Alcalá Kovalski]
variables: [share_debt_coll, share_debt_coll_quality]
geographies:
  county: 2018, 2022, 2023, 2025
  place: 2019, 2021, 2023
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - county-debt-coll-shares.qmd
  - city-debt-coll-shares.qmd
final_files:
  - final/metrics_overall_debt_coll_all_county.csv
  - final/metrics_overall_debt_coll_race_ethnicity_county.csv
  - final/metrics_overall_debt_coll_all_city.csv
  - final/metrics_overall_debt_coll_race_ethnicity_city.csv
sources:
  - name: Debt in America (county-level overall debt files)
    provider: Urban Institute
    vintage: 2022 (June 2022 file), 2023 (July 2024 file), 2025 (November 2025 file)
    access: downloaded in code
    url: https://apps.urban.org/features/debt-interactive-map/
  - name: Debt in America, 2018 county file (legacy)
    provider: Urban Institute
    vintage: 2018
    access: committed CSV (final/share_debt_2018_long.csv), originally pulled by hand
    url: https://apps.urban.org/features/debt-interactive-map/
  - name: Financial Health and Wealth Dashboard (city file city_2019_23.csv)
    provider: Urban Institute
    vintage: 2019, 2021, 2023
    access: downloaded in code
    url: https://apps.urban.org/features/financial-health-wealth-dashboard/
  - name: Large place to PUMA match summary (place FIPS codes)
    provider: IPUMS USA
    vintage: 2010 PUMAs
    access: downloaded in code
    url: https://usa.ipums.org/usa/resources/volii/large_place_PUMA2010_match_summary.xlsx
crosswalks: []
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
```

### Summary
Share of people with a credit bureau record who have debt in collections, from Urban's Debt in America (counties) and Financial Health and Wealth Dashboard (cities). The race-ethnicity file splits each geography into neighborhoods of color and white neighborhoods, based on the racial makeup of zip codes, not each person's race. Medical debt in collections was removed in 2026.

### Process
1. Render `county-debt-coll-shares.qmd`. It downloads the Debt in America county files for 2022, 2023, and 2025 (overall and medical for 2023 and 2025) from the Urban Data Catalog and reads the 2018 values from `final/share_debt_2018_long.csv`, a file committed by hand that can't be pulled with code.
2. `process_debt_data()` builds `state` and `county` from the FIPS column, renames the year-specific share columns, drops `OID` rows, pivots to long format (All, Neighborhoods of color, White neighborhoods), converts `n/a*`, `n/a**`, and `NA` to missing, and sets `share_debt_coll_quality` to `1` when a value is present.
3. The county files combine 2018, 2022, 2023, and 2025 overall debt only; medical debt is processed for 2023 and 2025 but not written out.
4. Render `city-debt-coll-shares.qmd`. It reads `city_2019_23.csv` from the Urban Data Catalog, keeps the `delinquent_debt` column as `share_debt_coll`, and maps the Overall, Residents of color, and White subgroups to All, Neighborhoods of color, and White neighborhoods.
5. State FIPS codes come from `tigris::fips_codes`; place FIPS codes come from the IPUMS large place to PUMA match file, matched on city name, with six city labels fixed by hand. Cities with no place FIPS match are dropped (the code comment says 63).
6. 2022 is dropped from the city files because every value is missing.
7. Neither .qmd joins onto `county-populations.csv` or `place-populations.csv`. Each ends with `evaluate_final_data()` against its forms in `99a_final-evaluation/`.

### Data quality flag
- County: `1` when a value is present, `NA` when it's missing. `2` and `3` are never assigned. All file: 12,138 rows are `1` and 427 are `NA`.
- City: `1` when a value is present, `3` when it's missing. All file: 493 rows are `1` and 122 are `3`.
- The flag only marks missing values; it doesn't reflect sample size (`process_debt_data()` in `county-debt-coll-shares.qmd`, and the `if_else(is.na(share_debt_coll), 3L, 1L)` step in `city-debt-coll-shares.qmd`).

### Missing values
County, All rows (rows present in the file):
- 2018: 197 of 3,142 missing
- 2022: 78 of 3,137
- 2023: 80 of 3,143
- 2025: 72 of 3,143
- Neighborhoods of color are missing for 2,265–2,631 counties a year (72–84 percent); White neighborhoods for 236–493.

County rows absent from the file, compared with `county-populations.csv`:
- The nine Connecticut planning regions (09110–09190) are absent in 2022, 2023, and 2025. The files have the eight pre-2022 Connecticut counties (09001–09015) instead.
- 2022 also lacks 02063, 02066, 02105, 02230, 02275, 31113, and 48155, and has 02261, which isn't in the target file for 2022.

City:
- Only 203, 207, and 205 places in 2019, 2021, and 2023, out of 486 in `place-populations.csv`. Three place codes in the file aren't in the target file: 0620802, 2250115, and 5103000.
- All rows missing: 3 in 2019, 117 in 2021, 2 in 2023.
- Neighborhoods of color missing: 21, 121, and 24 places; White neighborhoods: 29, 130, and 38.

### Known issues
- The city and county measures aren't the same. The city file uses the dashboard's `delinquent_debt` column (`select(... share_debt_coll = delinquent_debt)` in `city-debt-coll-shares.qmd`), which the old `documentation/overview.md` describes as derogatory debt, including collections, charge-offs, repossessions, and foreclosures. The county measure is debt in collections only.
- Subgroups are based on the racial makeup of zip codes, not on each person's race: majority-white communities are zip codes where 50 percent or more of residents are non-Hispanic white ([Debt in America Technical Appendix 2025](https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2025/11/19/Debt%20in%20America%20Technical%20Appendix%202025.pdf)).
- Connecticut is reported on the old county boundaries. The credit bureau data provider hasn't updated to the planning regions, so Debt in America reports the 2021 county-equivalents (Technical Appendix 2025, linked above). In the final files, 2022–2025 have 09001–09015 and no planning regions.
- The final files don't follow the target geography files: no `left_join()` onto `county-populations.csv` or `place-populations.csv` in either .qmd, so county years have 3,137–3,143 rows instead of 3,142 or 3,144, and cities have about 200 of 486 places (row counts from the final CSVs).
- 2018 can't be reproduced. The .qmd reads a CSV committed by hand and notes "we don't have a programmatic way to pull this file and reproduce the quality flags" (`county-debt-coll-shares.qmd`, 2018 section).

### Comparability across years
- 2022 and 2023 on: Debt in America changed the threshold for communities of color and majority-white communities from 60 percent to 50 percent, so the race-ethnicity breakdowns aren't directly comparable across that break (Technical Appendix 2025, footnote 2). The All values aren't affected by the threshold.
- Earlier Debt in America editions used a 2 percent sample; the 2025 edition uses a 4 percent sample (Technical Appendix 2025).
- City values (2019, 2021, 2023) measure derogatory debt and county values (2018, 2022, 2023, 2025) measure debt in collections, so city and county values shouldn't be compared directly.
- Medical debt was removed in 2026 because the three nationwide credit reporting companies changed medical debt reporting starting in 2022, which lowered the share with medical debt on credit records but not necessarily the share with medical debt (`county-debt-coll-shares.qmd` overview; Technical Appendix 2025, footnote 6).

### Open questions
- The 2022 sample size is described two ways: the .qmd says 2 percent, and the old `documentation/overview.md` says 4 percent for February 2022. Which is right?
- Should both .qmd files join onto `county-populations.csv` and `place-populations.csv` so the files have 3,144 counties and 486 places per year? The three place codes not in `place-populations.csv` (0620802, 2250115, 5103000) would drop out.
- The subgroups describe neighborhoods but use `subgroup_type = "race-ethnicity"`. The README's subgroup table has a `race-share` type for neighborhood-based groups ("Majority Non-White", "Majority White, Non-Hispanic"). Which type should these use?
- Final files are in `final/`, not `data/final/` as in the README. `final/share_debt_2018.csv` isn't read by either .qmd, and `final/share_debt_2018_long.csv` is an input stored in the output folder.
- The county .qmd says the 2025 data are "from August 2025, released November 2024"; the 2025 file is dated November 2025 in its URL.
- The city .qmd says "There are four final files to be tested" but tests two.

# 05_wealth-building-opportunities

```yaml
metric: Housing value
predictor: 05_wealth-building-opportunities
pillar: Rewarding Work
metric_lead: [Manu Alcalá Kovalski]
variables:
  - ratio_black_nh_house_value_households
  - ratio_black_nh_house_value_households_quality
  - ratio_hispanic_house_value_households
  - ratio_hispanic_house_value_households_quality
  - ratio_other_nh_house_value_households
  - ratio_other_nh_house_value_households_quality
  - ratio_white_nh_house_value_households
  - ratio_white_nh_house_value_households_quality
geographies:
  county: 2014-2019, 2021-2024
  place: 2014-2019, 2021-2024
subgroups: [age]
confidence_intervals: false
code:
  - housing-value.qmd
final_files:
  - final/households_house_value_race_ethnicity_all_county.csv
  - final/households_house_value_race_ethnicity_subgroup_county.csv
  - final/households_house_value_race_ethnicity_all_city.csv
  - final/households_house_value_race_ethnicity_subgroup_city.csv
sources:
  - name: American Community Survey (ACS) 1-year microdata
    provider: IPUMS USA
    vintage: 2014-2019 and 2021-2024 (2020 excluded)
    access: API (ipumsr, needs IPUMS_API_KEY)
    url: https://usa.ipums.org/usa/
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
```

### Summary
For each racial or ethnic group, the group's share of a community's total home value divided by its share of the community's households. Home value counts homeowners only; the household share counts all households. A ratio of 1 means the group holds housing wealth in proportion to its share of households. Groups are Black non-Hispanic, Hispanic, other non-Hispanic, and white non-Hispanic. The subgroup files repeat the calculation by age (under 45, 45 and over).

### Process
1. Set `IPUMS_API_KEY`, then run the `query-ipums-api` chunk in `housing-value.qmd` (it has `eval: false`, so run it by hand the first time). It requests ACS 1-year samples `us2014a` through `us2024a` with `define_extract_usa()` and saves the extract to `05_wealth-building-opportunities/data/`. It only submits a request if that folder has no `.xml` file.
2. Set `microdata` in the `load-acs` chunk to the downloaded file name (currently `"usa_00337.xml"`), then render.
3. Clean: drop 2020, keep one row per household (`pernum == 1`), set `valueh` "Missing" and "N/A" to `NA`, drop group quarters, and pad FIPS codes.
4. Groups: the age subgroup uses the age of person 1 (`age >= 45`). Race and ethnicity collapse into `white_nh`, `black_nh`, `hispanic`, and `other_nh` (any Hispanic origin is `hispanic`; American Indian or Alaska Native, Asian, Pacific Islander, other race, and multiracial are `other_nh`).
5. Crosswalk: tag each year with `crosswalk_period` (`"pre-2022"` before 2022, `"2022"` after) and `right_join()` onto the PUMA crosswalks by state, PUMA, and period.
   - County: keep the ACS county when IPUMS identifies it; otherwise take the county from the crosswalk and multiply `hhwt` by `afact`. Old Connecticut counties are dropped for 2022.
   - Place: always multiply `hhwt` by `afact`.
6. Household share: weighted households in each group divided by all weighted households, by geography (and by age subgroup).
7. Housing value share: among households with `ownership == "Owned or being bought (loan)"`, `sum(valueh * hhwt)` for each group divided by the total for the geography.
8. Join the two, write the ratio as text (see Known issues), reshape wide with one column pair per group, and `right_join()` onto `county-populations.csv` or `place-populations.csv` (2020 dropped) so every geography-year has a row. Files are written to `final/`.
9. The .qmd ends with `evaluate_final_data()` against the four `evaluation_form_house_value_*` forms in `99a_final-evaluation/`.

### Data quality flag
- `1`: `population` > 30 and `sum_products` > 0.75 (more than 75 percent of the data comes from the geography itself)
- `2`: `population` > 30 and `sum_products` between 0.35 and 0.75
- `3`: `population` > 30 and `sum_products` 0.35 or less
- `NA`: `population` 30 or less, or no homeowners from the group in the sample. The ratio is set to `NA` wherever the flag is `NA`.
- County all file (white non-Hispanic columns): 5,669 rows are `1`, 4,524 are `2`, 21,226 are `3` (68 percent), and 8 are `NA`. Place all file: 1,000 are `1`, 2,563 are `2`, 1,230 are `3`, and 63 are `NA`.

### Missing values
County all file, geographies missing per year:
- Black non-Hispanic: 375–702
- Hispanic: 16–107
- Other non-Hispanic: 0–22 (none from 2021 on)
- White non-Hispanic: 0–3

Place all file, places missing per year: Black non-Hispanic 12–22; each other group 6–8.

Geographies with no values for any group (none of them has rows in the current PUMA crosswalks for those years):
- 02261 (2014–2019), 02270 and 46113 (2014)
- South Fulton, GA (1372122): 2018, 2019, and 2021

In the subgroup files, these geography-years have a single row with `subgroup` = `NA` instead of three rows. Under Age 45 is missing far more often than Age 45 and Over (for example, Black non-Hispanic county rows: 13,452 versus 6,967 across all years).

### Known issues
- The ratio columns are text, not numbers: each value is the group's housing value share and household share joined by a colon (for example, `0.781:0.687`). Divide the first by the second to get the ratio. Evidence: `construct_ratio()` in `housing-value.qmd` and the final CSVs.
- The quality flag doesn't use the group's sample size. `construct_quality_flag(population, sum_products)` uses `population` from the crosswalk, which is the geography's population, while the .qmd text describes N as the number of households in each group. `home_owners = n()` is computed but not used. As a result, the flag is the same for every group in a geography: in the final files, no row has two groups with different nonmissing flags.
- Place flags don't change across years. `place_quality` keeps one row per place with `distinct(state, place, .keep_all = TRUE)`, ignoring year, so each place gets one `sum_products` for every year even though the crosswalk changes in 2022. In the place all file, 0 of 480 places have a flag that changes across years.
- Home value is `valueh` only. Mortgage debt isn't subtracted, so the metric reflects gross home value, not equity (`house_value_by_race()` in `housing-value.qmd`).

### Comparability across years
- There is no 2020: the .qmd drops the 2020 1-year ACS, which the Census Bureau [released as experimental](https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2020/1-year.html).
- The PUMA crosswalk changes in 2022, from 2012 PUMAs to 2020 PUMAs, and Connecticut switches from 8 counties to 9 planning regions.
- The place files have 485 places in 2014–2017 and 486 from 2018 on, matching `place-populations.csv` (South Fulton, GA, is added in 2018).

### Open questions
- Since #606, the PUMA crosswalks use `crosswalk_period` values `"2012"`, `"2k"`, and `"2022"`, but `housing-value.qmd` still tags pre-2022 years as `"pre-2022"`. Re-rendering would drop every year before 2022. The final files were last committed 2026-05-12, before #606 merged.
- Should the quality flag use the group's sample size (`home_owners`), as the .qmd text describes?
- The place subgroup check calls `evaluate_final_data()` with `evaluation_form_house_value_age_county.csv`, but `evaluation_form_house_value_age_place.csv` exists.
- In the subgroup files, the `All` rows have `subgroup_type` = `"age"`, while other metrics use `"all"`.
- `R/finalize_metric.R` renames income percentile columns (`pctl_income_*`) and isn't sourced here; `06_access-to-preschool` has its own copy that it does source. `R/geocorr2018_2503500948.csv` isn't read by any code. Are both still needed?

# 06_access-to-preschool

```yaml
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
```

### Summary
Share of 3- and 4-year-olds who attend nursery school or preschool, from American Community Survey (ACS) 5-year microdata. The county and place files have 95 percent confidence intervals, and the subgroup files split the share by race and ethnicity and by household income (below $50,000 versus $50,000 or more).

### Process
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

### Data quality flag
- `NA` when `share_in_preschool` is `NA` (effective sample under 30).
- Otherwise the crosswalk's `geographic_allocation_quality`, based on `sum_products`, the share of the geography's records that come from PUMAs inside it (`generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`):
  - `1`: `sum_products` is 0.75 or more
  - `2`: 0.35 to under 0.75
  - `3`: under 0.35
- Sample size only enters through suppression; a geography just over 30 can still be a `1`.
- County all file: 2,823 rows are `1`, 2,242 are `2`, 2,991 are `3`, and 7,660 are `NA`. Place all file: 644 are `1`, 1,273 are `2`, 503 are `3`, and 10 are `NA`.

### Missing values
- Counties: about half are suppressed each year (1,491–1,568 of 3,143 or 3,144).
- Places: Kissimmee, FL (1236950) and Palm Coast, FL (1254200) in 2014; North Port, FL (1249675) and South Fulton, GA (1372122) in 2014–2021; none in 2023.
- County subgroups, missing per year: White, Non-Hispanic 1,803–1,856; Black, Non-Hispanic 2,913–2,957; Hispanic 2,835–2,863; Other Races and Ethnicities 2,858–2,953; $50,000 or More 1,879–2,138; Less than $50,000 2,247–2,619.
- Place subgroups, missing per year: White, Non-Hispanic 95–166; Hispanic 235–291; Black, Non-Hispanic 369–397; Other Races and Ethnicities 345–410; $50,000 or More 4–75; Less than $50,000 148–295.

### Known issues
- 3- and 4-year-olds in kindergarten count in the denominator as not in preschool, and any in first grade or higher are dropped (`filter(grade_attending %in% c("Nursery school/preschool", "N/A", "Kindergarten"))` in both .qmd files).
- A `gradeatt` of N/A (code 0) is treated as not in school; the .qmd text states this as an assumption.
- The 2014–2018 county rows use later county codes, not that year's: they have 02063 and 02066 instead of 02261, and 2014 also has 02158 and 46102 instead of 02270 and 46113 (compared with `county-populations.csv`). The county list comes from the PUMA crosswalk, not the target county file, so those years have 3,143 rows instead of 3,142.
- Confidence intervals come from replicate weights (`R/calc_survey_mean.R`), while the old `documentation/overview.md` described a normal-approximation formula.

### Comparability across years
- Each year is a 5-year ACS sample, so neighboring years overlap (for example, 2014 and 2016 share 2012–2014).
- The code joins 2014–2021 to the pre-2022 crosswalk period and 2023 to the 2022 period (2020 PUMAs), so the county and place allocation changes in 2023.
- Connecticut has its 8 old counties through 2021 and its 9 planning regions in 2023.

### Open questions
- `run_preschool_years.qmd` builds the county output name from `params$metric_name`, but the file has no `params`, so it errors as written.
- Without S3 access, both .qmd files write intermediate files to `data/intermediate/` but read them back from `data/intermediate/preschool/`, so a local run with `single_year_update = "No"` can't find its own files.
- The code sets `crosswalk_period` to `"pre-2022"` for years before 2022, but `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` now use `"2k"`, `"2012"`, and `"2022"`. Re-running 2014–2021 would drop every record at the crosswalk join.
- The place .qmd text says suppressed places get a quality flag of 3; the code sets them to `NA`.
- The place .qmd describes the metric as "in pre-K or higher" and the county .qmd as "enrolled in pre-K"; both compute nursery school or preschool only.
- Four files in `data/final/` aren't written by the code or read by `99_construct-database/`: `metrics_preschool_county_all_longitudinal.csv` (2014–2021), `metrics_preschool_place_all_longitudinal.csv` (2018 and 2021), `metrics_preschool_place_all_longitudinal_2014_16.csv`, and `metrics_preschool_place_race-ethnicity_longitudinal_2014_16.csv`. Are they still needed?

# 07_effective-public-education

```yaml
metric: Effective public education (English language arts learning growth)
predictor: 07_effective-public-education
pillar: High-Quality Education
metric_lead: [E Gutierrez, JP Walsh]
variables: [learning_rate, learning_rate_lb, learning_rate_ub, learning_rate_quality]
geographies:
  county: 2014-2019
  place: 2014-2019
subgroups: [race-ethnicity, gender, income]
confidence_intervals: true
code:
  - SEDA_metrics_race_county.qmd
  - SEDA_metrics_race_city.qmd
final_files:
  - Data/Final/seda_all_county.csv
  - Data/Final/seda_race_ethnicity_all_county.csv
  - Data/Final/seda_gender_all_county.csv
  - Data/Final/seda_income_all_county.csv
  - Data/Final/seda_all_city.csv
  - Data/Final/seda_race_ethnicity_all_city.csv
  - Data/Final/seda_gender_all_city.csv
  - Data/Final/seda_income_all_city.csv
sources:
  - name: Stanford Education Data Archive (SEDA) 6.0, county and geographic school district long files (seda_county_long_gcs_6.0.csv, seda_geodist_long_gcs_6.0.csv)
    provider: Stanford University
    vintage: version 6.0
    access: downloaded in code
    url: https://purl.stanford.edu/xh833nn4025
  - name: Common Core of Data (CCD) school district directory
    provider: National Center for Education Statistics (NCES), via Urban's Education Data Portal
    vintage: 2008-2019
    access: API (educationdata R package, get_education_data()), city file only
    url: https://educationdata.urban.org/documentation/
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
```

### Summary
Average annual learning growth in English language arts (ELA) between third and eighth grade, from the Stanford Education Data Archive (SEDA). The metric is the slope of a cohort's mean test scores across grades, so 1 means a cohort gains about one grade level per year. County estimates come from SEDA's county file. City estimates come from SEDA's school district file, aggregated to cities. Final files are in `Data/Final/` (capital D and F), not `data/final/`.

### Process
1. Render `SEDA_metrics_race_county.qmd` (county) and `SEDA_metrics_race_city.qmd` (city), in either order. Both write raw downloads to `Data/Raw/`, which isn't in the repo, so create it first.
2. SEDA: download the county file (county .qmd) or the geographic school district file (city .qmd) if it isn't in `Data/Raw/`. Keep `subject == "rla"`, define `cohort = year - grade + 8` (the year the cohort reaches eighth grade), and keep cohorts from 2015 on.
3. City only: download the CCD district directory for 2008–2019 with `get_education_data(level = "school-districts", source = "ccd", topic = "directory")`. Join SEDA districts to CCD on `leaid` and year, fill each district's `city_location` across years, and `inner_join()` to `place-populations.csv` on lowercased city name and state. Ten place names are hand-edited to match CCD spellings (for example, "Boise City" becomes "Boise"). Districts that never match a place are dropped.
4. For each subgroup and cohort, run a regression of mean score on grade interacted with county (or district), weighted by the number of test-takers: `lm(score ~ grade:factor(sedacounty) + factor(sedacounty), weights = n_students)`. The grade slope is `learning_rate`; the bounds are the slope ± 1.96 standard errors. Slopes that are exactly 0 with bounds of 0 are set to `NA`.
5. City only: aggregate district estimates to cities with a weighted mean using each subgroup's test-taker counts. The rate, both bounds, and the quality flag are each averaged this way; the quality flag is then rounded.
6. `year = cohort - 1`. Join to `county-populations.csv` or `place-populations.csv` for 2014–2019 and expand so every geography has a row for every subgroup.
7. Split into all, race-ethnicity, gender, and income files and write them with `data.table::fwrite()`. Each split calls `evaluate_final_data()` first, but see Open questions.

Subgroups, by SEDA code:
- `all`: All
- `wht`, `blk`, `hsp`: White, Non-Hispanic; Black, Non-Hispanic; Hispanic
- `mal`, `fem`: Male, Female
- `ecd`, `nec`: Economically Disadvantaged, Not Economically Disadvantaged

### Data quality flag
- `1`: five or more grades in the estimate and at least 30 test-takers in every grade
- `2`: four or more grades and at least 30 test-takers in every grade
- `3`: any other nonmissing estimate
- City flags are the rounded, test-taker-weighted mean of the district flags.
- County all file: 14,294 rows are `1`, 2,242 are `2`, 1,613 are `3`, and 703 are missing. City all file: every nonmissing row (2,459) is `1`.

### Missing values
County all file (3,142 counties each year):
- 87, 79, 76, 93, 170, and 198 counties missing in 2014–2019; 52 counties are missing in all six years.
- All 62 New York counties are missing in 2018 and 2019 (11 in 2017).
- All Alaska boroughs and census areas are missing in 2019.
- Nebraska, Texas, Montana, and North Dakota each have 7–17 missing counties every year. Colorado has 5–6 through 2017 and 22–26 in 2018–2019.

City all file (486 places each year):
- 72, 72, 70, 73, 84, and 86 places missing in 2014–2019; 69 places are missing in all six years.
- 26 of 37 Florida places are missing every year, and Urban Honolulu (Hawaii's only place) is missing every year.
- New York places (7) are missing in 2018 and 2019; Anchorage is missing in 2019.

Subgroups, share missing per year:
- County race-ethnicity: Black, Non-Hispanic 58–60 percent; Hispanic 52–54 percent; White, Non-Hispanic 7–11 percent.
- County gender: 6–10 percent. County income: Economically Disadvantaged 6–10 percent; Not Economically Disadvantaged 10–17 percent.
- City subgroups: 14–29 percent, close to the city All rate except Black, Non-Hispanic (22–29 percent).

### Known issues
- The race-ethnicity files have no Other Races and Ethnicities rows. Both .qmd files build `gcs_mn_oth` (Asian and Native American combined), but `oth` isn't in `subgroups <- c("all", "wht", "blk", "hsp", "nec", "ecd", "mal", "fem")`, and `99_construct-database/test_file_updates.R` expects "Other Races and Ethnicities" when it checks these files.
- City confidence bounds are test-taker-weighted means of the district bounds (`aggregate_to_cities()` in `SEDA_metrics_race_city.qmd`), not intervals estimated for the city.
- City quality flags carry little information: rounding the weighted mean of district flags puts every nonmissing row of `seda_all_city.csv` at `1`.
- A city includes only districts whose CCD `city_location` matches the place name, so districts serving a city but located under another name are left out (`inner_join()` on `city_name` and `state` in `SEDA_metrics_race_city.qmd`).
- County rates go below zero in 27 county-years (min −1.55); 26 of them are quality `3`.

### Comparability across years
- Each year is a different cohort: `year` = the year the cohort reaches eighth grade, minus 1, and the estimate uses that cohort's scores from grades 3–8.
- New York (2018–2019) and Alaska (2019) drop out entirely, which changes the set of counties behind any state or national comparison in those years.

### Open questions
- Both .qmd files call `evaluate_final_data()` with forms in `10a_final-evaluation/`, which doesn't exist; the forms are in `99a_final-evaluation/`. The city chunks use `#| error: true`, so the check fails silently; the county all-file chunk doesn't, so the county render stops there.
- `Data/Raw/` isn't in the repo or `.gitignore`. The code doesn't create it, and the downloaded raw files would show up as untracked files.
- The text at the top of both .qmd files is out of date: it says years "2013 - 2017" (county) or "2013 - 2018" (city), "Uses MEPS," "Uses 2014-2024 data," and the county file says it "Produces city level data." The code produces 2014–2019 ELA learning rates.
- Both .qmd files point to https://edopportunity.org/get-the-data/seda-archive-downloads/ for SEDA, which returns 404. The SEDA 6.0 archive is at https://purl.stanford.edu/xh833nn4025.
- The end year is hardcoded (`config$current_year = 2020`). Does SEDA 6.0 support years after 2019?
- Should Florida and Hawaii cities be matched another way (e.g., by place geography instead of district city name)?

# 08_school-economic-diversity

```yaml
metric: Share of students attending high-poverty schools, by race and ethnicity
predictor: 08_school-economic-diversity
pillar: High-Quality Education
metric_lead: [E Gutierrez, JP Walsh]
variables: [share_meps20_black, share_meps20_black_quality, share_meps20_hispanic, share_meps20_hispanic_quality, share_meps20_white, share_meps20_white_quality]
geographies:
  county: 2014-2022
  place: 2014-2022
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - MEPS_metric_county.qmd
  - MEPS_metric_city.qmd
final_files:
  - data/final/meps_county_2014-2022.csv
  - data/final/meps_place_2014-2022.csv
sources:
  - name: Common Core of Data (CCD), school enrollment by race and ethnicity (grade 99, all grades)
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022 (school years 2014-15 through 2022-23)
    access: API (educationdata R package), cached to data/raw/ccd_enr_2014-2022.rds
    url: https://educationdata.urban.org/documentation/schools.html
  - name: Common Core of Data (CCD), school directory
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022
    access: API (educationdata R package), cached to data/raw/ccd_dir_2014-2022.rds
    url: https://educationdata.urban.org/documentation/schools.html
  - name: Model Estimates of Poverty in Schools (MEPS)
    provider: Urban Institute
    vintage: 2014-2022
    access: local Stata file data/raw/Abrv Set of Portal Variables.dta, internal Urban file not in the repo
    url: https://www.urban.org/research/publication/model-estimates-poverty-schools
crosswalks: [geographic-crosswalks/data/county-populations.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
```

### Summary
Share of Black, Hispanic, and White students in the county or city who attend a school where 20 percent or more of students live in poverty. School poverty comes from the Urban Institute's Model Estimates of Poverty in Schools (MEPS), the modeled share of students with family incomes at or below 100 percent of the federal poverty level ([MEPS report](https://www.urban.org/sites/default/files/2022-06/Model%20Estimates%20of%20Poverty%20in%20Schools.pdf)). There is no value for all students.

### Process
1. Put the MEPS file `Abrv Set of Portal Variables.dta` in `data/raw/`. It isn't in the repo and isn't downloaded in code. The commented-out code that pulls MEPS from the Education Data Portal API is still in both .qmd files.
2. Render `MEPS_metric_county.qmd` and `MEPS_metric_city.qmd`, in either order. They don't depend on each other. The first one to run downloads the Common Core of Data (CCD) enrollment and directory files for 2014–2022 from the Education Data Portal and caches them as `.rds` files in `data/raw/`; the second reads the cache. The enrollment download is large and slow.
3. The years are hardcoded as `year_ed = 2022` and `year_meps = 2022`. The `year: "2025"` parameter in the YAML header isn't used.
4. Enrollment: keep `grade = 99` (all grades), set negative counts to `NA`, sum by school and race, and reshape wide by race.
5. Join the CCD directory (total enrollment, county code, and city name) to the race enrollment and to MEPS by `year` and `ncessch`. Set negative directory enrollment to 0, then drop schools with missing or zero enrollment.
6. Flag a school as high poverty when `meps_poverty_pct / 100 >= 0.20`. For each race, the numerator is that race's enrollment in flagged schools.
7. Geography:
   - County: drop schools with county code `-2`, then sum numerators and enrollment by year, state, and county.
   - City: lowercase the CCD `city_location` and match it to the place name in `place-populations.csv`, after removing " city", " town", " municipality", " village", and " urban county" and renaming 10 cities by hand (for example, "Louisville/Jefferson County metro government (balance)" to "louisville"). The state comes from the school's county code.
8. Share = numerator / enrollment for Black, Hispanic, and White students, set to `NA` when the group's enrollment is 0. `left_join()` onto the county or place file.
9. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/` (`evaluation_form_meps_overall_county.csv`, `evaluation_form_meps_overall_place.csv`) and writes `data/final/meps_<geography>_2014-2022.csv`.

### Data quality flag
Based on the group's total enrollment in the county or city:
- `1`: 30 or more students
- `2`: 15 to 29 students
- `3`: fewer than 15 students

County file (28,282 rows):
- Black: 18,585 are `1`, 2,927 are `2`, and 5,943 are `3` (21 percent)
- Hispanic: 24,412 are `1`, 1,727 are `2`, and 1,961 are `3`
- White: 27,946 are `1`, 170 are `2`, and 127 are `3`

City file (4,370 rows): all but 18 Black, 3 Hispanic, and 3 White values are `1`.

### Missing values
County file:
- No values in any year: Kalawao County, HI (15005); Issaquena County, MS (28055); Buffalo County, SD (46017); and Loving County, TX (48301)
- Black: 87–106 counties a year, set to `NA` because the county has no Black students enrolled
- Hispanic: 15–27 counties a year
- White: the four counties above, plus 55078 (2020), and 01063 and 13061 (2021)

City file, all three variables missing:
- Urban Honolulu, HI (1571550) and Indianapolis, IN (1836003): every year
- Lee's Summit, MO (2941348) and O'Fallon, MO (2954074): 2014–2019
- Mount Pleasant, SC (4548535): 2014–2017
- South Fulton, GA (1372122): 2018–2022 (and not in the file for 2014–2017, so those years have 485 rows)
- St. Paul, MN (2758000): 2021–2022
- 2015 only: all 15 Illinois cities, plus Charleston and North Charleston, SC (4513330, 4550875). 2015 has 22 missing cities, compared with 3–5 in other years.

### Known issues
- Cities are matched by name, not by location. The city .qmd joins on the lowercased CCD `city_location`, so a school counts toward a city when its address city matches, whether or not it's inside the city boundary, and spelling differences drop cities. Examples checked against the Education Data Portal API: St. Paul schools are "SAINT PAUL" in 2021 and the place file has "St. Paul"; Lee's Summit schools are "LEES SUMMIT" in 2018; "Urban Honolulu CDP" and "Indianapolis city (balance)" aren't covered by the name cleaning.
- In 2015, 4,239 of the 4,241 Illinois schools in the CCD directory have `city_location = "-1"` (checked via the Education Data Portal API; in 2016 Chicago schools have "Chicago"), which is why all Illinois cities are missing in 2015.
- Schools without a MEPS value count as not high poverty. Their enrollment stays in the denominator, but `numerator` is `NA` and the county sum uses `na.rm = TRUE`. In the last render (`MEPS_metric_county.html`), 30,164 school-years had no MEPS value, and only 90–93 percent of directory schools matched MEPS each year.
- There is no "All" value and no Other Races and Ethnicities group. `meps20_total` is computed but dropped by `select()`. The final files are wide (one column per race), not the long `subgroup_type`/`subgroup` format, and are checked with `subgroups = FALSE`.
- Many values are exactly 0 or 1: 37 percent of county Black values, 34 percent of Hispanic, and 32 percent of White. Most quality `3` rows are 0 or 1 (4,419 of 5,943 for Black).
- Neither .qmd filters on school type, so every school in the CCD directory with enrollment counts, whatever its type.

### Comparability across years
- `year` is the fall of the school year: 2014 is the 2014–15 school year and 2022 is 2022–23.
- 2022 county rows use Connecticut's nine planning regions (09110–09190), as in `county-populations.csv`; earlier years use the eight old counties.
- The average county share falls every year from 2014 to 2020 and then rises in 2021 (Black students: 53 percent in 2014, 30 percent in 2020, and 37 percent in 2021; the other groups follow the same pattern).
- Illinois cities have no 2015 values (see Known issues).

### Open questions
- Where does `Abrv Set of Portal Variables.dta` come from, and who has it? The .qmd says it's temporary internal data while the Education Data Portal is updated. The portal API now returns MEPS for 2014–2022 (checked for one school), so the commented-out API code could replace the local file.
- The .qmd text says the MEPS merge "is good outside of years 2021 and 2022", but the rendered match rates for 2021 and 2022 (91 percent) are similar to other years.
- `filter(sex != 99)` and the note above it ("Add the number of enrolled male and female students") don't do anything: the race endpoint only returns `sex = 99` (Total) rows, and with `add_labels = TRUE` the value is the label "Total", which never equals 99.
- The histogram is titled "MEPS mod poverty pct share" but plots `meps_poverty_pct` (100 percent of the federal poverty level), not `meps_mod_poverty_pct`.
- `filter(!year %in% c(2023))` has no effect, since the data only go through 2022.
- Is the 2014–2020 decline and the 2021 rise a real change in school poverty, or a change in MEPS or CCD inputs?
- Should cities be built from school locations (latitude and longitude or a place code) instead of address city names?

# 09_preparation-for-college

```yaml
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
```

### Summary
Share of 19- and 20-year-olds with a high school diploma or General Educational Development (GED) credential, from American Community Survey (ACS) 5-year microdata. The subgroup files repeat the calculation by race and ethnicity, gender, and disability status.

### Process
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

### Data quality flag
- The flag is the crosswalk's `geographic_allocation_quality` for the geography, averaged over its records (`calc_survey_mean_college.R`). It measures how much of the geography's data comes from PUMAs that lie mostly inside it (`sum_products` in `geographic-crosswalks/generate_puma_county_crosswalks.qmd`):
  - `1`: `sum_products` of 0.75 or more
  - `2`: 0.35 to 0.75
  - `3`: under 0.35
- Sample size doesn't enter the flag. Small cells are `NA` instead, and their flag is `NA` too.
- The flag is the same for every subgroup in a geography-year (checked in all six subgroup files).
- County all file: 2,822 rows are `1`, 2,241 are `2`, 3,601 are `3`, and 7,052 are `NA`. Place all file: 643 are `1`, 1,266 are `2`, 500 are `3`, and 21 are `NA`.

### Missing values
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

### Known issues
- Counties that share the same PUMAs get the same estimate. In the county all file, 2,426 of 8,664 nonmissing rows (28 percent) have the same value and confidence interval as at least one other county in the same year (data check). For example, Coshocton and Guernsey counties, OH (39031, 39059), are both 0.655 in 2016.
- Some subgroup values are exactly 1 with a confidence interval of 1 to 1, because every sampled person has a diploma and the replicate weights then give no variance (data check): 173 rows in the county race-ethnicity file (103 of them Other Races and Ethnicities), 21 in county gender, 9 in county disability, and 112, 16, and 6 in the place files. Mountain View, CA (0649670) is 1 for All in 2014.
- The quality flag reflects crosswalk fit only, not sample size (`calc_survey_mean_college.R` takes `geographic_allocation_quality` and nothing else). The old `documentation/overview.md` described a flag that also set small samples to `3`.
- The 2014–2018 county rows use later FIPS codes: 02063, 02066, 02158, and 46102 instead of 02261, 02270, and 46113. That gives 3,143 counties a year, while `county-populations.csv` has 3,142 for those years (data check). The county list comes from the crosswalk, not from `county-populations.csv`.
- Low values: the lowest county value is Highlands County, FL (12055), 0.633 in 2014; the lowest place values are Flint, MI (0.633 in 2023) and Yakima, WA (0.661 in 2014).

### Comparability across years
- The years are overlapping 5-year samples: 2014 (2010–2014), 2016 (2012–2016), 2018 (2014–2018), 2021 (2017–2021), and 2023 (2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)). Nonoverlapping pairs are 2014 and 2021, 2016 and 2021, 2014 and 2023, 2016 and 2023, and 2018 and 2023.
- 2023 uses 2020 PUMAs and the 2022 crosswalk period. Place quality flags shift sharply: 125 places are `3` in 2021 and 7 in 2023.
- Connecticut uses its eight old counties through 2021 and its nine planning regions (09110–09190) in 2023.

### Open questions
- The PUMA crosswalks now have `crosswalk_period` values `2k`, `2012`, and `2022` (since #606), but both .qmd files still assign `"pre-2022"`. Rerunning any year before 2022 would match no PUMAs; in the county .qmd, `county_list` would also be empty and the row-count check would fail. The crosswalk notes say 2012 PUMAs cover 2012–2021 ACS data and 2000 PUMAs cover earlier years, so the 2014 5-year sample (2010–2014) may need both.
- The .qmd text says suppressed counties get a quality flag of `3`, but the code sets their flag to `NA`.
- Intermediate files are only written to S3, and only if the file isn't already there, so a rerun of the same year doesn't overwrite it. Without S3, `read_intermediate()` reads local files that nothing writes, with a different name (`metrics_education_*` instead of `metrics_college_*`) and folder (`data/intermediate/preschool/` for counties, `data/intermediate/college/` for places).
- `run_college.qmd` renders 2014–2021 but not 2023, while both .qmd files list 2023 in `existing_years`. Its text also refers to the preschool place file.
- `programs/` holds the old English Language Arts (ELA) Stata code (`SEDA_metrics_race_county.do`, `SEDA_metrics_race_city.do`) and `SEDA Final Data Evaluation.qmd`. They read and write `09_preparation-for-college/data/built/`, which doesn't exist, and the ELA metric now lives in `07_effective-public-education/` as .qmd files. Can they be removed?
- The rendered `college_metrics_county.html`, `college_metrics_place.html`, and `programs/SEDA Final Data Evaluation.html` are committed next to the .qmd files. Are they still needed?

# 10_digital-access

```yaml
metric: Share of households with broadband access
predictor: 10_digital-access
pillar: High-Quality Education
metric_lead: [Ridhi Purohit]
variables: [share_digital_access, share_digital_access_quality]
geographies:
  county: 2018, 2021, 2023
  place: 2018, 2021, 2023
subgroups: [race_ethnicity, income]
confidence_intervals: false
code:
  - digital_access/digital_access_ver2025.qmd
  - digital_access/explore_digital_access.qmd
final_files:
  - data/final/digital_access_county_all_longitudinal.csv
  - data/final/digital_access_county_race_ethnicity_longitudinal.csv
  - data/final/digital_access_county_income_longitudinal.csv
  - data/final/digital_access_place_all_longitudinal.csv
  - data/final/digital_access_place_race_ethnicity_longitudinal.csv
  - data/final/digital_access_place_income_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 5-Year microdata
    provider: IPUMS USA
    vintage: 2014-2018 (us2018c), 2017-2021 (us2021c), and 2019-2023 (us2023c) 5-year samples
    access: API, through ipumsr (IPUMS_API_KEY required)
    url: https://usa.ipums.org/usa/
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
```

### Summary
Share of households that have high-speed (broadband) internet installed and a desktop, laptop, or tablet computer, from the 5-year American Community Survey (ACS) microdata. Each year is the last year of a 5-year sample (2018 is 2014–2018). Subgroups are the race and ethnicity of the householder and household income (less than $50,000, or $50,000 or more).

### Process
1. Render `digital_access/digital_access_ver2025.qmd`. It is the only production file. `explore_digital_access.qmd` is the 2017–2021 exploration that justified the household universe; it doesn't write any data.
2. The first run downloads the three IPUMS extracts (`us2018c`, `us2021c`, `us2023c`) to `data/raw/ipums/` with a local `get_ipums_extract()` function (`ipumsr::define_extract_micro()`). It only downloads if that folder is empty. On a rerun, edit the three hardcoded file names (`usa_00022.xml`, `usa_00023.xml`, `usa_00024.xml`) to match your own extract numbers.
3. Keep the householder (`PERNUM == 1`) and households (`GQ` 1, 2, or 5). Drop households with `CINETHH == 0` and, for 2023, `CIHISPEED == 88` (suppressed by IPUMS for some Public Use Microdata Areas, or PUMAs).
4. `DIGITAL_ACCESS` is `1` when `CIHISPEED == 10` and `CILAPTOP` or `CITABLET` is `1`, and `0` when `CIHISPEED == 20`. Every other household (no internet subscription, or broadband without a computer) is `NA`. It is left out of the numerator but kept in the denominator, so it counts as no access.
5. Race and ethnicity: Hispanic if `HISPAN` is not "Not Hispanic"; otherwise Black, White, or Other Races and Ethnicities from `RACE`. Income: `HHINCOME` below or at least $50,000.
6. Crosswalks: `right_join()` the microdata onto the PUMA-to-county and PUMA-to-place crosswalks by state, PUMA, and `crosswalk_period` (Puerto Rico is dropped from the county crosswalk).
   - County: if IPUMS identifies the county (`COUNTYFIP != "000"`), the household keeps its county, its full weight, and `sum_products = 1`. Otherwise it is assigned to every county its PUMA overlaps, with `HHWT * afact` and the crosswalk's `sum_products`.
   - Place: every household gets `HHWT * afact` and the crosswalk's `sum_products`.
7. Share = weighted households with `DIGITAL_ACCESS == 1` divided by all weighted households. Geographies and subgroups with fewer than 30 records are set to `NA`.
8. The county race and ethnicity file is missing Black, Non-Hispanic rows for counties with no Black, Non-Hispanic households in 2021 and 2023; the code adds them back as `NA`.
9. Add the `All` rows to the subgroup files, run `evaluate_final_data()` against the six forms in `99a_final-evaluation/evaluation_form_digital_access_*.csv`, and write the six files to `data/final/`.

### Data quality flag
- `1`: 30 or more records and `sum_products` of 0.75 or more (at least 75 percent of the records come from the geography)
- `2`: 30 or more records and `sum_products` from 0.35 to 0.75
- `3`: 30 or more records and `sum_products` below 0.35
- `NA`: fewer than 30 records (the value is also `NA`)
- County, All: 560 rows are `1`, 454 are `2`, and 2,129 are `3` (68 percent) in both 2018 and 2021; 583, 451, and 2,110 in 2023.
- Place, All: 101 are `1`, 259 are `2`, and 125 are `3` in both 2018 and 2021; 240, 239, and 7 in 2023.
- Subgroup rows get the same flag as their geography's All row, except where the subgroup has fewer than 30 records.

### Missing values
All files:
- No county or place All rows are missing.
- Place 1372122 (South Fulton, GA) has no rows in 2018 or 2021 (485 places). The 2012 PUMA-to-place crosswalk has 485 places and doesn't include it.

County race and ethnicity file, `NA` rows per year (out of 3,143 or 3,144):
- Black, Non-Hispanic: 1,351 (2018), 1,351 (2021), 1,328 (2023)
- Hispanic: 448, 349, 243
- Other Races and Ethnicities: 211, 21, 7
- White, Non-Hispanic: none

Place race and ethnicity file, `NA` rows per year (out of 485 or 486):
- Black, Non-Hispanic: 37, 34, 31
- Hispanic: 4, 2, 1
- Other Races and Ethnicities: 3, 2, 1

Income files: none missing.

### Known issues
- Most counties don't have their own value. IPUMS only identifies counties with large enough populations (`COUNTYFIP`, [IPUMS](https://usa.ipums.org/usa-action/variables/COUNTYFIP)); the rest get the value of the PUMA they're in. In every year, 2,529 or more counties (80 percent) share their exact value with at least one other county, in groups of up to 24 (data check on `digital_access_county_all_longitudinal.csv`).
- The 30-record threshold counts records after the crosswalk join (`n()` in the `create-effective-sample-county` and `create-effective-sample-place` chunks), so every record in a PUMA counts toward each county or place it overlaps, however small the overlap. No county or place All row falls below 30.
- The subgroup quality flag ignores subgroup sample size above 30. `create_quality_metric()` joins the geography's `sum_products` to every subgroup, so the flag tallies are the same for every subgroup except where it's `NA` (data check).
- 2018 rows use the counties in the 2012 PUMA-to-county crosswalk, not the 2018 target counties: they include 02063 and 02066 (Chugach and Copper River, created in 2019) instead of 02261 (Valdez-Cordova), which `county-populations.csv` lists for 2018 (data check).
- `subgroup_type` is `race_ethnicity` (underscore), and the file names use `race_ethnicity` too. The other predictors use `race-ethnicity` (e.g., `03_opportunities-for-income`, `09_preparation-for-college`).
- Outlier: Black, Non-Hispanic households in place 0622230 have a share of 0.036 in 2021, compared with 0.28 in 2018 and 0.31 in 2023, with quality `1` in all three years.

### Comparability across years
- Years are 5-year samples that overlap: 2018 (2014–2018) and 2021 (2017–2021) share 2017 and 2018.
- 2018 and 2021 use 2010 PUMAs and the 2012 crosswalks; 2023 uses 2020 PUMAs and the 2022 crosswalks. IPUMS assigns 2020 PUMAs to every year of the 2019–2023 sample ([PUMA](https://usa.ipums.org/usa-action/variables/PUMA)). The PUMA change moves many places to better quality flags: place quality `3` drops from 125 to 7.
- Connecticut uses its eight old counties in 2018 and 2021 and its nine planning regions in 2023.
- Part of 2023 is affected by the `CIHISPEED` suppression for some PUMAs, which the code drops ([IPUMS comparability notes](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)).

### Open questions
- The code sets `crosswalk_period` to `"pre-2022"` for 2018 and 2021 and filters on it in the evaluation chunks, but since #606 the crosswalks only have `2k`, `2012`, and `2022`. A rerun for 2018 or 2021 matches no PUMAs and the geography checks fail. Should it use `"2012"`?
- The rendered `digital_access_ver2025.html` (2 MB) and `explore_digital_access.html` (1.4 MB) are committed. Are they still needed?
- The code comments in the geography checks say "385 counties" (2018 and 2021) and "386 counties" (2023) where they mean 485 and 486 places. The checks themselves are right.
- Should South Fulton, GA, get 2018 and 2021 values (it isn't in the 2012 PUMA-to-place crosswalk), and should the 2018 Alaska counties match the 2018 target file?
- Should years other than 2018, 2021, and 2023 be added?

# 11_housing-affordability

```yaml
metric: Housing affordability
predictor: 11_housing-affordability
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Will Curran-Groome]
variables:
  - share_affordable_30_ami
  - share_affordable_50_ami
  - share_affordable_80_ami
  - share_affordable_available_30_ami
  - share_affordable_available_50_ami
  - share_affordable_available_80_ami
  - share_affordable_30_ami_quality
  - share_affordable_50_ami_quality
  - share_affordable_80_ami_quality
  - share_affordable_available_30_ami_quality
  - share_affordable_available_50_ami_quality
  - share_affordable_available_80_ami_quality
geographies:
  county: 2014-2019, 2021-2024
  place: 2014-2019, 2021-2024
subgroups: [tenure]
confidence_intervals: false
code:
  - ratio_housing_affordable_available.qmd
  - quality-checks/ratio_housing_affordable_available_comparison.qmd
final_files:
  - data/final/housing_county_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024.csv
  - data/final/housing_county_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024_subgroups.csv
  - data/final/housing_place_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024.csv
  - data/final/housing_place_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024_subgroups.csv
sources:
  - name: American Community Survey (ACS) 1-year microdata, occupied and vacant housing units
    provider: IPUMS USA
    vintage: 2014-2019, 2021-2024 1-year samples (usYYYYa)
    access: API (ipumsr, requires an IPUMS API key)
    url: https://usa.ipums.org/usa/
  - name: Section 8 income limits (area median income thresholds)
    provider: US Department of Housing and Urban Development (HUD)
    vintage: FY2014-FY2019, FY2021-FY2024
    access: downloaded in code
    url: https://www.huduser.gov/portal/datasets/il.html
  - name: Connecticut town to planning region crosswalk
    provider: CT Data Collaborative
    vintage: 2022 planning regions
    access: downloaded in code
    url: https://raw.githubusercontent.com/CT-Data-Collaborative/ct-town-to-planning-region/refs/heads/main/ct-town-to-planning-region.csv
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
  - geographic-crosswalks/data/geocorr2018_county_place_2014_thru_2019.csv
  - geographic-crosswalks/data/geocorr2022_county_place_2020_2021.csv
  - geographic-crosswalks/data/geocorr2022_county_place_2022_onwards.csv
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
```

### Summary
Two ratios for each county and city, at three income thresholds (30, 50, and 80 percent of area median income, or AMI): housing units affordable at that threshold per household at or below it, and units affordable *and available* (vacant, or occupied by a household at or below the threshold) per household at or below it. A unit is affordable when 12 months of housing costs are at or below 30 percent of the threshold. Each ratio is reported for all households, owners, and renters.

### Process
1. Set `geography` (`county` or `place`) and the years in the .qmd `params`, and render once per geography. The years must be 2014–2019 or 2021–2024 (`stopifnot()`, line 164).
2. **Optional AWS S3 cache**: if the `mobility-from-poverty-test` bucket is reachable, the IPUMS extracts, HUD income limits, and final files are read from and written to S3 (`housing-affordability/data/`). Without credentials, everything is downloaded and kept in `data/temp/`.
3. Pull two IPUMS USA extracts, each covering all missing years in one API call, from ACS 1-year samples (`us{year}a`): occupied housing (rectangular, all persons) and vacant units (hierarchical, `GQ == 0`). Files are split by year into `data/temp/`. The first pull takes about an hour.
4. Occupied units: join `crosswalk_puma_to_{geography}.csv` by state and Public Use Microdata Area (PUMA), filtered to the year's `crosswalk_period`. Multiply `HHWT` and `PERWT` by `afact`, and `HHINCOME`, `RENT`, `RENTGRS`, and `OWNCOST` by `ADJUST`. Recode IPUMS missing codes to `NA` (`OWNCOST == 99999`, `RENT`/`RENTGRS == 0`, `VALUEH == 9999999`). Keep one row per household (`PERNUM == 1`) and drop group quarters (`GQ < 3`).
5. Vacant units: keep `VACANCY` 1–3 (for rent, for sale, rented or sold but not occupied).
   - For sale: monthly cost = a 30-year mortgage on 90 percent of `VALUEH` at 0.5 percent monthly interest, plus private mortgage insurance of 0.7 percent of the loan a year, plus taxes equal to 25 percent of principal and interest (lines 634–643).
   - For rent: `RENTGRS = RENT ×` the `HHWT`-weighted mean of `RENTGRS / RENT` among occupied rentals in the same geography and year.
6. AMI thresholds: download the HUD Section 8 income limits for each fiscal year and use the four-person limits `eli_4`, `l50_4`, and `l80_4` as the 30, 50, and 80 percent thresholds.
   - Sub-county limits (New England) are averaged within each county.
   - From 2022, Connecticut towns are mapped to the nine planning regions with the CT Data Collaborative crosswalk.
   - Valdez-Cordova (02261) limits are copied to Chugach (02063) and Copper River (02066) for years after 2019.
   - Places: population-weighted mean of county limits, using a county-place crosswalk built in memory from the three GeoCorr county-place files (2014–2019, 2020–2021, and 2022 on; lines 931–987).
7. Indicators: a household is below a threshold if `HHINCOME` is at or below it. An occupied unit is affordable if 12 × `RENTGRS` (renters) or 12 × `OWNCOST` (owners) is at or below 30 percent of the threshold, and available if it's also occupied by a household below that threshold. Every affordable vacant unit counts as available.
8. Sum weighted counts by geography and year, then:
   - affordable ratio = (affordable occupied + affordable vacant) / households below the threshold
   - affordable and available ratio = (available occupied + affordable vacant) / households below the threshold
9. Suppress and flag (see Data quality flag), pivot to long by tenure (`All`, `Owner`, `Renter`), and drop South Fulton, GA (13 72122) for 2018–2021 because the 2010-based PUMA-to-place crosswalk predates it (line 1377). Write the all file (`All` rows only) and the subgroups file for the geography; the file name lists the years.
10. Checks: `evaluate_final_data()` against the two housing forms in `99a_final-evaluation/`, plus `test_that()` checks on geography counts, no ratios at or below 0, no state with only `NA` values, and available ratios never above affordable ratios. It also tests that every value matches the May 2025 Urban Data Catalog files within 1e-10 (line 1765), plots 2023 differences from those files, and plots county values against the National Low Income Housing Coalition (NLIHC) *The Gap* 2024 estimates.
11. Optional: `quality-checks/ratio_housing_affordable_available_comparison.qmd` plots the 2023 values from the previous release against the updated ones.

`23_safety-from-crime` and `24_just-policing` read `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv` (2021–2024 rows), which `geographic-crosswalks/generate_county_place_crosswalks.qmd` builds (#648). The same script writes `geocorr2022_county_place_2022_onwards.csv`, which this .qmd reads. This .qmd doesn't use that file; it builds its county-place crosswalk in memory.

### Data quality flag
- A cell is suppressed (`NA`) when the count of sampled households below that threshold, for that tenure group and weighted only by `afact`, is under 30 (lines 1176 and 1278). The same count is used for the affordable and the affordable and available ratios, so their missing values are identical.
- Otherwise the flag is the mean `geographic_allocation_quality` of the PUMAs mapped to the geography (line 428). From `geographic-crosswalks/generate_puma_*_crosswalks.qmd`:
  - `1`: the sum over PUMAs of (share of the PUMA in the geography × share of the geography in the PUMA) is 0.75 or more
  - `2`: 0.35 to 0.75
  - `3`: below 0.35
- The flag reflects PUMA fit only; small samples are suppressed instead of flagged. Within a row, all six quality columns have the same value.
- County, `All`, 80 percent AMI: 5,665 rows are `1`, 4,528 are `2`, 12,748 are `3` (56 percent of nonmissing), and 8,492 are missing.
- Place, `All`, 80 percent AMI: 1,424 are `1`, 2,529 are `2`, 896 are `3`, and 4 are missing. Places flagged `3` drop from 125 a year (2014–2021) to 7 a year (2022–2024), when the 2020 PUMAs start.

### Missing values
Rows: counties have 3,143 rows a year through 2021 and 3,144 from 2022 (nine Connecticut planning regions instead of eight counties), matching `county-populations.csv` except in Alaska and South Dakota:
- 2014–2019 have Chugach (02063) and Copper River (02066) instead of Valdez-Cordova (02261). A code comment says this is for continuity (line 1503).
- 2014 has Kusilvak (02158) and Oglala Lakota (46102) instead of the older codes 02270 and 46113.

Places have 485 rows a year through 2021 and 486 from 2022: South Fulton, GA isn't in the place list for 2014–2017 and is dropped for 2018–2021.

Counties missing a value, per year (out of 3,143–3,144; the affordable and available ratios have the same counts):

| Subgroup | 30 percent AMI | 50 percent AMI | 80 percent AMI |
|---|---|---|---|
| All | 1,511–1,592 | 1,237–1,377 | 804–890 |
| Owner | 1,971–2,146 | 1,645–1,871 | 1,125–1,323 |
| Renter | 2,335–2,435 | 2,195–2,264 | 1,909–1,968 |

- 741 counties are missing the `All` 80 percent AMI ratio every year. In 2024, the states with the highest share of counties missing it are South Dakota (76 percent), North Dakota (75 percent), Nebraska (72 percent), Montana (66 percent), Alaska (60 percent), and Kansas (59 percent).
- Chugach and Copper River, AK (02063, 02066): every year. Kusilvak, AK (02158): 2014–2021. Oglala Lakota, SD (46102): 2014–2017.

Places missing a value, per year (out of 485–486):
- `All`: 28–45 at 30 percent AMI, 2–12 at 50 percent, 0–1 at 80 percent.
- `Owner`: 168–239 at 30 percent, 30–93 at 50 percent, 0–6 at 80 percent.
- `Renter`: 146–169 at 30 percent, 62–84 at 50 percent, 19–34 at 80 percent.
- Four large places are missing every value, for every subgroup, in one year: Quincy, MA (2019), Simi Valley, CA (2022), Bellflower, CA (2023), and Norwalk, CA (2024).

### Known issues
- **Re-runs before 2022 match no PUMAs.** The code filters the PUMA crosswalk to `crosswalk_period == "pre-2022"` (line 401) and labels vacant units the same way (line 645). Since #606, `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` only have `2k`, `2012`, and `2022` (checked).
- **Vacant units aren't split across geographies.** Occupied units' weights are multiplied by `afact` (line 504), but vacant units are joined to the PUMA crosswalk (line 711) and summed with `HHWT` alone (line 1193). A vacant unit in a PUMA that spans several counties or places counts in full in each, which raises both ratios where PUMAs are split.
- Every household and unit is compared with the four-person limit; there's no adjustment for household size or number of bedrooms (`eli_4`, `l50_4`, `l80_4` at lines 816–818; the .qmd's Analysis notes say the same).
- The variables are named `share_` but are ratios and can be above 1. The code keeps the name for consistency with earlier releases (comment at line 1353).
- Long right tail: 2,277 county rows have at least one ratio above 3. The highest are 5.78 (`Owner`, 30 percent AMI, county 38015, 2019, quality `2`) and 4.95 for `All` at 80 percent AMI (county 20117, 2019, quality `3`). At the low end, four place `Renter` rows have an affordable and available 30 percent AMI ratio below 0.01 (lowest: 48 42508, 2015).
- Rendering edits committed files: before calling `evaluate_final_data()`, the code overwrites the year row of the two housing forms in `99a_final-evaluation/` with the years being run (lines 1440–1454).

### Comparability across years
- PUMAs change in 2022: 2010 PUMAs through 2021 and 2020 PUMAs from 2022. Place quality flags shift with them (places flagged `3` drop from 125 to 7).
- No 2020 estimates, because of the quality of the 2020 ACS 1-year data (comment at line 751).
- Connecticut has eight counties through 2021 and nine planning regions from 2022, so Connecticut county values can't be compared across 2021 and 2022.
- For-sale vacant unit costs use the same mortgage assumptions every year (0.5 percent monthly interest, 10 percent down, 0.7 percent mortgage insurance, taxes at 25 percent of principal and interest), so changes in actual mortgage rates aren't reflected.

### Open questions
- Why are Quincy, Simi Valley, Bellflower, and Norwalk missing every value in one year each? They're large places with values in the neighboring years.
- Chugach and Copper River are missing every year. Is that small samples, or a join problem with the Valdez-Cordova income limits?
- Should vacant unit weights be multiplied by `afact`, as occupied units' are?
- `quality-checks/ratio_housing_affordable_available_comparison.qmd` reads the previous release from a `main` URL that returns 404 (`data/final/housing_{geo}_2014_..._2023_subgroups.csv`). That file now lives in `quality-checks/quality-check-data/nobedadj_nohhsizeadj/`.
- The rendered `ratio_housing_affordable_available_county.html` and `ratio_housing_affordable_available_place.html` at the folder root were last changed in 8f8af851. Are they still needed next to `ratio_housing_affordable_available.html`?

# 12_housing-stability

```yaml
metric: Students experiencing homelessness
predictor: 12_housing-stability
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Manuel Alcalá Kovalski]
variables: [count_homeless, count_homeless_lb, count_homeless_ub, share_homeless, count_homeless_quality, share_homeless_quality]
geographies:
  county: 2014-2022
  place: 2014-2022
subgroups: [race-ethnicity]
confidence_intervals: true
code:
  - homelessness.qmd
  - run_homelessness.R
final_files:
  - data/final/homelessness_2014-2022_county.csv
  - data/final/homelessness_2014-2022_city.csv
  - data/final/homelessness_2019-2022_subgroups_county.csv
  - data/final/homelessness_2019-2022_subgroups_city.csv
sources:
  - name: EdFacts LEA homeless students enrolled files (Data Group 655)
    provider: US Department of Education
    vintage: school years 2014-15 to 2018-19
    access: downloaded in code
    url: https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy2014-15.csv
  - name: EdDataExpress, FS118 homeless students enrolled (Data Group 655), LEA files
    provider: US Department of Education
    vintage: school years 2019-20 to 2021-22 (downloaded in code); 2022-23 (manual download or Box)
    access: downloaded in code for 2019-2021; manual download or Box (Metrics_2025_round) for 2022
    url: https://eddataexpress.ed.gov/download/data-builder/data-download-tool
  - name: Common Core of Data (CCD) school district directory and enrollment by race
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022
    access: API (educationdata R package)
    url: https://educationdata.urban.org/documentation/school-districts.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
```

### Summary
Number and share of public school students who experienced homelessness at some point during the school year, from EdFacts counts reported by local education agencies (LEAs, i.e., school districts) divided by Common Core of Data (CCD) enrollment. Year `2014` is school year 2014–15. Race and ethnicity subgroups start in 2019.

### Process
1. Render `run_homelessness.R`, which renders `homelessness.qmd` twice: `geography = "county"` and `geography = "place"`, both with `years = 2014:2022`. Each render writes the all file and, because 2019 and later are in `years`, the subgroup file.
2. Before rendering, save the 2022–23 file by hand as `data/raw/2022-23 LEA homeless student data.csv`. It comes from the EdDataExpress data download tool (Level: Local Education Agency; School Year: 2022–2023; Population: Homeless Students; set the other filters before State) or from Box (`Metrics_2025_round`). The .qmd has step-by-step instructions. The 2014–2021 files are downloaded to `data/raw/` if they aren't there.
3. CCD: pull the school district directory (`leaid`, `county_code`, `city_location`, `enrollment`) for each year from the Education Data Portal API. For 2019 and later, also pull enrollment by race (`grade = 99`, `sex = 99`, the all-grades and both-sexes totals) and combine Asian, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, and two or more races into `enroll_other`.
4. Homeless counts: keep Data Group 655 and the all-students and race rows. Each LEA count of `"S"` (suppressed, 0–2 students) becomes 1, with a lower bound of 0 and an upper bound of 2. If a state-year has two or fewer suppressed LEAs, the upper bound is the smallest count in that state-year instead, because of complementary suppression. For 2019 and later, the Other group is the sum of the four smaller race groups.
5. `inner_join()` homeless counts to CCD on year and `leaid`. Negative or missing enrollment becomes 0, and LEAs with 0 enrollment get 0 homeless students.
6. Aggregate to the geography:
   - County: by the LEA's CCD `county_code`
   - Place: by the LEA's CCD `city_location`, title-cased, matched to the crosswalk place name with " city", " town", " village", " municipality", and " urban county" removed, plus eight hardcoded name fixes (e.g., Nashville, Louisville, Boise)
7. Share = count / enrollment. Race shares divide by race-specific enrollment (e.g., Black homeless students / Black enrolled students).
8. Quality flag, then the suppression rules (see Missing values), then `left_join()` onto `county-populations.csv` or `place-populations.csv` so every geography-year has a row.
9. `evaluate_final_data()` runs against the four `evaluation_form_homeless_student_*.csv` forms in `99a_final-evaluation/`.

### Data quality flag
Based on the ratio of the upper to the lower bound of the count (`calc_quality()` in `homelessness.qmd`):
- `1`: ratio of 1.05 or less
- `2`: more than 1.05 and up to 1.1
- `3`: more than 1.1, or (All only) total enrollment under 30, or a total homeless count of 10–29 (this last rule sets every subgroup's flag to 3)
- `NA`: the value is suppressed
- `share_homeless_quality` is always the same as `count_homeless_quality`.

Tallies:
- County all file: 17,549 rows are `1`, 618 are `2`, 3,984 are `3`, and 6,131 are `NA`. Of the `3`s, 3,766 (95 percent) come from a total count of 10–29.
- Place all file: 3,713 are `1`, 16 are `2`, 63 are `3`, and 578 are `NA`.
- County subgroup file, `3`s: from 1,665 (Black) to 3,962 (Other Races and Ethnicities) of 12,572 rows per group.

### Missing values
Values are suppressed when:
1. the total homeless count is under 10 (every metric for that geography-year)
2. a share is above 1 (that group)
3. the four race groups add up to less than 70 percent or more than 110 percent of the total (all race groups)
4. a count is 2 or less after aggregation (that group)

Because of rule 1, a geography with no homeless students is missing, not 0. The smallest share in either all file is 0.08 percent.

County all file, missing per year: 788 (2014), 756, 703, 665, 619, 665, 695, 642, and 598 (2022), about 22 percent of county-years overall.
- 379 counties are missing every year. They're concentrated in the Plains: Nebraska (65), Kansas (37), South Dakota (37), North Dakota (33), Texas (26), Iowa (23), and Montana (22).
- Share of county-years missing: Nebraska 80 percent, North Dakota 73 percent, South Dakota 71 percent.
- Hawaii: only Honolulu County (15003) has values. The other four Hawaii counties are missing every year.
- Vermont: all 14 counties are missing in 2017, and 0–10 are missing in the other years.

Place all file, missing per year: 71 (2014), 69, 66, 64, 62, 62, 62, 64, and 58 (2022).
- 56 places are missing every year: 24 in Florida (e.g., Hialeah, St. Petersburg, Cape Coral, Pembroke Pines), 6 in California, 5 in Georgia (Johns Creek, Roswell, Sandy Springs, South Fulton, Warner Robins), 3 each in Colorado, Nevada (Henderson, North Las Vegas, Sparks), and Utah, 2 each in Michigan, Minnesota (St. Paul, Woodbury), and South Carolina, and Urban Honolulu, Indianapolis, Newton (MA), High Point (NC), Goodyear (AZ), and Cedar Park (TX).
- 20 more places are missing in some years.

Subgroup files, missing per year (2019–2022):
- County: All 598–695, White 939–1,111, Other 1,296–1,519, Hispanic 1,381–1,578, Black 1,637–1,775
- Place: All 58–64, Hispanic 77–84, White 84–92, Black 80–89, Other 80–101
- 1,101 county-years and 30 place-years have an All value but no race values (rule 3).

### Known issues
- Each LEA's homeless count and enrollment go to one county and one city: the ones in its CCD directory record (`county_code` and `city_location` in the `merge-aggregate` chunk). Districts that cross county or city lines aren't split.
- City values only include districts whose CCD city matches the city name, so cities served by a countywide district get no value. Of the 56 places missing every year, 24 are in Florida, where "each county shall constitute a school district" ([Florida Constitution, Article IX, Section 4](https://www.flsenate.gov/Laws/Constitution#A9S04)).
- Two place names never match because the name cleaning doesn't handle them: "Urban Honolulu CDP" (" CDP" isn't removed) and "Indianapolis city (balance)" (" city" isn't at the end, and there's no hardcoded fix). Both are missing every year (data check).
- Hawaii has one statewide LEA, so all Hawaii students are assigned to Honolulu County (data check: only 15003 has values).
- `count_homeless_lb` and `count_homeless_ub` are bounds from suppressed LEA counts, not statistical confidence intervals. The share has no bounds.
- The upper bound for Other Races and Ethnicities understates uncertainty. The four groups are summed after each `"S"` becomes 1, and `supp_other` is only set when the sum equals exactly 1 (`process-suppression` chunk). So two suppressed groups give `other = 2` with `other_lb = other_ub = 2`, although the true value could be 0–4.
- Subgroup quality flags don't account for small subgroup counts. The suppression and quality rules based on the homeless count use the total count, and the enrollment-under-30 rule only applies to All. Five county-year Black shares equal exactly 1 (counts of 3–11, in Tennessee, Illinois, and Minnesota counties), and three of them are quality `1`.
- Large outliers: 9 county-years have a share above 0.5, with a max of 0.89 (Mora County, NM, 2021). In 2017, Refugio, Calhoun, and Jefferson counties in Texas are 0.58–0.68, and Beaumont, TX (4807000) is 0.92 (17,711 students, compared with 487–1,659 in other years).
- From a script, the 2014–2018 `www2.ed.gov` URLs return an Azure WAF JavaScript challenge (HTTP 403, checked 2026-11-04), so `download.file()` would save an HTML page instead of the CSV on a fresh run. The 2019–2021 EdDataExpress zip URLs return 200.

### Comparability across years
- 2014–2018 counts come from the EdFacts CSV files and 2019–2022 from EdDataExpress. Both are Data Group 655.
- Race and ethnicity subgroups only exist from 2019 on.
- Connecticut has 8 counties through 2021 and 9 planning regions in 2022, so the county file has 3,144 rows in 2022 (matching `county-populations.csv`).
- Place files have 485 rows for 2014–2017 and 486 from 2018 on (South Fulton, GA added), matching `place-populations.csv`.
- The 2026 R translation reproduces the earlier Stata files (removed in d5d72c44) closely. Of 22,148 county-years with values in both, 188 have shares that differ by more than 0.001. 3 county-years and 9 place-years have values now that were missing before, and none went the other way.

### Open questions
- Is 2023–24 data out on EdDataExpress yet? The .qmd says it wasn't as of February 2026.
- Why are all Vermont counties missing in 2017? The raw files aren't in the repo, so this couldn't be checked.
- Do St. Paul, St. Petersburg, and Port St. Lucie fail to match because CCD spells them "Saint"? They're missing every year.
- Should Urban Honolulu and Indianapolis get name fixes, like the eight already in the code?
- Are the 2017 Texas Gulf Coast values (Beaumont, Refugio, Calhoun, Jefferson) students displaced by Hurricane Harvey? If so, a note in the footnotes may help.
- The rendered `homelessness-county.html` and `homelessness-place.html` are committed at the folder root. Are they still needed?
- Should the 2014–2018 downloads move to a URL that works from a script, or to Box?

# 13_economic-inclusion

```yaml
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
```

### Summary
Share of people in poverty in a county or city who live in census tracts where more than 40 percent of people are in poverty. A value of 0 means no one in poverty lives in a high-poverty tract; a value of 1 means everyone in poverty does. The race-ethnicity files repeat the calculation for four groups.

### Process
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

### Data quality flag
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

### Missing values
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

### Known issues
- Most counties are exactly 0: 2,393–2,513 a year (76–80 percent) in the all file. In cities, 200–262 a year (41–54 percent) are 0. Checked in the final files.
- Values of exactly 1 occur in 2–8 counties a year, mostly in South Dakota (Corson 46031, Mellette 46095, Todd 46121, Ziebach 46137, which are 1 in most years). In the city race-ethnicity file, Black exposure is 1 in Pharr, TX (4857200) in 2021, with quality `3`. Checked in the final files.
- The race-ethnicity groups overlap. Black (B17001B), the five groups in Other Races and Ethnicities (B17001C–G), and Hispanic (B17001I) are race-alone or ethnicity tables, so Hispanic people are also counted in a race group. Only White, Non-Hispanic (B17001H) excludes Hispanic people. The labels in the files are "Black" and "Hispanic" (`recode()` in both .qmd files; the [ACS 5-year variable list](https://api.census.gov/data/2021/acs/acs5/variables.html) gives the table titles).
- The city CVs are on a different scale from the county CVs. The county standard error is `sqrt(sum(moe^2)) / 1.645`; the city standard error is `sqrt(sum(afact * moe^2))`, without dividing by 1.645 (`places_summary` in `poverty-exposure-city.qmd`). The [Census Bureau worked examples](https://www2.census.gov/programs-surveys/acs/tech_docs/accuracy/2018_ACS_Accuracy_Document_Worked_Examples.pdf) convert MOEs to standard errors with 1.645.
- The suppression threshold is applied to the weighted estimate of people in poverty (`suppress_county(race = poverty, ...)` and `suppress_place()`), not to an unweighted sample count.
- The tract cache isn't refreshed when `years` changes. Both .qmd files only call the API `if (!file.exists("13_economic-inclusion/data/tracts.csv"))`, so a new year is silently skipped unless the cached file is deleted first.
- A city tract counts as high poverty based on the whole tract's rate, even when only part of the tract is in the city (stated in `poverty-exposure-city.qmd`, step 3).

### Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (for example, 2010–2014 and 2012–2016). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2014–2018 use 2010 tract boundaries and 2021–2023 use 2020 boundaries, so which tracts cross the 40 percent line can change between 2018 and 2021 because of the redrawn tracts alone.
- City values for 2014–2018 come from a 2010-tract-to-2014-place crosswalk and later values from a 2020 crosswalk.
- Connecticut: the 2014–2021 county files use the eight old counties, and 2023 uses the nine planning regions (09110–09190), so there are 3,144 county rows in 2023.

### Open questions
- `R/census_api_key.R` is not in `.gitignore`. The ignore rules cover `R/census_api_key.R` at the repo root and `06_neighborhoods/R/census_api_key.R`, an old folder name, so a key added here as Process step 1 says could be committed. `13_economic-inclusion/data/` (the cached tract files) isn't ignored either.
- The county .qmd text says the latest data is the 2017–2021 ACS, but the code pulls through 2019–2023.
- The city .qmd says it suppresses estimates "with thirty or fewer unweighted observations", but the code uses the weighted poverty count. It also describes the place allocation as areal interpolation by area overlap, but the Geocorr crosswalks carry population columns (`pop10`, `pop20`); check which weighting the crosswalks used.
- The city .qmd says there are 485 cities through 2014–2018, but `place-populations.csv` has 486 in 2018 (South Fulton). Should the city all file be joined onto `place-populations.csv` like the other files, so 2018 has a row for South Fulton?
- `R/get_vars.R` is sourced by both .qmd files, but `get_vars()` is never called. Is it still needed?
- The county check that the summed tract poverty rates match the published county rates is `eval: false` and noted as failing for two New York counties (36103, 36111).

# 14_racial-diversity

```yaml
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
```

### Summary
For four race-ethnicity groups (Black, Non-Hispanic; Hispanic; Other Races and Ethnicities; and White, Non-Hispanic), the share of the average group member's census tract neighbors who belong to one of the other three groups. A value near 1 means the average group member lives in tracts made up almost entirely of other groups; a value of 0 means the group lives only in tracts made up entirely of its own group. Each group is its own column (wide format); there is no "All" value.

### Process
1. Make sure a Census API key is set as `CENSUS_KEY` (for example in `~/.Renviron`). The line that sources `R/census_api_key.R` is commented out in both .qmd files (county line 52, city line 57), so the key has to be set already. `R/census_api_key-template.R` shows how.
2. Set `years` in both .qmd files (now `c(2016, 2018, 2021, 2023)`, county line 172 and city line 175). Each year is the end year of an ACS 5-year sample. Add the year's DP05 variable codes to the `variable_mapping` tribble; the codes change across years.
3. Render `race-ethnicity-exposure-county.qmd` and `race-ethnicity-exposure-city.qmd`, in either order. Whichever runs first pulls tract data for every state and DC (not Puerto Rico) through `R/get_vars.R` and caches it in `data/tracts.csv` (about 30 minutes); the other reads the cache. `get_vars()` adds total population (B01003_001) from `acs/acs5` to the DP05 counts from `acs/acs5/profile`.
4. Tracts: set controlled margins of error (MOEs, coded `-555555555`) for Hispanic to 0. Build Other Races and Ethnicities as the sum of the non-Hispanic American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races counts. Its MOE combines the group MOEs, keeping only the largest MOE among groups with a zero estimate. A check confirms the four groups add up to total population in every tract. The city .qmd also drops tracts with no people (line 207).
5. For each tract, compute the share of the county's (or place's) group members who live there, and the share of the tract that belongs to the other three groups.
6. Exposure = the weighted mean of the tract's other-groups share, weighted by the tract's share of the group (for example, `share_black_nh_exposure = weighted.mean(non_black_nh, w = share_of_black_nh)`).
   - County: tracts are grouped by their county code.
   - City: tracts are allocated to places with the GeoCorr tract-to-place allocation factor `afact`. 2016 and 2018 use the 2010-tract-to-2014-place crosswalk, 2021 the 2020 crosswalk, and 2023 the 2020 crosswalk with Connecticut tracts recoded to the planning regions. Only places in `place-populations.csv` are kept, then the result is `left_join()`ed onto that list so every place-year has a row.
7. Suppress (set to `NA`) a group's exposure when the group's estimated count in the county or place is 30 or less, then assign the quality flag.
8. The county .qmd checks that it has the same number of counties per year as `county-populations.csv`. The city .qmd compares interpolated place totals with the totals the API reports for places directly.
9. Write `final/race-ethnicity-exposure-county.csv` and `final/race-ethnicity-exposure-city.csv`. The Testing chunk at the end then runs `evaluate_final_data()` against `99a_final-evaluation/evaluation_form_share_race_exposure_overall_county.csv` and `evaluation_form_share_race_exposure_overall_place.csv`, but it reads the final file from the wrong path (see Known issues).

### Data quality flag
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

### Missing values
Both files have one row for every county and place in `county-populations.csv` and `place-populations.csv` for the four years: 3,142 counties in 2016 and 2018, 3,143 in 2021, and 3,144 in 2023 (nine Connecticut planning regions); 485 places in 2016 and 486 from 2018.

County file, counties missing per year:
- Black, Non-Hispanic: 441–474. Of these, 92–104 a year have no Black, Non-Hispanic residents (checked in `data/tracts.csv`); the rest have 30 or fewer. 281 counties are missing in all four years.
- Hispanic: 87–98 (30 counties in all four years)
- Other Races and Ethnicities: 111 (2016), 108 (2018), 65 (2021), 48 (2023)
- White, Non-Hispanic: Kalawao County, HI (15005) every year, and Kenedy County, TX (48261) in 2021 and 2023 (1 and 2 White, Non-Hispanic residents)

City file:
- South Fulton, GA (1372122): every group in 2018. It's in `place-populations.csv` from 2018 but not in the 2010-tract-to-2014-place crosswalk; the city .qmd says so.
- Pharr, TX (4857200): Black, Non-Hispanic in 2016 and 2018

### Known issues
- **The Testing chunks read the final files from a path that doesn't exist.** Both .qmd files read `here::here("14_racial-diversity", "final", "final", ...)` (county lines 887–888, city lines 1179–1180), so a full render stops before `evaluate_final_data()` runs. The predictor migration (cc436c22) introduced the doubled `final`; the earlier path was `06_neighborhoods/race-ethnicity-exposure/final/`.
- **The Census API key file can be committed by accident.** `.gitignore` only covers `R/census_api_key.R` at the repo root and `06_neighborhoods/R/census_api_key.R` (lines 257–258), not `14_racial-diversity/R/census_api_key.R` (`git check-ignore` returns nothing). No key has been committed.
- **The tract cache is committed and isn't refreshed when `years` changes.** `data/tracts.csv` (24 MB, 314,926 rows) is tracked in git, and both .qmd files only call the API `if(!file.exists(...))` (county line 174), so a new year is silently skipped unless the file is deleted first.
- The city quality flag uses CV only, although the city .qmd lists three dimensions (unweighted observations, CV, and tract-place overlap, line 976). `afact_sum_product` is computed (line 690) but never used, and suppression uses the weighted group estimate, not an unweighted count (`suppress_place(black_nh, ...)`, line 1010).
- Values near the extremes are common: 914 county-years have Black, Non-Hispanic exposure above 0.99, and 1,276 have White, Non-Hispanic exposure below 0.05. Five county-years have White, Non-Hispanic exposure of exactly 0 (Petroleum County, MT, 30069 in 2016; Blaine County, NE, 31009 in 2018, 2021, and 2023; Billings County, ND, 38007 in 2021), all quality `1`. Checked in the final file.
- The county final file isn't sorted by year, state, and county as the data standards require (it starts 01089, 01125, 01027 within 2016; checked). The city file is sorted.

### Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (2012–2016 and 2014–2018 share three years). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2016 and 2018 use 2010 tract boundaries, and 2021 and 2023 use 2020 boundaries. Because exposure depends on how people are split across tracts, redrawn tracts alone can change values between 2018 and 2021. City values also switch from the 2010-tract-to-2014-place crosswalk to the 2020 crosswalk.
- Connecticut uses its eight old counties through 2021 and the nine planning regions (09110–09190) in 2023.
- Average White, Non-Hispanic exposure rises every year, from 0.204 (2016) to 0.229 (2023) across counties and from 0.429 to 0.473 across cities (checked in the final files).

### Open questions
- `race-ethnicity-exposure-county.csv` and `race-ethnicity-exposure-city.csv` at the folder root look like stale copies of the `final/` files. The county copy has the same values in a different row order; the city copy is older (1,931 rows, with a `state_place` column and only 479 places in 2023). The rendered `race-ethnicity-exposure-county.html` (4.2 MB) and `race-ethnicity-exposure-city.html` (3.9 MB) are also committed. Are they still needed?
- `final/evaluation_form_share_race_exposure_overall_county.csv` is an older copy of the form in `99a_final-evaluation/` (it lists 2014 and "2018:2021"). Can it be removed?
- The city .qmd describes the place allocation as areal interpolation by area overlap (line 472 and the paragraph after it), but the GeoCorr crosswalks are weighted by population. Which is right?
- Why does this metric start in 2016 when 13 (poverty exposure) starts in 2014?
- The city .qmd's tract CV table computes `asian_nh = mean(asian_nh >= 0.4)` on the count instead of the CV (line 246), and the note above it ("Not sure why or if this is a problem!", line 237) is unresolved. Both only affect the diagnostic table.
- The city .qmd says it pulls the counts "for 2021" (line 70), but it pulls all four years.

# 15_social-capital

```yaml
metric: Social capital (membership associations per 10,000 people; economic connectedness)
predictor: 15_social-capital
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Manuel Alcalá Kovalski, Ridhi Purohit, Tina Chelidze]
variables: [count_membership_associations_per_10k, count_membership_associations_per_10k_quality, share_economic_connectedness, share_economic_connectedness_lb, share_economic_connectedness_ub, share_economic_connectedness_quality]
geographies:
  county: 2014-2023 (associations), 2022 (economic connectedness)
  place: 2014-2023 (associations), 2022 (economic connectedness)
subgroups: []
confidence_intervals: true
code:
  - social_associations_county.qmd
  - social_associations_city.qmd
  - economic_connectedness_county_2022.qmd
  - economic_connectedness_city_2022.qmd
final_files:
  - final/social_associations_all_county.csv
  - final/social_associations_all_city.csv
  - final/economic_connectedness_version2025_county_2022.csv
  - final/economic_connectedness_version2025_place_2022.csv
sources:
  - name: County Business Patterns (CBP) and ZIP Code Business Patterns (ZBP), establishment counts
    provider: US Census Bureau
    vintage: 2014-2023
    access: API (censusapi::getCensus(), needs a Census API key)
    url: https://www.census.gov/data/developers/data-sets/cbp-zbp/cbp-api.html
  - name: Social Capital Atlas, county and ZIP code files
    provider: Opportunity Insights and Meta
    vintage: 2022 release
    access: downloaded in code
    url: https://data.humdata.org/dataset/social-capital-atlas
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
```

### Summary
Two metrics.

- **Membership associations**: number of establishments in 10 membership-association industries (the North American Industry Classification System, or NAICS, codes used by [County Health Rankings](https://www.countyhealthrankings.org/health-data/community-conditions/social-and-economic-factors/safety-and-social-support/social-associations?year=2025): religious, civic, social, business, political, professional, and labor organizations, plus fitness, golf, bowling, and sports clubs) per 10,000 people, from County Business Patterns (CBP).
- **Economic connectedness**: the share of friends of people with below-median socioeconomic status (SES) who have above-median SES, from the Social Capital Atlas (Chetty et al. 2022, built from Facebook friendships). The atlas publishes this as a ratio to 50 percent; the code multiplies it by 0.5 to get the share, so 0.5 means a fully integrated community. One year only, labeled 2022.

### Process
Membership associations:

1. Add a Census API key. Both .qmd files source `15_social-capital/R/census_api_key.R`, which isn't in the repo (there's no `R/` folder in this predictor; see Open questions).
2. **County**: render `social_associations_county.qmd`. For 2014–2023, it pulls county establishment counts (`ESTAB`) from the `cbp` API, using `NAICS2012` codes for 2014–2016 and `NAICS2017` codes from 2017. Each year is cached in `data/cbp_county_{year}.csv` and only fetched if that file doesn't exist.
3. Keep the 10 NAICS codes (813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920) and sum establishments by county.
4. `left_join()` onto `county-populations.csv` (the denominator is its `population`, not an ACS pull, despite the section title), then `count_orgs / (population / 10,000)`, rounded to one decimal as County Health Rankings does.
5. **City**: render `social_associations_city.qmd`. It pulls ZIP code establishment counts from the `zbp` API for 2014–2018 and the `cbp` API (`zipcode:*`) for 2019–2023, with the same NAICS codes, cached in `data/cbp_zcta_{year}.csv`.
6. Join to two GeoCorr ZIP Code Tabulation Area (ZCTA) to place crosswalks read from `15_social-capital/data/` (`2020_ZCTA_2021_Census_Places_Crosswalk.csv` and `2010_ZCTA_2010_Census_Places_Crosswalk.csv`). These aren't in the repo, since `data/` is gitignored; the .qmd describes how to download them from GeoCorr 2022. The two are stacked with `bind_rows()` and joined on `zcta_code` only.
7. Multiply each ZIP code's count by its ZCTA-to-place allocation factor and sum by place. Drop the one unmatched row per year, `left_join()` onto `place-populations.csv`, and divide by `population / 10,000`.
8. Each .qmd ends with `evaluate_final_data()` against `evaluation_form_social_cap1_overall_{county,place}.csv` in `99a_final-evaluation/` and writes `final/social_associations_all_{county,city}.csv`.

Economic connectedness:

1. **County**: render `economic_connectedness_county_2022.qmd`. It downloads `social_capital_county.csv` from the Humanitarian Data Exchange to `temp/`, keeps `ec_county` and `ec_se_county`, and drops the 71 counties with no value.
2. `left_join()` the 2020 rows of `county-populations.csv` (3,143 counties) to the atlas data and set `year = 2022`.
3. `share_economic_connectedness = ec_county * 0.5`. The standard error is also halved, and the 95 percent bounds are the share ± `qnorm(0.975)` × the halved standard error.
4. **City**: render `economic_connectedness_city_2022.qmd`. It downloads `social_capital_zip.csv` (keyed by 2010 ZCTA, per the [working paper](https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf)) and drops the 4,048 ZIP codes with no value.
5. Join to `geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv` by state and ZIP code. Each place's value is the mean of its ZIP codes' `ec_zip`, weighted by `ZCTAinPlace` (the share of the ZCTA's area inside the place), then multiplied by 0.5.
6. `left_join()` onto the 2020 rows of `place-populations.csv` (486 places). No confidence intervals for cities.
7. Each .qmd runs `evaluate_final_data()` against `evaluation_form_social_cap2_overall_{county,place}.csv` and writes `final/economic_connectedness_version2025_{county,place}_2022.csv`.

### Data quality flag
Membership associations:

- **County**: `1` whenever there's a value, `NA` otherwise. 30,322 rows are `1` and 1,104 are `NA`.
- **City**: based on how well ZCTAs fit the place, using the same rule as `geographic-crosswalks/generate_puma_county_crosswalks.qmd`. For each place, `sum_products` is the sum over ZCTAs of (share of the ZCTA in the place × share of the place in the ZCTA). `1`: 0.75 or more; `2`: 0.35 to 0.75; `3`: below 0.35. 4,850 rows are `1` and 6 are `2` (South Fulton, GA, 2018–2023); none are `3`. See Known issues for why almost every place is `1`.

Economic connectedness:

- **County**: `1` whenever there's a value, `NA` otherwise. 3,017 are `1` and 126 are `NA`.
- **City**: based on `zip_ratio`, the number of ZCTAs entirely inside the place divided by the number of ZCTAs linked to it. `1`: 0.5 or more; `2`: above 0.15 and below 0.5; `3`: below 0.15. 13 places are `1`, 108 are `2`, 364 are `3` (75 percent), and 1 is `NA`.

### Missing values
Membership associations, county file (3,142 rows a year in 2014–2019, 3,143 in 2020–2021, and 3,144 in 2022–2023):

- Missing per year: 23–25 in 2014–2016 and 138–156 from 2017 on. A county with none of the 10 industries published is `NA`, never 0.
- 22 counties are missing every year: Hoonah-Angoon, AK (02105); Kalawao, HI (15005); Clark, ID (16033); Garfield, Golden Valley, Petroleum, and Treasure, MT (30033, 30037, 30069, 30103); Arthur, Blaine, Loup, and McPherson, NE (31005, 31009, 31115, 31117); Esmeralda and Eureka, NV (32009, 32011); Wheeler, OR (41069); Mellette, SD (46095); Borden, Kenedy, King, Loving, and Terrell, TX (48033, 48261, 48269, 48301, 48443); and Daggett and Garfield, UT (49009, 49017).
- Chugach and Copper River, AK (02063, 02066): 2020–2021. They have values from 2022.
- In 2023, the states with the most missing counties are Texas (22), Nebraska (15), Montana (13), Utah (12), and Alaska (12).

Membership associations, city file: no missing values (485 places a year in 2014–2017 and 486 from 2018).

Economic connectedness:

- County: 126 of 3,143 missing. These are mostly small counties (median population 1,662; largest 45,593), concentrated in Texas (23), Virginia (21), Nebraska (15), Georgia (11), and Montana (11). Chugach and Copper River, AK (02063, 02066) are missing because the atlas reports the former Valdez-Cordova (02261), which the code drops on purpose (the .qmd explains why).
- City: none missing (486 places).

### Known issues
- **City membership association values are about double the county values.** The two ZCTA-to-place crosswalks (2010 and 2020) are stacked and joined to every year on `zcta_code` alone (`bind_rows(zcta_20_place_21_xwalk, zcta_10_place_10_xwalk)` and `left_join(zcta_place_xwalk, by = c("zcta_code"))` in `social_associations_city.qmd`), so a ZIP code in both crosswalks is counted through each. Data check where the place matches its county or counties: the city value divided by the population-weighted county value is 1.93–1.96 in 2014–2016 and 1.68–1.79 from 2017 for New York City, Baltimore, and St. Louis, and about 2 for San Francisco, Philadelphia, Denver, and DC.
- The city quality flag has the same problem. `sum_products` is summed over both crosswalks for each place, so it's roughly doubled, which is why no place is ever `3` (`crosswalk_data_quality` chunk in `social_associations_city.qmd`).
- The city crosswalks are read from `15_social-capital/data/`, which is gitignored (`15_social-capital/.gitignore` has `data/`), so the city membership associations can't be rerun from the repo alone.
- **Small industries drop out from 2017.** Beginning with reference year 2017, CBP only publishes a cell with three or more establishments; before that, establishment counts were published even when other fields were suppressed ([CBP methodology](https://www.census.gov/programs-surveys/cbp/technical-documentation/methodology.html)). A county or ZIP code with one or two establishments in one of the 10 codes now counts 0 for that code. The county mean falls from 13.9 in 2016 to 12.2 in 2017, and missing counties rise from 25 to 141 (data check; the .qmd notes the same).
- Membership association outliers (data check): the highest county values are 70.6 (Hooker County, NE, 31091, 2016) and 65.1 (Comanche County, KS, 20033, 2015). In cities, Provo, UT (4962470) is 0.0 in 2022 and 0.5–0.7 in 2019–2021 and 2023, while Utah County is 1.7–2.0; DC is the highest city every year (54–56).
- **Economic connectedness city quality depends on how ZCTAs are counted.** `zip_total` counts every ZCTA linked to the place, including ones whose `ZCTAinPlace` rounds to 0.000: 1,021 of the 6,780 ZCTA-place rows for the 486 places (data check on `2010_ZCTA_2021_Census_Places_Crosswalk.csv`). The median place has no ZCTA entirely inside it, so most places are `3`.
- A `zip_ratio` of exactly 0.15 gets no flag, because the `case_when()` uses `> 0.15` for `2` and `< 0.15` for `3`. Overland Park, KS (2053775) has 3 of 20 ZCTAs inside (0.15) and is `NA` (recomputed from the atlas ZIP file and the crosswalk; the recomputed place values match the final file).
- The economic connectedness ZIP code file is joined to the crosswalk by state and ZIP code, where the ZIP code's state comes from its county in the atlas. 877 crosswalk rows have a ZIP code with an atlas value in a different state (for example, ZIP code 35586 in Alabama and Mississippi), and those place pairs are dropped (data check).
- City economic connectedness is weighted by the share of each ZCTA's land area in the place (`ZCTAinPlace` = `IntersectArea / ZCTAarea` in the crosswalk), not by population.

### Comparability across years
- Membership associations: 2014–2016 and 2017–2023 aren't comparable because of the 2017 CBP publication change (see Known issues). The NAICS vintage also changes from 2012 to 2017 in 2017; the .qmd says the 10 codes mean the same thing in both.
- City membership associations come from ZBP for 2014–2018 and CBP ZIP code data for 2019–2023.
- Connecticut: the county file has the 8 old counties through 2021 and the 9 planning regions in 2022–2023, all with values.
- Economic connectedness is a single cross-section (2022 release), so there's no change over time to compare.

### Open questions
- Should `social_associations_city.qmd` use one ZCTA crosswalk per year (2010 ZCTAs for earlier years, 2020 ZCTAs for later ones) instead of both? That would also fix the city quality flag.
- Where are the two ZCTA crosswalks in `15_social-capital/data/`? Should they move to `geographic-crosswalks/data/`?
- Both membership association .qmd files source `15_social-capital/R/census_api_key.R` and tell you to edit `census_api_key-template.R`, but neither file nor the `R/` folder exists here, and the root `.gitignore` doesn't cover a key at that path. Should this predictor get the template and a `.gitignore` entry, as 13 and 14 have?
- The economic connectedness city .qmd text describes the quality flag as the share of ZIP codes that fall "fully (>50%)" in the place, but the code uses ZCTAs entirely inside the place (`ZCTAinPlace == 1`).
- The economic connectedness .qmd files say they were first written as `economic_connectedness_county_code_2022.R` and `economic_connectedness_city_code_2022.R`; neither is in the folder. Should the references go?
- The county membership association .qmd has a heading "Download population data from ACS (denominator)", but it reads `county-populations.csv`.
- The rendered `.html` files for all four .qmd files (1.3–1.6 MB each) are committed. Are they still needed?

# 16_transportation-access

```yaml
metric: Transportation access
predictor: 16_transportation-access
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Tina Chelidze, Aaron R. Williams]
variables: [share_transit_commuter, share_transit_commuter_quality, share_transportation_cost, share_transportation_cost_quality]
geographies:
  county: 2015, 2019, 2022
  place: 2015, 2019, 2022
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - transportation_county_combined.qmd
  - transportation_city.qmd
  - transportation_city_subgroup.qmd
final_files:
  - final/transportation_all_county.csv
  - final/transportation_subgroup_county.csv
  - final/transportation_all_city.csv
  - final/transportation_subgroup_city.csv
sources:
  - name: Housing and Transportation (H+T) Affordability Index, tract files
    provider: Center for Neighborhood Technology (CNT)
    vintage: 2015, 2019, and 2022 tract files
    access: manual download (free account required), stored on Box
    url: https://htaindex.cnt.org/download/
  - name: American Community Survey (ACS) 5-year estimates, tables B25001, B03002, and B19013 (B00002 for 2015)
    provider: US Census Bureau
    vintage: 2011-2015, 2015-2019, and 2018-2022
    access: API (tidycensus::get_acs())
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/geocorr2018_2010tract_to_2014place.csv
  - geographic-crosswalks/data/geocorr2022_tract_to_place.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
```

### Summary
Two measures from the Center for Neighborhood Technology (CNT) Housing and Transportation (H+T) Affordability Index for a household earning 80 percent of the regional area median income (AMI): the share of workers who commute by transit (`share_transit_commuter`) and transportation costs as a share of income (`share_transportation_cost`). CNT models both at the census tract level; the code averages tracts to counties and cities, weighted by households. The subgroup files repeat the calculation by neighborhood type (White neighborhoods, neighborhoods of color, and mixed neighborhoods), not by the race or ethnicity of the household.

### Process
1. Download the CNT tract files for 2015, 2019, and 2022 from the [Box folder](https://urbanorg.app.box.com/folder/250262697073) into `data/2015_tract/`, `data/2019_tract/`, and `data/2022_tract/` (unzipped). The originals come from the CNT download page, which requires a free account. `data/` is gitignored.
2. Render the three .qmd files, in any order. They don't depend on each other. Each one pulls its own ACS data with `tidycensus::get_acs()`.
   - `transportation_county_combined.qmd` writes both county files.
   - `transportation_city.qmd` writes `transportation_all_city.csv`.
   - `transportation_city_subgroup.qmd` writes `transportation_subgroup_city.csv`.
3. CNT tracts: build the tract GEOID from CNT's `tract` field (characters 2–12), keep `pct_transit_commuters_80ami` as `share_transit_commuter` and `t_80ami` as `share_transportation_cost`, drop tracts with no households, and divide both by 100.
4. ACS tracts: pull B25001_001 (housing units, used as the household estimate and its margin of error) and B03002 (race and ethnicity) for 2015, 2019, and 2022. Convert margins of error to standard errors by dividing by `qnorm(0.95)`.
5. Neighborhood type (subgroup .qmd files only), from the tract's B03002 shares:
   - White neighborhoods: White, non-Hispanic share of 0.6 or more
   - Neighborhoods of color: share of everyone else of 0.6 or more
   - Mixed neighborhoods: everything else with population
   - Tracts with no ACS population are dropped.
6. County: household-weighted mean of the tract values (`weighted.mean(..., w = households)`), by county and by county and neighborhood type. The household estimate is summed and its standard error is the root sum of squares. `full_join()` onto `county-populations.csv` expanded to the four subgroups.
7. City: join tracts to places with the GeoCorr tract-to-place crosswalks (`geocorr2018_2010tract_to_2014place.csv` for 2015 and 2019, `geocorr2022_tract_to_place.csv` for 2022), drop tracts outside the target places, and take the mean weighted by `households * afact`. Join onto `place-populations.csv`.
8. Quality flags (see Data quality flag), then `evaluate_final_data()` against the four `evaluation_form_transportation_*` forms in `99a_final-evaluation/`, then write to `final/`.

### Data quality flag
Both variables always get the same flag. The flag is the worst of these tests:
- **Household estimate**: coefficient of variation (CV) of the summed ACS household estimate. `1` below 0.08, `2` below 0.15, otherwise `3`. The .qmd files use tighter cutoffs than the usual 0.2 and 0.4 because the CNT values are modeled.
- **Median household income**: CV of the county's or place's ACS median household income (B19013). `1` below 0.1, `2` below 0.3, otherwise `3`. A missing CV is set to 0.5, which gives `3`. Subgroup rows use the CV for the whole county or place.
- **Crosswalk match (cities only)**: `1` when at least half of the place's tracts have `afact` above 0.5, otherwise `2`.

Tallies:
- County all file: 8,885 rows are `1`, 529 are `2`, 13 are `3`, and 1 is missing. Rows rated `2` rise from 111 in 2015 to 159 in 2019 and 259 in 2022.
- County subgroups (`1`/`2`/`3`): White neighborhoods 8,458/419/12, mixed neighborhoods 3,450/256/35, neighborhoods of color 2,513/257/41.
- City all file: 1,447 rows are `1`, 2 are `2` (Conroe, TX, in 2015 and 2019), and 8 are missing.
- City subgroups (`1`/`2`/`3`): White neighborhoods 1,144/70/37, mixed neighborhoods 1,174/54/21, neighborhoods of color 1,138/35/20.

### Missing values
County all file (3,142 rows in 2015 and 2019 and 3,144 in 2022, matching `county-populations.csv`):
- Loving County, TX (48301): 2015

County subgroups, counties missing per year (because the county has no tract of that type):
- Neighborhoods of color: 2,145–2,252
- Mixed neighborhoods: 1,824–1,945
- White neighborhoods: 174–184

City all file (485 rows in 2015 and 486 in 2019 and 2022, matching `place-populations.csv`):
- South Fulton, GA (1372122): 2019. It isn't in the 2014-place crosswalk.
- All seven Connecticut cities (Bridgeport, Danbury, Hartford, New Haven, Norwalk, Stamford, and Waterbury): 2022 (see Known issues)

City subgroups, cities missing per year: neighborhoods of color 82–96, White neighborhoods 57–82, mixed neighborhoods 66–73. The `All` rows add South Fulton in 2019 and the Connecticut cities in 2022.

### Known issues
- **All Connecticut cities are missing in 2022.** In the 2022 CNT data, Connecticut tracts carry the planning region codes (the county file has 09110–09190 for 2022), but `geocorr2022_tract_to_place.csv` only has the old county codes (09001–09015, checked), so no Connecticut tract joins to a place. The city .qmd notes that "Most of the missing tracts are Connecticut Planning Regions."
- **The city match quality test isn't weighted.** `weighted.mean(afact > 0.5, weight = households, na.rm = TRUE)` passes `weight`, which `weighted.mean()` doesn't recognize (its argument is `w`), so it's ignored and every tract counts equally (checked: `weighted.mean(c(1, 0), weight = c(100, 1))` returns 0.5). Both city .qmd files.
- **The city household CV mixes allocated and unallocated tracts.** The household estimate is `sum(households_est * afact)`, but its standard error is `sqrt(sum(households_se ^ 2))` without `afact`, so places with many partly included tracts get a larger CV than their allocated estimate supports (both city .qmd files).
- **Subgroup rows use the whole geography's income CV.** The median household income test joins on year and geography only (`med_hh_income_cv` in all three .qmd files), so a neighborhood type with few households can still be `1` when its household CV is low.
- **The two city files disagree slightly on All.** `transportation_all_city.csv` comes from `transportation_city.qmd`, which keeps tracts with no ACS population; the `All` rows in `transportation_subgroup_city.csv` come from `transportation_city_subgroup.qmd`, which drops them (`filter(subgroup != "No population")`). Values differ by up to 0.0005 (data check). The county files don't have this problem: both come from one .qmd and match exactly.
- **Many counties have no transit commuters.** `share_transit_commuter` is exactly 0 for 480 counties in 2015, 1,924 in 2019, and 1,360 in 2022 (data check). In cities, only 8 values (all 2015) are 0.
- **Outliers**:
  - Transit: the highest county values are New York County, NY (0.69 in 2015), and the highest place is New York City (0.57 in 2015).
  - Cost: 23 county rows are above 0.6. The highest are Issaquena County, MS (0.83), and Jackson County, SD (0.79), both in 2022. The lowest is New York County (0.05 in 2015). All place values are between 0.10 and 0.42.

### Comparability across years
- 2015 and 2019 use 2010 tracts and the 2010-tract-to-2014-place crosswalk; 2022 uses 2020 tracts and the 2020 crosswalk.
- Connecticut uses its eight old counties in 2015 and 2019 and its nine planning regions in 2022, and has no city values in 2022.
- CNT changes its model and inputs between releases ([H+T Index methods, November 2022](https://htaindex.cnt.org/about/method-2022.pdf), which describes changes made in earlier releases). The share of counties with no transit commuters jumps from 15 percent in 2015 to 61 percent in 2019 and 43 percent in 2022, so county transit changes across years mix real change with model changes.
- The ACS inputs used for quality and subgroups are 5-year samples, so 2015 (2011–2015) and 2019 (2015–2019) share 2015.

### Open questions
- The .qmd text describes `t_80ami` as "Transportation Costs % Income for the Regional Typical Household". In the CNT methods, the typical household earns the regional median income, while the `80ami` variables are for a household at 80 percent of it; the old `documentation/overview.md` called it the "regional moderate household". Which one is it?
- The county .qmd histograms are labeled "Annual Transit Trips", but since March 2025 (e7ae2a88) the variable is the share of workers commuting by transit.
- In both city .qmd files, the step that blanks the cost flag when the cost is missing checks `is.na(share_transportation_cost_quality)` instead of `is.na(share_transportation_cost)`. It has no effect now, since cost and transit are missing together.
- The .qmd text calls B25001_001 "the number of households in the tract", but B25001 is total housing units, vacant ones included ([ACS 5-year variables](https://api.census.gov/data/2022/acs/acs5/variables.html)). Should the household CV use B11001_001 (households)?
- The year-over-year change checks in `transportation_city.qmd` group by `year, state, place` before `lag()`, so every change is `NA`.
- Which CNT release does each `data/{year}_tract/` folder hold? The raw files are only on Box, so the year-to-release mapping couldn't be checked.
- Should the Connecticut tracts be mapped to places for 2022 (for example, with a tract-to-place crosswalk that uses planning region codes)?
- The rendered `transportation_city.html`, `transportation_city_subgroup.html`, and `transportation_county_combined.html` (about 2 MB each) are committed at the folder root. Are they still needed?

# 17_access-to-health-services

```yaml
metric: Ratio of population to primary care physicians
predictor: 17_access-to-health-services
pillar: Healthy Environment and Access to Good Health Care
metric_lead: [Vincent Pancini]
variables: [ratio_population_pc_physician, ratio_population_pc_physician_quality]
geographies:
  county: 2014-2022
  place: none
subgroups: []
confidence_intervals: false
code:
  - access-health-services-all.qmd
final_files:
  - final/ratio_pop_pcp_metric_all_county.csv
sources:
  - name: Area Health Resources File (AHRF), county level, SAS files
    provider: Health Resources and Services Administration (HRSA), from the American Medical Association (AMA) Physician Masterfile
    vintage: 2021-2022 release (2014-2020), 2022-2023 release (2021), 2023-2024 release (2022)
    access: downloaded in code
    url: https://data.hrsa.gov/topics/health-workforce/ahrf
  - name: County Health Rankings 2023 data (validation only)
    provider: University of Wisconsin Population Health Institute
    vintage: 2023 release
    access: downloaded in code
    url: https://www.countyhealthrankings.org/health-data/methodology-and-sources/rankings-data-documentation
  - name: County population estimates, Vintage 2020 (validation only)
    provider: US Census Bureau
    vintage: 2010-2020
    access: downloaded in code
    url: https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/counties/totals/co-est2020.csv
crosswalks: [geographic-crosswalks/data/county-populations.csv]
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
```

### Summary
Number of people in the county per primary care physician (PCP), from the Area Health Resources File (AHRF) count of nonfederal primary care physicians excluding residents, divided into the county population from `county-populations.csv`. Higher values mean fewer physicians per person. Counties with 2,000 or fewer people and no PCPs get a value of 0.

### Process
1. Render `access-health-services-all.qmd`. It downloads and unzips three AHRF SAS releases into `data/` with its own `ahrf_fetch()` function (the `data/` folder is gitignored):
   - 2021–2022 release (`ahrf2022.sas7bdat`): PCP counts and populations for 2014–2020 (variables `f1467514`–`f1467520` and `f1198414`–`f1198419`, `f0453020`)
   - 2022–2023 release (`ahrf2023.sas7bdat`): 2021 (`phys_nf_prim_care_pc_exc_rsdt_21`, `popn_est_21`)
   - 2023–2024 release (`ahrf2024_feb2025.sas7bdat`): 2022 (`phys_nf_prim_care_pc_exc_rsdt_22`, `popn_est_22`)
2. Full-join the three files by state and county, drop Guam, Puerto Rico, and the US Virgin Islands, and reshape long by year.
3. Read `county-populations.csv`, dropping 2023 (`filter(!year %in% c(2023))`). A `testthat` check requires its years to equal the AHRF years.
4. Fix and drop AHRF counties that don't match the county file (`fix-missing-urban` chunk):
   - 2014: recode Oglala Lakota, SD (46102) to 46113 and Kusilvak, AK (02158) to 02270, the codes in the county file
   - Drop all Connecticut rows for 2021 and 2022
   - Drop 02001 (not a valid FIPS code), 02201, 02232, 02280, 51515, and 51560 (counties that no longer exist)
   - Drop Chugach and Copper River, AK (02063, 02066) for 2014–2019 and Valdez-Cordova, AK (02261) for 2020–2022
5. `left_join()` the AHRF data onto `county-populations.csv`. A `stopifnot()` checks that the Urban population equals the AHRF population in every matched row.
6. Ratio, following the County Health Rankings suppression rule:
   - 0 PCPs and population of 2,000 or less: `0`
   - 0 PCPs and population above 2,000: `NA` (treated as a false zero)
   - 1 or more PCPs: `round(population / pc_physicians)`
7. Quality flag from the ratio's sensitivity to one more physician (see Data quality flag).
8. Validation (doesn't change the output): downloads the 2023 County Health Rankings file and the Census Vintage 2020 county estimates to `data/` and compares 2020 ratios with County Health Rankings.
9. `evaluate_final_data()` against `99a_final-evaluation/evaluation_form_ratio_population_pc_physician_overall_county.csv`, then write `final/ratio_pop_pcp_metric_all_county.csv`.

### Data quality flag
Sensitivity = the percent change in the ratio when 1 is added to the county's PCP count (`calculate-sensitivity` chunk):
- `1`: change under 20 percent
- `2`: 20 percent to under 40 percent
- `3`: 40 percent to under 60 percent
- `NA`: the ratio is `NA`

Since the ratio is population / PCPs, the change is about 1 / (PCPs + 1), so the flag works out to a PCP count: `1` for about 5 or more PCPs, `2` for 2–4, and `3` for 1. The largest possible change is about 50 percent (1 PCP), so no nonmissing row is ever above 60 percent. Counties with a ratio of 0 have an infinite change, which the code replaces with the largest finite one, so all of them are `3`.

Tallies: 20,599 rows are `1`, 3,857 are `2`, 2,482 are `3` (9 percent of nonmissing), and 1,344 are `NA`. The split is about the same every year (2,262–2,310 counties are `1`).

### Missing values
134–179 counties a year (1,344 of 28,282 rows), rising over time: 134 (2014), 134, 135, 147, 150, 153, 147, 165, and 179 (2022).
- Connecticut: all 8 counties in 2021 and all 9 planning regions in 2022, so there are no Connecticut values after 2020
- Chugach and Copper River, AK (02063, 02066): 2020; Copper River also 2022
- Everything else (134–169 a year) is a false zero: a county with more than 2,000 people and 0 PCPs. The largest is Crawford County, MO (29055), with 24,302 people in 2016. These are concentrated in Texas (182 county-years), North Dakota (120), Georgia (119), South Dakota (96), Kansas (70), and Nebraska (67).
- 260 counties are missing in at least one year and 74 in every year.

### Known issues
- **A value of 0 means no physicians, not the best access.** The ratio is population per PCP, so lower is better, but counties with 2,000 or fewer people and no PCPs are set to 0 (`create-ratio` chunk). 67–76 counties a year are 0, all quality `3` (data check), for example Alpine County, CA and Denali Borough, AK. Anyone ranking or averaging the values needs to treat them separately.
- **Connecticut planning regions are dropped even though AHRF has them for 2022.** The .qmd notes that the 2023–2024 release has the nine planning regions, but `fix-missing-urban` drops every Connecticut row for 2021 and 2022, so the 2022 planning regions are `NA` (data check).
- **Rerunning fails the year check.** `county-populations.csv` now has 2014–2025 (2024 and 2025 were added in October and November 2025), and the code only drops 2023, so the `testthat` check that the county file and AHRF have the same years fails.
- **The flag is a physician count.** It doesn't account for population: a county of 45,996 with 1 PCP and a county of 900 with 1 PCP both get `3`, and a county with 5 PCPs gets `1` at any population (formula above, `assign-data-quality` chunk).
- **Large outliers.** Logan County, OK (40083) is 45,996–46,784 in 2015–2017 (1 PCP) and about 23,000–25,000 in the other years. Ripley County, IN (18137) jumps from 14,350 in 2015 to 28,846 in 2016, and Lincoln County, MO (29113) from 20,529 in 2021 to 31,578 in 2022. 55–67 county-years a year are 10,000 or more (data check).
- The AHRF counts nonfederal PCPs and excludes residents (variable names `phys_nf_prim_care_pc_exc_rsdt_*`; [AHRF](https://data.hrsa.gov/topics/health-workforce/ahrf)). Physicians are counted where they're recorded in the AMA Physician Masterfile, which can differ from where patients go for care.

### Comparability across years
- Each year comes from one AHRF release: 2014–2020 from the 2021–2022 release, 2021 from the 2022–2023 release, and 2022 from the 2023–2024 release. Starting with the 2022–2023 release, AHRF only includes the two most recent years of each variable (.qmd section 2), so later releases can't be used to rebuild earlier years.
- Missing values rise from 134 in 2014 to 179 in 2022, mostly from more false zeros, so the set of counties with a value changes across years.
- Alaska: Valdez-Cordova (02261) through 2019, Chugach and Copper River (02063, 02066) from 2020. Connecticut has no values after 2020.

### Open questions
- Should the 2022 Connecticut planning regions be kept, since AHRF has them?
- The .qmd text says "To get all years 2014-2021, we need to download two versions of the AHRF data", but the code downloads three releases and covers 2014–2022. Section 4.2 says the only unmatched counties are Connecticut in 2021.
- The .qmd says a ratio change of 40–59 percent is quality `3`, but there's no rule for 60 percent or more; in practice the change never exceeds about 50 percent, so every nonmissing ratio gets a flag. Should the flag account for population?
- The check after the quality flag, `stopifnot(!all(is.na(ratio) & is.na(quality)))`, only fails if every row is missing both. It doesn't check what its comment says ("If the `ratio` value is `NA`, the `quality` value is also `NA`").
- Are the Logan County, OK (2015–2017), Ripley County, IN (2016 on), and Lincoln County, MO (2022) jumps real, or AHRF reporting changes?
- The rendered `access-health-services-all.html` (1.2 MB) is committed next to the .qmd. Is it still needed?

# 18_neonatal-health

```yaml
metric: Neonatal health (share of low birthweight births)
predictor: 18_neonatal-health
pillar: Healthy Environment and Access to Good Health Care
metric_lead: [Vincent Pancini]
variables: [rate_low_birth_weight, rate_low_birth_weight_lb, rate_low_birth_weight_ub, rate_low_birth_weight_quality]
geographies:
  county: 2016-2024
  place: none
subgroups: [race-ethnicity, mothers-education]
confidence_intervals: true
code:
  - neonatal-health-all.qmd
final_files:
  - data/final/rate_low_birth_weight_metric_all_county.csv
  - data/final/rate_low_birth_weight_metric_subgroup_county.csv
sources:
  - name: Natality, 2007-2024 (expanded), CDC WONDER
    provider: National Center for Health Statistics (NCHS), Centers for Disease Control and Prevention (CDC)
    vintage: 2016-2024 final natality data, one extract per year and measure
    access: manual download from the CDC WONDER web form (no county-level API); raw extracts on Box
    url: https://wonder.cdc.gov/natality-current.html
crosswalks: [geographic-crosswalks/data/county-populations.csv]
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
```

### Summary
Share of births in the county with a low birthweight (under 2,500 grams), among births with a known birthweight, by the mother's county of residence. The subgroup file repeats the calculation by the mother's race and ethnicity (four groups) and the mother's education (four groups). Counties with fewer than 100,000 people get their state's pooled value for all such counties, because CDC WONDER doesn't report them separately.

### Process
1. Download 18 extracts per year from [CDC WONDER Natality](https://wonder.cdc.gov/natality-current.html), following section 2 of the .qmd: all births and low birthweight births, overall (2) and for each of the eight subgroups (16). Group by county, keep "Show Suppressed Values" and "Show Zero Values" on, and select one year at a time. Births are all birthweight categories except "All Weights" and "Unknown or Not Stated"; low birthweight births are the five categories under 2,500 grams. The data can't be queried by county through the CDC WONDER API, so this is done by hand. The raw extracts for this update are on Box (`Data/UMI Raw Data/Metrics_2026_round/18_neonatal-health/data`).
2. Save the `.txt` files with the names the .qmd expects: `all_births_YYYY.txt` and `lbw_births_YYYY.txt` in `data/all/`, and `all_births_{race|momed}_{subgroup}_YYYY.txt` and `lbw_births_...` in `data/subgroups/` (subgroups `nhwhite`, `nhblack`, `hisp`, `nhother`, `lths`, `hs`, `somecol`, `baplus`). Both folders are gitignored. Year, birth type, and subgroup are parsed from the file names.
3. Render `neonatal-health-all.qmd`. It reads every file in both folders, drops the notes rows at the bottom of each file, and reshapes to one row per county and year.
4. Drop Cape May County, NJ (34009) and Portsmouth city, VA (51740) from the CDC WONDER data. CDC WONDER recoded them to "Unidentified Counties" after 2013 ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)).
5. Drop Connecticut for 2022–2024 from both the births data and `county-populations.csv`, since CDC WONDER still uses the eight old counties and the target file uses the nine planning regions.
6. `full_join()` the births data onto `county-populations.csv` (2016 on). Counties with no match get the values of their state's "Unidentified Counties" row (county code `999`), separately for each subgroup, and are flagged as unidentified.
7. Counts marked "Suppressed" (1–9 births) become `NA` and are flagged.
8. `rate_low_birth_weight = births_lbw / births_all`, set to `NA` when `births_all` is under 30.
9. Assign the quality flag (below) and 95 percent confidence intervals: `p ± 1.96 × sqrt(p × (1 − p) / births_all)`, the normal approximation for percents in the NCHS User Guide to the 2010 Natality Public Use File (section 8 of the .qmd).
10. Add the nine Connecticut planning regions back for 2022–2024 with every value `NA`, then write the all file and the subgroup file. `evaluate_final_data()` checks the all file against `evaluation_form_low_birth_overall_county.csv` and the subgroup file, split by subgroup type, against the race-ethnicity and mothers-education forms in `99a_final-evaluation/`.

### Data quality flag
Applied from lowest to highest quality (`assign-quality` chunk):
- `NA`: the rate is missing or `births_all` is under 30
- `3`: the county is unidentified (it has the state's pooled value), a count was suppressed, or `births_all` is 30–99
- `2`: `births_all` is 100–199, or the state has 1–4 unidentified counties, or the state has 15 or fewer counties and under half of them are unidentified
- `1`: everything else

All file: 23,081 rows are `3` (82 percent), 489 are `2`, 4,689 are `1`, and 27 are `NA`. The counts are the same every year: 521 counties are `1` and 2,564–2,565 are `3`, with 57 counties at `2` through 2021 and 49 from 2022 (Connecticut's eight counties drop out). Every `2` in 2024 is in one of seven states: Arizona, Delaware, DC, Hawaii, Massachusetts, New Jersey, and Rhode Island.

Subgroup file, `3` share of each subgroup's nonmissing rows: 82 percent for White, Non-Hispanic and for every education group except Less than High School (84 percent); 85 percent for Black, Non-Hispanic and for Hispanic; 88 percent for Other Races and Ethnicities.

### Missing values
All file:
- The nine Connecticut planning regions (09110–09190): 2022–2024. No other county is ever missing.

Subgroup file, counties missing per year (2016–2024 range):
- Black, Non-Hispanic: 381–540
- Other Races and Ethnicities: 182–233
- Hispanic: 124–178
- Less than High School: 61–91
- GED/High School Degree: 4–17; College Degree or Higher: 8–17; White, Non-Hispanic: 2–13; Some College: 0–14 (each includes the nine Connecticut regions from 2022)

When a state's pooled "Unidentified Counties" value is missing, all of that state's small counties are missing together. For example, in 2024 every county in Montana (56) and Wyoming (23) is missing for Black, Non-Hispanic, as are 42 of 58 California counties.

### Known issues
- Most counties don't have their own value. CDC WONDER only identifies counties that had 100,000 or more people in the 2010 Census, for all of 2014–2024 ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)). Every other county gets the pooled value of its state's unidentified counties (`assign-unidentified` chunk). In the all file, all 23,081 quality `3` rows share their value with other counties in the same state and year, in groups of up to 215 (Texas). Wyoming has no identified counties, so every Wyoming county has one value each year.
- Because the set of identified counties is fixed by the 2010 Census, counties that passed 100,000 people after 2010 are still pooled, and the quality flags don't change from year to year (data check: only Alaska and Connecticut, whose county codes change, have different flags in different years).
- Confidence intervals for pooled counties understate uncertainty. They use the pooled state births as the denominator (`construct-CIs` chunk), so they describe the pooled rate, not the county. The median interval width is 0.007 for quality `3` rows, compared with 0.021 for quality `1` rows (data check on the all file).
- The `2` flag mostly reflects the state, not the county. It applies to identified counties in states with few unidentified counties or few counties (`quality2` in the `quality-criteria` chunk), so counties with their own value in Delaware, DC, and (through 2021) Connecticut, where no county is pooled, are `2` instead of `1`.
- Suppression removes small nonzero counts but keeps zeros. Counts of 1–9 are suppressed by CDC WONDER ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)) and become `NA`, while zero low birthweight births are shown, so small subgroups are either 0 or have at least 10 low birthweight births. 45 subgroup rows are exactly 0 (17 Black, Non-Hispanic; 14 Hispanic; 11 Other Races and Ethnicities; 3 Less than High School), with confidence intervals of 0 to 0.
- Subgroup outliers come from small denominators: the highest values are Black, Non-Hispanic births in counties 29097 (0.35, 2018), 35013 (0.33, 2017), and 55117 (0.32, 2016), all quality `3`. The highest All value is 0.167 (county 28049, 2024, quality `1`).
- The variables are named `rate_` but are shares (low birthweight births divided by all births), not rates per population.

### Comparability across years
- The same counties are identified in every year (2010 Census populations): 578 through 2021 and 570 from 2022, when Connecticut's eight drop out. The pooling is consistent across 2016–2024, but a pooled county's value moves with its state's small-county births, not its own.
- Connecticut has values for the eight old counties through 2021 and none for 2022–2024.
- Alaska has Valdez-Cordova (02261) through 2019 and Chugach (02063) and Copper River (02066) from 2020, following `county-populations.csv`.
- The previous round's quality rule also gave a `2` to counties with 10–29 low birthweight births; that rule was dropped in this update (section 1.1 of the .qmd).

### Open questions
- Can Connecticut 2022–2024 get values? The CDC WONDER help says the 2022–2024 data have an "Unidentified Counties" category for the combined Connecticut planning regions, which may allow a statewide value for all nine regions.
- Should identified counties in states like Delaware and DC be `1`? The current `2` rule depends on the number of counties and unidentified counties in the state, not on the county's own data.
- The .qmd text says to expect 20,516 counties only in the population file (the `check-wont-match-counties` chunk). The arithmetic in the same chunk, with 2024 included, gives 23,081.
- Section 1.3 of the .qmd suggests allocating the pooled births by county population instead of giving every small county the pooled rate. Should this be done in the next update?
- The rendered `neonatal-health-all.html` (1.5 MB) is committed next to the .qmd. Is it still needed?

# 19_environmental-quality

```yaml
metric: Air quality
predictor: 19_environmental-quality
pillar: Healthy Environment and Access to Good Health Care
metric_lead: [JP Walsh]
variables: [index_air_hazard, index_air_hazard_quality]
geographies:
  county: 2014, 2018, 2019
  place: 2014, 2018, 2019
subgroups: [poverty, race-ethnicity]
confidence_intervals: false
code:
  - air_toxicity_metric.qmd
final_files:
  - data/final/environment_county_longitudinal.csv
  - data/final/environment_county_poverty_longitudinal.csv
  - data/final/environment_county_race-ethnicity_longitudinal.csv
  - data/final/environment_place_longitudinal.csv
  - data/final/environment_place_poverty_longitudinal.csv
  - data/final/environment_place_race-ethnicity_longitudinal.csv
sources:
  - name: AirToxScreen (2018, 2019) and National Air Toxics Assessment (NATA, 2014), national results by tract and source group
    provider: US Environmental Protection Agency (EPA)
    vintage: 2014 NATA, 2018 and 2019 AirToxScreen
    access: manual download, committed in data/raw/ (also on Box)
    url: https://www.epa.gov/AirToxScreen/2019-airtoxscreen-assessment-results
  - name: American Community Survey (ACS) 5-year, tract tables B01003, B03002, and B17001
    provider: US Census Bureau
    vintage: 2010-2014, 2014-2018, and 2015-2019
    access: API (tidycensus::get_acs(), Census API key)
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/tract-county-crosswalk_2018.csv
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/geocorr2018_tract_to_place.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
```

### Summary
A 0–100 index of exposure to air toxics, from the Environmental Protection Agency's (EPA) modeled cancer risk and respiratory and neurological hazard for each census tract. Each tract gets its national percentile rank on the combined hazard, flipped so that higher values mean less hazard, and county and city values are the population-weighted averages of their tracts. The subgroup files repeat the average for tracts grouped by poverty rate and by racial and ethnic makeup.

### Process
1. The EPA files are already in `data/raw/2014/`, `data/raw/2018/`, and `data/raw/2019/`: three national by-tract files per year (cancer risk, neurological hazard index, and respiratory hazard index), downloaded by hand from the EPA assessment pages. The .qmd also points to a Box copy.
2. Set a Census API key for `tidycensus` (the `census_api_key()` line is commented out, line 41), then render `air_toxicity_metric.qmd`. One render writes all six files; there are no parameters.
3. Tracts: for each year, bind the three EPA files, keep `total_cancer_risk_per_million`, `total_neurological_hazard_quotient`, and `total_respiratory_hazard_quotient`, and drop Puerto Rico and the US Virgin Islands. 25 tract codes that changed after 2010 are recoded by hand (for example, Wade Hampton, AK, 02270 to Kusilvak, 02158, and Shannon, SD, 46113 to Oglala Lakota, 46102). Only tracts in the 2015–2019 ACS tract list are kept (line 314), which drops the EPA's nontract rows.
4. Tract index: within each year, convert each of the three measures to a z-score across tracts, add them, multiply by −1, and take `percent_rank() × 100`, rounded (lines 346–379).
5. ACS: pull tract population (B01003_001), race and ethnicity (B03002_001 and B03002_003), and poverty (B17001_001 and B17001_002) from the 2014, 2018, and 2019 5-year files. Classify each tract:
   - Race and ethnicity: Majority Non-White (60 percent or more people of color), No Majority Race/Ethnicity (more than 40 and less than 60 percent), and Majority White, Non-Hispanic (the rest)
   - Poverty: High-Poverty (40 percent or more in poverty) and Not High-Poverty
6. County: assign tracts to counties with `tract-county-crosswalk_2018.csv` (the same tracts in every year) and take the mean of the tract index weighted by tract population, for all tracts and for each tract class. The county list is every distinct county in `crosswalk_puma_to_county.csv`, across all crosswalk periods (line 509).
7. City: assign tracts to places with `geocorr2018_tract_to_place.csv`, weighting each tract by population × `afact` (the share of the tract's population in the place), and keep places in `place-populations.csv`.
8. Set the quality flag, round the index to a whole number, and write the files. The subgroup files include the `All` rows (`subgroup_type = "all"`). The .qmd doesn't call `evaluate_final_data()`.

### Data quality flag
- `1`: tracts with no index value (or, for subgroups, no subgroup class) hold less than 5 percent of the geography's population
- `2`: 5 percent or more (lines 696 and 950)
- `3` is never assigned, and the flag doesn't reflect how many tracts a value comes from or the uncertainty in the EPA models.
- County all file: every nonmissing row is `1`. County subgroup files: 4 rows are `2` in the poverty file and 7 in the race-ethnicity file; 3 High-Poverty rows (Michigan 2018 and 2019, Washington 2019) are `2` with a missing value. Place files: every nonmissing row is `1`.

### Missing values
County all file (3,141 rows a year, against 3,142 in `county-populations.csv`):
- Valdez-Cordova, AK (02261), and its 2019 replacements Chugach and Copper River (02063, 02066) have no row in any year, so that area has no value.
- 2014: Kusilvak, AK (02158) and Oglala Lakota, SD (46102) are in the file with missing values; their earlier codes (02270, 46113), which `county-populations.csv` uses for 2014, aren't in the file.

County subgroup files, missing per year (most because the county has no tract in that class):
- High-Poverty: 2,401–2,539
- Not High-Poverty: 6–11
- Majority Non-White: 2,209–2,242
- No Majority Race/Ethnicity: 1,901–1,945
- Majority White, Non-Hispanic: 165–182
- Chugach and Copper River have subgroup rows (all missing) but no `All` row.

City all file (483 rows a year, against 485–486):
- Jurupa Valley, CA (0637692) and Macon-Bibb County, GA (1349008): every year
- South Fulton, GA (1372122): 2018 and 2019
- These three places aren't in `geocorr2018_tract_to_place.csv` (checked; place code 37692 in that file is Jamestown, IN). They have rows in the subgroup files with every value missing, including South Fulton in 2014, before it was a city.

City subgroup files, missing per year: High-Poverty 201–260, Not High-Poverty 3, Majority Non-White 88–105, No Majority Race/Ethnicity 65–75, Majority White, Non-Hispanic 57–70.

### Known issues
- The index is relative. Tracts are ranked against all other tracts in the same year (`percent_rank()`, line 379), unweighted, so a county's value says where its residents' tracts fall in that year's national distribution, not how much air toxics they're exposed to.
- Higher values mean less hazard, although the variable is named `index_air_hazard`: the summed z-scores are multiplied by −1 before ranking (line 371). Cities average 39–42 and counties 63–70 (data check).
- The rows in the files don't match the code's own row checks. The .qmd stops unless the county files have 3,143 counties a year and the city files 486 (`stopifnot()` at lines 567 and 830), but the committed county all file has 3,141 and the city all file 483 (data check). For cities, the final files are built from `all_enviro_place` (line 946), not from `haz_index_place_all`, the table joined onto the full place list that the check tests, so places with no tracts drop out of the `All` rows.
- A rerun would fail the county row check. Since #606, `crosswalk_puma_to_county.csv` has 3,152 distinct counties across its periods, including the nine Connecticut planning regions, and the county list takes all of them (line 509; data check). That would also add planning-region rows to 2014–2019.
- Values of 0 and 100 are common at the county level: 68 counties are 100 in 2014, 39 in 2018, and 38 in 2019 (data check). Between 2018 and 2019, 96 counties move more than 20 points; the largest is Mariposa County, CA, from 8 to 83.
- The EPA says its assessments shouldn't be used "to characterize or compare risks or exposures at local levels (such as between neighborhoods)" ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions), A4). The subgroup values compare groups of tracts within a county or city.

### Comparability across years
- The EPA says it "can be misleading to compare this version of AirToxScreen with previous assessments", because the emissions inventory, models, background concentrations, health benchmarks, and weather year change between assessments ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions)). 2014 comes from NATA, the predecessor to AirToxScreen.
- Because the index is a within-year rank, changes over time show movement relative to other tracts, not changes in exposure.
- The tract classes use different ACS samples each year (2010–2014, 2014–2018, and 2015–2019), and 2014–2018 and 2015–2019 overlap.
- All three years use 2010 tracts and the 2018 tract-to-county and 2010-place crosswalks.

### Open questions
- Should the metric move to newer years? The EPA has published the 2020 AirToxScreen, at the census block level instead of the tract level ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions), A5), so the tract steps would need to change.
- Which run produced the committed files? Their county and place counts (3,141 and 483 a year) don't match the `stopifnot()` checks in the .qmd.
- Why are Kusilvak and Oglala Lakota missing in 2014? The EPA tracts are recoded to the new county codes, but the 2010–2014 ACS may still use the old codes (02270, 46113), which would leave those tracts without a population weight.
- Should Valdez-Cordova, Chugach, and Copper River get values, and should the three cities missing from the 2010-place crosswalk use a newer one?
- Do the large 2018 drops in rural California and Oregon counties (Mariposa, Siskiyou, Trinity, Curry), which recover in 2019, reflect wildfire emissions in the 2018 assessment?
- The two "Remove results form Puerto Rico and Virgin Islands" notes (lines 248 and 465): the second chunk only selects columns. The "Save … for 2019" notes (lines 998 and 1016) write all three years.
- The rendered `air_toxicity_metric.html` (1.9 MB) is committed. Is it still needed?

# 20_safety-from-trauma

```yaml
metric: Deaths due to injury
predictor: 20_safety-from-trauma
pillar: Healthy Environment and Access to Good Health Care
metric_lead: [Vincent Pancini]
variables: [rate_injury_death, rate_injury_death_lb, rate_injury_death_ub, rate_injury_death_quality]
geographies:
  county: 2014-2024
  place: none
subgroups: [race-ethnicity]
confidence_intervals: true
code:
  - safety-from-trauma.qmd
final_files:
  - data/final/rate_injury_deaths_metric_all_county.csv
  - data/final/rate_injury_deaths_metric_subgroup_county.csv
sources:
  - name: Underlying Cause of Death by Bridged-Race Categories, 1999-2020
    provider: CDC WONDER, National Center for Health Statistics (NCHS)
    vintage: five-year pools ending 2014-2020
    access: manual download; extracts on Box (Urban only)
    url: https://wonder.cdc.gov/ucd-icd10.html
  - name: Underlying Cause of Death by Single-Race Categories, 2018-2024
    provider: CDC WONDER, National Center for Health Statistics (NCHS)
    vintage: pools ending 2021-2024 (2018-2021 is a four-year pool)
    access: manual download; extracts on Box (Urban only)
    url: https://wonder.cdc.gov/ucd-icd10-expanded.html
crosswalks: [geographic-crosswalks/data/county-populations.csv]
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
```

### Summary
Crude rate of deaths from injury per 100,000 people, from CDC WONDER's Underlying Cause of Death data. Each year pools deaths and population over the five years ending that year (four years for 2021). Injury deaths are the ICD-10 codes County Health Rankings uses for its injury deaths measure: accidents, transport, self-harm, assault, undetermined intent, legal intervention, terrorism, and their sequelae. The subgroup file adds four race-ethnicity groups for 2021–2024. Rates are crude, not age-adjusted, in every year.

### Process
1. Download the extracts from CDC WONDER by hand. WONDER's API can't group mortality data by county, so there's no download in code. `safety-from-trauma.qmd` section 1 gives the full query settings. The extracts are also on [Box](https://urbanorg.box.com/s/lqoem3k7kc6nlhcqukudmo8nzw1cz3gn).
   - Bridged-Race, 2014–2020: seven files, `injury_deaths_all_YYYY.txt`, to `data/bridged-race/`
   - Single-Race, 2021–2024: four files, `injury_deaths_all_YYYY.txt`, to `data/single-race/all/`
   - Single-Race subgroups, 2021–2024: sixteen files, `injury_deaths_raceth_{nhwhite,nhblack,hisp,nhother}_YYYY.txt`, to `data/single-race/subgroups/`
   - Each file `YYYY` pools `YYYY` and the four years before it. Single-Race data start in 2018, so 2021 pools 2018–2021.
   - Settings: group by county; measures are deaths, population, crude rate, its 95 percent confidence interval, and its standard error; ICD-10 codes \*U01–\*U03, V01–Y36, Y85–Y87, and Y89; show totals, zero values, and suppressed values.
2. Render `safety-from-trauma.qmd`. It stops if any expected file is missing.
3. Clean: keep the crude rate, its bounds, and its standard error. `Suppressed`, `Unreliable`, and `Missing` become `NA`. The code stops if any death count is 1–9. In the Single-Race files, a rate is set to `NA` when deaths are 0. The bounds and standard error are set to `NA` wherever the rate is `NA`.
4. Fix county codes:
   - Shannon County, SD (46113) becomes Oglala Lakota County (46102), and Wade Hampton Census Area, AK (02270) becomes Kusilvak Census Area (02158), for every year after 2014.
   - Bedford city, VA (51515), Clifton Forge city, VA (51560), and three former Alaska census areas (02201, 02232, 02280) are dropped. WONDER keeps them with zero deaths and population.
   - CDC WONDER still reports Valdez-Cordova, AK (02261) after its 2019 split. Its rate and bounds for 2020–2024 are copied to both Chugach (02063) and Copper River (02066), and 02261 is then dropped.
5. `left_join()` onto `county-populations.csv`.
6. Quality flag from the coefficient of variation (CV), `rate_injury_death_se / rate_injury_death` (see below).
7. Write the all file (2014–2024) and the subgroup file (2021–2024: All plus the four groups). Each is checked with `evaluate_final_data()` against its form in `99a_final-evaluation/`.

### Data quality flag
- `1`: CV below 0.2
- `2`: CV 0.2 to below 0.4
- `3`: CV 0.4 or more, and Chugach and Copper River, AK (02063, 02066) in every year they have a value
- `NA` wherever the rate is `NA`
- All file: 30,544 rows are `1`, 1,171 are `2`, and 10 are `3` (all of them Chugach and Copper River, 2020–2024).
- Subgroup file:

| Subgroup | 1 | 2 | 3 | NA |
|---|---|---|---|---|
| All | 11,133 | 474 | 8 | 960 |
| White, Non-Hispanic | 10,560 | 622 | 8 | 1,385 |
| Black, Non-Hispanic | 3,195 | 669 | 0 | 8,711 |
| Hispanic | 2,200 | 704 | 0 | 9,671 |
| Other Races and Ethnicities | 1,554 | 499 | 4 | 10,518 |

### Missing values
All file (the `All` rows of the subgroup file are the same):

| Year | Missing | Percent |
|---|---|---|
| 2014 | 281 | 8.9 |
| 2015 | 268 | 8.5 |
| 2016 | 268 | 8.5 |
| 2017 | 271 | 8.6 |
| 2018 | 266 | 8.5 |
| 2019 | 267 | 8.5 |
| 2020 | 264 | 8.4 |
| 2021 | 323 | 10.3 |
| 2022 | 268 | 8.5 |
| 2023 | 258 | 8.2 |
| 2024 | 111 | 3.5 |

- 99 counties are missing every year, all small counties whose rates CDC WONDER suppresses or marks unreliable. Most are in Texas (22), Nebraska (20), North Dakota (11), Montana (10), South Dakota (8), and Alaska (7). Kalawao County, HI (15005) is one of them.
- All nine Connecticut planning regions (09110–09190) are missing in 2022–2024, so there are no Connecticut values in those years. CDC WONDER reports the eight old counties.
- 2021 has more missing values because it pools four years instead of five.

Subgroup file, counties missing per year, 2021–2024:
- White, Non-Hispanic: 12–14 percent through 2023, 6 percent in 2024
- Black, Non-Hispanic: 70–74 percent through 2023, 61 percent in 2024
- Hispanic: 78–83 percent through 2023, 67 percent in 2024
- Other Races and Ethnicities: 85–88 percent through 2023, 77 percent in 2024

### Known issues
- 2024 keeps rates based on 10–19 deaths, which every earlier year sets to `NA`. With the 2024 final deaths (February 2026), CDC WONDER changed its "Unreliable" flag from fewer than 20 deaths to a 95 percent confidence interval wider than 160 percent of the rate ([CDC WONDER help, Single-Race](https://wonder.cdc.gov/wonder/help/ucd-expanded.html)). The death counts implied by each row's confidence interval show 141 county rates from fewer than 20 deaths in the 2024 all file, and none in 2014–2023. The subgroup file has 190–312 such rates per group in 2024. This is why missing values drop from 258 to 111 and quality `2` rises from 66 to 222 between 2023 and 2024.
- The quality flag is a death-count cutoff. CDC WONDER's standard error for a crude rate is the rate × √(1/deaths) (same help page, "Standard Errors for Rates"), so CV = 1/√deaths. `1` means about 25 deaths or more, and `2` means 20–25 deaths (10–25 in 2024). A CV of 0.4 needs fewer than 7 deaths, which WONDER suppresses, so `3` is only assigned by the Chugach and Copper River override. The final files match this: every `2` row implies 20–25 deaths in 2014–2023.
- Chugach and Copper River, AK (02063, 02066) have identical values, copied from Valdez-Cordova for 2020–2024 (`assign-vc-death-rate` chunk). In the subgroup file, only White, Non-Hispanic (2021–2024) and Other Races and Ethnicities (2023–2024) are copied. Black, Non-Hispanic and Hispanic stay `NA`.
- The check that the only unmatched counties are Chugach, Copper River, and Connecticut can't fail. The `filter()` in `join-data` joins `GEOID %in% c("02063", "02066")` and the Connecticut condition with a comma (AND), so no row can match both, and `stopifnot(urban_antijoin |> nrow() == 0)` always passes.

### Comparability across years
- Each year pools five years of deaths, so consecutive years share four years of data. 2021 pools four years (2018–2021).
- 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files. Totals are comparable, but race-ethnicity subgroups exist only from 2021.
- Rates are crude, so they move with each county's age mix. The median county rate rose from 74.8 in 2014 to 101.2 in 2024; the .qmd notes some of this could be an older population.
- 2024 uses CDC WONDER's new unreliable-rate rule (see Known issues), so it has fewer missing counties and more quality `2` rows than earlier years.

### Open questions
- Should 2024 drop rates from fewer than 20 deaths to match earlier years, or should earlier years be redownloaded under the new rule?
- The .qmd says the Chugach and Copper River confidence intervals are not copied, but the code copies the bounds (only the standard error is not copied).
- The .qmd says 26,458 rows have a missing quality flag. The final files have 33,130 (1,885 in the all file for 2014–2020, plus 31,245 in the subgroup file).
- Section 2 says it reads 22 extracts; the code expects 27.
- Should the subgroup values for Chugach and Copper River be copied for all four groups, or for none?
- The rendered `safety-from-trauma.html` (6 MB) is committed. Is it still needed?
- Can CDC WONDER provide rates for the Connecticut planning regions?

# 21_political-participation

```yaml
metric: Election turnout
predictor: 21_political-participation
pillar: Responsive and Just Governance
metric_lead: [Aaron R. Williams, JP Walsh, Vincent Pancini, Ridhi Purohit]
variables: [share_election_turnout, share_election_turnout_quality]
geographies:
  county: 2016, 2020, 2024
  place: 2016, 2020
subgroups: none
confidence_intervals: false
code:
  - voter-turnout-2016.Rmd
  - voter-turnout-2020.Rmd
  - voter-turnout-2024.qmd
  - voter-turnout-city-2016.Rmd
  - voter-turnout-city-2020.Rmd
final_files:
  - data/final/voter-turnout-2016-2024.csv
  - data/final/voter-turnout-2016.csv
  - data/final/voter-turnout-2020.csv
  - data/final/voter-turnout-2024.csv
  - data/final/voter-turnout-city-2016.csv
  - data/final/voter-turnout-city-2020.csv
sources:
  - name: County Presidential Election Returns 2000-2024
    provider: MIT Election Data and Science Lab (Harvard Dataverse)
    vintage: 2016, 2020, and 2024 elections
    access: downloaded in code (data use agreement on the landing page)
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ
  - name: Citizen Voting Age Population (CVAP) Special Tabulation
    provider: US Census Bureau
    vintage: 2012-2016, 2016-2020, and 2020-2024 ACS 5-year
    access: downloaded in code
    url: https://www.census.gov/programs-surveys/decennial-census/about/voting-rights/cvap.html
  - name: 2016 Precinct-Level Election Results
    provider: Voting and Election Science Team (VEST, Harvard Dataverse)
    vintage: 2016 election
    access: downloaded in code
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/NH5S2I
  - name: 2020 Precinct-Level Election Results
    provider: Voting and Election Science Team (VEST, Harvard Dataverse)
    vintage: 2020 election
    access: downloaded in code
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/K7760H
  - name: Cartographic boundary files, places
    provider: US Census Bureau (via tigris)
    vintage: 2016 and 2020
    access: downloaded in code
    url: https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
  - name: Voting and Registration in the Election of November 2024 (P20, table 4a)
    provider: US Census Bureau (Current Population Survey)
    vintage: 2024
    access: downloaded in code, validation only
    url: https://www.census.gov/data/tables/time-series/demo/voting-and-registration/p20-587.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/connecticut_planning_regions_to_pre_2023_counties.csv
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
```

### Summary
Votes cast for president divided by the citizen voting-age population (CVAP), for the 2016, 2020, and 2024 elections. Counties use county vote totals from the MIT Election Data and Science Lab. Cities use precinct results from the Voting and Election Science Team (VEST), apportioned to places by area. There is no city file for 2024.

### Process
Each election has its own file. The 2016 and 2020 files are R Markdown (.Rmd); 2024 is Quarto (.qmd).

1. County numerator (MIT county returns):
   - Recode Shannon County, SD (46113) to Oglala Lakota County (46102), and set every Alaska row to `02000`, because MIT reports Alaska by election district.
   - 2016: drop the three rows without a FIPS code, set Bedford County, VA to `NA` (its `totalvotes` is 0), and sum `candidatevotes`.
   - 2020: assign DC its FIPS code (11001), drop the four Rhode Island "FEDERAL PRECINCT" rows, and sum `candidatevotes`.
   - 2024: keep one `totalvotes` per county, since some states have a "total" vote `mode` row that would double count if candidate votes were summed. Then apportion the eight old Connecticut counties to the nine planning regions with `votes * afact` from `connecticut_planning_regions_to_pre_2023_counties.csv` (2020 population shares).
   - Each file compares state totals with a Wayback Machine copy of Wikipedia's results table. The 2024 file also compares with the Census P20 table.
2. County denominator: CVAP `Total` rows from the ACS 5-year special tabulation ending in the election year (2012–2016, 2016–2020, 2020–2024), Puerto Rico dropped.
3. `left_join()` CVAP to the votes, then `share_election_turnout = votes / cvap`. Values above 1 are set to 1.
4. `left_join()` onto `county-populations.csv` for the election year and write the yearly file. The 2024 .qmd also stacks the 2016, 2020, and 2024 files into `voter-turnout-2016-2024.csv`, so it must run last.
5. Cities (`voter-turnout-city-2016.Rmd`, `voter-turnout-city-2020.Rmd`):
   - Download the VEST precinct shapefiles for each state and the place boundaries from `tigris`, and keep the places in `place-populations.csv`.
   - Drop Z/M dimensions and repair invalid precinct geometries.
   - Apportion precinct votes to places by share of precinct area (areal weighted interpolation, `areal`), and record a `messiness` score for how many precincts are split.
   - Divide by the place CVAP from the 2016–2020 tabulation (both years). Only the 2016 city file runs `evaluate_final_data()`.

### Data quality flag
Counties:
- `1`: CVAP coefficient of variation (CV) below 0.05
- `2`: CV of 0.05 or more and under 0.15
- `3`: CV of 0.15 or more
- Every Missouri county is at least `2` in all three years, and every Connecticut planning region is at least `2` in 2024.
- 2016: 2,931 are `1`, 178 are `2`, 3 are `3`. 2020: 2,906, 196, and 10. 2024: 2,900, 207, and 6.

Cities take the worst of three flags: the CV flag above, an interpolation flag (`messiness` below 0.05 is `1`, below 0.1 is `2`, otherwise `3`), and an allocation flag that sets Kentucky and New Jersey to `3` in 2020, because VEST apportioned their 2020 results from larger reporting units.
- 2016: 418 are `1`, 38 are `2`, 29 are `3`. 2020: 408, 42, and 36.

### Missing values
Counties:
- Every Alaska borough and census area: 29 in 2016, 30 in 2020 and 2024 (Valdez-Cordova split in 2020)
- Kalawao County, HI (15005): every year, because MIT reports it with Maui County

Cities: none. The 2016 file has 485 places because `place-populations.csv` has 485 in 2016.

### Known issues
- The 2016 and 2020 .Rmd files can't be rerun as they are. They read and write under `05_local-governance/voter-turnout/`, and their YAML loads `05_local-governance/www/web_report.css`; that folder no longer exists. `voter-turnout-city-2016.Rmd` also reads its evaluation form from `10a_final-evaluation/`, which is now `99a_final-evaluation/`, and `voter-turnout-city-2020.Rmd` writes to `05_local-governance/voter-turnout/voter-turnout-city-2020.csv`, not `data/final/`.
- `data/final/voter-turnout-city-2020.csv` names its columns `election_turnout` and `election_turnout_quality`. The 2016 city file and all county files use `share_election_turnout` and `share_election_turnout_quality`.
- Capped values aren't always flagged. The code says counties with turnout above 1 "will be flagged", but the flag only uses the CV. Hanson County, SD (46061) has turnout set to 1 in 2020 with quality `1`. Sixteen county-years are exactly 1 (4 in 2016, 6 in 2020, 6 in 2024).
- The 2016 city file divides 2016 votes by the 2016–2020 CVAP (`voter-turnout-city-2016.Rmd`, `download-cvap` chunk), while the 2016 county file uses the 2012–2016 CVAP.
- The 2024 Connecticut values assume each old county's votes split across planning regions in proportion to 2020 population (`votes * afact`), not by where votes were cast.
- Area-based apportionment assumes voters are spread evenly within each precinct. The city files keep places with less than 100 percent precinct coverage, mostly because place boundaries include water (`voter-turnout-city-2020.Rmd`, "Place Coverage").
- The county .Rmd and .qmd files don't call `evaluate_final_data()`.

### Comparability across years
- Each county year uses a different CVAP tabulation (2012–2016, 2016–2020, 2020–2024).
- County votes are summed candidate votes in 2016 and 2020 and MIT's `totalvotes` in 2024. The 2020 .Rmd notes the two match in 2020.
- Connecticut has 8 counties in 2016 and 2020 and 9 planning regions in 2024, so its values can't be compared county by county.
- The Kentucky and New Jersey allocation downgrade applies to 2020 cities only.

### Open questions
- Should the 2016 and 2020 .Rmd files be moved to Quarto and have their paths updated, or kept as a record of how those files were built?
- Should `voter-turnout-city-2020.csv` be renamed to `share_election_turnout` to match the other files?
- Is a 2024 city file planned?
- Should the 2016 city file use the 2012–2016 CVAP, as the 2016 county file does?
- The 2020 city .Rmd text says "`1` = messiness > 0.05", but the code assigns `1` when `messiness < 0.05`.
- The 2024 .qmd text says to save the MIT file to `21_political-participation/voter-turnout/data/mit`, but the code uses `21_political-participation/data/mit`.
- The rendered `.html` files for all five .Rmd and .qmd files (2–9 MB each) are committed. Are they still needed?

# 22_descriptive-representation

```yaml
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
```

### Summary
Share of the county or city population in each of four race and ethnicity groups, from the ACS 5-year estimates: Black non-Hispanic, Hispanic (any race), white non-Hispanic, and other (non-Hispanic Asian, American Indian and Alaska Native, Native Hawaiian and Other Pacific Islander, some other race, and two or more races). The four shares sum to 1. These are the denominator of the descriptive representation ratio (share of local elected officials in a group divided by the group's share of residents). The published variables are only these population shares; no ratio with elected officials is computed for any of the five years.

### Process
1. Set `CENSUS_API_KEY` in `.Renviron`. The .qmd calls `census_api_key(Sys.getenv("CENSUS_API_KEY"))`.
2. Set `update_years` at the top of `descriptive_representation_denom.qmd` (currently `c(2014, 2016, 2018, 2021, 2023)`) and render it. For each year it pulls the ACS 5-year estimates for all places and all counties with `get_acs(output = "wide")`. If `load_variables()` can't find the 5-year tables for a year, it pulls the 1-year estimates instead and prints a notice.
3. Variables: total population (`B01003_001`), Hispanic or Latino (`B03003_003`), and the non-Hispanic race counts (`B03002_003` to `B03002_009`). The margins of error are dropped.
4. Other = non-Hispanic Asian + American Indian and Alaska Native + Native Hawaiian and Other Pacific Islander + some other race + two or more races. A check stops the render if the four groups don't add up to the total population (county data only).
5. `left_join()` the ACS data onto `county-populations.csv` and `place-populations.csv` for the update years, on the five-digit county or seven-digit place GEOID, so the target geography list sets the rows.
6. Divide each group by total population. Checks stop the render if any share is outside 0–1 or the four shares don't sum to 1.
7. Set every quality flag to `1`, rename to `share_desc_rep_*`, run `evaluate_final_data()` against `99a_final-evaluation/evaluation_form_desc_rep_overall_place.csv` and `..._county.csv`, and write the two files in `data/final/`.

### Data quality flag
- `1` for every row and variable. The .qmd sets this because the values come from published Census summary tables.
- County file: all 15,713 rows are `1`. City file: all 2,428 rows are `1`.

### Missing values
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

### Known issues
- The quality flag ignores sampling error. Every row is `1` (`descriptive_representation_denom.qmd`, "Create quality flag"), but the margins of error are dropped before the shares are computed. Small counties get shares of exactly 0 or 1 (see Missing values), which are 5-year sample estimates, not counts.
- The other group combines five Census groups, including two or more races (`descriptive_representation_denom.qmd`, "Clean data"). Changes in the other share can't be split into those groups from the final files.
- The 1-year fallback in `read_places()` and `read_counties()` would pull 1-year estimates, which the Census Bureau publishes only for areas of 65,000 people or more ([When to use 1-year or 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/estimates.html)), so most counties would have no data. The check in step 4 only covers counties, and the `left_join()` in step 5 would leave those counties `NA` without stopping the render. The fallback isn't used for any current year.
- The population share check in step 4 runs on the county data only; there is no matching check on the place data before the shares are computed.

### Comparability across years
- The five years are overlapping 5-year periods (2010–2014, 2012–2016, 2014–2018, 2017–2021, 2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
- The other share grows faster after 2018: the median county share is 2.7 percent in 2014, 3.0 percent in 2018, 3.9 percent in 2021, and 4.8 percent in 2023, with the white non-Hispanic share falling by about the same amount.
- There are no values for 2015, 2017, 2019, 2020, 2022, or 2024.

### Open questions
- The predictor publishes only the denominator. `descriptive-representation.Rmd` is the older numerator code: it builds the full ratio for 2018 from the purchased ICMA Municipal Form of Government 2018 Survey (on Box, not publicly shareable). It reads and writes paths under `05_local-governance/`, which no longer exists, sources `05_local-governance/R/census_api_key.R` and `get_vars.R`, which aren't in the repo, and reads `geographic-crosswalks/data/county-file.csv`, which doesn't exist. Its `author:` field is blank. Is the plan to bring back the ratio, and is this file still needed?
- `descriptive-representation.csv` at the folder root is the output of that .Rmd: 2018 county ratios from the ICMA survey, with values for 1,521 of 3,142 counties. It isn't read by any code. Should a file derived from licensed survey data stay in the public repo?
- `fips/all-geocodes-v2018.xlsx` is read only by `descriptive-representation.Rmd`.
- The rendered `descriptive-representation.html` (from the .Rmd) and `descriptive_representation_denom.html` are committed. Are they still needed?
- The .qmd text says the place population file has no 2014 data and 2015 is used instead, but `place-populations.csv` has 2014 rows and the code uses them. It also gives the final data folder as `05_local-governance/descriptive-representation/data/final`.
- `99_construct-database/medians-raceeth.qmd` says "No quality variables for these" for `share_desc_rep_*`, but the final files and the evaluation forms have them.
- Does the faster growth in the other share after 2018 come from the Census Bureau's 2020 changes to race and ethnicity coding, or from population change?

# 23_safety-from-crime

```yaml
metric: Safety from crime (reported violent and property crime)
predictor: 23_safety-from-crime
pillar: Responsive and Just Governance
metric_lead: [Vincent Pancini]
variables: [rate_crime_violent, rate_crime_property, rate_crime_violent_quality, rate_crime_property_quality]
geographies:
  county: 2021-2024
  place: 2021-2024
subgroups: []
confidence_intervals: false
code:
  - reported-crime-county-combined.qmd
  - reported-crime-place-combined.qmd
final_files:
  - data/final/rates_crime_county_all.csv
  - data/final/rates_crime_place_all.csv
sources:
  - name: National Incident-Based Reporting System (NIBRS), Offense Segment, processed by Jacob Kaplan
    provider: Federal Bureau of Investigation (FBI), via openICPSR
    vintage: 2021-2024, V11 (August 2025), file offense_segment_rds_1991_2024.zip
    access: manual download after a data use agreement; on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Batch Header Segment, processed by Jacob Kaplan
    provider: Federal Bureau of Investigation (FBI), via openICPSR
    vintage: V11 (August 2025), file nibrs_batch_header_1991_2024.rds
    access: manual download after a data use agreement; on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: Law Enforcement Agency Identifiers Crosswalk (LEAIC)
    provider: Bureau of Justice Statistics (BJS), via ICPSR (NACJD study 35158)
    vintage: 2012 (V2)
    access: manual download with an ICPSR account; on Box
    url: https://www.icpsr.umich.edu/web/NACJD/studies/35158
  - name: American Community Survey (ACS) 5-year, total population (B01003_001)
    provider: US Census Bureau
    vintage: 2017-2021 through 2020-2024
    access: downloaded in code with tidycensus (Census API key)
    url: https://www.census.gov/programs-surveys/acs
crosswalks: [geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
```

### Summary
Reported violent crimes and reported property crimes per 100,000 people, from the FBI's National Incident-Based Reporting System (NIBRS). Offenses reported by each police agency are assigned to counties (weighted by county population when an agency covers more than one county) or to places, then divided by the ACS 5-year population. "Violent" here means NIBRS crimes against persons and "property" means NIBRS crimes against property, so robbery counts as property crime (see Known issues). The quality flag measures the share of police agencies in the county or place that reported any offenses.

### Process
1. For the place file only: render `geographic-crosswalks/generate_county_place_crosswalks.qmd` first. It writes `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv`, which is not committed (#648).
2. Download Jacob Kaplan's NIBRS files from [openICPSR project 118281](https://www.openicpsr.org/openicpsr/project/118281) (V11) after accepting the data use agreement. Unzip `offense_segment_rds_1991_2024.zip` and move `nibrs_offense_segment_2021.rds` through `nibrs_offense_segment_2024.rds` to `data/offense-segment/`. Move `nibrs_batch_header_1991_2024.rds` (from `batch_header_rds_1991_2024.zip`) to `data/batch-header-segment-and-agencies/`. Harvard Dataverse has 2021–2023 only. The files for this update are on Box.
3. Download the 2012 LEAIC from [ICPSR study 35158](https://www.icpsr.umich.edu/web/NACJD/studies/35158) (Delimited) and move `35158-0001-Data.tsv` to `data/batch-header-segment-and-agencies/`. Both data folders are gitignored by the folder's `.gitignore`.
4. Install a Census API key for `tidycensus` (the `census_api_key()` line in each .qmd is commented out).
5. Render `reported-crime-county-combined.qmd` and `reported-crime-place-combined.qmd`, in either order.
6. Offenses: each `ucr_offense_code` is classified with the crimes-against table from section 2.3 of the [2021.1 NIBRS User Manual](https://bjs.ojp.gov/sites/g/files/xyckuh236/files/sarble/data_common/nibrs-user-manual-2021-1041521.pdf). Person offenses are violent, property offenses are property, and society offenses are counted only in the unused `all` total. Offenses are counted by agency (`ori`) and year.
7. Batch Header: keep 2021–2024, title-case state names, fix Nebraska (`NB` to `NE`) and "Wyoming V2", drop Guam, Puerto Rico, and the Virgin Islands, drop `state police` agencies, and add state FIPS codes by matching on state name and abbreviation.
8. County file:
   - Agencies with no `fips_county_code_1` get a county from the LEAIC (`FIPS_COUNTY`) by ORI.
   - Reshape to one row per agency and county (up to five counties per agency) and join onto ACS 5-year county population (`B01003_001`), with ACS counties as the left side.
   - Each agency's weight in a county is that county's population divided by the total population of all counties the agency lists. Offense counts are multiplied by the weight and summed by county.
9. Place file, assigning a place FIPS code to each agency in three passes (each pass only handles agencies the previous ones missed):
   - LEAIC `FPLACE`, joined by ORI
   - The agency's city name, matched by state and year to `place-populations.csv` after dropping " city", " town", " village", and " municipality" and fixing six names by hand (Ventura, Fort Lauderdale, Augusta, Indianapolis, St. Louis, Winston-Salem)
   - The county-place crosswalk, for agencies whose first listed county overlaps only one of the 486 places (the 2020–2021 GeoCorr rows for 2021, the version with Connecticut planning regions for 2022–2024)

   Agencies in the 486 places are kept and their offense counts summed by place, without weights, then joined onto ACS 5-year place population.
10. Rate = count / population × 100,000. An agency counts as reporting if it has any record in the Offense Segment that year. Rates are `NA` when no agency in the county or place reported or the population is under 30.
11. County only: Loving County, TX (48301) is set to `NA` every year and Kenedy County, TX (48261) in 2023, because of very high rates on populations under 100.
12. Rates are set to `NA` wherever the quality flag is `NA`. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/`.

### Data quality flag
Based on the share of agencies in the county or place that reported (for counties, the unweighted share of agency-county pairs):
- `1`: all agencies reported
- `2`: 80 percent or more reported, or all core-city agencies reported
- `3`: more than 0 and under 80 percent reported
- `NA`: no agency reported, or there is no agency in the Batch Header for the county or place

The violent and property flags are identical in both files, and so are their missing values. County file, all years: 3,736 are `1`, 2,345 are `2`, 5,513 are `3` (44 percent), and 981 are `NA`. Place file: 1,097 are `1`, 431 are `2`, 147 are `3`, and 269 are `NA`.

### Missing values
County file, counties missing per year: 287 in 2021 (9.1 percent), 248 in 2022, 233 in 2023, and 213 in 2024 (6.8 percent). Pennsylvania has the most (50 in 2021, 30 in 2024), followed by Indiana (22–26), Florida (33 in 2021, 16 in 2024), Mississippi (17–19), and New York (16–19). Specific gaps:
- District of Columbia (11001): every year
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year
- Loving County, TX (48301): every year; Kenedy County, TX (48261): 2023 (both suppressed in code)
- All nine Connecticut planning regions (09110–09190): 2022, so there are no Connecticut values that year. The eight old counties have values in 2021 and the planning regions have values in 2023 and 2024.
- Kalawao County, HI (15005): every year

Place file, places missing per year: 110 in 2021, 62 in 2022, 54 in 2023, and 43 in 2024. The 43 missing in 2024 are missing every year: 25 in California (for example Lancaster, Palmdale, Santa Clarita, Compton, Moreno Valley, and Huntington Beach), 12 in Florida (for example Orlando, Miami Beach, and Pompano Beach), Athens-Clarke County and South Fulton, GA, Urban Honolulu CDP, HI, Rochester Hills, MI, Syracuse, NY, and Washington, DC. Most of the 2021 gap is California (72 places).

Zeros: 17–20 counties a year have a violent crime rate of exactly 0 and 13–21 have a property crime rate of 0. Among places, 6 have a violent rate of 0 in 2021 (among them Tempe, Hayward, Jacksonville, and Savannah), and none after that.

### Known issues
- All New York City crime is assigned to New York County. The New York County (36061) violent crime rate is 13,453 per 100,000 in 2023 and 14,050 in 2024, while the four other boroughs are missing every year and the New York city place rate is 2,571 and 2,699 (`data/final/` files). This happens because each agency's offenses are split only across the counties it lists in the Batch Header (`reported-crime-county-combined.qmd`, section 4.4e). The old `documentation/overview.md` described the same problem and used New York State county data for the five boroughs instead.
- District of Columbia is missing from both files every year. `str_to_title()` turns the state name into "District Of Columbia" (`reported-crime-county-combined.qmd` line 326; the rendered .html shows `District Of Columbia DC 12`), which doesn't match "District of Columbia" in the hand-built state FIPS table (line 422), so DC agencies get no state FIPS code and drop out. The same lines are in the place .qmd (288 and 373).
- "Violent" is NIBRS crimes against persons, not the FBI violent crime definition (murder and nonnegligent manslaughter, rape, robbery, and aggravated assault; [FBI](https://ucr.fbi.gov/crime-in-the-u.s/2019/crime-in-the-u.s.-2019/topic-pages/violent-crime)). It includes simple assault and intimidation and leaves out robbery, which NIBRS classifies as a crime against property (`reported-crime-county-combined.qmd` lines 107, 108, and 155). The old `documentation/overview.md` used the FBI definitions.
- An agency counts as reporting if it has any offense that year, however few months it reported. The months-reported filter is commented out (`number_of_months_reported`, county line 348, place line 299). Agencies that reported part of the year get full credit in the quality flag but low rates: New York city has a violent rate of 5.19 per 100,000 in 2021 with quality `2`, and Phoenix has 0.69–0.86 every year (quality `3`). In 2021, 38 places have a violent rate under 50 per 100,000, and 16 of them are quality `1` or `2`.
- The denominator is the full ACS population even when some agencies in the county or place didn't report, so quality `2` and `3` rates are biased down (section 5 of each .qmd).
- The place file's third pass gives every remaining agency in a county (for example the sheriff, a university, or a tribal agency) to the only one of the 486 places in that county, and it uses only the agency's first listed county (`reported-crime-place-combined.qmd` lines 471 and 693). The .qmd notes the first-county shortcut itself.
- The county quality flag uses the unweighted share of agencies reporting. The population-weighted shares (`agencies_reporting_violent_wt` and `agencies_reporting_property_wt`) are computed but not used.

### Comparability across years
- NIBRS coverage grows each year: 12,538 agencies have offenses in 2021 and 13,662 in 2024 (rendered .html), and missing counties fall from 287 to 213. Some large cities report only part of a year early on (New York city: 5 violent crimes per 100,000 in 2021, 92 in 2022, 2,571 in 2023; Los Angeles: missing in 2021, about 5 in 2022–2023, 1,002 in 2024), so changes across years mostly reflect reporting, not crime.
- All years are rerun with each new Kaplan release because agencies backfill earlier years, so values for the same year differ between metric updates.
- 2021 uses the eight old Connecticut counties and 2023–2024 use the nine planning regions.
- The LEAIC is from 2012, so agencies created since then can't be matched through it.
- Not comparable with the pre-2021 versions, which used UCR summary data with imputation and the FBI violent and property crime definitions.

### Open questions
- `data/final/` also holds `rate_arrests_county_all.csv`, `rate_arrests_county_all_subgroup.csv`, `rate_arrests_place_all.csv`, and `rate_arrests_place_all_subgroup.csv`. They are the juvenile arrest files from `24_just-policing`, with 2021–2023 only (the `24_just-policing/data/final/` copies have 2021–2024), committed in c23a32dc. Can they be deleted?
- Why are all nine Connecticut planning regions missing in 2022 but not in 2023 or 2024?
- What does `agency_indicator` value `5` mean? 4,142 Batch Header rows (4.7 percent) have it, and they are kept. The .qmd says it may be a preprocessing error.
- Why are 43 places missing every year, including some with their own police departments (Orlando, Syracuse, Huntington Beach)? Is Urban Honolulu CDP's agency (Honolulu Police Department) matched to a different place code?
- Should New York City crime be split across the five boroughs (by population, or with New York State data as before)?
- Some counts in the .qmd prose are from earlier runs. The place .qmd says 2,224 agencies are still unmatched after the three passes, and the rendered .html shows 3,186.
- The rendered `reported-crime-county-combined.html` and `reported-crime-place-combined.html` are committed. Are they still needed?

# 24_just-policing

```yaml
metric: Just policing (juvenile arrests per 100,000 juveniles)
predictor: 24_just-policing
pillar: Responsive and Just Governance
metric_lead: [Vincent Pancini]
variables: [rate_juv_arrest, rate_juv_arrest_quality]
geographies:
  county: 2021-2024
  place: 2021-2024
subgroups: [race-ethnicity, gender, age]
confidence_intervals: false
code:
  - juvenile-arrests-county-combined.qmd
  - juvenile-arrests-place-combined.qmd
final_files:
  - data/final/rate_arrests_county_all.csv
  - data/final/rate_arrests_county_all_subgroup.csv
  - data/final/rate_arrests_place_all.csv
  - data/final/rate_arrests_place_all_subgroup.csv
sources:
  - name: National Incident-Based Reporting System (NIBRS) Arrestee Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: 2021-2024 per-year .rds files from V11 (August 2025)
    access: manual download after a data use agreement; raw files on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Group B Arrest Report Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: 2021-2024 per-year .rds files from V11 (August 2025)
    access: manual download after a data use agreement; raw files on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Batch Header Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: nibrs_batch_header_1991_2024.rds from V11 (August 2025)
    access: manual download after a data use agreement; raw file on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: Law Enforcement Agency Identifiers Crosswalk (LEAIC), 2012
    provider: Bureau of Justice Statistics (BJS), via the National Archive of Criminal Justice Data (NACJD) at ICPSR
    vintage: ICPSR 35158 V2
    access: manual download with an ICPSR account
    url: https://www.icpsr.umich.edu/web/NACJD/studies/35158
  - name: American Community Survey (ACS) 5-year estimates, tables B01003, B01001, and B01001A-B01001I
    provider: US Census Bureau
    vintage: 2017-2021 through 2020-2024
    access: API (tidycensus::get_acs()), needs a Census API key
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
```

### Summary
Arrests of juveniles ages 10–17 per 100,000 juveniles ages 10–17, from the FBI's National Incident-Based Reporting System (NIBRS), for 2021–2024. Each arrest, citation, or summons counts, so the rate counts arrests, not people arrested. The denominator is the ACS 5-year population ages 10–17. The subgroup files repeat the rate by race and ethnicity (four groups), gender, and age (10–14 and 15–17). Earlier years aren't produced because too few agencies reported to NIBRS before 2021.

### Process
1. Download from [Jacob Kaplan's NIBRS files on openICPSR](https://www.openicpsr.org/openicpsr/project/118281) (V11) after accepting the data use agreement: `arrestee_segment_rds_1991_2024.zip`, `group_b_arrest_report_segment_rds_1991_2024.zip`, and `batch_header_rds_1991_2024.zip`. Save the 2021–2024 `.rds` files to `data/arrestee-segment/` and `data/group-b-arrest-report-segment/`, and `nibrs_batch_header_1991_2024.rds` to `data/batch-header-segment-and-agencies/`. The files for this update are on Box (link in each .qmd).
2. Download the 2012 LEAIC from [ICPSR 35158](https://www.icpsr.umich.edu/web/NACJD/studies/35158) (Delimited) and save `35158-0001-Data.tsv` to `data/batch-header-segment-and-agencies/`. All four data folders are gitignored.
3. Install a Census API key for `tidycensus` (the .qmd has the commented-out `census_api_key()` call).
4. For the place file, first render `geographic-crosswalks/generate_county_place_crosswalks.qmd`, which writes `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv` (not committed, #648). The county file doesn't need it.
5. Render `juvenile-arrests-county-combined.qmd` and `juvenile-arrests-place-combined.qmd`, in either order. Each writes its two final files.
6. Arrests (both files): stack the Arrestee (Group A) and Group B segments, which don't overlap ([Kaplan, Decoding FBI Crime Data](https://ucrbook.com/arrestee.html)). `age_of_arrestee` becomes numeric, so "over 98 years old" and "unknown" become `NA`. The all-age file is kept for the quality flag; the juvenile file keeps ages 10–17. Each agency (`ori`) and year gets counts of juvenile arrests in total and by group:
   - White: `race_of_arrestee == "white"`
   - Black: `race_of_arrestee == "black"`
   - Hispanic: `ethnicity_of_arrestee == "hispanic or latino"`, any race
   - Other Races and Ethnicities: Asian, Native Hawaiian or Other Pacific Islander, and American Indian/Alaska Native
   - Male, Female, Age 10 to 14, Age 15 to 17
7. Agencies (both files): keep 2021–2024 from the Batch Header Segment, normalize the casing of state names and abbreviations, drop Guam, Puerto Rico, and the Virgin Islands, recode `NB` to `NE` and "Wyoming V2" to "Wyoming", and add state FIPS codes from a table in the .qmd joined on state name and abbreviation. Drop state police agencies. `core_city` becomes 1 or 0.
8. County file: agencies with no county get one from the LEAIC by `ori`. Reshape to one row per agency and county (up to five counties per agency). An agency in more than one county is split by county total population (`B01003_001`), so each county gets `total_people / sum(total_people)` of the agency's arrests. Sum the weighted counts to the county.
9. Place file: give each agency a place code in three passes, keeping only the first county (`county_fips_1`):
   - By `ori`, from the LEAIC place code (`FPLACE`).
   - Agencies still without a place: by year, state, and lowercase name, from `place-populations.csv`, with " city", " municipality", " village", and " town" removed and six names edited by hand (Ventura, Fort Lauderdale, Augusta, Indianapolis, St. Louis, Winston-Salem).
   - Agencies still without a place: by county, from `county_place_crosswalk_longitudinal.csv` (all years pooled), for counties that overlap exactly one of the 486 places.

   Keep agencies in the 486 places and sum their arrests to the place, with no weights.
10. Denominators: ACS 5-year population ages 10–17 by county or place, from `B01001` (total, sex, and age) and `B01001A`, `B01001B`, and `B01001I` (white alone, Black alone, Hispanic). Other Races and Ethnicities is American Indian/Alaska Native, Asian, Native Hawaiian or Other Pacific Islander, some other race, and two or more races (the last computed as the total minus the single races). Rate = arrests / population × 100,000, set to `NA` when the population is under 30. The ACS rows set the universe: 3,143 counties in 2021, 3,144 from 2022 on (with the Connecticut planning regions), and 486 places.
11. Quality flag (section 6 of each .qmd): an agency is reporting if it has at least one arrest of any age in either segment that year. The flag compares the share of agencies reporting in the county or place, and the share of core-city agencies reporting. When the flag is `NA`, every rate in the row is set to `NA`.
12. Subgroup files: one row per county or place, year, and subgroup. Every subgroup takes the overall quality flag, set to `NA` when the subgroup population is under 30.
13. Each .qmd ends with `evaluate_final_data()` against the overall, race-ethnicity, gender, and age forms in `99a_final-evaluation/`.

### Data quality flag
- `1`: every agency in the county or place reported
- `2`: at least 80 percent of agencies reported, or every core-city agency reported
- `3`: some agencies, but fewer than 80 percent, reported
- `NA`: no agency reported, there is no agency in the county or place, or the population ages 10–17 is under 30
- County file: 3,414 county-years are `1`, 2,349 are `2`, 5,773 are `3` (46 percent), and 1,039 are `NA`, out of 12,575. By year, `3` is 1,414–1,460.
- Place file: 1,015 place-years are `1`, 498 are `2`, 154 are `3`, and 277 are `NA`, out of 1,944. `1` rises from 222 places in 2021 to 271 in 2024.

### Missing values
`rate_juv_arrest` is `NA` exactly where the quality flag is `NA`.

County file, counties missing per year: 308 (2021), 266 (2022), 243 (2023), 222 (2024).
- 149 counties are missing every year. The most are in Pennsylvania (31), Mississippi (17), Indiana (15), New York (15), Florida (14), and Alaska (10).
- District of Columbia (11001): every year (see Known issues)
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year (see Known issues)
- All nine Connecticut planning regions (09110–09190): 2022. They have values in 2023 and 2024, and the eight old counties have values in 2021.

County subgroup file, counties missing per year:
- Black: 1,371–1,390
- Hispanic: 661–753
- Other Races and Ethnicities: 368–574, falling each year
- White, Male, Female, and both age groups: within 15 of the All count each year

Place file, places missing per year: 116 (2021), 63 (2022), 54 (2023), 44 (2024).
- 43 places are missing every year: 25 in California (for example Compton, Lancaster, Palmdale, and Santa Clarita), 12 in Florida (for example Orlando, Miami Beach, and Pompano Beach), Washington, DC (11-50000), Urban Honolulu CDP, HI (15-71550), South Fulton and Athens-Clarke County, GA, Rochester Hills, MI, and Syracuse, NY.
- Los Angeles city (06-44000): 2021

Place subgroup file: every subgroup is missing for the same places as All, except Black (121, 67, 57, and 48 places a year).

### Known issues
- The District of Columbia has no values in any year, at county or place level. `str_to_title()` turns "district of columbia" into "District Of Columbia" (section 4.2, both .qmd files), which doesn't match "District of Columbia" in the state FIPS table, so DC's agencies get no state FIPS and drop out. The rendered county .html shows "District Of Columbia DC 12" in the state count. The 2025 release had DC values (for example 1,096 in 2021, quality `2`, in commit 98ec1b5c). The casing step was added in the 2026 update.
- All New York City juvenile arrests land in New York County (36061). Its rate is 7,515 in 2023 and 8,172 in 2024, about 8 times the New York city place rate (958 and 1,063), and the other four boroughs are `NA` every year because no reporting agency is linked to them. The old `documentation/overview.md` described the same problem in the UCR data and replaced the New York City counties with New York State data.
- The quality flag counts an agency as reporting if it had at least one arrest of any age that year (`reporting = ifelse(is.na(arr_total_allage), 0, 1)`, section 6.1), and the `number_of_months_reported` filter is commented out (section 4.2). An agency that reported part of the year looks complete. Examples: New York city is 1.0 per 100,000 in 2021 with quality `2` (1,063 in 2024); Boynton Beach, FL is 0 in 2021 with quality `1` (2,895 in 2024). Places under 50 per 100,000 with quality `1` or `2`: 18 in 2021, 12 in 2022, 5 in 2023, and 7 in 2024.
- A rate of 0 can mean no juvenile arrests or no reporting by the agencies that make juvenile arrests: arrest counts are summed with `na.rm = TRUE` (section 4.4g and 4.8). 344–395 counties a year are exactly 0, and 207–261 of those are quality `3`. 10–20 places a year are 0, among them Jacksonville, FL and Anchorage, AK in three or more years.
- In the place file, the county pass (section 4.5) gives every agency still without a place the only one of the 486 places in its county, with no filter on agency type. A sheriff's office or university police in such a county counts toward the city. It uses only the agency's first county (`county_fips = county_fips_1`, section 4.2), which the .qmd itself flags.
- White and Black include Hispanic arrestees in the numerator and Hispanic juveniles in the denominator (race-alone tables `B01001A` and `B01001B`), and Hispanic overlaps both. NIBRS has no "some other race" or two-or-more-races code, but the Other Races and Ethnicities denominator includes both groups, so that rate is biased down. Arrestees of unknown race count only toward All, Male, Female, and the age groups.
- County rates are split across counties by total population, not population ages 10–17 (`weight = total_people / sum(total_people)`, section 4.4e).
- Outliers: the highest county rate is 24,209 (Dewey County, SD, 46041, 2023, quality `3`), and the highest place rate is 21,894 (Dayton, OH, 2023, quality `2`). In the county subgroup file, 20 county-years of the Black subgroup are above 100,000, with a max of 248,207.

### Comparability across years
- NIBRS coverage grows every year, so changes mostly reflect more agencies reporting (section 7 of each .qmd says the same). The median county rate goes from 570 (2021) to 698 (2024), and the median place rate from 913 to 1,281. Los Angeles city goes from missing (2021) to 1.7 (2022) and 172 (2024).
- Every update reruns all years with Kaplan's latest release, since agencies backfill earlier years (section 0.1), so a year's values change between releases.
- The 2026 release labels the white subgroup "White". The 2025 release labeled the same calculation "White, Non-Hispanic" (98ec1b5c).
- Connecticut uses the eight old counties in 2021 and the nine planning regions from 2022 on.
- The denominators are overlapping ACS 5-year samples (2017–2021 to 2020–2024), which the Census Bureau advises against comparing ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).

### Open questions
- Why are the Connecticut planning regions missing in 2022 but not in 2023 or 2024?
- Are some of the 43 places missing every year policed by a county sheriff under contract (for example Lancaster, Palmdale, and Santa Clarita)? If so, should those cities get the sheriff's arrests, or stay missing?
- Agencies with `agency_indicator` "other agencies" (5,202 agency-years) and "5" (4,142, meaning unclear per section 4.2a) are kept. Should state agencies in those groups be dropped like the state police?
- Should the quality flag use `number_of_months_reported`, which section 4.2 has commented out?
- The 2012 LEAIC is the latest version. Is there a newer agency-to-county or agency-to-place crosswalk?
- The .qmd prose has stale numbers and names: the county .qmd says 971 of 1,113 agencies with no county are in the LEAIC (the render prints 1,298), the place .qmd says 2,224 agencies still have no place (the render prints 3,186), section 7 says "2021-2022", and the place .qmd calls the crosswalk `geocorr2022_county_place.csv` and the place list "2016-2022".
