###############################################################################
# Description: Code to create county-level Descriptive Representation denominator 
# This denominator is the population count at the county level overall and by race/ethnicity groups  
# Data:  [gitfolder]/06_local_governance/descriptive_representation
# Author: Tina Chelidze	(pulling a lot of advice from Aaron Williams' original code)										   
# Date: January 20, 2022

# Steps:
# (1) Housekeeping
# (2) Pull demographics for Census Places and Census Counties from ACS 5-year 2020
# (3) Clean and reshape to move data into the vars we want
# (4) Test for errors
# (5) Create a data quality flag
# (6) Prepare the data for saving & export final Metrics files
###############################################################################

# (1) Housekeeping

# Set working directory to [gitfolder]. Update path as necessary to your local metrics repo
setwd("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty")

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)
library(censusapi)

# add in your own Census API key or use mine if needed
# You can get a Census API key here: https://api.census.gov/data/key_signup.html
census_api_key("a92cdc14739747a791bb02096d30a82f27f05add", install = TRUE)

# Figuring out where to pull data from (not necessary to run this code - just a prep step)
apis <- listCensusApis()
View(apis)

acs5_vars <- listCensusMetadata(name="2020/acs/acs5", type = "variables")
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
                       year = 2020)

county_demo <- get_acs(geography = "county",
                       variables = myvars,
                       year = 2020)


# (3) Clean and reshape to move data into the vars we want

# Drop moe before reshape
places_demo <- places_demo %>% select(GEOID, NAME, variable, estimate)
county_demo <- county_demo %>% select(GEOID, NAME, variable, estimate)


# Reshape the datasets so we can see all the population values per row
wide_county_demo <- county_demo %>% spread(variable, estimate)
wide_places_demo <- places_demo %>% spread(variable, estimate)


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
wide_county_demo$asian_other <- rowSums(wide_county_demo[, c("aian_nh", "asian_nonhispanic", "nhpi_nh", "other_nh", "two_or_more_nh")], na.rm = TRUE)
wide_places_demo$asian_other <- rowSums(wide_places_demo[, c("aian_nh", "asian_nonhispanic", "nhpi_nh", "other_nh", "two_or_more_nh")], na.rm = TRUE)


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
# Need advice on this -- should I bring back the moe? the question is then how to handle asian_other...




# (6) Prepare the data for saving & export final Metrics files

# merge in the final County & Places files to isolate the data we need for each
county_pop <- read.csv("geographic-crosswalks/data/county-populations.csv")

places_pop <- read.csv("geographic-crosswalks/data/place-populations.csv")

# add in the lost leading zeroes for the state/county FIPs & state/place FIPs
county_pop$state <- sprintf("%02d", as.numeric(county_pop$state))
county_pop$county <- sprintf("%03d", as.numeric(county_pop$county))

places_pop$state <- sprintf("%02d", as.numeric(places_pop$state))
places_pop$place <- sprintf("%05d", as.numeric(places_pop$place))

# create a concatenated GEOID based on state + county & state + place
county_pop$GEOID <- paste(county_pop$state,county_pop$county, sep = "")

places_pop$GEOID <- paste(places_pop$state,places_pop$place, sep = "")

# keep the most recent year of population data (not 2022, but 2020)
county_pop <- filter(county_pop, year > 2019)

places_pop <- filter(places_pop, year > 2019)


# merge the data files into the population files (left join, since data files have more observations)
county_pop_by_race <- merge(county_pop, wide_county_demo, by=c("GEOID"), all.x = TRUE)

place_pop_by_race <- merge(places_pop, wide_places_demo, by=c("GEOID"), all.x = TRUE)


# Keep only relevant variables before export
county_pop_by_race <- county_pop_by_race %>% select(GEOID, year, state_name, county_name, total_people, total_nonhisp, asian_other, black_nonhispanic, total_hispanic, white_nonhispanic)

place_pop_by_race <- place_pop_by_race %>% select(GEOID, year, NAME, total_people, total_nonhisp, asian_other, black_nonhispanic, total_hispanic, white_nonhispanic)


# Export each of the files as CSVs
view(county_pop_by_race)
write_csv(county_pop_by_race, "06_local_governance/descriptive_representation/data/descriptive_rep_denominator_county_2022.csv")

write_csv(place_pop_by_race, "06_local_governance/descriptive_representation/descriptive_rep_denominator_city_2022.csv")





