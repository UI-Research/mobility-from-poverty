###
# Code to pull HUD FMR data from API
# Implement into existing metrics code
###


# Load necessary libraries
library(httr)
library(jsonlite)
library(tidyverse)

# Set  API key as a global variable
# Get key here: https://www.huduser.gov/hudapi/public/home
api_key <- "KEY"  # Replace with your actual key

# Function to fetch county data for a single state with a specified year
fetch_state_county_data <- function(state_code, year) {
  url <- paste0("https://www.huduser.gov/hudapi/public/fmr/statedata/", state_code, "?year=", year)
  response <- GET(url, add_headers(Authorization = paste("Bearer", api_key)))
  
  if (status_code(response) == 200) {
    content_data <- content(response, "text")
    parsed_data <- fromJSON(content_data)
    
    # Extract county data
    counties_df <- as.data.frame(parsed_data$data$counties)
    
    # Add a state code and year column to the dataframe
    counties_df$state_code <- state_code
    counties_df$year <- year
    
    return(counties_df)
  } else {
    warning(paste("Failed to fetch data for", state_code, "in year", year, "Status code:", status_code(response)))
    return(data.frame())
  }
}

# Function to fetch county data for all states for a specified year
fetch_all_states_county_data <- function(year) {
  # List of state codes plus DC
  states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", 
              "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", 
              "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", 
              "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", 
              "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")
  
  national_county_data <- lapply(states, function(state) fetch_state_county_data(state, year))
  
  # Combine all the dataframes into one
  national_counties_df <- bind_rows(national_county_data)
  return(national_counties_df)
}

# Create data sets for each year
national_counties_data_2017 <- fetch_all_states_county_data(2017)
national_counties_data_2019 <- fetch_all_states_county_data(2019)
