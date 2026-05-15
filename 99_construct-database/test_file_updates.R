library(tidyverse)


source("functions/construction/evaluate_input_data.R")
source("functions/construction/test_input_data.R")

# 06 neighborhoods

## Housing Affordability 

read_csv("11_housing-affordability/data/available_2022_county.csv") |>
  evaluate_input_data(geography = "county", confidence_intervals = FALSE)

read_csv("11_housing-affordability/data/available_2022_subgroups_county.csv") |>
  evaluate_input_data(geography = "county", confidence_intervals = FALSE, 
                      subgroups = c("Renter", "Owner"))

read_csv("11_housing-affordability/data/available_2022_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("11_housing-affordability/data/available_2022_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE, 
                      subgroups = c("Renter", "Owner"))

read_csv("11_housing-affordability/data/housing_2022_county.csv") |>
  evaluate_input_data(geography = "county", confidence_intervals = FALSE)

read_csv("11_housing-affordability/data/housing_2022_subgroups_county.csv") |>
  evaluate_input_data(geography = "county", confidence_intervals = FALSE, 
                      subgroups = c("Renter", "Owner"))

read_csv("11_housing-affordability/data/housing_2022_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("11_housing-affordability/data/housing_2022_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE, 
                      subgroups = c("Renter", "Owner"))

## Homelessness

read_csv("12_housing-stability/data/final/homelessness_2020_21_city.csv") |>
  evaluate_input_data(geography = "place")

read_csv("12_housing-stability/data/final/homelessness_all_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("12_housing-stability/data/final/homelessness_2020_21_county.csv") |>
  evaluate_input_data()

read_csv("12_housing-stability/data/final/homelessness_all_subgroups_county.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))

#These files were deleted inadvertantly in a pull request - must be replaced 
#read_csv("12_housing-stability/homelessness_all_county.csv") |>
#evaluate_input_data(geography = "place")

#read_csv("12_housing-stability/homelessness_all_county.csv") |>
#evaluate_input_data()


## Poverty Exposure

read_csv("13_economic-inclusion/poverty-exposure_city_2021.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("13_economic-inclusion/poverty-exposure_race-ethnicity_city_2021.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"),
                      confidence_intervals = FALSE)

read_csv("13_economic-inclusion/poverty-exposure_county_2021.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("13_economic-inclusion/poverty-exposure_race-ethnicity_county_2021.csv") |>
  evaluate_input_data(subgroups = c("Black", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"),
                      confidence_intervals = FALSE)


read_csv("13_economic-inclusion/poverty-exposure_county_2018.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("13_economic-inclusion/poverty-exposure_race-ethnicity_county_2018.csv") |>
  evaluate_input_data(subgroups = c("Black", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"),
                      confidence_intervals = FALSE)

## Racial diversity 

read_csv("14_racial-diversity/race-ethnicity-exposure-city-2021.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("14_racial-diversity/race-ethnicity-exposure-2018.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("14_racial-diversity/race-ethnicity-exposure-2021.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Membership associations

read_csv("15_social-capital/final/social_associations_all_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("15_social-capital/final/social_associations_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Economic connectedness 

read_csv("15_social-capital/final/economic_connectedness_city_2022.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("15_social-capital/final/economic_connectedness_county_2022.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Transportation

read_csv("16_transportation-access/final/transit_cost_all_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("16_transportation-access/final/transit_trips_all_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("16_transportation-access/final/transit_cost_all_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE, 
                      subgroups = c("Majority White-NH Tracts", 
                                    "Majority Non-White Tracts", 
                                    "Mixed Race and Ethnicity Tracts"))

read_csv("16_transportation-access/final/transit_trips_all_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE, 
                      subgroups = c("Majority White-NH Tracts", 
                                    "Majority Non-White Tracts", 
                                    "Mixed Race and Ethnicity Tracts"))

read_csv("16_transportation-access/final/transit_cost_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("16_transportation-access/final/transit_trips_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("16_transportation-access/final/transit_cost_all_subgroups_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE, 
                      subgroups = c("Majority White-NH Tracts", 
                                    "Majority Non-White Tracts", 
                                    "Mixed Race and Ethnicity Tracts"))

read_csv("16_transportation-access/final/transit_trips_all_subgroups_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE, 
                      subgroups = c("Majority White-NH Tracts", 
                                    "Majority Non-White Tracts", 
                                    "Mixed Race and Ethnicity Tracts"))


# Education

## Preschool

read_csv("06_access-to-preschool/data/final/metrics_preschool_place_all_longitudinal.csv") |>
  evaluate_input_data(geography = "place")

read_csv("06_access-to-preschool/data/final/metrics_preschool_place_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("06_access-to-preschool/data/final/metrics_preschool_county_all_longitudinal.csv") |>
  evaluate_input_data()

read_csv("06_access-to-preschool/data/final/metrics_preschool_county_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))


## Preschool

read_csv("06_access-to-preschool/data/final/metrics_preschool_place_all_longitudinal.csv") |>
  evaluate_input_data(geography = "place")

read_csv("06_access-to-preschool/data/final/metrics_preschool_place_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("06_access-to-preschool/data/final/metrics_preschool_county_all_longitudinal.csv") |>
  evaluate_input_data()

read_csv("06_access-to-preschool/data/final/metrics_preschool_county_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))

## SEDA

read_csv("07_effective-public-education-hold/data/built/SEDA_all_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("07_effective-public-education-hold/data/built/SEDA_all_subgroups_city.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Economically Disadvantaged", 
                                                         "Female", "Hispanic", "Male",
                                                         "Not Economically Disadvantaged",
                                                         "White, Non-Hispanic"), 
                      confidence_intervals = FALSE)

read_csv("07_effective-public-education-hold/data/built/SEDA_all_county_2014-2018.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("07_effective-public-education-hold/data/built/SEDA_all_subgroups_county_2014-2018.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Economically Disadvantaged", 
                                    "Female", "Hispanic", "Male",
                                    "Not Economically Disadvantaged",
                                    "White, Non-Hispanic"), 
                      confidence_intervals = FALSE)

## MEPs

read_csv("08_school-economic-diversity/data/final/meps_city_2020.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("08_school-economic-diversity/data/final/meps_county_2020.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## College

read_csv("09_preparation-for-college/data/final/metrics_college_place_all_longitudinal.csv") |>
  evaluate_input_data(geography = "place")

read_csv("09_preparation-for-college/data/final/metrics_college_place_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("09_preparation-for-college/data/final/metrics_college_place_disability_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("with disability", "without disability"))

read_csv("09_preparation-for-college/data/final/metrics_college_place_gender_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Female", "Male"))

read_csv("09_preparation-for-college/data/final/metrics_college_county_all_longitudinal.csv") |>
  evaluate_input_data()

read_csv("09_preparation-for-college/data/final/metrics_college_county_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))

read_csv("09_preparation-for-college/data/final/metrics_college_county_disability_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("with disability", "without disability"))

read_csv("09_preparation-for-college/data/final/metrics_college_county_gender_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Female", "Male"))


## Digital access

read_csv("10_digital-access/final/digital_access_city_all.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("10_digital-access/final/digital_access_city_subgroup_all.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("$50,000 or More",
                                                         "Black", "Hispanic", "Less than $50,000",
                                                         "Other Races and Ethnicities",
                                                         "White"), 
                      confidence_intervals = FALSE)

read_csv("10_digital-access/final/digital_access_county_all.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("10_digital-access/final/digital_access_county_subgroup_all.csv") |>
  evaluate_input_data(subgroups = c("$50,000 or More",
                                    "Black", "Hispanic", "Less than $50,000",
                                    "Other Races and Ethnicities",
                                    "White"), 
                      confidence_intervals = FALSE)

# Rewarding Work

## Employment

read_csv("01_employment-opportunities/data/final/metrics_employment_place_all_longitudinal.csv") |>
  evaluate_input_data(geography = "place")

read_csv("01_employment-opportunities/data/final/metrics_employment_place_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("01_employment-opportunities/data/final/metrics_employment_place_disability_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("with disability", "without disability"))

read_csv("01_employment-opportunities/data/final/metrics_employment_place_gender_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Female", "Male"))

read_csv("01_employment-opportunities/data/final/metrics_employment_county_all_longitudinal.csv") |>
  evaluate_input_data()

read_csv("01_employment-opportunities/data/final/metrics_employment_county_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))

read_csv("01_employment-opportunities/data/final/metrics_employment_county_disability_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("with disability", "without disability"))

read_csv("01_employment-opportunities/data/final/metrics_employment_county_gender_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Female", "Male"))

## Living wage

read_csv("01_employment-opportunities/metrics_wage_ratio_2022.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("01_employment-opportunities/metrics_wage_ratio_2022_subgroup.csv") |>
  evaluate_input_data(confidence_intervals = FALSE, subgroups = c("Goods Producing", "Public Administration",
                                                                  "Trade, Transit, Utilities", "Information Services",
                                                                  "Professional Services", "Education and Health", 
                                                                  "Leisure and Other"))

read_csv("01_employment-opportunities/metrics_wage_ratio_2021.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("01_employment-opportunities/metrics_wage_ratio_years_v2.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Income

read_csv("03_opportunities-for-income/final/metrics_income_place_all_longitudinal.csv") |>
  evaluate_input_data(geography = "place")

read_csv("03_opportunities-for-income/final/metrics_income_place_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                         "White, Non-Hispanic"))

read_csv("03_opportunities-for-income/final/metrics_income_county_all_longitudinal.csv") |>
  evaluate_input_data()

read_csv("03_opportunities-for-income/final/metrics_income_county_race-ethnicity_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))


## Debt in collections

read_csv("04_financial-security/final/metrics_overall_debt_coll_all_city.csv") |>
  evaluate_input_data(geography = "place_fips", subgroups = c("Majority White", "Majority Non-White"))

read_csv("04_financial-security/final/metrics_overall_debt_coll_all_county.csv") |>
  evaluate_input_data()

read_csv("04_financial-security/final/share_debt_2018_long.csv") |>
  evaluate_input_data(subgroups = c("Majority White", "Majority Non-White"))

read_csv("04_financial-security/final/metrics_overall_debt_coll_all_county.csv") |>
  evaluate_input_data()


## House Value

read_csv("05_wealth-building-opportunities/final/households_house_value_race_ethnicity_all_city.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("05_wealth-building-opportunities/final/households_house_value_race_ethnicity_subgroup_city.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Age 45 and Over", "Under Age 45"), 
                      confidence_intervals = FALSE)

read_csv("05_wealth-building-opportunities/final/households_house_value_race_ethnicity_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("05_wealth-building-opportunities/final/households_house_value_race_ethnicity_subgroup_county.csv") |>
  evaluate_input_data(subgroups = c("Age 45 and Over", "Under Age 45"), 
                      confidence_intervals = FALSE)

# Healthy Environment & Access to Good Healthcare

## Primary care physician

read_csv("17_access-to-health-services/final/ratio_pop_pcp_metric_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Neonatal Health

read_csv("18_neonatal-health/data/final/rate_low_birth_weight_metric_all_county.csv") |>
  evaluate_input_data()

read_csv("18_neonatal-health/data/final/rate_low_birth_weight_metric_subgroup_county.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic",
                                    "Less than High School", "GED/High School Degree",
                                    "Some College", "College Degree or Higher"))


read_csv("18_neonatal-health/data/final/rate_low_birth_weight_metric_subgroup_county.csv") |>
  evaluate_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                    "White, Non-Hispanic"))

## Air quality 

read_csv("19_environmental-quality/data/final/environment_place_longitudinal.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("19_environmental-quality/data/final/environment_place_race_poverty_longitudinal.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("Majority Non-White", 
                                                         "Majority White, Non-Hispanic",
                                                         "No Majority Race/Ethnicity",
                                                         "Extreme Poverty", "Not Extreme Poverty"),
                      confidence_intervals = FALSE)

read_csv("19_environmental-quality/data/final/environment_county_longitudinal.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("19_environmental-quality/data/final/environment_county_race_poverty_longitudinal.csv") |>
  evaluate_input_data(subgroups = c("Majority Non-White", 
                                    "Majority White, Non-Hispanic",
                                    "No Majority Race/Ethnicity",
                                    "Extreme Poverty", "Not Extreme Poverty"),
                      confidence_intervals = FALSE)

## Exposure to Trauma 

read_csv("20_safety-from-trauma/data/final/rate_injury_deaths_metric_all_county.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

# Responsible & Just Governance

## Political Participation

read_csv("21_political-participation/data/final/voter-turnout-city-2020.csv") |>
  evaluate_input_data(geography = "place", 
                      confidence_intervals = FALSE)

read_csv("21_political-participation/data/final/voter-turnout-2020.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("21_political-participation/data/final/voter-turnout-2016.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("21_political-participation/data/final/voter-turnout-2016-2024.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

## Descriptive representation 

read_csv("22_descriptive-representation/data/final/descriptive_rep_denominator_city_all.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("22_descriptive-representation/data/final/descriptive_rep_denominator_county_all.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

# Crime rate

read_csv("23_safety-from-crime/data/final/rates_crime_place_all.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("23_safety-from-crime/data/final/rates_crime_county_all.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

# Rates arrest

read_csv("24_just-policing/data/final/rate_arrests_place_all.csv") |>
  evaluate_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("24_just-policing/data/final/rate_arrests_place_all_subgroup.csv") |>
  evaluate_input_data(geography = "place", subgroups = c("1014", "1517",
                                                         "asian_other", "black",
                                                         "female", "hispanic", "male", "white"),
                      confidence_intervals = FALSE)

read_csv("24_just-policing/data/final/rate_arrests_county_all.csv") |>
  evaluate_input_data(confidence_intervals = FALSE)

read_csv("24_just-policing/data/final/rate_arrests_county_all_subgroup.csv") |>
  evaluate_input_data(subgroups = c("1014", "1517",
                                    "asian_other", "black",
                                    "female", "hispanic", "male", "white"),
                      confidence_intervals = FALSE)




