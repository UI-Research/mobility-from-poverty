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

## Process
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

## Known issues
- **A value of 0 means no physicians, not the best access.** The ratio is population per PCP, so lower is better, but counties with 2,000 or fewer people and no PCPs are set to 0 (`create-ratio` chunk). 67–76 counties a year are 0, all quality `3` (data check), for example Alpine County, CA and Denali Borough, AK. Anyone ranking or averaging the values needs to treat them separately.
- **Connecticut planning regions are dropped even though AHRF has them for 2022.** The .qmd notes that the 2023–2024 release has the nine planning regions, but `fix-missing-urban` drops every Connecticut row for 2021 and 2022, so the 2022 planning regions are `NA` (data check).
- **Rerunning fails the year check.** `county-populations.csv` now has 2014–2025 (2024 and 2025 were added in October and November 2025), and the code only drops 2023, so the `testthat` check that the county file and AHRF have the same years fails.
- **The flag is a physician count.** It doesn't account for population: a county of 45,996 with 1 PCP and a county of 900 with 1 PCP both get `3`, and a county with 5 PCPs gets `1` at any population (formula above, `assign-data-quality` chunk).
- **Large outliers.** Logan County, OK (40083) is 45,996–46,784 in 2015–2017 (1 PCP) and about 23,000–25,000 in the other years. Ripley County, IN (18137) jumps from 14,350 in 2015 to 28,846 in 2016, and Lincoln County, MO (29113) from 20,529 in 2021 to 31,578 in 2022. 55–67 county-years a year are 10,000 or more (data check).
- The AHRF counts nonfederal PCPs and excludes residents (variable names `phys_nf_prim_care_pc_exc_rsdt_*`; [AHRF](https://data.hrsa.gov/topics/health-workforce/ahrf)). Physicians are counted where they're recorded in the AMA Physician Masterfile, which can differ from where patients go for care.

## Comparability across years
- Each year comes from one AHRF release: 2014–2020 from the 2021–2022 release, 2021 from the 2022–2023 release, and 2022 from the 2023–2024 release. Starting with the 2022–2023 release, AHRF only includes the two most recent years of each variable (.qmd section 2), so later releases can't be used to rebuild earlier years.
- Missing values rise from 134 in 2014 to 179 in 2022, mostly from more false zeros, so the set of counties with a value changes across years.
- Alaska: Valdez-Cordova (02261) through 2019, Chugach and Copper River (02063, 02066) from 2020. Connecticut has no values after 2020.

## Open questions
- Should the 2022 Connecticut planning regions be kept, since AHRF has them?
- The .qmd text says "To get all years 2014-2021, we need to download two versions of the AHRF data", but the code downloads three releases and covers 2014–2022. Section 4.2 says the only unmatched counties are Connecticut in 2021.
- The .qmd says a ratio change of 40–59 percent is quality `3`, but there's no rule for 60 percent or more; in practice the change never exceeds about 50 percent, so every nonmissing ratio gets a flag. Should the flag account for population?
- The check after the quality flag, `stopifnot(!all(is.na(ratio) & is.na(quality)))`, only fails if every row is missing both. It doesn't check what its comment says ("If the `ratio` value is `NA`, the `quality` value is also `NA`").
- Are the Logan County, OK (2015–2017), Ripley County, IN (2016 on), and Lincoln County, MO (2022) jumps real, or AHRF reporting changes?
- The rendered `access-health-services-all.html` (1.2 MB) is committed next to the .qmd. Is it still needed?
