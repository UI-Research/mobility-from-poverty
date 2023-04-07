
###################################################################

# ACS Code: Income metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Bring in merged microdata
# (3) Create Income Metrics (non-subgroup)
# (4) Finish the Data Quality variable
# (5) Cleaning and export final data file

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(Hmisc)
library(ipumsr)

###################################################################

# (2) Bring in merged microdata

# Either run "0_microdata.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs2021clean <- read_csv("data/temp/2021microdata.csv")

###################################################################

# (3) Create Income Metrics (non-subgroup)

# Objective: get pctl_20 pctl_50 and pctl_80 per unique state+place for year 2021 for the var HHINCOME
# Aggregation should be weighted by HHWT

# isolate data to count each household only once (PERNUM == 1 counts head of household only)
# keep only the relevant year (for this, 2020)
acs2021income <- acs2021clean %>%
  filter(PERNUM == 1)
# 2,230,328 obs to 953,247 obs (1,277,081 dropped)

# remove "NA" records (variable codes explained here: https://usa.ipums.org/usa-action/variables/HHINCOME#codes_section)
acs2021income <- acs2021income %>%
  filter(HHINCOME != 9999999)
# no drops 

# Calculate quantiles by grouping variable
# detach(package:Hmisc)
metrics_income <- acs2021income %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(pctl_20 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.2), 
                   pctl_50 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.5),
                   pctl_80 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.8),
                   count = n())

###################################################################

# (4) Finish the Data Quality variable

# For Income metric: total number of households is the sample size we are checking
metrics_income <- metrics_income %>% 
  mutate(size_flag = case_when((count < 30) ~ 1,
                               (count >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# place_puma <- read_csv("data/temp/place_puma.csv")

metrics_income <- metrics_income %>% 
  dplyr::rename('state' = 'statefip')

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_income <- left_join(metrics_income, place_puma, by=c("state","place"))
# Generate the quality var
metrics_income <- metrics_income %>% 
  mutate(pctl_20_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                     size_flag==0 & puma_flag==2 ~ 2,
                                     size_flag==0 & puma_flag==3 ~ 3,
                                     size_flag==1 ~ 3),
         pctl_50_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                     size_flag==0 & puma_flag==2 ~ 2,
                                     size_flag==0 & puma_flag==3 ~ 3,
                                     size_flag==1 ~ 3),
         pctl_80_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                     size_flag==0 & puma_flag==2 ~ 2,
                                     size_flag==0 & puma_flag==3 ~ 3,
                                     size_flag==1 ~ 3)
  )

# Keep only relevant variables
metrics_income <- metrics_income %>% 
  select(statefip, place, pctl_20, pctl_20_quality, 
         pctl_50, pctl_50_quality, pctl_80, 
         pctl_80_quality, household, size_flag, 
         puma_flag)


###################################################################

# (5) Cleaning and export final data file

# add a variable for the year of the data
metrics_income <- metrics_income %>%
  mutate(
    year = 2021
  )

# order the variables how we want
metrics_income <- metrics_income %>% 
  select(year, state, place, pctl_20, pctl_20_quality, pctl_50, 
         pctl_50_quality, pctl_80, pctl_80_quality)

# export as CSV
write_csv(metrics_income, "01_financial-well-being/metrics_income_city_2021.csv")


