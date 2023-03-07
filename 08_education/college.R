###################################################################

# ACS Code: College Readiness metric, non-subgroup
# Tina Chelidze 2022-2023
# Using IPUMS extract for ACS 2021
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

# Either run "0_microdata.R" OR: Import the already prepared microdata file 
# this one should already match the PUMAs to places
# acs2021clean <- read_csv("data/temp/2021microdata.csv")

###################################################################

# (3) Create the college readiness metric

# Create a dataset of the microdata for only ages 19 and 20 
# first, isolate the dataset to 19-20 year olds
microdata_coll_age <- acs2021clean %>% 
  filter(AGE == 19 | AGE == 20) 

# collapse PERWT by place, create a variable for # of places (or n) in the collapse
num_in_coll_age <- microdata_coll_age %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_19_and_20 = sum(PERWT),
            n = n()
  )

# Create a dataset of the number of 19-20 year olds that fall between HS graduate (62) and Professional degree (116) (re: educational)
microdata_coll <- microdata_coll_age %>% 
  filter(EDUCD <= 116 & EDUCD >= 62) 

# collapse PERWT by place (total count of college ready people)
num_coll_ready <- microdata_coll %>% 
  dplyr::group_by(statefip, place) %>% 
  dplyr::summarize(num_coll_ready = sum(PERWT))


# Merge the two datasets (num_in_coll_age and num_coll_ready) to prepare for ratio
metrics_college <- left_join(num_in_coll_age, num_coll_ready, by=c("statefip", "place"))

# Compute the ratio (share employed)
metrics_college <- metrics_college %>%
  mutate(share_hs_degree = num_coll_ready/num_19_and_20)

# Create Confidence Interval (CI) and correctly format the variables
metrics_college <- metrics_college %>%
  mutate(no_hs_degree = 1 - share_hs_degree,
         interval = 1.96 * sqrt((no_hs_degree*share_hs_degree)/n),
         share_hs_degree_ub = share_hs_degree + interval,
         share_hs_degree_lb = share_hs_degree - interval)

# adjust ub & lb values that fall beyond 0 and 1
metrics_college$share_hs_degree_ub[metrics_college$share_hs_degree_ub > 1] <- 1
metrics_college$share_hs_degree_lb[metrics_college$share_hs_degree_lb < 0] <- 0

###################################################################

# (4) Create the Data Quality variable

# For Employment metric: total number of people 19 and 20 years old
metrics_college <- metrics_college %>% 
  mutate(size_flag = case_when((num_19_and_20 < 30) ~ 1,
                               (num_19_and_20 >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
# puma_place <- read_csv("data/temp/puma_place.csv")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
 metrics_college <- left_join(metrics_college, puma_place, by=c("statefip","place"))

# Generate the quality var
 metrics_college <- metrics_college %>% 
  mutate(share_hs_degree_quality = case_when(size_flag==0 & puma_flag==1 ~ 1,
                                             size_flag==0 & puma_flag==2 ~ 2,
                                             size_flag==0 & puma_flag==3 ~ 3,
                                             size_flag==1 ~ 3))

###################################################################

# (5) Cleaning and export

 # Limit to the Census Places we want 
 
 # rename to prep for merge to places file
 metrics_college <- metrics_college %>%
   dplyr::rename(state = statefip)
 
 # first, bring in the places crosswalk (place-populations.csv)
 places <- read_csv("geographic-crosswalks/data/place-populations.csv")
 # keep only the relevant year (for this, 2020)
 places <- places %>%
   filter(year > 2019)
 
 # left join to get rid of irrelevant places data
 metrics_college <- left_join(places, metrics_college, by=c("state","place"))
 metrics_college <- metrics_college %>% 
   distinct(year, state, place, share_hs_degree, .keep_all = TRUE)

 # add a variable for the year of the data
 metrics_college <- metrics_college %>%
   mutate(
     year = 2021
   )
 
 # order & sort the variables how we want
 metrics_college <- metrics_college %>%
   select(year, state, place, share_hs_degree, 
          share_hs_degree_ub, share_hs_degree_lb,
          share_hs_degree_quality)
 
 # Save as "metrics_employment.csv"
 write_csv(metrics_college, "08_education/metrics_college_city_2021.csv")  



