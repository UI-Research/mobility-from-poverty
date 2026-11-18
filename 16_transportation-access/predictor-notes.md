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

## Methodology
- **Measures**: tract values from the Center for Neighborhood Technology (CNT) Housing and Transportation (H+T) Affordability Index for CNT's regional moderate-income household, which earns 80 percent of the regional area median income (AMI). `share_transit_commuter` is CNT's `pct_transit_commuters_80ami` (transit ridership as a share of workers) and `share_transportation_cost` is `t_80ami` (transportation costs as a share of income), both converted from percentages to proportions. These are CNT's modeled values for that household, not measured spending of the households living in the tract.
- **Years**: `year` is the CNT tract file year (2015, 2019, or 2022). The American Community Survey (ACS) 5-year data used for neighborhood types and quality flags end in the same year (2011–2015, 2015–2019, 2018–2022).
- **Aggregation**: county and city values are means of tract values, weighted by the number of households in each tract from the CNT file. Tracts with no households are dropped.
- **Cities**: tracts are assigned to places with GeoCorr tract-to-place allocation factors (`afact`, the share of the tract's population in the place), and each tract's weight is its households × `afact`. 2015 and 2019 use the 2010-tract-to-2014-place crosswalk and 2022 the 2020-tract crosswalk (`geocorr2022_tract_to_place.csv`). A tract partly in a city contributes its whole-tract value.
- **Neighborhood types**: each tract is classified by its ACS table B03002 race and ethnicity shares. White neighborhoods are at least 60 percent White, non-Hispanic; neighborhoods of color are at least 60 percent people of all other races and ethnicities, including Hispanic people of any race; mixed neighborhoods are everything else. The subgroup describes the tract, not the household, and a tract partly in a city keeps its whole-tract type. Tracts with no ACS population have no type.

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
- All seven Connecticut cities (Bridgeport, Danbury, Hartford, New Haven, Norwalk, Stamford, and Waterbury): 2022

City subgroups, cities missing per year: neighborhoods of color 82–96, White neighborhoods 57–82, mixed neighborhoods 66–73. The `All` rows add South Fulton in 2019 and the Connecticut cities in 2022.

## Comparability across years
- 2015 and 2019 use 2010 tracts and the 2010-tract-to-2014-place crosswalk; 2022 uses 2020 tracts and the 2020 crosswalk.
- Connecticut uses its eight old counties in 2015 and 2019 and its nine planning regions in 2022, and has no city values in 2022.
- CNT changes its model and inputs between releases ([H+T Index methods, November 2022](https://htaindex.cnt.org/about/method-2022.pdf), which describes changes made in earlier releases). The share of counties with no transit commuters jumps from 15 percent in 2015 to 61 percent in 2019 and 43 percent in 2022, so county transit changes across years mix real change with model changes.
- The ACS inputs used for quality and subgroups are 5-year samples, so 2015 (2011–2015) and 2019 (2015–2019) share 2015.
