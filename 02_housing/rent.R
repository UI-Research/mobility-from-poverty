###################################################################

# ACS Code: Rent Burden metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:


# (1) Housekeeping
# (2) Bring in data: FMR income levels & population per FMR
# (3) Calculate the Rent Burden for each AMI group
# (4) Add Data Quality marker(s)
# (5) Clean and export

###################################################################

# (1) Housekeeping

# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)
library(readxl)
library(tidyverse)

###################################################################

# (2) Bring in data: FMR income levels & population per FMR

# Prepare a file containing HUD income levels for each county. This requires first
# importing a file with the income limits for each FMR, as well as a file that 
# includes the population for each FMR
# Access via https://www.huduser.gov/portal/datasets/il.html#2021_data	

# Specify URL where source data file is online
url <- "https://www.huduser.gov/portal/datasets/il/il21/Section8-FY21.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "C:/Users/tchelidze/Downloads/FMR_Income_Levels_2021.xlsx"

# Import the data file & save locally
download.file(url, destfile, mode="wb")

# Import the data file as a dataframe
FMR_Income_Levels_2021 <- read_excel("C:/Users/tchelidze/Downloads/FMR_Income_Levels_2021.xlsx")



# Import data file (FY&year_4050_FMRs_rev.csv) FY2021_4050_FMRs_rev
# Access via https://www.huduser.gov/portal/datasets/fmr.html#2021_data

# Specify URL where source data file is online
url_FMR <- "https://www.huduser.gov/portal/datasets/fmr/fmr2021/FY21_4050_FMRs_rev.xlsx"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile_FMR <- "C:/Users/tchelidze/Downloads/FMR_pop_2021.xlsx"

# Import the data file & save locally
download.file(url_FMR, destfile_FMR, mode="wb")

# Import the data file as a dataframe
FMR_pop_2021 <- read_excel("C:/Users/tchelidze/Downloads/FMR_pop_2021.xlsx")


# sort the data file (FMR_Income_Levels_2021) by fips2010
FMR_Income_Levels_2021 <- FMR_Income_Levels_2021 %>%
  arrange(fips2010)


# Convert the FMR code on the population file from a character string to a number,
# and add the population variable onto the income level file
FMR_Income_Levels_2021 <- left_join(FMR_Income_Levels_2021, FMR_pop_2021, by=c("fips2010"))


### Make some final adjustments to the income file so it can be matched to the ACS microdata by counties
# add in the lost leading zeroes for the state and county FIPs
FMR_Income_Levels_2021 <- FMR_Income_Levels_2021 %>%
  mutate(county = sprintf("%0.3d", as.numeric(County)),
         state = sprintf("%0.2d", as.numeric(State))
  )

###################################################################

# (3) Calculate the Rent Burden for each AMI group

# Import the prepared microdata file 
# Either run "0_microdata.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs2021clean <- read_csv("data/temp/2021microdata.csv")

# Filter microdata to where PERNUM == 1, so only one HH per observation, and OWNERSHP == 2, so only rentals
microdata <- acs2021clean %>%
  filter(PERNUM == 1 & OWNERSHP == 2)
# 5,369,803 obs

# bring in place-county crosswalk
county_place <- read_csv("C:/Users/tchelidze/Downloads/geocorr2022_county_place.csv")

# prep merge variable (add lost leading zeroes and rename matching vars)
county_place <- county_place %>%
  mutate(statefip = sprintf("%0.2d", as.numeric(state)),
         place = sprintf("%0.5d", as.numeric(place)))

# merge into FMR data
FMR_2021 <- left_join(FMR_Income_Levels_2021, county_place, by=c("statefip", "county"))

# Limit microdata to only relevant cities to save memory
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the relevant year (for this, 2020)
places <- places %>%
  filter(year > 2019)
places <- places %>%
  rename(statefip = state)
# left join to get rid of irrelevant places data
microdata <- left_join(places, microdata, by=c("statefip","place"))


# Merge the microdata file and the FMR Income Levels file
FMR_2021 <- FMR_2021 %>% 
  rename(statefip = state)
renters_2021 <- left_join(microdata, FMR_2021, by=c("statefip","place"))

# create indicator of HHs under given AMI
renters_2021 <- renters_2021 %>%
  mutate(below_80_ami = case_when((HHINCOME<l80_4) ~ 1,
                                  (HHINCOME>l80_4) ~ 0)
  )
renters_2021 <- renters_2021 %>%
  mutate(below_50_ami = case_when((HHINCOME<l50_4) ~ 1,
                                  (HHINCOME>l50_4) ~ 0)
  )
renters_2021 <- renters_2021 %>%
  mutate(below_30_ami = case_when((HHINCOME<ELI_4) ~ 1,
                                  (HHINCOME>ELI_4) ~ 0)
  )

# is rent >50% of HH income?
renters_2021 <- renters_2021 %>%
  mutate(rent_burden_80AMI = case_when(below_80_ami==1 & ((RENTGRS*12)>(HHINCOME/2)) ~ 1,
                                       below_80_ami==1 & ((RENTGRS*12)<=(HHINCOME/2)) ~ 0,
                                       below_80_ami==0 ~ 0
  ))
renters_2021 <- renters_2021 %>%
  mutate(rent_burden_50AMI = case_when(below_50_ami==1 & ((RENTGRS*12)>(HHINCOME/2)) ~ 1,
                                       below_50_ami==1 & ((RENTGRS*12)<=(HHINCOME/2)) ~ 0,
                                       below_50_ami==0 ~ 0
  ))
renters_2021 <- renters_2021 %>%
  mutate(rent_burden_30AMI = case_when(below_30_ami==1 & ((RENTGRS*12)>(HHINCOME/2)) ~ 1,
                                       below_30_ami==1 & ((RENTGRS*12)<=(HHINCOME/2)) ~ 0,
                                       below_30_ami==0 ~ 0
  ))


# Summarize data by place 
# vars to sum: below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI

renters_summed_wgt_2021 <- renters_2021 %>% 
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(below_80_ami = sum(below_80_ami*HHWT),
            rent_burden_80AMI = sum(rent_burden_80AMI*HHWT),
            below_50_ami = sum(below_50_ami*HHWT),
            rent_burden_50AMI = sum(rent_burden_50AMI*HHWT),
            below_30_ami = sum(below_30_ami*HHWT),
            rent_burden_30AMI = sum(rent_burden_30AMI*HHWT))


# Now create the share variable (the metric) for each level
renters_summed_2021 <- renters_summed_wgt_2021 %>%
  mutate(share_burdened_80_ami = rent_burden_80AMI/below_80_ami,
         share_burdened_50_ami = rent_burden_50AMI/below_50_ami,
         share_burdened_30_ami = rent_burden_30AMI/below_30_ami
  )

# Get unweighted count in each place for each metric
renters_unwgt_2021 <- renters_2021 %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(unwgt_below_80_ami = sum(below_80_ami),
            unwgt_below_50_ami = sum(below_50_ami),
            unwgt_below_30_ami = sum(below_30_ami))

# Merge in unweighted counts
renters_summed_2021 <- left_join(renters_summed_2021, renters_unwgt_2021, by=c("statefip", "place"))

# Compute upper bound and lower bound
renters_summed_2021 <- renters_summed_2021 %>%
  mutate(inverse_80_ami = 1-share_burdened_80_ami,
         inverse_50_ami = 1-share_burdened_50_ami,
         inverse_30_ami = 1-share_burdened_30_ami,
         interval_80_ami = 1.96*sqrt((inverse_80_ami*share_burdened_80_ami)/unwgt_below_80_ami),
         interval_50_ami = 1.96*sqrt((inverse_50_ami*share_burdened_50_ami)/unwgt_below_50_ami),
         interval_30_ami = 1.96*sqrt((inverse_30_ami*share_burdened_30_ami)/unwgt_below_30_ami),
         share_burdened_80_ami_ub = share_burdened_80_ami + interval_80_ami,
         share_burdened_50_ami_ub = share_burdened_50_ami + interval_50_ami,
         share_burdened_30_ami_ub = share_burdened_30_ami + interval_30_ami,
         share_burdened_80_ami_lb = share_burdened_80_ami - interval_80_ami,
         share_burdened_50_ami_lb = share_burdened_50_ami - interval_50_ami,
         share_burdened_30_ami_lb = share_burdened_30_ami - interval_30_ami
  )



###################################################################

# (4) Add Data Quality marker(s)

# For Rent Burden metric: number of HH that fall in each category
renters_summed_2021 <- renters_summed_2021 %>% 
  mutate(size_flag_80 = case_when((unwgt_below_80_ami < 30) ~ 1,
                                  (unwgt_below_80_ami >= 30) ~ 0),
         size_flag_50 = case_when((unwgt_below_50_ami < 30) ~ 1,
                                  (unwgt_below_50_ami >= 30) ~ 0),
         size_flag_30 = case_when((unwgt_below_30_ami < 30) ~ 1,
                                  (unwgt_below_30_ami >= 30) ~ 0)
                                  )

# bring in the PUMA flag file
# puma_place <- read_csv("C:/Users/tchelidze/Downloads/puma_place.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
renters_summed_2021 <- left_join(renters_summed_2021, puma_place, by=c("statefip","place"))

# Generate the quality var
renters_summed_2021 <- renters_summed_2021 %>% 
  mutate(share_burdened_80_ami_quality = case_when(size_flag_80==0 & puma_flag==1 ~ 1,
                                                   size_flag_80==0 & puma_flag==2 ~ 2,
                                                   size_flag_80==0 & puma_flag==3 ~ 3,
                                                   size_flag_80==1 ~ 3),
         share_burdened_50_ami_quality = case_when(size_flag_50==0 & puma_flag==1 ~ 1,
                                                   size_flag_50==0 & puma_flag==2 ~ 2,
                                                   size_flag_50==0 & puma_flag==3 ~ 3,
                                                   size_flag_50==1 ~ 3),
         share_burdened_30_ami_quality = case_when(size_flag_30==0 & puma_flag==1 ~ 1,
                                                   size_flag_30==0 & puma_flag==2 ~ 2,
                                                   size_flag_30==0 & puma_flag==3 ~ 3,
                                                   size_flag_30==1 ~ 3)
         )

###################################################################

# (5) Clean and export

# left join to get rid of irrelevant places data
renters_summed_2021 <- left_join(places, renters_summed_2021, by=c("statefip","place"))
renters_summed_2021 <- renters_summed_2021 %>% 
  distinct(statefip, place, share_burdened_80_ami, share_burdened_80_ami_ub, share_burdened_80_ami_lb, share_burdened_80_ami_quality,
           share_burdened_50_ami, share_burdened_50_ami_ub, share_burdened_50_ami_lb, share_burdened_50_ami_quality,
           share_burdened_30_ami, share_burdened_30_ami_ub, share_burdened_30_ami_lb, share_burdened_30_ami_quality, .keep_all = TRUE)

# create the year variable
renters_summed_2021 <- renters_summed_2021 %>%
  mutate(
    year = 2021
  )

renters_summed_2021 <- renters_summed_2021 %>%
  dplyr::rename(state = statefip)

# keep what we need
renters_summed_2021 <- renters_summed_2021 %>% 
  select(year, state, place, 
         share_burdened_80_ami, share_burdened_80_ami_ub, share_burdened_80_ami_lb, share_burdened_80_ami_quality,
         share_burdened_50_ami, share_burdened_50_ami_ub, share_burdened_50_ami_lb, share_burdened_50_ami_quality,
         share_burdened_30_ami, share_burdened_30_ami_ub, share_burdened_30_ami_lb, share_burdened_30_ami_quality)

# export our file as a .csv
# write_csv(renters_summed_2021, "08_education/data/rent_burden_city_2021.csv")  
write_csv(renters_summed_2021, "C:/Users/tchelidze/Downloads/rent_burden_city_2021.csv")

