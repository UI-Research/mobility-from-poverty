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

# collapse PERWT by place, create a variable for count per place in the collapse
# also create a collapse var for children 3-4 (who are BELOW Kindergarten age, or GRADEATT<2) 
# AND create a collapse var for children in pre-school (GRADEATT =1)
# these vars needed to calculate metric: share of kids in pre-school
metrics_preschool <- microdata_preschool_age %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(
    num_3_and_4 = sum((GRADEATT < 2) * PERWT),
    num_in_preschool = sum((GRADEATT == 1) * PERWT),
    n = n()
  )

# Compute the ratio (share of 3-4 yo kids in preschool)
metrics_preschool <- metrics_preschool %>%
  mutate(share_in_preschool = num_in_preschool/num_3_and_4)


###################################################################

# (4) Create the Data Quality variable

# Create size flag based on number of obs collapsed
metrics_preschool <- metrics_preschool %>% 
  mutate(size_flag = case_when((n < 30) ~ 1,
                               (n >= 30) ~ 0))

# bring in the PUMA flag file
# place_puma <- read_csv("data/temp/place_puma.csv")

# rename vars as needed
metrics_preschool <- metrics_preschool %>%
  dplyr::rename(state = statefip)

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_preschool <- left_join(metrics_preschool, place_puma, by=c("state","place"))

# Generate the quality var
metrics_preschool <- metrics_preschool %>% 
  mutate(share_in_preschool_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                             size_flag==0 & puma_flag==2 ~ 2,
                                             size_flag==0 & puma_flag==3 ~ 3,
                                             size_flag==1 ~ 3))

###################################################################

# (5) Cleaning and export

# add a variable for the year of the data
metrics_preschool <- metrics_preschool %>%
  mutate(
    year = 2021
  )

# order & sort the variables how we want
metrics_preschool <- metrics_preschool %>%
  select(year, state, place, share_in_preschool, 
         share_in_preschool_quality)

# Save as "metrics_preschool.csv"
write_csv(metrics_preschool, "08_education/metrics_preschool_city_2021.csv")  





