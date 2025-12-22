library(tidyverse)
library(rvest)
library(polite)

source(here::here("09_employment", "get_living_wages.R"))

# read in crosswalk file
all_counties <- read_csv(here::here("geographic-crosswalks", "data", "county-file.csv")) %>%
  filter(year == 2018)

# scrape the data and append each observation to a .csv
all_counties %>%
  mutate(fips = paste0(state, county)) %>%
  pull(fips) %>%  
  map_df(.f = get_living_wages, sleep_time = 10)

# read in the scraped data
mit <- read_csv(here::here("09_employment", "mit-living-wage-scraped_12_15_22.csv"), 
                col_names = FALSE) %>%
  mutate(state = str_sub(X1, 1, 2),
         county = str_sub(X1, 3, 5)) %>%
  select(-X1) %>%
  rename(adults = X2,
         children = X3,
         wage = X4)

# joint he scraped data to the final list of counties
joined_data <- left_join(all_counties, mit, by = c("state", "county"))

# write the final file
joined_data %>%
  select(year, state, county, adults, children, wage) %>%
  mutate(year = 2021) %>% 
  write_csv(here::here("09_employment", "mit-living-wage-2022.csv"))
  
  