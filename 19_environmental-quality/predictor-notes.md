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

## Process
1. The EPA files are already in `data/raw/2014/`, `data/raw/2018/`, and `data/raw/2019/`: three national by-tract files per year (cancer risk, neurological hazard index, and respiratory hazard index), downloaded by hand from the EPA assessment pages. The .qmd also points to a Box copy.
2. Set a Census API key for `tidycensus` (the `census_api_key()` line is commented out, line 41), then render `air_toxicity_metric.qmd`. One render writes all six files; there are no parameters.
3. Tracts: for each year, bind the three EPA files, keep `total_cancer_risk_per_million`, `total_neurological_hazard_quotient`, and `total_respiratory_hazard_quotient`, and drop Puerto Rico and the US Virgin Islands. 25 tract codes that changed after 2010 are recoded by hand (for example, Wade Hampton, AK, 02270 to Kusilvak, 02158, and Shannon, SD, 46113 to Oglala Lakota, 46102). Only tracts in the 2015–2019 ACS tract list are kept (line 314), which drops the EPA's nontract rows.
4. Tract index: within each year, convert each of the three measures to a z-score across tracts, add them, multiply by −1, and take `percent_rank() × 100`, rounded (lines 346–379).
5. ACS: pull tract population (B01003_001), race and ethnicity (B03002_001 and B03002_003), and poverty (B17001_001 and B17001_002) from the 2014, 2018, and 2019 5-year files. Classify each tract:
   - Race and ethnicity: Majority Non-White (60 percent or more people of color), No Majority Race/Ethnicity (more than 40 and less than 60 percent), and Majority White, Non-Hispanic (the rest)
   - Poverty: High-Poverty (40 percent or more in poverty) and Not High-Poverty
6. County: assign tracts to counties with `tract-county-crosswalk_2018.csv` (the same tracts in every year) and take the mean of the tract index weighted by tract population, for all tracts and for each tract class. The county list is every distinct county in `crosswalk_puma_to_county.csv`, across all crosswalk periods (line 509).
7. City: assign tracts to places with `geocorr2018_tract_to_place.csv`, weighting each tract by population × `afact` (the share of the tract's population in the place), and keep places in `place-populations.csv`.
8. Set the quality flag, round the index to a whole number, and write the files. The subgroup files include the `All` rows (`subgroup_type = "all"`). The .qmd doesn't call `evaluate_final_data()`.

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

## Known issues
- The index is relative. Tracts are ranked against all other tracts in the same year (`percent_rank()`, line 379), unweighted, so a county's value says where its residents' tracts fall in that year's national distribution, not how much air toxics they're exposed to.
- Higher values mean less hazard, although the variable is named `index_air_hazard`: the summed z-scores are multiplied by −1 before ranking (line 371). Cities average 39–42 and counties 63–70 (data check).
- The rows in the files don't match the code's own row checks. The .qmd stops unless the county files have 3,143 counties a year and the city files 486 (`stopifnot()` at lines 567 and 830), but the committed county all file has 3,141 and the city all file 483 (data check). For cities, the final files are built from `all_enviro_place` (line 946), not from `haz_index_place_all`, the table joined onto the full place list that the check tests, so places with no tracts drop out of the `All` rows.
- A rerun would fail the county row check. Since #606, `crosswalk_puma_to_county.csv` has 3,152 distinct counties across its periods, including the nine Connecticut planning regions, and the county list takes all of them (line 509; data check). That would also add planning-region rows to 2014–2019.
- Values of 0 and 100 are common at the county level: 68 counties are 100 in 2014, 39 in 2018, and 38 in 2019 (data check). Between 2018 and 2019, 96 counties move more than 20 points; the largest is Mariposa County, CA, from 8 to 83.
- The EPA says its assessments shouldn't be used "to characterize or compare risks or exposures at local levels (such as between neighborhoods)" ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions), A4). The subgroup values compare groups of tracts within a county or city.

## Comparability across years
- The EPA says it "can be misleading to compare this version of AirToxScreen with previous assessments", because the emissions inventory, models, background concentrations, health benchmarks, and weather year change between assessments ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions)). 2014 comes from NATA, the predecessor to AirToxScreen.
- Because the index is a within-year rank, changes over time show movement relative to other tracts, not changes in exposure.
- The tract classes use different ACS samples each year (2010–2014, 2014–2018, and 2015–2019), and 2014–2018 and 2015–2019 overlap.
- All three years use 2010 tracts and the 2018 tract-to-county and 2010-place crosswalks.

## Open questions
- Should the metric move to newer years? The EPA has published the 2020 AirToxScreen, at the census block level instead of the tract level ([AirToxScreen frequent questions](https://www.epa.gov/AirToxScreen/airtoxscreen-frequent-questions), A5), so the tract steps would need to change.
- Which run produced the committed files? Their county and place counts (3,141 and 483 a year) don't match the `stopifnot()` checks in the .qmd.
- Why are Kusilvak and Oglala Lakota missing in 2014? The EPA tracts are recoded to the new county codes, but the 2010–2014 ACS may still use the old codes (02270, 46113), which would leave those tracts without a population weight.
- Should Valdez-Cordova, Chugach, and Copper River get values, and should the three cities missing from the 2010-place crosswalk use a newer one?
- Do the large 2018 drops in rural California and Oregon counties (Mariposa, Siskiyou, Trinity, Curry), which recover in 2019, reflect wildfire emissions in the 2018 assessment?
- The two "Remove results form Puerto Rico and Virgin Islands" notes (lines 248 and 465): the second chunk only selects columns. The "Save … for 2019" notes (lines 998 and 1016) write all three years.
- The rendered `air_toxicity_metric.html` (1.9 MB) is committed. Is it still needed?
