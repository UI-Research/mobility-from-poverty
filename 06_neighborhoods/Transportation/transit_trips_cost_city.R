

###################################################################

# Transit Metrics: Transportation Costs & Trips - CITY LEVEL
# SAME Process (for overall, not subgroup, data):
# 1. For City: Import and reshape data
# 2. Crosswalk to the cities (from tracts) & aggregate data
# 3. QC checks
# 4. Add Data Quality marker
# 5. Export final files

###################################################################

# SUMMARY-LEVEL VALUES
# Raw data pulled from https://htaindex.cnt.org/download/
# the Housing and Transportation (H+T) Affordability Index from the Center for Neighborhood Technology (CNT)

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)
library(ggplot2)
library(tidyverse)
library(purrr)

###################################################################
###################################################################

# 1. Import all the tract-level files and combine into one mega-file with only the relevant variables and years

# 2015
# bring in all the downloaded CSVs (state-level tracts) & combine them into one nation-wide file for tracts
# these files can be found in the Urban Box folder -- replace USERNAME
tracts15files <- list.files(path="C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/2015_tract",
                            pattern="*.csv")
print(tracts15files)
tractpath15 = file.path("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/2015_tract",tracts15files)
print(tractpath15)
transport_tracts_2015 <- map_df(tractpath15, read_csv)


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
  select(GEOID, state, county, tract, blkgrps, population, households, t_80ami)



# 2019
# bring in all the downloaded CSVs (state-level tracts) & combine them into one nation-wide file for tracts
tracts19files <- list.files(path="C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/2019_tract/",
                            pattern="*.csv")
print(tracts19files)
tractpath19 = file.path("C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/2019_tract",tracts19files)
print(tractpath19)
transport_tracts_2019 <- map_df(tractpath19, read_csv)

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
  select(GEOID, state, county, tract, blkgrps, population, households, t_80ami)


###################################################################

# 2. Crosswalk to the cities (from tracts) & aggregate data

# bring in the crosswalk of interest (we want the year range to be before 2020, when tract definitions changed)
tract_place <- read_csv("geographic-crosswalks/data/geocorr2018_tract_to_place.csv")
# remove the decimal from the tract variable
tract_place <- tract_place %>%
  mutate(tract = tract*100)
# add in leading zeroes as needed
tract_place <- tract_place %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)),
         tract = sprintf("%0.6d", as.integer(as.character(tract))),
         placefp = sprintf("%0.5d", as.numeric(placefp)),
         county = substr(county, nchar(county) - 2, nchar(county))
  ) %>%
  rename(place = placefp)


# NOW, aggregate the tract-level data to the place levels for each variable for each year

# For when we want to: Limit to the Census Places we want 
# first, bring in the places crosswalk (place-populations.csv)
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the most relevant year
places <- places %>%
  filter(year == 2019)


# TRANSPORTATION COST 2015
transit_cost_city_2015 <- left_join(transit_cost_tracts_2015, tract_place, by=c("state", "county", "tract"))
# collapse to places and also create data quality marker
# data quality can be 1 when most of the tracts that fall in the place (e.g., >50% of the tracts) 
# have most of their area falling in the place (e.g., >50% of the tract's area is in the place)
# otherwise, data quality is 2
transit_cost_city_2015 <- transit_cost_city_2015 %>% 
  dplyr::group_by(state, place) %>% 
  dplyr::summarize(index_transportation_cost = round(weighted.mean(t_80ami, w = afact, na.rm = TRUE), 2),
                   n = n(),
                   dq = sum(afact > 0.5, na.rm = TRUE)
  )%>%
  dplyr::mutate(index_transportation_cost_quality = ifelse(dq / n > 0.5, 1, ifelse(dq / n <= 0.5, 2, NA)))


# left join with places file to get rid of irrelevant places data
transit_cost_city_2015 <- left_join(places, transit_cost_city_2015, by=c("state","place"))
# 29317 obs to 486 obs

# keep only the variables we will need & replace NA qual vars where there is NA metric value
transit_cost_city_2015 <- transit_cost_city_2015 %>% 
  mutate(year=2015)%>%
  select(year, state, place, index_transportation_cost, index_transportation_cost_quality)%>%
  dplyr::mutate(index_transportation_cost_quality = ifelse(is.na(index_transportation_cost), NA, index_transportation_cost_quality))



# TRANSPORTATION COST 2019
transit_cost_city_2019 <- left_join(transit_cost_tracts_2019, tract_place, by=c("state", "county","tract"))
# collapse to places and also create data quality marker
transit_cost_city_2019 <- transit_cost_city_2019 %>% 
  dplyr::group_by(state, place) %>% 
  dplyr::summarize(index_transportation_cost = round(weighted.mean(t_80ami, w = afact, na.rm = TRUE), 2),
                   n = n(),
                   dq = sum(afact > 0.5, na.rm = TRUE)
  )%>%
  dplyr::mutate(index_transportation_cost_quality = ifelse(dq / n > 0.5, 1, ifelse(dq / n <= 0.5, 2, NA)))

# left join with places file to get rid of irrelevant places data
transit_cost_city_2019 <- left_join(places, transit_cost_city_2019, by=c("state","place"))
# 29317 obs to 486 obs
# keep only the variables we will need & replace NA qual vars where there is NA metric value
transit_cost_city_2019 <- transit_cost_city_2019 %>% 
  mutate(year=2019)%>%
  select(year, state, place, index_transportation_cost, index_transportation_cost_quality)%>%
  dplyr::mutate(index_transportation_cost_quality = ifelse(is.na(index_transportation_cost), NA, index_transportation_cost_quality))



# TRANSIT TRIPS 2015
transit_trips_city_2015 <- left_join(transit_trips_tracts_2015, tract_place, by=c("state", "county","tract"))
# collapse to places and also create data quality marker
# data quality can be 1 when most of the tracts that fall in the place (e.g., >50% of the tracts) 
# have most of their area falling in the place (e.g., >50% of the tract's area is in the place)
# otherwise, data quality is 2
transit_trips_city_2015 <- transit_trips_city_2015 %>% 
  dplyr::group_by(state, place) %>% 
  dplyr::summarize(index_transit_trips = weighted.sum(transit_trips_80ami, w = afact, na.rm = TRUE),
                   n = n(),
                   dq = sum(afact > 0.5, na.rm = TRUE)
  )

# calculate the national percentile ranks
transit_trips_city_2015 <- transit_trips_city_2015 %>%
  mutate(
    rank = rank(index_transit_trips),
    percentile_rank = ((rank - 1) / (n() - 1)) * 100,
    index_transit_trips = round(percentile_rank, 2)
  )%>%
  dplyr::mutate(index_transit_trips_quality = ifelse(dq / n > 0.5, 1, ifelse(dq / n <= 0.5, 2, NA)))


# left join with places file to get rid of irrelevant places data
transit_trips_city_2015 <- left_join(places, transit_trips_city_2015, by=c("state","place"))
# 29317 obs to 486 obs

# keep only the variables we will need & replace NA qual vars where there is NA metric value
transit_trips_city_2015 <- transit_trips_city_2015 %>% 
  mutate(year==2015)%>%
  select(year, state, place, index_transit_trips, index_transit_trips_quality)%>%
  dplyr::mutate(index_transit_trips_quality = ifelse(is.na(index_transit_trips), NA, index_transit_trips_quality))



# TRANSIT TRIPS 2019
transit_trips_city_2019 <- left_join(transit_trips_tracts_2019, tract_place, by=c("state", "county","tract"))
# collapse to places and also create data quality marker
# data quality can be 1 when most of the tracts that fall in the place (e.g., >50% of the tracts) 
# have most of their area falling in the place (e.g., >50% of the tract's area is in the place)
# otherwise, data quality is 2
transit_trips_city_2019 <- transit_trips_city_2019 %>% 
  dplyr::group_by(state, place) %>% 
  dplyr::summarize(index_transit_trips = weighted.sum(transit_trips_80ami, w = afact, na.rm = TRUE),
                   n = n(),
                   dq = sum(afact > 0.5, na.rm = TRUE)
  )

# calculate the national percentile ranks
transit_trips_city_2019 <- transit_trips_city_2019 %>%
  mutate(
    rank = rank(index_transit_trips),
    percentile_rank = ((rank - 1) / (n() - 1)) * 100,
    index_transit_trips = round(percentile_rank, 2)
  )%>%
  dplyr::mutate(index_transit_trips_quality = ifelse(dq / n > 0.5, 1, ifelse(dq / n <= 0.5, 2, NA)))


# left join with places file to get rid of irrelevant places data
transit_trips_city_2019 <- left_join(places, transit_trips_city_2019, by=c("state","place"))
# 29317 obs to 486 obs

# keep only the variables we will need & replace NA qual vars where there is NA metric value
transit_trips_city_2019 <- transit_trips_city_2019 %>% 
  mutate(year==2019)%>%
  select(year, state, place, index_transit_trips, index_transit_trips_quality)%>%
  dplyr::mutate(index_transit_trips_quality = ifelse(is.na(index_transit_trips), NA, index_transit_trips_quality))


###################################################################

# 3. QC Checks
# create a histogram plot and summary stats for each dataframe
# check that all values are non-negative & count missing values
# examine outliers


# City-Level Transportation Cost
##############################################
ggplot(transit_cost_city_2015, aes(x=index_transportation_cost)) + geom_histogram(binwidth=10) + labs(y="number of places", x="Annual Transit Cost for the Regional Moderate Income Household, 2015")
ggplot(transit_cost_city_2019, aes(x=index_transportation_cost)) + geom_histogram(binwidth=10) + labs(y="number of places", x="Annual Transit Cost for the Regional Moderate Income Household, 2019")

# look at summary stats
summary(transit_cost_city_2015$index_transportation_cost)  
summary(transit_cost_city_2019$index_transportation_cost)
# no weird outliers

# Use stopifnot to check if all values in "transit_cost_city_XXXX" are non-negative
stopifnot(min(transit_cost_city_2015$index_transportation_cost, na.rm = TRUE) >= 0)
# Good to go
stopifnot(min(transit_cost_city_2019$index_transportation_cost, na.rm = TRUE) >= 0)
# Good to go

# Find indices of missing values for the "index_transportation_cost" variable
missing_indices15 <- which(is.na(transit_cost_city_2015$index_transportation_cost))
missing_indices19 <- which(is.na(transit_cost_city_2019$index_transportation_cost))

# Print observations with missing values
if (length(missing_indices15) > 0) {
  cat("Observations with missing values for index_transportation_cost:\n")
  print(transit_cost_city_2015[missing_indices15, , drop = FALSE])
} else {
  cat("No missing values for transportation_cost_county_2015\n")
}
# 77 missing values

if (length(missing_indices19) > 0) {
  cat("Observations with missing values for index_transportation_cost:\n")
  print(transit_cost_city_2019[missing_indices19, , drop = FALSE])
} else {
  cat("No missing values for transportation_cost_county_2019\n")
}
# 75 missing values


###################################################################

# 5. Export final files


# Combine the two years into one overall files for both variables
transit_cost_city <- rbind(transit_cost_city_2015, transit_cost_city_2019)
transit_trips_city <- rbind(transit_trips_city_2015, transit_trips_city_2019)


# Save as non-subgroup all-year files
write_csv(transit_cost_city, "06_neighborhoods/Transportation/final/transit_cost_all_city.csv")  
write_csv(transit_trips_city, "06_neighborhoods/Transportation/final/transit_trips_all_city.csv")  


