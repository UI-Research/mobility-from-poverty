###################################################################

# ACS Code: Employment metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Import the prepared microdata file
# (3) Create the employment metric
# (4) Create the Data Quality variable
# (5) Cleaning and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)

###################################################################

# (2) Import the prepared microdata file 

# Either run "0_microdata.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs2021clean <- read_csv("data/temp/2021microdata.csv")

###################################################################

# (3) Create the employment metric

# Create a dataset of the number of 25-54 year olds by place

# first, isolate the dataset to 25-54 year olds
microdata_emp_age <- acs2021clean %>% 
  filter(AGE >= 25 & AGE <= 54) 
# 19,974,218 observations

# collapse PERWT by place, create a variable for count/freq in the collapse
num_in_emp_age <- microdata_emp_age %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_25_thru_54 = sum(PERWT),
            n = n()
  )
# 31,533 observations

# EMPSTAT values:
#  0		N/A
#  1		Employed
#  2		Unemployed
#  3		Not in labor force

# Create a dataset of the number of EMPLOYED 25-54 year olds by place
# first, isolate the dataset to EMPLOYED 25-54 year olds
microdata_emp <- acs2021clean %>% 
  filter(AGE >= 25 & AGE <= 54 & EMPSTAT == 1) 
# 15,024,978 observations

# collapse PERWT by place to get num_employed
num_employed <- microdata_emp %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_employed = sum(PERWT))
# 31,533 observations

# Merge the two datasets (num_in_emp_age and num_employed)
metrics_employment <- left_join(num_in_emp_age, num_employed, by=c("statefip", "place"))

# Compute the ratio (share employed)
metrics_employment <- metrics_employment %>%
  mutate(share_employed = num_employed/num_25_thru_54)

# Create Confidence Interval (CI) and correctly format the variables
metrics_employment <- metrics_employment %>%
  mutate(not_employed = 1 - share_employed,
         interval = 1.96 * sqrt((not_employed*share_employed)/n),
         share_employed_ub = share_employed + interval,
         share_employed_lb = share_employed - interval)

###################################################################

# (4) Create the Data Quality variable

# For Employment metric: total number of people 25 to 54 years old
metrics_employment <- metrics_employment %>% 
  mutate(size_flag = case_when((num_25_thru_54 < 30) ~ 1,
                               (num_25_thru_54 >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# puma_place <- read_csv("data/temp/puma_place.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_employment <- left_join(metrics_employment, puma_place, by=c("statefip","place"))

# Generate the quality var
metrics_employment <- metrics_employment %>% 
  mutate(share_employed_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                            size_flag==0 & puma_flag==2 ~ 2,
                                            size_flag==0 & puma_flag==3 ~ 3,
                                            size_flag==1 ~ 3))

###################################################################

# (5) Cleaning and export

# Limit to the Census Places we want 

# rename to prep for merge to places file
metrics_employment <- metrics_employment %>%
  dplyr::rename(state = statefip)

# first, bring in the places crosswalk (place-populations.csv)
places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the relevant year (for this, 2020)
places <- places %>%
  filter(year > 2019)

# left join to get rid of irrelevant places data
metrics_employment <- left_join(places, metrics_employment, by=c("state","place"))
metrics_employment <- metrics_employment %>% 
  distinct(year, state, place, .keep_all = TRUE)
# 486 obs which means correct

# add a variable for the year of the data
metrics_employment <- metrics_employment %>%
  mutate(
    year = 2021
  )

# order & sort the variables how we want
metrics_employment <- metrics_employment %>%
  select(year, state, place, share_employed, share_employed_ub, 
         share_employed_lb, share_employed_quality)

# Save as "metrics_employment.csv"
write_csv(metrics_employment, "09_employment/metrics_employment_city_2021.csv")  



