# Final data evaluation - test function
# Prior to running this function users should fill out the final data expectation CSV form located in the functions/testing folder 
# Users should create an expectation form for each final data file being created in their program 
# Every final data file created in a program should be put through this test function 
#
# Function call: evaluate_final_data
# Inputs:
#   exp_form_path (str): the file path (including csv name) to the expectation form for this data file
#   data (str): the data that is staged to be read out as the final file
#   geography (str): either "place" or "county" depending on the level of data being tested
#   subgroups (logical): a true or false value indicating if the final file has subgroups
#   confidence_intervals  (logical): a true or false value indicating if the final file has confidence intervals
# Returns:
#   a series of test results that will throw an error is failed 

library(here)
library(tidyverse)

evaluate_final_data <- function(exp_form_path, data, 
                            geography = "county", subgroups = FALSE, confidence_intervals = TRUE) {

#Read in the data expectation form
exp_form <- read_csv(here::here(exp_form_path),
                     col_names = FALSE, show_col_types = FALSE) %>% 
  filter(!is.na(X2), !str_detect(X1, "Example")) 

#Pull information for variable check from expectation form
exp_form_variables <- exp_form %>% 
  select(X1:X5) %>% 
  mutate(quality_title = ifelse(X5 == "Yes", paste0(X2, "_", "quality"), NA_character_),
         ci_low_title = ifelse(X4 == "Yes", paste0(X2, "_", "lb"), NA_character_),
         ci_high_title = ifelse(X4 == "Yes", paste0(X2, "_", "up"), NA_character_),
         metric_geography = geography,
         state = "state", 
         year = "year",
         subgroup = "subgroup",
         subgroup_type = "subgroup_type"
  )

#For final data with multiple values expand the form results 
if(exp_form_variables %>% 
   nrow() > 1) {
  
  exp_form_variables <- exp_form_variables %>% 
    pivot_wider(names_from = X1, values_from = c("X2", "quality_title", "ci_low_title", "ci_high_title"))
  
}

  
#Pull subgroup list from expectation form 

if (isTRUE(subgroups)) {
  
expected_subgroups <- exp_form %>% 
  pull(X7) %>% 
  strsplit(split = ";") %>% 
  .[[1]]
  
}

#Pull year list from expectation form
expected_years <- exp_form %>% 
  pull(X3) %>% 
  strsplit(split = ";") %>% 
  as.numeric() %>% 
  .[[1]]

# check that the file has the necessary columns
# check that the first few columns are year, state
data_names <- names(data)

stopifnot(data_names[1] == "year")
stopifnot(data_names[2] == "state")
stopifnot(data_names[3] == "county" | data_names[3] == "place")

if (isTRUE(subgroups)) {
  
  stopifnot(data_names[4] == "subgroup_type")
  stopifnot(data_names[5] == "subgroup")
  
}

#Check if confidence intervals and data quality NA values align 
if (isTRUE(confidence_intervals)) {
  
  stopifnot(sum(is.na(select(data, ends_with("_lb")))) == sum(is.na(select(data, ends_with("_quality")))))
  stopifnot(sum(is.na(select(data, ends_with("_up")))) == sum(is.na(select(data, ends_with("_quality")))))
  stopifnot(sum(is.na(select(data, ends_with("_up")))) == sum(is.na(select(data, ends_with("_lb")))))
  
}

# check fips
if (geography == "county") {
  
  data_geoid <- data |>
    dplyr::mutate(geoid = paste0(state, county)) |>
    dplyr::mutate(geo_id_length = stringr::str_length(geoid))
  
}

if (geography == "place") {
  
  data_geoid <- data |>
    dplyr::mutate(geoid = paste0(state, place)) |>
    dplyr::mutate(geo_id_length = stringr::str_length(geoid))
  
}

# are there missing leading zeros?
stopifnot(length(unique(dplyr::pull(data_geoid, geo_id_length))) == 1)

#Compare final data and exp_form variable titles

##Variable names
if (isTRUE(subgroups)) {
  exp_form_variables <- exp_form_variables %>%
    select(-X3, -X4, -X5) %>% 
    pivot_longer(cols = everything()) %>%  
    pull(value) %>% 
    sort()
} else {
  exp_form_variables <- exp_form_variables %>%
    select(-X3, -X4, -X5, -subgroup_type, -subgroup) %>% 
    pivot_longer(cols = everything()) %>%   
    pull(value) %>% 
    sort()
}

stopifnot(all(exp_form_variables == sort(colnames(data))))

##subgroup values
if (isTRUE(subgroups)) {
  
  created_subgroups <- sort(unique(dplyr::pull(data, subgroup)))
  
  stopifnot(all(created_subgroups == sort(expected_subgroups)))
  
}

##Years

stopifnot(all(sort(expected_years) == sort(unique(dplyr::pull(data, year)))))

print("This data passes all tests!")

}

