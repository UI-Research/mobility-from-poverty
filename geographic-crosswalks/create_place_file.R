# this script pulls US Census Bureau Population Estimation Program and Decennial
# Census data to create a list of incorporated Census places with population estimates for 
# 2016-2020. Update in May 2023 once 2021 place estimates are released

library(tidyverse)
library(tidycensus)

# Replace YOUR-KEY-HERE below with your unique Census API key. Request a key at
# https://api.census.gov/data/key_signup.html if you don't have one.
# census_api_key("YOUR-KEY-HERE")

#' Get population estimates from the US Census Bureau Population Estimation Program
#'
#' @param year An integer for the year of interest
#'
#' @return A data frame with estimate for all US counties
#'
get_pop <- function(year) {
  
  pop <- tidycensus::get_estimates("place", year = year, variables = "POP") %>%
    mutate(year = year)
  
  return(pop)
  
}

# pull county population data for each year from the Population Estimates Program
## 2021 places will not be available until May 2023
pop <- map_df(.x = 2016:2019, 
              .f = ~get_pop(year = .x))

# pull the 2020 decennial census
census2020 <- tidycensus::get_decennial(geography = "place", year = 2020, variables = "P1_001N") %>%
  select(NAME, GEOID, variable, value) %>%
  mutate(year = 2020)

# combine the PEP data and decennial census data
pop <- bind_rows(pop, census2020)

# drop unnecessary variable and rename the useful variable
pop <- pop %>%
  select(-variable) %>%
  rename(population = value,
         place_state_name = NAME,
         state_place = GEOID)


# load in original population-based city file to get our original 486 cities
my_places <- read_csv(here::here("geographic-crosswalks", "data", "city_state_2020_population.csv")) %>%
  # DC is missing statefips and state_abbr
  mutate(state_abbr = case_when(cityname == "Washington city" & statename == "District of Columbia" ~ "DC",
                                TRUE ~ state_abbr),
         fips = case_when(cityname == "Washington city" & statename == "District of Columbia" ~ 11,
                               TRUE ~ fips)) %>%
  select(fips, statename, cityname, GeographicArea) %>%
  rename(state = fips,
         state_name = statename,
         place_name = cityname,
         place_state_name = GeographicArea)

# join data
joined_data <- left_join(x = my_places,
                         y = pop,
                         by = "place_state_name") 

# prepare file for export
joined_data <- joined_data %>%
  mutate(state = str_sub(state_place, start = 1L, end = 2L),
         place = str_sub(state_place, start = 3L, end = 7L)) %>%
  select(year, state, place, state_name, place_name, population) %>%
  arrange(year, state, place)

# We have 486 cities, so for 5 years we should have 2430 observations.
# However, South Fulton city, Georgia was incorporated in 2017, so we only
# have population estimates for this city from 2018-2020. Therefore, there
# are 2428 total observations

write_csv(x = joined_data,
          file = here::here("geographic-crosswalks/data/place-populations.csv")
          )

