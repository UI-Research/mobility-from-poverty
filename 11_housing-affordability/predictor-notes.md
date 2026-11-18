---
metric: Housing affordability
predictor: 11_housing-affordability
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Will Curran-Groome]
variables:
  - share_affordable_30_ami
  - share_affordable_50_ami
  - share_affordable_80_ami
  - share_affordable_available_30_ami
  - share_affordable_available_50_ami
  - share_affordable_available_80_ami
  - share_affordable_30_ami_quality
  - share_affordable_50_ami_quality
  - share_affordable_80_ami_quality
  - share_affordable_available_30_ami_quality
  - share_affordable_available_50_ami_quality
  - share_affordable_available_80_ami_quality
geographies:
  county: 2014-2019, 2021-2024
  place: 2014-2019, 2021-2024
subgroups: [tenure]
confidence_intervals: false
code:
  - ratio_housing_affordable_available.qmd
  - quality-checks/ratio_housing_affordable_available_comparison.qmd
final_files:
  - data/final/housing_county_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024.csv
  - data/final/housing_county_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024_subgroups.csv
  - data/final/housing_place_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024.csv
  - data/final/housing_place_2014_2015_2016_2017_2018_2019_2021_2022_2023_2024_subgroups.csv
sources:
  - name: American Community Survey (ACS) 1-year microdata, occupied and vacant housing units
    provider: IPUMS USA
    vintage: 2014-2019, 2021-2024 1-year samples (usYYYYa)
    access: API (ipumsr, requires an IPUMS API key)
    url: https://usa.ipums.org/usa/
  - name: Section 8 income limits (area median income thresholds)
    provider: US Department of Housing and Urban Development (HUD)
    vintage: FY2014-FY2019, FY2021-FY2024
    access: downloaded in code
    url: https://www.huduser.gov/portal/datasets/il.html
  - name: Connecticut town to planning region crosswalk
    provider: CT Data Collaborative
    vintage: 2022 planning regions
    access: downloaded in code
    url: https://raw.githubusercontent.com/CT-Data-Collaborative/ct-town-to-planning-region/refs/heads/main/ct-town-to-planning-region.csv
crosswalks:
  - geographic-crosswalks/data/crosswalk_puma_to_county.csv
  - geographic-crosswalks/data/crosswalk_puma_to_place.csv
  - geographic-crosswalks/data/geocorr2018_county_place_2014_thru_2019.csv
  - geographic-crosswalks/data/geocorr2022_county_place_2020_2021.csv
  - geographic-crosswalks/data/geocorr2022_county_place_2022_onwards.csv
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
last_updated:
  date: 2026-11-04
  by: Manu Alcalá
---

## Summary
Two ratios for each county and city, at three income thresholds (30, 50, and 80 percent of area median income, or AMI): housing units affordable at that threshold per household at or below it, and units affordable *and available* (vacant, or occupied by a household at or below the threshold) per household at or below it. A unit is affordable when 12 months of housing costs are at or below 30 percent of the threshold. Each ratio is reported for all households, owners, and renters.

## Methodology
- **Numerator**: housing units affordable at the threshold, counting occupied units and vacant units on the market (for rent, for sale, or rented or sold but not yet occupied). A unit is affordable when 12 months of housing costs are at or below 30 percent of the threshold. For the affordable and available ratio, an occupied unit counts only if the household living in it has income at or below the threshold; every affordable vacant unit counts.
- **Denominator**: households with income (`HHINCOME`) at or below the threshold. Only households are counted; group quarters are excluded.
- **Thresholds**: 30, 50, and 80 percent of area median income (AMI) are the US Department of Housing and Urban Development (HUD) Section 8 income limits for a four-person household (`eli_4`, `l50_4`, `l80_4`) for the fiscal year matching the ACS year. The same limit applies to every household and unit, with no adjustment for household size or number of bedrooms.
- **Housing costs**: renters use gross rent (`RENTGRS`, contract rent plus utilities) and owners use selected monthly owner costs (`OWNCOST`). Incomes and costs are put in the survey year's dollars with the ACS adjustment factor (`ADJUST`).
  - Vacant for rent: contract rent times the household-weighted average ratio of gross rent to contract rent among occupied rentals in the same geography and year.
  - Vacant for sale: the monthly payment on a 30-year mortgage for 90 percent of the home's value at 0.5 percent monthly interest, plus private mortgage insurance of 0.7 percent of the loan a year, plus property taxes equal to 25 percent of principal and interest. These assumptions are the same in every year.
- **Tenure subgroups**: `Owner` compares owner-occupied and for-sale vacant units with owner households at or below the threshold; `Renter` compares renter-occupied and for-rent vacant units with renter households at or below the threshold.
- **Geography**: the ACS identifies Public Use Microdata Areas (PUMAs), not counties or places. Each occupied unit is assigned to every county or place its PUMA overlaps, with its household weight multiplied by the allocation factor (`afact`), the share of the PUMA's population in that county or place. Vacant units are matched to counties and places through their PUMA with the same crosswalk. Years through 2021 use 2010 PUMAs and 2022–2024 use 2020 PUMAs.
- **Income limits by geography**: HUD publishes limits mostly by county; where limits are by town (New England), they are averaged within each county, and from 2022 Connecticut towns are grouped into the nine planning regions. Valdez-Cordova, AK, limits are applied to Chugach and Copper River after 2019. A place's limit is the population-weighted average of the limits of the counties it overlaps, from GeoCorr county-to-place crosswalks.
- **Small samples**: a cell is reported as missing when fewer than 30 sampled households at or below the threshold, in that tenure group, are allocated to the geography (household records summed with `afact`, not the survey weight).
- **No confidence intervals**: the ACS replicate weights aren't used, so values have no confidence intervals.

## Data quality flag
- A cell is suppressed (`NA`) when the count of sampled households below that threshold, for that tenure group and weighted only by `afact`, is under 30 (lines 1176 and 1278). The same count is used for the affordable and the affordable and available ratios, so their missing values are identical.
- Otherwise the flag is the mean `geographic_allocation_quality` of the PUMAs mapped to the geography (line 428). From `geographic-crosswalks/generate_puma_*_crosswalks.qmd`:
  - `1`: the sum over PUMAs of (share of the PUMA in the geography × share of the geography in the PUMA) is 0.75 or more
  - `2`: 0.35 to 0.75
  - `3`: below 0.35
- The flag reflects PUMA fit only; small samples are suppressed instead of flagged. Within a row, all six quality columns have the same value.
- County, `All`, 80 percent AMI: 5,665 rows are `1`, 4,528 are `2`, 12,748 are `3` (56 percent of nonmissing), and 8,492 are missing.
- Place, `All`, 80 percent AMI: 1,424 are `1`, 2,529 are `2`, 896 are `3`, and 4 are missing. Places flagged `3` drop from 125 a year (2014–2021) to 7 a year (2022–2024), when the 2020 PUMAs start.

## Missing values
Rows: counties have 3,143 rows a year through 2021 and 3,144 from 2022 (nine Connecticut planning regions instead of eight counties), matching `county-populations.csv` except in Alaska and South Dakota:
- 2014–2019 have Chugach (02063) and Copper River (02066) instead of Valdez-Cordova (02261). A code comment says this is for continuity (line 1503).
- 2014 has Kusilvak (02158) and Oglala Lakota (46102) instead of the older codes 02270 and 46113.

Places have 485 rows a year through 2021 and 486 from 2022: South Fulton, GA isn't in the place list for 2014–2017 and is dropped for 2018–2021.

Counties missing a value, per year (out of 3,143–3,144; the affordable and available ratios have the same counts):

| Subgroup | 30 percent AMI | 50 percent AMI | 80 percent AMI |
|---|---|---|---|
| All | 1,511–1,592 | 1,237–1,377 | 804–890 |
| Owner | 1,971–2,146 | 1,645–1,871 | 1,125–1,323 |
| Renter | 2,335–2,435 | 2,195–2,264 | 1,909–1,968 |

- 741 counties are missing the `All` 80 percent AMI ratio every year. In 2024, the states with the highest share of counties missing it are South Dakota (76 percent), North Dakota (75 percent), Nebraska (72 percent), Montana (66 percent), Alaska (60 percent), and Kansas (59 percent).
- Chugach and Copper River, AK (02063, 02066): every year. Kusilvak, AK (02158): 2014–2021. Oglala Lakota, SD (46102): 2014–2017.

Places missing a value, per year (out of 485–486):
- `All`: 28–45 at 30 percent AMI, 2–12 at 50 percent, 0–1 at 80 percent.
- `Owner`: 168–239 at 30 percent, 30–93 at 50 percent, 0–6 at 80 percent.
- `Renter`: 146–169 at 30 percent, 62–84 at 50 percent, 19–34 at 80 percent.
- Four large places are missing every value, for every subgroup, in one year: Quincy, MA (2019), Simi Valley, CA (2022), Bellflower, CA (2023), and Norwalk, CA (2024).

## Comparability across years
- PUMAs change in 2022: 2010 PUMAs through 2021 and 2020 PUMAs from 2022. Place quality flags shift with them (places flagged `3` drop from 125 to 7).
- No 2020 estimates, because of the quality of the 2020 ACS 1-year data (comment at line 751).
- Connecticut has eight counties through 2021 and nine planning regions from 2022, so Connecticut county values can't be compared across 2021 and 2022.
- For-sale vacant unit costs use the same mortgage assumptions every year (0.5 percent monthly interest, 10 percent down, 0.7 percent mortgage insurance, taxes at 25 percent of principal and interest), so changes in actual mortgage rates aren't reflected.
