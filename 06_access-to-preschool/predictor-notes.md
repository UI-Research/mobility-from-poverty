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

## Methodology
- **Universe**: children ages 3 and 4 in ACS 5-year microdata, including those in households and in group quarters. The year is the last year of the 5-year sample (for example, `2014` is 2010–2014).
- **Numerator**: children whose grade attending (`GRADEATT`) is nursery school or preschool.
- **Denominator**: children in nursery school or preschool, in kindergarten, or not attending school. A `GRADEATT` of N/A is treated as not in school. Children ages 3 and 4 reported in first grade or higher are excluded.
- **Weights and confidence intervals**: estimates use the person weight (`perwt`). The 95 percent confidence intervals come from the 80 ACS person replicate weights (variance scaled by 4/80, as the Census Bureau specifies for ACS replicate weights) and are truncated to the 0–1 range.
- **Race and ethnicity**: the child's own race and Hispanic origin. Any Hispanic origin is Hispanic. Non-Hispanic children are White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities, which includes everyone else, including multiracial children.
- **Income**: the total income of the child's household (`HHINCOME`), split at $50,000 into Less than $50,000 and $50,000 or More. The same cutoff applies in every year. Children with no household income value, including those in group quarters, are left out of the income subgroups but kept in the overall share.
- **Geography**: ACS microdata identify public use microdata areas (PUMAs), not counties or places. Each child is spread across the counties or places their PUMA overlaps, with the person weight and every replicate weight multiplied by the crosswalk allocation factor (`afact`). 2014–2021 use 2012 PUMAs; 2023 uses 2020 PUMAs.
- **Small samples**: the effective sample is the sum of `afact` across children in the geography (or geography and subgroup). Estimates with an effective sample under 30 are suppressed and reported as `NA`.

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

## Comparability across years
- Each year is a 5-year ACS sample, so neighboring years overlap (for example, 2014 and 2016 share 2012–2014).
- The code joins 2014–2021 to the pre-2022 crosswalk period and 2023 to the 2022 period (2020 PUMAs), so the county and place allocation changes in 2023.
- Connecticut has its 8 old counties through 2021 and its 9 planning regions in 2023.
