---
metric: Share with debt in collections
predictor: 04_financial-security
pillar: Rewarding Work
metric_lead: [Manuel Alcalá Kovalski]
variables: [share_debt_coll, share_debt_coll_quality]
geographies:
  county: 2018, 2022, 2023, 2025
  place: 2019, 2021, 2023
subgroups: [race-ethnicity]
confidence_intervals: false
code:
  - county-debt-coll-shares.qmd
  - city-debt-coll-shares.qmd
final_files:
  - final/metrics_overall_debt_coll_all_county.csv
  - final/metrics_overall_debt_coll_race_ethnicity_county.csv
  - final/metrics_overall_debt_coll_all_city.csv
  - final/metrics_overall_debt_coll_race_ethnicity_city.csv
sources:
  - name: Debt in America (county-level overall debt files)
    provider: Urban Institute
    vintage: 2022 (June 2022 file), 2023 (July 2024 file), 2025 (November 2025 file)
    access: downloaded in code
    url: https://apps.urban.org/features/debt-interactive-map/
  - name: Debt in America, 2018 county file (legacy)
    provider: Urban Institute
    vintage: 2018
    access: committed CSV (final/share_debt_2018_long.csv), originally pulled by hand
    url: https://apps.urban.org/features/debt-interactive-map/
  - name: Financial Health and Wealth Dashboard (city file city_2019_23.csv)
    provider: Urban Institute
    vintage: 2019, 2021, 2023
    access: downloaded in code
    url: https://apps.urban.org/features/financial-health-wealth-dashboard/
  - name: Large place to PUMA match summary (place FIPS codes)
    provider: IPUMS USA
    vintage: 2010 PUMAs
    access: downloaded in code
    url: https://usa.ipums.org/usa/resources/volii/large_place_PUMA2010_match_summary.xlsx
crosswalks: []
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
Share of people with a credit bureau record who have debt in collections, from Urban's Debt in America (counties) and Financial Health and Wealth Dashboard (cities). The race-ethnicity file splits each geography into neighborhoods of color and white neighborhoods, based on the racial makeup of zip codes, not each person's race. Medical debt in collections was removed in 2026.

## Process
1. Render `county-debt-coll-shares.qmd`. It downloads the Debt in America county files for 2022, 2023, and 2025 (overall and medical for 2023 and 2025) from the Urban Data Catalog and reads the 2018 values from `final/share_debt_2018_long.csv`, a file committed by hand that can't be pulled with code.
2. `process_debt_data()` builds `state` and `county` from the FIPS column, renames the year-specific share columns, drops `OID` rows, pivots to long format (All, Neighborhoods of color, White neighborhoods), converts `n/a*`, `n/a**`, and `NA` to missing, and sets `share_debt_coll_quality` to `1` when a value is present.
3. The county files combine 2018, 2022, 2023, and 2025 overall debt only; medical debt is processed for 2023 and 2025 but not written out.
4. Render `city-debt-coll-shares.qmd`. It reads `city_2019_23.csv` from the Urban Data Catalog, keeps the `delinquent_debt` column as `share_debt_coll`, and maps the Overall, Residents of color, and White subgroups to All, Neighborhoods of color, and White neighborhoods.
5. State FIPS codes come from `tigris::fips_codes`; place FIPS codes come from the IPUMS large place to PUMA match file, matched on city name, with six city labels fixed by hand. Cities with no place FIPS match are dropped (the code comment says 63).
6. 2022 is dropped from the city files because every value is missing.
7. Neither .qmd joins onto `county-populations.csv` or `place-populations.csv`. Each ends with `evaluate_final_data()` against its forms in `99a_final-evaluation/`.

## Data quality flag
- County: `1` when a value is present, `NA` when it's missing. `2` and `3` are never assigned. All file: 12,138 rows are `1` and 427 are `NA`.
- City: `1` when a value is present, `3` when it's missing. All file: 493 rows are `1` and 122 are `3`.
- The flag only marks missing values; it doesn't reflect sample size (`process_debt_data()` in `county-debt-coll-shares.qmd`, and the `if_else(is.na(share_debt_coll), 3L, 1L)` step in `city-debt-coll-shares.qmd`).

## Missing values
County, All rows (rows present in the file):
- 2018: 197 of 3,142 missing
- 2022: 78 of 3,137
- 2023: 80 of 3,143
- 2025: 72 of 3,143
- Neighborhoods of color are missing for 2,265–2,631 counties a year (72–84 percent); White neighborhoods for 236–493.

County rows absent from the file, compared with `county-populations.csv`:
- The nine Connecticut planning regions (09110–09190) are absent in 2022, 2023, and 2025. The files have the eight pre-2022 Connecticut counties (09001–09015) instead.
- 2022 also lacks 02063, 02066, 02105, 02230, 02275, 31113, and 48155, and has 02261, which isn't in the target file for 2022.

City:
- Only 203, 207, and 205 places in 2019, 2021, and 2023, out of 486 in `place-populations.csv`. Three place codes in the file aren't in the target file: 0620802, 2250115, and 5103000.
- All rows missing: 3 in 2019, 117 in 2021, 2 in 2023.
- Neighborhoods of color missing: 21, 121, and 24 places; White neighborhoods: 29, 130, and 38.

## Known issues
- The city and county measures aren't the same. The city file uses the dashboard's `delinquent_debt` column (`select(... share_debt_coll = delinquent_debt)` in `city-debt-coll-shares.qmd`), which the old `documentation/overview.md` describes as derogatory debt, including collections, charge-offs, repossessions, and foreclosures. The county measure is debt in collections only.
- Subgroups are based on the racial makeup of zip codes, not on each person's race: majority-white communities are zip codes where 50 percent or more of residents are non-Hispanic white ([Debt in America Technical Appendix 2025](https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2025/11/19/Debt%20in%20America%20Technical%20Appendix%202025.pdf)).
- Connecticut is reported on the old county boundaries. The credit bureau data provider hasn't updated to the planning regions, so Debt in America reports the 2021 county-equivalents (Technical Appendix 2025, linked above). In the final files, 2022–2025 have 09001–09015 and no planning regions.
- The final files don't follow the target geography files: no `left_join()` onto `county-populations.csv` or `place-populations.csv` in either .qmd, so county years have 3,137–3,143 rows instead of 3,142 or 3,144, and cities have about 200 of 486 places (row counts from the final CSVs).
- 2018 can't be reproduced. The .qmd reads a CSV committed by hand and notes "we don't have a programmatic way to pull this file and reproduce the quality flags" (`county-debt-coll-shares.qmd`, 2018 section).

## Comparability across years
- 2022 and 2023 on: Debt in America changed the threshold for communities of color and majority-white communities from 60 percent to 50 percent, so the race-ethnicity breakdowns aren't directly comparable across that break (Technical Appendix 2025, footnote 2). The All values aren't affected by the threshold.
- Earlier Debt in America editions used a 2 percent sample; the 2025 edition uses a 4 percent sample (Technical Appendix 2025).
- City values (2019, 2021, 2023) measure derogatory debt and county values (2018, 2022, 2023, 2025) measure debt in collections, so city and county values shouldn't be compared directly.
- Medical debt was removed in 2026 because the three nationwide credit reporting companies changed medical debt reporting starting in 2022, which lowered the share with medical debt on credit records but not necessarily the share with medical debt (`county-debt-coll-shares.qmd` overview; Technical Appendix 2025, footnote 6).

## Open questions
- The 2022 sample size is described two ways: the .qmd says 2 percent, and the old `documentation/overview.md` says 4 percent for February 2022. Which is right?
- Should both .qmd files join onto `county-populations.csv` and `place-populations.csv` so the files have 3,144 counties and 486 places per year? The three place codes not in `place-populations.csv` (0620802, 2250115, 5103000) would drop out.
- The subgroups describe neighborhoods but use `subgroup_type = "race-ethnicity"`. The README's subgroup table has a `race-share` type for neighborhood-based groups ("Majority Non-White", "Majority White, Non-Hispanic"). Which type should these use?
- Final files are in `final/`, not `data/final/` as in the README. `final/share_debt_2018.csv` isn't read by either .qmd, and `final/share_debt_2018_long.csv` is an input stored in the output folder.
- The county .qmd says the 2025 data are "from August 2025, released November 2024"; the 2025 file is dated November 2025 in its URL.
- The city .qmd says "There are four final files to be tested" but tests two.
