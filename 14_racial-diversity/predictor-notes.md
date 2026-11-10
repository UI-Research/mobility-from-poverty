---
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
---

## Summary
For four race-ethnicity groups (Black, Non-Hispanic; Hispanic; Other Races and Ethnicities; and White, Non-Hispanic), the share of the average group member's census tract neighbors who belong to one of the other three groups. A value near 1 means the average group member lives in tracts made up almost entirely of other groups; a value of 0 means the group lives only in tracts made up entirely of its own group. Each group is its own column (wide format); there is no "All" value.

## Process
1. Make sure a Census API key is set as `CENSUS_KEY` (for example in `~/.Renviron`). The line that sources `R/census_api_key.R` is commented out in both .qmd files (county line 52, city line 57), so the key has to be set already. `R/census_api_key-template.R` shows how.
2. Set `years` in both .qmd files (now `c(2016, 2018, 2021, 2023)`, county line 172 and city line 175). Each year is the end year of an ACS 5-year sample. Add the year's DP05 variable codes to the `variable_mapping` tribble; the codes change across years.
3. Render `race-ethnicity-exposure-county.qmd` and `race-ethnicity-exposure-city.qmd`, in either order. Whichever runs first pulls tract data for every state and DC (not Puerto Rico) through `R/get_vars.R` and caches it in `data/tracts.csv` (about 30 minutes); the other reads the cache. `get_vars()` adds total population (B01003_001) from `acs/acs5` to the DP05 counts from `acs/acs5/profile`.
4. Tracts: set controlled margins of error (MOEs, coded `-555555555`) for Hispanic to 0. Build Other Races and Ethnicities as the sum of the non-Hispanic American Indian and Alaska Native, Asian, Native Hawaiian and Other Pacific Islander, some other race, and two or more races counts. Its MOE combines the group MOEs, keeping only the largest MOE among groups with a zero estimate. A check confirms the four groups add up to total population in every tract. The city .qmd also drops tracts with no people (line 207).
5. For each tract, compute the share of the county's (or place's) group members who live there, and the share of the tract that belongs to the other three groups.
6. Exposure = the weighted mean of the tract's other-groups share, weighted by the tract's share of the group (for example, `share_black_nh_exposure = weighted.mean(non_black_nh, w = share_of_black_nh)`).
   - County: tracts are grouped by their county code.
   - City: tracts are allocated to places with the GeoCorr tract-to-place allocation factor `afact`. 2016 and 2018 use the 2010-tract-to-2014-place crosswalk, 2021 the 2020 crosswalk, and 2023 the 2020 crosswalk with Connecticut tracts recoded to the planning regions. Only places in `place-populations.csv` are kept, then the result is `left_join()`ed onto that list so every place-year has a row.
7. Suppress (set to `NA`) a group's exposure when the group's estimated count in the county or place is 30 or less, then assign the quality flag.
8. The county .qmd checks that it has the same number of counties per year as `county-populations.csv`. The city .qmd compares interpolated place totals with the totals the API reports for places directly.
9. Write `final/race-ethnicity-exposure-county.csv` and `final/race-ethnicity-exposure-city.csv`. The Testing chunk at the end then runs `evaluate_final_data()` against `99a_final-evaluation/evaluation_form_share_race_exposure_overall_county.csv` and `evaluation_form_share_race_exposure_overall_place.csv`, but it reads the final file from the wrong path (see Known issues).

## Data quality flag
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

## Missing values
Both files have one row for every county and place in `county-populations.csv` and `place-populations.csv` for the four years: 3,142 counties in 2016 and 2018, 3,143 in 2021, and 3,144 in 2023 (nine Connecticut planning regions); 485 places in 2016 and 486 from 2018.

County file, counties missing per year:
- Black, Non-Hispanic: 441–474. Of these, 92–104 a year have no Black, Non-Hispanic residents (checked in `data/tracts.csv`); the rest have 30 or fewer. 281 counties are missing in all four years.
- Hispanic: 87–98 (30 counties in all four years)
- Other Races and Ethnicities: 111 (2016), 108 (2018), 65 (2021), 48 (2023)
- White, Non-Hispanic: Kalawao County, HI (15005) every year, and Kenedy County, TX (48261) in 2021 and 2023 (1 and 2 White, Non-Hispanic residents)

City file:
- South Fulton, GA (1372122): every group in 2018. It's in `place-populations.csv` from 2018 but not in the 2010-tract-to-2014-place crosswalk; the city .qmd says so.
- Pharr, TX (4857200): Black, Non-Hispanic in 2016 and 2018

## Known issues
- **The Testing chunks read the final files from a path that doesn't exist.** Both .qmd files read `here::here("14_racial-diversity", "final", "final", ...)` (county lines 887–888, city lines 1179–1180), so a full render stops before `evaluate_final_data()` runs. The predictor migration (cc436c22) introduced the doubled `final`; the earlier path was `06_neighborhoods/race-ethnicity-exposure/final/`.
- **The Census API key file can be committed by accident.** `.gitignore` only covers `R/census_api_key.R` at the repo root and `06_neighborhoods/R/census_api_key.R` (lines 257–258), not `14_racial-diversity/R/census_api_key.R` (`git check-ignore` returns nothing). No key has been committed.
- **The tract cache is committed and isn't refreshed when `years` changes.** `data/tracts.csv` (24 MB, 314,926 rows) is tracked in git, and both .qmd files only call the API `if(!file.exists(...))` (county line 174), so a new year is silently skipped unless the file is deleted first.
- The city quality flag uses CV only, although the city .qmd lists three dimensions (unweighted observations, CV, and tract-place overlap, line 976). `afact_sum_product` is computed (line 690) but never used, and suppression uses the weighted group estimate, not an unweighted count (`suppress_place(black_nh, ...)`, line 1010).
- Values near the extremes are common: 914 county-years have Black, Non-Hispanic exposure above 0.99, and 1,276 have White, Non-Hispanic exposure below 0.05. Five county-years have White, Non-Hispanic exposure of exactly 0 (Petroleum County, MT, 30069 in 2016; Blaine County, NE, 31009 in 2018, 2021, and 2023; Billings County, ND, 38007 in 2021), all quality `1`. Checked in the final file.
- The county final file isn't sorted by year, state, and county as the data standards require (it starts 01089, 01125, 01027 within 2016; checked). The city file is sorted.

## Comparability across years
- Every pair of consecutive years uses overlapping 5-year samples (2012–2016 and 2014–2018 share three years). The Census Bureau advises against [comparing overlapping 5-year estimates](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html).
- 2016 and 2018 use 2010 tract boundaries, and 2021 and 2023 use 2020 boundaries. Because exposure depends on how people are split across tracts, redrawn tracts alone can change values between 2018 and 2021. City values also switch from the 2010-tract-to-2014-place crosswalk to the 2020 crosswalk.
- Connecticut uses its eight old counties through 2021 and the nine planning regions (09110–09190) in 2023.
- Average White, Non-Hispanic exposure rises every year, from 0.204 (2016) to 0.229 (2023) across counties and from 0.429 to 0.473 across cities (checked in the final files).

## Open questions
- `race-ethnicity-exposure-county.csv` and `race-ethnicity-exposure-city.csv` at the folder root look like stale copies of the `final/` files. The county copy has the same values in a different row order; the city copy is older (1,931 rows, with a `state_place` column and only 479 places in 2023). The rendered `race-ethnicity-exposure-county.html` (4.2 MB) and `race-ethnicity-exposure-city.html` (3.9 MB) are also committed. Are they still needed?
- `final/evaluation_form_share_race_exposure_overall_county.csv` is an older copy of the form in `99a_final-evaluation/` (it lists 2014 and "2018:2021"). Can it be removed?
- The city .qmd describes the place allocation as areal interpolation by area overlap (line 472 and the paragraph after it), but the GeoCorr crosswalks are weighted by population. Which is right?
- Why does this metric start in 2016 when 13 (poverty exposure) starts in 2014?
- The city .qmd's tract CV table computes `asian_nh = mean(asian_nh >= 0.4)` on the count instead of the CV (line 246), and the note above it ("Not sure why or if this is a problem!", line 237) is unresolved. Both only affect the diagnostic table.
- The city .qmd says it pulls the counts "for 2021" (line 70), but it pulls all four years.
