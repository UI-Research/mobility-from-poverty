# this script pulls US Census Bureau Population Estimation Program and Decennial
# Census data to create a list of counties with population estimates for 
# 2014-2020

# In 2014-2019, there are 3,142 counties. In 2020, 
# Valdez-Cordova Census Area split into 
# Chugach Census Area and Copper River Census Area

library(tidyverse)
library(tidycensus)

#' Get population estimates from the US Census Bureau Population Estimation Program
#'
#' @param year An integer for the year of interest
#'
#' @return A data frame with estimate for all US counties
#'
get_pop <- function(year) {
  
  pop <- get_estimates("county", year = year, variables = "POP") %>%
    mutate(year = year)
  
  return(pop)
  
}

# pull county population data for each year from the Population Estimates Program
pop <- map_df(.x = 2015:2019, 
              .f = ~get_pop(year = .x))

# pull the 2020 decennial census
census2020 <- get_decennial(geography = "county", year = 2020, variables = "P1_001N") %>%
  select(NAME, GEOID, variable, value) %>%
  mutate(year = 2020)

# combine the PEP data and decennial census data
pop <- bind_rows(pop, census2020)

# drop unnecessary variable and rename the useful variable
pop <- pop %>%
  select(-variable) %>%
  rename(population = value)

# split GEOID into state and county
pop <- pop %>%
  mutate(state = str_sub(GEOID, start = 1, end = 2),
         county = str_sub(GEOID, start = 3, end = 5)) %>%
  select(-GEOID)

# drop PR
pop <- pop %>%
  filter(state != "72")

# split the detailed county name into county_name and state_name
pop <- pop %>%
  separate(NAME, into = c("county_name", "state_name", "c", "d", "e"), sep = ",") %>%
  mutate(state_name = str_trim(state_name)) %>%
  select(-c, -d, -e)

# clean one messy county name from New Mexico
pop <- pop %>%
  select(year, state, county, state_name, county_name, population) %>%
  arrange(year, state, county) %>%
  mutate(county_name = ifelse(county_name == "DoÃ±a Ana County", "Doña Ana County", county_name))

# add 2014 county names with no population estimate
# PEP isn't in tidycensus before 2015
pop <-
  bind_rows(
    pop %>%
      filter(year == 2015) %>%
      mutate(year = 2014, population = NA),
    pop
  )

write_csv(pop, "geographic-crosswalks/data/county-populations.csv")
