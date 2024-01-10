
###################################################################

# ACS Code: Preparing the microdata, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (0) Housekeeping
# (1) Download microdata from IPUMS API
# (2) Prepare the Census Place to PUMA crosswalk
# (3) Prepare for Data Quality flag
# (4) Prepare Microdata (non-subgroup)
# (5) Merge the microdata PUMAs to counties

###################################################################

# (0) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(janitor)
library(tidylog)
library(ipumsr)
library(survey)
library(srvyr)

###################################################################

# (1) Download microdata from IPUMS API 

# More information on the API can be found here: https://cran.r-project.org/web/packages/ipumsr/vignettes/ipums-api.html
# If you don't already have one, you will need register for an IPUMS API key here: https://uma.pop.umn.edu/usa/registration/new

# get a list of all of the sample available
cps_samps <- get_sample_info("usa")
# we want "us2022a" for the 2022 ACS

# (1a) Import housing data

# define extract dataset and variables
housing_ext_def <- define_extract_usa(
  description = "Housing microdata extract", # description of extract
  samples = c("us2022a"), # use 2022 ACS data
  variables = c("HHWT", "ADJUST", "STATEFIP", "PUMA", "GQ", "OWNERSHP", "OWNCOST", "RENT", "RENTGRS", "HHINCOME",
                "VALUEH", "VACANCY", "PERNUM", "PERWT", "EDUC", "EDUCD", "GRADEATT", "EMPSTAT", "AGE", "KITCHEN", "PLUMBING")
) %>% 
  submit_extract() %>% 
  wait_for_extract() %>% 
  download_extract() %>% 
  read_ipums_ddi() %>% 
  read_ipums_micro()
# 3373378 obs

# save temp file with API pull
write_csv(housing_ext_def, "data/temp/housing_microdata2022.csv")


# (1b) Import vacant unit specific data

# For VACANT UNIT side: Import vacant-unit-specific data
# This IPUMS extract has HHWT, GQ, ADJUST, STATEFIP, PUMA, VALUEH, and VACANCY
# When you click "Create Data Extract", must click "SELECT CASES" -> 
# check off "GQ" and click "SUBMIT" -> Check off "O Vacant Unit" under GQ status and click "SUBMIT"
# THEN:
# Under "STRUCTURE:" , click "Change" -> switch from 'Rectangular' to 'Hierarchical' -> "APPLY SELECTIONS"

# keep only the variables we need/can even have given this hierarchical structure
vacant_microdata22 <- define_extract_usa(
  description = "Vacancy microdata extract", # description of extract
  samples = c("us2022a"), # use 2022 ACS data
  variables = list(
    "HHWT", 
    var_spec("GQ", case_selections = c("0")), # just download cases where GQ == 0 (vacant)
    "ADJUST", "STATEFIP", "PUMA", "VALUEH", "VACANCY","RENTGRS","RENT", "KITCHEN", "PLUMBING"
  ),
  data_structure = "hierarchical"
) %>% 
  submit_extract() %>% 
  wait_for_extract() %>% 
  download_extract() %>% 
  read_ipums_ddi() %>% 
  read_ipums_micro() %>% 
  dplyr::rename("puma" = "PUMA",
                "statefip" = "STATEFIP") %>%
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                puma = sprintf("%0.5d", as.numeric(puma)),
  ) %>% arrange(statefip, puma)

# save vacancy data
write_csv(vacant_microdata22, "data/temp/vacancy_microdata2022.csv")

###################################################################

# (2) Prepare the Census Place to PUMA crosswalk
# open relevant crosswalk data
puma_place_2022 <- read_csv("data/temp/geocorr2022_puma_to_place.csv") %>% 
  clean_names()%>% 
  # rename variables for working purposes
  dplyr::rename(puma = puma22,
                statefip = state) %>% 
  mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
         puma = sprintf("%0.5d", as.numeric(puma)),
         place = sprintf("%0.5d", as.numeric(place))) 

# Limit to the Census Places we want 
# first, bring in the places crosswalk (place-populations.csv)
places <- read_csv("geographic-crosswalks/data/place-populations.csv") %>% 
  # keep only the relevant year (for this, 2022)
  filter(year > 2021) %>% 
  # rename to prep for merge
  dplyr::rename("statefip" = "state")

# left join to get rid of irrelevant places data (this is in an effort to make our working files smaller)
puma_place_2022 <- left_join(places, puma_place_2022, by=c("statefip","place")) %>% 
  # 37123 obs to 1578 obs (35,545 obs dropped)
  # keep only the variables we will need
  select(statefip, puma, place, pop20, afact, afact2)

# check number fo unique places in data
puma_place_2022 %>% distinct(statefip, place) %>% nrow() # 486

# drop observations where the weight adjustment is zero
puma_place_2022 <- puma_place_2022 %>%
  filter(afact!= 0.000)
# 1,550 obs (28 dropped)

# (optional) sort by statefip place (previously was statefip puma)
#puma_place_2021 <- puma_place_2021 %>%
#  arrange(statefip, place)

# Create a variable that assigns a weight to each place based on total 2020 population
# first, create a variable for the total population
puma_place_2022 <- puma_place_2022 %>%
  mutate(totpop = sum(pop20))

# then, create a variable for the population of each place (unique statefip+county pairs)
puma_place_2022 <- puma_place_2022 %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::mutate(placepop = sum(pop20*afact),
                placewgt = placepop/totpop)


###################################################################

# (3) Prepare for Data Quality flag (at end)
# Create flags in the PUMA-place crosswalk for high percentage of data from outside of place. 
# Per Greg (for counties), 75% or more from the county - in this case, place - is good, below 35% is bad, in between is marginal.
# This is calculated by taking the product of percentage of PUMA in place and
# percentage of place in PUMA for each place-PUMA pairing, and summing across the place.

# Create new vars of interest
puma_place <- puma_place_2022 %>%
  mutate(products = afact*afact2)

puma_place <- puma_place %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::mutate(sum_products = sum(products),
                place_pop = sum(pop20*afact))

summary(puma_place)
# Q1 of placepop is 75,069
# sum_products mean is 0.77
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
        placepop >= 75069 ~ 0,
        placepop < 75069 ~ 1
      ), 
    place_code = str_c(statefip, place)
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

# keep only vars we need
acs_2022 <- housing_ext_def %>%
  select(HHWT, ADJUST, STATEFIP, PUMA, GQ, OWNERSHP, OWNCOST, RENT, RENTGRS, HHINCOME,
         VALUEH, VACANCY, PERNUM, PERWT, EDUC, EDUCD, GRADEATT, EMPSTAT, AGE) %>% 
  # clean up for matching purposes
  dplyr::rename("puma" = "PUMA",
                "statefip" = "STATEFIP") %>% 
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                puma = sprintf("%0.5d", as.numeric(puma)))


###################################################################

# (5) Merge the microdata PUMAs to places

# (left join, since microdata has more observations)
# memory.limit(size=999999)
acs2022clean  <- left_join(acs_2022, puma_place, by=c( "statefip", "puma")) %>% 
  mutate(place_code = str_c(statefip, place))
# now have 3,787,952 observations

# check distinct number of places - 536
acs2022clean %>% distinct(statefip, place) %>% nrow()

# run anti_join to see how many cases on the left did not have a match on the right
test  <- anti_join(acs_2022, puma_place, by=c("statefip","puma"))
# 1,842,100 obs from the microdata (makes sense since we limited to only PUMAs that are overlapping with Places of interest)

# Drop any observations with NA or 0 for afact (i.e. there is no place of interest overlapping this PUMA)
acs2022clean <- acs2022clean %>% 
  filter(!is.na(afact))
# 3,787,952 obs to 1,945,852 obs (1,842,100 dropped)
acs2022clean <- acs2022clean %>% 
  filter(afact > 0)
# no drops

# Adjust weight to account for PUMA-to-county mapping (those where unique_types > 1).;

# Same adjustments as Kevin:
acs2022clean <- acs2022clean %>%
  mutate(HHWT = HHWT*afact, # the weight of each household is adjusted by the area of the PUMA that falls into a given Place
         HHINCOME = HHINCOME*ADJUST, # adjusts the HH income values by the Census's 12-month adjustment factor (converts numbers into calendar year dollars)
         PERWT = PERWT*afact, # the weight of each person is adjusted by the area of the PUMA that falls into a given Place
         RENTGRS = RENTGRS*ADJUST, # adjusts gross monthly rental cost for rented housing units into cal-year dollars
         OWNCOST = OWNCOST*ADJUST) # adjusts monthly costs for owner-occupied housing units into cal-year dollars

# save as "microdata.csv" 
write_csv(acs2022clean, "data/temp/2022microdata.csv")


