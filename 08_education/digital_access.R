###################################################################

# ACS Code: Digital Access metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Prepare relevant PUMA-City crosswalk
# (3) Bring in the relevant ACS microdata & create Digital Access indicator
# (4) Merge & create Digital Access metric
# (5) Create the Data Quality variable
# (6) Cleaning and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)
library(tidyverse)
library(ipumsr)

###################################################################

# (2) Prepare relevant PUMA-City crosswalk

# Open crosswalk data
puma_city_2020 <- read_csv("geographic-crosswalks/data/geocorr2012_PUMA_Places_2020.csv")
# Note:
# afact = how much of the Census Place is in the PUMA
# afact2 = how much of the PUMA is in the Census Place

# rename variables and rework for future merge
puma_city_2020 <- puma_city_2020 %>% 
  dplyr::rename(puma = puma12)
puma_city_2020 <- puma_city_2020 %>%
  mutate(statefip = sprintf("%02d", as.numeric(statefip)),
         puma = sprintf("%05d", as.numeric(puma)),
         place = sprintf("%05d", as.numeric(place)))

# create a concatenated GEOID for each city(e.g. census place)
puma_city_2020$GEOID <- paste(puma_city_2020$statefip,puma_city_2020$place, sep = "")

# drop observations where the weight adjustment is zero (these are PUMAs where 0 of the PUMA is in the Place)
puma_city_2020 <- puma_city_2020[puma_city_2020$afact != 0.000, ]
# Note: 37810 to 37538 obs

# merge in place population file (to isolate to the places we want)
place_file <- read_csv("geographic-crosswalks/data/place-populations.csv")
place_file <- filter(place_file, year == 2020)
place_file$GEOID <- paste(place_file$state,place_file$place, sep = "")

puma_city <- place_file %>% left_join(puma_city_2020, 
                                      by=c('GEOID'))
# Note: 1698 observations for 486 Census Places

# sort final crosswalk file by statefip GEOID
puma_city <- puma_city %>%
  arrange(statefip, GEOID)

# create a variable that assigns a weight to each Census Place (City) based on total 2020 population
# First, create a variable for the total population
puma_city <- puma_city %>%
  mutate(totpop = sum(population))

# Then, create the weight variable for each Census Place (City)
puma_city <- puma_city %>%
  mutate(citywgt=population/totpop)

# keep only the variables we will need
puma_city <- puma_city %>% 
  select(year, state, puma, GEOID, population, afact, afact2, totpop, citywgt)


###################################################################

# (3) Bring in the relevant ACS microdata & create Digital Access indicator

# ACS 2021 1-year data for Digital Access
# How to download from IPUMS:
# Select Samples -> ACS 1-year, 2021
# Following variables:
# STATEFIP - state FIPs code
# PUMA - PUMA ID code
# HHWT - Household weight
# CIHISPEED - household subscription to high-speed Internet

# Right-click "DDI" under "Codebook", "Save link as", save .xml file to directory
# Download .dat file to your directory as well (names should match)

# Import the ACS microdata
ddi <- read_ipums_ddi("data/temp/usa_00008.xml")
data <- read_ipums_micro(ddi)
# 3,252,599 observations

# summing up HHWT will give you aggregate household-level counts
# NOTE: if you are using an extract that has microdata at the individual level (vs HH level),
# AKA a rectangularized sample, select only one person (e.g., PERNUM = 1) to isolate unique households.

# Limit our analysis to actual households (e.g. GQ should equal 1 or 2)
digital_microdata <- filter(data, GQ == 1 | GQ == 2)
# 3,092,079 observations

# Checking out the high-speed internet access variable
digital_microdata %>% 
  select(CIHISPEED) %>% 
  summary()
# CIHISPEED value = 10 means YES
# CIHISPEED value = 20 means NO
# CIHISPEED value = 0 mean N/A (GQ)

# Create the digital access indicator (hspd_int meaning high speed internet)
digital_microdata <- digital_microdata %>%
  mutate(
    hspd_int = case_when(
      CIHISPEED == 0 ~ NA_real_,
      CIHISPEED == 10 ~ 1,
      CIHISPEED == 20 ~ 0
    ))


###################################################################

# (4) Merge & create Digital Access metric

# prep variables for merge
digital_microdata <- digital_microdata %>% 
  dplyr::rename("puma" = "PUMA",
         "state" = "STATEFIP")
digital_microdata <- digital_microdata %>%
  mutate(state = sprintf("%02d", as.numeric(state)),
         puma = sprintf("%05d", as.numeric(puma))
  )

# merge the microdata to Census Places (Cities)
# left join because we only want the PUMA microdata that falls into our Cities
digital_puma_city <- puma_city %>% 
  left_join(digital_microdata, by=c('state','puma'))
# 2,130,573 observations

# checking that the merge went the right way
length(unique(digital_puma_city$GEOID))
# 486 unique places - good to go 

# create a variable for the number of Census Places (Cities) per PUMA
digital_puma_city <- digital_puma_city %>%
  group_by(puma, state) %>%
  mutate(cities_per_PUMA = n_distinct(GEOID))

# create a variable for the number of PUMAs per Census Place (City) 
digital_puma_city <- digital_puma_city %>%
  group_by(GEOID) %>%
  mutate(PUMAs_per_city = n_distinct(state, puma))

# Adjust HH weight by the amount of the Place that falls into that PUMA
digital_puma_city <- digital_puma_city %>%
  mutate(HHWT = HHWT*afact)


# Create the Digital Access metric
# it's a ratio: number of HH with access to broadband/number of HH
# Number of HH with broadband (hspd_int = 1)

# create a dataset with the count of all the HH with broadband access per city
# first, weigh our access variable (hspd_int) by HHWT
digital_puma_city <- digital_puma_city %>%
  mutate(hspd_int = HHWT*hspd_int)

# collapse (sum) high speed internet (hspd_int) by city (digital_hh will be the count of HH with access)
# include n as a count of how many observations from the microdata were collapsed for that city
digital_hh <- digital_puma_city %>% 
  dplyr::group_by(GEOID) %>% 
  dplyr::summarize(digital_hh = sum(hspd_int, na.rm=TRUE),
            n = n(),
            na.rm=TRUE
  )

# create a similar dataset for all HH per city
# include same n count (should end up with same counts as above)
all_hh <- digital_puma_city %>% 
  dplyr::group_by(GEOID) %>% 
  dplyr::summarize(all_hh = sum(HHWT, na.rm=TRUE),
            n = n(),
            na.rm=TRUE
  )

# Merge the two datasets (digital_hh and all_hh)
digital_access <- merge(digital_hh, all_hh, by=c("GEOID", "n"), all.x=TRUE)

# Compute the ratio (share of HH with digital access)
digital_access <- digital_access %>%
  mutate(share_digital_access = digital_hh/all_hh)

# Create Confidence Interval (CI) and correctly format the variables
digital_access <- digital_access %>%
  mutate(no_access = 1 - share_digital_access,
         interval = 1.96 * sqrt((no_access*share_digital_access)/n),
         share_digital_access_ub = share_digital_access + interval,
         share_digital_access_lb = share_digital_access - interval)


###################################################################

# (5) Create the Data Quality variable

# For Digital Access metric: total number of households surveyed
digital_access <- digital_access %>% 
  mutate(size_flag = case_when((all_hh < 30) ~ 1,
                               (all_hh >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
 puma_place <- read_csv("data/temp/puma_place.csv")
 puma_place <- transform(puma_place,GEOID=interaction(statefip,place,sep=''))
 puma_place$GEOID <- as.character(puma_place$GEOID)

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
 digital_access <- digital_access %>% 
   left_join(puma_place, by=c('GEOID'))

# Generate the quality var
 digital_access <- digital_access %>% 
  mutate(share_digital_access_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                                size_flag==0 & puma_flag==2 ~ 2,
                                                size_flag==0 & puma_flag==3 ~ 3,
                                                size_flag==1 ~ 3))

 ###################################################################
 
 # (6) Cleaning and export
 
 
 # Limit to the Census Places we want 
 
 # rename to prep for merge to places file
 digital_access <- digital_access %>%
   dplyr::rename(state = statefip)
 
 # first, bring in the places crosswalk (place-populations.csv)
 places <- read_csv("geographic-crosswalks/data/place-populations.csv")
 # keep only the relevant year (for this, 2020)
 places <- places %>%
   filter(year > 2019)
 
 # left join to get rid of irrelevant places data
 digital_access <- left_join(places, digital_access, by=c("state","place"))
 digital_access <- digital_access %>% 
   distinct(year, state, place, share_digital_access, 
            share_digital_access_ub, share_digital_access_lb,
            share_digital_access_quality, .keep_all = TRUE)
 
 # add a variable for the year of the data
 digital_access <- digital_access %>%
   mutate(
     year = 2021
   )
 
 # order & sort the variables how we want
 digital_access <- digital_access %>%
   select(year, state, place, share_digital_access, 
          share_digital_access_ub, share_digital_access_lb,
          share_digital_access_quality)
 
 # Replace the NaNs with NAs
 digital_access$share_digital_access[is.nan(digital_access$share_digital_access)]<-NA
 digital_access$share_digital_access_ub[is.nan(digital_access$share_digital_access_ub)]<-NA
 digital_access$share_digital_access_lb[is.nan(digital_access$share_digital_access_lb)]<-NA
 
 # check how many missings
 sum(is.na(digital_access$share_digital_access))
 # 0 missings

 # Save as "digital_access.csv"
  write_csv(digital_access, "08_education/digital_access_city_2021.csv")  
 
 


