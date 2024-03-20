############################################################

# SUBGROUP FILE - CITIES

# Process for SUBGROUP-level:
# 1. Import all the tract-level files and combine into one mega-file with only the relevant variables and years
# 2. Race-Ethnicity work: 
# 2a. Pull in that year's population by race via ACS (tract-level)
# 2b. for all tracts that are 60%+ of one race (or mixed) -- the buckets are: neighborhoods of color, white, and mixed
# 3. Collapse accordingly (by)
# 4. QC checks
# 5. Data Quality marker
# 6. Export
###################################################################

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)
library(ggplot2)
library(tidyverse)
library(purrr)
library(tidycensus)

###################################################################

# 1. Import all the tract-level files and combine into one mega-file with only the relevant variables and years

# 2015
# bring in all the downloaded CSVs (state-level tracts) & combine them into one nation-wide file for tracts
tracts15files <- list.files(path="C:/Users/USERNAME/Box/Lab/Projects/Gates Upward Mobility Framework/Outreach and Tools/Data/Metrics_2024_round/Transportation/2015_tract/",
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
missing_count <- sum(is.na(cost_data_2015$t_80ami))
cat("Number of missing values for t_80ami:", missing_count, "\n")
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
missing_count <- sum(is.na(cost_data_2019$t_80ami))
cat("Number of missing values for t_80ami:", missing_count, "\n")
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
  mutate(
    perc_white = if_else(
      complete.cases(total_population, white_population),
      if_else(population > 0, white_population / total_population, 0),
      NA_real_
    ), 
    perc_POC = if_else(
      complete.cases(total_population, black_population, asian_population, aian_population, nhpi_population, other_population),
      if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0),
      NA_real_
    )
  )

cost_data_2019 <- cost_data_2019 %>%
  mutate(
    perc_white = if_else(
      complete.cases(total_population, white_population),
      if_else(population > 0, white_population / total_population, 0),
      NA_real_
    ), 
    perc_POC = if_else(
      complete.cases(total_population, black_population, asian_population, aian_population, nhpi_population, other_population),
      if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0),
      NA_real_
    )
  )

trips_data_2015 <- trips_data_2015 %>%
  mutate(
    perc_white = if_else(
      complete.cases(total_population, white_population),
      if_else(population > 0, white_population / total_population, 0),
      NA_real_
    ), 
    perc_POC = if_else(
      complete.cases(total_population, black_population, asian_population, aian_population, nhpi_population, other_population),
      if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0),
      NA_real_
    )
  )

trips_data_2019 <- trips_data_2019 %>%
  mutate(
    perc_white = if_else(
      complete.cases(total_population, white_population),
      if_else(population > 0, white_population / total_population, 0),
      NA_real_
    ), 
    perc_POC = if_else(
      complete.cases(total_population, black_population, asian_population, aian_population, nhpi_population, other_population),
      if_else(population > 0, ((black_population + asian_population + aian_population + nhpi_population + other_population) / total_population), 0),
      NA_real_
    )
  )


# Assign race-category for each tract
# If 0.6+ White, assign Majority White NH, if 0.6+ POC, assign Predominantly POC
# 40-60% White or POC, assign No Predominant Racial Group

# subgroup_type=race-ethnicity; 
# subgroup=All ZIPs, Majority White-NH Tracts; Majority Non-White Tracts; Mixed Race and Ethnicity Tracts

cost_data_2015 <- cost_data_2015 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Majority White-NH Tracts",
      perc_POC >= 0.6 ~ "Majority Non-White Tracts",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "Mixed Race and Ethnicity Tracts",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

cost_data_2019 <- cost_data_2019 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Majority White-NH Tracts",
      perc_POC >= 0.6 ~ "Majority Non-White Tracts",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "Mixed Race and Ethnicity Tracts",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

trips_data_2015 <- trips_data_2015 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Majority White-NH Tracts",
      perc_POC >= 0.6 ~ "Majority Non-White Tracts",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "Mixed Race and Ethnicity Tracts",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

trips_data_2019 <- trips_data_2019 %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Majority White-NH Tracts",
      perc_POC >= 0.6 ~ "Majority Non-White Tracts",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "Mixed Race and Ethnicity Tracts",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    ))

############################################################################
############################################################################
############################################################################
##########################################################################
###################################################################

# 3a. Collapse to the CITY level to create ALL values (to be appended later)

# FIRST: Bring in the needed crosswalks 
# 2015 place-tract, 2019 place-tract are both covered by our 2018 tract to place crosswalk, since tract designations are only updated on the decade (e.g., 2010, 2020)
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
  rename(place = placefp) %>%
  select(state, county, tract, place, afact)

# merge it into each of our four data files so that we have what we need for the city-level collapse
cost_data_2015 <- left_join(cost_data_2015, tract_place, by=c("state", "county", "tract"))
cost_data_2019 <- left_join(cost_data_2019, tract_place, by=c("state", "county", "tract"))
trips_data_2015 <- left_join(trips_data_2015, tract_place, by=c("state", "county", "tract"))
trips_data_2019 <- left_join(trips_data_2019, tract_place, by=c("state", "county", "tract"))
# 73056 obs to 124139 obs - makes sense as tracts and places don't match up perfectly, so there's multiplicity


# NOW, collapse by place(s) for each of our four data files
# weight the collapse by households*afact (the amount of each tract that falls into the place x the number of households represented by the estimate)
# add quality variable =1 when more than half of the tracts that were collapsed 
# are 50%+ in the Place, and =2 when less than half the tracts that are collapsed per place are <50% in the Place
cost_all_15 <- cost_data_2015 %>%
  group_by(state, place) %>%
  summarize(
    index_transportation_cost = weighted.mean(x = t_80ami, w = households * afact, na.rm = TRUE),
    n = n(),
    dq = sum(afact > 0.5, na.rm = TRUE)
  ) %>%
  mutate(
    subgroup_type = "race-ethnicity",
    subgroup = "All",
    index_transportation_cost_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )

cost_all_19 <- cost_data_2019 %>%
  group_by(state, place) %>%
  summarize(
    index_transportation_cost = weighted.mean(x = t_80ami, w = households * afact, na.rm = TRUE),
    n = n(),
    dq = sum(afact > 0.5, na.rm = TRUE)
  ) %>%
  mutate(
    subgroup_type = "race-ethnicity",
    subgroup = "All",
    index_transportation_cost_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )

trips_all_15 <- trips_data_2015 %>%
  group_by(state, place) %>%
  summarize(index_transit_trips = sum(transit_trips_80ami*households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
            ) %>%
  mutate(
      subgroup_type = "race-ethnicity",
      subgroup = "All",
      index_transit_trips_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
      )

trips_all_19 <- trips_data_2019 %>%
  group_by(state, place) %>%
  summarize(index_transit_trips = sum(transit_trips_80ami*households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
  ) %>%
  mutate(
    subgroup_type = "race-ethnicity",
    subgroup = "All",
    index_transit_trips_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )


# Now make sure to change the trips (both years) to national percentile ranks

trips_all_15 <- trips_all_15 %>%
  mutate(
    rank = rank(index_transit_trips),
    percentile_rank = ((rank - 1) / (sum(!is.na(index_transit_trips)) - 1)) * 100,
    index_transit_trips = round(percentile_rank, 2),
    index_transit_trips_quality = index_transit_trips_quality
  ) %>%
  select(state, place, subgroup_type, subgroup, index_transit_trips, index_transit_trips_quality) %>%
  mutate(index_transit_trips_quality = ifelse(is.na(index_transit_trips), NA, index_transit_trips_quality))


trips_all_19 <- trips_all_19 %>%
  mutate(
    rank = rank(index_transit_trips),
    percentile_rank = ((rank - 1) / (sum(!is.na(index_transit_trips)) - 1)) * 100,
    index_transit_trips = round(percentile_rank, 2),
    index_transit_trips_quality = index_transit_trips_quality
  ) %>%
  select(state, place, subgroup_type, subgroup, index_transit_trips, index_transit_trips_quality) %>%
  mutate(index_transit_trips_quality = ifelse(is.na(index_transit_trips), NA, index_transit_trips_quality))



# 3b. Collapse to the CITY level to create RACE-BASED values (to be appended later)
# Collapse to places and race categories, weighting the measure by HH count x afact per tract

cost_by_race_15 <- cost_data_2015 %>%
  group_by(state, place, race_category) %>%
  summarize(transportation_cost = weighted.mean(x = t_80ami, w = households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
            ) %>%
  mutate(
    index_transportation_cost_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )


cost_by_race_19 <- cost_data_2019 %>%
  group_by(state, place, race_category) %>%
  summarize(transportation_cost = weighted.mean(x = t_80ami, w = households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
            )%>%
  mutate(
    index_transportation_cost_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )

trips_by_race_15 <- trips_data_2015 %>%
  group_by(state, place, race_category) %>%
  summarize(transit_trips = sum(transit_trips_80ami*households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
            )%>%
  mutate(
    index_transit_trips_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )

trips_by_race_19 <- trips_data_2019 %>%
  group_by(state, place, race_category) %>%
  summarize(transit_trips = sum(transit_trips_80ami*households*afact, na.rm = TRUE),
            n = n(),
            dq = sum(afact > 0.5, na.rm = TRUE)
            )%>%
  mutate(
    index_transit_trips_quality = ifelse(dq / n >= 0.5, 1, ifelse(dq / n < 0.5, 2, NA))
  )


# Make sure we have 3 race vars accounted for each place - create dummy df for merging purposes
place_expander <- expand_grid(
  count(cost_by_race_15, state, place) %>% select(-n),
  race_category = c("Majority White-NH Tracts", "Majority Non-White Tracts", "Mixed Race and Ethnicity Tracts")
)

# merge all four datasets into this dummy to account for all race categories
cost_by_race_15 <- left_join(place_expander, cost_by_race_15, by = c("state", "place", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category,
         index_transportation_cost = transportation_cost)

cost_by_race_19 <- left_join(place_expander, cost_by_race_19, by = c("state", "place", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category,
         index_transportation_cost = transportation_cost)

trips_by_race_15 <- left_join(place_expander, trips_by_race_15, by = c("state", "place", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)

trips_by_race_19 <- left_join(place_expander, trips_by_race_19, by = c("state", "place", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)

# remove dummy df
rm(place_expander)



# CHANGE THE TRIPS VALUES TO NATIONAL PERCENTILE RANKS FOR EACH PLACE
# For 2015 data
trips_by_race_15 <- trips_by_race_15 %>%
  group_by(subgroup) %>%
  mutate(
    rank = if_else(!is.na(transit_trips), 
                   rank(transit_trips),
                   NA_real_),
    percentile_rank = if_else(!is.na(rank),
                              (rank - 1) / (sum(!is.na(rank)) - 1) * 100,
                              NA_real_),
    percentile_rank = if_else(!is.na(percentile_rank),
                              round(percentile_rank, 2),
                              NA_real_)
  )

trips_by_race_15 <- trips_by_race_15 %>%
  rename(index_transit_trips = percentile_rank) %>%
  select(state, place, subgroup, subgroup_type, index_transit_trips, index_transit_trips_quality)



# For 2019 data
trips_by_race_19 <- trips_by_race_19 %>%
  group_by(subgroup) %>%
  mutate(
    rank = if_else(!is.na(transit_trips), 
                   rank(transit_trips),
                   NA_real_),
    percentile_rank = if_else(!is.na(rank),
                              (rank - 1) / (sum(!is.na(rank)) - 1) * 100,
                              NA_real_),
    percentile_rank = if_else(!is.na(percentile_rank),
                              round(percentile_rank, 2),
                              NA_real_)
  )

trips_by_race_19 <- trips_by_race_19 %>%
  rename(index_transit_trips = percentile_rank) %>%
  select(state, place, subgroup, subgroup_type, index_transit_trips, index_transit_trips_quality)




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
ggplot(subset(cost_by_race_15, index_transportation_cost>0), aes(x = index_transportation_cost, fill = subgroup)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Cost by Race Category, 2015",
       x = "Transit Cost",
       y = "Frequency") +
  facet_wrap(~subgroup, scales = "fixed")
# looks about right -- similar range across all three groups, way more majority-White tracts (as expected)

# look at summary stats
summary_by_race <- cost_by_race_15 %>%
  group_by(subgroup) %>%
  summarise(
    count = n(),
    mean = mean(index_transportation_cost, na.rm = TRUE),
    median = median(index_transportation_cost, na.rm = TRUE),
    min = min(index_transportation_cost, na.rm = TRUE),
    max = max(index_transportation_cost, na.rm = TRUE),
    sd = sd(index_transportation_cost, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
cost_by_race_2015_outliers <- cost_by_race_15 %>% 
  filter(index_transportation_cost>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(cost_by_race_15$index_transportation_cost, na.rm = TRUE) >= 0)
# Good to go



# Cost 2019
#############################
# look at histograms
# County-Level Transit Cost 2019 by Race Category (look at transit costs below $250 so we can
# actually see something; above 250, we have already explored outliers above)
ggplot(subset(cost_by_race_19, index_transportation_cost>0), aes(x = index_transportation_cost, fill = subgroup)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Cost by Race Category, 2019",
       x = "Transit Cost",
       y = "Frequency") +
  facet_wrap(~subgroup, scales = "fixed")
# looks about right -- similar range across all three groups, way more majority-White tracts (as expected)

# look at summary stats
summary_by_race <- cost_by_race_19 %>%
  group_by(subgroup) %>%
  summarise(
    count = n(),
    mean = mean(index_transportation_cost, na.rm = TRUE),
    median = median(index_transportation_cost, na.rm = TRUE),
    min = min(index_transportation_cost, na.rm = TRUE),
    max = max(index_transportation_cost, na.rm = TRUE),
    sd = sd(index_transportation_cost, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
cost_by_race_2019_outliers <- cost_by_race_19 %>% 
  filter(index_transportation_cost>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(cost_by_race_19$index_transportation_cost, na.rm = TRUE) >= 0)
# Good to go



# Trips 2015
#############################
# look at histograms
# County-Level Transit Trips 2015 by Race Category (look at transit costs below 100 trips so we can
# actually see something; above 100, we have already explored outliers above)
ggplot(subset(trips_by_race_15, index_transit_trips>0), aes(x = index_transit_trips, fill = subgroup)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Trips by Race Category, 2015",
       x = "Transit Trips",
       y = "Frequency") +
  facet_wrap(~subgroup, scales = "fixed")

# look at summary stats
summary_by_race <- trips_by_race_15 %>%
  group_by(subgroup) %>%
  summarise(
    count = n(),
    mean = mean(index_transit_trips, na.rm = TRUE),
    median = median(index_transit_trips, na.rm = TRUE),
    min = min(index_transit_trips, na.rm = TRUE),
    max = max(index_transit_trips, na.rm = TRUE),
    sd = sd(index_transit_trips, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
trips_by_race_2015_outliers <- trips_by_race_15 %>% 
  filter(index_transit_trips>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(trips_by_race_15$index_transit_trips, na.rm = TRUE) >= 0)
# Good to go



# Trips 2019
#############################
# look at histograms
# County-Level Transit Trips 2019 by Race Category (look at transit trips below 100 so we can
# actually see something; above 100, we have already explored outliers above)
ggplot(subset(trips_by_race_19, index_transit_trips>0), aes(x = index_transit_trips, fill = subgroup)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Histogram of Transit Trips by Race Category, 2019",
       x = "Transit Trips",
       y = "Frequency") +
  facet_wrap(~subgroup, scales = "fixed")

# look at summary stats
summary_by_race <- trips_by_race_19 %>%
  group_by(subgroup) %>%
  summarise(
    count = n(),
    mean = mean(index_transit_trips, na.rm = TRUE),
    median = median(index_transit_trips, na.rm = TRUE),
    min = min(index_transit_trips, na.rm = TRUE),
    max = max(index_transit_trips, na.rm = TRUE),
    sd = sd(index_transit_trips, na.rm = TRUE)
  )

print(summary_by_race)

# examine outliers
trips_by_race_2019_outliers <- trips_by_race_19 %>% 
  filter(index_transit_trips>100) 
# Nothing unexpected

# Use stopifnot to check if all values are non-negative
stopifnot(min(trips_by_race_19$index_transit_trips, na.rm = TRUE) >= 0)
# Good to go



###################################################################

# 5. Export


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
transit_cost_subgroup_city <- rbind(cost_race_15, cost_race_19)
transit_trips_subgroup_city <- rbind(trips_race_15, trips_race_19)


# Keep variables of interest and order them appropriately
transit_trips_subgroup_city <- transit_trips_subgroup_city %>%
  select(year, state, place, subgroup_type, subgroup, index_transit_trips, index_transit_trips_quality) %>%
  arrange(year, state, place, subgroup_type, subgroup)
transit_cost_subgroup_city <- transit_cost_subgroup_city %>%
  select(year, state, place, subgroup_type, subgroup, index_transportation_cost, index_transportation_cost_quality) %>%
  arrange(year, state, place, subgroup_type, subgroup)


# Keep only our cities of interest (486 of them from the places crosswalk)
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep the most recent year
places <- places %>%
  filter(year == 2019) %>%
  select(state, place)

# left join to limit to places of interest
transit_trips_subgroup_city <- left_join(places, transit_trips_subgroup_city, by = c("state", "place"))
# 234,544 obs to 3867 obs

transit_cost_subgroup_city <- left_join(places, transit_cost_subgroup_city, by = c("state", "place"))
# 234,544 obs to 3867 obs

# another place expander to account for the difference between 3867 and 3888 (what the count should be if all places accounted for)
place_expander <- expand_grid(
  count(places, state, place) %>% select(-n),
  race_category = c("All", "Majority White-NH Tracts", "Majority Non-White Tracts", "Mixed Race and Ethnicity Tracts")
)
#1944 obs

duplicated_expander <- bind_rows(place_expander, place_expander) %>%
  mutate(year = ifelse(row_number() <= nrow(place_expander), 2015, 2019)) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category)


# merge back in to account for missings
transit_trips_subgroup_city <- left_join(duplicated_expander, transit_trips_subgroup_city, by = c("year", "state", "place", "subgroup_type", "subgroup")) %>%
  arrange (year, state, place, subgroup_type, subgroup, index_transit_trips, index_transit_trips_quality)

transit_cost_subgroup_city <- left_join(duplicated_expander, transit_cost_subgroup_city, by = c("year", "state", "place", "subgroup_type", "subgroup")) %>%
  arrange (year, state, place, subgroup_type, subgroup, index_transportation_cost, index_transportation_cost_quality)
# 3867 obs to 3888 obs


# Save as non-subgroup all-year files
write_csv(transit_trips_subgroup_city, "06_neighborhoods/Transportation/final/transit_trips_all_subgroups_city.csv")
write_csv(transit_cost_subgroup_city, "06_neighborhoods/Transportation/final/transit_cost_all_subgroups_city.csv")  





