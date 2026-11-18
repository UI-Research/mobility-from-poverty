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

## Methodology
- **Numerator**: students enrolled in public schools who experienced homelessness at any point during the school year, as reported by local education agencies (LEAs, i.e., school districts) to EdFacts (Data Group 655). This uses the McKinney-Vento definition of homelessness ([42 U.S.C. 11434a](https://www.law.cornell.edu/uscode/text/42/11434a)), which includes students sharing housing with others because of loss of housing or economic hardship, not only those in shelters or unsheltered.
- **Denominator**: Common Core of Data (CCD) enrollment for the same LEAs and year. Race and ethnicity shares divide by enrollment of that group (e.g., Black students experiencing homelessness / Black students enrolled).
- **Year**: `year` is the fall of the school year, so `2014` is school year 2014–15.
- **Suppressed LEA counts**: EdFacts suppresses counts of 0–2 students. Each suppressed LEA count is set to 1, with a lower bound of 0 and an upper bound of 2. When a state-year has two or fewer suppressed LEAs, the upper bound is the smallest reported count in that state-year instead, because of complementary suppression. `count_homeless_lb` and `count_homeless_ub` come from these bounds, not from sampling error, and the share has no bounds.
- **Geography**: each LEA is assigned in full to the county and city in its CCD directory record. Districts that cross county or city lines aren't split. Cities are matched to LEAs by city name, so a city served by a countywide district (e.g., most of Florida) gets no value.
- **Subgroups**: Black, Hispanic, and White, Non-Hispanic come straight from EdFacts. Other Races and Ethnicities combines Asian, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, and two or more races. Race and ethnicity data start in school year 2019–20.
- **Small counts**: geographies with fewer than 10 students experiencing homelessness are suppressed rather than reported as 0 (see Missing values).

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

## Comparability across years
- 2014–2018 counts come from the EdFacts CSV files and 2019–2022 from EdDataExpress. Both are Data Group 655.
- Race and ethnicity subgroups only exist from 2019 on.
- Connecticut has 8 counties through 2021 and 9 planning regions in 2022, so the county file has 3,144 rows in 2022 (matching `county-populations.csv`).
- Place files have 485 rows for 2014–2017 and 486 from 2018 on (South Fulton, GA added), matching `place-populations.csv`.
- The 2026 R translation reproduces the earlier Stata files (removed in d5d72c44) closely. Of 22,148 county-years with values in both, 188 have shares that differ by more than 0.001. 3 county-years and 9 place-years have values now that were missing before, and none went the other way.
