
########################################################################
# Project: Mobility From Poverty
# Analysis: County Level Housing Wealth Distribution by Race/Ethnicity
# Data: ACS 2010-2021
# Created by: Jung Hyun Choi
# Created Date: 1/18/2023
########################################################################

# Step 1. Library
library(tidyverse)
library(haven)

# Step 2. Read Data
## 2.1. ACS: keep households living not living in gq
acs2014_21 <- read_csv("usa_00584.csv") %>% 
  filter(PERNUM==1) %>% 
  filter(GQ!=3 & GQ!=4) %>% 
  # two digit state code
  mutate(statefip = case_when(nchar(STATEFIP, type = "chars") == 2 ~ as.character(STATEFIP),
                           nchar(STATEFIP, type = "chars") == 1 ~ paste0("0", STATEFIP))) %>% 
  # three digit county code
  mutate(countyfip = case_when(nchar(COUNTYFIP, type = "chars") == 3 ~ as.character(COUNTYFIP),
                            nchar(COUNTYFIP, type = "chars") == 2 ~ paste0("0", COUNTYFIP),
                            nchar(COUNTYFIP, type = "chars") == 1 ~ paste0("00", COUNTYFIP))) 

## 2.2. Crosswalk
puma_county <- read_csv("puma_to_county_geocorr2014.csv") %>% 
  mutate(state = case_when(nchar(state, type = "chars") == 2 ~ as.character(state),
                           nchar(state, type = "chars") == 1 ~ paste0("0", state))) 

## 2.3. Join Data
acs_hh <- acs2014_21 %>% 
          left_join(puma_county, by = c("statefip" = "state", "PUMA" = "puma12"))

# Step 3. Data Cleaning
## 3.1. Household Data
acs_hh <- acs_hh %>% 
  #county
  mutate(county = ifelse(countyfip != "000", countyfip, county)) %>% 
  #weight
  mutate(weight = ifelse(countyfip != "000", HHWT, HHWT*afact)) %>% 
  #ownershp %>% 
  mutate(owner = ifelse(OWNERSHP == 1, 1, 0)) %>% 
  #race_ethnicity
  mutate(race_ethnicity = case_when(RACE == 1 & HISPAN == 0 ~ "white_nh",
                                    RACE == 2 & HISPAN == 0 ~ "black_nh",
                                    (RACE >= 3) & HISPAN == 0 ~ "other_nh",
                                    HISPAN!=0 & HISPAN!=9 ~ "hispanic"),
         race_ethnicity = factor(race_ethnicity,
                                 levels = c("white_nh",
                                            "black_nh",
                                            "hispanic",
                                            "other_nh")))
##3.2. Homeowner Data
acs_ho <- acs_hh %>% 
  filter(OWNERSHP == 1) 

# Step 4. Output Data Creation: Households
## 4.1. Calculate Total Households by Race and Ethnicity

total_hh <- acs_hh %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(total_hh = sum(weight)) 

black_nh_hh <- acs_hh %>% 
  filter(race_ethnicity == "black_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
    summarize(black_nh_hh = sum(weight))

hispanic_hh <- acs_hh %>% 
  filter(race_ethnicity == "hispanic") %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(hispanic_hh = sum(weight)) 

other_nh_hh <- acs_hh %>% 
  filter(race_ethnicity == "other_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
    summarize(other_nh_hh = sum(weight))

white_nh_hh <- acs_hh %>% 
  filter(race_ethnicity == "white_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
    summarize(white_nh_hh = sum(weight))

## 4.2. Join Household Data Sets
county_hh <- total_hh %>% 
                left_join(black_nh_hh, by = c("YEAR", "statefip", "county")) %>% 
                left_join(hispanic_hh, by = c("YEAR", "statefip", "county")) %>% 
                left_join(other_nh_hh, by = c("YEAR", "statefip", "county")) %>% 
                left_join(white_nh_hh, by = c("YEAR", "statefip", "county"))

## 4.3. Calculate Household Ratio by Race and Ethnicity
county_hh_raceeth <- county_hh %>% 
                     mutate(black_nh_hhshare = black_nh_hh/total_hh,
                            hispanic_hhshare = hispanic_hh/total_hh,
                            other_nh_hhshare = other_nh_hh/total_hh,
                            white_nh_hhshare = white_nh_hh/total_hh) %>% 
                     select(YEAR, statefip, county, 
                            black_nh_hhshare, hispanic_hhshare, 
                            other_nh_hhshare, white_nh_hhshare)
                   
# Step 5. Output Data Creation: Housing Wealth (Homeowners Only)
## 5.1. Calculate Total House Value by Race and Ethnicity 
total_hv<- acs_ho %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(total_hv = sum(VALUEH*weight)) 

black_nh_hv<- acs_ho %>% 
  filter(race_ethnicity == "black_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(black_nh_hv = sum(VALUEH*weight), 
            black_nh_ho = sum(owner)) %>% 
  # if there are less than 50 homeowners than housing wealth data quality is poor
  mutate(black_nh_wealth_quality=ifelse(black_nh_ho < 50, 3, 1))  

hispanic_hv<- acs_ho %>% 
  filter(race_ethnicity == "hispanic") %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(hispanic_hv = sum(VALUEH*weight), 
            hispanic_ho = sum(owner)) %>% 
  mutate(hispanic_wealth_quality=ifelse(hispanic_ho<50, 3, 1))  

other_nh_hv<- acs_ho %>% 
  filter(race_ethnicity == "other_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(other_nh_hv = sum(VALUEH*weight), 
            other_nh_ho = sum(owner)) %>% 
  mutate(other_nh_wealth_quality=ifelse(other_nh_ho<50, 3, 1))  

white_nh_hv<- acs_ho %>% 
  filter(race_ethnicity == "white_nh") %>% 
  group_by(YEAR, statefip, county) %>% 
  summarize(white_nh_hv = sum(VALUEH*weight), 
            white_nh_ho = sum(owner)) %>% 
  mutate(white_nh_wealth_quality=ifelse(white_nh_ho<50, 3, 1))  

## 5.2. Join Housing Wealth Data Sets
county_hv <- total_hv %>% 
  left_join(black_nh_hv, by = c("YEAR", "statefip", "county")) %>% 
  left_join(hispanic_hv, by = c("YEAR", "statefip", "county")) %>% 
  left_join(other_nh_hv, by = c("YEAR", "statefip", "county")) %>% 
  left_join(white_nh_hv, by = c("YEAR", "statefip", "county")) 

## 5.3. Calculate Housing Wealth Ratio by Race and Ethnicity
county_hv_raceeth <- county_hv %>% 
  mutate(black_nh_hvshare = black_nh_hv/total_hv,
         hispanic_hvshare = hispanic_hv/total_hv,
         other_nh_hvshare = other_nh_hv/total_hv,
         white_nh_hvshare = white_nh_hv/total_hv) %>% 
  select(YEAR, statefip, county, 
         black_nh_hvshare, black_nh_wealth_quality,
         hispanic_hvshare, hispanic_wealth_quality,
         other_nh_hvshare, other_nh_wealth_quality,
         white_nh_hvshare, white_nh_wealth_quality)

# Step 6. Output Data Final
## 6.1. County Level Household & Housing Wealth Data
county_hh_hw_raceeth <- county_hh_raceeth %>%
                        left_join(county_hv_raceeth, by = c("YEAR", "statefip", "county")) %>% 
                        mutate(r_black_nh_hv_hh = paste(round(100*black_nh_hvshare, 1),"%", 
                                                        ":", round(100*black_nh_hhshare, 1),"%"),
                               r_hispanic_hv_hh = paste(round(100*hispanic_hvshare, 1),"%", 
                                                        ":", round(100*hispanic_hhshare, 1),"%"),
                               r_other_nh_hv_hh = paste(round(100*other_nh_hvshare, 1),"%", 
                                                        ":", round(100*other_nh_hhshare, 1),"%"),
                               r_white_nh_hv_hh = paste(round(100*white_nh_hvshare, 1),"%", 
                                                        ":", round(100*white_nh_hhshare, 1),"%")) %>% 
                        rename(year = YEAR,
                               state = statefip) %>% 
                        # order variables according to request
                        select(year, state, county, 
                               black_nh_hhshare, black_nh_hvshare, r_black_nh_hv_hh, black_nh_wealth_quality,
                               hispanic_hhshare, hispanic_hvshare, r_hispanic_hv_hh, hispanic_wealth_quality,
                               other_nh_hhshare, other_nh_hvshare, r_other_nh_hv_hh, other_nh_wealth_quality,
                               white_nh_hhshare, white_nh_hvshare, r_white_nh_hv_hh, white_nh_wealth_quality)

# Step 7. Export Data to CSV
write.csv(county_hh_hw_raceeth, "county_hh_hw_raceeth.csv", row.names = FALSE)
  

      
         
