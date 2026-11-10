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

## Process
1. Set `geography` (`county` or `place`) and the years in the .qmd `params`, and render once per geography. The years must be 2014–2019 or 2021–2024 (`stopifnot()`, line 164).
2. **Optional AWS S3 cache**: if the `mobility-from-poverty-test` bucket is reachable, the IPUMS extracts, HUD income limits, and final files are read from and written to S3 (`housing-affordability/data/`). Without credentials, everything is downloaded and kept in `data/temp/`.
3. Pull two IPUMS USA extracts, each covering all missing years in one API call, from ACS 1-year samples (`us{year}a`): occupied housing (rectangular, all persons) and vacant units (hierarchical, `GQ == 0`). Files are split by year into `data/temp/`. The first pull takes about an hour.
4. Occupied units: join `crosswalk_puma_to_{geography}.csv` by state and Public Use Microdata Area (PUMA), filtered to the year's `crosswalk_period`. Multiply `HHWT` and `PERWT` by `afact`, and `HHINCOME`, `RENT`, `RENTGRS`, and `OWNCOST` by `ADJUST`. Recode IPUMS missing codes to `NA` (`OWNCOST == 99999`, `RENT`/`RENTGRS == 0`, `VALUEH == 9999999`). Keep one row per household (`PERNUM == 1`) and drop group quarters (`GQ < 3`).
5. Vacant units: keep `VACANCY` 1–3 (for rent, for sale, rented or sold but not occupied).
   - For sale: monthly cost = a 30-year mortgage on 90 percent of `VALUEH` at 0.5 percent monthly interest, plus private mortgage insurance of 0.7 percent of the loan a year, plus taxes equal to 25 percent of principal and interest (lines 634–643).
   - For rent: `RENTGRS = RENT ×` the `HHWT`-weighted mean of `RENTGRS / RENT` among occupied rentals in the same geography and year.
6. AMI thresholds: download the HUD Section 8 income limits for each fiscal year and use the four-person limits `eli_4`, `l50_4`, and `l80_4` as the 30, 50, and 80 percent thresholds.
   - Sub-county limits (New England) are averaged within each county.
   - From 2022, Connecticut towns are mapped to the nine planning regions with the CT Data Collaborative crosswalk.
   - Valdez-Cordova (02261) limits are copied to Chugach (02063) and Copper River (02066) for years after 2019.
   - Places: population-weighted mean of county limits, using a county-place crosswalk built in memory from the three GeoCorr county-place files (2014–2019, 2020–2021, and 2022 on; lines 931–987).
7. Indicators: a household is below a threshold if `HHINCOME` is at or below it. An occupied unit is affordable if 12 × `RENTGRS` (renters) or 12 × `OWNCOST` (owners) is at or below 30 percent of the threshold, and available if it's also occupied by a household below that threshold. Every affordable vacant unit counts as available.
8. Sum weighted counts by geography and year, then:
   - affordable ratio = (affordable occupied + affordable vacant) / households below the threshold
   - affordable and available ratio = (available occupied + affordable vacant) / households below the threshold
9. Suppress and flag (see Data quality flag), pivot to long by tenure (`All`, `Owner`, `Renter`), and drop South Fulton, GA (13 72122) for 2018–2021 because the 2010-based PUMA-to-place crosswalk predates it (line 1377). Write the all file (`All` rows only) and the subgroups file for the geography; the file name lists the years.
10. Checks: `evaluate_final_data()` against the two housing forms in `99a_final-evaluation/`, plus `test_that()` checks on geography counts, no ratios at or below 0, no state with only `NA` values, and available ratios never above affordable ratios. It also tests that every value matches the May 2025 Urban Data Catalog files within 1e-10 (line 1765), plots 2023 differences from those files, and plots county values against the National Low Income Housing Coalition (NLIHC) *The Gap* 2024 estimates.
11. Optional: `quality-checks/ratio_housing_affordable_available_comparison.qmd` plots the 2023 values from the previous release against the updated ones.

`23_safety-from-crime` and `24_just-policing` read `geographic-crosswalks/data/county_place_crosswalk_longitudinal.csv` (2021–2024 rows), which `geographic-crosswalks/generate_county_place_crosswalks.qmd` builds (#648). The same script writes `geocorr2022_county_place_2022_onwards.csv`, which this .qmd reads. This .qmd doesn't use that file; it builds its county-place crosswalk in memory.

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

## Known issues
- **Re-runs before 2022 match no PUMAs.** The code filters the PUMA crosswalk to `crosswalk_period == "pre-2022"` (line 401) and labels vacant units the same way (line 645). Since #606, `crosswalk_puma_to_county.csv` and `crosswalk_puma_to_place.csv` only have `2k`, `2012`, and `2022` (checked).
- **Vacant units aren't split across geographies.** Occupied units' weights are multiplied by `afact` (line 504), but vacant units are joined to the PUMA crosswalk (line 711) and summed with `HHWT` alone (line 1193). A vacant unit in a PUMA that spans several counties or places counts in full in each, which raises both ratios where PUMAs are split.
- Every household and unit is compared with the four-person limit; there's no adjustment for household size or number of bedrooms (`eli_4`, `l50_4`, `l80_4` at lines 816–818; the .qmd's Analysis notes say the same).
- The variables are named `share_` but are ratios and can be above 1. The code keeps the name for consistency with earlier releases (comment at line 1353).
- Long right tail: 2,277 county rows have at least one ratio above 3. The highest are 5.78 (`Owner`, 30 percent AMI, county 38015, 2019, quality `2`) and 4.95 for `All` at 80 percent AMI (county 20117, 2019, quality `3`). At the low end, four place `Renter` rows have an affordable and available 30 percent AMI ratio below 0.01 (lowest: 48 42508, 2015).
- Rendering edits committed files: before calling `evaluate_final_data()`, the code overwrites the year row of the two housing forms in `99a_final-evaluation/` with the years being run (lines 1440–1454).

## Comparability across years
- PUMAs change in 2022: 2010 PUMAs through 2021 and 2020 PUMAs from 2022. Place quality flags shift with them (places flagged `3` drop from 125 to 7).
- No 2020 estimates, because of the quality of the 2020 ACS 1-year data (comment at line 751).
- Connecticut has eight counties through 2021 and nine planning regions from 2022, so Connecticut county values can't be compared across 2021 and 2022.
- For-sale vacant unit costs use the same mortgage assumptions every year (0.5 percent monthly interest, 10 percent down, 0.7 percent mortgage insurance, taxes at 25 percent of principal and interest), so changes in actual mortgage rates aren't reflected.

## Open questions
- Why are Quincy, Simi Valley, Bellflower, and Norwalk missing every value in one year each? They're large places with values in the neighboring years.
- Chugach and Copper River are missing every year. Is that small samples, or a join problem with the Valdez-Cordova income limits?
- Should vacant unit weights be multiplied by `afact`, as occupied units' are?
- `quality-checks/ratio_housing_affordable_available_comparison.qmd` reads the previous release from a `main` URL that returns 404 (`data/final/housing_{geo}_2014_..._2023_subgroups.csv`). That file now lives in `quality-checks/quality-check-data/nobedadj_nohhsizeadj/`.
- The rendered `ratio_housing_affordable_available_county.html` and `ratio_housing_affordable_available_place.html` at the folder root were last changed in 8f8af851. Are they still needed next to `ratio_housing_affordable_available.html`?
