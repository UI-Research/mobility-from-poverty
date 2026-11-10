---
metric: Share of households with broadband access
predictor: 10_digital-access
pillar: High-Quality Education
metric_lead: [Ridhi Purohit]
variables: [share_digital_access, share_digital_access_quality]
geographies:
  county: 2018, 2021, 2023
  place: 2018, 2021, 2023
subgroups: [race_ethnicity, income]
confidence_intervals: false
code:
  - digital_access/digital_access_ver2025.qmd
  - digital_access/explore_digital_access.qmd
final_files:
  - data/final/digital_access_county_all_longitudinal.csv
  - data/final/digital_access_county_race_ethnicity_longitudinal.csv
  - data/final/digital_access_county_income_longitudinal.csv
  - data/final/digital_access_place_all_longitudinal.csv
  - data/final/digital_access_place_race_ethnicity_longitudinal.csv
  - data/final/digital_access_place_income_longitudinal.csv
sources:
  - name: American Community Survey (ACS) 5-Year microdata
    provider: IPUMS USA
    vintage: 2014-2018 (us2018c), 2017-2021 (us2021c), and 2019-2023 (us2023c) 5-year samples
    access: API, through ipumsr (IPUMS_API_KEY required)
    url: https://usa.ipums.org/usa/
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Share of households that have high-speed (broadband) internet installed and a desktop, laptop, or tablet computer, from the 5-year American Community Survey (ACS) microdata. Each year is the last year of a 5-year sample (2018 is 2014–2018). Subgroups are the race and ethnicity of the householder and household income (less than $50,000, or $50,000 or more).

## Process
1. Render `digital_access/digital_access_ver2025.qmd`. It is the only production file. `explore_digital_access.qmd` is the 2017–2021 exploration that justified the household universe; it doesn't write any data.
2. The first run downloads the three IPUMS extracts (`us2018c`, `us2021c`, `us2023c`) to `data/raw/ipums/` with a local `get_ipums_extract()` function (`ipumsr::define_extract_micro()`). It only downloads if that folder is empty. On a rerun, edit the three hardcoded file names (`usa_00022.xml`, `usa_00023.xml`, `usa_00024.xml`) to match your own extract numbers.
3. Keep the householder (`PERNUM == 1`) and households (`GQ` 1, 2, or 5). Drop households with `CINETHH == 0` and, for 2023, `CIHISPEED == 88` (suppressed by IPUMS for some Public Use Microdata Areas, or PUMAs).
4. `DIGITAL_ACCESS` is `1` when `CIHISPEED == 10` and `CILAPTOP` or `CITABLET` is `1`, and `0` when `CIHISPEED == 20`. Every other household (no internet subscription, or broadband without a computer) is `NA`. It is left out of the numerator but kept in the denominator, so it counts as no access.
5. Race and ethnicity: Hispanic if `HISPAN` is not "Not Hispanic"; otherwise Black, White, or Other Races and Ethnicities from `RACE`. Income: `HHINCOME` below or at least $50,000.
6. Crosswalks: `right_join()` the microdata onto the PUMA-to-county and PUMA-to-place crosswalks by state, PUMA, and `crosswalk_period` (Puerto Rico is dropped from the county crosswalk).
   - County: if IPUMS identifies the county (`COUNTYFIP != "000"`), the household keeps its county, its full weight, and `sum_products = 1`. Otherwise it is assigned to every county its PUMA overlaps, with `HHWT * afact` and the crosswalk's `sum_products`.
   - Place: every household gets `HHWT * afact` and the crosswalk's `sum_products`.
7. Share = weighted households with `DIGITAL_ACCESS == 1` divided by all weighted households. Geographies and subgroups with fewer than 30 records are set to `NA`.
8. The county race and ethnicity file is missing Black, Non-Hispanic rows for counties with no Black, Non-Hispanic households in 2021 and 2023; the code adds them back as `NA`.
9. Add the `All` rows to the subgroup files, run `evaluate_final_data()` against the six forms in `99a_final-evaluation/evaluation_form_digital_access_*.csv`, and write the six files to `data/final/`.

## Data quality flag
- `1`: 30 or more records and `sum_products` of 0.75 or more (at least 75 percent of the records come from the geography)
- `2`: 30 or more records and `sum_products` from 0.35 to 0.75
- `3`: 30 or more records and `sum_products` below 0.35
- `NA`: fewer than 30 records (the value is also `NA`)
- County, All: 560 rows are `1`, 454 are `2`, and 2,129 are `3` (68 percent) in both 2018 and 2021; 583, 451, and 2,110 in 2023.
- Place, All: 101 are `1`, 259 are `2`, and 125 are `3` in both 2018 and 2021; 240, 239, and 7 in 2023.
- Subgroup rows get the same flag as their geography's All row, except where the subgroup has fewer than 30 records.

## Missing values
All files:
- No county or place All rows are missing.
- Place 1372122 (South Fulton, GA) has no rows in 2018 or 2021 (485 places). The 2012 PUMA-to-place crosswalk has 485 places and doesn't include it.

County race and ethnicity file, `NA` rows per year (out of 3,143 or 3,144):
- Black, Non-Hispanic: 1,351 (2018), 1,351 (2021), 1,328 (2023)
- Hispanic: 448, 349, 243
- Other Races and Ethnicities: 211, 21, 7
- White, Non-Hispanic: none

Place race and ethnicity file, `NA` rows per year (out of 485 or 486):
- Black, Non-Hispanic: 37, 34, 31
- Hispanic: 4, 2, 1
- Other Races and Ethnicities: 3, 2, 1

Income files: none missing.

## Known issues
- Most counties don't have their own value. IPUMS only identifies counties with large enough populations (`COUNTYFIP`, [IPUMS](https://usa.ipums.org/usa-action/variables/COUNTYFIP)); the rest get the value of the PUMA they're in. In every year, 2,529 or more counties (80 percent) share their exact value with at least one other county, in groups of up to 24 (data check on `digital_access_county_all_longitudinal.csv`).
- The 30-record threshold counts records after the crosswalk join (`n()` in the `create-effective-sample-county` and `create-effective-sample-place` chunks), so every record in a PUMA counts toward each county or place it overlaps, however small the overlap. No county or place All row falls below 30.
- The subgroup quality flag ignores subgroup sample size above 30. `create_quality_metric()` joins the geography's `sum_products` to every subgroup, so the flag tallies are the same for every subgroup except where it's `NA` (data check).
- 2018 rows use the counties in the 2012 PUMA-to-county crosswalk, not the 2018 target counties: they include 02063 and 02066 (Chugach and Copper River, created in 2019) instead of 02261 (Valdez-Cordova), which `county-populations.csv` lists for 2018 (data check).
- `subgroup_type` is `race_ethnicity` (underscore), and the file names use `race_ethnicity` too. The other predictors use `race-ethnicity` (e.g., `03_opportunities-for-income`, `09_preparation-for-college`).
- Outlier: Black, Non-Hispanic households in place 0622230 have a share of 0.036 in 2021, compared with 0.28 in 2018 and 0.31 in 2023, with quality `1` in all three years.

## Comparability across years
- Years are 5-year samples that overlap: 2018 (2014–2018) and 2021 (2017–2021) share 2017 and 2018.
- 2018 and 2021 use 2010 PUMAs and the 2012 crosswalks; 2023 uses 2020 PUMAs and the 2022 crosswalks. IPUMS assigns 2020 PUMAs to every year of the 2019–2023 sample ([PUMA](https://usa.ipums.org/usa-action/variables/PUMA)). The PUMA change moves many places to better quality flags: place quality `3` drops from 125 to 7.
- Connecticut uses its eight old counties in 2018 and 2021 and its nine planning regions in 2023.
- Part of 2023 is affected by the `CIHISPEED` suppression for some PUMAs, which the code drops ([IPUMS comparability notes](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)).

## Open questions
- The code sets `crosswalk_period` to `"pre-2022"` for 2018 and 2021 and filters on it in the evaluation chunks, but since #606 the crosswalks only have `2k`, `2012`, and `2022`. A rerun for 2018 or 2021 matches no PUMAs and the geography checks fail. Should it use `"2012"`?
- The rendered `digital_access_ver2025.html` (2 MB) and `explore_digital_access.html` (1.4 MB) are committed. Are they still needed?
- The code comments in the geography checks say "385 counties" (2018 and 2021) and "386 counties" (2023) where they mean 485 and 486 places. The checks themselves are right.
- Should South Fulton, GA, get 2018 and 2021 values (it isn't in the 2012 PUMA-to-place crosswalk), and should the 2018 Alaska counties match the 2018 target file?
- Should years other than 2018, 2021, and 2023 be added?
