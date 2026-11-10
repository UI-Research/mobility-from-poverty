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

## Process
1. Put the MEPS file `Abrv Set of Portal Variables.dta` in `data/raw/`. It isn't in the repo and isn't downloaded in code. The commented-out code that pulls MEPS from the Education Data Portal API is still in both .qmd files.
2. Render `MEPS_metric_county.qmd` and `MEPS_metric_city.qmd`, in either order. They don't depend on each other. The first one to run downloads the Common Core of Data (CCD) enrollment and directory files for 2014–2022 from the Education Data Portal and caches them as `.rds` files in `data/raw/`; the second reads the cache. The enrollment download is large and slow.
3. The years are hardcoded as `year_ed = 2022` and `year_meps = 2022`. The `year: "2025"` parameter in the YAML header isn't used.
4. Enrollment: keep `grade = 99` (all grades), set negative counts to `NA`, sum by school and race, and reshape wide by race.
5. Join the CCD directory (total enrollment, county code, and city name) to the race enrollment and to MEPS by `year` and `ncessch`. Set negative directory enrollment to 0, then drop schools with missing or zero enrollment.
6. Flag a school as high poverty when `meps_poverty_pct / 100 >= 0.20`. For each race, the numerator is that race's enrollment in flagged schools.
7. Geography:
   - County: drop schools with county code `-2`, then sum numerators and enrollment by year, state, and county.
   - City: lowercase the CCD `city_location` and match it to the place name in `place-populations.csv`, after removing " city", " town", " municipality", " village", and " urban county" and renaming 10 cities by hand (for example, "Louisville/Jefferson County metro government (balance)" to "louisville"). The state comes from the school's county code.
8. Share = numerator / enrollment for Black, Hispanic, and White students, set to `NA` when the group's enrollment is 0. `left_join()` onto the county or place file.
9. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/` (`evaluation_form_meps_overall_county.csv`, `evaluation_form_meps_overall_place.csv`) and writes `data/final/meps_<geography>_2014-2022.csv`.

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

## Known issues
- Cities are matched by name, not by location. The city .qmd joins on the lowercased CCD `city_location`, so a school counts toward a city when its address city matches, whether or not it's inside the city boundary, and spelling differences drop cities. Examples checked against the Education Data Portal API: St. Paul schools are "SAINT PAUL" in 2021 and the place file has "St. Paul"; Lee's Summit schools are "LEES SUMMIT" in 2018; "Urban Honolulu CDP" and "Indianapolis city (balance)" aren't covered by the name cleaning.
- In 2015, 4,239 of the 4,241 Illinois schools in the CCD directory have `city_location = "-1"` (checked via the Education Data Portal API; in 2016 Chicago schools have "Chicago"), which is why all Illinois cities are missing in 2015.
- Schools without a MEPS value count as not high poverty. Their enrollment stays in the denominator, but `numerator` is `NA` and the county sum uses `na.rm = TRUE`. In the last render (`MEPS_metric_county.html`), 30,164 school-years had no MEPS value, and only 90–93 percent of directory schools matched MEPS each year.
- There is no "All" value and no Other Races and Ethnicities group. `meps20_total` is computed but dropped by `select()`. The final files are wide (one column per race), not the long `subgroup_type`/`subgroup` format, and are checked with `subgroups = FALSE`.
- Many values are exactly 0 or 1: 37 percent of county Black values, 34 percent of Hispanic, and 32 percent of White. Most quality `3` rows are 0 or 1 (4,419 of 5,943 for Black).
- Neither .qmd filters on school type, so every school in the CCD directory with enrollment counts, whatever its type.

## Comparability across years
- `year` is the fall of the school year: 2014 is the 2014–15 school year and 2022 is 2022–23.
- 2022 county rows use Connecticut's nine planning regions (09110–09190), as in `county-populations.csv`; earlier years use the eight old counties.
- The average county share falls every year from 2014 to 2020 and then rises in 2021 (Black students: 53 percent in 2014, 30 percent in 2020, and 37 percent in 2021; the other groups follow the same pattern).
- Illinois cities have no 2015 values (see Known issues).

## Open questions
- Where does `Abrv Set of Portal Variables.dta` come from, and who has it? The .qmd says it's temporary internal data while the Education Data Portal is updated. The portal API now returns MEPS for 2014–2022 (checked for one school), so the commented-out API code could replace the local file.
- The .qmd text says the MEPS merge "is good outside of years 2021 and 2022", but the rendered match rates for 2021 and 2022 (91 percent) are similar to other years.
- `filter(sex != 99)` and the note above it ("Add the number of enrolled male and female students") don't do anything: the race endpoint only returns `sex = 99` (Total) rows, and with `add_labels = TRUE` the value is the label "Total", which never equals 99.
- The histogram is titled "MEPS mod poverty pct share" but plots `meps_poverty_pct` (100 percent of the federal poverty level), not `meps_mod_poverty_pct`.
- `filter(!year %in% c(2023))` has no effect, since the data only go through 2022.
- Is the 2014–2020 decline and the 2021 rise a real change in school poverty, or a change in MEPS or CCD inputs?
- Should cities be built from school locations (latitude and longitude or a place code) instead of address city names?
