
###################################################################

# ACS Code: Housing metric, non-subgroup
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# and code by Tina Chelidze in R for 2022-2023
# Process:
# (1) Housekeeping
# (2) Import microdata 
# (3) Create a Vacant unit dataframe (vacant units will not be accounted for when we isolate households in Steps 4 & 5)
#     Note that to get vacant unit data, need to pull a separate extract from IPUMS; see instructions below.
#       (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:
#       (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#               This "total_monthly_cost" variable will be used to calculate affordability in Step 6
#       (3c) Now create accurate gross rent variable for vacant units for rent: 
#       (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#             vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per county).
#       (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#               This "RENTGRS" variable will be used to calculate affordability in Step 6
# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)
#       (4a) Merge the 2 files
#       (4b) Create county_level_income_limits (weight by FMR population in collapse)
# (5) Generate households_2021: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)
# (6) Merge Vacant with county_level_income_limits
#       (6a) create same 30%, 50%, and 80% AMI affordability indicators
# (7) Create the housing metric
#       (7a) Summarize households_2021 and vacant both by county
#       (7b) Merge them by county
#       (7c) Calculate share_affordable_30/50/80AMI
# (8) Create Data Quality marker
# (9) Clean and export
# (10) Quality Checks and Visualizations
#       (10a) Histograms
#       (10b) Summaries
#       (10c) Check against last years values

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(tidylog)
library(ipumsr)
library(janitor)
library(readxl)

###################################################################

# (2) Import microdata (PUMA County combination already done)

# Either run "0_housing_microdata_county.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to counties
acs2022 <- read_csv("data/temp/2022microdata_county.csv") 

# For HH side: isolate original microdata to only GQ under 3 (only want households)
# see here for more information: https://usa.ipums.org/usa-action/variables/GQ#codes_section
acs2022clean <- acs2022 %>%
  tidylog::filter(GQ < 3) 
# removed 421,838 rows (6%), 6,914,926 rows remaining


###################################################################

# (3) Create a Vacant units dataframe (vacant units
#    will not be accounted for when we isolate households in Steps 4 & 5)

# Vacancy = 1 (for rent)
# Vacancy = 2 (for sale)
# Vacancy - 3 (rented or sold but not yet occupied)
# Choosing only 1-3 excludes seasonal, occasional, and migratory units
# drop all missing VALUEH (value of housing units) obs: https://usa.ipums.org/usa-action/variables/VALUEH#codes_section

vacant_microdata22 <- read_csv("data/temp/vacancy_microdata2022.csv") %>% 
  tidylog::filter(VACANCY==1 | VACANCY==2 | VACANCY==3)
# removed 79,676 rows (75%), 26,866 rows remaining


# (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:

# Using 6% for the USA to match the choice made by Kevin/Aaron
# Calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation

vacant <- vacant_microdata22 %>%
  mutate(VALUEH = VALUEH*ADJUST,
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
  select(RENT, RENTGRS, HHINCOME, HHWT, PERNUM, OWNERSHP, statefip, county)
# Keep one observation per household (PERNUM=1), and only rented ones (OWNERSHP=2)
rent_ratio <- rent_ratio %>%
  tidylog::filter(PERNUM == 1,
         OWNERSHP == 2)
# removed 6,217,253 rows (90%), 697,673 rows remaining

# (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#      vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per county)
rent_ratio <- rent_ratio %>%
  mutate(ratio_rentgrs_rent = RENTGRS/RENT)

# Collapse (mean) ratio by county
rent_ratio <- rent_ratio %>% 
  dplyr::group_by(statefip, county) %>% 
  dplyr::summarize(ratio_rentgrs_rent = mean(ratio_rentgrs_rent, na.rm=TRUE),
                   RENT = mean(RENT), na.rm=TRUE,
                   HHINCOME = mean(HHINCOME), na.rm=TRUE,
                   HHWT = mean(HHWT), na.rm=TRUE
  )


# (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#      This "RENTGRS" variable will be used to calculate affordability in Step 6

# in order to be able to merge in rent_ratio, need to have counties in the vacant data file
# bring in county to PUMA crosswalk if you don't have it already
puma_county <-  read_csv("geographic-crosswalks/data/crosswalk_puma_to_county.csv") %>% 
  filter(crosswalk_period == 2022) %>% 
  filter(statefip != 72)

# merge in counties
vacant_counties  <- left_join(vacant, puma_county, by=c("statefip","puma"))
# 59,580 rows

# Merge rent ratio into vacant unit microdata
vacant_final<- left_join(vacant_counties, rent_ratio, by = c("statefip", "county"))

# Update the RENTGRS variable with our calculated ratio
vacant_final <- vacant_final %>%
  mutate(RENTGRS = RENT.x*ratio_rentgrs_rent)


###################################################################

# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)

# Access via https://www.huduser.gov/portal/datasets/il.html#data_2022	

# Specify URL where source data file is online
url <- "https://www.huduser.gov/portal/datasets/il/il22/Section8-FY22.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "data/FMR_Income_Levels_2022.xlsx"

# Import the data file & save locally
download.file(url, destfile, mode="wb")

# Import the data file as a dataframe
FMR_Income_Levels_2022 <- read_excel("data/FMR_Income_Levels_2022.xlsx") %>% 
  # edit for join
  mutate(metro = as.character(metro))

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
FMR_Income_Levels_2022 <- left_join(FMR_Income_Levels_2022, FMR_pop_2022, by = "fips2010")
# 4,765 rows

FMR_Income_Levels_2022 <- FMR_Income_Levels_2022 %>%
  mutate(county = sprintf("%0.3d", as.numeric(county)),
         state = sprintf("%0.2d", as.numeric(state.x)))


# (4b) Create county_level_income_limits (weight by FMR population in collapse)

# Some counties (mainly in New England) contain multiple FMRs. For these counties, replace the 
# multiple FMR records with just one county record, using the weighted average value of the income levels, 
# weighted by the FMR population

county_income_limits_2022 <- FMR_Income_Levels_2022 %>%
  dplyr::group_by(state, county) %>%
  dplyr::summarise(l50_1 = weighted.mean(l50_1, na.rm = T, w = pop2017),
                   l50_2 = weighted.mean(l50_2, na.rm = T, w = pop2017),
                   l50_3 = weighted.mean(l50_3, na.rm = T, w = pop2017),
                   l50_4 = weighted.mean(l50_4, na.rm = T, w = pop2017),
                   l50_5 = weighted.mean(l50_5, na.rm = T, w = pop2017),
                   l50_6 = weighted.mean(l50_6, na.rm = T, w = pop2017),
                   l50_7 = weighted.mean(l50_7, na.rm = T, w = pop2017),
                   l50_8 = weighted.mean(l50_8, na.rm = T, w = pop2017),
                   ELI_1 = weighted.mean(ELI_1, na.rm = T, w = pop2017),
                   ELI_2 = weighted.mean(ELI_2, na.rm = T, w = pop2017),
                   ELI_3 = weighted.mean(ELI_3, na.rm = T, w = pop2017),
                   ELI_4 = weighted.mean(ELI_4, na.rm = T, w = pop2017),
                   ELI_5 = weighted.mean(ELI_5, na.rm = T, w = pop2017),
                   ELI_6 = weighted.mean(ELI_6, na.rm = T, w = pop2017),
                   ELI_7 = weighted.mean(ELI_7, na.rm = T, w = pop2017),
                   ELI_8 = weighted.mean(ELI_8, na.rm = T, w = pop2017),
                   l80_1 = weighted.mean(l80_1, na.rm = T, w = pop2017),
                   l80_2 = weighted.mean(l80_2, na.rm = T, w = pop2017),
                   l80_3 = weighted.mean(l80_3, na.rm = T, w = pop2017),
                   l80_4 = weighted.mean(l80_4, na.rm = T, w = pop2017),
                   l80_5 = weighted.mean(l80_5, na.rm = T, w = pop2017),
                   l80_6 = weighted.mean(l80_6, na.rm = T, w = pop2017),
                   l80_7 = weighted.mean(l80_7, na.rm = T, w = pop2017),
                   l80_8 = weighted.mean(l80_8, na.rm = T, w = pop2017),
                   n = n()
  )

county_income_limits_2022 <- county_income_limits_2022 %>% 
  dplyr::rename("statefip" = "state") %>% 
  dplyr::mutate(statefip = sprintf("%0.2d", as.numeric(statefip)),
                county = sprintf("%0.3d", as.numeric(county)),
  )
county_income_limits_2022$GEOID <- paste(county_income_limits_2022$statefip,county_income_limits_2022$county, sep = "")

# limit only to counties of interest
county_income_limits_2022 <- county_income_limits_2022 %>%
  # remove territories
  filter(!statefip %in% c(60, 66, 69, 72, 78))

###################################################################

# (5) Generate households_2022: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)

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
#removed 3,993,555 rows (58%), 2,921,371 rows remaining

# create new dataset called "households_year" to merge microdata & county income limits (county_income_limits_2022) by state and county
# county FIPS 2261 (Valdez–Cordova Census Area, Alaska) split into 2063 (Chugach Census Area) and 2066 (Copper River Census Area) 
# the county limit file has fips 2261 and the microdata has it split into 2063 and 2066
households_2022 <- left_join( microdata_housing, county_income_limits_2022, by=c("statefip","county"))


# Create variables called Affordable80AMI, Affordable50AMI, Affordable30AMI
# Read more about the AMI vars methodology here: https://www.huduser.gov/portal/datasets/il//il18/IncomeLimitsMethodology-FY18.pdf
# l50 is 50% of median rent: Very low-income
# ELI is 30% of median rent: Extremely low-income
# l80 is 80% of median rent: Low-income

# For owners, use the housing cost, and for renters, use the gross rent.
# create new variable 'Affordable80AMI' and 'Below80AMI' for HH below 80% of area median income (L80_4 and OWNERSHP)
# if OWNERSHP is not equal to 1 or 2, leave as NA

households_2022 <- households_2022 %>%
  mutate(Affordable80AMI_all = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l80_4*0.30)) ~ 1,
                                         OWNERSHP==2 & ((RENTGRS*12)>(l80_4*0.30)) ~ 0,
                                         OWNERSHP==1 & ((OWNCOST*12)<=(l80_4*0.30)) ~ 1,
                                         OWNERSHP==1 & ((OWNCOST*12)>(l80_4*0.30)) ~ 0),
         # create subgroups for renter and owners specifically
         Affordable80AMI_renter = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l80_4*0.30)) ~ 1,
                                            OWNERSHP==2 & ((RENTGRS*12)>(l80_4*0.30)) ~ 0), 
         Affordable80AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(l80_4*0.30)) ~ 1,
                                           OWNERSHP==1 & ((OWNCOST*12)>(l80_4*0.30)) ~ 0),
         Below80AMI = case_when((HHINCOME<l80_4) ~ 1,
                                (HHINCOME>l80_4) ~ 0)
  )

# Create new variable 'Affordable50AMI' and 'Below50AMI' for HH below 50% of area median income (L50_4 and OWNERSHP)
# NOTE that we will need to create a Below50AMI_HH (the count of HH) for the Data Quality flag in step 8
households_2022<- households_2022 %>%
  mutate(Affordable50AMI_all = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l50_4*0.30)) ~ 1,
                                         OWNERSHP==2 & ((RENTGRS*12)>(l50_4*0.30)) ~ 0,
                                         OWNERSHP==1 & ((OWNCOST*12)<=(l50_4*0.30)) ~ 1,
                                         OWNERSHP==1 & ((OWNCOST*12)>(l50_4*0.30)) ~ 0),
         # create subgroup categories for renters and owners
         Affordable50AMI_renter = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l50_4*0.30)) ~ 1,
                                            OWNERSHP==2 & ((RENTGRS*12)>(l50_4*0.30)) ~ 0),
         Affordable50AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(l50_4*0.30)) ~ 1,
                                           OWNERSHP==1 & ((OWNCOST*12)>(l50_4*0.30)) ~ 0),
         Below50AMI = case_when((HHINCOME<l50_4) ~ 1,
                                (HHINCOME>l50_4) ~ 0),
         Below50AMI_HH = HHWT*Below50AMI
  )

# create new variable 'Affordable30AMI' and 'Below80AMI' for HH below 30% of area median income (ELI_4 and OWNERSHP)
households_2022 <- households_2022 %>%
  mutate(Affordable30AMI_all = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(ELI_4*0.30)) ~ 1,
                                         OWNERSHP==2 & ((RENTGRS*12)>(ELI_4*0.30)) ~ 0,
                                         OWNERSHP==1 & ((OWNCOST*12)<=(ELI_4*0.30)) ~ 1,
                                         OWNERSHP==1 & ((OWNCOST*12)>(ELI_4*0.30)) ~ 0),
         # create subgroup categories for renters and owners
         Affordable30AMI_renter = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(ELI_4*0.30)) ~ 1,
                                            OWNERSHP==2 & ((RENTGRS*12)>(ELI_4*0.30)) ~ 0), 
         Affordable30AMI_owner = case_when(OWNERSHP==1 & ((OWNCOST*12)<=(ELI_4*0.30)) ~ 1,
                                           OWNERSHP==1 & ((OWNCOST*12)>(ELI_4*0.30)) ~ 0),
         Below30AMI = case_when((HHINCOME<ELI_4) ~ 1,
                                (HHINCOME>ELI_4) ~ 0)
  )

# save file to use for affordability measure in 2b_afordable_available_county.R
write_csv(households_2022, "data/temp/households_2022_county.csv")

# NOTE TO REVIEWER: for 30AMI/50AMI/80AMI a quarter of owner values are missing 
# and 3/4 of renter values are missing - I'm not positive why 
# potentially because that's the distribution of renters/owners in the micro data but I'm not familiar
# enough with microdata to sniff test that guess
skim(households_2022)

###################################################################

# (6) Merge Vacant with county_level_income_limits (FMR_2022)

# Merge on the % AMI income levels and determine which vacant units are also affordable for a 
# family of 4 at %s of AMI (regardless of actual unit size). If there is a non-zero value for
# gross rent (RENTGRS), use that for the cost. Otherwise, if there is a valid house value, use the 
# housing cost that was calculated and prepared above in the "vacant" df.
# Note: I believe that the split county in alaska is what it not merged in this join but would be 
# good for the reviewer to double check throughout
vacant_2022 <- left_join(vacant_final, county_income_limits_2022, by=c("statefip","county"))


# (6a) create same 30%, 50%, and 80% AMI affordability indicators

vacant_2022_new <- vacant_2022 %>%
  mutate(
    # 80% AMI all, renter, and owner
    Affordable80AMI_all = case_when(
      is.na(l80_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (l80_4*0.30), 
      VALUEH != 9999999 ~ (total_monthly_cost*12) <= (l80_4*0.30), 
      VALUEH == 9999999 ~ NA),
    Affordable80AMI_renter = case_when(
      is.na(l80_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (l80_4*0.30)),
    Affordable80AMI_owner = case_when(
      is.na(l80_4) ~ NA, 
      VALUEH != 9999999 ~ (total_monthly_cost*12) <= (l80_4*0.30), 
      VALUEH == 9999999 ~ NA),
    # 50% AMI all, renter, and owner
    Affordable50AMI_all = case_when(
      is.na(l50_4) ~ NA,
      RENTGRS > 0 ~ (RENTGRS*12) <= (l50_4*0.30), 
      VALUEH != 9999999 ~ (total_monthly_cost*12) <= (l50_4*0.30), 
      VALUEH == 9999999 ~ NA), 
    Affordable50AMI_renter = case_when(
      is.na(l50_4) ~ NA,
      RENTGRS > 0 ~ (RENTGRS*12) <= (l50_4*0.30)),
    Affordable50AMI_owner = case_when(
      is.na(l50_4) ~ NA,
      VALUEH != 9999999 ~ (total_monthly_cost*12) <= (l50_4*0.30), 
      VALUEH == 9999999 ~ NA), 
    # 30% AMI all, renter, and owner
    Affordable30AMI_all = case_when(
      is.na(ELI_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (ELI_4*0.30), 
      VALUEH != 9999999 ~(total_monthly_cost*12) <= (ELI_4*0.30), 
      VALUEH == 9999999 ~ NA),
    Affordable30AMI_renter = case_when(
      is.na(ELI_4) ~ NA, 
      RENTGRS > 0 ~ (RENTGRS*12) <= (ELI_4*0.30)),
    Affordable30AMI_owner = case_when(
      is.na(ELI_4) ~ NA, 
      VALUEH != 9999999 ~(total_monthly_cost*12) <= (ELI_4*0.30), 
      VALUEH == 9999999 ~ NA)) %>% 
  # turn TRUE/FALSE booleans into binary 1/0 flags
  mutate(across(matches("Affordable"), ~as.integer(.x)))


###################################################################

# (7) Create the housing metric

# (7a) Summarize households_2021 and vacant both by county
households_summed_2022 <- households_2022 %>% 
  dplyr::group_by(statefip, county) %>%
  # summarize all Below80AMI, Below50AMI, Below30AMI, and 
  # Affordable80AMI, Affordable50AMI, Affordable30AMI (all, renter, owner) variables
  dplyr::summarise(across(matches("Below|Affordable"), ~sum(.x*HHWT, na.rm = TRUE)), 
                   HHobs_count = n()) %>% 
  rename("state" = "statefip")

# Sum variables Affordable80AMI, Affordable50AMI, and Affordable30AMI 
# from 'vacant_2022', grouped by statefip and county, and weighted by HHWT
# save as df 'vacant_summed_2022'

vacant_summed_2022 <- vacant_2022_new %>% 
  dplyr::group_by(statefip, county) %>%
  dplyr::summarize(across(matches("Affordable"), ~ sum(.x*HHWT.x, na.rm = TRUE), 
                          # create naming onvention to add _vacant after columns name
                          .names = "{.col}_vacant"),
                   vacantHHobs_count = n()) %>% 
  rename("state" = "statefip")

# save csv for avaiablity calculation in 2b_affordable_available_county.R
write_csv(vacant_summed_2022, "data/temp/vacant_summed_2022_county.csv")


# (7b) Merge them by county
housing_2022 <- left_join(households_summed_2022, vacant_summed_2022, by=c("state","county"))
# 3,143 obs

# (7c) Calculate share_affordable metric for each level
housing_2022 <- housing_2022 %>%
  mutate(
    # all values
    share_affordable_80_ami_all = (Affordable80AMI_all+Affordable80AMI_all_vacant)/Below80AMI,
    share_affordable_50_ami_all = (Affordable50AMI_all+Affordable50AMI_all_vacant)/Below50AMI,
    share_affordable_30_ami_all = (Affordable30AMI_all+Affordable30AMI_all_vacant)/Below30AMI,
    # renter subgroup
    share_affordable_80_ami_renter = (Affordable80AMI_renter+Affordable80AMI_renter_vacant)/Below80AMI,
    share_affordable_50_ami_renter = (Affordable50AMI_renter+Affordable50AMI_renter_vacant)/Below50AMI,
    share_affordable_30_ami_renter = (Affordable30AMI_renter+Affordable30AMI_renter_vacant)/Below30AMI,
    # owner subgroup
    share_affordable_80_ami_owner = (Affordable80AMI_owner+Affordable80AMI_owner_vacant)/Below80AMI,
    share_affordable_50_ami_owner = (Affordable50AMI_owner+Affordable50AMI_owner_vacant)/Below50AMI,
    share_affordable_30_ami_owner = (Affordable30AMI_owner+Affordable30AMI_owner_vacant)/Below30AMI
  )


###################################################################

# (8) Create the Data Quality variable

# (8a) For Housing metric: total number of HH below 50% AMI (need to add HH + vacant units)
# Create a "Size Flag" for any county-level observations made off of less than 30 observed HH, vacant or otherwise
housing_2022 <- housing_2022 %>% 
  mutate(affordableHH_sum = HHobs_count + vacantHHobs_count,
         county_size_flag = case_when((affordableHH_sum < 30) ~ 1,
                               (affordableHH_sum >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata_county.R" before this
county_puma <- read_csv("data/temp/county_puma.csv")


# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
housing_2022 <- left_join(housing_2022, county_puma, by=c("state" = "statefip","county"))

# Generate the quality var (naming it housing_quality to match Kevin's notation from 2018)
housing_2022 <- housing_2022 %>% 
  mutate(housing_quality = case_when(county_size_flag==0 & puma_flag==1 ~ 1,# 579
                                     county_size_flag==0 & puma_flag==2 ~ 2,# 454
                                     county_size_flag==0 & puma_flag==3 ~ 3,# 2110
                                     county_size_flag==1 ~ 3))


###################################################################

# (9) Clean and export

# turn long for subgroup output
housing_2022_subgroup <- housing_2022 %>%
  # create year variable
  mutate(year = 2022) %>% 
  # seperate share_afforadable by AMI and the subgroup
  pivot_longer(cols = c(contains("share_affordable")), 
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
         subgroup_type = "renter-owner" )

# (9a) overall file
# keep what we need
housing_2022_overall <- housing_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  select(year, state, county, share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami, housing_quality) %>% 
  arrange(year, state, county)

# export our file as a .csv
write_csv(housing_2022_overall, "02_housing/data/housing_2022_county.csv")  

# (9b) subgroup file
# keep what we need
housing_2022_subgroup_final <- housing_2022_subgroup %>% 
  select(year, state, county,subgroup_type, subgroup, share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami, housing_quality) %>% 
  arrange(year, state, county, subgroup_type, subgroup)

# export our file as a .csv
write_csv(housing_2022_subgroup_final, "02_housing/data/housing_2022_subgroups_county.csv")  


###################################################################

# (10) Quality Checks and Visualizations

# (10a) Histograms 

# share affordable at 30 AMI histogram
housing_2022_subgroup %>% 
  ggplot(aes(share_affordable_30_ami))+
  geom_histogram()+
  scale_x_continuous(limits = c(0, 3))+
  facet_wrap(~subgroup)

# share affordable at 50 AMI histogram
housing_2022_subgroup %>% 
  ggplot(aes(share_affordable_50_ami))+
  geom_histogram()+
  scale_x_continuous(limits = c(0, 3))+
  facet_wrap(~subgroup)

# share affordable at 80 AMI histogram
housing_2022_subgroup %>% 
  ggplot(aes(share_affordable_80_ami))+
  scale_x_continuous(limits = c(0, 3))+
  geom_histogram() +
  facet_wrap(~subgroup)

# (10b) Summaries

# six-number summaries (min, 25th percentile, median, mean, 75th percentile, max) 
# to explore the distribution of calculated metrics 
summary(housing_2022_overall)


# share_affordable_80_ami share_affordable_50_ami share_affordable_30_ami housing_quality
# Min.   :  1.075         Min.   :  0.8355        Min.   :  0.5171        Min.   :1.000  
# 1st Qu.:  1.650         1st Qu.:  1.6919        1st Qu.:  1.5934        1st Qu.:2.000  
# Median :  1.844         Median :  1.9903        Median :  1.9610        Median :3.000  
# Mean   :  2.306         Mean   :  2.3997        Mean   :  2.2557        Mean   :2.487  
# 3rd Qu.:  2.177         3rd Qu.:  2.3880        3rd Qu.:  2.3679        3rd Qu.:3.000  
# Max.   :139.485         Max.   :104.8880        Max.   :147.8675        Max.   :3.000  

# (10c) Check against 2021 values

# read in 2021 data
# download 2021 mobility metrics at the place level: https://datacatalog.urban.org/dataset/boosting-upward-mobility-metrics-inform-local-action-10
metrics_2021 <- read_csv("C:/Users/ARogin/Downloads/mobility_metrics_county.csv") %>% 
  filter(year == 2021) %>% 
  select(share_affordable_80_ami, share_affordable_50_ami, share_affordable_30_ami) 

summary(metrics_2021)


# share_affordable_80_ami share_affordable_50_ami share_affordable_30_ami
# Min.   :1.018           Min.   :0.7835          Min.   :0.432          
# 1st Qu.:1.580           1st Qu.:1.6170          1st Qu.:1.562          
# Median :1.696           Median :1.8479          Median :1.827          
# Mean   :1.692           Mean   :1.8304          Mean   :1.788          
# 3rd Qu.:1.800           3rd Qu.:2.0571          3rd Qu.:2.054          
# Max.   :2.380           Max.   :3.0197          Max.   :3.521

#  2021 metric histograms
# share affordable at 30 AMI histogram
metrics_2021 %>% 
  ggplot(aes(share_affordable_30_ami))+
  geom_histogram()+
  scale_x_continuous(limits = c(0, 3))

# share affordable at 50 AMI histogram
metrics_2021 %>% 
  ggplot(aes(share_affordable_50_ami))+
  geom_histogram()+
  scale_x_continuous(limits = c(0, 3))

# share affordable at 80 AMI histogram
metrics_2021 %>% 
  ggplot(aes(share_affordable_80_ami))+
  scale_x_continuous(limits = c(0, 3))+
  geom_histogram() 
