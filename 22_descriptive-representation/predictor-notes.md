---
metric: Descriptive representation (population share by race and ethnicity, the denominator)
predictor: 22_descriptive-representation
pillar: Responsive and Just Governance
metric_lead: [JP Walsh]
variables: [share_desc_rep_other, share_desc_rep_other_quality, share_desc_rep_black_nonhispanic, share_desc_rep_black_nonhispanic_quality, share_desc_rep_hispanic, share_desc_rep_hispanic_quality, share_desc_rep_white_nonhispanic, share_desc_rep_white_nonhispanic_quality]
geographies:
  county: 2014, 2016, 2018, 2021, 2023
  place: 2014, 2016, 2018, 2021, 2023
subgroups: none
confidence_intervals: false
code:
  - descriptive_representation_denom.qmd
final_files:
  - data/final/descriptive_rep_denominator_county_all.csv
  - data/final/descriptive_rep_denominator_city_all.csv
sources:
  - name: American Community Survey (ACS) 5-year estimates, tables B01003, B03002, and B03003
    provider: US Census Bureau
    vintage: 2010-2014, 2012-2016, 2014-2018, 2017-2021, and 2019-2023
    access: Census API through tidycensus get_acs(), key in CENSUS_API_KEY
    url: https://www.census.gov/programs-surveys/acs/data.html
crosswalks: [geographic-crosswalks/data/county-populations.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
---

## Summary
Share of the county or city population in each of four race and ethnicity groups, from the ACS 5-year estimates: Black non-Hispanic, Hispanic (any race), white non-Hispanic, and other (non-Hispanic Asian, American Indian and Alaska Native, Native Hawaiian and Other Pacific Islander, some other race, and two or more races). The four shares sum to 1. These are the denominator of the descriptive representation ratio (share of local elected officials in a group divided by the group's share of residents). The published variables are only these population shares; no ratio with elected officials is computed for any of the five years.

## Methodology
- **Measure**: each group's count divided by the total population of the county or city. Only these population shares are published. They are meant as the denominator of a representation ratio (a group's share of local elected officials divided by its share of residents), and no officials data are included.
- **Population**: all residents of every age, including people in group quarters, from American Community Survey (ACS) table `B01003` (total population).
- **Race and ethnicity groups**: Hispanic is anyone of Hispanic or Latino origin, of any race (`B03003`). The other three groups are non-Hispanic only (`B03002`): Black alone, white alone, and other. Other combines non-Hispanic Asian, American Indian and Alaska Native, Native Hawaiian and Other Pacific Islander, some other race, and two or more races. The four groups are mutually exclusive and sum to the total population, so the four shares sum to 1.
- **Estimates and years**: values are ACS 5-year estimates, and `year` is the last year of the period, so `2014` is 2010–2014. Only 2014, 2016, 2018, 2021, and 2023 are produced.
- **Margins of error**: ACS margins of error aren't carried into the shares, so the values are point estimates only.
- **Geography**: counties and places come directly from ACS county and place tables, matched to the target list of counties and cities on the five-digit county or seven-digit place code. No crosswalk or allocation is needed.

## Data quality flag
- `1` for every row and variable. The .qmd sets this because the values come from published Census summary tables.
- County file: all 15,713 rows are `1`. City file: all 2,428 rows are `1`.

## Missing values
No values are missing in either file.

Rows per year:
- County: 3,142 in 2014, 2016, and 2018; 3,143 in 2021; 3,144 in 2023 (the nine Connecticut planning regions), matching `county-populations.csv`
- City: 485 in 2014 and 2016, 486 from 2018 on. South Fulton, GA (13 72122) isn't in `place-populations.csv` before 2018.

Values of exactly 0 or 1 (counties):
- Black non-Hispanic share is 0 in 92–104 counties a year (487 county-years)
- Hispanic share is 0 in 8–15 counties a year (65 county-years)
- Other share is 0 in 4–15 counties a year (50 county-years)
- White non-Hispanic share is 1 in five county-years: 30069 (2016), 31009 (2018, 2021, 2023), and 38007 (2021)

Cities: Mission city, TX (48 48768) has a Black non-Hispanic share of 0 in 2018, and 0.3–0.9 percent in the other years.

## Comparability across years
- The five years are overlapping 5-year periods (2010–2014, 2012–2016, 2014–2018, 2017–2021, 2019–2023). The Census Bureau advises against comparing overlapping 5-year estimates ([Comparing ACS data](https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data.html)).
- The other share grows faster after 2018: the median county share is 2.7 percent in 2014, 3.0 percent in 2018, 3.9 percent in 2021, and 4.8 percent in 2023, with the white non-Hispanic share falling by about the same amount.
- There are no values for 2015, 2017, 2019, 2020, 2022, or 2024.
