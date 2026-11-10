---
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
---

## Summary
Two measures from the Center for Neighborhood Technology (CNT) Housing and Transportation (H+T) Affordability Index for a household earning 80 percent of the regional area median income (AMI): the share of workers who commute by transit (`share_transit_commuter`) and transportation costs as a share of income (`share_transportation_cost`). CNT models both at the census tract level; the code averages tracts to counties and cities, weighted by households. The subgroup files repeat the calculation by neighborhood type (White neighborhoods, neighborhoods of color, and mixed neighborhoods), not by the race or ethnicity of the household.

## Process
1. Download the CNT tract files for 2015, 2019, and 2022 from the [Box folder](https://urbanorg.app.box.com/folder/250262697073) into `data/2015_tract/`, `data/2019_tract/`, and `data/2022_tract/` (unzipped). The originals come from the CNT download page, which requires a free account. `data/` is gitignored.
2. Render the three .qmd files, in any order. They don't depend on each other. Each one pulls its own ACS data with `tidycensus::get_acs()`.
   - `transportation_county_combined.qmd` writes both county files.
   - `transportation_city.qmd` writes `transportation_all_city.csv`.
   - `transportation_city_subgroup.qmd` writes `transportation_subgroup_city.csv`.
3. CNT tracts: build the tract GEOID from CNT's `tract` field (characters 2–12), keep `pct_transit_commuters_80ami` as `share_transit_commuter` and `t_80ami` as `share_transportation_cost`, drop tracts with no households, and divide both by 100.
4. ACS tracts: pull B25001_001 (housing units, used as the household estimate and its margin of error) and B03002 (race and ethnicity) for 2015, 2019, and 2022. Convert margins of error to standard errors by dividing by `qnorm(0.95)`.
5. Neighborhood type (subgroup .qmd files only), from the tract's B03002 shares:
   - White neighborhoods: White, non-Hispanic share of 0.6 or more
   - Neighborhoods of color: share of everyone else of 0.6 or more
   - Mixed neighborhoods: everything else with population
   - Tracts with no ACS population are dropped.
6. County: household-weighted mean of the tract values (`weighted.mean(..., w = households)`), by county and by county and neighborhood type. The household estimate is summed and its standard error is the root sum of squares. `full_join()` onto `county-populations.csv` expanded to the four subgroups.
7. City: join tracts to places with the GeoCorr tract-to-place crosswalks (`geocorr2018_2010tract_to_2014place.csv` for 2015 and 2019, `geocorr2022_tract_to_place.csv` for 2022), drop tracts outside the target places, and take the mean weighted by `households * afact`. Join onto `place-populations.csv`.
8. Quality flags (see Data quality flag), then `evaluate_final_data()` against the four `evaluation_form_transportation_*` forms in `99a_final-evaluation/`, then write to `final/`.

## Data quality flag
Both variables always get the same flag. The flag is the worst of these tests:
- **Household estimate**: coefficient of variation (CV) of the summed ACS household estimate. `1` below 0.08, `2` below 0.15, otherwise `3`. The .qmd files use tighter cutoffs than the usual 0.2 and 0.4 because the CNT values are modeled.
- **Median household income**: CV of the county's or place's ACS median household income (B19013). `1` below 0.1, `2` below 0.3, otherwise `3`. A missing CV is set to 0.5, which gives `3`. Subgroup rows use the CV for the whole county or place.
- **Crosswalk match (cities only)**: `1` when at least half of the place's tracts have `afact` above 0.5, otherwise `2`.

Tallies:
- County all file: 8,885 rows are `1`, 529 are `2`, 13 are `3`, and 1 is missing. Rows rated `2` rise from 111 in 2015 to 159 in 2019 and 259 in 2022.
- County subgroups (`1`/`2`/`3`): White neighborhoods 8,458/419/12, mixed neighborhoods 3,450/256/35, neighborhoods of color 2,513/257/41.
- City all file: 1,447 rows are `1`, 2 are `2` (Conroe, TX, in 2015 and 2019), and 8 are missing.
- City subgroups (`1`/`2`/`3`): White neighborhoods 1,144/70/37, mixed neighborhoods 1,174/54/21, neighborhoods of color 1,138/35/20.

## Missing values
County all file (3,142 rows in 2015 and 2019 and 3,144 in 2022, matching `county-populations.csv`):
- Loving County, TX (48301): 2015

County subgroups, counties missing per year (because the county has no tract of that type):
- Neighborhoods of color: 2,145–2,252
- Mixed neighborhoods: 1,824–1,945
- White neighborhoods: 174–184

City all file (485 rows in 2015 and 486 in 2019 and 2022, matching `place-populations.csv`):
- South Fulton, GA (1372122): 2019. It isn't in the 2014-place crosswalk.
- All seven Connecticut cities (Bridgeport, Danbury, Hartford, New Haven, Norwalk, Stamford, and Waterbury): 2022 (see Known issues)

City subgroups, cities missing per year: neighborhoods of color 82–96, White neighborhoods 57–82, mixed neighborhoods 66–73. The `All` rows add South Fulton in 2019 and the Connecticut cities in 2022.

## Known issues
- **All Connecticut cities are missing in 2022.** In the 2022 CNT data, Connecticut tracts carry the planning region codes (the county file has 09110–09190 for 2022), but `geocorr2022_tract_to_place.csv` only has the old county codes (09001–09015, checked), so no Connecticut tract joins to a place. The city .qmd notes that "Most of the missing tracts are Connecticut Planning Regions."
- **The city match quality test isn't weighted.** `weighted.mean(afact > 0.5, weight = households, na.rm = TRUE)` passes `weight`, which `weighted.mean()` doesn't recognize (its argument is `w`), so it's ignored and every tract counts equally (checked: `weighted.mean(c(1, 0), weight = c(100, 1))` returns 0.5). Both city .qmd files.
- **The city household CV mixes allocated and unallocated tracts.** The household estimate is `sum(households_est * afact)`, but its standard error is `sqrt(sum(households_se ^ 2))` without `afact`, so places with many partly included tracts get a larger CV than their allocated estimate supports (both city .qmd files).
- **Subgroup rows use the whole geography's income CV.** The median household income test joins on year and geography only (`med_hh_income_cv` in all three .qmd files), so a neighborhood type with few households can still be `1` when its household CV is low.
- **The two city files disagree slightly on All.** `transportation_all_city.csv` comes from `transportation_city.qmd`, which keeps tracts with no ACS population; the `All` rows in `transportation_subgroup_city.csv` come from `transportation_city_subgroup.qmd`, which drops them (`filter(subgroup != "No population")`). Values differ by up to 0.0005 (data check). The county files don't have this problem: both come from one .qmd and match exactly.
- **Many counties have no transit commuters.** `share_transit_commuter` is exactly 0 for 480 counties in 2015, 1,924 in 2019, and 1,360 in 2022 (data check). In cities, only 8 values (all 2015) are 0.
- **Outliers**:
  - Transit: the highest county values are New York County, NY (0.69 in 2015), and the highest place is New York City (0.57 in 2015).
  - Cost: 23 county rows are above 0.6. The highest are Issaquena County, MS (0.83), and Jackson County, SD (0.79), both in 2022. The lowest is New York County (0.05 in 2015). All place values are between 0.10 and 0.42.

## Comparability across years
- 2015 and 2019 use 2010 tracts and the 2010-tract-to-2014-place crosswalk; 2022 uses 2020 tracts and the 2020 crosswalk.
- Connecticut uses its eight old counties in 2015 and 2019 and its nine planning regions in 2022, and has no city values in 2022.
- CNT changes its model and inputs between releases ([H+T Index methods, November 2022](https://htaindex.cnt.org/about/method-2022.pdf), which describes changes made in earlier releases). The share of counties with no transit commuters jumps from 15 percent in 2015 to 61 percent in 2019 and 43 percent in 2022, so county transit changes across years mix real change with model changes.
- The ACS inputs used for quality and subgroups are 5-year samples, so 2015 (2011–2015) and 2019 (2015–2019) share 2015.

## Open questions
- The .qmd text describes `t_80ami` as "Transportation Costs % Income for the Regional Typical Household". In the CNT methods, the typical household earns the regional median income, while the `80ami` variables are for a household at 80 percent of it; the old `documentation/overview.md` called it the "regional moderate household". Which one is it?
- The county .qmd histograms are labeled "Annual Transit Trips", but since March 2025 (e7ae2a88) the variable is the share of workers commuting by transit.
- In both city .qmd files, the step that blanks the cost flag when the cost is missing checks `is.na(share_transportation_cost_quality)` instead of `is.na(share_transportation_cost)`. It has no effect now, since cost and transit are missing together.
- The .qmd text calls B25001_001 "the number of households in the tract", but B25001 is total housing units, vacant ones included ([ACS 5-year variables](https://api.census.gov/data/2022/acs/acs5/variables.html)). Should the household CV use B11001_001 (households)?
- The year-over-year change checks in `transportation_city.qmd` group by `year, state, place` before `lag()`, so every change is `NA`.
- Which CNT release does each `data/{year}_tract/` folder hold? The raw files are only on Box, so the year-to-release mapping couldn't be checked.
- Should the Connecticut tracts be mapped to places for 2022 (for example, with a tract-to-place crosswalk that uses planning region codes)?
- The rendered `transportation_city.html`, `transportation_city_subgroup.html`, and `transportation_county_combined.html` (about 2 MB each) are committed at the folder root. Are they still needed?
