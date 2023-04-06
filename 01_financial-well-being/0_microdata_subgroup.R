
###################################################################

# ACS Code: Preparing the microdata, subgroups
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2017-2021, 5-year
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

# Download needed microdata from IPUMS:
#  Sample Selection: ACS 2021 (5-year)
#  Variables: HHWT, ADJUST, STATEFIP, PUMA, GQ, OWNERSHP, OWNCOST, RENT, RENTGRS, HHINCOME,
#             VALUEH, PERNUM, PERWT, EDUC, EDUCD, GRADEATT, EMPSTAT, AGE, RACE, HISPAN
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
# 37810 obs to 1725 obs (36085 obs dropped)

# keep only the variables we will need
puma_place_2021 <- puma_place_2021 %>% 
  select(statefip, puma, place, pop20, afact, afact2)

# drop observations where the weight adjustment is zero
puma_place_2021 <- puma_place_2021 %>%
  filter(afact!= 0.000)
# 1698 obs (27 obs dropped)

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
# Prepare MICRODATA (by race subgroup)

# open IPUMS extract (change "usa_00017.xml" to whatever your extract is called)
microdata <- 'usa_00017.xml'
ddi <- read_ipums_ddi(microdata)
acs5_2021 <- read_ipums_micro(ddi)
# 15,537,785 observations

# keep only vars we need
acs5_2021 <- acs5_2021 %>%
  select(HHWT, ADJUST, STATEFIP, PUMA, GQ, OWNERSHP, OWNCOST, RENT, RENTGRS, HHINCOME,
         VALUEH, PERNUM, PERWT, EDUC, EDUCD, GRADEATT, EMPSTAT, AGE, RACE, HISPAN)

# clean up for matching purposes
acs5_2021 <- acs5_2021 %>% 
  dplyr::rename("puma" = "PUMA",
                "statefip" = "STATEFIP")

acs5_2021 <- acs5_2021 %>%
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                puma = sprintf("%0.5d", as.numeric(puma)),
  )


###################################################################
# (5) Merge the microdata PUMAs to places

# (left join, since microdata has more observations)
# memory.limit(size=999999)
acs5yr_clean  <- left_join(acs5_2021, puma_place, by=c("statefip","puma"))
# now have 18,514,586 observations
# run anti_join to see how many cases on the left did not have a match on the right
# test  <- anti_join(acs_2021, puma_place, by=c("statefip","puma"))

# Drop any observations with NA or 0 for afact (i.e. there is no place of interest overlapping this PUMA)
acs5yr_clean <- acs5yr_clean %>% 
  filter(!is.na(afact))
# 18,514,586 obs to 10,583,133 obs (7,931,453 dropped)
acs5yr_clean <- acs5yr_clean %>% 
  filter(afact > 0)
# no drops


# Adjust weight to account for PUMA-to-county mapping (those where unique_types > 1).;
# Same adjustments as Kevin:
acs5yr_clean <- acs5yr_clean %>%
  mutate(HHWT = HHWT*afact, # the weight of each household is adjusted by the area of the PUMA that falls into a given Place
         HHINCOME = HHINCOME*ADJUST, # adjusts the HH income values by the Census's 12-month adjustment factor (converts numbers into calendar year dollars)
         PERWT = PERWT*afact, # the weight of each person is adjusted by the area of the PUMA that falls into a given Place
         RENTGRS = RENTGRS*ADJUST, # adjusts gross monthly rental cost for rented housing units into cal-year dollars
         OWNCOST = OWNCOST*ADJUST) # adjusts monthly costs for owner-occupied housing units into cal-year dollars


# Now: create race categories
#  values for RACE variable:
# 1	White	
# 2	Black/African American/Negro	
# 3	American Indian or Alaska Native
# 4	Chinese
# 5	Japanese	
# 6	Other Asian or Pacific Islander
# 7	Other race, nec	
# 8	Two major races	
# 9	Three or more major races	

# values for HISPAN variable:
# 0	Not Hispanic
# 1	Mexican
# 2	Puerto Rican·
# 3	Cuban
# 4	Other
# 9	Not Reported


# if HISPAN is 0 and RACE is 1, then subgroup 4 (White)
# if HISPAN is 0 and RACE is 2, then subgroup 1 (Black)
# if HISPAN is 0 and RACE is (3,4,5,6,7,8,9), then subgroup 3 (Other)
# if HISPAN is (1,2,3,4), then subgroup 2 (Hispanic)
acs5yr_clean <- acs5yr_clean %>%
  mutate(subgroup = case_when((HISPAN == 0 & RACE == 1) ~ 4,
                              (HISPAN == 0 & RACE == 2) ~ 1,
                              (HISPAN == 0 & RACE %in% 3:9) ~ 3,
                              (HISPAN %in% 1:4) ~ 2,
  ))

# Rename the values from number category to race label
# 4 = "White, Non-Hispanic"
# 1 = "Black, Non-Hispanic"
# 3 = "Other Races and Ethnicities"
# 2 = "Hispanic"
acs5yr_clean <- acs5yr_clean %>%
  mutate(subgroup = case_when(subgroup %in% 1 ~ 'Black, Non-Hispanic',
                              subgroup %in% 2 ~ 'Hispanic',
                              subgroup %in% 3 ~ 'Other Races and Ethnicities',
                              subgroup %in% 4 ~ 'White, Non-Hispanic'
  ))



# save as "microdata.csv" in gitignore
# write_csv(acs5yr_clean, "data/temp/2021microdata5yr.csv")


##########################################
# create empty sub-group level place file (1944 observations), to use as check/comparison for catching NA values 
place_subgroup <- acs5yr_clean %>% 
  dplyr::group_by(statefip, place, subgroup) %>% 
  dplyr::summarize(
    n = n()
  )

# save as "place_subgroup.csv" in gitignore
# write_csv(acs5yr_clean, "data/temp/place_subgroup.csv")

