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
# 1,193,945 obs

# collapse PERWT by place, create a variable for count per place in the collapse
num_3_and_4 <- microdata_preschool_age %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_3_and_4 = sum(PERWT),
            n = n()
  )

# Isolate further to children 3-4 AND in pre-school 
microdata_preschool <- acs2021clean %>% 
  dplyr::filter((AGE==3|AGE==4) & GRADEATT == 1) 

# collapse PERWT by place
num_in_preschool <- microdata_preschool %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_in_preschool = sum(PERWT))


# Combine the two files to get the ratio we need: share of kids in pre-school
metrics_preschool <- left_join(num_3_and_4, num_in_preschool, by=c("statefip", "place"))

# Compute the ratio (share of 3-4 yo kids in preschool)
metrics_preschool <- metrics_preschool %>%
  mutate(share_in_preschool = num_in_preschool/num_3_and_4)


# Create Confidence Interval (CI) and correctly format the variables
metrics_preschool <- metrics_preschool %>%
  mutate(not_in_pre = 1 - share_in_preschool,
         interval = 1.96*sqrt((not_in_pre*share_in_preschool)/n),
         share_in_preschool_ub = share_in_preschool + interval,
         share_in_preschool_lb = share_in_preschool - interval)


# adjust ub & lb values 
metrics_preschool$share_in_preschool_ub[metrics_preschool$share_in_preschool_ub > 1] <- 1
metrics_preschool$share_in_preschool_lb[metrics_preschool$share_in_preschool_lb < 0] <- 0


###################################################################

# (4) Create the Data Quality variable

# For Preschool metric: total number of people ages 3 and 4
metrics_preschool <- metrics_preschool %>% 
  mutate(size_flag = case_when((num_3_and_4 < 30) ~ 1,
                               (num_3_and_4 >= 30) ~ 0))

# bring in the PUMA flag file
# puma_place <- read_csv("data/temp/puma_place.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_preschool <- left_join(metrics_preschool, puma_place, by=c("statefip","place"))

# Generate the quality var
metrics_preschool <- metrics_preschool %>% 
  mutate(share_in_preschool_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                             size_flag==0 & puma_flag==2 ~ 2,
                                             size_flag==0 & puma_flag==3 ~ 3,
                                             size_flag==1 ~ 3))

###################################################################

# (5) Cleaning and export

# Limit to the Census Places we want 

# rename to prep for merge to places file
metrics_preschool <- metrics_preschool %>%
  dplyr::rename(state = statefip)

# first, bring in the places crosswalk (place-populations.csv)
 places <- read_csv("geographic-crosswalks/data/place-populations.csv")
# keep only the relevant year (for this, 2020)
places <- places %>%
  filter(year > 2019)

# left join to get rid of irrelevant places data
metrics_preschool <- left_join(places, metrics_preschool, by=c("state","place"))
metrics_preschool <- metrics_preschool %>% 
  distinct(year, state, place, share_in_preschool, .keep_all = TRUE)

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





