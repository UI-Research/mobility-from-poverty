
###################################################################

# ACS Code: Housing metric, non-subgroup
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# and code by Tina Chelidze in R for 2022-2023
# Process:
# (1) Housekeeping
# (2) Import microdata (PUMA Place combination already done)
#       (2a) Create a vacant unit specific file
# (3) Create a Vacant unit dataframe (vacant units will not be accounted for when we isolate households in Steps 4 & 5)
#     Note that to get vacant unit data, need to pull a separate extract from IPUMS; see instructions below.
#       (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:
#       (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#               This "total_monthly_cost" variable will be used to calculate affordability in Step 6
#       (3c) Now create accurate gross rent variable for vacant units for rent: 
#       (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#             vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per place).
#       (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#               This "RENTGRS" variable will be used to calculate affordability in Step 6
# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)
#       (4a) Merge the 2 files
#       (4b) Bring in county_place crosswalk
#       (4c) Merge FMR file with crosswalk on county
#       (4d) Create place_level_income_limits (weight by FMR population in collapse)
# (5) Generate households_2022: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)
# (6) Merge Vacant with place_level_income_limits
#       (6a) create same 30%, 50%, and 80% AMI affordability indicators
# (7) Create the housing metric
#       (7a) Summarize households_2021 and vacant both by place
#       (7b) Merge them by place
#       (7c) Calculate share_affordable_30/50/80AMI
# (8) Create Data Quality marker
# (9) Clean and export
# (10) Quality Checks and Visualizations
#       (10a) Histograms
#       (10b) Summaries
#       (10c) Check against last years values


###################################################################

# (1) Housekeeping
# Always use mobility-from-poverty.Rproj to set correct file paths. Working directory should be the root directory of [gitfolder]

# Libraries you'll need
library(tidyverse)
library(ipumsr)
library(readxl)
library(tidylog)

###################################################################

# (2) Import microdata (PUMA Place combination already done)

# Either run "0_housing_microdata.qmd" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
acs2022 <- read_csv("data/temp/2022microdata.csv") 

# For HH side: isolate original microdata to only GQ under 3 (only want households)
# see here for more information: https://usa.ipums.org/usa-action/variables/GQ#codes_section
acs2022clean <- acs2022 %>%
  tidylog::filter(GQ < 3) 
# removed 94,963 rows (5%), 1,847,434 rows remaining


###################################################################

# (3) Create a Vacant units dataframe (vacant units
#    will not be accounted for when we isolate households in Steps 4 & 5)

# Vacancy = 1 (for rent)
# Vacancy = 2 (for sale)
# Vacancy = 3 (rented or sold but not yet occupied)
# Choosing only 1-3 excludes seasonal, occasional, and migratory units
# drop all missing VALUEH (value of housing units) obs: https://usa.ipums.org/usa-action/variables/VALUEH#codes_section

vacant_microdata22 <- read_csv("data/temp/vacancy_microdata2022.csv") %>% 
  tidylog::filter(VACANCY %in% c(1, 2, 3))
# 26,866 obs from 106,542 obs (79,676 dropped)


# (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:

# Using 6% for the USA to match the choice made by Kevin/Aaron
# Calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation

vacant <- vacant_microdata22 %>%
  # Turn 9999999 to NA and then multiply by ADJUST variable for all else
  mutate(VALUEH = if_else(VALUEH == 9999999, NA,  VALUEH*ADJUST),
         loan = 0.9 * VALUEH,
         month_mortgage = (6 / 12) / 100,
         monthly_PI = loan * month_mortgage * ((1+month_mortgage)**360)/(((1+month_mortgage)**360)-1))


# (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#      This "total_monthly_cost" variable will be used to calculate affordability in Step 6

vacant <- vacant %>%
  mutate(PMI = (.007 * loan) / 12, # typical annual PMI is .007 of loan amount (taken from Paul/Kevin)
         tax_ins = .25 * monthly_PI, # taxes assumed to be 25% of monthly PI
         total_monthly_cost = monthly_PI + PMI + tax_ins # Sum of monthly payment components
  )

# (3c) Now create accurate gross rent variable for vacant units for rent: 
# This needs to come from the original ACS microdata file (rectangularized rather than hierarchical), which
# has HH-level vars like RENT, RENTGRS, and HHINCOME (unlike the Vacant Unit extract)

rent_ratio <- acs2022clean %>% 
  select(RENT, RENTGRS, HHINCOME, HHWT, PERNUM, OWNERSHP, statefip, place) %>% 
  # Keep one observation per household (PERNUM=1), and only rented ones (OWNERSHP=2)
  tidylog::filter(PERNUM == 1,
                  OWNERSHP == 2)
# removed 1,596,449 rows (86%), 250,985 rows remaining


# (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#      vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per place)
rent_ratio <- rent_ratio %>%
  mutate(ratio_rentgrs_rent = RENTGRS/RENT) %>% 
  # Collapse (mean) ratio by place - values have been multiplied by the afact in 
  # 0_housing_microdata.qmd so summarizing gets the place-level value 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(ratio_rentgrs_rent = mean(ratio_rentgrs_rent, na.rm=TRUE),
                   RENT = mean(RENT), na.rm=TRUE,
                   HHINCOME = mean(HHINCOME), na.rm=TRUE,
                   HHWT = mean(HHWT), na.rm=TRUE)
# 486 obs

# (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#      This "RENTGRS" variable will be used to calculate affordability in Step 6

puma_place <- read_csv("geographic-crosswalks/data/crosswalk_puma_to_place.csv") %>% 
  filter(crosswalk_period == 2022)

# in order to be able to merge in rent_ratio, need to have places in the vacant data file
# merge in places
vacant_places  <- left_join(vacant, puma_place, by=c("statefip","puma"))

# create a concatenated GEOID for each city(e.g. census place)
puma_place$GEOID <- paste(puma_place$statefip,puma_place$place, sep = "")
vacant_places$GEOID <- paste(vacant_places$statefip,vacant_places$place, sep = "")
# limit only to places of interest
vacant_places <- vacant_places %>%
  tidylog::filter(GEOID %in% puma_place$GEOID)
#  removed 12,708 rows (42%), 17,265 rows remaining

# Merge rent ratio into vacant unit microdata
vacant_final<- left_join(vacant_places, rent_ratio, by = c("statefip", "place"))
# 1 row doesn't merge - place 0672016 which didn't have any values with VACANCY = 1, 2, or 3 (simi valley, CA)

# Update the RENTGRS variable with our calculated ratio
vacant_final <- vacant_final %>%
  mutate(RENTGRS = RENT.x*ratio_rentgrs_rent)


###################################################################

# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)
# NOTE: There is an API to do this that should be used in future updates of the data 
# but we didn't have the capacity to update in 2023

# Access via https://www.huduser.gov/portal/datasets/il.html#data_2022	

# Specify URL where source data file is online
url <- "https://www.huduser.gov/portal/datasets/il/il22/Section8-FY22.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "data/FMR_Income_Levels_2022.xlsx"

# Import the data file & save locally
download.file(url, destfile, mode="wb")

# Import the data file as a dataframe
FMR_Income_Levels_2022 <- read_excel("data/FMR_Income_Levels_2022.xlsx")

# Import data file (FY&year_4050_FMRs_rev.csv) FY2022_4050_FMRs_rev
# Access via https://www.huduser.gov/portal/datasets/fmr.html#data_2022

# Specify URL where source data file is online
url_FMR <- "https://www.huduser.gov/portal/datasets/fmr/fmr2022/FY22_FMRs_revised.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile_FMR <- "data/FMR_pop_2022.xlsx"

# Import the data file & save locally
download.file(url_FMR, destfile_FMR, mode="wb")

# Import the data file as a dataframe
FMR_pop_2022 <- read_excel("data/FMR_pop_2022.xlsx")

# (4a) Merge the 2 files

# Add the population variable onto the income level file
FMR_Income_Levels_2022 <- left_join(FMR_Income_Levels_2022, FMR_pop_2022, by=c("fips2010"))
# 4,765 obs


# (4b) Bring in county_place crosswalk
county_place <- read_csv("geographic-crosswalks/data/geocorr2022_county_place.csv") %>% 
  # prep merge variable (add lost leading zeroes and rename matching vars)
  mutate(state = sprintf("%0.2d", as.numeric(state)))

# (4c) Merge FMR file with crosswalk on county

FMR_Income_Levels_2022 <- FMR_Income_Levels_2022 %>%
  mutate(county = sprintf("%0.3d", as.numeric(county)),
         state = sprintf("%0.2d", as.numeric(state.x)))

# left join to assign places to each county-level obs
FMR_2022 <- left_join(FMR_Income_Levels_2022, county_place, by=c("state.x" = "state", "county"))
# 62,748 obs

# (4d) Create place_level_income_limits (weight by FMR population in collapse)

# Most FMRs have a one-to-one correspondence with places because most places fall into whole counties. 
# However, some counties (mainly in New England) contain multiple FMRs. For these counties, replace the 
# multiple FMR records with just one county record, using the weighted average value of the income levels, 
# weighted by the FMR population

place_income_limits_2022 <- FMR_2022 %>%
  dplyr::group_by(state, place) %>%
  dplyr::summarise(l50_1 = weighted.mean(l50_1, na.rm = T, w = pop20),
                   l50_2 = weighted.mean(l50_2, na.rm = T, w = pop20),
                   l50_3 = weighted.mean(l50_3, na.rm = T, w = pop20),
                   l50_4 = weighted.mean(l50_4, na.rm = T, w = pop20),
                   l50_5 = weighted.mean(l50_5, na.rm = T, w = pop20),
                   l50_6 = weighted.mean(l50_6, na.rm = T, w = pop20),
                   l50_7 = weighted.mean(l50_7, na.rm = T, w = pop20),
                   l50_8 = weighted.mean(l50_8, na.rm = T, w = pop20),
                   ELI_1 = weighted.mean(ELI_1, na.rm = T, w = pop20),
                   ELI_2 = weighted.mean(ELI_2, na.rm = T, w = pop20),
                   ELI_3 = weighted.mean(ELI_3, na.rm = T, w = pop20),
                   ELI_4 = weighted.mean(ELI_4, na.rm = T, w = pop20),
                   ELI_5 = weighted.mean(ELI_5, na.rm = T, w = pop20),
                   ELI_6 = weighted.mean(ELI_6, na.rm = T, w = pop20),
                   ELI_7 = weighted.mean(ELI_7, na.rm = T, w = pop20),
                   ELI_8 = weighted.mean(ELI_8, na.rm = T, w = pop20),
                   l80_1 = weighted.mean(l80_1, na.rm = T, w = pop20),
                   l80_2 = weighted.mean(l80_2, na.rm = T, w = pop20),
                   l80_3 = weighted.mean(l80_3, na.rm = T, w = pop20),
                   l80_4 = weighted.mean(l80_4, na.rm = T, w = pop20),
                   l80_5 = weighted.mean(l80_5, na.rm = T, w = pop20),
                   l80_6 = weighted.mean(l80_6, na.rm = T, w = pop20),
                   l80_7 = weighted.mean(l80_7, na.rm = T, w = pop20),
                   l80_8 = weighted.mean(l80_8, na.rm = T, w = pop20),
                   n = n()
  ) %>% 
  dplyr::rename("statefip" = "state") %>% 
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                place = sprintf("%0.5d", as.numeric(place)),
  )

place_income_limits_2022$GEOID <- paste(place_income_limits_2022$statefip,place_income_limits_2022$place, sep = "")
# limit only to places of interest
place_income_limits_2022 <- place_income_limits_2022 %>%
  filter(GEOID %in% puma_place$GEOID)
# 486 obs

###################################################################

# (5) Generate households_2022: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels) 
#     overall and for renters and owner subgroups

# Merge on the 80% and 50% AMI income levels and determine:
#  1) which households are <= 80% and <= 50% of AMI for a family of 4 
#    (regardless of the actual household size). 
#  2) which units are affordable for a family of 4 at 80% and 50% of AMI
#    (regardless of the actual unit size). "Affordable" means costs are < 30% of the AMI
#    (again, for a family of 4). For owners, use the housing cost, and for renters, 
#    use the gross rent.

# Filter microdata to where PERNUM == 1, so only one HH per observation
microdata_housing <- acs2022clean %>%
  tidylog::filter(PERNUM == 1)
# removed 1,101,760 rows (60%), 745,674 rows remaining


# create new dataset called "households_year" to merge microdata & place income limits (place_income_limits_2022) by state and place
households_2022 <- left_join(microdata_housing, place_income_limits_2022, by=c("statefip","place"))
# 745,674

# Create variables called Affordable80AMI, Affordable50AMI, Affordable30AMI
# Read more about the AMI vars methodology here: https://www.huduser.gov/portal/datasets/il//il18/IncomeLimitsMethodology-FY18.pdf
# l50 is 50% of median rent: Very low-income
# ELI is 30% of median rent: Extremely low-income
# l80 is 80% of median rent: Low-income
# For owners, use the housing cost, and for renters, use the gross rent.
# Also create variable for total population at 80% AMI, 50% AMI, and 30% AMI
# for renter and owner subgroups, this is just the population of renters or owners at each income level

# create new variable 'Affordable80AMI' and 'Below80AMI' for HH below 80% of area median income (L80_4 and OWNERSHP)
# if OWNERSHP is not equal to 1 or 2, leave as NA

households_2022 <- households_2022 %>%
  mutate(Affordable80AMI_all =
           case_when(# deal with cases when RENTGRS and OWNCOST are 0
             RENTGRS == 0 ~ 0,
             OWNERSHP==2 & ((RENTGRS*12)<=(l80_4*0.30)) ~ 1,
             OWNERSHP==2 & ((RENTGRS*12)>(l80_4*0.30)) ~ 0,
             OWNERSHP==1 & ((OWNCOST*12)<=(l80_4*0.30)) ~ 1,
             OWNERSHP==1 & ((OWNCOST*12)>(l80_4*0.30)) ~ 0),
         # create subgroups for renter and owners specifically
         Affordable80AMI_renter = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l80_4*0.30)) ~ 1,
                                            OWNERSHP==2 & ((RENTGRS*12)>(l80_4*0.30)) ~ 0,
                                            OWNERSHP==2 & RENTGRS == 0 ~ 0,), 
         Affordable80AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(l80_4*0.30)) ~ 1,
                                           OWNERSHP==1 & ((OWNCOST*12)>(l80_4*0.30)) ~ 0),
         # overall population below 80 ami
         Below80AMI = case_when((HHINCOME<l80_4) ~ 1,
                                (HHINCOME>l80_4) ~ 0),
         # renter population below 80 ami
         Below80AMI_renter = if_else((HHINCOME<l80_4 & OWNERSHP == 2), 1,0),
         # owner population below 80 ami
         Below80AMI_owner = if_else((HHINCOME<l80_4 & OWNERSHP == 1), 1,0),
         # create for data quality flag
         Below80AMI_HH = HHWT*Below80AMI
  )

# Create new variable 'Affordable50AMI' and 'Below50AMI' for HH below 50% of area median income (L50_4 and OWNERSHP)
# NOTE that we will need to create a Below50AMI_HH (the count of HH) for the Data Quality flag in step 8
households_2022<- households_2022 %>%
  mutate(
    Affordable50AMI_all = case_when(# deal with cases when RENTGRS 
      RENTGRS == 0 ~ 0,
      OWNERSHP==2 & ((RENTGRS*12)<=(l50_4*0.30)) ~ 1,
                                    OWNERSHP==2 & ((RENTGRS*12)>(l50_4*0.30)) ~ 0,
                                    OWNERSHP==1 & ((OWNCOST*12)<=(l50_4*0.30)) ~ 1,
                                    OWNERSHP==1 & ((OWNCOST*12)>(l50_4*0.30)) ~ 0),
    # create subgroup categories for renters and owners
    Affordable50AMI_renter = case_when(
      OWNERSHP==2 & RENTGRS == 0 ~ 0,
      OWNERSHP==2 & ((RENTGRS*12)<=(l50_4*0.30)) ~ 1,
      OWNERSHP==2 & ((RENTGRS*12)>(l50_4*0.30)) ~ 0),
    Affordable50AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(l50_4*0.30)) ~ 1,
                                      OWNERSHP==1 & ((OWNCOST*12)>(l50_4*0.30)) ~ 0),
    Below50AMI = case_when((HHINCOME<l50_4) ~ 1,
                           (HHINCOME>l50_4) ~ 0),
    # renter population below 80 ami
    Below50AMI_renter = if_else((HHINCOME<l50_4 & OWNERSHP == 2), 1,0),
    # owner population below 80 ami
    Below50AMI_owner = if_else((HHINCOME<l50_4 & OWNERSHP == 1), 1,0),
    # create for data quality flag
    Below50AMI_HH = HHWT*Below50AMI
  )

# create new variable 'Affordable30AMI' and 'Below80AMI' for HH below 30% of area median income (ELI_4 and OWNERSHP)
households_2022 <- households_2022 %>%
  mutate(
    Affordable30AMI_all = case_when(# deal with cases when RENTGRS 
      RENTGRS == 0 ~ 0,
      OWNERSHP==2 & ((RENTGRS*12)<=(ELI_4*0.30)) ~ 1,
                                    OWNERSHP==2 & ((RENTGRS*12)>(ELI_4*0.30)) ~ 0,
                                    OWNERSHP==1 & ((OWNCOST*12)<=(ELI_4*0.30)) ~ 1,
                                    OWNERSHP==1 & ((OWNCOST*12)>(ELI_4*0.30)) ~ 0),
    # create subgroup categories for renters and owners
    Affordable30AMI_renter = case_when(
      OWNERSHP==2 &  RENTGRS == 0 ~ 0,
      OWNERSHP==2 & ((RENTGRS*12)<=(ELI_4*0.30)) ~ 1,
      OWNERSHP==2 & ((RENTGRS*12)>(ELI_4*0.30)) ~ 0), 
    Affordable30AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(ELI_4*0.30)) ~ 1,
                                      OWNERSHP==1 & ((OWNCOST*12)>(ELI_4*0.30)) ~ 0),
    Below30AMI = case_when((HHINCOME<ELI_4) ~ 1,
                           (HHINCOME>ELI_4) ~ 0),
    # renter population below 30 ami
    Below30AMI_renter = if_else((HHINCOME<ELI_4 & OWNERSHP == 2), 1,0),
    # owner population below 30 ami
    Below30AMI_owner = if_else((HHINCOME<ELI_4 & OWNERSHP == 1), 1,0),
    # create for data quality flag
    Below30AMI_HH = HHWT*Below30AMI
  )

# save file to use for affordability measure in 2a_affordable_available_place.R
write_csv(households_2022, "data/temp/households_2022.csv")

# Data is 1/3 renters 2/3 owners 
#skimr::skim(households_2022)


###################################################################

# (6) Merge Vacant with place_level_income_limits (FMR_2022)

# Merge on the % AMI income levels and determine which vacant units are also affordable for a 
# family of 4 at %s of AMI (regardless of actual unit size). If there is a non-zero value for
# gross rent (RENTGRS), use that for the cost. Otherwise, if there is a valid house value, use the 
# housing cost that was calculated and prepared above in the "vacant" df.

vacant_2022 <- left_join(vacant_final, place_income_limits_2022, by=c("statefip","place"))
# 17,265 
# 1 row doesn't merge - place 0672016 which didn't have any values with VACANCY = 1, 2, or 3

# (6a) create same 30%, 50%, and 80% AMI affordability indicators
# Include renter and owner subgroups
# NOTE TO REVIEWER: Is it correct to assume that  if there is a zero gross rent value (RENTGRS) the unit
# is not available to rent and therefore should have an NA value? 
vacant_2022_new <- vacant_2022 %>%
  mutate(
    # 80% AMI all, renter, and owner
    Affordable80AMI_all = case_when(
      is.na(l80_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (l80_4*0.30), 
      !is.na(VALUEH) ~ (total_monthly_cost*12) <= (l80_4*0.30), 
      is.na(VALUEH) ~ NA),
    Affordable80AMI_renter = case_when(
      is.na(l80_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (l80_4*0.30)),
    Affordable80AMI_owner = case_when(
      is.na(l80_4) ~ NA, 
      !is.na(VALUEH) ~ (total_monthly_cost*12) <= (l80_4*0.30), 
      is.na(VALUEH) ~ NA),
    # 50% AMI all, renter, and owner
    Affordable50AMI_all = case_when(
      is.na(l50_4) ~ NA,
      RENTGRS > 0 ~ (RENTGRS*12) <= (l50_4*0.30), 
      !is.na(VALUEH) ~ (total_monthly_cost*12) <= (l50_4*0.30), 
      is.na(VALUEH) ~ NA), 
    Affordable50AMI_renter = case_when(
      is.na(l50_4) ~ NA,
      RENTGRS > 0 ~ (RENTGRS*12) <= (l50_4*0.30)),
    Affordable50AMI_owner = case_when(
      is.na(l50_4) ~ NA,
      !is.na(VALUEH) ~ (total_monthly_cost*12) <= (l50_4*0.30), 
      is.na(VALUEH) ~ NA), 
    # 30% AMI all, renter, and owner
    Affordable30AMI_all = case_when(
      is.na(ELI_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (ELI_4*0.30), 
      !is.na(VALUEH) ~(total_monthly_cost*12) <= (ELI_4*0.30), 
      is.na(VALUEH) ~ NA),
    Affordable30AMI_renter = case_when(
      is.na(ELI_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (ELI_4*0.30)),
    Affordable30AMI_owner = case_when(
      is.na(ELI_4) ~ NA, 
      !is.na(VALUEH) ~(total_monthly_cost*12) <= (ELI_4*0.30), 
      is.na(VALUEH) ~ NA)) %>% 
  # turn TRUE/FALSE booleans into binary 1/0 flags
  mutate(across(matches("Affordable"), ~as.integer(.x)))

# save file to use for affordability measure in 2a_affordable_available_place.R
write_csv(vacant_2022_new, "data/temp/vacant_2022.csv")

# look at data
#skimr::skim(vacant_2022_new)

###################################################################

# (7) Create the housing metric

# (7a) Summarize households_2022 and vacant both by place
households_summed_2022 <- households_2022 %>% 
  group_by(statefip, place) %>%
  # summarize all Below80AMI, Below50AMI, Below30AMI, and 
  # Affordable80AMI, Affordable50AMI, Affordable30AMI (all, renter, owner) variables
  summarise( 
    # get unweighted N for households below 30 ami for quality flag
    HH_30_ami_quality_all = sum(Below30AMI == 1),
    HH_30_ami_quality_renter = sum(Below30AMI_renter == 1), 
    HH_30_ami_quality_owner = sum(Below30AMI_owner == 1), 
    # get unweighted N for households below 50 ami for quality flag
    HH_50_ami_quality_all = sum(Below50AMI == 1),
    HH_50_ami_quality_renter = sum(Below50AMI_renter == 1), 
    HH_50_ami_quality_owner = sum(Below50AMI_owner == 1), 
    # get unweighted N for households below 80 ami for quality flag
    HH_80_ami_quality_all = sum(Below80AMI == 1),
    HH_80_ami_quality_renter = sum(Below80AMI_renter == 1), 
    HH_80_ami_quality_owner = sum(Below80AMI_owner == 1), 
    across(matches("Below|Affordable"), ~sum(.x*HHWT, na.rm = TRUE))) %>% 
  rename("state" = "statefip")

# Sum variables Affordable80AMI, Affordable50AMI, and Affordable30AMI 
# from 'vacant_2022', grouped by statefip and place, and weighted by HHWT
# save as df 'vacant_summed_2022'

vacant_summed_2022 <- vacant_2022_new %>% 
  group_by(statefip, place) %>%
  summarize(
    across(matches("Affordable"), ~ sum(.x*HHWT.x, na.rm = TRUE), 
           # create naming onvention to add _vacant after columns name
           .names = "{.col}_vacant")) %>% 
  rename("state" = "statefip")

# save csv for avaiablity calculation in 2a_affordable_available_place.R
write_csv(vacant_summed_2022, "data/temp/vacant_summed_2022.csv")

# (7b) Merge them by place
housing_2022 <- left_join(households_summed_2022, vacant_summed_2022, by=c("state","place"))
# 486 obs
# 1 place doesn't have vacancy data - place 0672016 which didn't have any values with VACANCY = 1, 2, or 3


# (7c) Calculate share_affordable metric for each level all and for subgroups (renters/owners)
housing_2022 <- housing_2022 %>%
  mutate(
    # all values
    share_affordable_80_ami_all = (Affordable80AMI_all+Affordable80AMI_all_vacant)/Below80AMI,
    share_affordable_50_ami_all = (Affordable50AMI_all+Affordable50AMI_all_vacant)/Below50AMI,
    share_affordable_30_ami_all = (Affordable30AMI_all+Affordable30AMI_all_vacant)/Below30AMI,
    # renter subgroup
    share_affordable_80_ami_renter = (Affordable80AMI_renter+Affordable80AMI_renter_vacant)/Below80AMI_renter,
    share_affordable_50_ami_renter = (Affordable50AMI_renter+Affordable50AMI_renter_vacant)/Below50AMI_renter,
    share_affordable_30_ami_renter = (Affordable30AMI_renter+Affordable30AMI_renter_vacant)/Below30AMI_renter,
    # owner subgroup
    share_affordable_80_ami_owner = (Affordable80AMI_owner+Affordable80AMI_owner_vacant)/Below80AMI_owner,
    share_affordable_50_ami_owner = (Affordable50AMI_owner+Affordable50AMI_owner_vacant)/Below50AMI_owner,
    share_affordable_30_ami_owner = (Affordable30AMI_owner+Affordable30AMI_owner_vacant)/Below30AMI_owner
  )


###################################################################

# (8) Create the Data Quality variable

# For Housing metric: total number of HH below 30/50/80% AMI 
# Create a "Size Flag" for any place-level observations made off of less than 30 observed HH
housing_2022 <- housing_2022 %>% 
  # This data quality flag is based on if the unqieghted number of observations for household below 30/50/80 ami (overall/renter/owner subgroup)
  # is less than 30 
  mutate(across(starts_with("HH_"), 
                \(x) if_else(x < 30, 1, 0)))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
place_puma <- read_csv("data/temp/place_puma.csv") %>% 
  rename("state" = "statefip")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
housing_2022 <- left_join(housing_2022, place_puma, by=c("state","place"))

# Generate the quality var (naming it housing_quality to match Kevin's notation from 2018)
housing_2022 <- housing_2022 %>% 
  mutate(across(matches("^HH_.*quality"), 
                \(x) case_when(x==0 & puma_flag==1 ~ 1, 
                               x==0 & puma_flag==2 ~ 2, 
                               x==0 & puma_flag==3 ~ 3, 
                               x==1 ~ NA))) %>% 
  # rename variables to match data quality naming convention of e.g. "share_affordable_30_ami_quality"
  rename_with(~str_replace(., "HH", "share_affordable"), matches("^HH_.*quality"))

###################################################################

# (9) Clean and export

# turn long for subgroup output
housing_2022_subgroup <- housing_2022 %>%
  # create year variable
  mutate(year = 2022) %>% 
  # seperate share_afforadable by AMI and the subgroup
  pivot_longer(cols = matches("share_affordable_"), 
               names_to = c("affordable", "subgroup"),
               names_pattern = "(.+?(?=_[^_]+$))(_[^_]+$)", # this creates two columns - "share_affordable_XXAMI" and "_owner/_renter/_all"
               values_to = "value") %>% 
  # pivot_wider again so that each share_affordable by AMI is it's own column with subgroups as rows
  pivot_wider(
    names_from = affordable, 
    values_from = value
  ) %>% 
  # clean subgroup names and add subgroup type column 
  # remove leading underscore and capitalize words
  mutate(subgroup = str_remove(subgroup, "_") %>% str_to_title(),
         subgroup_type = "tenure" ,
         # subpress counties with too small of sample size
         across(matches("share_.*ami$"), \(x) if_else(is.na(get(cur_column() %>% paste0("_quality"))), NA, x)))

# (9a) overall file
# keep what we need
housing_2022_overall <- housing_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  select(year, state, place, share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami,
         share_affordable_80_ami_quality, share_affordable_50_ami_quality, share_affordable_30_ami_quality) %>% 
  arrange(year, state, place)

# export our file as a .csv
write_csv(housing_2022_overall, "02_housing/data/housing_2022_city.csv")  

# (9b) subgroup file
# keep what we need
housing_2022_subgroup_final <- housing_2022_subgroup %>% 
  select(year, state, place,subgroup_type, subgroup, share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami, 
         share_affordable_80_ami_quality, share_affordable_50_ami_quality, share_affordable_30_ami_quality) %>% 
  arrange(year, state, place, subgroup_type, subgroup)

# export our file as a .csv
write_csv(housing_2022_subgroup_final, "02_housing/data/housing_2022_subgroups_city.csv")  

###################################################################

# (10) Quality Checks and Visualizations

# (10a) Histograms 

# share affordable at 30 AMI histogram
housing_2022_subgroup_final %>% 
  ggplot(aes(share_affordable_30_ami))+
  geom_histogram()+
  facet_wrap(~subgroup)

# share affordable at 50 AMI histogram
housing_2022_subgroup_final %>% 
  ggplot(aes(share_affordable_50_ami))+
  geom_histogram()+
  facet_wrap(~subgroup)

# share affordable at 80 AMI histogram
housing_2022_subgroup_final %>% 
  ggplot(aes(share_affordable_80_ami))+
  geom_histogram() +
  facet_wrap(~subgroup)

# (10b) Summaries

# six-number summaries (min, 25th percentile, median, mean, 75th percentile, max) 
# to explore the distribution of calculated metrics 
summary(housing_2022_overall)

# share_affordable_80AMI share_affordable_50AMI share_affordable_30AMI 
# Min.   :0.8361         Min.   :0.5428         Min.   :0.3337         
# 1st Qu.:1.2800         1st Qu.:1.0335         1st Qu.:0.7922         
# Median :1.4344         Median :1.2228         Median :1.0197        
# Mean   :1.4526         Mean   :1.2688         Mean   :1.0776         
# 3rd Qu.:1.5971         3rd Qu.:1.4820         3rd Qu.:1.2559          
# Max.   :2.4180         Max.   :2.4532         Max.   :3.6769         
# NA's   :1              NA's   :1              NA's   :1              


# (10c) Check against last years metrics

# download 2021 mobility metrics at the place level: https://datacatalog.urban.org/dataset/boosting-upward-mobility-metrics-inform-local-action-10
# and save in Downloads folder as "mobility_metrics_place.csv"
username = getwd() %>% str_match("Users/.*?/") %>% str_remove_all("Users|/")

metrics_2021 <- read_csv(paste0("C:/Users/",username,"/Downloads/mobility_metrics_place.csv")) %>% 
  filter(year == 2021) %>% 
  select(state, place, share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami) 

summary(metrics_2021)

# share_affordable_80_ami share_affordable_50_ami share_affordable_30_ami
# Min.   :0.8749          Min.   :0.6476          Min.   :0.3875         
# 1st Qu.:1.3378          1st Qu.:1.0364          1st Qu.:0.8235         
# Median :1.4754          Median :1.2509          Median :1.0533         
# Mean   :1.5016          Mean   :1.2978          Mean   :1.1260         
# 3rd Qu.:1.6485          3rd Qu.:1.5241          3rd Qu.:1.3435         
# Max.   :2.6981          Max.   :2.8454          Max.   :3.4335    


# NLIHC has an Out of Reach tool that is a good benchmark for comparing results to 
# https://nlihc.org/oor
# it's not a 1:1 equivalent measure, but gives a sense of the cost of renting in each 
# state and by zip code


# subgroup summaries
subgroup_sum <- housing_2022_subgroup %>% 
  group_by(subgroup) %>% 
  reframe(across(c("share_affordable_30_ami",
                   "share_affordable_50_ami", 
                   "share_affordable_80_ami"),
                 list("mean" = mean,"min"= min,"max"= max),na.rm = T))

# the place with the highest share affordable 30 ami for owners is Lehi, UT 
