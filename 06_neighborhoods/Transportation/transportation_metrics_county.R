###################################################################

# Transit Metrics: Transit Trips & Transportation Costs
# Tina Chelidze 
# 2023-2024 Mobility Metrics update
# Process (for overall, not subgroup, data):
# 1. For County: Import and reshape data
# 2. QC checks
# 3. Add Data Quality marker
# 4. Export final files

###################################################################


# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)
library(ggplot2)
library(tidyverse)
library(tidycensus)
library(purrr)

# SUMMARY-LEVEL VALUES
# Raw data pulled from https://htaindex.cnt.org/download/
# the Housing and Transportation (H+T) Affordability Index from the Center for Neighborhood Technology (CNT)

###################################################################

# 1. Import all the files (and/or combine into one file) with only the relevant variables and years

# FOR COUNTIES - import the raw data files
# Unlike for Places and Tracts, the CNT website allows you to download raw data for all counties at once
# so we just import the all-county file for the two available years; 2015 and 2019
# 2015
transport_county_2015 <- read_csv("C:/Users/tchelidze/Documents/Transportation/htaindex2015_data_counties.csv")

# create correct FIPS columns
transport_county_2015 <- transport_county_2015 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

  # keep only variables of interest & separate out into separate var files (access vs. cost)
transportation_cost_county_2015 <- transport_county_2015 %>%
  select(state, county, blkgrps, population, households, transit_cost_80ami)
transit_trips_county_2015 <- transport_county_2015 %>%
  select(state, county, blkgrps, population, households, transit_trips_80ami)



#2019
transport_county_2019 <- read_csv("C:/Users/tchelidze/Documents/Transportation/htaindex2019_data_counties.csv")
transport_county_2019 <- transport_county_2019 %>%
  select(county, blkgrps, population, households, transit_cost_80ami, transit_trips_80ami)

# create correct FIPS columns
transport_county_2019 <- transport_county_2019 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

# keep only variables of interest
transportation_cost_county_2019 <- transport_county_2019 %>%
  select(state, county, blkgrps, population, households, transit_cost_80ami)
transit_trips_county_2019 <- transport_county_2019 %>%
  select(state, county, blkgrps, population, households, transit_trips_80ami)

# Compare to our official county file to make sure we have all counties accounted for
# Bring in the official county file
counties <- read_csv("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty/geographic-crosswalks/data/county-populations.csv")
counties_2015 <- counties %>%
  filter(year == 2015)
counties_2019 <- counties %>%
  filter(year == 2019)
# all files have same number of observations (3142) so no merging needed to account for missings!

###################################################################

# 2. QC Checks
  # create a histogram plot and summary stats for each dataframe
  # check that all values are non-negative & count missing values
  # examine outliers
  

  # County-Level Transit Trips 2015
ggplot(transit_trips_county_2015, aes(x=transit_trips_80ami)) + geom_histogram(binwidth=5) + labs(y="number of counties", x="Annual Transit Trips for the Regional Moderate Income Household, 2015")
  # Makes sense for most counties to fall in really low transit trip numbers since most of the US has no public infrastructure that can be used for daily transport
# look at summary stats
summary(transit_trips_county_2015$transit_trips_80ami)
# examine outliers
transit_trips_county_2015_outliers <- transit_trips_county_2015 %>% 
  filter(transit_trips_80ami>250) 
  # 1057 trips in 38059 county -- Morton County, North Dakota -- seems to be a railroad town...
  # 1300 trips in 36047 -- Kings County, New York -- this is Brooklyn, makes total sense
  # all the highest ones(1000+) are in New York counties - checks out
  # 313 trips in 06037 -- Los Angeles county, California - checks out

# Use stopifnot to check if all values in "transit_trips_county_2015" are non-negative
stopifnot(min(transit_trips_county_2015$transit_trips_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "transit_trips_80ami" variable
missing_indices <- which(is.na(transit_trips_county_2015$transit_trips_80ami))
# Print observations with missing values
if (length(missing_indices) > 0) {
  cat("Observations with missing values for transit_trips_80ami:\n")
  print(transit_trips_county_2015[missing_indices, , drop = FALSE])
} else {
  cat("No missing values for transit_trips_county_2015.\n")
}
# One missing value: Loving County, Texas (FIPS 48301)


# County-Level Transit Trips 2019
ggplot(transit_trips_county_2019, aes(x=transit_trips_80ami)) + geom_histogram(binwidth=5) + labs(y="number of counties", x="Annual Transit Trips for the Regional Moderate Income Household, 2019")
 # looks similar, checks out
# look at summary stats
summary(transit_trips_county_2019$transit_trips_80ami)  
# examine outliers
transit_trips_county_2019_outliers <- transit_trips_county_2019 %>% 
  filter(transit_trips_80ami>250) 
# 1160 trips in 42101 county - Bowling Green, Kentucky. GObg, Bowling Green's public transit system, provides para-transit service throughout the City of Bowling Green
# 2105 trips in 25025 county - Suffolk County, MA - Boston metro area, makes sense
# 1150 trips in 11001 county - Washington DC, makes sense
# all the highest ones(1000+) are in New York counties - checks out

# Use stopifnot to check if all values in "transit_trips_county_2019" are non-negative
stopifnot(min(transit_trips_county_2019$transit_trips_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "transit_trips_80ami" variable
missing_indices <- which(is.na(transit_trips_county_2019$transit_trips_80ami))
# Print observations with missing values
if (length(missing_indices) > 0) {
  cat("Observations with missing values for transit_trips_80ami:\n")
  print(transit_trips_county_2019[missing_indices, , drop = FALSE])
} else {
  cat("No missing values for transit_trips_county_2019\n")
}
# No missing values for 2019


  # County-Level Transportation Cost 2015
ggplot(transportation_cost_county_2015, aes(x=transit_cost_80ami)) + geom_histogram(binwidth=10) + labs(y="number of counties", x="Annual Transit Cost for the Regional Moderate Income Household, 2015")
# look at summary stats
summary(transportation_cost_county_2015$transit_cost_80ami)  
# examine outliers
transportation_cost_county_2015_outliers <- transportation_cost_county_2015 %>% 
  filter(transit_cost_80ami>250) 
# $1037 in 06075 county - Tolland County, CT - suburban, between Boston, PVD, and New Haven. Makes sense
# All high numbers ($1000+) in NYC area, makes sense (state FIPS 36)
# $1726 in 38059 county -- Morton County, North Dakota - this aligns with the high number of trips! (see above)

# Use stopifnot to check if all values in "transportation_cost_county_2015" are non-negative
stopifnot(min(transportation_cost_county_2015$transit_cost_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "transit_cost_80ami" variable
missing_indices <- which(is.na(transportation_cost_county_2015$transit_cost_80ami))
# Print observations with missing values
if (length(missing_indices) > 0) {
  cat("Observations with missing values for transit_cost_80ami:\n")
  print(transportation_cost_county_2015[missing_indices, , drop = FALSE])
} else {
  cat("No missing values for transportation_cost_county_2015\n")
}
# 1 missing value: Loving County, TX (48301 FIPS) - consistent with the trips 2015 data



  # County-Level Transportation Cost 2019
ggplot(transportation_cost_county_2019, aes(x=transit_cost_80ami)) + geom_histogram(binwidth=10) + labs(y="number of counties", x="Annual Transit Cost for the Regional Moderate Income Household, 2019")
# look at summary stats
summary(transportation_cost_county_2019$transit_cost_80ami) 
# examine outliers
transportation_cost_county_2019_outliers <- transportation_cost_county_2019 %>% 
  filter(transit_cost_80ami>250) 
# $1184 in 42045 county - Grand Rivers, Kentucky ?
# $1744 in 42101 county - Bowling Green, Kentucky ?
# $1444 in 51013 county - Arlington County, VA -  DC suburb, makes sense
# $2866 in 34017 county - Hudson County, NJ -- NYC+suburb, makes sense 
# $3998 in 25025 county - Suffolk County, MA - Boston metro area, makes sense
# $2192 in 11001 county - Washington, D.C.
# $1021 in 06075 county - San Francisco, CA

# Use stopifnot to check if all values in "transportation_cost_county_2019" are non-negative
stopifnot(min(transportation_cost_county_2019$transit_cost_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "transit_cost_80ami" variable
missing_indices <- which(is.na(transportation_cost_county_2019$transit_cost_80ami))
# Print observations with missing values
if (length(missing_indices) > 0) {
  cat("Observations with missing values for transit_cost_80ami:\n")
  print(transportation_cost_county_2019[missing_indices, , drop = FALSE])
} else {
  cat("No missing values for transportation_cost_county_2019\n")
}
# No missing values for 2019


###################################################################

# 3. Data Quality marker

# Determine data quality cutoffs based on number of observations (all at the HH level for these values)
summary(transit_trips_county_2015$households) 
summary(transit_trips_county_2019$households) 
summary(transportation_cost_county_2015$households) 
summary(transportation_cost_county_2019$households) 

# we use a 30 HH cutoff for Data Quality 3 for the ACS variables, so for the sake of consistency, since none of 
# these are less than 30 (all minimum values are at least 30 HHs), Data Quality can be 1 for all these observations
# BUT ALSO, rename all the metrics variables to what we had before (transit_trips & transit_cost), so we can name
# the quality variable appropriately
transit_trips_county_2015 <- transit_trips_county_2015 %>% 
  rename(transit_trips = transit_trips_80ami) %>%
  mutate(transit_trips_quality = 1)
transit_trips_county_2019 <- transit_trips_county_2019 %>% 
  rename(transit_trips = transit_trips_80ami) %>%
  mutate(transit_trips_quality = 1)
transportation_cost_county_2015 <- transportation_cost_county_2015 %>% 
  rename(transit_cost = transit_cost_80ami) %>%
  mutate(transit_cost_quality = 1)
transportation_cost_county_2019 <- transportation_cost_county_2019 %>% 
  rename(transit_cost = transit_cost_80ami) %>%
  mutate(transit_cost_quality = 1)


###################################################################

# 4. Export final files

# add a variable for the year of the data
transit_trips_county_2015 <- transit_trips_county_2015 %>%
  mutate(
    year = 2015
  )
transit_trips_county_2019 <- transit_trips_county_2019 %>%
  mutate(
    year = 2019
  )
transportation_cost_county_2015 <- transportation_cost_county_2015 %>%
  mutate(
    year = 2015
  )
transportation_cost_county_2019 <- transportation_cost_county_2019 %>%
  mutate(
    year = 2019
  )

# Combine the two years into one overall files for both variables
transit_trips_county <- rbind(transit_trips_county_2015, transit_trips_county_2019)
transit_cost_county <- rbind(transportation_cost_county_2015, transportation_cost_county_2019)


# Keep variables of interest and order them appropriately
transit_trips_county <- transit_trips_county %>%
  select(year, state, county, transit_trips, transit_trips_quality)
transit_cost_county <- transit_cost_county %>%
  select(year, state, county, transit_cost, transit_cost_quality)


# Save as non-subgroup all-year files
#write_csv(transit_trips_county, "06_neighborhoods/transit_trips_all_county.csv")
#write_csv(transit_cost_county, "06_neighborhoods/transit_cost_all_county.csv")  


############################################################

# SUBGROUP FILE

# Process for SUBGROUP-level:
# 1. Import all the tract-level files and combine into one mega-file with only the relevant variables and years
# 2. Race-Ethnicity work: 
# 2a. Pull in that year's population by race via ACS (tract-level)
# 2b. for all tracts that are 60%+ of one race (or mixed) -- the buckets are: neighborhoods of color, white, and mixed
# 3. Collapse accordingly
# 4. QC checks
# 5. Data Quality marker
# 6. Export
###################################################################


###################################################################

# 1. Import all the tract-level files and combine into one mega-file with only the relevant variables and years

# 2015
# bring in all the downloaded CSVs (state-level tracts) & combine them into one nation-wide file for tracts
tracts15files <- list.files(path="C:/Users/tchelidze/Documents/Transportation/2015_tract/",
                            pattern="*.csv")
print(tracts15files)
tractpath15 = file.path("C:/Users/tchelidze/Documents/Transportation/2015_tract",tracts15files)
print(tractpath15)
transport_tracts_2015 <- do.call("rbind",lapply(tractpath15,FUN=function(files){ read.csv(files)}))

# create correct FIPS columns
transport_tracts_2015 <- transport_tracts_2015 %>%
  rename (GEOID = tract) %>%
  mutate(
    state = substr(GEOID, start = 2, stop = 3),
    county = substr(GEOID, start = 4, stop = 6),
    tract = substr(GEOID, start = 7, stop = 12)
  )

# keep only variables of interest
transit_trips_tracts_2015 <- transport_tracts_2015 %>%
  select(GEOID, state, county, tract, blkgrps, population, households, transit_trips_80ami)
transit_cost_tracts_2015 <- transport_tracts_2015 %>%
  select(GEOID, state, county, tract, blkgrps, population, households, transit_cost_80ami)



# 2019
# bring in all the downloaded CSVs (state-level tracts) & combine them into one nation-wide file for tracts
tracts19files <- list.files(path="C:/Users/tchelidze/Documents/Transportation/2019_tract/",
                            pattern="*.csv")
print(tracts19files)
tractpath19 = file.path("C:/Users/tchelidze/Documents/Transportation/2019_tract",tracts19files)
print(tractpath19)
transport_tracts_2019 <- do.call("rbind",lapply(tractpath19,FUN=function(files){ read.csv(files)}))

# create correct FIPS columns
transport_tracts_2019 <- transport_tracts_2019 %>%
  rename (GEOID = tract) %>%
  mutate(
    state = substr(GEOID, start = 2, stop = 3),
    county = substr(GEOID, start = 4, stop = 6),
    tract = substr(GEOID, start = 7, stop = 12)
  )

# keep only variables of interest
transit_trips_tracts_2019 <- transport_tracts_2019 %>%
  select(GEOID, state, county, tract, blkgrps, population, households, transit_trips_80ami)
transit_cost_tracts_2019 <- transport_tracts_2019 %>%
  select(GEOID, state, county, tract, blkgrps, population, households, transit_cost_80ami)


###################################################################

# 2. Race-Ethnicity work: 
# 2a. Pull in that year's population by race via ACS (tract-level)

ACSvars2015 <- load_variables(2015, "acs5", cache = TRUE)
ACSvars2019 <- load_variables(2019, "acs5", cache = TRUE)

# Variables we want:
# B02001_001 Total Pop Estimate
# B02001_002 White alone
# B02001_003 Black or AfAm alone
# B02001_004 Am Indian & Alaska Native alone
# B02001_005 Asian alone
# B02001_006 Native Hawaiian, Pacific Islander alone
# B02001_007 Some other race alone
# B02001_008 Two or more races


my_states <- fips_codes %>% 
  filter(!state %in% c("PR", "UM", "VI", "GU", "AS", "MP")) %>%
  pull(state) %>%
  unique()

acs_tract_pop15 <- map_dfr(
  my_states,
  ~ get_acs(
    geography = "tract",
    state = .,
    table = "B02001",
    year = 2015,
    survey = "acs5",
    output = "wide"
  )
)

# rename columns for clarity
acs_tract_pop15 <- acs_tract_pop15 %>%  
  rename(total_population = B02001_001E,
         white_population = B02001_002E,
         black_population = B02001_003E,
         asian_population = B02001_005E,
         aian_population = B02001_004E,
         nhpi_population = B02001_006E,
         other_population = B02001_007E
         )

acs_tract_pop19 <- map_dfr(
  my_states,
  ~ get_acs(
    geography = "tract",
    state = .,
    table = "B02001",
    year = 2019,
    survey = "acs5",
    output = "wide"
  )
)

acs_tract_pop19 <- acs_tract_pop19 %>%  
  rename(total_population = B02001_001E,
         white_population = B02001_002E,
         black_population = B02001_003E,
         asian_population = B02001_005E,
         aian_population = B02001_004E,
         nhpi_population = B02001_006E,
         other_population = B02001_007E
  )

# keep only vars we want
acs_tract_pop15 <- acs_tract_pop15 %>%
  select(GEOID, total_population, white_population, black_population,
         asian_population, aian_population, nhpi_population, other_population)
acs_tract_pop19 <- acs_tract_pop19 %>%
  select(GEOID, total_population, white_population, black_population,
         asian_population, aian_population, nhpi_population, other_population)

# note that this is 73,056 observations in the ACS data
# That means we will have 317 missing tract values in 2015 (73056 - 72739), and 
# 314 missing tract values in the 2019 data (72056 - 72742)

# Join the transit data with the ACS population data,

# first, prep GEOID in the transit data for join purposes
transit_cost_tracts_2015$GEOID <- paste0(transit_cost_tracts_2015$state, transit_cost_tracts_2015$county, transit_cost_tracts_2015$tract)
transit_cost_tracts_2019$GEOID <- paste0(transit_cost_tracts_2019$state, transit_cost_tracts_2019$county, transit_cost_tracts_2019$tract)
transit_trips_tracts_2015$GEOID <- paste0(transit_trips_tracts_2015$state, transit_trips_tracts_2015$county, transit_trips_tracts_2015$tract)
transit_trips_tracts_2019$GEOID <- paste0(transit_trips_tracts_2019$state, transit_trips_tracts_2019$county, transit_trips_tracts_2019$tract)


# merge population data with transit data files (4 of them)
############################################################################
# FIRST ONE - Cost in 2015
############################################################################
cost_data_2015 <- left_join(acs_tract_pop15, transit_cost_tracts_2015, by = "GEOID")
#Test with anti_join to make sure it worked properly
stopifnot(
  anti_join(acs_tract_pop15, transit_cost_tracts_2015, by = "GEOID") %>%
    nrow() == 0
)
# Error - therefore, check how many missing cost values for observations where we have population
missing_count <- sum(is.na(cost_data_2015$transit_cost_80ami))
cat("Number of missing values for transit_cost_80ami:", missing_count, "\n")
# 810 missing values

############################################################################
# SECOND ONE - Cost in 2019
############################################################################
cost_data_2019 <- left_join(acs_tract_pop19, transit_cost_tracts_2019, by = "GEOID")
#Test with anti_join to make sure it worked properly
stopifnot(
  anti_join(acs_tract_pop19, transit_cost_tracts_2019, by = "GEOID") %>%
    nrow() == 0
)
# Error - therefore, check how many missing cost values for observations where we have population
missing_count <- sum(is.na(cost_data_2019$transit_cost_80ami))
cat("Number of missing values for transit_cost_80ami:", missing_count, "\n")
# 831 missing values

############################################################################
# THIRD ONE - Trips in 2015
############################################################################
trips_data_2015 <- left_join(acs_tract_pop15, transit_trips_tracts_2015, by = "GEOID")
#Test with anti_join to make sure it worked properly
stopifnot(
  anti_join(acs_tract_pop15, transit_trips_tracts_2015, by = "GEOID") %>%
    nrow() == 0
)
# Error - therefore, check how many missing trips values for observations where we have population
missing_count <- sum(is.na(trips_data_2015$transit_trips_80ami))
cat("Number of missing values for transit_trips_80ami:", missing_count, "\n")
# 810 missing values - aligns with cost data for the same year, good

############################################################################
# FOURTH ONE - Trips in 2019
############################################################################
trips_data_2019 <- left_join(acs_tract_pop19, transit_trips_tracts_2019, by = "GEOID")
#Test with anti_join to make sure it worked properly
stopifnot(
  anti_join(acs_tract_pop19, transit_trips_tracts_2019, by = "GEOID") %>%
    nrow() == 0
)
# Error - therefore, check how many missing trips values for observations where we have population
missing_count <- sum(is.na(trips_data_2019$transit_trips_80ami))
cat("Number of missing values for transit_trips_80ami:", missing_count, "\n")
# 831 missing values - aligns with cost data for the same year, good

############################################################################

# For each tract, ID the race category
# Calculate the percentage of total population for White & POC for each tract
cost_data_2015 <- cost_data_2015 %>%
  mutate(perc_white = if_else(population > 0, white_population / total_population, 0), 
         perc_POC = if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0))

cost_data_2019 <- cost_data_2019 %>%
  mutate(perc_white = if_else(population > 0, white_population / total_population, 0), 
         perc_POC = if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0))

trips_data_2015 <- trips_data_2015 %>%
  mutate(perc_white = if_else(population > 0, white_population / total_population, 0), 
         perc_POC = if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0))

trips_data_2019 <- trips_data_2019 %>%
  mutate(perc_white = if_else(population > 0, white_population / total_population, 0), 
         perc_POC = if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0))

# Assign race-category for each tract
# If 0.6+ White, assign Predominantly White, if 0.6+ POC, assign Predominantly POC
# 40-60% White or POC, assign No Predominant Racial Group
cost_data_2015 <- cost_data_2015 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Predominantly White",
      perc_POC >= 0.6 ~ "Predominantly People of Color",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "No Predominant Racial Group",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

cost_data_2019 <- cost_data_2019 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Predominantly White",
      perc_POC >= 0.6 ~ "Predominantly People of Color",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "No Predominant Racial Group",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

trips_data_2015 <- trips_data_2015 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Predominantly White",
      perc_POC >= 0.6 ~ "Predominantly People of Color",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "No Predominant Racial Group",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

trips_data_2019 <- trips_data_2019 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Predominantly White",
      perc_POC >= 0.6 ~ "Predominantly People of Color",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "No Predominant Racial Group",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

############################################################################
############################################################################
############################################################################
##########################################################################
###################################################################

# 3a. Collapse to the county level to create ALL values (to be appended later)

cost_all_15 <- cost_data_2015 %>%
  group_by(state, county) %>%
  summarize(transit_cost = weighted.mean(x = transit_cost_80ami, w = households, na.rm = TRUE)) %>%
  mutate(subgroup_type = "race-ethnicity",
         subgroup = "All")

cost_all_19 <- cost_data_2019 %>%
  group_by(state, county) %>%
  summarize(transit_cost = weighted.mean(x = transit_cost_80ami, w = households, na.rm = TRUE)) %>%
  mutate(subgroup_type = "race-ethnicity",
         subgroup = "All")

trips_all_15 <- trips_data_2015 %>%
  group_by(state, county) %>%
  summarize(transit_trips = weighted.mean(x = transit_trips_80ami, w = households, na.rm = TRUE)) %>%
  mutate(subgroup_type = "race-ethnicity",
         subgroup = "All")

trips_all_19 <- trips_data_2019 %>%
  group_by(state, county) %>%
  summarize(transit_trips = weighted.mean(x = transit_trips_80ami, w = households, na.rm = TRUE)) %>%
  mutate(subgroup_type = "race-ethnicity",
         subgroup = "All")


# 3b. Collapse accordingly -- to counties and race categories, weighting the measured by HH count per tract

cost_by_race_15 <- cost_data_2015 %>%
  group_by(state, county, race_category) %>%
  summarize(transit_cost = weighted.mean(x = transit_cost_80ami, w = households, na.rm = TRUE))

cost_by_race_19 <- cost_data_2019 %>%
  group_by(state, county, race_category) %>%
  summarize(transit_cost = weighted.mean(x = transit_cost_80ami, w = households, na.rm = TRUE))

trips_by_race_15 <- trips_data_2015 %>%
  group_by(state, county, race_category) %>%
  summarize(transit_trips = weighted.mean(x = transit_trips_80ami, w = households, na.rm = TRUE))

trips_by_race_19 <- trips_data_2019 %>%
  group_by(state, county, race_category) %>%
  summarize(transit_trips = weighted.mean(x = transit_trips_80ami, w = households, na.rm = TRUE))

# Make sure we have 3 race vars accounted for each county - create dummy df for merging purposes
county_expander <- expand_grid(
  count(cost_by_race_15, state, county) %>% select(-n),
  race_category = c("Predominantly White", "Predominantly People of Color", "No Predominant Racial Group")
)

# merge all four datasets into this dummy to account for all race categories
cost_by_race_15 <- left_join(county_expander, cost_by_race_15, by = c("state", "county", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)
# 9429 obs - 3*3143 counties - good

cost_by_race_19 <- left_join(county_expander, cost_by_race_19, by = c("state", "county", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)

trips_by_race_15 <- left_join(county_expander, trips_by_race_15, by = c("state", "county", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)

trips_by_race_19 <- left_join(county_expander, trips_by_race_19, by = c("state", "county", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)

# remove dummy df
rm(county_expander)

###################################################################

# 4. QC checks
# create a histogram plot and summary stats for each dataframe
# check that all values are non-negative & count missing values
# examine outliers

# Cost 2015
#############################
# look at histograms
# County-Level Transit Cost 2015 by Race Category (look at transit costs below $250 so we can
# actually see something; above 250, we have already explored outliers above)
ggplot(subset(cost_by_race_15, transit_cost < 250), aes(x = transit_cost, fill = race_category)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Cost (Below 250) by Race Category, 2015",
       x = "Transit Cost",
       y = "Frequency") +
  facet_wrap(~race_category, scales = "fixed")

# look at summary stats
summary_by_race <- cost_by_race_15 %>%
  group_by(race_category) %>%
  summarise(
    count = n(),
    mean = mean(transit_cost, na.rm = TRUE),
    median = median(transit_cost, na.rm = TRUE),
    min = min(transit_cost, na.rm = TRUE),
    max = max(transit_cost, na.rm = TRUE),
    sd = sd(transit_cost, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
cost_by_race_2015_outliers <- cost_by_race_15 %>% 
  filter(transit_cost>250) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(cost_by_race_15$transit_cost, na.rm = TRUE) >= 0)
# Good to go



# Cost 2019
#############################
# look at histograms
# County-Level Transit Cost 2019 by Race Category (look at transit costs below $250 so we can
# actually see something; above 250, we have already explored outliers above)
ggplot(subset(cost_by_race_19, transit_cost < 250), aes(x = transit_cost, fill = race_category)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Cost (Below 250) by Race Category, 2019",
       x = "Transit Cost",
       y = "Frequency") +
  facet_wrap(~race_category, scales = "fixed")

# look at summary stats
summary_by_race <- cost_by_race_19 %>%
  group_by(race_category) %>%
  summarise(
    count = n(),
    mean = mean(transit_cost, na.rm = TRUE),
    median = median(transit_cost, na.rm = TRUE),
    min = min(transit_cost, na.rm = TRUE),
    max = max(transit_cost, na.rm = TRUE),
    sd = sd(transit_cost, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
cost_by_race_2019_outliers <- cost_by_race_19 %>% 
  filter(transit_cost>250) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(cost_by_race_19$transit_cost, na.rm = TRUE) >= 0)
# Good to go



# Trips 2015
#############################
# look at histograms
# County-Level Transit Trips 2015 by Race Category (look at transit costs below 100 trips so we can
# actually see something; above 100, we have already explored outliers above)
ggplot(subset(trips_by_race_15, transit_trips<100), aes(x = transit_trips, fill = race_category)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Trips (below 100) by Race Category, 2015",
       x = "Transit Trips",
       y = "Frequency") +
  facet_wrap(~race_category, scales = "fixed")

# look at summary stats
summary_by_race <- trips_by_race_15 %>%
  group_by(race_category) %>%
  summarise(
    count = n(),
    mean = mean(transit_trips, na.rm = TRUE),
    median = median(transit_trips, na.rm = TRUE),
    min = min(transit_trips, na.rm = TRUE),
    max = max(transit_trips, na.rm = TRUE),
    sd = sd(transit_trips, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
trips_by_race_2015_outliers <- trips_by_race_15 %>% 
  filter(transit_trips>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(trips_by_race_15$transit_trips, na.rm = TRUE) >= 0)
# Good to go



# Trips 2019
#############################
# look at histograms
# County-Level Transit Trips 2019 by Race Category (look at transit trips below 100 so we can
# actually see something; above 100, we have already explored outliers above)
ggplot(subset(trips_by_race_19, transit_trips < 100), aes(x = transit_trips, fill = race_category)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Trips (Below 100) by Race Category, 2019",
       x = "Transit Trips",
       y = "Frequency") +
  facet_wrap(~race_category, scales = "fixed")

# look at summary stats
summary_by_race <- trips_by_race_19 %>%
  group_by(race_category) %>%
  summarise(
    count = n(),
    mean = mean(transit_trips, na.rm = TRUE),
    median = median(transit_trips, na.rm = TRUE),
    min = min(transit_trips, na.rm = TRUE),
    max = max(transit_trips, na.rm = TRUE),
    sd = sd(transit_trips, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
trips_by_race_2019_outliers <- trips_by_race_19 %>% 
  filter(transit_trips>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(trips_by_race_19$transit_trips, na.rm = TRUE) >= 0)
# Good to go


###################################################################

# 5. Data Quality marker
# TBD I am confused how to approach this

###################################################################

# 6. Export

# Combine the All values with the Subgroup values by appending
cost_race_15 <- bind_rows(cost_all_15, cost_by_race_15)
cost_race_19 <- bind_rows(cost_all_19, cost_by_race_19)
trips_race_15 <- bind_rows(trips_all_15, trips_by_race_15)
trips_race_19 <- bind_rows(trips_all_19, trips_by_race_19)


# add a variable for the year of the data
cost_race_15 <- cost_race_15 %>%
  mutate(
    year = 2015
  )
cost_race_19 <- cost_race_19 %>%
  mutate(
    year = 2019
  )
trips_race_15 <- trips_race_15 %>%
  mutate(
    year = 2015
  )
trips_race_19 <- trips_race_19 %>%
  mutate(
    year = 2019
  )

# Combine the two years into one overall files for both variables
transit_cost_subgroup_county <- rbind(cost_race_15, cost_race_19)
transit_trips_subgroup_county <- rbind(trips_race_15, trips_race_19)


# Keep variables of interest and order them appropriately
#transit_trips_subgroup_county <- transit_trips_subgroup_county %>%
#  select(year, state, county, subgroup_type, subgroup, transit_trips, transit_trips_quality)
#transit_cost_subgroup_county <- transit_cost_subgroup_county %>%
#  select(year, state, county, subgroup_type, subgroup, transit_cost, transit_cost_quality)


# Save as non-subgroup all-year files
#write_csv(transit_trips_county, "06_neighborhoods/transit_trips_all_subgroups_county.csv")
#write_csv(transit_cost_county, "06_neighborhoods/transit_cost_all_subgroups_county.csv")  





