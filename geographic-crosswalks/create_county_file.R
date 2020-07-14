library(tidyverse)
library(tidycensus)

#' Get population estimates from the US Census Bureau Population Estimation Project
#'
#' @param year An integer for the year of interest
#'
#' @return A data frame with estimate for all US counties
#'
get_pop <- function(year) {
  
  pop <- get_estimates("county", year = year, var = "POP") %>%
    mutate(year = year)
  
  return(pop)
  
}

# pull state and county for each year 
pop <- map_df(.x = 2015:2018, 
              .f = ~get_pop(year = .x))

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

# clean one messy county from New Mexico
pop <- pop %>%
  select(year, state, county, state_name, county_name, population) %>%
  arrange(year, state, county) %>%
  mutate(county_name = ifelse(county_name == "DoÃ±a Ana County", "Doña Ana County", county_name))

write_csv(pop, "geographic-crosswalks/data/county-file.csv")
