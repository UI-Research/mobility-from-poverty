
###################################################################

# ACS Code: Housing metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Import microdata (PUMA Place combination already done)
# (3) Create a Vacant units dataframe (e.g. limit the microdata to vacant units, 
#     which will not be accounted for when we isolate households in Steps 4 & 5)
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
# (5) Generate households_2021: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)
# (6) Merge Vacant with place_level_income_limits
#       (6a) create same 30%, 50%, and 80% AMI affordability indicators
# (7) Create the housing metric
#       (7a) Summarize households_2021 and vacant both by place
#       (7b) Merge them by place
#       (7c) Calculate share_affordable_30/50/80AMI
# (8) Clean and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(Hmisc)
library(ipumsr)
library(readxl)

###################################################################

# (2) Import microdata (PUMA Place combination already done)

# Either run "0_microdata.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs2021clean <- read_csv("data/temp/2021microdata.csv")


###################################################################

# (3) Create a Vacant units dataframe (e.g. limit the microdata to vacant units, 
#     which will not be accounted for when we isolate households in Steps 4 & 5)

# Vacancy = 1 (for rent)
# Vacancy = 2 (for sale)
# Vacancy - 3 (rented or sold but not yet occupied)
# Choosing only 1-3 excludes seasonal, occasional, and migratory units
vacant <- acs2021clean %>%
  mutate(vacant = case_when((VACANCY==1 | VACANCY==2 | VACANCY==3) ~ 1,
                            (VACANCY==0 | VACANCY>3) ~ 0))
# now 2,230,328 obs 

# adjust needed variables
vacant <- vacant %>%
  mutate(RENT = RENT*ADJUST)

# (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:

# Kevin used 3.69% as the effective mortgage rate for DC in 2016, *look up rates on FHFA*
# Using 4.15% for the USA in April 2019 (https://www.fhfa.gov/DataTools/Downloads/Pages/Monthly-Interest-Rate-Data.aspx)
# Calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation

vacant <- vacant %>%
  mutate(VALUEH = VALUEH*ADJUST,
         loan = 0.9 * VALUEH,
         month_mortgage = (4.15 / 12) / 100,
         monthly_PI = loan * month_mortgage * ((1+month_mortgage)**360)/(((1+month_mortgage)**360)-1))


# (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#      This "total_monthly_cost" variable will be used to calculate affordability in Step 6

vacant <- vacant %>%
  mutate(PMI = (.007 * loan) / 12, # typical annual PMI is .007 of loan amount (taken from Paul/Kevin)
         tax_ins = .25 * monthly_PI, # taxes assumed to be 25% of monthly PI
         total_monthly_cost = monthly_PI + PMI + tax_ins # Sum of monthly payment components
  )

# (3c) Now create accurate gross rent variable for vacant units for rent: 

rent_ratio <- acs2021clean %>% 
  select(RENT, RENTGRS, PERNUM, OWNERSHP, statefip, place)
# Keep one observation per household (PERNUM=1), and only rented ones (OWNERSHP=2)
rent_ratio <- rent_ratio %>%
  filter(PERNUM == 1,
         OWNERSHP == 2)
# 289,314 obs


# (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#      vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per place)
rent_ratio <- rent_ratio %>%
  mutate(ratio_rentgrs_rent = RENTGRS/RENT)

# Collapse (mean) ratio by place
rent_ratio <- rent_ratio %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(ratio_rentgrs_rent = mean(ratio_rentgrs_rent, na.rm=TRUE))


# (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#      This "RENTGRS" variable will be used to calculate affordability in Step 6

# create a concatenated GEOID for each city(e.g. census place)
places$GEOID <- paste(places$statefip,places$place, sep = "")
vacant$GEOID <- paste(vacant$statefip,vacant$place, sep = "")
# limit only to places of interest
vacant <- vacant %>%
  filter(GEOID %in% places$GEOID)

# Merge rent ratio into vacant unit microdata
vacant <- left_join(vacant, rent_ratio, by = c("statefip", "place"))

# Update the RENTGRS variable with our calculated ratio
vacant <- vacant %>%
  mutate(RENTGRS = RENT*ratio_rentgrs_rent)


###################################################################

# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)

# Access via https://www.huduser.gov/portal/datasets/il.html#2021_data	

# Specify URL where source data file is online
url <- "https://www.huduser.gov/portal/datasets/il/il21/Section8-FY21.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "data/temp/FMR_Income_Levels_2021.xlsx"

# Import the data file & save locally
download.file(url, destfile, mode="wb")

# Import the data file as a dataframe
FMR_Income_Levels_2021 <- read_excel("data/temp/FMR_Income_Levels_2021.xlsx")

# Import data file (FY&year_4050_FMRs_rev.csv) FY2021_4050_FMRs_rev
# Access via https://www.huduser.gov/portal/datasets/fmr.html#2021_data

# Specify URL where source data file is online
url_FMR <- "https://www.huduser.gov/portal/datasets/fmr/fmr2021/FY21_4050_FMRs_rev.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile_FMR <- "data/temp/FMR_pop_2021.xlsx"

# Import the data file & save locally
download.file(url_FMR, destfile_FMR, mode="wb")

# Import the data file as a dataframe
FMR_pop_2021 <- read_excel("data/temp/FMR_pop_2021.xlsx")

# (4a) Merge the 2 files

# Add the population variable onto the income level file
FMR_Income_Levels_2021 <- left_join(FMR_Income_Levels_2021, FMR_pop_2021, by=c("fips2010"))
# 4,766 obs


# (4b) Bring in county_place crosswalk

county_place <- read_csv("geographic-crosswalks/data/geocorr2022_county_place.csv")

# (4c) Merge FMR file with crosswalk on county

# prep merge variable (add lost leading zeroes and rename matching vars)
county_place <- county_place %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))

FMR_Income_Levels_2021 <- FMR_Income_Levels_2021 %>%
  mutate(county = sprintf("%0.3d", as.numeric(County)),
         state = sprintf("%0.2d", as.numeric(State)))

# left join to assign places to each county-level obs
FMR_2021 <- left_join(FMR_Income_Levels_2021, county_place, by=c("state", "county"))


# (4d) Create place_level_income_limits (weight by FMR population in collapse)

# Most FMRs have a one-to-one correspondence with places because most places fall into whole counties. 
# However, some counties (mainly in New England) contain multiple FMRs. For these counties, replace the 
# multiple FMR records with just one county record, using the weighted average value of the income levels, 
# weighted by the FMR population

place_income_limits_2021 <- FMR_2021 %>%
  dplyr::group_by(state, place) %>%
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

###################################################################

# (5) Generate households_2021: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)

# Merge on the 80% and 50% AMI income levels and determine:
#  1) which households are <= 80% and <= 50% of AMI for a family of 4 
#    (regardless of the actual household size). 
#  2) which units are affordable for a family of 4 at 80% and 50% of AMI
#    (regardless of the actual unit size). "Affordable" means costs are < 30% of the AMI
#    (again, for a family of 4). For owners, use the housing cost, and for renters, 
#    use the gross rent.

# Filter microdata to where PERNUM == 1, so only one HH per observation
microdata_housing <- acs2021clean %>%
  filter(PERNUM == 1)

# create new dataset called "households_year" to merge microdata & place income limits (FMR_2021) by state and place
# first rename state so it will merge
FMR_2021 <- FMR_2021 %>% 
  dplyr::rename(statefip = state) %>%
  mutate(place = sprintf("%0.5d", as.numeric(place)))
households_2021 <- left_join(microdata_housing, FMR_2021, by=c("statefip","place"))
# 2,152,591 obs


# Create variables called Affordable80AMI, Affordable50AMI, Affordable30AMI
# Read more about the AMI vars methodology here: https://www.huduser.gov/portal/datasets/il//il18/IncomeLimitsMethodology-FY18.pdf
# l50 is 50% of median rent: Very low-income
# ELI is 30% of median rent: Extremely low-income
# l80 is 80% of median rent: Low-income

# create new variable 'Affordable80AMI' and 'Below80AMI' for HH below 80% of area median income (L80_4 and OWNERSHP)
# if OWNERSHP is not equal to 1 or 2, leave as NA
households_2021 <- households_2021 %>%
  mutate(Affordable80AMI = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l80_4*0.30)) ~ 1,
                                     OWNERSHP==2 & ((RENTGRS*12)>(l80_4*0.30)) ~ 0,
                                     OWNERSHP==1 & ((OWNCOST*12)<=(l80_4*0.30)) ~ 1,
                                     OWNERSHP==1 & ((OWNCOST*12)>(l80_4*0.30)) ~ 0),
         Below80AMI = case_when((HHINCOME<l80_4) ~ 1,
                                (HHINCOME>l80_4) ~ 0)
  )

# Create new variable 'Affordable50AMI' and 'Below50AMI' for HH below 50% of area median income (L50_4 and OWNERSHP)
households_2021 <- households_2021 %>%
  mutate(Affordable50AMI = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(l50_4*0.30)) ~ 1,
                                     OWNERSHP==2 & ((RENTGRS*12)>(l50_4*0.30)) ~ 0,
                                     OWNERSHP==1 & ((OWNCOST*12)<=(l50_4*0.30)) ~ 1,
                                     OWNERSHP==1 & ((OWNCOST*12)>(l50_4*0.30)) ~ 0),
         Below50AMI = case_when((HHINCOME<l50_4) ~ 1,
                                (HHINCOME>l50_4) ~ 0)
  )

# create new variable 'Affordable30AMI' and 'Below80AMI' for HH below 30% of area median income (ELI_4 and OWNERSHP)
households_2021 <- households_2021 %>%
  mutate(Affordable30AMI = case_when(OWNERSHP==2 & ((RENTGRS*12)<=(ELI_4*0.30)) ~ 1,
                                     OWNERSHP==2 & ((RENTGRS*12)>(ELI_4*0.30)) ~ 0,
                                     OWNERSHP==1 & ((OWNCOST*12)<=(ELI_4*0.30)) ~ 1,
                                     OWNERSHP==1 & ((OWNCOST*12)>(ELI_4*0.30)) ~ 0),
         Below30AMI = case_when((HHINCOME<ELI_4) ~ 1,
                                (HHINCOME>ELI_4) ~ 0)
  )


###################################################################

# (6) Merge Vacant with place_level_income_limits (FMR_2021)

# Merge on the % AMI income levels and determine which vacant units are also affordable for a 
# family of 4 at %s of AMI (regardless of actual unit size). If there is a non-zero value for
# gross rent (RENTGRS), use that for the cost. Otherwise, if there is a valid house value, use the 
# housing cost that was calculated and prepared above in the "vacant" df.

vacant_2021 <- left_join(vacant, FMR_2021, by=c("statefip","place"))
# 4,896,161 obs

# (6a) create same 30%, 50%, and 80% AMI affordability indicators
vacant_2021 <- vacant_2021 %>%
  mutate(Affordable80AMI = case_when(RENTGRS > 0 & ((RENTGRS*12) <= (l80_4*0.30)) ~ 1,
                                     RENTGRS ==0 & ((total_monthly_cost*12) <= (l80_4*0.30)) ~ 0),
         Affordable50AMI = case_when(RENTGRS > 0 & ((RENTGRS*12) <= (l50_4*0.30)) ~ 1,
                                     RENTGRS ==0 & ((total_monthly_cost*12) <= (l50_4*0.30)) ~ 0),
         Affordable30AMI = case_when(RENTGRS > 0 & ((RENTGRS*12) <= (ELI_4*0.30)) ~ 1,
                                     RENTGRS ==0 & ((total_monthly_cost*12) <= (ELI_4*0.30)) ~ 0)
  )


###################################################################

# (7) Create the housing metric

# (7a) Summarize households_2021 and vacant both by place

households_summed_2021 <- households_2021 %>% 
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(Below80AMI = sum(Below80AMI*HHWT, na.rm = TRUE),
                  Affordable80AMI = sum(Affordable80AMI*HHWT, na.rm = TRUE),
                  Below50AMI = sum(Below50AMI*HHWT, na.rm = TRUE),
                  Affordable50AMI = sum(Affordable50AMI*HHWT, na.rm = TRUE),
                  Below30AMI = sum(Below30AMI*HHWT, na.rm = TRUE),
                  Affordable30AMI = sum(Affordable30AMI*HHWT, na.rm = TRUE))

households_summed_2021 <- households_summed_2021 %>% 
  rename("state" = "statefip")

# Sum variables Affordable80AMI, Affordable50AMI, and Affordable30AMI 
# from 'vacant_2021', grouped by statefip and place, and weighted by HHWT
# save as df 'vacant_summed_2021'

vacant_summed_2021 <- vacant_2021 %>% 
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(Affordable80AMI_vacant = sum(Affordable80AMI*HHWT, na.rm = TRUE),
                   Affordable50AMI_vacant = sum(Affordable50AMI*HHWT, na.rm = TRUE),
                   Affordable30AMI_vacant = sum(Affordable30AMI*HHWT, na.rm = TRUE))

vacant_summed_2021 <- vacant_summed_2021 %>% 
  rename("state" = "statefip")

# (7b) Merge them by place
housing_2021 <- left_join(households_summed_2021, vacant_summed_2021, by=c("state","place"))


# (7c) Calculate share_affordable metric for each level
housing_2021 <- housing_2021 %>%
  mutate(share_affordable_80AMI = (Affordable80AMI+Affordable80AMI_vacant)/Below80AMI,
         share_affordable_50AMI = (Affordable50AMI+Affordable50AMI_vacant)/Below50AMI,
         share_affordable_30AMI = (Affordable30AMI+Affordable30AMI_vacant)/Below30AMI
  )

###################################################################

# (8) Clean and export

# create the year variable
housing_2021 <- housing_2021 %>%
  mutate(year = 2021) 

# keep what we need
housing_2021 <- housing_2021 %>% 
  select(year, state, place, share_affordable_80AMI, share_affordable_50AMI, share_affordable_30AMI)

# export our file as a .csv
write_csv(housing_2021, "02_housing/data/housing_city_2021.csv")  

