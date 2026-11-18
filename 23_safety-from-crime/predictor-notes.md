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
Reported violent crimes and reported property crimes per 100,000 people, from the FBI's National Incident-Based Reporting System (NIBRS). Offenses reported by each police agency are assigned to counties (weighted by county population when an agency covers more than one county) or to places, then divided by the ACS 5-year population. "Violent" here means NIBRS crimes against persons and "property" means NIBRS crimes against property, so robbery counts as property crime (see Methodology). The quality flag measures the share of police agencies in the county or place that reported any offenses.

## Methodology
- **Numerator**: offenses reported by police agencies to the National Incident-Based Reporting System (NIBRS), from the Offense Segment. Each offense record counts once, so an incident with several offenses counts more than once.
- **Violent and property**: offenses are grouped with the "crimes against" categories in section 2.3 of the [2021.1 NIBRS User Manual](https://bjs.ojp.gov/sites/g/files/xyckuh236/files/sarble/data_common/nibrs-user-manual-2021-1041521.pdf). Violent is crimes against persons (for example, murder and manslaughter, aggravated and simple assault, intimidation, kidnapping, and sex offenses). Property is crimes against property, which in NIBRS includes robbery. Crimes against society (for example, drug and weapon law violations) aren't in either rate. These are not the FBI's traditional violent and property crime definitions.
- **Denominator**: total population from the American Community Survey (ACS) 5-year estimates ending in the data year (for example, 2017–2021 for 2021). The rate is offenses per 100,000 people. The full county or place population is used whether or not every agency there reported.
- **Agencies included**: every agency in the NIBRS Batch Header except state police. Agencies in Guam, Puerto Rico, and the Virgin Islands are dropped. An agency counts as reporting in a year if it has any offense record that year, regardless of how many months it reported.
- **Counties**: each agency is assigned to the counties listed in its Batch Header record, or, if none is listed, to the county in the 2012 Law Enforcement Agency Identifiers Crosswalk (LEAIC). An agency that covers more than one county has its offenses split across those counties in proportion to each county's total population.
- **Places**: each agency is assigned in full to one place, with no splitting. The place comes first from the LEAIC place code, then from the agency's city name matched to the place name, and finally, for remaining agencies whose first listed county contains only one of the 486 places, that place. Offenses of all agencies assigned to a place are summed.
- **Suppression**: rates are missing when no agency in the county or place reported, or the population is under 30. Loving County, TX is suppressed in every year and Kenedy County, TX in 2023 because their populations are under 100 and their rates are extreme.

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

## Comparability across years
- NIBRS coverage grows each year: 12,538 agencies have offenses in 2021 and 13,662 in 2024 (rendered .html), and missing counties fall from 287 to 213. Some large cities report only part of a year early on (New York city: 5 violent crimes per 100,000 in 2021, 92 in 2022, 2,571 in 2023; Los Angeles: missing in 2021, about 5 in 2022–2023, 1,002 in 2024), so changes across years mostly reflect reporting, not crime.
- All years are rerun with each new Kaplan release because agencies backfill earlier years, so values for the same year differ between metric updates.
- 2021 uses the eight old Connecticut counties and 2023–2024 use the nine planning regions.
- The LEAIC is from 2012, so agencies created since then can't be matched through it.
- Not comparable with the pre-2021 versions, which used UCR summary data with imputation and the FBI violent and property crime definitions.
