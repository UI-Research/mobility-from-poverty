---
metric: Share of students attending high-poverty schools, by race and ethnicity
predictor: 08_school-economic-diversity
pillar: High-Quality Education
metric_lead: [E Gutierrez, JP Walsh]
variables: [share_meps20_black, share_meps20_black_quality, share_meps20_hispanic, share_meps20_hispanic_quality, share_meps20_white, share_meps20_white_quality]
geographies:
  county: 2014-2022
  place: 2014-2022
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - MEPS_metric_county.qmd
  - MEPS_metric_city.qmd
final_files:
  - data/final/meps_county_2014-2022.csv
  - data/final/meps_place_2014-2022.csv
sources:
  - name: Common Core of Data (CCD), school enrollment by race and ethnicity (grade 99, all grades)
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022 (school years 2014-15 through 2022-23)
    access: API (educationdata R package), cached to data/raw/ccd_enr_2014-2022.rds
    url: https://educationdata.urban.org/documentation/schools.html
  - name: Common Core of Data (CCD), school directory
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022
    access: API (educationdata R package), cached to data/raw/ccd_dir_2014-2022.rds
    url: https://educationdata.urban.org/documentation/schools.html
  - name: Model Estimates of Poverty in Schools (MEPS)
    provider: Urban Institute
    vintage: 2014-2022
    access: local Stata file data/raw/Abrv Set of Portal Variables.dta, internal Urban file not in the repo
    url: https://www.urban.org/research/publication/model-estimates-poverty-schools
crosswalks: [geographic-crosswalks/data/county-populations.csv, geographic-crosswalks/data/place-populations.csv]
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Share of Black, Hispanic, and White students in the county or city who attend a school where 20 percent or more of students live in poverty. School poverty comes from the Urban Institute's Model Estimates of Poverty in Schools (MEPS), the modeled share of students with family incomes at or below 100 percent of the federal poverty level ([MEPS report](https://www.urban.org/sites/default/files/2022-06/Model%20Estimates%20of%20Poverty%20in%20Schools.pdf)). There is no value for all students.

## Methodology
- **High-poverty school**: a school whose MEPS share of students at or below 100 percent of the federal poverty level is 20 percent or more. Schools with no MEPS value are not counted as high poverty.
- **Numerator**: Black, Hispanic, or White students enrolled in high-poverty schools in the county or city, from Common Core of Data (CCD) enrollment by race and ethnicity, all grades combined.
- **Denominator**: all students of that group enrolled in schools in the county or city, including schools without a MEPS value. Schools with missing or zero total enrollment in the CCD directory are excluded. When a group has no students enrolled, the share is `NA`.
- **Race and ethnicity**: the CCD categories Black, Hispanic, and White, as reported by schools. There is no value for all students or for other groups.
- **Schools counted**: every school in the CCD directory with enrollment, regardless of school type.
- **Year**: `year` is the fall of the school year, and MEPS and CCD are matched by school and year, so `2014` uses 2014–15 enrollment and 2014–15 MEPS.
- **Counties**: each school is assigned to the county in its CCD directory record.
- **Cities**: each school is assigned to the city named in its CCD directory record (`city_location`), matched to the place name and state, not to the place boundary. Place names are standardized for the match by dropping suffixes such as "city" and "town" and by renaming 10 consolidated or differently spelled cities by hand (for example, "Louisville/Jefferson County metro government (balance)" to "Louisville").

## Data quality flag
Based on the group's total enrollment in the county or city:
- `1`: 30 or more students
- `2`: 15 to 29 students
- `3`: fewer than 15 students

County file (28,282 rows):
- Black: 18,585 are `1`, 2,927 are `2`, and 5,943 are `3` (21 percent)
- Hispanic: 24,412 are `1`, 1,727 are `2`, and 1,961 are `3`
- White: 27,946 are `1`, 170 are `2`, and 127 are `3`

City file (4,370 rows): all but 18 Black, 3 Hispanic, and 3 White values are `1`.

## Missing values
County file:
- No values in any year: Kalawao County, HI (15005); Issaquena County, MS (28055); Buffalo County, SD (46017); and Loving County, TX (48301)
- Black: 87–106 counties a year, set to `NA` because the county has no Black students enrolled
- Hispanic: 15–27 counties a year
- White: the four counties above, plus 55078 (2020), and 01063 and 13061 (2021)

City file, all three variables missing:
- Urban Honolulu, HI (1571550) and Indianapolis, IN (1836003): every year
- Lee's Summit, MO (2941348) and O'Fallon, MO (2954074): 2014–2019
- Mount Pleasant, SC (4548535): 2014–2017
- South Fulton, GA (1372122): 2018–2022 (and not in the file for 2014–2017, so those years have 485 rows)
- St. Paul, MN (2758000): 2021–2022
- 2015 only: all 15 Illinois cities, plus Charleston and North Charleston, SC (4513330, 4550875). 2015 has 22 missing cities, compared with 3–5 in other years.

## Comparability across years
- `year` is the fall of the school year: 2014 is the 2014–15 school year and 2022 is 2022–23.
- 2022 county rows use Connecticut's nine planning regions (09110–09190), as in `county-populations.csv`; earlier years use the eight old counties.
- The average county share falls every year from 2014 to 2020 and then rises in 2021 (Black students: 53 percent in 2014, 30 percent in 2020, and 37 percent in 2021; the other groups follow the same pattern).
- Illinois cities have no 2015 values.
