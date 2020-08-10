library(tidyverse)
library(rvest)
library(polite)

source("get_living_wages.R")

all_counties <- pull(urbnmapr::countydata, county_fips) %>%
  map_df(.f = get_living_wages, sleep_time = 10)


all_counties <- read_csv(here::here("geographic-crosswalks", "data", "county-file.csv")) %>%
  filter(year == 2018)

mit <- read_csv(here::here("09_employment", "mit-living-wage-scraped.csv"), 
                col_names = FALSE) %>%
  mutate(state = str_sub(X1, 1, 2),
         county = str_sub(X1, 3, 5)) %>%
  select(-X1) %>%
  rename(adults = X2,
         children = X3,
         wage = X4)

all_counties <- left_join(all_counties, mit, by = c("state", "county"))

all_counties %>%
  select(year, state, county, adults, children, wage) %>%
  write_csv(here::here("09_employment", "mit-living-wage.csv"))
  
  