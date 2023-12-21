
##############################################################################
# Project: Mobility From Poverty
# Analysis: City Level Housing Wealth Distribution by Race/Ethnicity
# Data: ACS 2014-2021
# Created by: Jung Hyun Choi
# Date Created : 1/18/2023
# Data Coding Steps: 
# Step 1. Load Packages
# Step 2. Read and Merge Data (ACS & PUMA PLACE Cross Work) 
# Step 3. Clean Data (Household & Homeowner Data)  
# Step 4. Create Output Data: Household Share by Race/Ethnicity)
# Step 5. Create Output Data: Housing Wealth Share by Race/Ethnicity)
# Step 6. Create Final Output Data: Merge Household & Housing Wealth Share
# Step 7. Export Final Data in CSV Format
#############################################################################

# Step 1. Load Packages
library(tidyverse)
library(pastecs)

# Step 2. Read and Merge Data
## 2.1. ACS: keep households living not living in gq
acs2014_21 <- read_csv("01_financial-well-being/home-values/usa_00584.csv.gz") %>% 
  filter(PERNUM==1) %>% 
  filter(GQ!=3 & GQ!=4) %>% 
  # two digit state code
  mutate(statefip = str_pad(STATEFIP, width = 2, pad = "0", side = "left"))

## 2.2. Crosswalk
puma_place <- read_csv("01_financial-well-being/home-values/puma_to_place_geocorr2012.csv") %>% 
  # two digit state code
  mutate(state = str_pad(state, width = 2, pad = "0", side = "left")) %>% 
  mutate(place = str_pad(place, width = 5, pad = "0", side = "left"))

## 2.3. Join Data
acs_hh <- acs2014_21 %>% 
  left_join(puma_place, by = c("statefip" = "state", "PUMA" = "puma12"))  

# Detailed methods of caculating afact_sum can be found in Kevin's code: I used below stata codes saved the data to excel file 
## gen afact_product= afact (pumatoplace allocation) * afact2 (placetopuma allocation)
## bysort countyfip: egen afact_sum=total(afact_product)
## place is selected from 2020 Census data based on the population of the city (over 50,000)

# Step 3. Data Cleaning
## 3.1. Household Data
acs_hh <- acs_hh %>% 
  # adjust the household weights to account for the allocation from PUMAs to places (afact: puma to place allocation)
  mutate(weight = HHWT*afact) %>% 
  # home ownership
  mutate(owner = ifelse(OWNERSHP == 1, 1, 0)) %>% 
  # race_ethnicity
  mutate(race_ethnicity = case_when(RACE == 1 & HISPAN == 0 ~ "white_nh",
                                    RACE == 2 & HISPAN == 0 ~ "black_nh",
                                    (RACE >= 3) & HISPAN == 0 ~ "other_nh",
                                    HISPAN!=0 & HISPAN!=9 ~ "hispanic"),
         race_ethnicity = factor(race_ethnicity,
                                 levels = c("white_nh",
                                            "black_nh",
                                            "hispanic",
                                            "other_nh")))
##3.2. Create Homeowner Data
acs_ho <- acs_hh %>% 
  filter(OWNERSHP == 1) 

# Step 4. Create Output Data: Household Share by Race.Ethnicity
## 4.1. Calculate Total Households by Race and Ethnicity
place_hh <- acs_hh %>%
  group_by(YEAR, statefip, place) %>% 
  summarize(
    total_hh = sum(weight),
    black_nh_hh = sum(weight * (race_ethnicity == "black_nh")), 
    hispanic_hh = sum(weight * (race_ethnicity == "hispanic")),
    other_nh_hh = sum(weight * (race_ethnicity == "other_nh")),
    white_nh_hh = sum(weight * (race_ethnicity == "white_nh"))
  ) %>%
  ungroup()

## 4.3. Calculate Household Ratio by Race and Ethnicity
place_hh_raceeth <- place_hh %>% 
  mutate(black_nh_hhshare = black_nh_hh/total_hh,
         hispanic_hhshare = hispanic_hh/total_hh,
         other_nh_hhshare = other_nh_hh/total_hh,
         white_nh_hhshare = white_nh_hh/total_hh) %>% 
  select(YEAR, statefip, place, 
         black_nh_hhshare, hispanic_hhshare, 
         other_nh_hhshare, white_nh_hhshare)

## 4.3 Check Outliers
options(scipen=100)
options(digits=2)

stat.desc(place_hh_raceeth)

# Step 5. Create Output Data: Housing Wealth Share by Race/Ethnicity (Homeowners Only)
## 5.1. Calculate Total House Value by Race and Ethnicity 
place_hv <- acs_ho %>% 
  group_by(YEAR, statefip, place) %>% 
  summarize(
    total_hv = sum(VALUEH * weight),
    black_nh_hv = sum(VALUEH * weight * (race_ethnicity == "black_nh")), 
    black_nh_ho = sum(owner * (race_ethnicity == "black_nh")),
    hispanic_hv = sum(VALUEH * weight * (race_ethnicity == "hispanic")), 
    hispanic_ho = sum(owner * (race_ethnicity == "hispanic")),
    other_nh_hv = sum(VALUEH * weight * (race_ethnicity == "other_nh")), 
    other_nh_ho = sum(owner * (race_ethnicity == "other_nh")),
    white_nh_hv = sum(VALUEH * weight * (race_ethnicity == "white_nh")), 
    white_nh_ho = sum(owner * (race_ethnicity == "white_nh"))
  ) %>%
  ungroup() 

## 5.3 Quality Check Flag
place_quality <- acs_hh %>% 
  group_by(statefip, place) %>% 
  filter(row_number() == 1) %>% 
  select(statefip, place, afact_sum) %>%
  ungroup()

place_hv <- place_hv %>% 
  left_join(place_quality, by = c("statefip" = "statefip", "place" = "place")) 

place_hv <- place_hv %>% 
  # if there are less than 30 homeowners than housing wealth data quality is poor,
  # if is n>=30 but sum of afact*afact2 (afact_sum) for each place is below 0.35 than data quality is poor,
  # if is n>=30 and sum of afact*afact2 (afact_sum) for each place is between 0.35 & 0.75 than data quality is marginal,
  # if is n>=30 but sum of afact*afact2 (afact_sum) for each place is a0.75 or above than data quality is good.
  mutate(ratio_black_nh_house_value_households_quality=case_when(black_nh_ho < 30 ~ 3,
                                           black_nh_ho >=30 & afact_sum<0.35 ~ 3,
                                           black_nh_ho >=30 & afact_sum>=0.35 & afact_sum<0.75 ~ 2,
                                           black_nh_ho >=30 & afact_sum>=0.75 ~ 1)) %>%
  mutate(ratio_hispanic_house_value_households_quality=case_when(hispanic_ho < 30 ~ 3,
                                           hispanic_ho >=30 & afact_sum<0.35 ~ 3,
                                           hispanic_ho >=30 & afact_sum>=0.35 & afact_sum<0.75 ~ 2,
                                           hispanic_ho >=30 & afact_sum>=0.75 ~ 1)) %>% 
  mutate(ratio_other_nh_house_value_households_quality=case_when(other_nh_ho < 30 ~ 3,
                                           other_nh_ho >=30 & afact_sum<0.35 ~ 3,
                                           other_nh_ho >=30 & afact_sum>=0.35 & afact_sum<0.75 ~ 2,
                                           other_nh_ho >=30 & afact_sum>=0.75 ~ 1)) %>% 
  mutate(ratio_white_nh_house_value_households_quality=case_when(white_nh_ho < 30 ~ 3,
                                           white_nh_ho >=30 & afact_sum<0.35 ~ 3,
                                           white_nh_ho >=30 & afact_sum>=0.35 & afact_sum<0.75 ~ 2,
                                           white_nh_ho >=30 & afact_sum>=0.75 ~ 1))


## 5.4. Calculate Housing Wealth Ratio by Race and Ethnicity
place_hv_raceeth <- place_hv %>% 
  mutate(black_nh_hvshare = black_nh_hv/total_hv,
         hispanic_hvshare = hispanic_hv/total_hv,
         other_nh_hvshare = other_nh_hv/total_hv,
         white_nh_hvshare = white_nh_hv/total_hv) %>% 
  select(YEAR, statefip, place, 
         black_nh_hvshare, ratio_black_nh_house_value_households_quality,
         hispanic_hvshare, ratio_hispanic_house_value_households_quality,
         other_nh_hvshare, ratio_other_nh_house_value_households_quality,
         white_nh_hvshare, ratio_white_nh_house_value_households_quality)

## 5.5 Check Outliers
stat.desc(place_hv_raceeth)

# Step 6. Create Final Output Data: Merge Household & Housing Wealth Share
## 6.1. City Level Household & Housing Wealth Data
construct_ratio <- function(hvshare, hhshare) {
  
  paste0(format(round(100*hvshare, 1), nsmall = 1),"%", 
         ":",format(round(100*hhshare, 1), nsmall = 1),"%") %>%
    str_remove_all(pattern = " ")
  
}

place_hh_hw_raceeth <- place_hh_raceeth %>%
  filter(place != "NA") %>% 
  left_join(place_hv_raceeth, by = c("YEAR", "statefip", "place")) %>% 
  mutate(
    ratio_black_nh_house_value_households = construct_ratio(hvshare = black_nh_hvshare, hhshare = black_nh_hhshare),
    ratio_hispanic_house_value_households = construct_ratio(hvshare = hispanic_hvshare, hhshare = hispanic_hhshare),
    ratio_other_nh_house_value_households = construct_ratio(hvshare = other_nh_hvshare, hhshare = other_nh_hhshare),
    ratio_white_nh_house_value_households = construct_ratio(hvshare = white_nh_hvshare, hhshare = white_nh_hhshare)
  ) %>% 
  rename(year = YEAR,
         state = statefip) %>% 
  # order variables according to request
  select(year, state, place, 
         ratio_black_nh_house_value_households, ratio_black_nh_house_value_households_quality,
         ratio_hispanic_house_value_households, ratio_hispanic_house_value_households_quality,
         ratio_other_nh_house_value_households, ratio_other_nh_house_value_households_quality,
         ratio_white_nh_house_value_households, ratio_white_nh_house_value_households_quality)  

# Step 7. Export Final Data in CSV Format
write_csv(place_hh_hw_raceeth, file = "01_financial-well-being/home-values/place_hh_hw_raceeth_2014_2021.csv")
