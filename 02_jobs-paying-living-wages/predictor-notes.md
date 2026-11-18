---
metric: Jobs paying a living wage
predictor: 02_jobs-paying-living-wages
pillar: Rewarding Work
metric_lead: [Kevin Werner, Kassandra Martincheck, Aaron R. Williams]
variables: [ratio_living_wage, ratio_living_wage_quality]
geographies:
  county: 2014-2024
  place: none
subgroups: [industry]
confidence_intervals: false
code:
  - jobs-paying-living-wages.qmd
  - jobs-paying-living-wages_industry.qmd
final_files:
  - data/final/living_wage_county_all_longitudinal.csv
  - data/final/living_wage_county_industry_longitudinal.csv
sources:
  - name: Quarterly Census of Employment and Wages (QCEW), county high-level files
    provider: Bureau of Labor Statistics (BLS)
    vintage: 2014-2024 annual averages
    access: downloaded in code
    url: https://www.bls.gov/cew/downloadable-data-files.htm
  - name: Living Wage Calculator
    provider: Living Wage Institute (LWI, MIT)
    vintage: 2018 file, 2022 file, 2023 file, and Benchmark Series (delivered 2025-10-10)
    access: Box only, not publicly shareable
    url: https://livingwage.mit.edu/
  - name: Consumer Price Index for All Urban Consumers (CPI-U), annual averages
    provider: Bureau of Labor Statistics (BLS)
    vintage: 2014-2024
    access: hardcoded in the .qmd files
    url: https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexannualandsemiannual_table.htm
crosswalks: [geographic-crosswalks/data/county-populations.csv]
last_updated:
  date: 2026-11-03
  by: Manu Alcalá
---

## Summary
Average weekly wage of jobs in the county, from the Quarterly Census of Employment and Wages (QCEW), divided by the weekly living wage for one adult with two children, from the Living Wage Institute (LWI). A value above 1 means average pay covers the living wage. The industry file repeats the calculation for seven industry groups.

## Methodology
- **Numerator**: Quarterly Census of Employment and Wages (QCEW) annual average weekly wage for all jobs covered by unemployment insurance in the county, across private and government employers. QCEW counts jobs where they are located, and counts full- and part-time jobs alike ([BLS Handbook of Methods](https://www.bls.gov/opub/hom/cew/concepts.htm)). Zero wages and establishment counts are treated as missing.
- **Denominator**: the Living Wage Institute (LWI) hourly living wage for a household of one adult and two children, multiplied by 40 hours to get a weekly living wage.
- **Living wage years**: values are in nominal dollars of each year, to match QCEW wages. Years without their own LWI file are filled with the Consumer Price Index for All Urban Consumers (CPI-U):
  - 2014–2018: the 2018 file, adjusted to each year with the CPI-U
  - 2019–2022: the 2022 file, treated as 2022 dollars and adjusted to each earlier year by the CPI-U relative to 2022
  - 2023: the 2023 file, unadjusted
  - 2024: the LWI Benchmark Series file, unadjusted
- **Geography**: QCEW and LWI values are matched by county Federal Information Processing Standards (FIPS) code. County-years present in only one source have no value. QCEW's "unknown or undefined" county (`999`) is dropped.
- **Industry groups**: the industry file uses QCEW supersector codes.
  - Goods Producing: `101`
  - Trade, Transit, Utilities: `1021`
  - Information Services: `1022`
  - Professional Services: `1023` (financial activities) and `1024` (professional and business services)
  - Education and Health: `1025`
  - Leisure and Other: `1026` (leisure and hospitality) and `1027` (other services)
  - Public Administration: all jobs at federal, state, and local government employers (QCEW [ownership codes](https://www.bls.gov/cew/classifications/ownerships/ownership-titles.htm) 1–3), not the QCEW public administration supersector
- **Combined groups**: for groups built from more than one code, the weekly wage is the simple average of the codes' weekly wages, and establishment counts are summed.

## Data quality flag
- `1`: annual average establishment count is 30 or more
- `3`: fewer than 30
- `2` is never assigned.
- All file: 34,392 rows are `1` and 132 are `3`. Industry file: 214,239 are `1` and 60,508 are `3` (22 percent).

## Missing values
All file (the `All` rows of the industry file are the same):
- Kalawao County, HI (15005): every year
- All nine Connecticut planning regions (09110–09190): 2022–2024, so there are no Connecticut values in those years
- Chugach and Copper River, AK (02063, 02066): 2020–2022
- 02270 and 46113 (2014, FIPS codes later replaced)
- Adams County, IA (19003): 2015 and 2018
- Eureka County, NV (32011): 2023

Industry file, counties missing per year:
- Information Services: 690–777 a year through 2023, 874 in 2024
- Leisure and Other: 341–396 a year through 2023, 510 in 2024
- Public Administration: 271–332 a year through 2021, 126–143 from 2022 on
- Professional Services: 248–339
- Education and Health: 107–169
- Goods Producing: 24–36
- Trade, Transit, Utilities: 8–24

## Comparability across years
- The 2024 living wage comes from a different LWI product (the Benchmark Series) than 2023.
- Within 2014–2018 and within 2019–2022, the living wage comes from one file, so changes within those blocks reflect wage growth and the CPI-U only.
- Public Administration has far fewer missing counties from 2022 on.
