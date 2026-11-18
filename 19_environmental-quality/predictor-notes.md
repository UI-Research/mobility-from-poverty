---
metric: Air quality
predictor: 19_environmental-quality
pillar: Healthy Environment and Access to Good Health Care
metric_lead: [JP Walsh]
variables: [index_air_hazard, index_air_hazard_quality]
geographies:
  county: 2014, 2018, 2019
  place: 2014, 2018, 2019
subgroups: [poverty, race-ethnicity]
confidence_intervals: false
code:
  - air_toxicity_metric.qmd
final_files:
  - data/final/environment_county_longitudinal.csv
  - data/final/environment_county_poverty_longitudinal.csv
  - data/final/environment_county_race-ethnicity_longitudinal.csv
  - data/final/environment_place_longitudinal.csv
  - data/final/environment_place_poverty_longitudinal.csv
  - data/final/environment_place_race-ethnicity_longitudinal.csv
sources:
  - name: AirToxScreen (2018, 2019) and National Air Toxics Assessment (NATA, 2014), national results by tract and source group
    provider: US Environmental Protection Agency (EPA)
    vintage: 2014 NATA, 2018 and 2019 AirToxScreen
    access: manual download, committed in data/raw/ (also on Box)
    url: https://www.epa.gov/AirToxScreen/2019-airtoxscreen-assessment-results
  - name: American Community Survey (ACS) 5-year, tract tables B01003, B03002, and B17001
    provider: US Census Bureau
    vintage: 2010-2014, 2014-2018, and 2015-2019
    access: API (tidycensus::get_acs(), Census API key)
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/tract-county-crosswalk_2018.csv
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/geocorr2018_tract_to_place.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
---

## Summary
A 0–100 index of exposure to air toxics, from the Environmental Protection Agency's (EPA) modeled cancer risk and respiratory and neurological hazard for each census tract. Each tract gets its national percentile rank on the combined hazard, flipped so that higher values mean less hazard, and county and city values are the population-weighted averages of their tracts. The subgroup files repeat the average for tracts grouped by poverty rate and by racial and ethnic makeup.

## Methodology
- **Hazard measures**: three Environmental Protection Agency (EPA) modeled estimates for each census tract: `total_cancer_risk_per_million`, `total_respiratory_hazard_quotient`, and `total_neurological_hazard_quotient`. 2014 comes from the National Air Toxics Assessment (NATA) and 2018 and 2019 from AirToxScreen.
- **Tract index**: within each year, each measure is converted to a z-score across tracts, the three are summed, and the sum is multiplied by −1. Tracts are then given their national percentile rank (0–100, unweighted by population), so higher values mean less hazard compared with other tracts in the same year.
- **Tracts**: all three years use 2010 tracts. Only tracts in the 2015–2019 American Community Survey (ACS) tract list are kept, which drops the EPA's nontract rows, after 25 tract codes that changed after 2010 are recoded. Puerto Rico and the US Virgin Islands are excluded.
- **County and city values**: the mean of the tract index, weighted by tract population from the ACS 5-year table B01003 (2010–2014 for 2014, 2014–2018 for 2018, and 2015–2019 for 2019). Tracts with no index are left out of the mean and counted toward the quality flag.
  - Counties: each tract is assigned in full to its county with `tract-county-crosswalk_2018.csv`.
  - Cities: tracts are assigned with `geocorr2018_tract_to_place.csv`, and each tract's weight is its population × `afact`, the share of the tract's population in the place.
- **Race-ethnicity subgroups**: tracts, not people, are classified by the share of residents who are people of color (total population minus White, Non-Hispanic, from ACS table B03002): Majority Non-White is 60 percent or more, No Majority Race/Ethnicity is more than 40 and less than 60 percent, and Majority White, Non-Hispanic is 40 percent or less. A subgroup value is the population-weighted mean index of the county's or city's tracts in that class, so it describes neighborhoods, not residents of a given race or ethnicity.
- **Poverty subgroups**: High-Poverty tracts have a poverty rate of 40 percent or more among people for whom poverty status is determined (ACS table B17001); all others are Not High-Poverty. Tracts are weighted by total population, not by the number of people in or out of poverty.

## Data quality flag
- `1`: tracts with no index value (or, for subgroups, no subgroup class) hold less than 5 percent of the geography's population
- `2`: 5 percent or more (lines 696 and 950)
- `3` is never assigned, and the flag doesn't reflect how many tracts a value comes from or the uncertainty in the EPA models.
- County all file: every nonmissing row is `1`. County subgroup files: 4 rows are `2` in the poverty file and 7 in the race-ethnicity file; 3 High-Poverty rows (Michigan 2018 and 2019, Washington 2019) are `2` with a missing value. Place files: every nonmissing row is `1`.

## Missing values
County all file (3,141 rows a year, against 3,142 in `county-populations.csv`):
- Valdez-Cordova, AK (02261), and its 2019 replacements Chugach and Copper River (02063, 02066) have no row in any year, so that area has no value.
- 2014: Kusilvak, AK (02158) and Oglala Lakota, SD (46102) are in the file with missing values; their earlier codes (02270, 46113), which `county-populations.csv` uses for 2014, aren't in the file.

County subgroup files, missing per year (most because the county has no tract in that class):
- High-Poverty: 2,401–2,539
- Not High-Poverty: 6–11
- Majority Non-White: 2,209–2,242
- No Majority Race/Ethnicity: 1,901–1,945
- Majority White, Non-Hispanic: 165–182
- Chugach and Copper River have subgroup rows (all missing) but no `All` row.

City all file (483 rows a year, against 485–486):
- Jurupa Valley, CA (0637692) and Macon-Bibb County, GA (1349008): every year
- South Fulton, GA (1372122): 2018 and 2019
- These three places aren't in `geocorr2018_tract_to_place.csv` (checked; place code 37692 in that file is Jamestown, IN). They have rows in the subgroup files with every value missing, including South Fulton in 2014, before it was a city.

City subgroup files, missing per year: High-Poverty 201–260, Not High-Poverty 3, Majority Non-White 88–105, No Majority Race/Ethnicity 65–75, Majority White, Non-Hispanic 57–70.

## Comparability across years
- The EPA says it "can be misleading to compare this version of AirToxScreen with previous assessments", because the emissions inventory, models, background concentrations, health benchmarks, and weather year change between assessments ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions)). 2014 comes from NATA, the predecessor to AirToxScreen.
- Because the index is a within-year rank, changes over time show movement relative to other tracts, not changes in exposure.
- The tract classes use different ACS samples each year (2010–2014, 2014–2018, and 2015–2019), and 2014–2018 and 2015–2019 overlap.
- All three years use 2010 tracts and the 2018 tract-to-county and 2010-place crosswalks.
