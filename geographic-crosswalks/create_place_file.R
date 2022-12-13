# this script pulls US Census Bureau Population Estimation Program and Decennial
# Census data to create a list of incorporated Census places with population estimates for 
# 2016-2020. Update in May 2023 once 2021 place estimates are released

library(tidyverse)
library(tidycensus)

census_api_key("866122dc573a0f65f0ff4c23130956014a5b480c")
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
         geographicarea = NAME,
         stateplacefp = GEOID)


# load in original population-based city file to get our original 486 cities
og_cityfile <- read_csv(here::here("geographic-crosswalks", "data", "city_state_2020_population.csv")) %>%
  rename(geographicarea = GeographicArea,
         statefips = fips) %>%
  # DC is missing statefips and state_abbr
  mutate(state_abbr = case_when(cityname == "Washington city" & statename == "District of Columbia" ~ "DC",
                                TRUE ~ state_abbr),
         statefips = case_when(cityname == "Washington city" & statename == "District of Columbia" ~ 11,
                               TRUE ~ statefips)) %>%
  select(-population2020)

# join data
joined_data <- left_join(x = og_cityfile,
                         y = pop,
                         by = "geographicarea") %>%
  arrange(year, statefips, stateplacefp) %>%
  select(year, geographicarea, cityname, city, statename, state_abbr, population, statefips, stateplacefp)

# We have 486 cities, so for 5 years we should have 2430 observations.
# However, South Fulton city, Georgia was incorporated in 2017, so we only
# have population estimates for this city from 2018-2020. Therefore, there
# are 2428 total observations

write_csv(joined_data, here::here("geographic-crosswalks/data/place-populations.csv"))
