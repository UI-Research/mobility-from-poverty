---
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
---

## Summary
For each racial or ethnic group, the group's share of a community's total home value divided by its share of the community's households. Home value counts homeowners only; the household share counts all households. A ratio of 1 means the group holds housing wealth in proportion to its share of households. Groups are Black non-Hispanic, Hispanic, other non-Hispanic, and white non-Hispanic. The subgroup files repeat the calculation by age (under 45, 45 and over).

## Process
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

## Data quality flag
- `1`: `population` > 30 and `sum_products` > 0.75 (more than 75 percent of the data comes from the geography itself)
- `2`: `population` > 30 and `sum_products` between 0.35 and 0.75
- `3`: `population` > 30 and `sum_products` 0.35 or less
- `NA`: `population` 30 or less, or no homeowners from the group in the sample. The ratio is set to `NA` wherever the flag is `NA`.
- County all file (white non-Hispanic columns): 5,669 rows are `1`, 4,524 are `2`, 21,226 are `3` (68 percent), and 8 are `NA`. Place all file: 1,000 are `1`, 2,563 are `2`, 1,230 are `3`, and 63 are `NA`.

## Missing values
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

## Known issues
- The ratio columns are text, not numbers: each value is the group's housing value share and household share joined by a colon (for example, `0.781:0.687`). Divide the first by the second to get the ratio. Evidence: `construct_ratio()` in `housing-value.qmd` and the final CSVs.
- The quality flag doesn't use the group's sample size. `construct_quality_flag(population, sum_products)` uses `population` from the crosswalk, which is the geography's population, while the .qmd text describes N as the number of households in each group. `home_owners = n()` is computed but not used. As a result, the flag is the same for every group in a geography: in the final files, no row has two groups with different nonmissing flags.
- Place flags don't change across years. `place_quality` keeps one row per place with `distinct(state, place, .keep_all = TRUE)`, ignoring year, so each place gets one `sum_products` for every year even though the crosswalk changes in 2022. In the place all file, 0 of 480 places have a flag that changes across years.
- Home value is `valueh` only. Mortgage debt isn't subtracted, so the metric reflects gross home value, not equity (`house_value_by_race()` in `housing-value.qmd`).

## Comparability across years
- There is no 2020: the .qmd drops the 2020 1-year ACS, which the Census Bureau [released as experimental](https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2020/1-year.html).
- The PUMA crosswalk changes in 2022, from 2012 PUMAs to 2020 PUMAs, and Connecticut switches from 8 counties to 9 planning regions.
- The place files have 485 places in 2014–2017 and 486 from 2018 on, matching `place-populations.csv` (South Fulton, GA, is added in 2018).

## Open questions
- Since #606, the PUMA crosswalks use `crosswalk_period` values `"2012"`, `"2k"`, and `"2022"`, but `housing-value.qmd` still tags pre-2022 years as `"pre-2022"`. Re-rendering would drop every year before 2022. The final files were last committed 2026-05-12, before #606 merged.
- Should the quality flag use the group's sample size (`home_owners`), as the .qmd text describes?
- The place subgroup check calls `evaluate_final_data()` with `evaluation_form_house_value_age_county.csv`, but `evaluation_form_house_value_age_place.csv` exists.
- In the subgroup files, the `All` rows have `subgroup_type` = `"age"`, while other metrics use `"all"`.
- `R/finalize_metric.R` renames income percentile columns (`pctl_income_*`) and isn't sourced here; `06_access-to-preschool` has its own copy that it does source. `R/geocorr2018_2503500948.csv` isn't read by any code. Are both still needed?
