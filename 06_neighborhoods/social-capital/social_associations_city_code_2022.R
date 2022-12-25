###############################################################################

# Description: Code to create city-level Social Associations metric (one of two Social Capital Gates Mobility Metrics)  
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/zbp20detail.csv (won't be on Github main)
# Data downloaded from: Census County Business Patterns 2020
# Author: Tina Chelidze											   
# Date: December 23, 2022

# (1)  download social organization data from https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html (this is the numerator)										
# (2)  import and clean the data file	(collapse to unique ZIPs)			   
# (3)  merge with the 2010 ZCTA -> 2021 Census Place crosswalk
# (4)  collapse estimates to unique Places
# (5)  check against official Census Place file & limit to population cutoff Places
# (6)  use crosswalk population data to construct the ratio (Numerator/Denominator)
# (7)  add data quality tag, final file cleaning and export to .csv file	

###############################################################################

# Houskeeping
# Set working directory to [gitfolder]. Update path as necessary to your local metrics repo
setwd("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty")

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)
library(tigris)
library(censusapi)

# Add key to .Renviron
Sys.setenv(CENSUS_KEY="a92cdc14739747a791bb02096d30a82f27f05add")
# Reload .Renviron
readRenviron("~/.Renviron")
# Check to see that the expected key is output in your R console
Sys.getenv("CENSUS_KEY")


# (1)  download social organization data from https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html (this is the numerator)										
# Instead of using the file, going to go for the API this time (due to many more observations)

cbp_zip <- getCensus(
  name = "cbp",
  vintage = 2020,
  vars = c("EMP", "ESTAB", "NAICS2017"),
  region = "zipcode:*")
head(cbp_zip)


# (2) import and clean the CBP data file 
# This means a) fill in fips missing zeroes, b) isolate to only the following NAICS, 
# c) collapse & keep only relevant variables, and d) add the year of these data
# codes: 813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, and 813920
# These are the codes/associations included in the County Health Rankings metric
# See here for more: https://www.countyhealthrankings.org/explore-health-rankings/county-health-rankings-model/health-factors/social-economic-factors/family-and-social-support/social-associations?year=2022


# (a) add leading zeroes where they are missing (ZCTA codes are 5 digits)
#           cbp_zip$zip_code <- sprintf("%05d", as.numeric(cbp_zip$zip_code))
# Not needed, already good
# write_csv(cbp_zip, "06_neighborhoods/social-capital/final_data/CBP_ZIP_2022.csv")
cbp_zip$naics <- as.numeric(cbp_zip$NAICS2017)
cbp_zip$zip <- as.numeric(cbp_zip$zip_code)


# (b) keep the NAICS organization codes we want
keep = c(813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920)
cbp_zip <- filter(cbp_zip, naics %in% keep)
# 2,886,438 to 28,698 obs


# (c) collapse (aggregate org #s so there is only 1 value per ZIP) & keep only relevant variables 

# keep only relevant data
cbp_zip <- cbp_zip %>% select(zip_code, zip, ESTAB)
# remove observations with missing data for our orgs variable
cbp_zip <- cbp_zip %>% drop_na(ESTAB)
    # no missings (observations still at 28698)

# aggregate the total # of orgs per ZIP
cbp_zip <- cbp_zip %>% group_by(zip) %>%
  summarize(est_total = sum(ESTAB))
# 28,698 observations to 16,594 observations

#add lost leading zeroes
cbp_zip$zipcode <- sprintf("%05d", as.numeric(cbp_zip$zip))


# (d) add the year of the data
cbp_zip$year <- "2020"


# (3)  Merge with the 2010 ZCTA -> 2021 Census Place crosswalk

# import the 2010 ZCTA -> 2021 Census Place crosswalk file
ZCTA_Place <- read.csv("geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv")

# clean up the crosswalk file to prepare for the merge:
# rename the ZCTA and state FIPS variables to avoid confusion
ZCTA_Place <- ZCTA_Place %>% 
  rename("zip" = "ZCTA5CE10")
ZCTA_Place <- ZCTA_Place %>% 
  rename("statefips" = "STATEFP")
ZCTA_Place <- ZCTA_Place %>% 
  rename("place" = "PLACEFP")
ZCTA_Place <- ZCTA_Place %>% 
  rename("place_name" = "NAMELSAD")
# adjust the leading zeroes now
ZCTA_Place$zip <- sprintf("%05d", as.numeric(ZCTA_Place$zip))
ZCTA_Place$statefips <- sprintf("%02d", as.numeric(ZCTA_Place$statefips))
ZCTA_Place$place <- sprintf("%05d", as.numeric(ZCTA_Place$place))

# make an indicator for ZIPs that fall wholly into a Place vs. partially (ZCTAinPlace < 1)
ZCTA_Place <- ZCTA_Place %>%
  mutate(portionin = case_when(ZCTAinPlace == 1 ~ 1,
                               ZCTAinPlace < 1 ~ 0))
# check how many of these...
sum(with(ZCTA_Place, portionin==1))
# 2079 of these ZCTAs fall fully into a Census Place

# keep only the variables we will need
ZCTA_Place <- ZCTA_Place %>% select(zip, statefips, place, place_name, IntersectArea, ZCTAinPlace, portionin)

# merge the ZIP/Places crosswalk into the CBP ZIP-level data file (left join, since places file has more observations)
merged_sa_zip_city <- merge(ZCTA_Place, cbp_zip, by=c("zip"))

# check if there are missings after the merge
merged_sa_zip_city <- merged_sa_zip_city %>% drop_na(est_total)
# No missings --> perfect match coverage. Number of obs stayed consistent at 44,610



# (4)  Collapse estimates to unique Places 

# For data quality marker
# create a new variable that tracks the number of ZCTAs falling in each Place (duplicates)
merged_sa_zip_city <- merged_sa_zip_city %>% group_by(place, place_name) %>%
  mutate(num_ZCTAs_in_place = n())

# create the merged file where the SA numerator (number of orgs) is averaged per Place, weighted by the % area of the ZCTA in that Place (new_est_zip)
# and also include total ZCTAs in Place & how many of those partially fall outside the Place 
test2 <- merged_sa_zip_city %>% 
  group_by(statefips, place) %>% 
  summarize(zip_total = mean(num_ZCTAs_in_place), zipsin = sum(portionin), new_est_zip = weighted.mean(est_total, ZCTAinPlace))

# drop missing values
test2 <- test2 %>% drop_na(new_est_zip)
# lost 2,190 observations (21190 minus 19000)



# (5) Check against Census Place file & limit to population cutoff Places

# bring in the updated population-cutoff Places file
places_pop <- read.csv("geographic-crosswalks/data/place-populations.csv")

# adapt variables to prepare for merge 
places_pop$statefips <- sprintf("%02d", as.numeric(places_pop$state))

# keep only 2020 data to prepare for merge (should leave us with 486 obs total)
keep = c(2020)
places_pop <- filter(places_pop, year %in% keep)

test2$place <- sprintf("%05d", as.numeric(test2$place))


# merge places_pop with data file in order to get final SA (numerator) city data
sa_city_data <- merge(places_pop, test2, by=c("place", "statefips"), all.x=TRUE)
# Note: 86 missing city values


# (6)  use crosswalk population data to construct the ratio (Numerator/Denominator)

# create the Social Associations ratio metric (socassn)
# The original calls for "Number of membership associations per 10,000 population"
# so we first divide the population by 10,000
sa_city_data$popratio <- as.numeric(as.character(sa_city_data$population)) / 10000

# now the final ratio
sa_city_data$socassn <- sa_city_data$new_est_zip / sa_city_data$popratio

# round the ratio metric to one decimal point (as they do in County Health Rankings)
sa_city_data$socassn <- round(sa_city_data$socassn, digits = 1) 



# (7)  add data quality tag, final file cleaning and export to .csv file	

# create a ratio value to see how many of the ZIPs we aggregated fell fully into a Census Place boundary 
sa_city_data <- sa_city_data %>%
  mutate(zipratio = zipsin/zip_total)
# check the range on this
summary(sa_city_data)
# zipratio mean = 0.09, Q1 = 0, Q3 = 0.125

# Data Quality 1 = 10% or more of the ZIPs fall mostly (>50%) in the census place 
# Data Quality 2 = less than 10% of the ZIPs fall mostly (>50%) in the census place
sa_city_data <- sa_city_data %>%
  mutate(data_quality = case_when(zipratio >= 0.1 ~ 1,
                                  zipratio < 0.1 ~ 2))


# keep what we need
sa_city_data <- sa_city_data %>% select(year, statefips, place, socassn, data_quality)

# export our file as a .csv
write_csv(sa_city_data, "06_neighborhoods/social-capital/final_data/social_associations_city_2022.csv")






