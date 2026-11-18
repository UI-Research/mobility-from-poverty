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

### Methodology
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

### Data quality flag
- `share_employed_quality` is the crosswalk's `geographic_allocation_quality`, averaged over the records in the geography with `unweighted(mean())` (`R/calc_survey_mean.R`). The crosswalk sets it from `sum_products`: `1` if 0.75 or more, `2` if 0.35 or more, `3` otherwise (`geographic-crosswalks/generate_puma_county_crosswalks.qmd` and `generate_puma_place_crosswalks.qmd`).
- Suppressed geographies (effective sample below 30) get `NA` for both the metric and the flag.
- County all file: 5,669 rows are `1`, 4,531 are `2`, 16,042 are `3` (51 percent), and 5,191 are `NA`. Place all file: 1,427 are `1`, 2,530 are `2`, 896 are `3`, and 7 are `NA`.

### Missing values
- County all file: 488–544 counties a year (about 16–17 percent) are suppressed for an effective sample below 30. In 2014 and 2024, every suppressed county had a population of 15,000 or less (`county-populations.csv`).
- Place all file: South Fulton city, GA (1372122) in 2014–2021; no missing places from 2022 on.
- County subgroup files, pooled over the five years: Black, Non-Hispanic is missing for 64 percent of county-years, Hispanic for 60 percent, Other Races and Ethnicities for 63 percent, and White, Non-Hispanic for 4 percent. With Disability is missing for 31 percent; Female and Male for 5 percent each; All for 2 percent.
- Place subgroup files: Black, Non-Hispanic is missing for 18 percent of place-years; every other subgroup for 2 percent or less.

### Comparability across years
- No 2020: the all files skip 2020 (`existing_years`), so 2019 to 2021 is a two-year change.
- PUMA boundaries changed in 2022, and the crosswalk changes with them (`crosswalk_period`), so geographic allocation and quality flags can shift between 2021 and 2022.
- The subgroup files are 5-year estimates for 2014, 2016, 2018, 2021, and 2023; consecutive releases overlap in years.

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

### Methodology
- **Numerator**: Quarterly Census of Employment and Wages (QCEW) annual average weekly wage for all jobs covered by unemployment insurance in the county, across private and government employers. QCEW counts jobs where they are located, and counts full- and part-time jobs alike ([BLS Handbook of Methods](https://www.bls.gov/opub/hom/cew/concepts.htm)). Zero wages and establishment counts are treated as missing.
- **Denominator**: the Living Wage Institute (LWI) hourly living wage for a household of one adult and two children, multiplied by 40 hours to get a weekly living wage.
- **Living wage years**: values are in nominal dollars of each year, to match QCEW wages. Years without their own LWI file are filled with the Consumer Price Index for All Urban Consumers (CPI-U):
  - 2014–2018: the 2018 file, adjusted to each year with the CPI-U
  - 2019–2022: the 2022 file, treated as 2022 dollars and adjusted to each earlier year by the CPI-U relative to 2022
  - 2023: the 2023 file, unadjusted
  - 2024: the LWI Benchmark Series file, unadjusted
- **Geography**: QCEW and LWI values are matched by county Federal Information Processing Standards (FIPS) code. County-years present in only one source have no value. QCEW's "unknown or undefined" county (`999`) is dropped.
- **Industry groups**: the industry file uses QCEW supersector codes.
  - Goods Producing: `101`
  - Trade, Transit, Utilities: `1021`
  - Information Services: `1022`
  - Professional Services: `1023` (financial activities) and `1024` (professional and business services)
  - Education and Health: `1025`
  - Leisure and Other: `1026` (leisure and hospitality) and `1027` (other services)
  - Public Administration: all jobs at federal, state, and local government employers (QCEW [ownership codes](https://www.bls.gov/cew/classifications/ownerships/ownership-titles.htm) 1–3), not the QCEW public administration supersector
- **Combined groups**: for groups built from more than one code, the weekly wage is the simple average of the codes' weekly wages, and establishment counts are summed.

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

### Comparability across years
- The 2024 living wage comes from a different LWI product (the Benchmark Series) than 2023.
- Within 2014–2018 and within 2019–2022, the living wage comes from one file, so changes within those blocks reflect wage growth and the CPI-U only.
- Public Administration has far fewer missing counties from 2022 on.

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

### Methodology
- **Unit**: households, one record each, weighted by the American Community Survey (ACS) household weight. Group quarters, such as institutions and college dorms, are excluded. Income is the ACS total household income for the past 12 months (`hhincome`); households with zero or negative income are kept.
- **Dollars**: all values are in 2024 dollars. Income is multiplied by the IPUMS `adjust` factor (which puts income reported over different 12-month periods into survey-year dollars), by the IPUMS USA CPI99 factor for the survey year, and by the IPUMS CPS CPI99 factor for 2024.
- **Samples**: the all files use the 1-year ACS for each year. The subgroup files use the 5-year ACS, labeled by the last year of the period (e.g., `2014` is 2010–2014).
- **Subgroups**: each household takes the race and ethnicity or the sex of its householder (person number 1 in the household).
  - Race and ethnicity: Hispanic householders of any race are Hispanic. Non-Hispanic householders are White, Black, or Other Races and Ethnicities, which combines all other single races and people of two or more races.
  - Gender: Male or Female, from the householder's ACS sex question.
- **Geography**: ACS microdata identify Public Use Microdata Areas (PUMAs), not counties or places. Each household's weight is multiplied by the crosswalk's allocation factor (`afact`, the share of the PUMA's population in that county or place), so a household in a PUMA that spans several counties counts partly toward each. Survey years before 2022 use a crosswalk for the earlier PUMA boundaries; 2022 and later use one for the 2020 PUMA boundaries.
- **Small samples**: a geography, or a subgroup within it, is suppressed when its effective sample (the sum of `afact` across its household records) is below 30.
- **Percentiles and confidence intervals**: the 20th, 50th, and 80th percentiles are weighted quantiles, with 95 percent confidence intervals from the 80 ACS household replicate weights (successive difference replication).

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

### Comparability across years
- There is no 2020: `existing_years` skips it in both all .qmd files.
- PUMA boundaries change in 2022, and the code switches crosswalks at that year (`crosswalk_period`).
- The subgroup years are 5-year samples that overlap: 2014 (2010–2014), 2016 (2012–2016), and 2018 (2014–2018) share survey years, so changes between them are smaller than year-to-year changes in the all files.

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

### Methodology
- **County measure**: share of people with a credit bureau record who have any debt in collections, as published in Debt in America. Debt in America is built from a sample of deidentified credit records (Debt in America Technical Appendix 2025).
- **City measure**: the Financial Health and Wealth Dashboard's `delinquent_debt` share, which measures derogatory debt rather than debt in collections alone, so it differs from the county measure.
- **Years**: each year is the value the source publishes for that year; no years are interpolated or filled. The 2018 county values come from an earlier Debt in America county file. Medical debt in collections is not included.
- **Subgroups**: neighborhoods of color and white neighborhoods are defined by the racial makeup of each person's zip code, not by the person's race. Since the 2023 data, majority-white communities are zip codes where at least 50 percent of residents are white, non-Hispanic ([Debt in America Technical Appendix 2025](https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2025/11/19/Debt%20in%20America%20Technical%20Appendix%202025.pdf)). The dashboard's "Residents of color" and "White" city subgroups are relabeled to the same names.
- **Geography**: counties are the county Federal Information Processing Standards (FIPS) codes Debt in America reports. For Connecticut that means the eight pre-2022 counties in every year, because the credit data provider hasn't moved to the planning regions (Technical Appendix 2025). Cities are matched to place FIPS codes by city name, using the IPUMS large place to PUMA match file; cities without a match are dropped.
- **Missing values**: values the source marks as unavailable (`n/a*`, `n/a**`, or `NA`) are set to missing. The values are not suppressed further, and there are no confidence intervals.

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

### Comparability across years
- 2022 and 2023 on: Debt in America changed the threshold for communities of color and majority-white communities from 60 percent to 50 percent, so the race-ethnicity breakdowns aren't directly comparable across that break (Technical Appendix 2025, footnote 2). The All values aren't affected by the threshold.
- Earlier Debt in America editions used a 2 percent sample; the 2025 edition uses a 4 percent sample (Technical Appendix 2025).
- City values (2019, 2021, 2023) measure derogatory debt and county values (2018, 2022, 2023, 2025) measure debt in collections, so city and county values shouldn't be compared directly.
- Medical debt was removed in 2026 because the three nationwide credit reporting companies changed medical debt reporting starting in 2022, which lowered the share with medical debt on credit records but not necessarily the share with medical debt (`county-debt-coll-shares.qmd` overview; Technical Appendix 2025, footnote 6).

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

### Methodology
- **Unit**: households, represented by the householder's record (person 1) in ACS 1-year microdata. Group quarters, institutional and noninstitutional, are excluded. Each household is weighted by the household weight (`hhwt`); replicate weights aren't used, so there are no confidence intervals.
- **Household share**: weighted households in the group divided by all weighted households in the geography, counting renters and owners.
- **Housing value share**: among owner-occupied households (with or without a mortgage), the weighted sum of the group's self-reported home value (`valueh`) divided by the weighted sum for all owner households in the geography. Mortgage debt isn't subtracted, so this is gross home value, not equity. Households with missing or N/A `valueh` are excluded.
- **Race and ethnicity**: assigned from the householder. Anyone of Hispanic origin is Hispanic. Non-Hispanic householders are white, Black, or other; other combines American Indian or Alaska Native, Asian, Pacific Islander, some other race, and two or more races.
- **Age subgroups**: the householder's age, Under Age 45 or Age 45 and Over. Both shares are computed within the age group, so the denominators are all households (or all owner households) of that age in the geography.
- **Geography**: ACS microdata identify public use microdata areas (PUMAs). When IPUMS identifies a household's county, it is assigned to that county in full. Otherwise, and for every place, the household is spread across the counties or places its PUMA overlaps, with `hhwt` multiplied by the crosswalk allocation factor (`afact`). Years before 2022 use 2012 PUMAs; 2022 on use 2020 PUMAs and Connecticut's planning regions.
- **Small samples**: a ratio is reported only when the geography's population in the crosswalk is over 30 (see Data quality flag). Every county and place in the Urban county and place population files gets a row, with `NA` where a group has no estimate.

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

### Comparability across years
- There is no 2020: the .qmd drops the 2020 1-year ACS, which the Census Bureau [released as experimental](https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2020/1-year.html).
- The PUMA crosswalk changes in 2022, from 2012 PUMAs to 2020 PUMAs, and Connecticut switches from 8 counties to 9 planning regions.
- The place files have 485 places in 2014–2017 and 486 from 2018 on, matching `place-populations.csv` (South Fulton, GA, is added in 2018).

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

### Methodology
- **Universe**: children ages 3 and 4 in ACS 5-year microdata, including those in households and in group quarters. The year is the last year of the 5-year sample (for example, `2014` is 2010–2014).
- **Numerator**: children whose grade attending (`GRADEATT`) is nursery school or preschool.
- **Denominator**: children in nursery school or preschool, in kindergarten, or not attending school. A `GRADEATT` of N/A is treated as not in school. Children ages 3 and 4 reported in first grade or higher are excluded.
- **Weights and confidence intervals**: estimates use the person weight (`perwt`). The 95 percent confidence intervals come from the 80 ACS person replicate weights (variance scaled by 4/80, as the Census Bureau specifies for ACS replicate weights) and are truncated to the 0–1 range.
- **Race and ethnicity**: the child's own race and Hispanic origin. Any Hispanic origin is Hispanic. Non-Hispanic children are White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities, which includes everyone else, including multiracial children.
- **Income**: the total income of the child's household (`HHINCOME`), split at $50,000 into Less than $50,000 and $50,000 or More. The same cutoff applies in every year. Children with no household income value, including those in group quarters, are left out of the income subgroups but kept in the overall share.
- **Geography**: ACS microdata identify public use microdata areas (PUMAs), not counties or places. Each child is spread across the counties or places their PUMA overlaps, with the person weight and every replicate weight multiplied by the crosswalk allocation factor (`afact`). 2014–2021 use 2012 PUMAs; 2023 uses 2020 PUMAs.
- **Small samples**: the effective sample is the sum of `afact` across children in the geography (or geography and subgroup). Estimates with an effective sample under 30 are suppressed and reported as `NA`.

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

### Comparability across years
- Each year is a 5-year ACS sample, so neighboring years overlap (for example, 2014 and 2016 share 2012–2014).
- The code joins 2014–2021 to the pre-2022 crosswalk period and 2023 to the 2022 period (2020 PUMAs), so the county and place allocation changes in 2023.
- Connecticut has its 8 old counties through 2021 and its 9 planning regions in 2023.

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

### Methodology
- **Scores**: SEDA 6.0 mean English language arts (reading/language arts) test scores on the grade cohort standardized (GCS) scale, which places state test results from EDFacts on a common national scale linked to the National Assessment of Educational Progress (NAEP). One unit is about one grade level of learning.
- **Cohorts**: a cohort is the set of students who reach eighth grade in the same spring. Each estimate follows one cohort through grades 3–8 (for example, third grade in spring 2010 through eighth grade in spring 2015). `year` is the fall of that cohort's eighth-grade school year, so `2014` is the cohort in eighth grade in 2014–15.
- **Learning rate**: for each cohort and subgroup, a regression of mean score on grade, with a separate intercept and grade slope for each county (or school district), weighted by the number of test-takers in each grade. The county's grade slope is its learning rate. Grades with no score or no test-takers are left out, so an estimate can rest on fewer than six grades (see Data quality flag).
- **Confidence intervals**: the slope plus or minus 1.96 standard errors from that regression.
- **Subgroups**: SEDA's own groups: White, Non-Hispanic; Black, Non-Hispanic; Hispanic; Male; Female; Economically Disadvantaged; and Not Economically Disadvantaged.
- **Counties**: estimates come directly from SEDA's county file.
- **Cities**: estimates are computed for SEDA geographic school districts, then combined. Each district is assigned in full to the city named in its Common Core of Data (CCD) directory record (`city_location`), matched to the place name and state. City values (the rate and both bounds) are the mean of the district values, weighted by each district's test-takers in that subgroup and cohort; the quality flag is the rounded weighted mean of the district flags.

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

### Comparability across years
- Each year is a different cohort: `year` = the year the cohort reaches eighth grade, minus 1, and the estimate uses that cohort's scores from grades 3–8.
- New York (2018–2019) and Alaska (2019) drop out entirely, which changes the set of counties behind any state or national comparison in those years.

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

### Methodology
- **High-poverty school**: a school whose MEPS share of students at or below 100 percent of the federal poverty level is 20 percent or more. Schools with no MEPS value are not counted as high poverty.
- **Numerator**: Black, Hispanic, or White students enrolled in high-poverty schools in the county or city, from Common Core of Data (CCD) enrollment by race and ethnicity, all grades combined.
- **Denominator**: all students of that group enrolled in schools in the county or city, including schools without a MEPS value. Schools with missing or zero total enrollment in the CCD directory are excluded. When a group has no students enrolled, the share is `NA`.
- **Race and ethnicity**: the CCD categories Black, Hispanic, and White, as reported by schools. There is no value for all students or for other groups.
- **Schools counted**: every school in the CCD directory with enrollment, regardless of school type.
- **Year**: `year` is the fall of the school year, and MEPS and CCD are matched by school and year, so `2014` uses 2014–15 enrollment and 2014–15 MEPS.
- **Counties**: each school is assigned to the county in its CCD directory record.
- **Cities**: each school is assigned to the city named in its CCD directory record (`city_location`), matched to the place name and state, not to the place boundary. Place names are standardized for the match by dropping suffixes such as "city" and "town" and by renaming 10 consolidated or differently spelled cities by hand (for example, "Louisville/Jefferson County metro government (balance)" to "Louisville").

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

### Comparability across years
- `year` is the fall of the school year: 2014 is the 2014–15 school year and 2022 is 2022–23.
- 2022 county rows use Connecticut's nine planning regions (09110–09190), as in `county-populations.csv`; earlier years use the eight old counties.
- The average county share falls every year from 2014 to 2020 and then rises in 2021 (Black students: 53 percent in 2014, 30 percent in 2020, and 37 percent in 2021; the other groups follow the same pattern).
- Illinois cities have no 2015 values.

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

### Methodology
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

### Comparability across years
- The years are overlapping 5-year samples: 2014 (2010–2014), 2016 (2012–2016), 2018 (2014–2018), 2021 (2017–2021), and 2023 (2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)). Nonoverlapping pairs are 2014 and 2021, 2016 and 2021, 2014 and 2023, 2016 and 2023, and 2018 and 2023.
- 2023 uses 2020 PUMAs and the 2022 crosswalk period. Place quality flags shift sharply: 125 places are `3` in 2021 and 7 in 2023.
- Connecticut uses its eight old counties through 2021 and its nine planning regions (09110–09190) in 2023.

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

### Methodology
- **Unit**: households, not people. Each household is represented by its householder record, and people in group quarters are excluded. Households are weighted by the ACS household weight (`HHWT`).
- **Numerator**: households with high-speed internet installed (`CIHISPEED`: cable modem, fiber optic, or DSL) and at least one desktop, laptop, or tablet computer (`CILAPTOP` or `CITABLET`).
- **Denominator**: all households, whether they have an internet subscription, access without a subscription, or no internet access (`CINETHH`). Households without a subscription, and households with high-speed internet but no computer, count as not having access.
- **Excluded records (2023)**: IPUMS suppressed `CIHISPEED` for some Public Use Microdata Areas (PUMAs) in the 2019–2023 sample ([IPUMS](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)). Those households are dropped from both numerator and denominator.
- **Geography**: the ACS identifies PUMAs, and for counties with large enough populations, the county (`COUNTYFIP`). For counties, a household with an identified county counts in that county with its full weight. Otherwise it is assigned to every county its PUMA overlaps, with its weight multiplied by the allocation factor (`afact`), the share of the PUMA's population in that county. For places, every household is assigned this way. Counties and places that share PUMAs can get the same value. 2018 and 2021 use 2010 PUMAs, and 2023 uses 2020 PUMAs, each with the matching crosswalk.
- **Subgroups**: assigned by the householder's race and ethnicity and by household income.
  - Race and ethnicity: Hispanic if the householder is Hispanic, regardless of race. Non-Hispanic householders are White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities (all other races, including two or more races).
  - Income: total household income (`HHINCOME`) less than $50,000, or $50,000 or more. The threshold is the same nominal dollar amount in every year.
- **Small samples**: a geography, or a geography and subgroup, with fewer than 30 household records after the crosswalk is reported as missing. Each record in a PUMA counts toward every county or place the PUMA overlaps.
- **No confidence intervals**: the ACS replicate weights aren't used, so values have no confidence intervals.

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

### Comparability across years
- Years are 5-year samples that overlap: 2018 (2014–2018) and 2021 (2017–2021) share 2017 and 2018.
- 2018 and 2021 use 2010 PUMAs and the 2012 crosswalks; 2023 uses 2020 PUMAs and the 2022 crosswalks. IPUMS assigns 2020 PUMAs to every year of the 2019–2023 sample ([PUMA](https://usa.ipums.org/usa-action/variables/PUMA)). The PUMA change moves many places to better quality flags: place quality `3` drops from 125 to 7.
- Connecticut uses its eight old counties in 2018 and 2021 and its nine planning regions in 2023.
- Part of 2023 is affected by the `CIHISPEED` suppression for some PUMAs, which the code drops ([IPUMS comparability notes](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)).

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

### Methodology
- **Numerator**: housing units affordable at the threshold, counting occupied units and vacant units on the market (for rent, for sale, or rented or sold but not yet occupied). A unit is affordable when 12 months of housing costs are at or below 30 percent of the threshold. For the affordable and available ratio, an occupied unit counts only if the household living in it has income at or below the threshold; every affordable vacant unit counts.
- **Denominator**: households with income (`HHINCOME`) at or below the threshold. Only households are counted; group quarters are excluded.
- **Thresholds**: 30, 50, and 80 percent of area median income (AMI) are the US Department of Housing and Urban Development (HUD) Section 8 income limits for a four-person household (`eli_4`, `l50_4`, `l80_4`) for the fiscal year matching the ACS year. The same limit applies to every household and unit, with no adjustment for household size or number of bedrooms.
- **Housing costs**: renters use gross rent (`RENTGRS`, contract rent plus utilities) and owners use selected monthly owner costs (`OWNCOST`). Incomes and costs are put in the survey year's dollars with the ACS adjustment factor (`ADJUST`).
  - Vacant for rent: contract rent times the household-weighted average ratio of gross rent to contract rent among occupied rentals in the same geography and year.
  - Vacant for sale: the monthly payment on a 30-year mortgage for 90 percent of the home's value at 0.5 percent monthly interest, plus private mortgage insurance of 0.7 percent of the loan a year, plus property taxes equal to 25 percent of principal and interest. These assumptions are the same in every year.
- **Tenure subgroups**: `Owner` compares owner-occupied and for-sale vacant units with owner households at or below the threshold; `Renter` compares renter-occupied and for-rent vacant units with renter households at or below the threshold.
- **Geography**: the ACS identifies Public Use Microdata Areas (PUMAs), not counties or places. Each occupied unit is assigned to every county or place its PUMA overlaps, with its household weight multiplied by the allocation factor (`afact`), the share of the PUMA's population in that county or place. Vacant units are matched to counties and places through their PUMA with the same crosswalk. Years through 2021 use 2010 PUMAs and 2022–2024 use 2020 PUMAs.
- **Income limits by geography**: HUD publishes limits mostly by county; where limits are by town (New England), they are averaged within each county, and from 2022 Connecticut towns are grouped into the nine planning regions. Valdez-Cordova, AK, limits are applied to Chugach and Copper River after 2019. A place's limit is the population-weighted average of the limits of the counties it overlaps, from GeoCorr county-to-place crosswalks.
- **Small samples**: a cell is reported as missing when fewer than 30 sampled households at or below the threshold, in that tenure group, are allocated to the geography (household records summed with `afact`, not the survey weight).
- **No confidence intervals**: the ACS replicate weights aren't used, so values have no confidence intervals.

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

### Comparability across years
- PUMAs change in 2022: 2010 PUMAs through 2021 and 2020 PUMAs from 2022. Place quality flags shift with them (places flagged `3` drop from 125 to 7).
- No 2020 estimates, because of the quality of the 2020 ACS 1-year data (comment at line 751).
- Connecticut has eight counties through 2021 and nine planning regions from 2022, so Connecticut county values can't be compared across 2021 and 2022.
- For-sale vacant unit costs use the same mortgage assumptions every year (0.5 percent monthly interest, 10 percent down, 0.7 percent mortgage insurance, taxes at 25 percent of principal and interest), so changes in actual mortgage rates aren't reflected.

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

### Methodology
- **Numerator**: students enrolled in public schools who experienced homelessness at any point during the school year, as reported by local education agencies (LEAs, i.e., school districts) to EdFacts (Data Group 655). This uses the McKinney-Vento definition of homelessness ([42 U.S.C. 11434a](https://www.law.cornell.edu/uscode/text/42/11434a)), which includes students sharing housing with others because of loss of housing or economic hardship, not only those in shelters or unsheltered.
- **Denominator**: Common Core of Data (CCD) enrollment for the same LEAs and year. Race and ethnicity shares divide by enrollment of that group (e.g., Black students experiencing homelessness / Black students enrolled).
- **Year**: `year` is the fall of the school year, so `2014` is school year 2014–15.
- **Suppressed LEA counts**: EdFacts suppresses counts of 0–2 students. Each suppressed LEA count is set to 1, with a lower bound of 0 and an upper bound of 2. When a state-year has two or fewer suppressed LEAs, the upper bound is the smallest reported count in that state-year instead, because of complementary suppression. `count_homeless_lb` and `count_homeless_ub` come from these bounds, not from sampling error, and the share has no bounds.
- **Geography**: each LEA is assigned in full to the county and city in its CCD directory record. Districts that cross county or city lines aren't split. Cities are matched to LEAs by city name, so a city served by a countywide district (e.g., most of Florida) gets no value.
- **Subgroups**: Black, Hispanic, and White, Non-Hispanic come straight from EdFacts. Other Races and Ethnicities combines Asian, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, and two or more races. Race and ethnicity data start in school year 2019–20.
- **Small counts**: geographies with fewer than 10 students experiencing homelessness are suppressed rather than reported as 0 (see Missing values).

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

### Comparability across years
- 2014–2018 counts come from the EdFacts CSV files and 2019–2022 from EdDataExpress. Both are Data Group 655.
- Race and ethnicity subgroups only exist from 2019 on.
- Connecticut has 8 counties through 2021 and 9 planning regions in 2022, so the county file has 3,144 rows in 2022 (matching `county-populations.csv`).
- Place files have 485 rows for 2014–2017 and 486 from 2018 on (South Fulton, GA added), matching `place-populations.csv`.
- The 2026 R translation reproduces the earlier Stata files (removed in d5d72c44) closely. Of 22,148 county-years with values in both, 188 have shares that differ by more than 0.001. 3 county-years and 9 place-years have values now that were missing before, and none went the other way.

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

### Methodology
- **Universe**: people for whom poverty status is determined in American Community Survey (ACS) table B17001 (`B17001_001`). The Census Bureau doesn't determine poverty status for people in institutional group quarters, military group quarters, or college dormitories, or for unrelated individuals under age 15 ([How the Census Bureau measures poverty](https://www.census.gov/topics/income-poverty/poverty/guidance/poverty-measures.html)). Tracts with no one in this universe are dropped.
- **High-poverty tract**: a census tract where more than 40 percent of the poverty universe is below the poverty line. The tract's overall poverty rate decides this for every race-ethnicity group, so a group's members count as living in a high-poverty tract based on the whole tract, not on the group's own rate.
- **Numerator and denominator**: people in poverty who live in high-poverty tracts, divided by all people in poverty in the county or city. Both are sums of tract counts.
- **Year**: `year` is the end year of an ACS 5-year sample, so `2014` is 2010–2014.
- **Subgroups**: each group uses its own B17001 iteration. Black is B17001B (Black alone) and Hispanic is B17001I. White, Non-Hispanic is B17001H. Other Races and Ethnicities is the sum of B17001C–G (American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races). The race tables other than B17001H include Hispanic people, so Hispanic people are also counted in Black or Other Races and Ethnicities. A group with no people in poverty gets 0 before suppression.
- **Margins of error**: the Other Races and Ethnicities margin of error combines the five group margins as a root sum of squares, counting only the largest margin among groups with a zero estimate, as the [Census Bureau recommends](https://www.census.gov/content/dam/Census/programs-surveys/acs/guidance/training-presentations/20180418_MOE_Webinar_Transcript.pdf). These margins feed the quality flag only; the exposure share has no confidence interval.
- **Geography**: counties sum the tracts inside them. Cities allocate tract counts to places with the Geocorr population allocation factor (`afact`, the share of a tract's population in the place): the 2010-tract-to-2014-place crosswalk for 2014–2018, the 2020 crosswalk for 2021, and the 2020 crosswalk with Connecticut tracts recoded to planning regions for 2023. A tract partly in a city is classified as high poverty using the whole tract's rate.
- **Small counts**: a value is suppressed when the group's estimated number of people in poverty in the county or city is 30 or less.

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

### Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (for example, 2010–2014 and 2012–2016). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2014–2018 use 2010 tract boundaries and 2021–2023 use 2020 boundaries, so which tracts cross the 40 percent line can change between 2018 and 2021 because of the redrawn tracts alone.
- City values for 2014–2018 come from a 2010-tract-to-2014-place crosswalk and later values from a 2020 crosswalk.
- Connecticut: the 2014–2021 county files use the eight old counties, and 2023 uses the nine planning regions (09110–09190), so there are 3,144 county rows in 2023.

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

### Methodology
- **Groups**: four mutually exclusive groups built from American Community Survey (ACS) 5-year data profile table DP05: Hispanic (any race); Black, Non-Hispanic; White, Non-Hispanic; and Other Races and Ethnicities, the sum of non-Hispanic American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races. The four groups add up to total population (B01003) in every tract, and that total is the tract denominator. The DP05 variable codes change across years, so each year maps its own codes to the groups.
- **Measure**: for each group, the average share of a group member's census tract neighbors who belong to the other three groups. Each tract's other-groups share is weighted by the share of the county's or city's group members who live in that tract. For example, if 80 percent of a county's White, Non-Hispanic residents live in a tract that is 10 percent other groups and 20 percent live in a tract that is 50 percent other groups, `share_white_nh_exposure` is 0.8 × 0.1 + 0.2 × 0.5 = 0.18.
- **Neighborhood**: the census tract. The other-groups share divides by the tract's full population, including the group's own members.
- **Year**: `year` is the end year of an ACS 5-year sample, so `2016` is 2012–2016.
- **Geography**: county values use the tracts inside each county. City values allocate tract group counts to places with the Geocorr population allocation factor (`afact`, the share of a tract's population in the place): the 2010-tract-to-2014-place crosswalk for 2016 and 2018, the 2020 crosswalk for 2021, and the 2020 crosswalk with Connecticut tracts recoded to planning regions for 2023. A tract's other-groups share is the same whether all or part of the tract is in the city.
- **Margins of error**: the Other Races and Ethnicities margin of error combines the five group margins as a root sum of squares, counting only the largest margin among groups with a zero estimate, as the [Census Bureau recommends](https://www.census.gov/content/dam/Census/programs-surveys/acs/guidance/training-presentations/20180418_MOE_Webinar_Transcript.pdf). Hispanic margins for controlled estimates, which the Census Bureau reports as `-555555555`, are set to 0. These margins feed the quality flag only; the exposure shares have no confidence intervals.
- **Small counts**: a group's value is suppressed when the group's estimated count in the county or city is 30 or less.

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

### Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (2012–2016 and 2014–2018 share three years). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2016 and 2018 use 2010 tract boundaries, and 2021 and 2023 use 2020 boundaries. Because exposure depends on how people are split across tracts, redrawn tracts alone can change values between 2018 and 2021. City values also switch from the 2010-tract-to-2014-place crosswalk to the 2020 crosswalk.
- Connecticut uses its eight old counties through 2021 and the nine planning regions (09110–09190) in 2023.
- Average White, Non-Hispanic exposure rises every year, from 0.204 (2016) to 0.229 (2023) across counties and from 0.429 to 0.473 across cities (checked in the final files).

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

### Methodology
Membership associations:

- **Numerator**: establishments (`ESTAB`) in the 10 North American Industry Classification System (NAICS) codes County Health Rankings uses (813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920). Codes come from NAICS 2012 for 2014–2016 and NAICS 2017 from 2017 on. The measure counts establishments, not members or participants.
- **Sources by geography**: counties use County Business Patterns (CBP) county counts. Cities use ZIP code counts, from ZIP Code Business Patterns (ZBP) for 2014–2018 and CBP ZIP code data for 2019–2023.
- **Denominator**: population from the project's county and place population files (Census Bureau Population Estimates Program and decennial census counts), for the same year. The rate is establishments / (population / 10,000), rounded to one decimal place as County Health Rankings does.
- **City allocation**: each ZIP code is treated as its ZIP Code Tabulation Area (ZCTA). Its establishment count is allocated to places with the GeoCorr ZCTA-to-place allocation factor, which is based on population, and summed by place.
- **Publication rules**: from reference year 2017, CBP publishes an industry cell only when it has three or more establishments ([CBP methodology](https://www.census.gov/programs-surveys/cbp/technical-documentation/methodology.html)), so a county or ZIP code with one or two establishments in a code counts 0 for that code from 2017 on. A county with no published establishments in any of the 10 codes is missing, not 0.

Economic connectedness:

- **Measure**: the Social Capital Atlas county and ZIP code economic connectedness (`ec_county`, `ec_zip`), which is twice the share of above-median-SES friends among people with below-median SES ([Chetty et al. 2022 working paper](https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf)). Values are multiplied by 0.5 to report the share itself. One cross-section, labeled `2022`.
- **County**: atlas values are used as published, matched to the 2020 county list. The atlas reports Valdez-Cordova, AK (02261), which split into Chugach and Copper River in 2019; that value is dropped rather than assigned to the new areas.
- **Confidence intervals (county)**: the atlas standard error (`ec_se_county`) is halved, and `share_economic_connectedness_lb` and `share_economic_connectedness_ub` are the share ± 1.96 × that standard error (95 percent). Cities have no bounds.
- **City**: the atlas ZIP codes are 2010 ZCTAs. Each place's value is the mean of its ZCTAs' values, weighted by `ZCTAinPlace`, the share of the ZCTA's area inside the place (2010-ZCTA-to-2021-place crosswalk). ZCTAs without an atlas value are left out of the mean.

### Data quality flag
Membership associations:

- **County**: `1` whenever there's a value, `NA` otherwise. 30,322 rows are `1` and 1,104 are `NA`.
- **City**: based on how well ZCTAs fit the place, using the same rule as `geographic-crosswalks/generate_puma_county_crosswalks.qmd`. For each place, `sum_products` is the sum over ZCTAs of (share of the ZCTA in the place × share of the place in the ZCTA). `1`: 0.75 or more; `2`: 0.35 to 0.75; `3`: below 0.35. 4,850 rows are `1` and 6 are `2` (South Fulton, GA, 2018–2023); none are `3`.

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

### Comparability across years
- Membership associations: 2014–2016 and 2017–2023 aren't comparable because of the 2017 CBP publication change (see Methodology). The NAICS vintage also changes from 2012 to 2017 in 2017; the .qmd says the 10 codes mean the same thing in both.
- City membership associations come from ZBP for 2014–2018 and CBP ZIP code data for 2019–2023.
- Connecticut: the county file has the 8 old counties through 2021 and the 9 planning regions in 2022–2023, all with values.
- Economic connectedness is a single cross-section (2022 release), so there's no change over time to compare.

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

### Methodology
- **Measures**: tract values from the Center for Neighborhood Technology (CNT) Housing and Transportation (H+T) Affordability Index for CNT's regional moderate-income household, which earns 80 percent of the regional area median income (AMI). `share_transit_commuter` is CNT's `pct_transit_commuters_80ami` (transit ridership as a share of workers) and `share_transportation_cost` is `t_80ami` (transportation costs as a share of income), both converted from percentages to proportions. These are CNT's modeled values for that household, not measured spending of the households living in the tract.
- **Years**: `year` is the CNT tract file year (2015, 2019, or 2022). The American Community Survey (ACS) 5-year data used for neighborhood types and quality flags end in the same year (2011–2015, 2015–2019, 2018–2022).
- **Aggregation**: county and city values are means of tract values, weighted by the number of households in each tract from the CNT file. Tracts with no households are dropped.
- **Cities**: tracts are assigned to places with GeoCorr tract-to-place allocation factors (`afact`, the share of the tract's population in the place), and each tract's weight is its households × `afact`. 2015 and 2019 use the 2010-tract-to-2014-place crosswalk and 2022 the 2020-tract crosswalk (`geocorr2022_tract_to_place.csv`). A tract partly in a city contributes its whole-tract value.
- **Neighborhood types**: each tract is classified by its ACS table B03002 race and ethnicity shares. White neighborhoods are at least 60 percent White, non-Hispanic; neighborhoods of color are at least 60 percent people of all other races and ethnicities, including Hispanic people of any race; mixed neighborhoods are everything else. The subgroup describes the tract, not the household, and a tract partly in a city keeps its whole-tract type. Tracts with no ACS population have no type.

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
- All seven Connecticut cities (Bridgeport, Danbury, Hartford, New Haven, Norwalk, Stamford, and Waterbury): 2022

City subgroups, cities missing per year: neighborhoods of color 82–96, White neighborhoods 57–82, mixed neighborhoods 66–73. The `All` rows add South Fulton in 2019 and the Connecticut cities in 2022.

### Comparability across years
- 2015 and 2019 use 2010 tracts and the 2010-tract-to-2014-place crosswalk; 2022 uses 2020 tracts and the 2020 crosswalk.
- Connecticut uses its eight old counties in 2015 and 2019 and its nine planning regions in 2022, and has no city values in 2022.
- CNT changes its model and inputs between releases ([H+T Index methods, November 2022](https://htaindex.cnt.org/about/method-2022.pdf), which describes changes made in earlier releases). The share of counties with no transit commuters jumps from 15 percent in 2015 to 61 percent in 2019 and 43 percent in 2022, so county transit changes across years mix real change with model changes.
- The ACS inputs used for quality and subgroups are 5-year samples, so 2015 (2011–2015) and 2019 (2015–2019) share 2015.

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

### Methodology
- **Numerator**: total county population from `county-populations.csv`. In every county-year that matches the Area Health Resources File (AHRF), it equals the population AHRF reports.
- **Denominator**: AHRF's count of nonfederal primary care physicians (PCPs), excluding residents (`phys_nf_prim_care_pc_exc_rsdt_*` and the matching 2021–2022 release variables), which comes from the American Medical Association (AMA) Physician Masterfile. PCPs are MDs and DOs under age 75 in general practice, family medicine, internal medicine, and pediatrics. Nurse practitioners, physician assistants, and hospital residents aren't counted.
- **Ratio**: population divided by PCPs, rounded to a whole number. It's people per physician, so higher values mean fewer physicians per person.
- **Zero physicians**: follows the County Health Rankings suppression rule. A county with 0 PCPs gets a ratio of 0 if it has 2,000 or fewer people and `NA` if it has more, treating a reported 0 in a larger county as a likely false zero.
- **Vintages**: each year comes from one AHRF release (see Comparability across years). 2020 is in both the 2021–2022 and 2022–2023 releases with the same values; the 2021–2022 release is used.
- **Geography**: county only, since AHRF has no city data. AHRF counties are matched to `county-populations.csv` by FIPS code. For 2014, AHRF's codes for Oglala Lakota, SD and Kusilvak, AK are recoded to the codes the county file uses for that year (46113 and 02270). Counties that no longer exist are dropped, as are all Connecticut rows for 2021 and 2022, so Connecticut has no values after 2020. Valdez-Cordova, AK (02261) is used through 2019 and Chugach and Copper River (02063, 02066) from 2020.

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

### Comparability across years
- Each year comes from one AHRF release: 2014–2020 from the 2021–2022 release, 2021 from the 2022–2023 release, and 2022 from the 2023–2024 release. Starting with the 2022–2023 release, AHRF only includes the two most recent years of each variable (.qmd section 2), so later releases can't be used to rebuild earlier years.
- Missing values rise from 134 in 2014 to 179 in 2022, mostly from more false zeros, so the set of counties with a value changes across years.
- Alaska: Valdez-Cordova (02261) through 2019, Chugach and Copper River (02063, 02066) from 2020. Connecticut has no values after 2020.

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

### Methodology
- **Numerator**: births under 2,500 grams (CDC WONDER's five birthweight categories below 2,500 grams) to mothers living in the county, for one calendar year.
- **Denominator**: births in every birthweight category except "Unknown or Not Stated," so births with an unknown birthweight are excluded from both counts.
- **Small counties**: CDC WONDER reports counties with 100,000 or more people in the 2010 Census on their own and combines all others into one "Unidentified Counties" row per state ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)). Each county without its own row gets its state's "Unidentified Counties" births and low birthweight births, separately for each subgroup, so all small counties in a state share one value. Cape May County, NJ and Portsmouth city, VA, which CDC WONDER moved into "Unidentified Counties" after 2013, also get the pooled value.
- **Suppressed and small counts**: CDC WONDER suppresses counts of 1–9 births. Suppressed counts become `NA`, so the share is `NA`, while counts of 0 are kept. Shares based on fewer than 30 births are set to `NA`.
- **Subgroups**: race and ethnicity use the mother's single race and Hispanic origin. Hispanic includes any race, and Other Races and Ethnicities combines non-Hispanic American Indian or Alaska Native, Asian, Native Hawaiian or Other Pacific Islander, and more than one race. Mother's education groups are:
  - Less than High School: 8th grade or less, or 9th–12th grade with no diploma
  - GED/High School Degree: high school graduate or GED
  - Some College: some college credit but no degree, or an associate degree
  - College Degree or Higher: bachelor's, master's, doctorate, or professional degree
- **Confidence intervals**: 95 percent normal approximation for a proportion, p ± 1.96 × √(p × (1 − p) / B), where B is births with a known birthweight, following the NCHS User Guide to the 2010 Natality Public Use File. For counties with their state's pooled value, B is the pooled births, so the interval describes the pooled share.
- **Connecticut**: CDC WONDER still reports the eight old counties for 2022–2024, so those rows aren't used and the nine planning regions are `NA` in those years.
- **Units**: `rate_low_birth_weight` is a share between 0 and 1 (low birthweight births / all births), not a rate per population.

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

### Comparability across years
- The same counties are identified in every year (2010 Census populations): 578 through 2021 and 570 from 2022, when Connecticut's eight drop out. The pooling is consistent across 2016–2024, but a pooled county's value moves with its state's small-county births, not its own.
- Connecticut has values for the eight old counties through 2021 and none for 2022–2024.
- Alaska has Valdez-Cordova (02261) through 2019 and Chugach (02063) and Copper River (02066) from 2020, following `county-populations.csv`.
- The previous round's quality rule also gave a `2` to counties with 10–29 low birthweight births; that rule was dropped in this update (section 1.1 of the .qmd).

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

### Methodology
- **Hazard measures**: three Environmental Protection Agency (EPA) modeled estimates for each census tract: `total_cancer_risk_per_million`, `total_respiratory_hazard_quotient`, and `total_neurological_hazard_quotient`. 2014 comes from the National Air Toxics Assessment (NATA) and 2018 and 2019 from AirToxScreen.
- **Tract index**: within each year, each measure is converted to a z-score across tracts, the three are summed, and the sum is multiplied by −1. Tracts are then given their national percentile rank (0–100, unweighted by population), so higher values mean less hazard compared with other tracts in the same year.
- **Tracts**: all three years use 2010 tracts. Only tracts in the 2015–2019 American Community Survey (ACS) tract list are kept, which drops the EPA's nontract rows, after 25 tract codes that changed after 2010 are recoded. Puerto Rico and the US Virgin Islands are excluded.
- **County and city values**: the mean of the tract index, weighted by tract population from the ACS 5-year table B01003 (2010–2014 for 2014, 2014–2018 for 2018, and 2015–2019 for 2019). Tracts with no index are left out of the mean and counted toward the quality flag.
  - Counties: each tract is assigned in full to its county with `tract-county-crosswalk_2018.csv`.
  - Cities: tracts are assigned with `geocorr2018_tract_to_place.csv`, and each tract's weight is its population × `afact`, the share of the tract's population in the place.
- **Race-ethnicity subgroups**: tracts, not people, are classified by the share of residents who are people of color (total population minus White, Non-Hispanic, from ACS table B03002): Majority Non-White is 60 percent or more, No Majority Race/Ethnicity is more than 40 and less than 60 percent, and Majority White, Non-Hispanic is 40 percent or less. A subgroup value is the population-weighted mean index of the county's or city's tracts in that class, so it describes neighborhoods, not residents of a given race or ethnicity.
- **Poverty subgroups**: High-Poverty tracts have a poverty rate of 40 percent or more among people for whom poverty status is determined (ACS table B17001); all others are Not High-Poverty. Tracts are weighted by total population, not by the number of people in or out of poverty.

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

### Comparability across years
- The EPA says it "can be misleading to compare this version of AirToxScreen with previous assessments", because the emissions inventory, models, background concentrations, health benchmarks, and weather year change between assessments ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions)). 2014 comes from NATA, the predecessor to AirToxScreen.
- Because the index is a within-year rank, changes over time show movement relative to other tracts, not changes in exposure.
- The tract classes use different ACS samples each year (2010–2014, 2014–2018, and 2015–2019), and 2014–2018 and 2015–2019 overlap.
- All three years use 2010 tracts and the 2018 tract-to-county and 2010-place crosswalks.

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

### Methodology
- **Numerator**: deaths whose underlying cause is one of the ICD-10 codes County Health Rankings uses for injury deaths: \*U01–\*U03, V01–Y36, Y85–Y87, and Y89. These cover accidents, transport, self-harm, assault, undetermined intent, legal intervention and operations of war, terrorism, and their sequelae.
- **Rate**: CDC WONDER's crude rate per 100,000 people, using its population for the same county and years. Rates are crude, not age-adjusted, in every year, because CDC WONDER doesn't produce county age-adjusted rates from the Single-Race data.
- **Pooling**: each year pools deaths and population over the five years ending that year (`2014` is 2010–2014). 2021 pools four years (2018–2021) because the Single-Race data start in 2018.
- **Sources**: 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files.
- **Suppressed and unreliable rates**: rates CDC WONDER marks "Suppressed" (fewer than 10 deaths) or "Unreliable" are set to `NA`, along with their bounds. Single-Race rates based on 0 deaths are also `NA`. Through the 2023 data, CDC WONDER marks a rate unreliable when it's based on fewer than 20 deaths; starting with the 2024 data, it marks a rate unreliable when its 95 percent confidence interval is wider than 160 percent of the rate ([CDC WONDER help, Single-Race](https://wonder.cdc.gov/wonder/help/ucd-expanded.html)).
- **Subgroups**: the decedent's single race and Hispanic origin, for 2021–2024 only. Hispanic includes any race, and Other Races and Ethnicities combines non-Hispanic American Indian or Alaska Native, Asian, Native Hawaiian or Other Pacific Islander, and more than one race.
- **Confidence intervals**: the 95 percent confidence intervals for the crude rate as CDC WONDER reports them.
- **Geography**: CDC WONDER codes for Shannon County, SD and Wade Hampton, AK are recoded to Oglala Lakota (46102) and Kusilvak (02158) from 2015 on. CDC WONDER still reports Valdez-Cordova, AK (02261) after its 2019 split, so its rate and bounds for 2020–2024 are given to both Chugach (02063) and Copper River (02066). It still reports Connecticut's eight old counties for 2022–2024, so the nine planning regions are `NA` in those years.

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

### Comparability across years
- Each year pools five years of deaths, so consecutive years share four years of data. 2021 pools four years (2018–2021).
- 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files. Totals are comparable, but race-ethnicity subgroups exist only from 2021.
- Rates are crude, so they move with each county's age mix. The median county rate rose from 74.8 in 2014 to 101.2 in 2024; the .qmd notes some of this could be an older population.
- 2024 uses CDC WONDER's new unreliable-rate rule (see Methodology), so it has fewer missing counties and more quality `2` rows than earlier years.

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

### Methodology
- **Numerator**: votes cast for president, the "highest office" on the ballot. For counties, this is the sum of all candidates' votes in the MIT Election Data and Science Lab returns in 2016 and 2020, and MIT's county `totalvotes` in 2024, because some states' 2024 returns include a "total" vote-mode row that would double count if candidate votes were summed. For cities, it is the sum of all presidential candidates' votes in each VEST precinct (`G16PRE*` or `G20PRE*` fields).
- **Denominator**: the citizen voting-age population (CVAP), US citizens ages 18 and older, from the Census Bureau's CVAP special tabulation of the American Community Survey (ACS). Counties use the 5-year tabulation ending in the election year (2012–2016, 2016–2020, 2020–2024). Cities use the 2016–2020 tabulation for both 2016 and 2020.
- **Cap at 1**: county turnout above 1 (more votes than estimated CVAP) is set to 1. City values don't exceed 1, so no cap is applied.
- **Counties with nonstandard reporting**: MIT reports Alaska by election district, so Alaska returns are pooled to one statewide code and Alaska boroughs get no value. Kalawao County, HI is reported with Maui County. Votes reported under Shannon County, SD (46113) are assigned to Oglala Lakota County (46102).
- **Connecticut in 2024**: votes for the eight former counties are split across the nine planning regions in proportion to 2020 population, using the allocation factors in `connecticut_planning_regions_to_pre_2023_counties.csv`.
- **Cities**: precinct votes are apportioned to places by the share of each precinct's area inside the place (areal weighted interpolation), which assumes votes are spread evenly across a precinct. Precinct geometries that are invalid are repaired before the overlay.
- **Quality inputs**: the county flag reflects only the CVAP coefficient of variation (CV), computed from the published margin of error divided by 1.645. City flags also reflect how many precincts are split by the place boundary (`messiness`, the vote-weighted average distance of each precinct's area share from 0 or 1) and whether VEST allocated the state's results to precincts from larger reporting units.

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

### Comparability across years
- Each county year uses a different CVAP tabulation (2012–2016, 2016–2020, 2020–2024).
- County votes are summed candidate votes in 2016 and 2020 and MIT's `totalvotes` in 2024. The 2020 .Rmd notes the two match in 2020.
- Connecticut has 8 counties in 2016 and 2020 and 9 planning regions in 2024, so its values can't be compared county by county.
- The Kentucky and New Jersey allocation downgrade applies to 2020 cities only.

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

### Methodology
- **Measure**: each group's count divided by the total population of the county or city. Only these population shares are published. They are meant as the denominator of a representation ratio (a group's share of local elected officials divided by its share of residents), and no officials data are included.
- **Population**: all residents of every age, including people in group quarters, from American Community Survey (ACS) table `B01003` (total population).
- **Race and ethnicity groups**: Hispanic is anyone of Hispanic or Latino origin, of any race (`B03003`). The other three groups are non-Hispanic only (`B03002`): Black alone, white alone, and other. Other combines non-Hispanic Asian, American Indian and Alaska Native, Native Hawaiian and Other Pacific Islander, some other race, and two or more races. The four groups are mutually exclusive and sum to the total population, so the four shares sum to 1.
- **Estimates and years**: values are ACS 5-year estimates, and `year` is the last year of the period, so `2014` is 2010–2014. Only 2014, 2016, 2018, 2021, and 2023 are produced.
- **Margins of error**: ACS margins of error aren't carried into the shares, so the values are point estimates only.
- **Geography**: counties and places come directly from ACS county and place tables, matched to the target list of counties and cities on the five-digit county or seven-digit place code. No crosswalk or allocation is needed.

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

### Comparability across years
- The five years are overlapping 5-year periods (2010–2014, 2012–2016, 2014–2018, 2017–2021, 2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
- The other share grows faster after 2018: the median county share is 2.7 percent in 2014, 3.0 percent in 2018, 3.9 percent in 2021, and 4.8 percent in 2023, with the white non-Hispanic share falling by about the same amount.
- There are no values for 2015, 2017, 2019, 2020, 2022, or 2024.

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
Reported violent crimes and reported property crimes per 100,000 people, from the FBI's National Incident-Based Reporting System (NIBRS). Offenses reported by each police agency are assigned to counties (weighted by county population when an agency covers more than one county) or to places, then divided by the ACS 5-year population. "Violent" here means NIBRS crimes against persons and "property" means NIBRS crimes against property, so robbery counts as property crime (see Methodology). The quality flag measures the share of police agencies in the county or place that reported any offenses.

### Methodology
- **Numerator**: offenses reported by police agencies to the National Incident-Based Reporting System (NIBRS), from the Offense Segment. Each offense record counts once, so an incident with several offenses counts more than once.
- **Violent and property**: offenses are grouped with the "crimes against" categories in section 2.3 of the [2021.1 NIBRS User Manual](https://bjs.ojp.gov/sites/g/files/xyckuh236/files/sarble/data_common/nibrs-user-manual-2021-1041521.pdf). Violent is crimes against persons (for example, murder and manslaughter, aggravated and simple assault, intimidation, kidnapping, and sex offenses). Property is crimes against property, which in NIBRS includes robbery. Crimes against society (for example, drug and weapon law violations) aren't in either rate. These are not the FBI's traditional violent and property crime definitions.
- **Denominator**: total population from the American Community Survey (ACS) 5-year estimates ending in the data year (for example, 2017–2021 for 2021). The rate is offenses per 100,000 people. The full county or place population is used whether or not every agency there reported.
- **Agencies included**: every agency in the NIBRS Batch Header except state police. Agencies in Guam, Puerto Rico, and the Virgin Islands are dropped. An agency counts as reporting in a year if it has any offense record that year, regardless of how many months it reported.
- **Counties**: each agency is assigned to the counties listed in its Batch Header record, or, if none is listed, to the county in the 2012 Law Enforcement Agency Identifiers Crosswalk (LEAIC). An agency that covers more than one county has its offenses split across those counties in proportion to each county's total population.
- **Places**: each agency is assigned in full to one place, with no splitting. The place comes first from the LEAIC place code, then from the agency's city name matched to the place name, and finally, for remaining agencies whose first listed county contains only one of the 486 places, that place. Offenses of all agencies assigned to a place are summed.
- **Suppression**: rates are missing when no agency in the county or place reported, or the population is under 30. Loving County, TX is suppressed in every year and Kenedy County, TX in 2023 because their populations are under 100 and their rates are extreme.

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

### Comparability across years
- NIBRS coverage grows each year: 12,538 agencies have offenses in 2021 and 13,662 in 2024 (rendered .html), and missing counties fall from 287 to 213. Some large cities report only part of a year early on (New York city: 5 violent crimes per 100,000 in 2021, 92 in 2022, 2,571 in 2023; Los Angeles: missing in 2021, about 5 in 2022–2023, 1,002 in 2024), so changes across years mostly reflect reporting, not crime.
- All years are rerun with each new Kaplan release because agencies backfill earlier years, so values for the same year differ between metric updates.
- 2021 uses the eight old Connecticut counties and 2023–2024 use the nine planning regions.
- The LEAIC is from 2012, so agencies created since then can't be matched through it.
- Not comparable with the pre-2021 versions, which used UCR summary data with imputation and the FBI violent and property crime definitions.

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

### Methodology
- **Numerator**: arrests of people ages 10–17 reported to the National Incident-Based Reporting System (NIBRS), combining the Arrestee Segment (arrests for Group A offenses) and the Group B Arrest Report Segment (arrests for Group B offenses, such as bad checks and disorderly conduct). The two segments don't overlap ([Kaplan, Decoding FBI Crime Data](https://ucrbook.com/arrestee.html)). Each arrest, citation, or summons counts, so a juvenile arrested twice counts twice. Arrestees with unknown age aren't counted.
- **Denominator**: population ages 10–17 from the American Community Survey (ACS) 5-year estimates ending in the data year (for example, 2017–2021 for 2021), table `B01001` and its race and ethnicity versions. The rate is arrests per 100,000 juveniles, and is missing when that population is under 30.
- **Race and ethnicity subgroups**: arrestees are grouped by the race and ethnicity the agency records.
  - White and Black: `race_of_arrestee` of white or Black, including Hispanic arrestees; denominators are the race-alone populations (`B01001A`, `B01001B`), which also include Hispanic juveniles.
  - Hispanic: `ethnicity_of_arrestee` of Hispanic or Latino, of any race; denominator `B01001I`.
  - Other Races and Ethnicities: Asian, Native Hawaiian or Other Pacific Islander, and American Indian or Alaska Native arrestees; the denominator also includes some other race and two or more races, which NIBRS doesn't record.
  - Arrestees of unknown race count only toward All, the gender groups, and the age groups. Age groups are 10–14 and 15–17.
- **Agencies included**: every agency in the NIBRS Batch Header except state police. Agencies in Guam, Puerto Rico, and the Virgin Islands are dropped. An agency counts as reporting in a year if it has at least one arrest of any age that year, regardless of how many months it reported.
- **Counties**: each agency is assigned to the counties listed in its Batch Header record, or, if none is listed, to the county in the 2012 Law Enforcement Agency Identifiers Crosswalk (LEAIC). An agency that covers more than one county has its arrests split across those counties in proportion to each county's total population (all ages).
- **Places**: each agency is assigned in full to one place, with no splitting. The place comes first from the LEAIC place code, then from the agency's city name matched to the place name, and finally, for remaining agencies whose first listed county contains only one of the 486 places, that place. Arrests of all agencies assigned to a place are summed.
- **Subgroup quality**: each subgroup row takes the overall quality flag for its county or place, because reporting is measured by agency, not by subgroup.

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
- District of Columbia (11001): every year
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year
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

### Comparability across years
- NIBRS coverage grows every year, so changes mostly reflect more agencies reporting (section 7 of each .qmd says the same). The median county rate goes from 570 (2021) to 698 (2024), and the median place rate from 913 to 1,281. Los Angeles city goes from missing (2021) to 1.7 (2022) and 172 (2024).
- Every update reruns all years with Kaplan's latest release, since agencies backfill earlier years (section 0.1), so a year's values change between releases.
- The 2026 release labels the white subgroup "White". The 2025 release labeled the same calculation "White, Non-Hispanic" (98ec1b5c).
- Connecticut uses the eight old counties in 2021 and the nine planning regions from 2022 on.
- The denominators are overlapping ACS 5-year samples (2017–2021 to 2020–2024), which the Census Bureau advises against comparing ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
