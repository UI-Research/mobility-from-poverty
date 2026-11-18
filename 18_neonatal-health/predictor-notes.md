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

## Methodology
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

## Comparability across years
- The same counties are identified in every year (2010 Census populations): 578 through 2021 and 570 from 2022, when Connecticut's eight drop out. The pooling is consistent across 2016–2024, but a pooled county's value moves with its state's small-county births, not its own.
- Connecticut has values for the eight old counties through 2021 and none for 2022–2024.
- Alaska has Valdez-Cordova (02261) through 2019 and Chugach (02063) and Copper River (02066) from 2020, following `county-populations.csv`.
- The previous round's quality rule also gave a `2` to counties with 10–29 low birthweight births; that rule was dropped in this update (section 1.1 of the .qmd).
