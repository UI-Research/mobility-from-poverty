---
metric: Effective public education (English language arts learning growth)
predictor: 07_effective-public-education
pillar: High-Quality Education
metric_lead: [E Gutierrez, JP Walsh]
variables: [learning_rate, learning_rate_lb, learning_rate_ub, learning_rate_quality]
geographies:
  county: 2014-2019
  place: 2014-2019
subgroups: [race-ethnicity, gender, income]
confidence_intervals: true
code:
  - SEDA_metrics_race_county.qmd
  - SEDA_metrics_race_city.qmd
final_files:
  - Data/Final/seda_all_county.csv
  - Data/Final/seda_race_ethnicity_all_county.csv
  - Data/Final/seda_gender_all_county.csv
  - Data/Final/seda_income_all_county.csv
  - Data/Final/seda_all_city.csv
  - Data/Final/seda_race_ethnicity_all_city.csv
  - Data/Final/seda_gender_all_city.csv
  - Data/Final/seda_income_all_city.csv
sources:
  - name: Stanford Education Data Archive (SEDA) 6.0, county and geographic school district long files (seda_county_long_gcs_6.0.csv, seda_geodist_long_gcs_6.0.csv)
    provider: Stanford University
    vintage: version 6.0
    access: downloaded in code
    url: https://purl.stanford.edu/xh833nn4025
  - name: Common Core of Data (CCD) school district directory
    provider: National Center for Education Statistics (NCES), via Urban's Education Data Portal
    vintage: 2008-2019
    access: API (educationdata R package, get_education_data()), city file only
    url: https://educationdata.urban.org/documentation/
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
Average annual learning growth in English language arts (ELA) between third and eighth grade, from the Stanford Education Data Archive (SEDA). The metric is the slope of a cohort's mean test scores across grades, so 1 means a cohort gains about one grade level per year. County estimates come from SEDA's county file. City estimates come from SEDA's school district file, aggregated to cities. Final files are in `Data/Final/` (capital D and F), not `data/final/`.

## Methodology
- **Scores**: SEDA 6.0 mean English language arts (reading/language arts) test scores on the grade cohort standardized (GCS) scale, which places state test results from EDFacts on a common national scale linked to the National Assessment of Educational Progress (NAEP). One unit is about one grade level of learning.
- **Cohorts**: a cohort is the set of students who reach eighth grade in the same spring. Each estimate follows one cohort through grades 3–8 (for example, third grade in spring 2010 through eighth grade in spring 2015). `year` is the fall of that cohort's eighth-grade school year, so `2014` is the cohort in eighth grade in 2014–15.
- **Learning rate**: for each cohort and subgroup, a regression of mean score on grade, with a separate intercept and grade slope for each county (or school district), weighted by the number of test-takers in each grade. The county's grade slope is its learning rate. Grades with no score or no test-takers are left out, so an estimate can rest on fewer than six grades (see Data quality flag).
- **Confidence intervals**: the slope plus or minus 1.96 standard errors from that regression.
- **Subgroups**: SEDA's own groups: White, Non-Hispanic; Black, Non-Hispanic; Hispanic; Male; Female; Economically Disadvantaged; and Not Economically Disadvantaged.
- **Counties**: estimates come directly from SEDA's county file.
- **Cities**: estimates are computed for SEDA geographic school districts, then combined. Each district is assigned in full to the city named in its Common Core of Data (CCD) directory record (`city_location`), matched to the place name and state. City values (the rate and both bounds) are the mean of the district values, weighted by each district's test-takers in that subgroup and cohort; the quality flag is the rounded weighted mean of the district flags.

## Data quality flag
- `1`: five or more grades in the estimate and at least 30 test-takers in every grade
- `2`: four or more grades and at least 30 test-takers in every grade
- `3`: any other nonmissing estimate
- City flags are the rounded, test-taker-weighted mean of the district flags.
- County all file: 14,294 rows are `1`, 2,242 are `2`, 1,613 are `3`, and 703 are missing. City all file: every nonmissing row (2,459) is `1`.

## Missing values
County all file (3,142 counties each year):
- 87, 79, 76, 93, 170, and 198 counties missing in 2014–2019; 52 counties are missing in all six years.
- All 62 New York counties are missing in 2018 and 2019 (11 in 2017).
- All Alaska boroughs and census areas are missing in 2019.
- Nebraska, Texas, Montana, and North Dakota each have 7–17 missing counties every year. Colorado has 5–6 through 2017 and 22–26 in 2018–2019.

City all file (486 places each year):
- 72, 72, 70, 73, 84, and 86 places missing in 2014–2019; 69 places are missing in all six years.
- 26 of 37 Florida places are missing every year, and Urban Honolulu (Hawaii's only place) is missing every year.
- New York places (7) are missing in 2018 and 2019; Anchorage is missing in 2019.

Subgroups, share missing per year:
- County race-ethnicity: Black, Non-Hispanic 58–60 percent; Hispanic 52–54 percent; White, Non-Hispanic 7–11 percent.
- County gender: 6–10 percent. County income: Economically Disadvantaged 6–10 percent; Not Economically Disadvantaged 10–17 percent.
- City subgroups: 14–29 percent, close to the city All rate except Black, Non-Hispanic (22–29 percent).

## Comparability across years
- Each year is a different cohort: `year` = the year the cohort reaches eighth grade, minus 1, and the estimate uses that cohort's scores from grades 3–8.
- New York (2018–2019) and Alaska (2019) drop out entirely, which changes the set of counties behind any state or national comparison in those years.
