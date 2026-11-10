---
metric: Election turnout
predictor: 21_political-participation
pillar: Responsive and Just Governance
metric_lead: [Aaron R. Williams, JP Walsh, Vincent Pancini, Ridhi Purohit]
variables: [share_election_turnout, share_election_turnout_quality]
geographies:
  county: 2016, 2020, 2024
  place: 2016, 2020
subgroups: none
confidence_intervals: false
code:
  - voter-turnout-2016.Rmd
  - voter-turnout-2020.Rmd
  - voter-turnout-2024.qmd
  - voter-turnout-city-2016.Rmd
  - voter-turnout-city-2020.Rmd
final_files:
  - data/final/voter-turnout-2016-2024.csv
  - data/final/voter-turnout-2016.csv
  - data/final/voter-turnout-2020.csv
  - data/final/voter-turnout-2024.csv
  - data/final/voter-turnout-city-2016.csv
  - data/final/voter-turnout-city-2020.csv
sources:
  - name: County Presidential Election Returns 2000-2024
    provider: MIT Election Data and Science Lab (Harvard Dataverse)
    vintage: 2016, 2020, and 2024 elections
    access: downloaded in code (data use agreement on the landing page)
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ
  - name: Citizen Voting Age Population (CVAP) Special Tabulation
    provider: US Census Bureau
    vintage: 2012-2016, 2016-2020, and 2020-2024 ACS 5-year
    access: downloaded in code
    url: https://www.census.gov/programs-surveys/decennial-census/about/voting-rights/cvap.html
  - name: 2016 Precinct-Level Election Results
    provider: Voting and Election Science Team (VEST, Harvard Dataverse)
    vintage: 2016 election
    access: downloaded in code
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/NH5S2I
  - name: 2020 Precinct-Level Election Results
    provider: Voting and Election Science Team (VEST, Harvard Dataverse)
    vintage: 2020 election
    access: downloaded in code
    url: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/K7760H
  - name: Cartographic boundary files, places
    provider: US Census Bureau (via tigris)
    vintage: 2016 and 2020
    access: downloaded in code
    url: https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
  - name: Voting and Registration in the Election of November 2024 (P20, table 4a)
    provider: US Census Bureau (Current Population Survey)
    vintage: 2024
    access: downloaded in code, validation only
    url: https://www.census.gov/data/tables/time-series/demo/voting-and-registration/p20-587.html
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/connecticut_planning_regions_to_pre_2023_counties.csv
last_updated:
  date: 2026-11-10
  by: Manu Alcalá
---

## Summary
Votes cast for president divided by the citizen voting-age population (CVAP), for the 2016, 2020, and 2024 elections. Counties use county vote totals from the MIT Election Data and Science Lab. Cities use precinct results from the Voting and Election Science Team (VEST), apportioned to places by area. There is no city file for 2024.

## Process
Each election has its own file. The 2016 and 2020 files are R Markdown (.Rmd); 2024 is Quarto (.qmd).

1. County numerator (MIT county returns):
   - Recode Shannon County, SD (46113) to Oglala Lakota County (46102), and set every Alaska row to `02000`, because MIT reports Alaska by election district.
   - 2016: drop the three rows without a FIPS code, set Bedford County, VA to `NA` (its `totalvotes` is 0), and sum `candidatevotes`.
   - 2020: assign DC its FIPS code (11001), drop the four Rhode Island "FEDERAL PRECINCT" rows, and sum `candidatevotes`.
   - 2024: keep one `totalvotes` per county, since some states have a "total" vote `mode` row that would double count if candidate votes were summed. Then apportion the eight old Connecticut counties to the nine planning regions with `votes * afact` from `connecticut_planning_regions_to_pre_2023_counties.csv` (2020 population shares).
   - Each file compares state totals with a Wayback Machine copy of Wikipedia's results table. The 2024 file also compares with the Census P20 table.
2. County denominator: CVAP `Total` rows from the ACS 5-year special tabulation ending in the election year (2012–2016, 2016–2020, 2020–2024), Puerto Rico dropped.
3. `left_join()` CVAP to the votes, then `share_election_turnout = votes / cvap`. Values above 1 are set to 1.
4. `left_join()` onto `county-populations.csv` for the election year and write the yearly file. The 2024 .qmd also stacks the 2016, 2020, and 2024 files into `voter-turnout-2016-2024.csv`, so it must run last.
5. Cities (`voter-turnout-city-2016.Rmd`, `voter-turnout-city-2020.Rmd`):
   - Download the VEST precinct shapefiles for each state and the place boundaries from `tigris`, and keep the places in `place-populations.csv`.
   - Drop Z/M dimensions and repair invalid precinct geometries.
   - Apportion precinct votes to places by share of precinct area (areal weighted interpolation, `areal`), and record a `messiness` score for how many precincts are split.
   - Divide by the place CVAP from the 2016–2020 tabulation (both years). Only the 2016 city file runs `evaluate_final_data()`.

## Data quality flag
Counties:
- `1`: CVAP coefficient of variation (CV) below 0.05
- `2`: CV of 0.05 or more and under 0.15
- `3`: CV of 0.15 or more
- Every Missouri county is at least `2` in all three years, and every Connecticut planning region is at least `2` in 2024.
- 2016: 2,931 are `1`, 178 are `2`, 3 are `3`. 2020: 2,906, 196, and 10. 2024: 2,900, 207, and 6.

Cities take the worst of three flags: the CV flag above, an interpolation flag (`messiness` below 0.05 is `1`, below 0.1 is `2`, otherwise `3`), and an allocation flag that sets Kentucky and New Jersey to `3` in 2020, because VEST apportioned their 2020 results from larger reporting units.
- 2016: 418 are `1`, 38 are `2`, 29 are `3`. 2020: 408, 42, and 36.

## Missing values
Counties:
- Every Alaska borough and census area: 29 in 2016, 30 in 2020 and 2024 (Valdez-Cordova split in 2020)
- Kalawao County, HI (15005): every year, because MIT reports it with Maui County

Cities: none. The 2016 file has 485 places because `place-populations.csv` has 485 in 2016.

## Known issues
- The 2016 and 2020 .Rmd files can't be rerun as they are. They read and write under `05_local-governance/voter-turnout/`, and their YAML loads `05_local-governance/www/web_report.css`; that folder no longer exists. `voter-turnout-city-2016.Rmd` also reads its evaluation form from `10a_final-evaluation/`, which is now `99a_final-evaluation/`, and `voter-turnout-city-2020.Rmd` writes to `05_local-governance/voter-turnout/voter-turnout-city-2020.csv`, not `data/final/`.
- `data/final/voter-turnout-city-2020.csv` names its columns `election_turnout` and `election_turnout_quality`. The 2016 city file and all county files use `share_election_turnout` and `share_election_turnout_quality`.
- Capped values aren't always flagged. The code says counties with turnout above 1 "will be flagged", but the flag only uses the CV. Hanson County, SD (46061) has turnout set to 1 in 2020 with quality `1`. Sixteen county-years are exactly 1 (4 in 2016, 6 in 2020, 6 in 2024).
- The 2016 city file divides 2016 votes by the 2016–2020 CVAP (`voter-turnout-city-2016.Rmd`, `download-cvap` chunk), while the 2016 county file uses the 2012–2016 CVAP.
- The 2024 Connecticut values assume each old county's votes split across planning regions in proportion to 2020 population (`votes * afact`), not by where votes were cast.
- Area-based apportionment assumes voters are spread evenly within each precinct. The city files keep places with less than 100 percent precinct coverage, mostly because place boundaries include water (`voter-turnout-city-2020.Rmd`, "Place Coverage").
- The county .Rmd and .qmd files don't call `evaluate_final_data()`.

## Comparability across years
- Each county year uses a different CVAP tabulation (2012–2016, 2016–2020, 2020–2024).
- County votes are summed candidate votes in 2016 and 2020 and MIT's `totalvotes` in 2024. The 2020 .Rmd notes the two match in 2020.
- Connecticut has 8 counties in 2016 and 2020 and 9 planning regions in 2024, so its values can't be compared county by county.
- The Kentucky and New Jersey allocation downgrade applies to 2020 cities only.

## Open questions
- Should the 2016 and 2020 .Rmd files be moved to Quarto and have their paths updated, or kept as a record of how those files were built?
- Should `voter-turnout-city-2020.csv` be renamed to `share_election_turnout` to match the other files?
- Is a 2024 city file planned?
- Should the 2016 city file use the 2012–2016 CVAP, as the 2016 county file does?
- The 2020 city .Rmd text says "`1` = messiness > 0.05", but the code assigns `1` when `messiness < 0.05`.
- The 2024 .qmd text says to save the MIT file to `21_political-participation/voter-turnout/data/mit`, but the code uses `21_political-participation/data/mit`.
- The rendered `.html` files for all five .Rmd and .qmd files (2–9 MB each) are committed. Are they still needed?
