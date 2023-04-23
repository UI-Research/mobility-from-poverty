###################################################################

# ACS Code: College Readiness metric, subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2017-2021, 5-year
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# Process:
# (1) Housekeeping
# (2) Import the prepared microdata file 
# (3) Create the college readiness metric
# (4) Create the Data Quality variable
# (5) Cleaning and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyr)
library(dplyr)
library(readr)

# EDUCD values from IPUMS:
# 000		N/A or no schooling
# 001		N/A
# 002		No schooling completed
# 010		Nursery school to grade 4
# 011		Nursery school, preschool
# 012		Kindergarten
# 013		Grade 1, 2, 3, or 4
# 014		Grade 1
# 015		Grade 2
# 016		Grade 3
# 017		Grade 4
# 020		Grade 5, 6, 7, or 8
# 021		Grade 5 or 6
# 022		Grade 5
# 023		Grade 6
# 024		Grade 7 or 8
# 025		Grade 7
# 026		Grade 8
# 030		Grade 9
# 040		Grade 10
# 050		Grade 11
# 060		Grade 12
# 061		12th grade, no diploma
# 062		High school graduate or GED
# 063		Regular high school diploma
# 064		GED or alternative credential
# 065		Some college, but less than 1 year
# 070		1 year of college
# 071		1 or more years of college credit, no degree
# 080		2 years of college
# 081		Associate's degree, type not specified
# 082		Associate's degree, occupational program
# 083		Associate's degree, academic program
# 090		3 years of college
# 100		4 years of college
# 101		Bachelor's degree
# 110		5+ years of college
# 111		6 years of college (6+ in 1960-1970)
# 112		7 years of college
# 113		8+ years of college
# 114		Master's degree
# 115		Professional degree beyond a bachelor's degree
# 116		Doctoral degree
# 999		Missing

###################################################################

# (2) Import the prepared microdata file 

# Either run "0_microdata_subgroup.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs5yr_clean <- read_csv("data/temp/2021microdata5yr.csv")

###################################################################

# (3) Create the college readiness metric

# FIRST, remove "NA" records 
# (variable codes explained here: https://usa.ipums.org/usa-action/variables/EDUC#codes_section & see "Detailed codes" at bottom)
# NA = code 001
microdata <- acs5yr_clean %>%
  filter(EDUCD != 001)
# 10,583,133 obs to 10,273,129 obs (310,004 missing obs dropped)

# Create dataset of the microdata for only ages 19 and 20 
# first, isolate the dataset to 19-20 year olds
microdata_coll_age <- microdata %>% 
  filter(AGE == 19 | AGE == 20) 
# 288,449 obs

# Find the # of 19-20 year olds that fall between HS graduate (62) and Professional degree (116) (re: education)
# collapse PERWT by PLACE & RACIAL SUBGROUP (total count of college ready people)
# and combine these into df to prepare for metric ratio
metrics_college <- microdata_coll_age %>% 
  dplyr::group_by(statefip, place, subgroup) %>% 
  dplyr::summarize(
    num_19_and_20 = sum(PERWT),
    num_coll_ready = sum((EDUCD <= 116 & EDUCD >= 62) * PERWT),
    count = n()
  )
# EDUCD <= 116 & EDUCD >= 62 evaluates to FALSE if the person isn't college ready and they aren't counted
# 1937 obs, which is less than 1944, which means we will have a to merge with place_subgroup.csv to account for missing subgroup obs

# Compute the ratio (share employed)
metrics_college <- metrics_college %>%
  mutate(share_hs_degree = num_coll_ready/num_19_and_20)


# Take care of adding in missing values for specific subgroups
# if you don't already have it loaded from "0_microdata_subgroup.R", then load:
# place_subgroup <- read_csv("data/temp/place_subgroup.csv")
metrics_college <- left_join(place_subgroup, metrics_college, by=c("statefip","place", "subgroup"))

###################################################################

# (4) Create the Data Quality variable

# For Employment metric: total number of people 19 and 20 years old
metrics_college <- metrics_college %>% 
  mutate(size_flag = case_when((count < 30) ~ 1,
                               (count >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# place_puma <- read_csv("data/temp/place_puma.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
metrics_college <- left_join(metrics_college, place_puma, by=c("statefip","place"))

# Generate the quality var & subgroup_type var
# make missing values Data Quality 3 as well
metrics_college <- metrics_college %>% 
  mutate(share_hs_degree_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                             size_flag==0 & puma_flag==2 ~ 2,
                                             size_flag==0 & puma_flag==3 ~ 3,
                                             size_flag==1 ~ 3,
                                             is.na(share_hs_degree) ~ 3),
         subgroup_type = "race-ethnicity")

###################################################################

# (5) Cleaning and export

# rename vars as needed
metrics_college <- metrics_college %>%
  dplyr::rename(state = statefip)

# add a variable for the year of the data
metrics_college <- metrics_college %>%
  mutate(
    year = 2021
  )

# order & sort the variables how we want
metrics_college <- metrics_college %>%
  select(year, state, place, subgroup_type, subgroup, share_hs_degree, 
         share_hs_degree_quality)


###################################################################

# Import the original overall population values to add as "All" under "subgroup"
college_all <- read_csv("08_education/metrics_college_city_2021.csv")

college_all <- college_all %>%
  mutate(
    subgroup = "All",
    subgroup_type = "all"
  )

# Append the "All" version of the data
metrics_college <- bind_rows(metrics_college, college_all)

# Sort by place again to double check we have 5 observations per place (All, Black, White, Hispanic, Other)
metrics_college <- metrics_college %>%
  arrange(state, place)


# Save as "metrics_employment.csv"
write_csv(metrics_college, "08_education/metrics_college_subgroup_city_2021.csv")  



