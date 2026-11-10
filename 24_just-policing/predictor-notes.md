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

## Process
1. Download from [Jacob Kaplan's NIBRS files on openICPSR](https://www.openicpsr.org/openicpsr/project/118281) (V11) after accepting the data use agreement: `arrestee_segment_rds_1991_2024.zip`, `group_b_arrest_report_segment_rds_1991_2024.zip`, and `batch_header_rds_1991_2024.zip`. Save the 2021–2024 `.rds` files to `data/arrestee-segment/` and `data/group-b-arrest-report-segment/`, and `nibrs_batch_header_1991_2024.rds` to `data/batch-header-segment-and-agencies/`. The files for this update are on Box (link in each .qmd).
2. Download the 2012 LEAIC from [ICPSR 35158](https://www.icpsr.umich.edu/web/NACJD/studies/35158) (Delimited) and save `35158-0001-Data.tsv` to `data/batch-header-segment-and-agencies/`. All four data folders are gitignored.
3. Install a Census API key for `tidycensus` (the .qmd has the commented-out `census_api_key()` call).
4. For the place file, first render `geographic-crosswalks/generate_county_place_crosswalks.qmd`, which writes `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv` (not committed, #648). The county file doesn't need it.
5. Render `juvenile-arrests-county-combined.qmd` and `juvenile-arrests-place-combined.qmd`, in either order. Each writes its two final files.
6. Arrests (both files): stack the Arrestee (Group A) and Group B segments, which don't overlap ([Kaplan, Decoding FBI Crime Data](https://ucrbook.com/arrestee.html)). `age_of_arrestee` becomes numeric, so "over 98 years old" and "unknown" become `NA`. The all-age file is kept for the quality flag; the juvenile file keeps ages 10–17. Each agency (`ori`) and year gets counts of juvenile arrests in total and by group:
   - White: `race_of_arrestee == "white"`
   - Black: `race_of_arrestee == "black"`
   - Hispanic: `ethnicity_of_arrestee == "hispanic or latino"`, any race
   - Other Races and Ethnicities: Asian, Native Hawaiian or Other Pacific Islander, and American Indian/Alaska Native
   - Male, Female, Age 10 to 14, Age 15 to 17
7. Agencies (both files): keep 2021–2024 from the Batch Header Segment, normalize the casing of state names and abbreviations, drop Guam, Puerto Rico, and the Virgin Islands, recode `NB` to `NE` and "Wyoming V2" to "Wyoming", and add state FIPS codes from a table in the .qmd joined on state name and abbreviation. Drop state police agencies. `core_city` becomes 1 or 0.
8. County file: agencies with no county get one from the LEAIC by `ori`. Reshape to one row per agency and county (up to five counties per agency). An agency in more than one county is split by county total population (`B01003_001`), so each county gets `total_people / sum(total_people)` of the agency's arrests. Sum the weighted counts to the county.
9. Place file: give each agency a place code in three passes, keeping only the first county (`county_fips_1`):
   - By `ori`, from the LEAIC place code (`FPLACE`).
   - Agencies still without a place: by year, state, and lowercase name, from `place-populations.csv`, with " city", " municipality", " village", and " town" removed and six names edited by hand (Ventura, Fort Lauderdale, Augusta, Indianapolis, St. Louis, Winston-Salem).
   - Agencies still without a place: by county, from `county_place_crosswalk_longitudinal.csv` (all years pooled), for counties that overlap exactly one of the 486 places.

   Keep agencies in the 486 places and sum their arrests to the place, with no weights.
10. Denominators: ACS 5-year population ages 10–17 by county or place, from `B01001` (total, sex, and age) and `B01001A`, `B01001B`, and `B01001I` (white alone, Black alone, Hispanic). Other Races and Ethnicities is American Indian/Alaska Native, Asian, Native Hawaiian or Other Pacific Islander, some other race, and two or more races (the last computed as the total minus the single races). Rate = arrests / population × 100,000, set to `NA` when the population is under 30. The ACS rows set the universe: 3,143 counties in 2021, 3,144 from 2022 on (with the Connecticut planning regions), and 486 places.
11. Quality flag (section 6 of each .qmd): an agency is reporting if it has at least one arrest of any age in either segment that year. The flag compares the share of agencies reporting in the county or place, and the share of core-city agencies reporting. When the flag is `NA`, every rate in the row is set to `NA`.
12. Subgroup files: one row per county or place, year, and subgroup. Every subgroup takes the overall quality flag, set to `NA` when the subgroup population is under 30.
13. Each .qmd ends with `evaluate_final_data()` against the overall, race-ethnicity, gender, and age forms in `99a_final-evaluation/`.

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
- District of Columbia (11001): every year (see Known issues)
- Bronx, Kings, Queens, and Richmond counties, NY (36005, 36047, 36081, 36085): every year (see Known issues)
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

## Known issues
- The District of Columbia has no values in any year, at county or place level. `str_to_title()` turns "district of columbia" into "District Of Columbia" (section 4.2, both .qmd files), which doesn't match "District of Columbia" in the state FIPS table, so DC's agencies get no state FIPS and drop out. The rendered county .html shows "District Of Columbia DC 12" in the state count. The 2025 release had DC values (for example 1,096 in 2021, quality `2`, in commit 98ec1b5c). The casing step was added in the 2026 update.
- All New York City juvenile arrests land in New York County (36061). Its rate is 7,515 in 2023 and 8,172 in 2024, about 8 times the New York city place rate (958 and 1,063), and the other four boroughs are `NA` every year because no reporting agency is linked to them. The old `documentation/overview.md` described the same problem in the UCR data and replaced the New York City counties with New York State data.
- The quality flag counts an agency as reporting if it had at least one arrest of any age that year (`reporting = ifelse(is.na(arr_total_allage), 0, 1)`, section 6.1), and the `number_of_months_reported` filter is commented out (section 4.2). An agency that reported part of the year looks complete. Examples: New York city is 1.0 per 100,000 in 2021 with quality `2` (1,063 in 2024); Boynton Beach, FL is 0 in 2021 with quality `1` (2,895 in 2024). Places under 50 per 100,000 with quality `1` or `2`: 18 in 2021, 12 in 2022, 5 in 2023, and 7 in 2024.
- A rate of 0 can mean no juvenile arrests or no reporting by the agencies that make juvenile arrests: arrest counts are summed with `na.rm = TRUE` (section 4.4g and 4.8). 344–395 counties a year are exactly 0, and 207–261 of those are quality `3`. 10–20 places a year are 0, among them Jacksonville, FL and Anchorage, AK in three or more years.
- In the place file, the county pass (section 4.5) gives every agency still without a place the only one of the 486 places in its county, with no filter on agency type. A sheriff's office or university police in such a county counts toward the city. It uses only the agency's first county (`county_fips = county_fips_1`, section 4.2), which the .qmd itself flags.
- White and Black include Hispanic arrestees in the numerator and Hispanic juveniles in the denominator (race-alone tables `B01001A` and `B01001B`), and Hispanic overlaps both. NIBRS has no "some other race" or two-or-more-races code, but the Other Races and Ethnicities denominator includes both groups, so that rate is biased down. Arrestees of unknown race count only toward All, Male, Female, and the age groups.
- County rates are split across counties by total population, not population ages 10–17 (`weight = total_people / sum(total_people)`, section 4.4e).
- Outliers: the highest county rate is 24,209 (Dewey County, SD, 46041, 2023, quality `3`), and the highest place rate is 21,894 (Dayton, OH, 2023, quality `2`). In the county subgroup file, 20 county-years of the Black subgroup are above 100,000, with a max of 248,207.

## Comparability across years
- NIBRS coverage grows every year, so changes mostly reflect more agencies reporting (section 7 of each .qmd says the same). The median county rate goes from 570 (2021) to 698 (2024), and the median place rate from 913 to 1,281. Los Angeles city goes from missing (2021) to 1.7 (2022) and 172 (2024).
- Every update reruns all years with Kaplan's latest release, since agencies backfill earlier years (section 0.1), so a year's values change between releases.
- The 2026 release labels the white subgroup "White". The 2025 release labeled the same calculation "White, Non-Hispanic" (98ec1b5c).
- Connecticut uses the eight old counties in 2021 and the nine planning regions from 2022 on.
- The denominators are overlapping ACS 5-year samples (2017–2021 to 2020–2024), which the Census Bureau advises against comparing ([Comparing ACS Data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).

## Open questions
- Why are the Connecticut planning regions missing in 2022 but not in 2023 or 2024?
- Are some of the 43 places missing every year policed by a county sheriff under contract (for example Lancaster, Palmdale, and Santa Clarita)? If so, should those cities get the sheriff's arrests, or stay missing?
- Agencies with `agency_indicator` "other agencies" (5,202 agency-years) and "5" (4,142, meaning unclear per section 4.2a) are kept. Should state agencies in those groups be dropped like the state police?
- Should the quality flag use `number_of_months_reported`, which section 4.2 has commented out?
- The 2012 LEAIC is the latest version. Is there a newer agency-to-county or agency-to-place crosswalk?
- The .qmd prose has stale numbers and names: the county .qmd says 971 of 1,113 agencies with no county are in the LEAIC (the render prints 1,298), the place .qmd says 2,224 agencies still have no place (the render prints 3,186), section 7 says "2021-2022", and the place .qmd calls the crosswalk `geocorr2022_county_place.csv` and the place list "2016-2022".
