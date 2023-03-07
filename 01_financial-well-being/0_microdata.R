
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
library(tidyr)
library(dplyr)
library(readr)
library(tidyverse)
library(ipumsr)

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

# keep only the variables we will need
puma_place_2021 <- puma_place_2021 %>% 
  select(statefip, puma, place, pop20, afact, afact2)

# drop observations where the weight adjustment is zero
puma_place_2021 <- puma_place_2021[puma_place_2021$afact != 0.000, ]
# 37810 obs to 37538 obs (272 dropped)


# sort by statefip place (previously was statefip puma)
puma_place_2021 <- puma_place_2021 %>%
  arrange(statefip, place)

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
# Q1 of placepop is 351
# sum_products mean is 0.09
puma_place <- puma_place %>%
  dplyr::mutate(puma_flag = case_when((sum_products >= 0.75) ~ 1,
                                      (sum_products < 0.75 & sum_products >= 0.35) ~ 2,
                                      (sum_products < 0.35) ~ 3),
                small_place = case_when((placepop >= 350) ~ 0,
                                        (placepop < 350) ~ 1))

# save as "puma_place.csv" in gitignore
write_csv(puma_place, "data/temp/puma_place.csv")

###################################################################

# (4) Prepare Microdata (non-subgroup)

# open IPUMS extract (change "usa_00014.xml" to whatever your extract is called)
microdata <- 'data/temp/usa_00014.xml'
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
memory.limit(size=999999)
acs2021clean  <- left_join(acs_2021, puma_place, by=c("statefip","puma"))
# now have 59,650,363 observations

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
  mutate(HHWT = HHWT*afact,
         HHINCOME = HHINCOME*ADJUST,
         PERWT = PERWT*afact,
         RENTGRS = RENTGRS*ADJUST,
         OWNCOST = OWNCOST*ADJUST)

# sort by statefip place (previously was statefip puma)
acs2021clean <- acs2021clean %>%
  arrange(statefip, place)

# save as "microdata.csv" in gitignore
write_csv(acs2021clean, "data/temp/2021microdata.csv")


