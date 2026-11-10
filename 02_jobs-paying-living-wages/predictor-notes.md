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

## Process
1. Save the four LWI files from Box to `data/living-wage/`: `mit-living-wage.csv` (2018), `mit-living-wage-2022.csv`, `mit-living-wage-2023.csv`, and `LWI-BenchmarkSeries-County-Urban Institute-2025-10-10.xlsx`.
2. Render `jobs-paying-living-wages.qmd` (all) and `jobs-paying-living-wages_industry.qmd` (industry), in either order. They don't depend on each other. Each downloads the annual QCEW files to `data/qcew/` if they aren't there.
3. QCEW: keep county rows, drop county `999` (unknown area), and convert zero wages and establishment counts to `NA`. The all file keeps `ownership == "Total Covered"`. The industry file maps QCEW codes to seven groups:
   - Goods Producing: `naics == 101`
   - Trade, Transit, Utilities: `1021`
   - Information Services: `1022`
   - Professional Services: `1023` (Financial Activities) and `1024` (Professional and Business Services)
   - Education and Health: `1025`
   - Leisure and Other: `1026` (Leisure and Hospitality) and `1027` (Other Services)
   - Public Administration: `naics == 10` with ownership `1`, `2`, or `3` (federal, state, and local government)

   Groups built from more than one code take the `mean()` of the weekly wages and the sum of the establishment counts.
4. Living wage: keep `1 Adult, 2 Children`. Weekly living wage = hourly wage × 40. Years without their own LWI file are filled from another one:
   - 2014–2018: the 2018 file, adjusted to each year with the CPI-U
   - 2019–2022: the 2022 file, adjusted to each year with the CPI-U
   - 2023: the 2023 file
   - 2024: the Benchmark Series file, relabeled `mutate(year = 2024)`
5. `inner_join()` QCEW and the living wage on year, state, and county, then `ratio_living_wage = annual_average_weekly_wage / weekly_living_wage`.
6. `left_join()` onto `county-populations.csv` (expanded to every industry group in the industry file) so every county-year has a row.
7. Each .qmd ends with `evaluate_final_data()` against its form in `99a_final-evaluation/`.

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

## Known issues
- The QCEW average weekly wage includes part-time jobs. QCEW employment counts "filled jobs, whether full or part time" ([BLS Handbook of Methods](https://www.bls.gov/opub/hom/cew/concepts.htm)); the old `documentation/overview.md` noted the same.
- Every industry group except All and Public Administration covers private-sector jobs only. In the QCEW county files, codes `101` and `1021`–`1027` exist only for private ownership (`own == 5`; checked in the 2014 and 2024 files), so public school and public hospital jobs count toward Public Administration, not Education and Health.
- Public Administration here means all government-owned jobs (QCEW [ownership codes](https://www.bls.gov/cew/classifications/ownerships/ownership-titles.htm) 1–3), not the QCEW supersector of the same name (`1028`, [industry titles](https://www.bls.gov/cew/classifications/industry/industry-supersectors.htm)).
- Groups built from more than one code use an unweighted `mean()` of the weekly wages (`jobs-paying-living-wages_industry.qmd`), so a small code counts as much as a large one. This applies to Professional Services, Leisure and Other, and Public Administration (federal, state, and local).
- Industry ratios have a long right tail: 36 county-industry-years are above 3, with a max of 11.5 (Information Services, county 30057, 2020, quality `3`).

## Comparability across years
- The 2024 living wage comes from a different LWI product (the Benchmark Series) than 2023.
- Within 2014–2018 and within 2019–2022, the living wage comes from one file, so changes within those blocks reflect wage growth and the CPI-U only.
- Public Administration has far fewer missing counties from 2022 on.

## Open questions
- The .qmd text lists the 2022 file only for 2021, but the code also uses it for 2019, 2020, and 2022.
- `living_wage_county_all_longitudinal.csv` and `living_wage_county_industry_longitudinal.csv` at the folder root only have 2014, 2018, and 2021–2023. They look like stale copies of the `data/final/` files.
- `scrape-living-wages.R` sources `01_employment-opportunities/get_living_wages.R`, which doesn't exist (`get_living_wages.R` is in this folder). Neither script is called by the .qmd files. Are they still needed?
- Why did Public Administration missing values drop in 2022, and why did missing values rise across industries in 2024?
- Can we get living wages for the Connecticut planning regions?
