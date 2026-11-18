---
metric: Just policing (juvenile arrests per 100,000 juveniles)
predictor: 24_just-policing
pillar: Responsive and Just Governance
metric_lead: [Vincent Pancini]
variables: [rate_juv_arrest, rate_juv_arrest_quality]
geographies:
  county: 2021-2024
  place: 2021-2024
subgroups: [race-ethnicity, gender, age]
confidence_intervals: false
code:
  - juvenile-arrests-county-combined.qmd
  - juvenile-arrests-place-combined.qmd
final_files:
  - data/final/rate_arrests_county_all.csv
  - data/final/rate_arrests_county_all_subgroup.csv
  - data/final/rate_arrests_place_all.csv
  - data/final/rate_arrests_place_all_subgroup.csv
sources:
  - name: National Incident-Based Reporting System (NIBRS) Arrestee Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: 2021-2024 per-year .rds files from V11 (August 2025)
    access: manual download after a data use agreement; raw files on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Group B Arrest Report Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: 2021-2024 per-year .rds files from V11 (August 2025)
    access: manual download after a data use agreement; raw files on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: NIBRS Batch Header Segment, Jacob Kaplan's concatenated files
    provider: Federal Bureau of Investigation (FBI), processed by Jacob Kaplan (openICPSR 118281)
    vintage: nibrs_batch_header_1991_2024.rds from V11 (August 2025)
    access: manual download after a data use agreement; raw file on Box
    url: https://www.openicpsr.org/openicpsr/project/118281
  - name: Law Enforcement Agency Identifiers Crosswalk (LEAIC), 2012
    provider: Bureau of Justice Statistics (BJS), via the National Archive of Criminal Justice Data (NACJD) at ICPSR
    vintage: ICPSR 35158 V2
    access: manual download with an ICPSR account
    url: https://www.icpsr.umich.edu/web/NACJD/studies/35158
  - name: American Community Survey (ACS) 5-year estimates, tables B01003, B01001, and B01001A-B01001I
    provider: US Census Bureau
    vintage: 2017-2021 through 2020-2024
    access: API (tidycensus::get_acs()), needs a Census API key
    url: https://www.census.gov/data/developers/data-sets/acs-5year.html
crosswalks:
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
---

## Summary
Arrests of juveniles ages 10–17 per 100,000 juveniles ages 10–17, from the FBI's National Incident-Based Reporting System (NIBRS), for 2021–2024. Each arrest, citation, or summons counts, so the rate counts arrests, not people arrested. The denominator is the ACS 5-year population ages 10–17. The subgroup files repeat the rate by race and ethnicity (four groups), gender, and age (10–14 and 15–17). Earlier years aren't produced because too few agencies reported to NIBRS before 2021.

## Methodology
- **Numerator**: arrests of people ages 10–17 reported to the National Incident-Based Reporting System (NIBRS), combining the Arrestee Segment (arrests for Group A offenses) and the Group B Arrest Report Segment (arrests for Group B offenses, such as bad checks and disorderly conduct). The two segments don't overlap ([Kaplan, Decoding FBI Crime Data](https://ucrbook.com/arrestee.html)). Each arrest, citation, or summons counts, so a juvenile arrested twice counts twice. Arrestees with unknown age aren't counted.
- **Denominator**: population ages 10–17 from the American Community Survey (ACS) 5-year estimates ending in the data year (for example, 2017–2021 for 2021), table `B01001` and its race and ethnicity versions. The rate is arrests per 100,000 juveniles, and is missing when that population is under 30.
- **Race and ethnicity subgroups**: arrestees are grouped by the race and ethnicity the agency records.
  - White and Black: `race_of_arrestee` of white or Black, including Hispanic arrestees; denominators are the race-alone populations (`B01001A`, `B01001B`), which also include Hispanic juveniles.
  - Hispanic: `ethnicity_of_arrestee` of Hispanic or Latino, of any race; denominator `B01001I`.
  - Other Races and Ethnicities: Asian, Native Hawaiian or Other Pacific Islander, and American Indian or Alaska Native arrestees; the denominator also includes some other race and two or more races, which NIBRS doesn't record.
  - Arrestees of unknown race count only toward All, the gender groups, and the age groups. Age groups are 10–14 and 15–17.
- **Agencies included**: every agency in the NIBRS Batch Header except state police. Agencies in Guam, Puerto Rico, and the Virgin Islands are dropped. An agency counts as reporting in a year if it has at least one arrest of any age that year, regardless of how many months it reported.
- **Counties**: each agency is assigned to the counties listed in its Batch Header record, or, if none is listed, to the county in the 2012 Law Enforcement Agency Identifiers Crosswalk (LEAIC). An agency that covers more than one county has its arrests split across those counties in proportion to each county's total population (all ages).
- **Places**: each agency is assigned in full to one place, with no splitting. The place comes first from the LEAIC place code, then from the agency's city name matched to the place name, and finally, for remaining agencies whose first listed county contains only one of the 486 places, that place. Arrests of all agencies assigned to a place are summed.
- **Subgroup quality**: each subgroup row takes the overall quality flag for its county or place, because reporting is measured by agency, not by subgroup.

## Data quality flag
- `1`: every agency in the county or place reported
- `2`: at least 80 percent of agencies reported, or every core-city agency reported
- `3`: some agencies, but fewer than 80 percent, reported
- `NA`: no agency reported, there is no agency in the county or place, or the population ages 10–17 is under 30
- County file: 3,414 county-years are `1`, 2,349 are `2`, 5,773 are `3` (46 percent), and 1,039 are `NA`, out of 12,575. By year, `3` is 1,414–1,460.
- Place file: 1,015 place-years are `1`, 498 are `2`, 154 are `3`, and 277 are `NA`, out of 1,944. `1` rises from 222 places in 2021 to 271 in 2024.

## Missing values
`rate_juv_arrest` is `NA` exactly where the quality flag is `NA`.

County file, counties missing per year: 308 (2021), 266 (2022), 243 (2023), 222 (2024).
- 149 counties are missing every year. The most are in Pennsylvania (31), Mississippi (17), Indiana (15), New York (15), Florida (14), and Alaska (10).
- District of Columbia (11001): every year
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year
- All nine Connecticut planning regions (09110–09190): 2022. They have values in 2023 and 2024, and the eight old counties have values in 2021.

County subgroup file, counties missing per year:
- Black: 1,371–1,390
- Hispanic: 661–753
- Other Races and Ethnicities: 368–574, falling each year
- White, Male, Female, and both age groups: within 15 of the All count each year

Place file, places missing per year: 116 (2021), 63 (2022), 54 (2023), 44 (2024).
- 43 places are missing every year: 25 in California (for example Compton, Lancaster, Palmdale, and Santa Clarita), 12 in Florida (for example Orlando, Miami Beach, and Pompano Beach), Washington, DC (11-50000), Urban Honolulu CDP, HI (15-71550), South Fulton and Athens-Clarke County, GA, Rochester Hills, MI, and Syracuse, NY.
- Los Angeles city (06-44000): 2021

Place subgroup file: every subgroup is missing for the same places as All, except Black (121, 67, 57, and 48 places a year).

## Comparability across years
- NIBRS coverage grows every year, so changes mostly reflect more agencies reporting (section 7 of each .qmd says the same). The median county rate goes from 570 (2021) to 698 (2024), and the median place rate from 913 to 1,281. Los Angeles city goes from missing (2021) to 1.7 (2022) and 172 (2024).
- Every update reruns all years with Kaplan's latest release, since agencies backfill earlier years (section 0.1), so a year's values change between releases.
- The 2026 release labels the white subgroup "White". The 2025 release labeled the same calculation "White, Non-Hispanic" (98ec1b5c).
- Connecticut uses the eight old counties in 2021 and the nine planning regions from 2022 on.
- The denominators are overlapping ACS 5-year samples (2017–2021 to 2020–2024), which the Census Bureau advises against comparing ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
