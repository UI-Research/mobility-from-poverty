###################################################################

# ACS Code: Affordable and available housing metric, subgroup
# Geography: place
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by the Seattle Office of Planning & Community Dev
# for the displacement risk indicators

# Definitions of AFFORDABILITY and AVAILABILITY from page 20: 
# https://www.huduser.gov/portal/sites/default/files/pdf/Worst-Case-Housing-Needs-2021.pdf

# • Affordability measures the extent to which enough rental housing units of different costs
# can provide each renter household with a unit it can afford (based on the 30-percent-of-income standard). 
# Affordability, which is the broadest measure of the relative supply of the housing stock, addresses whether sufficient housing
# units would exist if allocated solely on the basis of cost. The affordable stock includes both
# vacant and occupied units.

# • Availability measures the extent to which affordable rental housing units are available
# to renters within a particular income range. Availability is a more restrictive concept because
# units that meet the definition must be available and affordable. Some renters choose to spend
# less than 30 percent of their incomes on rent, occupying housing that is affordable to renters of
# lower incomes. Those units thus are not available to lower-income renters. A unit is available at a
# given level of income if (1) it is affordable at that level, and (2) it is occupied by a renter either at
# that income level or at a lower level or is vacant. 


# Process:
# (1) Housekeeping
# (2) Import housing affordability measures calculated in 1a_housing_place.R
# (3) At rent and down rent -  A unit is available at a given level of income if (1) it is affordable at that
#     level, and (2) it is occupied by a renter either at that income level or at a lower level or is vacant. 
#     (3a) Calculate the "at rent" number of units occupied at the appropriate income level or a lower level
#         Do this for all units, and for renter and owner subgroups 
#     (3b) Summarize at_rent for each subgroup and number of units/households at each
#       income threshold by place
# (4) calculate the number of affordable and available units at each income level per 100 households
# (5) Create the Data Quality variable
# (6) Clean and export
#     (6a) subgroup file
#     (6b) overall file
# (7) Quality Check

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(tidylog)
library(ipumsr)
library(readxl)
library(skimr)

###################################################################

# (2) Import housing affordability data (created in 1a_housing_place.R)

# Either run "1a_housing_place.R" OR: Import the already prepared housing affordability and vacancy files 

# this file is at the household level still so we can 
# calculate the availability metric
households_2022 <- read_csv("data/temp/households_2022.csv")

# this file is at the place level for calculating the overall number
# of affordable and available units per 100 households in step 4
vacant_summed_2022 <- read_csv("data/temp/vacant_summed_2022.csv")

###################################################################

# (3) Availability -  A unit is available at a given level of income if (1) it is affordable at that
#     level, and (2) it is occupied by a renter either at that income level or at a lower level or is vacant. 
#     
#    -  supply is number of housing units in each income bracket. 
#         This is calculated in step 5 of the 1a_housing_place.R file (variables: Affordable80AMI_all, Affordable80AMI_renter, Affordable80AMI_owner)
#    -  demand is number of households in each income bracket 
#         This is calculated in step 5 of the 1a_housing_place.R file (variables: below80AMI, below50AMI, below30AMI)

#    (3a) Calculate the "at rent" number of units occupied at the appropriate income level or a lower level
#         Do this for all units, and for renter and owner subgroups 
#         e.g., unit is affordable at 30 AMI and household is below 30 AMI and the unit is occupied (include vacancy in step 4)


available_2022 <- households_2022 %>% 
  mutate(
    # AT RENT 30% AMI
    at_rent30_all = if_else(Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent30_renter = if_else(OWNERSHP == 2 & Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0),
    at_rent30_owner = if_else(OWNERSHP == 1 & Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    # AT RENT 50% AMI
    at_rent50_all = if_else(Affordable50AMI_all == 1 & Below50AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent50_renter = if_else(OWNERSHP == 2 & Affordable50AMI_all == 1 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    at_rent50_owner = if_else(OWNERSHP == 1 & Affordable50AMI_all == 1 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    # AT RENT 80% AMI
    at_rent80_all = if_else(Affordable80AMI_all == 1 & Below80AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent80_renter = if_else(OWNERSHP == 2 & Affordable80AMI_all == 1 & Below80AMI == 1  & VACANCY == 0, 1, 0),
    at_rent80_owner = if_else(OWNERSHP == 1 & Affordable80AMI_all == 1 & Below80AMI == 1  & VACANCY == 0, 1, 0), 
    
    # Note: we don't end up using downrent in the final measure, just to check results
    # DOWN RENT 30% AMI 
    down_rent30_all = if_else(Affordable30AMI_all == 1 & Below30AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent30_renter = if_else(OWNERSHP == 2 & Affordable30AMI_all == 0 & Below30AMI == 1 & VACANCY == 0, 1, 0),
    down_rent30_owner = if_else(OWNERSHP == 1 & Affordable30AMI_all == 0 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    # DOWN RENT 50% AMI
    down_rent50_all = if_else(Affordable50AMI_all == 1 & Below50AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent50_renter = if_else(OWNERSHP == 2 & Affordable50AMI_all == 0 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    down_rent50_owner = if_else(OWNERSHP == 1 & Affordable50AMI_all == 0 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    # DOWN RENT 80% AMI
    down_rent80_all = if_else(Affordable80AMI_all == 1 & Below80AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent80_renter = if_else(OWNERSHP == 2 & Affordable80AMI_all == 0 & Below80AMI == 1  & VACANCY == 0, 1, 0),
    down_rent80_owner = if_else(OWNERSHP == 1 & Affordable80AMI_all == 0 & Below80AMI == 1  & VACANCY == 0, 1, 0)) 


# (3b) Summarize at_rent for each subgroup and number of units/households at each
#       income threshold by place
available_2022 <- available_2022 %>% 
  group_by(statefip, place) %>% 
  dplyr::summarise(across(matches("Below|Affordable|down_|at_"), ~sum(.x*HHWT, na.rm = TRUE)), 
                   HHobs_count = n()) %>% 
  rename("state" = "statefip") %>% 
  ungroup()

# test that the down rent and at rent values sum to the affordable value at each income bracket
available_2022 %>% 
  mutate(combine_rent = rowSums(select(.,"at_rent30_all", "down_rent30_all"), na.rm = TRUE), 
         rent_dif = Affordable30AMI_all - combine_rent) %>% 
  summary(rent_dif)

###################################################################
# (4) calculate the number of affordable and available units at each income level per 100 households
# this is the number of units that are rented to people at or below each income threshold
# plus the number of vacant units at that income threshold over the total number
# of households in each income bracket
available_2022_final <- available_2022 %>% 
  # join in vacancy data
  left_join(vacant_summed_2022, by = c("state", "place")) %>% 
  mutate(
    # number of affordable and available at 30 AMI per 100 households
    share_affordable_available_30ami_all = (at_rent30_all+Affordable30AMI_all_vacant)/Below30AMI*100, 
    share_affordable_available_30ami_renter = (at_rent30_renter+Affordable30AMI_renter_vacant)/Below30AMI*100, 
    share_affordable_available_30ami_owner = (at_rent30_owner+Affordable30AMI_owner_vacant)/Below30AMI*100, 
    
    # number of affordable and available at 50 AMI per 100 households
    share_affordable_available_50ami_all = (at_rent50_all+Affordable50AMI_all_vacant)/Below50AMI*100, 
    share_affordable_available_50ami_renter = (at_rent50_renter+Affordable50AMI_renter_vacant)/Below50AMI*100, 
    share_affordable_available_50ami_owner = (at_rent50_owner+Affordable50AMI_owner_vacant)/Below50AMI*100, 
    
    # number affordable and available at 80 AMI per 100 households
    share_affordable_available_80ami_all = (at_rent80_all+Affordable80AMI_all_vacant)/Below80AMI*100, 
    share_affordable_available_80ami_renter = (at_rent80_renter+Affordable80AMI_renter_vacant)/Below80AMI*100, 
    share_affordable_available_80ami_owner = (at_rent80_owner+Affordable80AMI_owner_vacant)/Below80AMI*100
  )

###################################################################

# (5) Create the Data Quality variable

# For Housing metric: total number of HH below 50% AMI (need to add HH + vacant units)
# Create a "Size Flag" for any place-level observations made off of less than 30 observed HH, vacant or otherwise
available_2022_final <- available_2022_final %>% 
  mutate(affordableHH_sum = HHobs_count + vacantHHobs_count,
         size_flag = case_when((affordableHH_sum < 30) ~ 1,
                               (affordableHH_sum >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
place_puma <- read_csv("data/temp/place_puma.csv") %>% 
  rename("state" = "statefip")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
available_2022_final <- left_join(available_2022_final, place_puma, by=c("state","place"))

# Generate the quality var (naming it housing_quality to match Kevin's notation from 2018)
available_2022_final <- available_2022_final %>% 
  mutate(housing_quality = case_when(size_flag==0 & puma_flag==1 ~ 1, # 239 obs
                                     size_flag==0 & puma_flag==2 ~ 2, # 239 obs
                                     size_flag==0 & puma_flag==3 ~ 3, # 7 obs
                                     size_flag==1 ~ 3))

###################################################################

# (6) Clean and export

# (6a) subgroup file
# turn long for subgroup output
available_2022_subgroup <- available_2022_final %>%
  select(state, place, starts_with("share_affordable_"), housing_quality) %>% 
  # create year variable
  mutate(year = 2022) %>% 
  # seperate share_afforadable by AMI and the subgroup
  pivot_longer(cols = c(contains("share_affordable")), 
               names_to = c("available", "subgroup"),
               names_pattern = "(.+?(?=_[^_]+$))(_[^_]+$)", # this creates two columns - "share_affordable_XXAMI" and "_owner/_renter/_all"
               values_to = "value") %>% 
  # pivot_wider again so that each share_affordable by AMI is it's own column with subgroups as rows
  pivot_wider(
    names_from = available, 
    values_from = value
  ) %>% 
  # clean subgroup names and add subgroup type column 
  # remove leading underscore and capitalize words
  mutate(subgroup = str_remove(subgroup, "_") %>% str_to_title(),
         subgroup_type = "renter-owner" )

# export our file as a .csv
write_csv(available_2022_subgroup, "02_housing/data/available_2022_subgroups_city.csv")  


# (6b) overall file
# keep what we need
available_2022_overall <- available_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  select(year, state, place, share_affordable_available_80ami, share_affordable_available_50ami, share_affordable_available_30ami, housing_quality) %>% 
  arrange(year, state, place)

# export our file as a .csv
write_csv(available_2022_overall, "02_housing/data/available_2022_subgroups_city.csv")  


###################################################################

# (7) Quality check tests 

#   (7a) see if state trends match 
#   National Low Income Housing Coalition Report - https://nlihc.org/gap

# this is a really rough comparison since there isn't really local level data for this measure
# so I'm using the 2021 report state level numbers to snif test our results
# the NLIHC report has state level numbers for the number of units that are
# affordable and available for 30AMI households and the range is 17 to 58
# our range is 21 to 59 

state_av <- available_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  group_by(state) %>% 
  summarise(across(starts_with("share_affordable"), 
                   ~ mean(.x, na.rm = TRUE))) 


range(state_av$share_affordable_available_30ami)


# For Housing metric: total number of HH below 50% AMI (need to add HH + vacant units)
# Create a "Size Flag" for any place-level observations made off of less than 30 observed HH, vacant or otherwise
housing_2022 <- housing_2022 %>% 
  mutate(affordableHH_sum = HHobs_count + vacantHHobs_count,
         size_flag = case_when((affordableHH_sum < 30) ~ 1,
                               (affordableHH_sum >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
place_puma <- read_csv("data/temp/place_puma.csv")

place_puma <- place_puma %>% 
  rename("state" = "statefip")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
housing_2022 <- left_join(housing_2022, place_puma, by=c("state","place"))

#  (7b) Histograms

# share affordable and available at 30 AMI histogram
available_2022_subgroup %>% 
  ggplot(aes(share_affordable_available_30ami))+
  geom_histogram()+
  facet_wrap(~subgroup)

# share affordable and available at 50 AMI histogram
available_2022_subgroup %>% 
  ggplot(aes(share_affordable_available_30ami))+
  geom_histogram()+
  facet_wrap(~subgroup)

# share affordable and available at 80 AMI histogram
available_2022_subgroup %>% 
  ggplot(aes(share_affordable_available_30ami))+
  geom_histogram()+
  facet_wrap(~subgroup)


