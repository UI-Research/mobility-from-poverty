###################################################################

# ACS Code: Income metric, racial subgroups
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2017-2021, 5-year
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Bring in merged microdata
# (3) Create Income Metrics (subgroup)
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
# acs2021clean <- read_csv("data/temp/2021microdata5yr.csv")

###################################################################

# (3) Create Income Metrics (non-subgroup)

# Objective: get pctl_20 pctl_50 and pctl_80 per unique state+place for year 2021 for the var HHINCOME
# Aggregation should be weighted by HHWT

# isolate data to count each household only once (PERNUM == 1 counts head of household only)
# keep only the relevant year (for this, 2020)
acs5yr_income <- acs5yr_clean %>%
  filter(PERNUM == 1)
# 4,510,687 obs (6,072,446 dropped from acs5yr_clean)

# remove "NA" records (variable codes explained here: https://usa.ipums.org/usa-action/variables/HHINCOME#codes_section)
acs5yr_income <- acs5yr_income %>%
  filter(HHINCOME != 9999999)
# no drops 

# Calculate quantiles by grouping variables (geography and subgroup)
# detach(package:Hmisc)
metrics_income <- acs5yr_income %>%
  dplyr::group_by(statefip, place, subgroup) %>%
  dplyr::summarize(pctl_20 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.2), 
                   pctl_50 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.5),
                   pctl_80 = Hmisc::wtd.quantile(HHINCOME, weights = HHWT, probs = 0.8),
                   count = n())
# 1944 obs (this is 486 - the # of places - times 4 - the number of race groups - so good to go)

###################################################################

# (4) Finish the Data Quality variable

# For Income metric: total number of households is the sample size we are checking
metrics_income <- metrics_income %>% 
  mutate(size_flag = case_when((count < 30) ~ 1,
                               (count >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# place_puma <- read_csv("data/temp/place_puma.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_income <- left_join(metrics_income, place_puma, by=c("statefip","place"))
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


metrics_income <- metrics_income %>% 
  dplyr::rename('state' = 'statefip')


###################################################################

# (5) Cleaning and export final data file

# add a variable for the year of the data
metrics_income <- metrics_income %>%
  mutate(
    year = 2021
  )

# order the variables how we want
metrics_income <- metrics_income %>% 
  select(year, state, place, subgroup, pctl_20, pctl_20_quality, pctl_50, 
         pctl_50_quality, pctl_80, pctl_80_quality)



###################################################################

# Import the original overall population values to add as "All" under "subgroup"
income_all <- read_csv("01_financial-well-being/metrics_income_city_2021.csv")

income_all <- income_all %>%
  mutate(
    subgroup = "All"
  )

# Append the "All" version of the data
metrics_income <- bind_rows(metrics_income, income_all)

# Sort by place again to double check we have 5 observations per place (All, Black, White, Hispanic, Other)
metrics_income <- metrics_income %>%
  arrange(state, place)


# export as CSV
write_csv(metrics_income, "01_financial-well-being/metrics_income_subgroup_city_2021.csv")



