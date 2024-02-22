###################################################################

# Transit Metrics: Transportation Costs
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
# raw data lives in the Urban Box folder (replace USERNAME)
transport_county_2015 <- read_csv("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/htaindex2015_data_counties.csv")

# create correct FIPS columns
transport_county_2015 <- transport_county_2015 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

# keep only variables of interest
transportation_cost_county_2015 <- transport_county_2015 %>%
  select(state, county, blkgrps, population, households, t_80ami)



#2019
transport_county_2019 <- read_csv("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/htaindex2019_data_counties.csv")
transport_county_2019 <- transport_county_2019 %>%
  select(county, blkgrps, population, households, t_80ami)

# create correct FIPS columns
transport_county_2019 <- transport_county_2019 %>%
  mutate(
    state = substr(county, start = 2, stop = 3),
    county = substr(county, start = 4, stop = 6)
  )

# keep only variables of interest
transportation_cost_county_2019 <- transport_county_2019 %>%
  select(state, county, blkgrps, population, households, t_80ami)


# Compare to our official county file to make sure we have all counties accounted for
# Bring in the official county file
# you should already be in the project folder for this path to work
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
  

  # County-Level Transportation Cost 2015
ggplot(transportation_cost_county_2015, aes(x=t_80ami)) + geom_histogram(binwidth=10) + labs(y="number of counties", x="Annual Transit Cost for the Regional Moderate Income Household, 2015")
# look at summary stats
summary(transportation_cost_county_2015$t_80ami)  
# examine outliers
transportation_cost_county_2015_outliers <- transportation_cost_county_2015 %>% 
  filter(t_80ami>100) 
# no weird outliers

# Use stopifnot to check if all values in "transportation_cost_county_2015" are non-negative
stopifnot(min(transportation_cost_county_2015$t_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "t_80ami" variable
missing_indices <- which(is.na(transportation_cost_county_2015$t_80ami))
# Print observations with missing values
if (length(missing_indices) > 0) {
  cat("Observations with missing values for transit_cost_80ami:\n")
  print(transportation_cost_county_2015[missing_indices, , drop = FALSE])
} else {
  cat("No missing values for transportation_cost_county_2015\n")
}
# 1 missing value: Loving County, TX (48301 FIPS)



  # County-Level Transportation Cost 2019
ggplot(transportation_cost_county_2019, aes(x=t_80ami)) + geom_histogram(binwidth=10) + labs(y="number of counties", x="Annual Transit Cost for the Regional Moderate Income Household, 2019")
# look at summary stats
summary(transportation_cost_county_2019$t_80ami) 
# examine outliers
transportation_cost_county_2019_outliers <- transportation_cost_county_2019 %>% 
  filter(t_80ami>100) 
# no weird outliers

# Use stopifnot to check if all values in "transportation_cost_county_2019" are non-negative
stopifnot(min(transportation_cost_county_2019$t_80ami, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "transit_cost_80ami" variable
missing_indices <- which(is.na(transportation_cost_county_2019$t_80ami))
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
summary(transportation_cost_county_2015$households) 
summary(transportation_cost_county_2019$households) 

# we use a 30 HH cutoff for Data Quality 3 for the ACS variables, so for the sake of consistency, since none of 
# these are less than 30 (all minimum values are at least 30 HHs), Data Quality can be 1 for all these observations
# BUT ALSO, rename all the metrics variables to what we had before (transit_trips & transit_cost), so we can name
# the quality variable appropriately
transportation_cost_county_2015 <- transportation_cost_county_2015 %>% 
  rename(transit_cost = t_80ami) %>%
  mutate(transit_cost_quality = 1)
transportation_cost_county_2019 <- transportation_cost_county_2019 %>% 
  rename(transit_cost = t_80ami) %>%
  mutate(transit_cost_quality = 1)


###################################################################

# 4. Export final files

# add a variable for the year of the data
transportation_cost_county_2015 <- transportation_cost_county_2015 %>%
  mutate(
    year = 2015
  )
transportation_cost_county_2019 <- transportation_cost_county_2019 %>%
  mutate(
    year = 2019
  )

# Combine the two years into one overall files for both variables
transit_cost_county <- rbind(transportation_cost_county_2015, transportation_cost_county_2019)


# Keep variables of interest and order them appropriately
# also rename to correct var names
transit_cost_county <- transit_cost_county %>%
  rename(index_transportation_cost = transit_cost,
         index_transportation_cost_quality = transit_cost_quality) %>%
  select(year, state, county, index_transportation_cost, index_transportation_cost_quality) %>%
  arrange(year, state, county, index_transportation_cost, index_transportation_cost_quality)
  

# Save as non-subgroup all-year files
write_csv(transit_cost_county, "06_neighborhoods/Transportation/output/transit_cost_all_county.csv")  


  
  