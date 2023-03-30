
###################################################################

# ACS Code: Preparing the microdata, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Prepare the Census Place to PUMA crosswalk
# (3) Prepare for Data Quality flag
# (4) Prepare Microdata (non-subgroup)
# (5) Merge the microdata PUMAs to counties

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(ipumsr)
library(survey)
library(srvyr)

# Download needed microdata from IPUMS:
#  Sample Selection: ACS 2021 (1-year)
#  Variables: HHWT, ADJUST, STATEFIP, PUMA, GQ, OWNERSHP, OWNCOST, RENT, RENTGRS, HHINCOME,
#             VALUEH, VACANCY, PERNUM, PERWT, EDUC, EDUCD, GRADEATT, EMPSTAT, AGE
# Right-click "DDI" under "Codebook", "Save link as", save .xml file to directory
# Download .dat file to your directory as well (names should match)

###################################################################

# (2) Prepare the Census Place to PUMA crosswalk
# open relevant crosswalk data
puma_place_2021 <- read_csv("geographic-crosswalks/data/geocorr2012_PUMA_Places_2020.csv")

# rename variables for working purposes
puma_place_2021 <- puma_place_2021 %>% 
  dplyr::rename(puma = puma12,
                statefip = state)
puma_place_2021 <- puma_place_2021 %>%
  mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
         puma = sprintf("%0.5d", as.numeric(puma)),
         place = sprintf("%0.5d", as.numeric(place))
  )

# Limit to the Census Places we want 
# first, bring in the places crosswalk (place-populations.csv)
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the relevant year (for this, 2020)
places <- places %>%
  filter(year > 2019)
# rename to prep for merge
places <- places %>% 
  dplyr::rename("statefip" = "state")

# left join to get rid of irrelevant places data (this is in an effort to make our working files smaller)
puma_place_2021 <- left_join(places, puma_place_2021, by=c("statefip","place"))
# 37583 obs to 1698 obs (35885 obs dropped)

# keep only the variables we will need
puma_place_2021 <- puma_place_2021 %>% 
  select(statefip, puma, place, pop20, afact, afact2)

# drop observations where the weight adjustment is zero
puma_place_2021 <- puma_place_2021 %>%
  filter(afact!= 0.000)
# no drops

# (optional) sort by statefip place (previously was statefip puma)
#puma_place_2021 <- puma_place_2021 %>%
#  arrange(statefip, place)

# Create a variable that assigns a weight to each place based on total 2020 population
# first, create a variable for the total population
puma_place_2021 <- puma_place_2021 %>%
  mutate(totpop = sum(pop20))

# then, create a variable for the population of each place (unique statefip+county pairs)
puma_place_2021 <- puma_place_2021 %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::mutate(placepop = sum(pop20),
                placewgt = placepop/totpop)


###################################################################

# (3) Prepare for Data Quality flag (at end)
# Create flags in the PUMA-place crosswalk for high percentage of data from outside of place. 
# Per Greg (for counties), 75% or more from the county - in this case, place - is good, below 35% is bad, in between is marginal.
# This is calculated by taking the product of percentage of PUMA in place and
# percentage of place in PUMA for each place-PUMA pairing, and summing across the place.

# Create new vars of interest
puma_place <- puma_place_2021 %>%
  mutate(products = afact*afact2)

puma_place <- puma_place %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::mutate(sum_products = sum(products),
                place_pop = sum(pop20))

summary(puma_place)
# Q1 of placepop is 110,629
# sum_products mean is 0.76
puma_place <- puma_place %>%
  dplyr::mutate(
    puma_flag = 
      case_when(
        sum_products >= 0.75 ~ 1,
        sum_products >= 0.35 ~ 2,
        sum_products < 0.35 ~ 3
      ),
    small_place = 
      case_when(
        placepop >= 110629 ~ 0,
        placepop < 110629 ~ 1
      )
  )

# save as "puma_place.csv" in gitignore
write_csv(puma_place, "data/temp/puma_place.csv")

# save a version with just the place-level values of data quality variables
place_puma <- puma_place %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(puma_flag = mean(puma_flag), 
            small_place = mean(small_place))

# save as "place_puma.csv" in gitignore
write_csv(place_puma, "data/temp/place_puma.csv")

###################################################################

# (4) Prepare Microdata (non-subgroup)

# open IPUMS extract (change "usa_00014.xml" to whatever your extract is called)
microdata <- 'usa_00014.xml'
ddi <- read_ipums_ddi(microdata)
acs_2021 <- read_ipums_micro(ddi)
# 3252599 observations

# keep only vars we need
acs_2021 <- acs_2021 %>%
  select(HHWT, ADJUST, STATEFIP, PUMA, GQ, OWNERSHP, OWNCOST, RENT, RENTGRS, HHINCOME,
         VALUEH, VACANCY, PERNUM, PERWT, EDUC, EDUCD, GRADEATT, EMPSTAT, AGE)

# clean up for matching purposes
acs_2021 <- acs_2021 %>% 
  dplyr::rename("puma" = "PUMA",
                "statefip" = "STATEFIP")

acs_2021 <- acs_2021 %>%
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                puma = sprintf("%0.5d", as.numeric(puma)),
  )


###################################################################

# (5) Merge the microdata PUMAs to places

# (left join, since microdata has more observations)
# memory.limit(size=999999)
acs2021clean  <- left_join(acs_2021, puma_place, by=c("statefip","puma"))
# now have 3,252,599 observations
# run anti_join to see how many cases on the left did not have a match on the right
test  <- anti_join(acs_2021, puma_place, by=c("statefip","puma"))
# 1,656,456 obs from the microdata (makes sense since we limited to only PUMAs that are overlapping with Places of interest)

# Drop any observations with NA or 0 for afact (i.e. there is no place of interest overlapping this PUMA)
acs2021clean <- acs2021clean %>% 
  filter(!is.na(afact))
# 3,252,599 obs to 2,230,328 obs (1,022,271 dropped)
acs2021clean <- acs2021clean %>% 
  filter(afact > 0)
# no drops

# create a variable for the number of places per PUMA population per place (e.g., in unique statefip+place pairs)
#acs2021clean  <- acs2021clean  %>%
#  dplyr::group_by(puma, statefip) %>%
#  dplyr::mutate(places_per_PUMA = n_distinct(statefip, place))

# create a variable for the number of PUMAs per place 
#acs2021clean  <- acs2021clean %>%
#  group_by(place, statefip) %>%
#  mutate(PUMAs_per_place = n_distinct(statefip, puma))

# Adjust weight to account for PUMA-to-county mapping (those where unique_types > 1).;

# Same adjustments as Kevin:
acs2021clean <- acs2021clean %>%
  mutate(HHWT = HHWT*afact, # the weight of each household is adjusted by the area of the PUMA that falls into a given Place
         HHINCOME = HHINCOME*ADJUST, # adjusts the HH income values by the Census's 12-month adjustment factor (converts numbers into calendar year dollars)
         PERWT = PERWT*afact, # the weight of each person is adjusted by the area of the PUMA that falls into a given Place
         RENTGRS = RENTGRS*ADJUST, # adjusts gross monthly rental cost for rented housing units into cal-year dollars
         OWNCOST = OWNCOST*ADJUST) # adjusts monthly costs for owner-occupied housing units into cal-year dollars

# save as "microdata.csv" 
# write_csv(acs2021clean, "data/temp/2021microdata.csv")


