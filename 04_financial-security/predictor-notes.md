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

## Methodology
- **County measure**: share of people with a credit bureau record who have any debt in collections, as published in Debt in America. Debt in America is built from a sample of deidentified credit records (Debt in America Technical Appendix 2025).
- **City measure**: the Financial Health and Wealth Dashboard's `delinquent_debt` share, which measures derogatory debt rather than debt in collections alone, so it differs from the county measure.
- **Years**: each year is the value the source publishes for that year; no years are interpolated or filled. The 2018 county values come from an earlier Debt in America county file. Medical debt in collections is not included.
- **Subgroups**: neighborhoods of color and white neighborhoods are defined by the racial makeup of each person's zip code, not by the person's race. Since the 2023 data, majority-white communities are zip codes where at least 50 percent of residents are white, non-Hispanic ([Debt in America Technical Appendix 2025](https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2025/11/19/Debt%20in%20America%20Technical%20Appendix%202025.pdf)). The dashboard's "Residents of color" and "White" city subgroups are relabeled to the same names.
- **Geography**: counties are the county Federal Information Processing Standards (FIPS) codes Debt in America reports. For Connecticut that means the eight pre-2022 counties in every year, because the credit data provider hasn't moved to the planning regions (Technical Appendix 2025). Cities are matched to place FIPS codes by city name, using the IPUMS large place to PUMA match file; cities without a match are dropped.
- **Missing values**: values the source marks as unavailable (`n/a*`, `n/a**`, or `NA`) are set to missing. The values are not suppressed further, and there are no confidence intervals.

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

## Comparability across years
- 2022 and 2023 on: Debt in America changed the threshold for communities of color and majority-white communities from 60 percent to 50 percent, so the race-ethnicity breakdowns aren't directly comparable across that break (Technical Appendix 2025, footnote 2). The All values aren't affected by the threshold.
- Earlier Debt in America editions used a 2 percent sample; the 2025 edition uses a 4 percent sample (Technical Appendix 2025).
- City values (2019, 2021, 2023) measure derogatory debt and county values (2018, 2022, 2023, 2025) measure debt in collections, so city and county values shouldn't be compared directly.
- Medical debt was removed in 2026 because the three nationwide credit reporting companies changed medical debt reporting starting in 2022, which lowered the share with medical debt on credit records but not necessarily the share with medical debt (`county-debt-coll-shares.qmd` overview; Technical Appendix 2025, footnote 6).
