# Update the county- and city-populations crosswalks with pop for 2021 & 2022, which is based on the 
# US Census Bureau Population Estimation Program and Decennial data
# Data for 2021 & 2022 pulled manually via link

# In 2014-2022, there are 3,142 counties. In 2020, 
# Valdez-Cordova Census Area split into 
# Chugach Census Area and Copper River Census Area

# Data links pulled from: https://www.census.gov/programs-surveys/popest/data/data-sets.html

library(readxl)
library(stringr)
library(tidyr)





#######################################################################


# repeat the same process for cities


# FIRST, RUN THE ORIGINAL create_places_file.R 

# Specify URL where source data file is online
placeurl <- "https://www2.census.gov/programs-surveys/popest/datasets/2020-2022/cities/totals/sub-est2022.csv"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfileplace <- "Census_PEP_city.csv"

# Import the data file & save locally
download.file(placeurl, destfileplace, mode="wb")

# Import the data file as a dataframe
place_pops <- read_csv("Census_PEP_city.csv")

# rename columns
place_pops <- place_pops %>% 
  rename('2021' = POPESTIMATE2021,
         '2022' = POPESTIMATE2022,
         state = STATE,
         place = PLACE,
         state_name = STNAME,
         place_name = NAME)

# remove unnecessary data before reshaping
place_pops <- place_pops %>%
  filter(place != "00000")

# keep only variables we want before reshaping by place
place_pops <- place_pops %>% 
  select(state, place, state_name, place_name, "2021", "2022")

# load in original population-based city file to get our original 486 cities
my_places <- read_csv("geographic-crosswalks/data/city_state_2020_population.csv") %>%
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
joined_data2 <- semi_join(place_pops, my_places, by = c("place_name", "state_name"))
#drop duplicates
joined_data2 <- joined_data2[!duplicated(joined_data2), ]


# reshape by place
joined_data2 <- joined_data2 %>% 
  pivot_longer(
    cols = `2021`:`2022`, 
    names_to = "year",
    values_to = "population"
  )

# append to original places population file
places_pop <- rbind(joined_data, joined_data2)

# resave the updated population file
write_csv(places_pop, "geographic-crosswalks/data/place-populations.csv")



# We have 486 cities, so for 7 years we should have 3402 observations.
# However, South Fulton city, Georgia was incorporated in 2017, so we only
# have population estimates for this city from 2018-2020. Therefore, there
# are 3400 total observations










