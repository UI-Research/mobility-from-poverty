#Create fips to name crosswalk
#Gabe Morrison
# 2023 03 29

# Script to create a mapping between fips codes and names for Forum One Devs

library(tidyverse)

county_xwalk <- read_csv("geographic-crosswalks/data/county-populations.csv") %>%
  filter(year == max(year)) %>%
  mutate(fips = paste0(state, county),
        name = paste0(county_name, ", ", state_name)) %>%
  select(fips, 
         name) %>%
  mutate(name2 = name)

city_xwalk <- read_csv("geographic-crosswalks/data/place-populations.csv") %>%
  filter(year == max(year)) %>%
  mutate(place_name_2 = sub("\\s+[^ ]+$", "", place_name),
         name = paste0(place_name, ", ", state_name), 
         name2 = paste0(place_name_2, ", ", state_name),
        fips = paste0(state, place)
  ) %>%
  select(fips, name, name2)

xwalk <- rbind(county_xwalk, city_xwalk)
write_csv(xwalk, "geographic-crosswalks/data/names-to-fips_all.csv")  
write_csv(county_xwalk, "geographic-crosswalks/data/names-to-fips_county.csv")
write_csv(city_xwalk, "geographic-crosswalks/data/names-to-fips_city.csv")
