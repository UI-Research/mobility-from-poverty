###################################################################

# Transit Metrics: Transit Trips
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
transport_county_2015 <- read_csv("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/htaindex2015_data_counties.csv")

# create correct FIPS columns
transport_county_2015 <- transport_county_2015 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

# keep only variables of interest
transit_trips_county_2015 <- transport_county_2015 %>%
  select(state, county, blkgrps, population, households, transit_trips_80ami)


#2019
transport_county_2019 <- read_csv("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/htaindex2019_data_counties.csv")
transport_county_2019 <- transport_county_2019 %>%
  select(county, blkgrps, population, households, transit_trips_80ami)

# create correct FIPS columns
transport_county_2019 <- transport_county_2019 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

# keep only variables of interest
transit_trips_county_2019 <- transport_county_2019 %>%
  select(state, county, blkgrps, population, households, transit_trips_80ami)

# Compare to our official county file to make sure we have all counties accounted for
# Bring in the official county file
counties <- read_csv("geographic-crosswalks/data/county-populations.csv")
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
  filter(transit_trips_80ami>250) %>%
  arrange(desc(transit_trips_80ami))
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

#####################################################################

# Create national percentile ranking for 'transit_trips_80ami'
transit_trips_county_2015 <- transit_trips_county_2015 %>%
  mutate(rank = rank(transit_trips_80ami),
         percentile_rank = (rank - 1) / (n() - 1) * 100,
         percentile_rank = round(percentile_rank, 2)) %>%
  rename(index_transit_trips = percentile_rank)

transit_trips_county_2019 <- transit_trips_county_2019 %>%
  mutate(rank = rank(transit_trips_80ami),
         percentile_rank = (rank - 1) / (n() - 1) * 100,
         percentile_rank = round(percentile_rank, 2)) %>%
  rename(index_transit_trips = percentile_rank)

###################################################################

# 3. Data Quality marker

# Determine data quality cutoffs based on number of observations (all at the HH level for these values)
summary(transit_trips_county_2015$households) 
summary(transit_trips_county_2019$households) 

# we use a 30 HH cutoff for Data Quality 3 for the ACS variables, so for the sake of consistency, since none of 
# these are less than 30 (all minimum values are at least 30 HHs), Data Quality can be 1 for all these observations
transit_trips_county_2015 <- transit_trips_county_2015 %>% 
  mutate(index_transit_trips_quality = 1)

transit_trips_county_2019 <- transit_trips_county_2019 %>% 
  mutate(index_transit_trips_quality = 1)


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


# Combine the two years into one overall file
transit_trips_county <- rbind(transit_trips_county_2015, transit_trips_county_2019)


# Keep variables of interest and order them appropriately
transit_trips_county <- transit_trips_county %>%
  select(year, state, county, index_transit_trips, index_transit_trips_quality) %>%
  arrange(year, state, county, index_transit_trips, index_transit_trips_quality)
  

# Save as non-subgroup all-year files
write_csv(transit_trips_county, "06_neighborhoods/Transportation/final/transit_trips_all_county.csv")


############################################################