###################################################################

# ACS Code: Preschool metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:

# Source data: If you need to downloaded from IPUMS, as follows->
#   
# - "Select Samples" > ACS (1-year choice; 2021)
# - "Person" > "Education" > Select "GRADEATT"
# - "Search" > AGE (& select)
# - "Search" > PUMA (& select)
# - "Search" > FIPS (& select state & county fips)
# - Create Data Extract
# - in "Options" > "Select Data Quality Flags" > Select "GRADEATT" & "AGE"
# saved as usa_00004.dat & usa_00004.xml in directory

# (1) Housekeeping
# (2) Import the prepared microdata file 
# (3) Calculate the Preschool Metric
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

# (3) Calculate the Preschool Metric

# Isolate the data to only children 3-4 yrs old
microdata_preschool_age <- acs2021clean %>% 
  filter(AGE==3|AGE==4) 
# 44,367 obs

# re-import as survey to prep for CI
svy <- as_survey_design(microdata_preschool_age, weights = PERWT)

# use srvyr to calculate our desired metric ratio & 95% confidence interval(s)
# collapse the number of emp age people for data quality var later
metrics_preschool <- svy %>%
  mutate(preschool = (GRADEATT == 1)) %>%
  group_by(statefip, place) %>%
  summarise(share_in_preschool = survey_mean(preschool, vartype = "ci"),
            num_3_and_4 = sum(PERWT))


# Rename Confidence Interval (CI) vars
metrics_preschool <- metrics_preschool %>%
  rename(share_in_preschool_ub = share_in_preschool_upp,
         share_in_preschool_lb = share_in_preschool_low)

# adjust ub & lb values 
metrics_preschool <- metrics_preschool %>% 
  mutate(share_in_preschool_ub = pmin(1, pmax(0, share_in_preschool_ub)),
         share_in_preschool_lb = pmax(0, pmin(1, share_in_preschool_lb)))


###################################################################

# (4) Create the Data Quality variable

# For Preschool metric: total number of people ages 3 and 4
metrics_preschool <- metrics_preschool %>% 
  mutate(size_flag = case_when((num_3_and_4 < 30) ~ 1,
                               (num_3_and_4 >= 30) ~ 0))

# bring in the PUMA flag file
# place_puma <- read_csv("data/temp/place_puma.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_preschool <- left_join(metrics_preschool, place_puma, by=c("statefip","place"))

# Generate the quality var
metrics_preschool <- metrics_preschool %>% 
  mutate(share_in_preschool_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                             size_flag==0 & puma_flag==2 ~ 2,
                                             size_flag==0 & puma_flag==3 ~ 3,
                                             size_flag==1 ~ 3))

###################################################################

# (5) Cleaning and export

# rename vars as needed
metrics_preschool <- metrics_preschool %>%
  dplyr::rename(state = statefip)

# add a variable for the year of the data
metrics_preschool <- metrics_preschool %>%
  mutate(
    year = 2021
  )

# order & sort the variables how we want
metrics_preschool <- metrics_preschool %>%
  select(year, state, place, share_in_preschool, 
         share_in_preschool_ub, share_in_preschool_lb,
         share_in_preschool_quality)

# Save as "metrics_preschool.csv"
write_csv(metrics_preschool, "08_education/metrics_preschool_city_2021.csv")  





