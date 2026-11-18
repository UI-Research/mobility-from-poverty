---
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
---

## Summary
Number of people in the county per primary care physician (PCP), from the Area Health Resources File (AHRF) count of nonfederal primary care physicians excluding residents, divided into the county population from `county-populations.csv`. Higher values mean fewer physicians per person. Counties with 2,000 or fewer people and no PCPs get a value of 0.

## Methodology
- **Numerator**: total county population from `county-populations.csv`. In every county-year that matches the Area Health Resources File (AHRF), it equals the population AHRF reports.
- **Denominator**: AHRF's count of nonfederal primary care physicians (PCPs), excluding residents (`phys_nf_prim_care_pc_exc_rsdt_*` and the matching 2021–2022 release variables), which comes from the American Medical Association (AMA) Physician Masterfile. PCPs are MDs and DOs under age 75 in general practice, family medicine, internal medicine, and pediatrics. Nurse practitioners, physician assistants, and hospital residents aren't counted.
- **Ratio**: population divided by PCPs, rounded to a whole number. It's people per physician, so higher values mean fewer physicians per person.
- **Zero physicians**: follows the County Health Rankings suppression rule. A county with 0 PCPs gets a ratio of 0 if it has 2,000 or fewer people and `NA` if it has more, treating a reported 0 in a larger county as a likely false zero.
- **Vintages**: each year comes from one AHRF release (see Comparability across years). 2020 is in both the 2021–2022 and 2022–2023 releases with the same values; the 2021–2022 release is used.
- **Geography**: county only, since AHRF has no city data. AHRF counties are matched to `county-populations.csv` by FIPS code. For 2014, AHRF's codes for Oglala Lakota, SD and Kusilvak, AK are recoded to the codes the county file uses for that year (46113 and 02270). Counties that no longer exist are dropped, as are all Connecticut rows for 2021 and 2022, so Connecticut has no values after 2020. Valdez-Cordova, AK (02261) is used through 2019 and Chugach and Copper River (02063, 02066) from 2020.

## Data quality flag
Sensitivity = the percent change in the ratio when 1 is added to the county's PCP count (`calculate-sensitivity` chunk):
- `1`: change under 20 percent
- `2`: 20 percent to under 40 percent
- `3`: 40 percent to under 60 percent
- `NA`: the ratio is `NA`

Since the ratio is population / PCPs, the change is about 1 / (PCPs + 1), so the flag works out to a PCP count: `1` for about 5 or more PCPs, `2` for 2–4, and `3` for 1. The largest possible change is about 50 percent (1 PCP), so no nonmissing row is ever above 60 percent. Counties with a ratio of 0 have an infinite change, which the code replaces with the largest finite one, so all of them are `3`.

Tallies: 20,599 rows are `1`, 3,857 are `2`, 2,482 are `3` (9 percent of nonmissing), and 1,344 are `NA`. The split is about the same every year (2,262–2,310 counties are `1`).

## Missing values
134–179 counties a year (1,344 of 28,282 rows), rising over time: 134 (2014), 134, 135, 147, 150, 153, 147, 165, and 179 (2022).
- Connecticut: all 8 counties in 2021 and all 9 planning regions in 2022, so there are no Connecticut values after 2020
- Chugach and Copper River, AK (02063, 02066): 2020; Copper River also 2022
- Everything else (134–169 a year) is a false zero: a county with more than 2,000 people and 0 PCPs. The largest is Crawford County, MO (29055), with 24,302 people in 2016. These are concentrated in Texas (182 county-years), North Dakota (120), Georgia (119), South Dakota (96), Kansas (70), and Nebraska (67).
- 260 counties are missing in at least one year and 74 in every year.

## Comparability across years
- Each year comes from one AHRF release: 2014–2020 from the 2021–2022 release, 2021 from the 2022–2023 release, and 2022 from the 2023–2024 release. Starting with the 2022–2023 release, AHRF only includes the two most recent years of each variable (.qmd section 2), so later releases can't be used to rebuild earlier years.
- Missing values rise from 134 in 2014 to 179 in 2022, mostly from more false zeros, so the set of counties with a value changes across years.
- Alaska: Valdez-Cordova (02261) through 2019, Chugach and Copper River (02063, 02066) from 2020. Connecticut has no values after 2020.
