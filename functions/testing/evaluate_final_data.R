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
#   a series of test results that will throw an error if failed 

library(here)
library(tidyverse)

evaluate_final_data <- function(exp_form_path, data, 
                            geography, subgroups = FALSE, confidence_intervals = TRUE) {

#Read in the data expectation form
exp_form <- read_csv(here::here(exp_form_path),
                     skip = 2, locale=locale(encoding="latin1"),
                     show_col_types = FALSE) %>% 
  janitor::clean_names() %>% 
  filter(!is.na(metric_name_as_written_in_final_data_file), !str_detect(user_input, "Example")) 

#Pull information for variable check from expectation form
exp_form_variables <- exp_form %>% 
  select(user_input:quality_variables_available_yes_or_no) %>% 
  mutate(quality_title = ifelse(quality_variables_available_yes_or_no == "Yes", paste0(metric_name_as_written_in_final_data_file, "_", "quality"), NA_character_),
         ci_low_title = ifelse(confidence_intervals_yes_or_no == "Yes", paste0(metric_name_as_written_in_final_data_file, "_", "lb"), NA_character_),
         ci_high_title = ifelse(confidence_intervals_yes_or_no == "Yes", paste0(metric_name_as_written_in_final_data_file, "_", "ub"), NA_character_),
         metric_geography = geography,
         state = "state", 
         year = "year",
         subgroup = "subgroup",
         subgroup_type = "subgroup_type"
  )

#For final data with multiple values expand the form results 
if(exp_form_variables %>% nrow() > 1) {
  exp_form_variables <- exp_form_variables %>% 
    pivot_wider(names_from = user_input, values_from = c("metric_name_as_written_in_final_data_file", "quality_title", "ci_low_title", "ci_high_title"))
}


#Pull subgroup list from expectation form 

if (isTRUE(subgroups)) {
  
expected_subgroups <- exp_form %>% 
  pull(subgroup_values_include_all_and_use_no_space) %>% 
  strsplit(split = ";") %>% 
  .[[1]]
  
}

#Pull year list from expectation form
expected_years <- exp_form %>% 
  pull(all_years_use_no_space) %>% 
  strsplit(split = ";") %>% 
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
  stopifnot(sum(is.na(select(data, ends_with("_ub")))) == sum(is.na(select(data, ends_with("_quality")))))
  stopifnot(sum(is.na(select(data, ends_with("_ub")))) == sum(is.na(select(data, ends_with("_lb")))))
  
}

# check fips
if (geography == "county") {
  
  data_geoid <- data |>
    dplyr::mutate(geoid = paste0(state, county),
                  geoid_length = stringr::str_length(geoid)) 
  
}

if (geography == "place") {
  
  data_geoid <- data |>
    dplyr::mutate(geoid = paste0(state, place),
                  geoid_length = stringr::str_length(geoid))
  
}

# are there missing leading zeros?
stopifnot(length(unique(dplyr::pull(data_geoid, geoid_length))) == 1)

#Compare final data and exp_form variable titles

##Variable names
if (isTRUE(subgroups)) {
  exp_form_variables <- exp_form_variables %>%
    select(-all_years_use_no_space, 
           -confidence_intervals_yes_or_no, 
           -quality_variables_available_yes_or_no) %>% 
    pivot_longer(cols = everything()) %>%  
    pull(value) %>% 
    sort()
} else {
  exp_form_variables <- exp_form_variables %>%
    select(-all_years_use_no_space, 
           -confidence_intervals_yes_or_no, 
           -quality_variables_available_yes_or_no, 
           -subgroup_type, -subgroup) %>% 
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

