library(tidyverse)


source("functions/construction/test_input_data.R")

# Income metric

read_csv("01_financial-well-being/final/metrics_income_place_all_longitudinal.csv") |>
  test_input_data(geography = "place")

read_csv("01_financial-well-being/final/metrics_income_place_race-ethnicity_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"))

read_csv("01_financial-well-being/final/metrics_income_county_all_longitudinal.csv") |>
  test_input_data()

read_csv("01_financial-well-being/final/metrics_income_county_race-ethnicity_longitudinal.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                "White, Non-Hispanic"))


# Homelessness

read_csv("02_housing/data/final/homelessness_2020_21_city.csv") |>
  test_input_data(geography = "place")

read_csv("02_housing/data/final/homelessness_all_subgroups_city.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"))

read_csv("02_housing/data/final/homelessness_2020_21_county.csv") |>
  test_input_data()

read_csv("02_housing/data/final/homelessness_all_subgroups_county.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                "White, Non-Hispanic"))


# Poverty Exposure

read_csv("06_neighborhoods/poverty-exposure/poverty-exposure_city_2021.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("06_neighborhoods/poverty-exposure/poverty-exposure_race-ethnicity_city_2021.csv") |>
  test_input_data(geography = "place", subgroups = c("Black", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"),
                  confidence_intervals = FALSE)

read_csv("06_neighborhoods/poverty-exposure/poverty-exposure_county_2021.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("06_neighborhoods/poverty-exposure/poverty-exposure_race-ethnicity_county_2021.csv") |>
  test_input_data(subgroups = c("Black", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"),
                  confidence_intervals = FALSE)

# Membership associations

read_csv("06_neighborhoods/social-capital/final/social_associations_all_city.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("06_neighborhoods/social-capital/final/social_associations_all_county.csv") |>
  test_input_data(confidence_intervals = FALSE)


# Economic connectedness 

read_csv("06_neighborhoods/social-capital/final/economic_connectedness_city_2022.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("06_neighborhoods/social-capital/final/economic_connectedness_county_2022.csv") |>
  test_input_data(confidence_intervals = FALSE)


# Preschool metric

read_csv("08_education/data/final/metrics_preschool_place_all_longitudinal.csv") |>
  test_input_data(geography = "place")

read_csv("08_education/data/final/metrics_preschool_place_race-ethnicity_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"))

read_csv("08_education/data/final/metrics_college_place_disability_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("with disability", "without disability"))

read_csv("08_education/data/final/metrics_college_place_gender_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Female", "Male"))

read_csv("08_education/data/final/metrics_preschool_county_all_longitudinal.csv") |>
  test_input_data()

read_csv("08_education/data/final/metrics_preschool_county_race-ethnicity_longitudinal.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                "White, Non-Hispanic"))

read_csv("08_education/data/final/metrics_college_county_disability_longitudinal.csv") |>
  test_input_data(subgroups = c("with disability", "without disability"))

read_csv("08_education/data/final/metrics_college_county_gender_longitudinal.csv") |>
  test_input_data(subgroups = c("Female", "Male"))


# SEDA

read_csv("08_education/SEDA_all_metro.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("08_education/SEDA_all_subgroups_metro.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Economically Disadvantaged", 
                                                     "Female", "Hispanic", "Male",
                                                     "Not Economically Disadvantaged",
                                                     "White, Non-Hispanic"), 
                  confidence_intervals = FALSE)

read_csv("08_education/SEDA_all_county.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("08_education/SEDA_all_subgroups_county.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Economically Disadvantaged", 
                                "Female", "Hispanic", "Male",
                                "Not Economically Disadvantaged",
                                "White, Non-Hispanic"), 
                  confidence_intervals = FALSE)


# MEPs

read_csv("08_education/data/final_data/meps_city_2020.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("08_education/data/final_data/meps_county_2020.csv") |>
  test_input_data(confidence_intervals = FALSE)


# College

read_csv("08_education/data/final/metrics_college_place_all_longitudinal.csv") |>
  test_input_data(geography = "place")

read_csv("08_education/data/final/metrics_college_place_race-ethnicity_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"))

read_csv("08_education/data/final/metrics_college_place_disability_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("with disability", "without disability"))

read_csv("08_education/data/final/metrics_college_place_gender_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Female", "Male"))

read_csv("08_education/data/final/metrics_college_county_all_longitudinal.csv") |>
  test_input_data()

read_csv("08_education/data/final/metrics_college_county_race-ethnicity_longitudinal.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                "White, Non-Hispanic"))

read_csv("08_education/data/final/metrics_college_county_disability_longitudinal.csv") |>
  test_input_data(subgroups = c("with disability", "without disability"))

read_csv("08_education/data/final/metrics_college_county_gender_longitudinal.csv") |>
  test_input_data(subgroups = c("Female", "Male"))

# Digital access

read_csv("08_education/final/digital_access_city_all.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("08_education/final/digital_access_city_subgroup_all.csv") |>
  test_input_data(geography = "place", subgroups = c("$50,000 or More",
                                                     "Black", "Hispanic", "Less than $50,000",
                                                     "Other Races and Ethnicities",
                                                     "White"), 
                  confidence_intervals = FALSE)

read_csv("08_education/final/digital_access_county_all.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("08_education/final/digital_access_county_subgroup_all.csv") |>
  test_input_data(subgroups = c("$50,000 or More",
                                "Black", "Hispanic", "Less than $50,000",
                                "Other Races and Ethnicities",
                                "White"), 
                  confidence_intervals = FALSE)


# Employment

read_csv("09_employment/data/final/metrics_employment_place_all_longitudinal.csv") |>
  test_input_data(geography = "place")

read_csv("09_employment/data/final/metrics_employment_place_race-ethnicity_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                     "White, Non-Hispanic"))

read_csv("09_employment/data/final/metrics_employment_place_disability_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("with disability", "without disability"))

read_csv("09_employment/data/final/metrics_employment_place_gender_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Female", "Male"))

read_csv("09_employment/data/final/metrics_employment_county_all_longitudinal.csv") |>
  test_input_data()

read_csv("09_employment/data/final/metrics_employment_county_race-ethnicity_longitudinal.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                "White, Non-Hispanic"))

read_csv("09_employment/data/final/metrics_employment_county_disability_longitudinal.csv") |>
  test_input_data(subgroups = c("with disability", "without disability"))

read_csv("09_employment/data/final/metrics_employment_county_gender_longitudinal.csv") |>
  test_input_data(subgroups = c("Female", "Male"))

# Living wage

read_csv("09_employment/metrics_wage_ratio_2022.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("09_employment/metrics_wage_ratio_2022_subgroup.csv") |>
  test_input_data(confidence_intervals = FALSE, subgroups = c("Goods Producing", "Public Administration",
                                                              "Trade, Transit, Utilities", "Information Services",
                                                              "Professional Services", "Education and Health", 
                                                              "Leisure and Other"))

# House Value

read_csv("01_financial-well-being/final/households_house_value_race_ethnicity_all_city.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("01_financial-well-being/final/households_house_value_race_ethnicity_subgroup_city.csv") |>
  test_input_data(geography = "place", subgroups = c("Age 45 and Over", "Under Age 45"), 
                  confidence_intervals = FALSE)

read_csv("01_financial-well-being/final/households_house_value_race_ethnicity_all_county.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("01_financial-well-being/final/households_house_value_race_ethnicity_subgroup_county.csv") |>
  test_input_data(subgroups = c("Age 45 and Over", "Under Age 45"), 
                  confidence_intervals = FALSE)

# Primary care physician

read_csv("04_health/access-health-services/final/ratio_pop_pcp_metric_all_county.csv") |>
  test_input_data(confidence_intervals = FALSE)

# Primary care physician

read_csv("04_health/access-health-services/final/ratio_pop_pcp_metric_all_county.csv") |>
  test_input_data(confidence_intervals = FALSE)

# Neonatal Health

read_csv("04_health/data/final_data/neonatal_health_2022.csv") |>
  test_input_data()

read_csv("04_health/data/final_data/neonatal_health_subgroup_2022.csv") |>
  test_input_data(subgroups = c("Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities",
                                                              "White, Non-Hispanic",
                                                              "Less than High School", "GED/High School Degree",
                                                              "Some College", "College Degree or Higher"))

# Air quality 

read_csv("06_neighborhoods/environment/data/final/environment_place_longitudinal.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("06_neighborhoods/environment/data/final/environment_place_race_poverty_longitudinal.csv") |>
  test_input_data(geography = "place", subgroups = c("Majority Non-White", 
                                                     "Majority White, Non-Hispanic",
                                                     "No Majority Race/Ethnicity",
                                                     "Extreme Poverty", "Not Extreme Poverty"),
                  confidence_intervals = FALSE)

read_csv("06_neighborhoods/environment/data/final/environment_county_longitudinal.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("06_neighborhoods/environment/data/final/environment_county_race_poverty_longitudinal.csv") |>
  test_input_data(subgroups = c("Majority Non-White", 
                                                     "Majority White, Non-Hispanic",
                                                     "No Majority Race/Ethnicity",
                                                     "Extreme Poverty", "Not Extreme Poverty"),
                  confidence_intervals = FALSE)


# Descriptive representation 

read_csv("05_local-governance/descriptive-representation/data/final/descriptive_rep_denominator_city_2021.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("05_local-governance/descriptive-representation/data/final/descriptive_rep_denominator_county_2021.csv") |>
  test_input_data(confidence_intervals = FALSE)

# Crime rate

read_csv("07_safety/final/rates_crime_place_all.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("07_safety/final/rates_crime_county_all.csv") |>
  test_input_data(confidence_intervals = FALSE)

# Rates arrest

read_csv("07_safety/final/rate_arrests_place_all.csv") |>
  test_input_data(geography = "place", confidence_intervals = FALSE)

read_csv("07_safety/final/rate_arrests_place_all_subgroup.csv") |>
  test_input_data(geography = "place", subgroups = c("1014", "1517",
                                                     "asian_other", "black",
                                                     "female", "hispanic", "male", "white"),
                  confidence_intervals = FALSE)

read_csv("07_safety/final/rate_arrests_county_all.csv") |>
  test_input_data(confidence_intervals = FALSE)

read_csv("07_safety/final/rate_arrests_county_all_subgroup.csv") |>
  test_input_data(subgroups = c("1014", "1517",
                                "asian_other", "black",
                                "female", "hispanic", "male", "white"),
                  confidence_intervals = FALSE)

