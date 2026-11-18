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

## Methodology
- **Numerator**: deaths whose underlying cause is one of the ICD-10 codes County Health Rankings uses for injury deaths: \*U01–\*U03, V01–Y36, Y85–Y87, and Y89. These cover accidents, transport, self-harm, assault, undetermined intent, legal intervention and operations of war, terrorism, and their sequelae.
- **Rate**: CDC WONDER's crude rate per 100,000 people, using its population for the same county and years. Rates are crude, not age-adjusted, in every year, because CDC WONDER doesn't produce county age-adjusted rates from the Single-Race data.
- **Pooling**: each year pools deaths and population over the five years ending that year (`2014` is 2010–2014). 2021 pools four years (2018–2021) because the Single-Race data start in 2018.
- **Sources**: 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files.
- **Suppressed and unreliable rates**: rates CDC WONDER marks "Suppressed" (fewer than 10 deaths) or "Unreliable" are set to `NA`, along with their bounds. Single-Race rates based on 0 deaths are also `NA`. Through the 2023 data, CDC WONDER marks a rate unreliable when it's based on fewer than 20 deaths; starting with the 2024 data, it marks a rate unreliable when its 95 percent confidence interval is wider than 160 percent of the rate ([CDC WONDER help, Single-Race](https://wonder.cdc.gov/wonder/help/ucd-expanded.html)).
- **Subgroups**: the decedent's single race and Hispanic origin, for 2021–2024 only. Hispanic includes any race, and Other Races and Ethnicities combines non-Hispanic American Indian or Alaska Native, Asian, Native Hawaiian or Other Pacific Islander, and more than one race.
- **Confidence intervals**: the 95 percent confidence intervals for the crude rate as CDC WONDER reports them.
- **Geography**: CDC WONDER codes for Shannon County, SD and Wade Hampton, AK are recoded to Oglala Lakota (46102) and Kusilvak (02158) from 2015 on. CDC WONDER still reports Valdez-Cordova, AK (02261) after its 2019 split, so its rate and bounds for 2020–2024 are given to both Chugach (02063) and Copper River (02066). It still reports Connecticut's eight old counties for 2022–2024, so the nine planning regions are `NA` in those years.

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

## Comparability across years
- Each year pools five years of deaths, so consecutive years share four years of data. 2021 pools four years (2018–2021).
- 2014–2020 come from the Bridged-Race files and 2021–2024 from the Single-Race files. Totals are comparable, but race-ethnicity subgroups exist only from 2021.
- Rates are crude, so they move with each county's age mix. The median county rate rose from 74.8 in 2014 to 101.2 in 2024; the .qmd notes some of this could be an older population.
- 2024 uses CDC WONDER's new unreliable-rate rule (see Methodology), so it has fewer missing counties and more quality `2` rows than earlier years.
