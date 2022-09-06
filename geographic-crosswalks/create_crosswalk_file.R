library(tidyverse)
library(censusapi)

source(here::here("geographic-crosswalks", "census_api_key.R"))

#' Pull all US tracts in a given year
#'
#' @param year An integer for year
#'
#' @return A data frame with state, county, tract, and year
#' 
get_tracts <- function(year) {
  
  state <- c("01", "02", "04", "05", "06", "08", "09", "10", "11", "12", 
             "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", 
             "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", 
             "34", "35", "36", "37", "38", "39", "40", "41", "42", "44", 
             "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56")

  state_fips <- paste0("state:", state)
  
  # pull state, county, and tract
  population <- map_df(state_fips, ~getCensus(name = "acs/acs5",
                                              vars = "B01003_001E", # TOTAL POPULATION 
                                              region = "tract:*",
                                              regionin = .x,
                                              vintage = year)) %>%
    as_tibble() %>%
    mutate(year = year)

  return(population)
  
}

# pull the 2018 tracts
tracts <- get_tracts(year = 2018) %>%
  select(-B01003_001E)

# sort rows and columns and save as a csv
tracts %>%
  arrange(year, state, county, tract) %>%
  select(year, state, county, tract) %>%
  write_csv("geographic-crosswalks/data/tract-county-crosswalk_2018.csv")

# pull the 2020 tracts
tracts <- get_tracts(year = 2020) %>%
  select(-B01003_001E)

# sort rows and columns and save as a csv
tracts %>%
  arrange(year, state, county, tract) %>%
  select(year, state, county, tract) %>%
  write_csv("geographic-crosswalks/data/tract-county-crosswalk_2020.csv")