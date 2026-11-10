---
metric: Students experiencing homelessness
predictor: 12_housing-stability
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Manuel Alcalá Kovalski]
variables: [count_homeless, count_homeless_lb, count_homeless_ub, share_homeless, count_homeless_quality, share_homeless_quality]
geographies:
  county: 2014-2022
  place: 2014-2022
subgroups: [race-ethnicity]
confidence_intervals: true
code:
  - homelessness.qmd
  - run_homelessness.R
final_files:
  - data/final/homelessness_2014-2022_county.csv
  - data/final/homelessness_2014-2022_city.csv
  - data/final/homelessness_2019-2022_subgroups_county.csv
  - data/final/homelessness_2019-2022_subgroups_city.csv
sources:
  - name: EdFacts LEA homeless students enrolled files (Data Group 655)
    provider: US Department of Education
    vintage: school years 2014-15 to 2018-19
    access: downloaded in code
    url: https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy2014-15.csv
  - name: EdDataExpress, FS118 homeless students enrolled (Data Group 655), LEA files
    provider: US Department of Education
    vintage: school years 2019-20 to 2021-22 (downloaded in code); 2022-23 (manual download or Box)
    access: downloaded in code for 2019-2021; manual download or Box (Metrics_2025_round) for 2022
    url: https://eddataexpress.ed.gov/download/data-builder/data-download-tool
  - name: Common Core of Data (CCD) school district directory and enrollment by race
    provider: National Center for Education Statistics (NCES), via the Urban Institute Education Data Portal
    vintage: 2014-2022
    access: API (educationdata R package)
    url: https://educationdata.urban.org/documentation/school-districts.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Number and share of public school students who experienced homelessness at some point during the school year, from EdFacts counts reported by local education agencies (LEAs, i.e., school districts) divided by Common Core of Data (CCD) enrollment. Year `2014` is school year 2014–15. Race and ethnicity subgroups start in 2019.

## Process
1. Render `run_homelessness.R`, which renders `homelessness.qmd` twice: `geography = "county"` and `geography = "place"`, both with `years = 2014:2022`. Each render writes the all file and, because 2019 and later are in `years`, the subgroup file.
2. Before rendering, save the 2022–23 file by hand as `data/raw/2022-23 LEA homeless student data.csv`. It comes from the EdDataExpress data download tool (Level: Local Education Agency; School Year: 2022–2023; Population: Homeless Students; set the other filters before State) or from Box (`Metrics_2025_round`). The .qmd has step-by-step instructions. The 2014–2021 files are downloaded to `data/raw/` if they aren't there.
3. CCD: pull the school district directory (`leaid`, `county_code`, `city_location`, `enrollment`) for each year from the Education Data Portal API. For 2019 and later, also pull enrollment by race (`grade = 99`, `sex = 99`, the all-grades and both-sexes totals) and combine Asian, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, and two or more races into `enroll_other`.
4. Homeless counts: keep Data Group 655 and the all-students and race rows. Each LEA count of `"S"` (suppressed, 0–2 students) becomes 1, with a lower bound of 0 and an upper bound of 2. If a state-year has two or fewer suppressed LEAs, the upper bound is the smallest count in that state-year instead, because of complementary suppression. For 2019 and later, the Other group is the sum of the four smaller race groups.
5. `inner_join()` homeless counts to CCD on year and `leaid`. Negative or missing enrollment becomes 0, and LEAs with 0 enrollment get 0 homeless students.
6. Aggregate to the geography:
   - County: by the LEA's CCD `county_code`
   - Place: by the LEA's CCD `city_location`, title-cased, matched to the crosswalk place name with " city", " town", " village", " municipality", and " urban county" removed, plus eight hardcoded name fixes (e.g., Nashville, Louisville, Boise)
7. Share = count / enrollment. Race shares divide by race-specific enrollment (e.g., Black homeless students / Black enrolled students).
8. Quality flag, then the suppression rules (see Missing values), then `left_join()` onto `county-populations.csv` or `place-populations.csv` so every geography-year has a row.
9. `evaluate_final_data()` runs against the four `evaluation_form_homeless_student_*.csv` forms in `99a_final-evaluation/`.

## Data quality flag
Based on the ratio of the upper to the lower bound of the count (`calc_quality()` in `homelessness.qmd`):
- `1`: ratio of 1.05 or less
- `2`: more than 1.05 and up to 1.1
- `3`: more than 1.1, or (All only) total enrollment under 30, or a total homeless count of 10–29 (this last rule sets every subgroup's flag to 3)
- `NA`: the value is suppressed
- `share_homeless_quality` is always the same as `count_homeless_quality`.

Tallies:
- County all file: 17,549 rows are `1`, 618 are `2`, 3,984 are `3`, and 6,131 are `NA`. Of the `3`s, 3,766 (95 percent) come from a total count of 10–29.
- Place all file: 3,713 are `1`, 16 are `2`, 63 are `3`, and 578 are `NA`.
- County subgroup file, `3`s: from 1,665 (Black) to 3,962 (Other Races and Ethnicities) of 12,572 rows per group.

## Missing values
Values are suppressed when:
1. the total homeless count is under 10 (every metric for that geography-year)
2. a share is above 1 (that group)
3. the four race groups add up to less than 70 percent or more than 110 percent of the total (all race groups)
4. a count is 2 or less after aggregation (that group)

Because of rule 1, a geography with no homeless students is missing, not 0. The smallest share in either all file is 0.08 percent.

County all file, missing per year: 788 (2014), 756, 703, 665, 619, 665, 695, 642, and 598 (2022), about 22 percent of county-years overall.
- 379 counties are missing every year. They're concentrated in the Plains: Nebraska (65), Kansas (37), South Dakota (37), North Dakota (33), Texas (26), Iowa (23), and Montana (22).
- Share of county-years missing: Nebraska 80 percent, North Dakota 73 percent, South Dakota 71 percent.
- Hawaii: only Honolulu County (15003) has values. The other four Hawaii counties are missing every year.
- Vermont: all 14 counties are missing in 2017, and 0–10 are missing in the other years.

Place all file, missing per year: 71 (2014), 69, 66, 64, 62, 62, 62, 64, and 58 (2022).
- 56 places are missing every year: 24 in Florida (e.g., Hialeah, St. Petersburg, Cape Coral, Pembroke Pines), 6 in California, 5 in Georgia (Johns Creek, Roswell, Sandy Springs, South Fulton, Warner Robins), 3 each in Colorado, Nevada (Henderson, North Las Vegas, Sparks), and Utah, 2 each in Michigan, Minnesota (St. Paul, Woodbury), and South Carolina, and Urban Honolulu, Indianapolis, Newton (MA), High Point (NC), Goodyear (AZ), and Cedar Park (TX).
- 20 more places are missing in some years.

Subgroup files, missing per year (2019–2022):
- County: All 598–695, White 939–1,111, Other 1,296–1,519, Hispanic 1,381–1,578, Black 1,637–1,775
- Place: All 58–64, Hispanic 77–84, White 84–92, Black 80–89, Other 80–101
- 1,101 county-years and 30 place-years have an All value but no race values (rule 3).

## Known issues
- Each LEA's homeless count and enrollment go to one county and one city: the ones in its CCD directory record (`county_code` and `city_location` in the `merge-aggregate` chunk). Districts that cross county or city lines aren't split.
- City values only include districts whose CCD city matches the city name, so cities served by a countywide district get no value. Of the 56 places missing every year, 24 are in Florida, where "each county shall constitute a school district" ([Florida Constitution, Article IX, Section 4](https://www.flsenate.gov/Laws/Constitution#A9S04)).
- Two place names never match because the name cleaning doesn't handle them: "Urban Honolulu CDP" (" CDP" isn't removed) and "Indianapolis city (balance)" (" city" isn't at the end, and there's no hardcoded fix). Both are missing every year (data check).
- Hawaii has one statewide LEA, so all Hawaii students are assigned to Honolulu County (data check: only 15003 has values).
- `count_homeless_lb` and `count_homeless_ub` are bounds from suppressed LEA counts, not statistical confidence intervals. The share has no bounds.
- The upper bound for Other Races and Ethnicities understates uncertainty. The four groups are summed after each `"S"` becomes 1, and `supp_other` is only set when the sum equals exactly 1 (`process-suppression` chunk). So two suppressed groups give `other = 2` with `other_lb = other_ub = 2`, although the true value could be 0–4.
- Subgroup quality flags don't account for small subgroup counts. The suppression and quality rules based on the homeless count use the total count, and the enrollment-under-30 rule only applies to All. Five county-year Black shares equal exactly 1 (counts of 3–11, in Tennessee, Illinois, and Minnesota counties), and three of them are quality `1`.
- Large outliers: 9 county-years have a share above 0.5, with a max of 0.89 (Mora County, NM, 2021). In 2017, Refugio, Calhoun, and Jefferson counties in Texas are 0.58–0.68, and Beaumont, TX (4807000) is 0.92 (17,711 students, compared with 487–1,659 in other years).
- From a script, the 2014–2018 `www2.ed.gov` URLs return an Azure WAF JavaScript challenge (HTTP 403, checked 2026-11-04), so `download.file()` would save an HTML page instead of the CSV on a fresh run. The 2019–2021 EdDataExpress zip URLs return 200.

## Comparability across years
- 2014–2018 counts come from the EdFacts CSV files and 2019–2022 from EdDataExpress. Both are Data Group 655.
- Race and ethnicity subgroups only exist from 2019 on.
- Connecticut has 8 counties through 2021 and 9 planning regions in 2022, so the county file has 3,144 rows in 2022 (matching `county-populations.csv`).
- Place files have 485 rows for 2014–2017 and 486 from 2018 on (South Fulton, GA added), matching `place-populations.csv`.
- The 2026 R translation reproduces the earlier Stata files (removed in d5d72c44) closely. Of 22,148 county-years with values in both, 188 have shares that differ by more than 0.001. 3 county-years and 9 place-years have values now that were missing before, and none went the other way.

## Open questions
- Is 2023–24 data out on EdDataExpress yet? The .qmd says it wasn't as of February 2026.
- Why are all Vermont counties missing in 2017? The raw files aren't in the repo, so this couldn't be checked.
- Do St. Paul, St. Petersburg, and Port St. Lucie fail to match because CCD spells them "Saint"? They're missing every year.
- Should Urban Honolulu and Indianapolis get name fixes, like the eight already in the code?
- Are the 2017 Texas Gulf Coast values (Beaumont, Refugio, Calhoun, Jefferson) students displaced by Hurricane Harvey? If so, a note in the footnotes may help.
- The rendered `homelessness-county.html` and `homelessness-place.html` are committed at the folder root. Are they still needed?
- Should the 2014–2018 downloads move to a URL that works from a script, or to Box?
