###################################################################

# ACS Code: Preschool metric, racial subgroups
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2017-2021, 5-year
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:

# Source data: If you need to downloaded from IPUMS, as follows->

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

# (2) Import the prepared subgroup microdata file 

# Either run "0_microdata_subgroup.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs5yr_clean <- read_csv("data/temp/2021microdata5yr.csv")

###################################################################

# (3) Calculate the Preschool Metric

# Isolate the data to only children 3-4 yrs old
microdata_preschool_age <- acs5yr_clean %>% 
  filter(AGE==3|AGE==4) 
# 221,209 obs 

# collapse PERWT by place, create a variable for count per PLACE & SUBGROUP in the collapse
# also create a collapse var for children 3-4 AND in pre-school (GRADEATT =1)
# these vars are needed to calculate metric: share of kids in pre-school
metrics_preschool <- microdata_preschool_age %>% 
  dplyr::group_by(statefip, place, subgroup) %>% 
  dplyr::summarize(
    num_3_and_4 = sum((GRADEATT < 2) * PERWT),
    num_in_preschool = sum((GRADEATT == 1) * PERWT),
    count = n()
  )
# only 1927 obs (should be 1944 -- will need to merge place_subgroup later to capture missings)

# Compute the ratio (share of 3-4 yo kids in preschool)
metrics_preschool <- metrics_preschool %>%
  mutate(share_in_preschool = num_in_preschool/num_3_and_4)


###################################################################

# (4) Create the Data Quality variable

# Create size flag based on number of obs collapsed per place
metrics_preschool <- metrics_preschool %>% 
  mutate(size_flag = case_when((count < 30) ~ 1,
                               (count >= 30) ~ 0))

# bring in the PUMA flag file
# place_puma <- read_csv("data/temp/place_puma.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_preschool <- left_join(metrics_preschool, place_puma, by=c("statefip","place"))

# Take care of adding in missing values for specific subgroups
# if you don't alreday have it loaded from "0_microdata_subgroup.R", then load:
# place_subgroup <- read_csv("data/temp/place_subgroup.csv")
metrics_preschool <- left_join(place_subgroup, metrics_preschool, by=c("statefip","place", "subgroup"))

# Generate the quality var & subgroup_type var
# make missing values Data Quality 3 as well
metrics_preschool <- metrics_preschool %>% 
  mutate(share_in_preschool_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                                size_flag==0 & puma_flag==2 ~ 2,
                                                size_flag==0 & puma_flag==3 ~ 3,
                                                size_flag==1 ~ 3,
                                                is.na(share_in_preschool) ~ 3),
         subgroup_type = "race-ethnicity")

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
  select(year, state, place, subgroup_type, subgroup, share_in_preschool, 
         share_in_preschool_quality)


###################################################################

# Import the original overall population values to add as "All" under "subgroup"
preschool_all <- read_csv("08_education/metrics_preschool_city_2021.csv")

preschool_all <- preschool_all %>%
  mutate(
    subgroup = "All",
    subgroup_type = "all"
  )

# Append the "All" version of the data
metrics_preschool <- bind_rows(metrics_preschool, preschool_all)

# Sort by place again to double check we have 5 observations per place (All, Black, White, Hispanic, Other)
metrics_preschool <- metrics_preschool %>%
  arrange(state, place)



# Save as "metrics_preschool.csv"
write_csv(metrics_preschool, "08_education/metrics_preschool_subgroup_city_2021.csv")  





