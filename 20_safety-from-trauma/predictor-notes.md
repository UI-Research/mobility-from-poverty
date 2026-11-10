---
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
---

## Summary
Crude rate of deaths from injury per 100,000 people, from CDC WONDER's Underlying Cause of Death data. Each year pools deaths and population over the five years ending that year (four years for 2021). Injury deaths are the ICD-10 codes County Health Rankings uses for its injury deaths measure: accidents, transport, self-harm, assault, undetermined intent, legal intervention, terrorism, and their sequelae. The subgroup file adds four race-ethnicity groups for 2021–2024. Rates are crude, not age-adjusted, in every year.

## Process
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

## Data quality flag
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

## Missing values
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

## Known issues
- 2024 keeps rates based on 10–19 deaths, which every earlier year sets to `NA`. With the 2024 final deaths (February 2026), CDC WONDER changed its "Unreliable" flag from fewer than 20 deaths to a 95 percent confidence interval wider than 160 percent of the rate ([CDC WONDER help, Single-Race](https://wonder.cdc.gov/wonder/help/ucd-expanded.html)). The death counts implied by each row's confidence interval show 141 county rates from fewer than 20 deaths in the 2024 all file, and none in 2014–2023. The subgroup file has 190–312 such rates per group in 2024. This is why missing values drop from 258 to 111 and quality `2` rises from 66 to 222 between 2023 and 2024.
- The quality flag is a death-count cutoff. CDC WONDER's standard error for a crude rate is the rate × √(1/deaths) (same help page, "Standard Errors for Rates"), so CV = 1/√deaths. `1` means about 25 deaths or more, and `2` means 20–25 deaths (10–25 in 2024). A CV of 0.4 needs fewer than 7 deaths, which WONDER suppresses, so `3` is only assigned by the Chugach and Copper River override. The final files match this: every `2` row implies 20–25 deaths in 2014–2023.
- Chugach and Copper River, AK (02063, 02066) have identical values, copied from Valdez-Cordova for 2020–2024 (`assign-vc-death-rate` chunk). In the subgroup file, only White, Non-Hispanic (2021–2024) and Other Races and Ethnicities (2023–2024) are copied. Black, Non-Hispanic and Hispanic stay `NA`.
- The check that the only unmatched counties are Chugach, Copper River, and Connecticut can't fail. The `filter()` in `join-data` joins `GEOID %in% c("02063", "02066")` and the Connecticut condition with a comma (AND), so no row can match both, and `stopifnot(urban_antijoin |> nrow() == 0)` always passes.

## Comparability across years
- Each year pools five years of deaths, so consecutive years share four years of data. 2021 pools four years (2018–2021).
- 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files. Totals are comparable, but race-ethnicity subgroups exist only from 2021.
- Rates are crude, so they move with each county's age mix. The median county rate rose from 74.8 in 2014 to 101.2 in 2024; the .qmd notes some of this could be an older population.
- 2024 uses CDC WONDER's new unreliable-rate rule (see Known issues), so it has fewer missing counties and more quality `2` rows than earlier years.

## Open questions
- Should 2024 drop rates from fewer than 20 deaths to match earlier years, or should earlier years be redownloaded under the new rule?
- The .qmd says the Chugach and Copper River confidence intervals are not copied, but the code copies the bounds (only the standard error is not copied).
- The .qmd says 26,458 rows have a missing quality flag. The final files have 33,130 (1,885 in the all file for 2014–2020, plus 31,245 in the subgroup file).
- Section 2 says it reads 22 extracts; the code expects 27.
- Should the subgroup values for Chugach and Copper River be copied for all four groups, or for none?
- The rendered `safety-from-trauma.html` (6 MB) is committed. Is it still needed?
- Can CDC WONDER provide rates for the Connecticut planning regions?
