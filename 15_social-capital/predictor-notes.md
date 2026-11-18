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

## Methodology
Membership associations:

- **Numerator**: establishments (`ESTAB`) in the 10 North American Industry Classification System (NAICS) codes County Health Rankings uses (813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920). Codes come from NAICS 2012 for 2014–2016 and NAICS 2017 from 2017 on. The measure counts establishments, not members or participants.
- **Sources by geography**: counties use County Business Patterns (CBP) county counts. Cities use ZIP code counts, from ZIP Code Business Patterns (ZBP) for 2014–2018 and CBP ZIP code data for 2019–2023.
- **Denominator**: population from the project's county and place population files (Census Bureau Population Estimates Program and decennial census counts), for the same year. The rate is establishments / (population / 10,000), rounded to one decimal place as County Health Rankings does.
- **City allocation**: each ZIP code is treated as its ZIP Code Tabulation Area (ZCTA). Its establishment count is allocated to places with the GeoCorr ZCTA-to-place allocation factor, which is based on population, and summed by place.
- **Publication rules**: from reference year 2017, CBP publishes an industry cell only when it has three or more establishments ([CBP methodology](https://www.census.gov/programs-surveys/cbp/technical-documentation/methodology.html)), so a county or ZIP code with one or two establishments in a code counts 0 for that code from 2017 on. A county with no published establishments in any of the 10 codes is missing, not 0.

Economic connectedness:

- **Measure**: the Social Capital Atlas county and ZIP code economic connectedness (`ec_county`, `ec_zip`), which is twice the share of above-median-SES friends among people with below-median SES ([Chetty et al. 2022 working paper](https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf)). Values are multiplied by 0.5 to report the share itself. One cross-section, labeled `2022`.
- **County**: atlas values are used as published, matched to the 2020 county list. The atlas reports Valdez-Cordova, AK (02261), which split into Chugach and Copper River in 2019; that value is dropped rather than assigned to the new areas.
- **Confidence intervals (county)**: the atlas standard error (`ec_se_county`) is halved, and `share_economic_connectedness_lb` and `share_economic_connectedness_ub` are the share ± 1.96 × that standard error (95 percent). Cities have no bounds.
- **City**: the atlas ZIP codes are 2010 ZCTAs. Each place's value is the mean of its ZCTAs' values, weighted by `ZCTAinPlace`, the share of the ZCTA's area inside the place (2010-ZCTA-to-2021-place crosswalk). ZCTAs without an atlas value are left out of the mean.

## Data quality flag
Membership associations:

- **County**: `1` whenever there's a value, `NA` otherwise. 30,322 rows are `1` and 1,104 are `NA`.
- **City**: based on how well ZCTAs fit the place, using the same rule as `geographic-crosswalks/generate_puma_county_crosswalks.qmd`. For each place, `sum_products` is the sum over ZCTAs of (share of the ZCTA in the place × share of the place in the ZCTA). `1`: 0.75 or more; `2`: 0.35 to 0.75; `3`: below 0.35. 4,850 rows are `1` and 6 are `2` (South Fulton, GA, 2018–2023); none are `3`.

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

## Comparability across years
- Membership associations: 2014–2016 and 2017–2023 aren't comparable because of the 2017 CBP publication change (see Methodology). The NAICS vintage also changes from 2012 to 2017 in 2017; the .qmd says the 10 codes mean the same thing in both.
- City membership associations come from ZBP for 2014–2018 and CBP ZIP code data for 2019–2023.
- Connecticut: the county file has the 8 old counties through 2021 and the 9 planning regions in 2022–2023, all with values.
- Economic connectedness is a single cross-section (2022 release), so there's no change over time to compare.
