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

## Methodology
- **Unit**: households, not people. Each household is represented by its householder record, and people in group quarters are excluded. Households are weighted by the ACS household weight (`HHWT`).
- **Numerator**: households with high-speed internet installed (`CIHISPEED`: cable modem, fiber optic, or DSL) and at least one desktop, laptop, or tablet computer (`CILAPTOP` or `CITABLET`).
- **Denominator**: all households, whether they have an internet subscription, access without a subscription, or no internet access (`CINETHH`). Households without a subscription, and households with high-speed internet but no computer, count as not having access.
- **Excluded records (2023)**: IPUMS suppressed `CIHISPEED` for some Public Use Microdata Areas (PUMAs) in the 2019–2023 sample ([IPUMS](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)). Those households are dropped from both numerator and denominator.
- **Geography**: the ACS identifies PUMAs, and for counties with large enough populations, the county (`COUNTYFIP`). For counties, a household with an identified county counts in that county with its full weight. Otherwise it is assigned to every county its PUMA overlaps, with its weight multiplied by the allocation factor (`afact`), the share of the PUMA's population in that county. For places, every household is assigned this way. Counties and places that share PUMAs can get the same value. 2018 and 2021 use 2010 PUMAs, and 2023 uses 2020 PUMAs, each with the matching crosswalk.
- **Subgroups**: assigned by the householder's race and ethnicity and by household income.
  - Race and ethnicity: Hispanic if the householder is Hispanic, regardless of race. Non-Hispanic householders are White, Non-Hispanic; Black, Non-Hispanic; or Other Races and Ethnicities (all other races, including two or more races).
  - Income: total household income (`HHINCOME`) less than $50,000, or $50,000 or more. The threshold is the same nominal dollar amount in every year.
- **Small samples**: a geography, or a geography and subgroup, with fewer than 30 household records after the crosswalk is reported as missing. Each record in a PUMA counts toward every county or place the PUMA overlaps.
- **No confidence intervals**: the ACS replicate weights aren't used, so values have no confidence intervals.

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

## Comparability across years
- Years are 5-year samples that overlap: 2018 (2014–2018) and 2021 (2017–2021) share 2017 and 2018.
- 2018 and 2021 use 2010 PUMAs and the 2012 crosswalks; 2023 uses 2020 PUMAs and the 2022 crosswalks. IPUMS assigns 2020 PUMAs to every year of the 2019–2023 sample ([PUMA](https://usa.ipums.org/usa-action/variables/PUMA)). The PUMA change moves many places to better quality flags: place quality `3` drops from 125 to 7.
- Connecticut uses its eight old counties in 2018 and 2021 and its nine planning regions in 2023.
- Part of 2023 is affected by the `CIHISPEED` suppression for some PUMAs, which the code drops ([IPUMS comparability notes](https://usa.ipums.org/usa-action/variables/CIHISPEED#comparability_section)).
