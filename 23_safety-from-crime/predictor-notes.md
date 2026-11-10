---
metric: Safety from crime (reported violent and property crime)
predictor: 23_safety-from-crime
pillar: Responsive and Just Governance
metric_lead: [Vincent Pancini]
variables: [rate_crime_violent, rate_crime_property, rate_crime_violent_quality, rate_crime_property_quality]
geographies:
  county: 2021-2024
  place: 2021-2024
subgroups: []
confidence_intervals: false
code:
  - reported-crime-county-combined.qmd
  - reported-crime-place-combined.qmd
final_files:
  - data/final/rates_crime_county_all.csv
  - data/final/rates_crime_place_all.csv
sources:
  - name: National Incident-Based Reporting System (NIBRS), Offense Segment, processed by Jacob Kaplan
    provider: Federal Bureau of Investigation (FBI), via openICPSR
    vintage: 2021-2024, V11 (August 2025), file offense_segment_rds_1991_2024.zip
    access: manual download after a data use agreement; on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Batch Header Segment, processed by Jacob Kaplan
    provider: Federal Bureau of Investigation (FBI), via openICPSR
    vintage: V11 (August 2025), file nibrs_batch_header_1991_2024.rds
    access: manual download after a data use agreement; on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: Law Enforcement Agency Identifiers Crosswalk (LEAIC)
    provider: Bureau of Justice Statistics (BJS), via ICPSR (NACJD study 35158)
    vintage: 2012 (V2)
    access: manual download with an ICPSR account; on Box
    url: https://www.icpsr.umich.edu/web/NACJD/studies/35158
  - name: American Community Survey (ACS) 5-year, total population (B01003_001)
    provider: US Census Bureau
    vintage: 2017-2021 through 2020-2024
    access: downloaded in code with tidycensus (Census API key)
    url: https://www.census.gov/programs-surveys/acs
crosswalks: [geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
---

## Summary
Reported violent crimes and reported property crimes per 100,000 people, from the FBI's National Incident-Based Reporting System (NIBRS). Offenses reported by each police agency are assigned to counties (weighted by county population when an agency covers more than one county) or to places, then divided by the ACS 5-year population. "Violent" here means NIBRS crimes against persons and "property" means NIBRS crimes against property, so robbery counts as property crime (see Known issues). The quality flag measures the share of police agencies in the county or place that reported any offenses.

## Process
1. For the place file only: render `geographic-crosswalks/generate_county_place_crosswalks.qmd` first. It writes `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv`, which is not committed (#648).
2. Download Jacob Kaplan's NIBRS files from [openICPSR project 118281](https://www.openicpsr.org/openicpsr/project/118281) (V11) after accepting the data use agreement. Unzip `offense_segment_rds_1991_2024.zip` and move `nibrs_offense_segment_2021.rds` through `nibrs_offense_segment_2024.rds` to `data/offense-segment/`. Move `nibrs_batch_header_1991_2024.rds` (from `batch_header_rds_1991_2024.zip`) to `data/batch-header-segment-and-agencies/`. Harvard Dataverse has 2021–2023 only. The files for this update are on Box.
3. Download the 2012 LEAIC from [ICPSR study 35158](https://www.icpsr.umich.edu/web/NACJD/studies/35158) (Delimited) and move `35158-0001-Data.tsv` to `data/batch-header-segment-and-agencies/`. Both data folders are gitignored by the folder's `.gitignore`.
4. Install a Census API key for `tidycensus` (the `census_api_key()` line in each .qmd is commented out).
5. Render `reported-crime-county-combined.qmd` and `reported-crime-place-combined.qmd`, in either order.
6. Offenses: each `ucr_offense_code` is classified with the crimes-against table from section 2.3 of the [2021.1 NIBRS User Manual](https://bjs.ojp.gov/sites/g/files/xyckuh236/files/sarble/data_common/nibrs-user-manual-2021-1041521.pdf). Person offenses are violent, property offenses are property, and society offenses are counted only in the unused `all` total. Offenses are counted by agency (`ori`) and year.
7. Batch Header: keep 2021–2024, title-case state names, fix Nebraska (`NB` to `NE`) and "Wyoming V2", drop Guam, Puerto Rico, and the Virgin Islands, drop `state police` agencies, and add state FIPS codes by matching on state name and abbreviation.
8. County file:
   - Agencies with no `fips_county_code_1` get a county from the LEAIC (`FIPS_COUNTY`) by ORI.
   - Reshape to one row per agency and county (up to five counties per agency) and join onto ACS 5-year county population (`B01003_001`), with ACS counties as the left side.
   - Each agency's weight in a county is that county's population divided by the total population of all counties the agency lists. Offense counts are multiplied by the weight and summed by county.
9. Place file, assigning a place FIPS code to each agency in three passes (each pass only handles agencies the previous ones missed):
   - LEAIC `FPLACE`, joined by ORI
   - The agency's city name, matched by state and year to `place-populations.csv` after dropping " city", " town", " village", and " municipality" and fixing six names by hand (Ventura, Fort Lauderdale, Augusta, Indianapolis, St. Louis, Winston-Salem)
   - The county-place crosswalk, for agencies whose first listed county overlaps only one of the 486 places (the 2020–2021 GeoCorr rows for 2021, the version with Connecticut planning regions for 2022–2024)

   Agencies in the 486 places are kept and their offense counts summed by place, without weights, then joined onto ACS 5-year place population.
10. Rate = count / population × 100,000. An agency counts as reporting if it has any record in the Offense Segment that year. Rates are `NA` when no agency in the county or place reported or the population is under 30.
11. County only: Loving County, TX (48301) is set to `NA` every year and Kenedy County, TX (48261) in 2023, because of very high rates on populations under 100.
12. Rates are set to `NA` wherever the quality flag is `NA`. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/`.

## Data quality flag
Based on the share of agencies in the county or place that reported (for counties, the unweighted share of agency-county pairs):
- `1`: all agencies reported
- `2`: 80 percent or more reported, or all core-city agencies reported
- `3`: more than 0 and under 80 percent reported
- `NA`: no agency reported, or there is no agency in the Batch Header for the county or place

The violent and property flags are identical in both files, and so are their missing values. County file, all years: 3,736 are `1`, 2,345 are `2`, 5,513 are `3` (44 percent), and 981 are `NA`. Place file: 1,097 are `1`, 431 are `2`, 147 are `3`, and 269 are `NA`.

## Missing values
County file, counties missing per year: 287 in 2021 (9.1 percent), 248 in 2022, 233 in 2023, and 213 in 2024 (6.8 percent). Pennsylvania has the most (50 in 2021, 30 in 2024), followed by Indiana (22–26), Florida (33 in 2021, 16 in 2024), Mississippi (17–19), and New York (16–19). Specific gaps:
- District of Columbia (11001): every year
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year
- Loving County, TX (48301): every year; Kenedy County, TX (48261): 2023 (both suppressed in code)
- All nine Connecticut planning regions (09110–09190): 2022, so there are no Connecticut values that year. The eight old counties have values in 2021 and the planning regions have values in 2023 and 2024.
- Kalawao County, HI (15005): every year

Place file, places missing per year: 110 in 2021, 62 in 2022, 54 in 2023, and 43 in 2024. The 43 missing in 2024 are missing every year: 25 in California (for example Lancaster, Palmdale, Santa Clarita, Compton, Moreno Valley, and Huntington Beach), 12 in Florida (for example Orlando, Miami Beach, and Pompano Beach), Athens-Clarke County and South Fulton, GA, Urban Honolulu CDP, HI, Rochester Hills, MI, Syracuse, NY, and Washington, DC. Most of the 2021 gap is California (72 places).

Zeros: 17–20 counties a year have a violent crime rate of exactly 0 and 13–21 have a property crime rate of 0. Among places, 6 have a violent rate of 0 in 2021 (among them Tempe, Hayward, Jacksonville, and Savannah), and none after that.

## Known issues
- All New York City crime is assigned to New York County. The New York County (36061) violent crime rate is 13,453 per 100,000 in 2023 and 14,050 in 2024, while the four other boroughs are missing every year and the New York city place rate is 2,571 and 2,699 (`data/final/` files). This happens because each agency's offenses are split only across the counties it lists in the Batch Header (`reported-crime-county-combined.qmd`, section 4.4e). The old `documentation/overview.md` described the same problem and used New York State county data for the five boroughs instead.
- District of Columbia is missing from both files every year. `str_to_title()` turns the state name into "District Of Columbia" (`reported-crime-county-combined.qmd` line 326; the rendered .html shows `District Of Columbia DC 12`), which doesn't match "District of Columbia" in the hand-built state FIPS table (line 422), so DC agencies get no state FIPS code and drop out. The same lines are in the place .qmd (288 and 373).
- "Violent" is NIBRS crimes against persons, not the FBI violent crime definition (murder and nonnegligent manslaughter, rape, robbery, and aggravated assault; [FBI](https://ucr.fbi.gov/crime-in-the-u.s/2019/crime-in-the-u.s.-2019/topic-pages/violent-crime)). It includes simple assault and intimidation and leaves out robbery, which NIBRS classifies as a crime against property (`reported-crime-county-combined.qmd` lines 107, 108, and 155). The old `documentation/overview.md` used the FBI definitions.
- An agency counts as reporting if it has any offense that year, however few months it reported. The months-reported filter is commented out (`number_of_months_reported`, county line 348, place line 299). Agencies that reported part of the year get full credit in the quality flag but low rates: New York city has a violent rate of 5.19 per 100,000 in 2021 with quality `2`, and Phoenix has 0.69–0.86 every year (quality `3`). In 2021, 38 places have a violent rate under 50 per 100,000, and 16 of them are quality `1` or `2`.
- The denominator is the full ACS population even when some agencies in the county or place didn't report, so quality `2` and `3` rates are biased down (section 5 of each .qmd).
- The place file's third pass gives every remaining agency in a county (for example the sheriff, a university, or a tribal agency) to the only one of the 486 places in that county, and it uses only the agency's first listed county (`reported-crime-place-combined.qmd` lines 471 and 693). The .qmd notes the first-county shortcut itself.
- The county quality flag uses the unweighted share of agencies reporting. The population-weighted shares (`agencies_reporting_violent_wt` and `agencies_reporting_property_wt`) are computed but not used.

## Comparability across years
- NIBRS coverage grows each year: 12,538 agencies have offenses in 2021 and 13,662 in 2024 (rendered .html), and missing counties fall from 287 to 213. Some large cities report only part of a year early on (New York city: 5 violent crimes per 100,000 in 2021, 92 in 2022, 2,571 in 2023; Los Angeles: missing in 2021, about 5 in 2022–2023, 1,002 in 2024), so changes across years mostly reflect reporting, not crime.
- All years are rerun with each new Kaplan release because agencies backfill earlier years, so values for the same year differ between metric updates.
- 2021 uses the eight old Connecticut counties and 2023–2024 use the nine planning regions.
- The LEAIC is from 2012, so agencies created since then can't be matched through it.
- Not comparable with the pre-2021 versions, which used UCR summary data with imputation and the FBI violent and property crime definitions.

## Open questions
- `data/final/` also holds `rate_arrests_county_all.csv`, `rate_arrests_county_all_subgroup.csv`, `rate_arrests_place_all.csv`, and `rate_arrests_place_all_subgroup.csv`. They are the juvenile arrest files from `24_just-policing`, with 2021–2023 only (the `24_just-policing/data/final/` copies have 2021–2024), committed in c23a32dc. Can they be deleted?
- Why are all nine Connecticut planning regions missing in 2022 but not in 2023 or 2024?
- What does `agency_indicator` value `5` mean? 4,142 Batch Header rows (4.7 percent) have it, and they are kept. The .qmd says it may be a preprocessing error.
- Why are 43 places missing every year, including some with their own police departments (Orlando, Syracuse, Huntington Beach)? Is Urban Honolulu CDP's agency (Honolulu Police Department) matched to a different place code?
- Should New York City crime be split across the five boroughs (by population, or with New York State data as before)?
- Some counts in the .qmd prose are from earlier runs. The place .qmd says 2,224 agencies are still unmatched after the three passes, and the rendered .html shows 3,186.
- The rendered `reported-crime-county-combined.html` and `reported-crime-place-combined.html` are committed. Are they still needed?
