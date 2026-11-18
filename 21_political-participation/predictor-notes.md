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

## Methodology
- **Numerator**: votes cast for president, the "highest office" on the ballot. For counties, this is the sum of all candidates' votes in the MIT Election Data and Science Lab returns in 2016 and 2020, and MIT's county `totalvotes` in 2024, because some states' 2024 returns include a "total" vote-mode row that would double count if candidate votes were summed. For cities, it is the sum of all presidential candidates' votes in each VEST precinct (`G16PRE*` or `G20PRE*` fields).
- **Denominator**: the citizen voting-age population (CVAP), US citizens ages 18 and older, from the Census Bureau's CVAP special tabulation of the American Community Survey (ACS). Counties use the 5-year tabulation ending in the election year (2012–2016, 2016–2020, 2020–2024). Cities use the 2016–2020 tabulation for both 2016 and 2020.
- **Cap at 1**: county turnout above 1 (more votes than estimated CVAP) is set to 1. City values don't exceed 1, so no cap is applied.
- **Counties with nonstandard reporting**: MIT reports Alaska by election district, so Alaska returns are pooled to one statewide code and Alaska boroughs get no value. Kalawao County, HI is reported with Maui County. Votes reported under Shannon County, SD (46113) are assigned to Oglala Lakota County (46102).
- **Connecticut in 2024**: votes for the eight former counties are split across the nine planning regions in proportion to 2020 population, using the allocation factors in `connecticut_planning_regions_to_pre_2023_counties.csv`.
- **Cities**: precinct votes are apportioned to places by the share of each precinct's area inside the place (areal weighted interpolation), which assumes votes are spread evenly across a precinct. Precinct geometries that are invalid are repaired before the overlay.
- **Quality inputs**: the county flag reflects only the CVAP coefficient of variation (CV), computed from the published margin of error divided by 1.645. City flags also reflect how many precincts are split by the place boundary (`messiness`, the vote-weighted average distance of each precinct's area share from 0 or 1) and whether VEST allocated the state's results to precincts from larger reporting units.

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

## Comparability across years
- Each county year uses a different CVAP tabulation (2012–2016, 2016–2020, 2020–2024).
- County votes are summed candidate votes in 2016 and 2020 and MIT's `totalvotes` in 2024. The 2020 .Rmd notes the two match in 2020.
- Connecticut has 8 counties in 2016 and 2020 and 9 planning regions in 2024, so its values can't be compared county by county.
- The Kentucky and New Jersey allocation downgrade applies to 2020 cities only.
