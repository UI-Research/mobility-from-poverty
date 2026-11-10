---
metric: Social capital (membership associations per 10,000 people; economic connectedness)
predictor: 15_social-capital
pillar: Opportunity-Rich and Inclusive Neighborhoods
metric_lead: [Manuel Alcalá Kovalski, Ridhi Purohit, Tina Chelidze]
variables: [count_membership_associations_per_10k, count_membership_associations_per_10k_quality, share_economic_connectedness, share_economic_connectedness_lb, share_economic_connectedness_ub, share_economic_connectedness_quality]
geographies:
  county: 2014-2023 (associations), 2022 (economic connectedness)
  place: 2014-2023 (associations), 2022 (economic connectedness)
subgroups: []
confidence_intervals: true
code:
  - social_associations_county.qmd
  - social_associations_city.qmd
  - economic_connectedness_county_2022.qmd
  - economic_connectedness_city_2022.qmd
final_files:
  - final/social_associations_all_county.csv
  - final/social_associations_all_city.csv
  - final/economic_connectedness_version2025_county_2022.csv
  - final/economic_connectedness_version2025_place_2022.csv
sources:
  - name: County Business Patterns (CBP) and ZIP Code Business Patterns (ZBP), establishment counts
    provider: US Census Bureau
    vintage: 2014-2023
    access: API (censusapi::getCensus(), needs a Census API key)
    url: https://www.census.gov/data/developers/data-sets/cbp-zbp/cbp-api.html
  - name: Social Capital Atlas, county and ZIP code files
    provider: Opportunity Insights and Meta
    vintage: 2022 release
    access: downloaded in code
    url: https://data.humdata.org/dataset/social-capital-atlas
crosswalks:
  - geographic-crosswalks/data/county-populations.csv
  - geographic-crosswalks/data/place-populations.csv
  - geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv
last_updated:
  date: 2026-11-09
  by: Manu Alcalá
---

## Summary
Two metrics.

- **Membership associations**: number of establishments in 10 membership-association industries (the North American Industry Classification System, or NAICS, codes used by [County Health Rankings](https://www.countyhealthrankings.org/health-data/community-conditions/social-and-economic-factors/safety-and-social-support/social-associations?year=2025): religious, civic, social, business, political, professional, and labor organizations, plus fitness, golf, bowling, and sports clubs) per 10,000 people, from County Business Patterns (CBP).
- **Economic connectedness**: the share of friends of people with below-median socioeconomic status (SES) who have above-median SES, from the Social Capital Atlas (Chetty et al. 2022, built from Facebook friendships). The atlas publishes this as a ratio to 50 percent; the code multiplies it by 0.5 to get the share, so 0.5 means a fully integrated community. One year only, labeled 2022.

## Process
Membership associations:

1. Add a Census API key. Both .qmd files source `15_social-capital/R/census_api_key.R`, which isn't in the repo (there's no `R/` folder in this predictor; see Open questions).
2. **County**: render `social_associations_county.qmd`. For 2014–2023, it pulls county establishment counts (`ESTAB`) from the `cbp` API, using `NAICS2012` codes for 2014–2016 and `NAICS2017` codes from 2017. Each year is cached in `data/cbp_county_{year}.csv` and only fetched if that file doesn't exist.
3. Keep the 10 NAICS codes (813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920) and sum establishments by county.
4. `left_join()` onto `county-populations.csv` (the denominator is its `population`, not an ACS pull, despite the section title), then `count_orgs / (population / 10,000)`, rounded to one decimal as County Health Rankings does.
5. **City**: render `social_associations_city.qmd`. It pulls ZIP code establishment counts from the `zbp` API for 2014–2018 and the `cbp` API (`zipcode:*`) for 2019–2023, with the same NAICS codes, cached in `data/cbp_zcta_{year}.csv`.
6. Join to two GeoCorr ZIP Code Tabulation Area (ZCTA) to place crosswalks read from `15_social-capital/data/` (`2020_ZCTA_2021_Census_Places_Crosswalk.csv` and `2010_ZCTA_2010_Census_Places_Crosswalk.csv`). These aren't in the repo, since `data/` is gitignored; the .qmd describes how to download them from GeoCorr 2022. The two are stacked with `bind_rows()` and joined on `zcta_code` only.
7. Multiply each ZIP code's count by its ZCTA-to-place allocation factor and sum by place. Drop the one unmatched row per year, `left_join()` onto `place-populations.csv`, and divide by `population / 10,000`.
8. Each .qmd ends with `evaluate_final_data()` against `evaluation_form_social_cap1_overall_{county,place}.csv` in `99a_final-evaluation/` and writes `final/social_associations_all_{county,city}.csv`.

Economic connectedness:

1. **County**: render `economic_connectedness_county_2022.qmd`. It downloads `social_capital_county.csv` from the Humanitarian Data Exchange to `temp/`, keeps `ec_county` and `ec_se_county`, and drops the 71 counties with no value.
2. `left_join()` the 2020 rows of `county-populations.csv` (3,143 counties) to the atlas data and set `year = 2022`.
3. `share_economic_connectedness = ec_county * 0.5`. The standard error is also halved, and the 95 percent bounds are the share ± `qnorm(0.975)` × the halved standard error.
4. **City**: render `economic_connectedness_city_2022.qmd`. It downloads `social_capital_zip.csv` (keyed by 2010 ZCTA, per the [working paper](https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf)) and drops the 4,048 ZIP codes with no value.
5. Join to `geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv` by state and ZIP code. Each place's value is the mean of its ZIP codes' `ec_zip`, weighted by `ZCTAinPlace` (the share of the ZCTA's area inside the place), then multiplied by 0.5.
6. `left_join()` onto the 2020 rows of `place-populations.csv` (486 places). No confidence intervals for cities.
7. Each .qmd runs `evaluate_final_data()` against `evaluation_form_social_cap2_overall_{county,place}.csv` and writes `final/economic_connectedness_version2025_{county,place}_2022.csv`.

## Data quality flag
Membership associations:

- **County**: `1` whenever there's a value, `NA` otherwise. 30,322 rows are `1` and 1,104 are `NA`.
- **City**: based on how well ZCTAs fit the place, using the same rule as `geographic-crosswalks/generate_puma_county_crosswalks.qmd`. For each place, `sum_products` is the sum over ZCTAs of (share of the ZCTA in the place × share of the place in the ZCTA). `1`: 0.75 or more; `2`: 0.35 to 0.75; `3`: below 0.35. 4,850 rows are `1` and 6 are `2` (South Fulton, GA, 2018–2023); none are `3`. See Known issues for why almost every place is `1`.

Economic connectedness:

- **County**: `1` whenever there's a value, `NA` otherwise. 3,017 are `1` and 126 are `NA`.
- **City**: based on `zip_ratio`, the number of ZCTAs entirely inside the place divided by the number of ZCTAs linked to it. `1`: 0.5 or more; `2`: above 0.15 and below 0.5; `3`: below 0.15. 13 places are `1`, 108 are `2`, 364 are `3` (75 percent), and 1 is `NA`.

## Missing values
Membership associations, county file (3,142 rows a year in 2014–2019, 3,143 in 2020–2021, and 3,144 in 2022–2023):

- Missing per year: 23–25 in 2014–2016 and 138–156 from 2017 on. A county with none of the 10 industries published is `NA`, never 0.
- 22 counties are missing every year: Hoonah-Angoon, AK (02105); Kalawao, HI (15005); Clark, ID (16033); Garfield, Golden Valley, Petroleum, and Treasure, MT (30033, 30037, 30069, 30103); Arthur, Blaine, Loup, and McPherson, NE (31005, 31009, 31115, 31117); Esmeralda and Eureka, NV (32009, 32011); Wheeler, OR (41069); Mellette, SD (46095); Borden, Kenedy, King, Loving, and Terrell, TX (48033, 48261, 48269, 48301, 48443); and Daggett and Garfield, UT (49009, 49017).
- Chugach and Copper River, AK (02063, 02066): 2020–2021. They have values from 2022.
- In 2023, the states with the most missing counties are Texas (22), Nebraska (15), Montana (13), Utah (12), and Alaska (12).

Membership associations, city file: no missing values (485 places a year in 2014–2017 and 486 from 2018).

Economic connectedness:

- County: 126 of 3,143 missing. These are mostly small counties (median population 1,662; largest 45,593), concentrated in Texas (23), Virginia (21), Nebraska (15), Georgia (11), and Montana (11). Chugach and Copper River, AK (02063, 02066) are missing because the atlas reports the former Valdez-Cordova (02261), which the code drops on purpose (the .qmd explains why).
- City: none missing (486 places).

## Known issues
- **City membership association values are about double the county values.** The two ZCTA-to-place crosswalks (2010 and 2020) are stacked and joined to every year on `zcta_code` alone (`bind_rows(zcta_20_place_21_xwalk, zcta_10_place_10_xwalk)` and `left_join(zcta_place_xwalk, by = c("zcta_code"))` in `social_associations_city.qmd`), so a ZIP code in both crosswalks is counted through each. Data check where the place matches its county or counties: the city value divided by the population-weighted county value is 1.93–1.96 in 2014–2016 and 1.68–1.79 from 2017 for New York City, Baltimore, and St. Louis, and about 2 for San Francisco, Philadelphia, Denver, and DC.
- The city quality flag has the same problem. `sum_products` is summed over both crosswalks for each place, so it's roughly doubled, which is why no place is ever `3` (`crosswalk_data_quality` chunk in `social_associations_city.qmd`).
- The city crosswalks are read from `15_social-capital/data/`, which is gitignored (`15_social-capital/.gitignore` has `data/`), so the city membership associations can't be rerun from the repo alone.
- **Small industries drop out from 2017.** Beginning with reference year 2017, CBP only publishes a cell with three or more establishments; before that, establishment counts were published even when other fields were suppressed ([CBP methodology](https://www.census.gov/programs-surveys/cbp/technical-documentation/methodology.html)). A county or ZIP code with one or two establishments in one of the 10 codes now counts 0 for that code. The county mean falls from 13.9 in 2016 to 12.2 in 2017, and missing counties rise from 25 to 141 (data check; the .qmd notes the same).
- Membership association outliers (data check): the highest county values are 70.6 (Hooker County, NE, 31091, 2016) and 65.1 (Comanche County, KS, 20033, 2015). In cities, Provo, UT (4962470) is 0.0 in 2022 and 0.5–0.7 in 2019–2021 and 2023, while Utah County is 1.7–2.0; DC is the highest city every year (54–56).
- **Economic connectedness city quality depends on how ZCTAs are counted.** `zip_total` counts every ZCTA linked to the place, including ones whose `ZCTAinPlace` rounds to 0.000: 1,021 of the 6,780 ZCTA-place rows for the 486 places (data check on `2010_ZCTA_2021_Census_Places_Crosswalk.csv`). The median place has no ZCTA entirely inside it, so most places are `3`.
- A `zip_ratio` of exactly 0.15 gets no flag, because the `case_when()` uses `> 0.15` for `2` and `< 0.15` for `3`. Overland Park, KS (2053775) has 3 of 20 ZCTAs inside (0.15) and is `NA` (recomputed from the atlas ZIP file and the crosswalk; the recomputed place values match the final file).
- The economic connectedness ZIP code file is joined to the crosswalk by state and ZIP code, where the ZIP code's state comes from its county in the atlas. 877 crosswalk rows have a ZIP code with an atlas value in a different state (for example, ZIP code 35586 in Alabama and Mississippi), and those place pairs are dropped (data check).
- City economic connectedness is weighted by the share of each ZCTA's land area in the place (`ZCTAinPlace` = `IntersectArea / ZCTAarea` in the crosswalk), not by population.

## Comparability across years
- Membership associations: 2014–2016 and 2017–2023 aren't comparable because of the 2017 CBP publication change (see Known issues). The NAICS vintage also changes from 2012 to 2017 in 2017; the .qmd says the 10 codes mean the same thing in both.
- City membership associations come from ZBP for 2014–2018 and CBP ZIP code data for 2019–2023.
- Connecticut: the county file has the 8 old counties through 2021 and the 9 planning regions in 2022–2023, all with values.
- Economic connectedness is a single cross-section (2022 release), so there's no change over time to compare.

## Open questions
- Should `social_associations_city.qmd` use one ZCTA crosswalk per year (2010 ZCTAs for earlier years, 2020 ZCTAs for later ones) instead of both? That would also fix the city quality flag.
- Where are the two ZCTA crosswalks in `15_social-capital/data/`? Should they move to `geographic-crosswalks/data/`?
- Both membership association .qmd files source `15_social-capital/R/census_api_key.R` and tell you to edit `census_api_key-template.R`, but neither file nor the `R/` folder exists here, and the root `.gitignore` doesn't cover a key at that path. Should this predictor get the template and a `.gitignore` entry, as 13 and 14 have?
- The economic connectedness city .qmd text describes the quality flag as the share of ZIP codes that fall "fully (>50%)" in the place, but the code uses ZCTAs entirely inside the place (`ZCTAinPlace == 1`).
- The economic connectedness .qmd files say they were first written as `economic_connectedness_county_code_2022.R` and `economic_connectedness_city_code_2022.R`; neither is in the folder. Should the references go?
- The county membership association .qmd has a heading "Download population data from ACS (denominator)", but it reads `county-populations.csv`.
- The rendered `.html` files for all four .qmd files (1.3–1.6 MB each) are committed. Are they still needed?
