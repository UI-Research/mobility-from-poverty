
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
library(tidyr)
library(dplyr)
library(readr)
library(tidyverse)
library(Hmisc)
library(plyr)
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

# Calculate quantiles by grouping variable
# detach(package:Hmisc)
metrics_income <- acs2021clean %>%
  dplyr::group_by(statefip, place) %>%
  dplyr::summarize(pctl_20 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.2), 
                   pctl_50 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.5),
                   pctl_80 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.8),
                   household = sum(HHWT))


###################################################################

# (4) Finish the Data Quality variable

# For Income metric: total number of households is the sample size we are checking
metrics_income <- metrics_income %>% 
  mutate(size_flag = case_when((household < 30) ~ 1,
                               (household >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# puma_place <- read_csv("data/temp/puma_place.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_income <- left_join(metrics_income, puma_place, by=c("statefip","place"))
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
  select(state, place, pctl_20, pctl_20_quality, 
         pctl_50, pctl_50_quality, pctl_80, 
         pctl_80_quality, household, size_flag, 
         puma_flag)

metrics_income <- metrics_income %>% 
  dplyr::rename('state' = 'statefip')
      
# Limit to the Census Places we want 
# first, bring in the places crosswalk (place-populations.csv)
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the relevant year (for this, 2020)
places <- places %>%
  filter(year > 2019)

# left join to get rid of irrelevant places data
metrics_income <- left_join(places, metrics_income, by=c("state","place"))
metrics_income <- metrics_income %>% 
  distinct(state, place, pctl_20, pctl_20_quality, 
           pctl_50, pctl_50_quality, pctl_80, 
           pctl_80_quality, household, size_flag, 
           puma_flag, .keep_all = TRUE)
# 486 obs which means correct


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


