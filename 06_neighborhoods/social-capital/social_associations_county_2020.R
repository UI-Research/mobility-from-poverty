###############################################################################

# Description: Code to create county-level Social Associatations ratio (one of two Social Capital Gates Mobility Metrics)
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/cbp20co.csv (won't be on Github)
# Data downloaded from: Census County Business Patterns 2020
# Author: Tina Chelidze
# Date: December 10, 2022

# (1)  download social organization data from https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html (this is the numerator)
# (2)  import and clean the data file
# (3)  download population data from ACS (this is the denominator)
# (4)  merge the data file(s) & construct the ratio (Numerator/Denominator)
# (5)  final file cleaning and export to .csv file

###############################################################################

# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)

# (1) download data from the Census County Business Patterns survey

#     access via https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html
# Specify URL where source data file is online
url <- "https://www2.census.gov/programs-surveys/cbp/datasets/2020/cbp20co.zip"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "06_neighborhoods/social-capital/temp/cbp20co.zip"

# Import the data file & save locally
download.file(url, destfile)

# Extract the text file from the ZIP file
unzip("06_neighborhoods/social-capital/temp/cbp20co.zip", files = "cbp20co.txt", exdir = "06_neighborhoods/social-capital/temp")


# (2) import and clean the CBP data file

# This means a) open the data, b) fill in fips missing zeroes, c) isolate to only the following NAICS,
# d) collapse & keep only relevant variables, and e) add the year of these data

# codes: 813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, and 813920
# These are the codes/associations included in the County Health Rankings metric
# See here for more: https://www.countyhealthrankings.org/explore-health-rankings/county-health-rankings-model/health-factors/social-economic-factors/family-and-social-support/social-associations?year=2022
sa_raw <- getCensus(
  name = "cbp",
  vintage = 2020,
  vars = c("EMP", "ESTAB", "NAICS2017"),
  region = "county:*"
) %>% 
  as_tibble() %>% 
  filter(NAICS2017 %in% naics_codes_to_keep) %>% 
  select(state, county, orgs = ESTAB) %>% 
  drop_na(orgs) %>% 
  summarise(count_orgs = sum(orgs), .by = c("state", "county")) %>% 
  mutate(year = 2020) %>% 
  rename(fipstate = state, fipscty = county, est = orgs)

# a) open the data
# Read in the TXT file as df
# sa_raw <- read.table("06_neighborhoods/social-capital/temp/cbp20co.txt",
#   header = TRUE,
#   sep = ","
# )
# 
# # b) fill in the fips missing zeroes
# 
# # add in the lost leading zeroes for the state FIP
# sa_raw <- sa_raw %>%
#   mutate(fipstate = sprintf("%0.2d", as.numeric(fipstate)))
# 
# # add in the lost leading zeroes for county FIP
# sa_raw <- sa_raw %>%
#   mutate(fipscty = sprintf("%0.3d", as.numeric(fipscty)))
# 
# 
# # c) keep the NAICS organization codes we want
# keep <- c(813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920)
# sa_raw <- filter(sa_raw, naics %in% keep)
# # just noting -- 9792 observations
# 
# 
# # d) collapse (aggregate org #s so there is only 1 value per county) & keep only relevant variables
# #    Note: "est" is the number of organizations (stands for establishments)
# 
# # keep only relevant data
# sa_raw <- sa_raw %>%
#   select(fipstate, fipscty, est)
# 
# 
# # remove observations with missing data for our orgs variable
# sa_raw <- sa_raw %>%
#   drop_na(est)
# 
# # aggregate the total # of orgs per county
# sa_raw <- sa_raw %>%
#   group_by(fipstate, fipscty) %>%
#   summarise(est = sum(est)) %>% 
#   mutate(year = 2020)

# (3)  download population data from ACS (this is the denominator)
# no need to do this if we use our county file which already has these data
pop_20 <- read.csv("geographic-crosswalks/data/county-populations.csv")

# add in the lost leading zeroes for the state FIP & rename for merge
pop_20 <- pop_20 %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))
pop_20 <- pop_20 %>%
  rename(fipstate = state)

# add in the lost leading zeroes for county FIP & rename for merge
pop_20 <- pop_20 %>%
  mutate(county = sprintf("%0.3d", as.numeric(county)))
pop_20 <- pop_20 %>%
  rename(fipscty = county)

# keep the year we want
keepyr <- c(2020)
pop_20 <- filter(pop_20, year %in% keepyr)

# keep the variables we want
pop_20 <- pop_20 %>%
  select(year, fipstate, fipscty, population)


# (4)  merge the data file(s) & construct the ratio (Numerator/Denominator)

# merge the county pop file into the social associations file (left join, since county file has more observations)
merged_sa <- left_join(pop_20, sa_raw, by = c("fipstate", "fipscty"))

# clean up
merged_sa <- merged_sa %>%
  select(year.x, fipstate, fipscty, est, population)
merged_sa <- merged_sa %>%
  rename(year = year.x)

# create the Number of membership associations per 10,000 people metric
# The original calls for "Number of membership associations per 10,000 population"
# so we first divide the population by 10,000
merged_sa <- merged_sa %>%
  mutate(
    popratio = population / 10000,
    count_membership_associations_per_10k = est / popratio
  ) %>%
  # round the ratio metric to one decimal point (as they do in County Health Rankings)
  mutate(count_membership_associations_per_10k = round(count_membership_associations_per_10k, digits = 1))
# (5)  final file cleaning and export to .csv file

# data quality flag (we have no issues with this metric except overall missings)
# this is so that the missing values transfer as missing values
merged_sa <- merged_sa %>%
  mutate(
    count_membership_associations_per_10k_quality =
      if_else(is.na(count_membership_associations_per_10k),
        as.numeric(NA),
        1
      )
  ) %>%
  # keep what we need
  select(
    year, fipstate, fipscty,
    count_membership_associations_per_10k,
    count_membership_associations_per_10k_quality
  ) %>%
  # rename before exporting
  rename(
    state = fipstate,
    county = fipscty
  )

# check how many missing
sum(is.na(merged_sa$count_membership_associations_per_10k))

# export our file as a .csv
write_csv(merged_sa, "06_neighborhoods/social-capital/data/social_associations_county_2020.csv")

