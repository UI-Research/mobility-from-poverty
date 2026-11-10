---
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
---

## Summary
Share of births in the county with a low birthweight (under 2,500 grams), among births with a known birthweight, by the mother's county of residence. The subgroup file repeats the calculation by the mother's race and ethnicity (four groups) and the mother's education (four groups). Counties with fewer than 100,000 people get their state's pooled value for all such counties, because CDC WONDER doesn't report them separately.

## Process
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

## Data quality flag
Applied from lowest to highest quality (`assign-quality` chunk):
- `NA`: the rate is missing or `births_all` is under 30
- `3`: the county is unidentified (it has the state's pooled value), a count was suppressed, or `births_all` is 30–99
- `2`: `births_all` is 100–199, or the state has 1–4 unidentified counties, or the state has 15 or fewer counties and under half of them are unidentified
- `1`: everything else

All file: 23,081 rows are `3` (82 percent), 489 are `2`, 4,689 are `1`, and 27 are `NA`. The counts are the same every year: 521 counties are `1` and 2,564–2,565 are `3`, with 57 counties at `2` through 2021 and 49 from 2022 (Connecticut's eight counties drop out). Every `2` in 2024 is in one of seven states: Arizona, Delaware, DC, Hawaii, Massachusetts, New Jersey, and Rhode Island.

Subgroup file, `3` share of each subgroup's nonmissing rows: 82 percent for White, Non-Hispanic and for every education group except Less than High School (84 percent); 85 percent for Black, Non-Hispanic and for Hispanic; 88 percent for Other Races and Ethnicities.

## Missing values
All file:
- The nine Connecticut planning regions (09110–09190): 2022–2024. No other county is ever missing.

Subgroup file, counties missing per year (2016–2024 range):
- Black, Non-Hispanic: 381–540
- Other Races and Ethnicities: 182–233
- Hispanic: 124–178
- Less than High School: 61–91
- GED/High School Degree: 4–17; College Degree or Higher: 8–17; White, Non-Hispanic: 2–13; Some College: 0–14 (each includes the nine Connecticut regions from 2022)

When a state's pooled "Unidentified Counties" value is missing, all of that state's small counties are missing together. For example, in 2024 every county in Montana (56) and Wyoming (23) is missing for Black, Non-Hispanic, as are 42 of 58 California counties.

## Known issues
- Most counties don't have their own value. CDC WONDER only identifies counties that had 100,000 or more people in the 2010 Census, for all of 2014–2024 ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)). Every other county gets the pooled value of its state's unidentified counties (`assign-unidentified` chunk). In the all file, all 23,081 quality `3` rows share their value with other counties in the same state and year, in groups of up to 215 (Texas). Wyoming has no identified counties, so every Wyoming county has one value each year.
- Because the set of identified counties is fixed by the 2010 Census, counties that passed 100,000 people after 2010 are still pooled, and the quality flags don't change from year to year (data check: only Alaska and Connecticut, whose county codes change, have different flags in different years).
- Confidence intervals for pooled counties understate uncertainty. They use the pooled state births as the denominator (`construct-CIs` chunk), so they describe the pooled rate, not the county. The median interval width is 0.007 for quality `3` rows, compared with 0.021 for quality `1` rows (data check on the all file).
- The `2` flag mostly reflects the state, not the county. It applies to identified counties in states with few unidentified counties or few counties (`quality2` in the `quality-criteria` chunk), so counties with their own value in Delaware, DC, and (through 2021) Connecticut, where no county is pooled, are `2` instead of `1`.
- Suppression removes small nonzero counts but keeps zeros. Counts of 1–9 are suppressed by CDC WONDER ([CDC WONDER natality help](https://wonder.cdc.gov/wonder/help/natality.html)) and become `NA`, while zero low birthweight births are shown, so small subgroups are either 0 or have at least 10 low birthweight births. 45 subgroup rows are exactly 0 (17 Black, Non-Hispanic; 14 Hispanic; 11 Other Races and Ethnicities; 3 Less than High School), with confidence intervals of 0 to 0.
- Subgroup outliers come from small denominators: the highest values are Black, Non-Hispanic births in counties 29097 (0.35, 2018), 35013 (0.33, 2017), and 55117 (0.32, 2016), all quality `3`. The highest All value is 0.167 (county 28049, 2024, quality `1`).
- The variables are named `rate_` but are shares (low birthweight births divided by all births), not rates per population.

## Comparability across years
- The same counties are identified in every year (2010 Census populations): 578 through 2021 and 570 from 2022, when Connecticut's eight drop out. The pooling is consistent across 2016–2024, but a pooled county's value moves with its state's small-county births, not its own.
- Connecticut has values for the eight old counties through 2021 and none for 2022–2024.
- Alaska has Valdez-Cordova (02261) through 2019 and Chugach (02063) and Copper River (02066) from 2020, following `county-populations.csv`.
- The previous round's quality rule also gave a `2` to counties with 10–29 low birthweight births; that rule was dropped in this update (section 1.1 of the .qmd).

## Open questions
- Can Connecticut 2022–2024 get values? The CDC WONDER help says the 2022–2024 data have an "Unidentified Counties" category for the combined Connecticut planning regions, which may allow a statewide value for all nine regions.
- Should identified counties in states like Delaware and DC be `1`? The current `2` rule depends on the number of counties and unidentified counties in the state, not on the county's own data.
- The .qmd text says to expect 20,516 counties only in the population file (the `check-wont-match-counties` chunk). The arithmetic in the same chunk, with 2024 included, gives 23,081.
- Section 1.3 of the .qmd suggests allocating the pooled births by county population instead of giving every small county the pooled rate. Should this be done in the next update?
- The rendered `neonatal-health-all.html` (1.5 MB) is committed next to the .qmd. Is it still needed?
