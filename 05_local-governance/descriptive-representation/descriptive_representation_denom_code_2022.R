###############################################################################
# Description: Code to create county- & City-level Descriptive Representation denominator 
# This denominator is the population count at the county and city (e.g. Census Place) 
# level overall and by race/ethnicity groups  
# Data:  [gitfolder]/06_local-governance/descriptive-representation/data
# Author: Tina Chelidze	(pulling a lot of advice from Aaron Williams' original code)										   
# Date: January 20, 2022

# Steps:
# (1) Housekeeping
# (2) Pull demographics for Census Places and Census Counties from ACS 5-year 2021
# (3) Clean and reshape to move data into the vars we want
# (4) Test for errors
# (5) Create a data quality flag
# (6) Prepare the data for saving & export final Metrics files
###############################################################################

# (1) Housekeeping

# Open mobility-from-poverty.Rproj to make sure all file paths will work
# File > Open Project > select correct one

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)
library(tidyverse)
library(censusapi)
library(tidycensus)

# Establish Census API key
# You can get a Census API key here: https://api.census.gov/data/key_signup.html
# Your API key is stored in your .Renviron and can be accessed by Sys.getenv("CENSUS_API_KEY") 
# You can run `readRenviron("~/.Renviron")` or 
# census_api_key("YOURKEYHERE", install = TRUE)

# Figuring out where to pull data from (not necessary to run this code - just a prep step)
apis <- listCensusApis()
View(apis)

acs5_vars <- listCensusMetadata(name="2021/acs/acs5", type = "variables")
head(acs5_vars)


# Here are all the codes we need: 
# B01003_001E # Estimate total population
# B03003_003E # Estimate total, Hispanic and Latino
# B03002_002E # Estimate total, not Hispanic or Latino
# B03002_003E # Not Hispanic or Latino, White Alone
# B03002_004E # Not Hispanic or Latino, Black of African American Alone
# B03002_005E # Not Hispanic or Latino, American Indian and Alaska Native alone
# B03002_006E # Not Hispanic or Latino, Asian Alone
# B03002_007E # Not Hispanic or Latino, Native Hawaiian and Other Pacific Islander alone
# B03002_008E # Not Hispanic or Latino, some other race alone
# B03002_009E # Not Hispanic or Latino, two or more races


# (2) Pull demographics for Census Places and Census Counties

# First, list & save variables of interest as a vector
myvars <- c(
  "B01003_001E",
  "B03003_003E", 
  "B03002_002E",
  "B03002_003E",
  "B03002_004E",
  "B03002_005E",
  "B03002_006E",
  "B03002_007E",
  "B03002_008E",
  "B03002_009E"
  )

# Pull ACS data at the Census Place and Census County levels
places_demo <- get_acs(geography = "place",
                       variables = myvars,
                       year = 2021)

county_demo <- get_acs(geography = "county",
                       variables = myvars,
                       year = 2021)


# (3) Clean and reshape to move data into the vars we want

# Drop moe before reshape
places_demo <- places_demo %>% 
  select(GEOID, NAME, variable, estimate)
county_demo <- county_demo %>% 
  select(GEOID, NAME, variable, estimate)


# Reshape the datasets so we can see all the population values per row
wide_county_demo <- county_demo %>%
  pivot_wider(names_from = variable, values_from = estimate)
wide_places_demo <- places_demo %>%
  pivot_wider(names_from = variable, values_from = estimate)


# Rename vars for clarity
wide_county_demo <- wide_county_demo %>% 
  rename(
    "total_people" = "B01003_001",
    "total_hispanic" = "B03003_003", 
    "total_nonhisp" = "B03002_002",
    "white_nonhispanic" = "B03002_003",
    "black_nonhispanic" = "B03002_004",
    "aian_nh" = "B03002_005",
    "asian_nonhispanic" = "B03002_006",
    "nhpi_nh" = "B03002_007",
    "other_nh" = "B03002_008",
    "two_or_more_nh" = "B03002_009"
  )

wide_places_demo <- wide_places_demo %>% 
  rename(
    "total_people" = "B01003_001",
    "total_hispanic" = "B03003_003", 
    "total_nonhisp" = "B03002_002",
    "white_nonhispanic" = "B03002_003",
    "black_nonhispanic" = "B03002_004",
    "aian_nh" = "B03002_005",
    "asian_nonhispanic" = "B03002_006",
    "nhpi_nh" = "B03002_007",
    "other_nh" = "B03002_008",
    "two_or_more_nh" = "B03002_009"
  )

# Note from Aaron's code: The Census reports race and ethnicity as many different groups. 
# Table 2 in [this publication](https://www.census.gov/prod/cen2010/briefs/c2010br-02.pdf) is helpful. 
# Here, we collapse the detailed groups into the same four groups of interest from the above section. 

# Construct asian_other (combined value)
wide_county_demo <- wide_county_demo %>%
  mutate(
    asian_other = aian_nh + asian_nonhispanic + nhpi_nh + other_nh + two_or_more_nh,
  )

wide_places_demo <- wide_places_demo %>%
  mutate(
    asian_other = aian_nh + asian_nonhispanic + nhpi_nh + other_nh + two_or_more_nh,
  )

# Keep only the vars we need
wide_county_demo <- wide_county_demo %>% select(GEOID, 
                                                NAME, 
                                                total_people, 
                                                total_nonhisp,
                                                asian_other, 
                                                black_nonhispanic, 
                                                total_hispanic, 
                                                white_nonhispanic)

wide_places_demo <- wide_places_demo %>% select(GEOID, 
                                                NAME, 
                                                total_people, 
                                                total_nonhisp,
                                                asian_other, 
                                                black_nonhispanic, 
                                                total_hispanic, 
                                                white_nonhispanic)



# (4) Test for errors

# Test that the new groups sum to the original people total
stopifnot(
  wide_county_demo %>%
    mutate(total_people2 = asian_other + black_nonhispanic + total_hispanic + white_nonhispanic) %>%
    filter(total_people != total_people2) %>%
    nrow() == 0
)
# good to go!

# Now calculate the share of municipalities by race
wide_county_demo <- wide_county_demo %>%
  mutate(
    asian_other = asian_other / total_people, 
    black_nonhispanic = black_nonhispanic / total_people, 
    total_hispanic = total_hispanic / total_people,
    white_nonhispanic = white_nonhispanic / total_people
  )

wide_places_demo <- wide_places_demo %>%
  mutate(
    asian_other = asian_other / total_people, 
    black_nonhispanic = black_nonhispanic / total_people, 
    total_hispanic = total_hispanic / total_people,
    white_nonhispanic = white_nonhispanic / total_people
  )

# Test to see if bounded by 0 and 1
stopifnot(
  wide_county_demo %>%
    filter(
      asian_other < 0 | asian_other > 1 |
        black_nonhispanic < 0 | black_nonhispanic > 1|
        total_hispanic < 0 | total_hispanic > 1 |
        white_nonhispanic < 0 | white_nonhispanic > 1
    ) %>% 
    nrow() == 0
)

stopifnot(
  wide_places_demo %>%
    filter(
      asian_other < 0 | asian_other > 1 |
        black_nonhispanic < 0 | black_nonhispanic > 1|
        total_hispanic < 0 | total_hispanic > 1 |
        white_nonhispanic < 0 | white_nonhispanic > 1
    ) %>% 
    nrow() == 0
)
# good to go!

# Test to see if the 4 categories sum to 1
stopifnot(
  wide_county_demo %>%
    mutate(total = round(asian_other + black_nonhispanic + total_hispanic + white_nonhispanic, 10)) %>%
    filter(total != 1) %>%
    nrow() == 0
)

stopifnot(
  wide_places_demo %>%
    mutate(total = round(asian_other + black_nonhispanic + total_hispanic + white_nonhispanic, 10)) %>%
    filter(total != 1) %>%
    nrow() == 0
)
# good to go!


# (5) Create a data quality flag
wide_county_demo <- wide_county_demo %>%
  mutate(total_people_quality = 1, total_nonhisp_quality = 1, asian_other_quality = 1, 
         black_nonhispanic_quality = 1, total_hispanic_quality = 1, white_nonhispanic_quality = 1)

wide_places_demo <- wide_places_demo %>%
  mutate(total_people_quality = 1, total_nonhisp_quality = 1, asian_other_quality = 1, 
         black_nonhispanic_quality = 1, total_hispanic_quality = 1, white_nonhispanic_quality = 1)

# (6) Prepare the data for saving & export final Metrics files

# merge in the final County & Places files to isolate the data we need for each
county_pop <- read_csv("geographic-crosswalks/data/county-populations.csv")

places_pop <- read_csv("geographic-crosswalks/data/place-populations.csv")

# add in the lost leading zeroes for the state/county FIPs & state/place FIPs

county_pop <- county_pop %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))
county_pop <- county_pop %>%
  mutate(county = sprintf("%0.3d", as.numeric(county)))


places_pop <- places_pop %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))
places_pop <- places_pop %>%
  mutate(place = sprintf("%0.5d", as.numeric(place)))

# create a concatenated GEOID based on state + county & state + place
county_pop$GEOID <- paste(county_pop$state,county_pop$county, sep = "")

places_pop$GEOID <- paste(places_pop$state,places_pop$place, sep = "")



# keep the most recent year of population data (not 2022, but 2020)
county_pop <- filter(county_pop, year > 2019)

places_pop <- filter(places_pop, year > 2019)


# merge the data files into the population files (left join, since data files have more observations)
county_pop_by_race <- left_join(county_pop, wide_county_demo, by=c("GEOID"))

place_pop_by_race <- left_join(places_pop, wide_places_demo, by=c("GEOID"))


# Keep only relevant variables before export
county_pop_by_race <- county_pop_by_race %>% 
  select(year, state, county, total_people, total_nonhisp, 
         asian_other, black_nonhispanic, total_hispanic, white_nonhispanic,
         total_people_quality, total_nonhisp_quality, asian_other_quality, 
         black_nonhispanic_quality, total_hispanic_quality, white_nonhispanic_quality) %>%
  #Gabe Morrison code update: 
  #the year variable comes from the crosswalks, but the data is from 2017 - 2021, so we 
  # are calling it 2021
  mutate(year = 2021) %>%
  #GM second update: to make names better
  rename_with(.cols = total_people:white_nonhispanic_quality, 
              ~str_c("desc_rep_", .x)) %>%
  rename(desc_rep_total_population = desc_rep_total_people, 
         desc_rep_total_population_quality = desc_rep_total_people_quality)

place_pop_by_race <- place_pop_by_race %>% 
  select(year, state, place, total_people, total_nonhisp, asian_other, 
         black_nonhispanic, total_hispanic, white_nonhispanic,
         total_people_quality, total_nonhisp_quality, asian_other_quality, 
         black_nonhispanic_quality, total_hispanic_quality, white_nonhispanic_quality) %>%
  #See note above!
  mutate(year = 2021) %>%
  rename_with(.cols = total_people:white_nonhispanic_quality, 
              ~str_c("desc_rep_", .x)) %>%
  rename(desc_rep_total_population = desc_rep_total_people, 
         desc_rep_total_population_quality = desc_rep_total_people_quality)


# Export each of the files as CSVs
# view(county_pop_by_race)
write_csv(county_pop_by_race, "05_local-governance/descriptive-representation/data/descriptive_rep_denominator_county_2022.csv")

write_csv(place_pop_by_race, "05_local-governance/descriptive-representation/data/descriptive_rep_denominator_city_2022.csv")





