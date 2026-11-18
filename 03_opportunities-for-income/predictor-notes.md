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

## Methodology
- **Unit**: households, one record each, weighted by the American Community Survey (ACS) household weight. Group quarters, such as institutions and college dorms, are excluded. Income is the ACS total household income for the past 12 months (`hhincome`); households with zero or negative income are kept.
- **Dollars**: all values are in 2024 dollars. Income is multiplied by the IPUMS `adjust` factor (which puts income reported over different 12-month periods into survey-year dollars), by the IPUMS USA CPI99 factor for the survey year, and by the IPUMS CPS CPI99 factor for 2024.
- **Samples**: the all files use the 1-year ACS for each year. The subgroup files use the 5-year ACS, labeled by the last year of the period (e.g., `2014` is 2010–2014).
- **Subgroups**: each household takes the race and ethnicity or the sex of its householder (person number 1 in the household).
  - Race and ethnicity: Hispanic householders of any race are Hispanic. Non-Hispanic householders are White, Black, or Other Races and Ethnicities, which combines all other single races and people of two or more races.
  - Gender: Male or Female, from the householder's ACS sex question.
- **Geography**: ACS microdata identify Public Use Microdata Areas (PUMAs), not counties or places. Each household's weight is multiplied by the crosswalk's allocation factor (`afact`, the share of the PUMA's population in that county or place), so a household in a PUMA that spans several counties counts partly toward each. Survey years before 2022 use a crosswalk for the earlier PUMA boundaries; 2022 and later use one for the 2020 PUMA boundaries.
- **Small samples**: a geography, or a subgroup within it, is suppressed when its effective sample (the sum of `afact` across its household records) is below 30.
- **Percentiles and confidence intervals**: the 20th, 50th, and 80th percentiles are weighted quantiles, with 95 percent confidence intervals from the 80 ACS household replicate weights (successive difference replication).

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

## Comparability across years
- There is no 2020: `existing_years` skips it in both all .qmd files.
- PUMA boundaries change in 2022, and the code switches crosswalks at that year (`crosswalk_period`).
- The subgroup years are 5-year samples that overlap: 2014 (2010–2014), 2016 (2012–2016), and 2018 (2014–2018) share survey years, so changes between them are smaller than year-to-year changes in the all files.
