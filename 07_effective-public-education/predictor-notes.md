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

## Process
1. Render `SEDA_metrics_race_county.qmd` (county) and `SEDA_metrics_race_city.qmd` (city), in either order. Both write raw downloads to `Data/Raw/`, which isn't in the repo, so create it first.
2. SEDA: download the county file (county .qmd) or the geographic school district file (city .qmd) if it isn't in `Data/Raw/`. Keep `subject == "rla"`, define `cohort = year - grade + 8` (the year the cohort reaches eighth grade), and keep cohorts from 2015 on.
3. City only: download the CCD district directory for 2008–2019 with `get_education_data(level = "school-districts", source = "ccd", topic = "directory")`. Join SEDA districts to CCD on `leaid` and year, fill each district's `city_location` across years, and `inner_join()` to `place-populations.csv` on lowercased city name and state. Ten place names are hand-edited to match CCD spellings (for example, "Boise City" becomes "Boise"). Districts that never match a place are dropped.
4. For each subgroup and cohort, run a regression of mean score on grade interacted with county (or district), weighted by the number of test-takers: `lm(score ~ grade:factor(sedacounty) + factor(sedacounty), weights = n_students)`. The grade slope is `learning_rate`; the bounds are the slope ± 1.96 standard errors. Slopes that are exactly 0 with bounds of 0 are set to `NA`.
5. City only: aggregate district estimates to cities with a weighted mean using each subgroup's test-taker counts. The rate, both bounds, and the quality flag are each averaged this way; the quality flag is then rounded.
6. `year = cohort - 1`. Join to `county-populations.csv` or `place-populations.csv` for 2014–2019 and expand so every geography has a row for every subgroup.
7. Split into all, race-ethnicity, gender, and income files and write them with `data.table::fwrite()`. Each split calls `evaluate_final_data()` first, but see Open questions.

Subgroups, by SEDA code:
- `all`: All
- `wht`, `blk`, `hsp`: White, Non-Hispanic; Black, Non-Hispanic; Hispanic
- `mal`, `fem`: Male, Female
- `ecd`, `nec`: Economically Disadvantaged, Not Economically Disadvantaged

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

## Known issues
- The race-ethnicity files have no Other Races and Ethnicities rows. Both .qmd files build `gcs_mn_oth` (Asian and Native American combined), but `oth` isn't in `subgroups <- c("all", "wht", "blk", "hsp", "nec", "ecd", "mal", "fem")`, and `99_construct-database/test_file_updates.R` expects "Other Races and Ethnicities" when it checks these files.
- City confidence bounds are test-taker-weighted means of the district bounds (`aggregate_to_cities()` in `SEDA_metrics_race_city.qmd`), not intervals estimated for the city.
- City quality flags carry little information: rounding the weighted mean of district flags puts every nonmissing row of `seda_all_city.csv` at `1`.
- A city includes only districts whose CCD `city_location` matches the place name, so districts serving a city but located under another name are left out (`inner_join()` on `city_name` and `state` in `SEDA_metrics_race_city.qmd`).
- County rates go below zero in 27 county-years (min −1.55); 26 of them are quality `3`.

## Comparability across years
- Each year is a different cohort: `year` = the year the cohort reaches eighth grade, minus 1, and the estimate uses that cohort's scores from grades 3–8.
- New York (2018–2019) and Alaska (2019) drop out entirely, which changes the set of counties behind any state or national comparison in those years.

## Open questions
- Both .qmd files call `evaluate_final_data()` with forms in `10a_final-evaluation/`, which doesn't exist; the forms are in `99a_final-evaluation/`. The city chunks use `#| error: true`, so the check fails silently; the county all-file chunk doesn't, so the county render stops there.
- `Data/Raw/` isn't in the repo or `.gitignore`. The code doesn't create it, and the downloaded raw files would show up as untracked files.
- The text at the top of both .qmd files is out of date: it says years "2013 - 2017" (county) or "2013 - 2018" (city), "Uses MEPS," "Uses 2014-2024 data," and the county file says it "Produces city level data." The code produces 2014–2019 ELA learning rates.
- Both .qmd files point to https://edopportunity.org/get-the-data/seda-archive-downloads/ for SEDA, which returns 404. The SEDA 6.0 archive is at https://purl.stanford.edu/xh833nn4025.
- The end year is hardcoded (`config$current_year = 2020`). Does SEDA 6.0 support years after 2019?
- Should Florida and Hawaii cities be matched another way (e.g., by place geography instead of district city name)?
