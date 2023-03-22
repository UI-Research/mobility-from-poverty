#/*************************/
#  air quality program: 
#  created by: Rebecca Marx
#  updated on: March 21, 2023
#Original data:
  #https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide
  #https://www.epa.gov/national-air-toxics-assessment/2014-nata-assessment-results
#Description: 

#create indicatorand prepare tracts
#(1) create tract level indicators of environmental hazards for 2014 and 2018 and merge with crosswalks
#(2) create tract-level indicators of poverty and race in US
#create county files 
#(3) population weight tract-level environmental indicators using poverty and race-idenity subgroups for 2014 and 2018
#(4) create county level environmental index by race-identity and poverty-level
#create place files
#(5) using tract level indicators and sub-group weights created previously, create place-level indicators 
    #weighted by population and area of tract in a place
#(6) create place-level environmental index by race-identity and poverty-level
#*/
#  /*************************/

#install packages
# install.packages("devtools")
# devtools::install_github("UrbanInstitute/urbnmapr")
library(tidyverse)
library(tidycensus)
library(tm)
library(purrr)
library(urbnmapr)
library(skimr)
library(rvest)
library(httr)
library (dplyr)
library(readxl)

####(1) create tract level indicators of environmental hazards for 2014 and 2018 and merge with crosswalks####

##Import 2018 AirToxScreen Data and 2014 AFFH data##
#https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide

cancer_data18 <- read_excel("06_neighborhoods/environment/data/raw/2018_National_CancerRisk_by_tract_srcgrp.xlsx")
neuro_data18 <- read_excel("06_neighborhoods/environment/data/raw/2018_National_NeurHI_by_tract_srcgrp.xlsx")
resp_data18 <- read_excel("06_neighborhoods/environment/data/raw/2018_National_RespHI_by_tract_srcgrp.xlsx")

##Only keep needed variabales##

cancer_data18 <- cancer_data18 %>% 
  select(Tract, `Total Cancer Risk (per million)`) 

neuro_data18 <- neuro_data18 %>% 
  select(Tract, `Total Neurological (hazard quotient)`) 

resp_data18 <- resp_data18 %>% 
  select(Tract, `Total Respiratory (hazard quotient)`)   

##Join Variables and rename## [try left_join %>%]

enviro18_int <- left_join(resp_data18, cancer_data18, by = "Tract") %>%
  left_join(neuro_data18, by = "Tract")

enviro18_test <- enviro18_int %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
         state = str_sub(tract, start = 1, end = 2),
         county = str_sub(tract, start = 3, end = 5),
         tract = str_sub(tract, start = 6, end = 11))

colnames (enviro18_int) <- c("tract", "resp", "carc","neuro")

##Drop rows that are not tracts - rows where the last 6 digist are "0" are not tracts## 

#create a new varibale for filtering (Pull out last 6 digits)
enviro18_int$tract1 <- str_sub(enviro18_int$tract, start = 6, end = 11)

#filter to keep only tracts(tract1 != "000000") and drop tract1
enviro18 <- filter(enviro18_int, tract1 != "000000") %>%
  select(tract, resp, carc, neuro) 

##Calculate means and st. devs and store values##

resp_mean18 <- mean(enviro18$resp, na.rm = TRUE)
carc_mean18 <- mean(enviro18$carc, na.rm = TRUE)
neuro_mean18 <- mean (enviro18$neuro, na.rm = TRUE)

resp_stdv18 <- sd(enviro18$resp, na.rm = TRUE)
carc_stdv18 <- sd(enviro18$carc, na.rm = TRUE)
neuro_stdv18 <- sd(enviro18$neuro, na.rm = TRUE)

##Calculate EnvHealth Indicator##

#calculate EnvHealth components
enviro18$resp2 <- (enviro18$resp - resp_mean18)/resp_stdv18
enviro18$carc2 <- (enviro18$carc - carc_mean18)/carc_stdv18
enviro18$neuro2 <- (enviro18$neuro - neuro_mean18)/neuro_stdv18

#multiply the sums by -1
enviro18$envhealth18 <- (enviro18$carc2 + enviro18$resp2 + enviro18$neuro2)*-1

#percentile rank caculated values
enviro18$envhrank18 <- percent_rank(enviro18$envhealth18)

#set haz_idx between 0 and 100
enviro18$haz_idx <- round(enviro18$envhrank18*100,0)

#keep only the needed variables
haz_idx18 <- enviro18 %>% 
  select(tract, haz_idx)

#Save File? [CHECK]


###Repeat for 2014###

###Import 2014 National Air Toxics Assessment (NATA) Data###
#https://www.epa.gov/national-air-toxics-assessment/2014-nata-assessment-results
#hazard index by sourcegroup

cancer_data14 <- read_excel("06_neighborhoods/environment/data/raw/nata2014v2_national_cancerrisk_by_tract_srcgrp.xlsx")
neuro_data14 <- read_excel("06_neighborhoods/environment/data/raw/nata2014v2_national_neurhi_by_tract_srcgrp.xlsx")
resp_data14 <- read_excel("06_neighborhoods/environment/data/raw/nata2014v2_national_resphi_by_tract_srcgrp.xlsx")

#only keep needed variabales##

cancer_data14 <- cancer_data14 %>% 
  select(Tract, `Total Cancer Risk (per million)`) 

neuro_data14 <- neuro_data14 %>% 
  select(Tract, `Total Neurological (hazard quotient)`) 

resp_data14 <- resp_data14 %>% 
  select(Tract, `Total Respiratory (hazard quotient)`) 

##Join variables and rename##

enviro14_int <- left_join(resp_data14, cancer_data14, by = "Tract") %>%
  left_join(neuro_data14, by = "Tract")

colnames (enviro14_int) <- c("tract", "resp", "carc","neuro")

#create a new varibale for filtering (Pull out last 6 digits)
enviro14_int$tract1 <- str_sub(enviro14_int$tract, start = 6, end = 11)

#filter to keep only tracts(tract1 != "000000") and drop tract1
enviro14 <- filter(enviro14_int, tract1 != "000000")%>%
  select(tract, resp, carc, neuro) 

##calculate means and st. devs and store values##

resp_mean14 <- mean(enviro14$resp)
carc_mean14 <- mean(enviro14$carc)
neuro_mean14 <- mean(enviro14$neuro)

resp_stdv14 <- sd(enviro14$resp)
carc_stdv14 <- sd(enviro14$carc)
neuro_stdv14 <- sd(enviro14$neuro)

##calculate EnvHealth14 components##
enviro14$resp2 <- (enviro14$resp - resp_mean14)/resp_stdv14
enviro14$carc2 <- (enviro14$carc - carc_mean14)/carc_stdv14
enviro14$neuro2 <- (enviro14$neuro - neuro_mean14)/neuro_stdv14

##Calculate EnvHealth 2014 Indicator##
enviro14$envhealth14 <- (enviro14$carc2 + enviro14$resp2 + enviro14$neuro2)*-1

#percentile rank
enviro14$envhrank14 <- percent_rank(enviro14$envhealth14)

#set haz_idx between 0 and 100 
enviro14$haz_idx <- round(enviro14$envhrank14*100,0)

#keep what we need
haz_idx14 <- enviro14 %>% 
  select(tract, haz_idx)


###COMPARE TO 2014 AFFH###

##Import AFFH data and select haz_idx
#affh20 <- read.csv("06_neighborhoods/environment/data/raw/AFFH_tract_AFFHT0006_July2020.csv")

#affh20 <- affh20 %>% 
  #select(geoid, haz_idx) 
  #colnames (affh20) <- c("tract", "haz_idx_affh")

#Step 11: Join indexes by tract to compare values 
#haz_idx <- merge(haz_idx14, haz_idx18, by = "tract")
#haz_idx <- merge(haz_idx, affh20, by = "tract")
#haz_idx <- haz_idx[,c(1,4,2,3)]
#haz_idx$diff_14_affh <- haz_idx$haz_idx14 - haz_idx$haz_idx_affh
#haz_idx$chng_14_18 <- haz_idx$haz_idx18 - haz_idx$haz_idx14
#avg_diff_14_affh <- mean(haz_idx$diff_14_affh)
#avg_change_14_18 <- mean(haz_idx$chng_14_18)

##Look at which tracts are not in the affh file##
#missing_affh 
#non_affh <- setdiff(enviro14$tract,affh20$tract)
#non_affh = as.data.frame(non_affh)
#write.csv(haz_idx, "06_neighborhoods/environment/data/output/EnvHazIdx2.csv", row.names = F)


##Join the indicators file to the county crossswalk file## 

#import tract-county-crosswalk_2018.csv
crosswalk_cnty <- read.csv("geographic-crosswalks/data/tract-county-crosswalk_2018.csv")
#use county-populations ?

#prep crosswalk file by adding leading zeroes to state and county 
crosswalk_cnty$state <- str_pad(crosswalk_cnty$state, 2, side = "left", pad = "0")

crosswalk_cnty$county <- str_pad(crosswalk_cnty$county, 3, side = "left", pad = "0")

crosswalk_cnty$tract <- str_pad(crosswalk_cnty$tract, 6, side = "left", pad = "0")

#concatenate crosswalk and remove spaces to prepare for join with AirTox  
crosswalk_cnty$tract2 <- paste(crosswalk_cnty$state,crosswalk_cnty$county,crosswalk_cnty$tract)
crosswalk_cnty$tract2 <- gsub(" ", "", crosswalk_cnty$tract2)
crosswalk_cnty <- crosswalk_cnty %>%
  select(year,tract2)
  colnames(crosswalk_cnty) <- c("year", "tract")

##merge 2018 hazard and crosswalk file##
hazidx18_merge <- tidylog::left_join(x = crosswalk_cnty, y = haz_idx18, 
                        by= "tract")

#check which did not join (551 obs)
#hazidx18_nomerge <- anti_join(crosswalk_cnty, haz_idx18, by = "tract")

#split tract into state and county 
enviro_haz18 <- hazidx18_merge %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
          state = str_sub(tract, start = 1, end = 2),
           county = str_sub(tract, start = 3, end = 5),
           tract = str_sub(tract, start = 6, end = 11))

##PULL RACE VARIABLES FROM ACS for 2018##
# pull total population and white, non-Hispanic population, total for poverty calculation, and total in poverty
# by tract from the ACS

state_fips <- unique(urbnmapr::states$state_fips)
pull_acs <- function(state_fips) {
  tidycensus::get_acs(geography = "tract", 
                      variables = c("total_pop" = "B02001_001",
                                    "wnh" = "B03002_003", 
                                    "total_pov" = "B17001_001", 
                                    "poverty" = "B17001_002"),
                      year = 2018,
                      state = state_fips,
                      geometry = FALSE,
                      output = "wide"
  )
}
acs18 <- map_df(state_fips, pull_acs)

###CREATE INDICATORS FOR RACE AND POVERTY for 2018###

#use acs data to create a variable for percent poc, by 2018 tract
race_pov18 <- acs18 %>%
  transmute(GEOID = GEOID,
            name = NAME,
            total_pop = total_popE,
            wnh = wnhE,
            poc = total_pop - wnh, 
            percent_poc = poc/total_pop, 
            total_pov = total_povE, 
            poverty = povertyE, 
            percent_pov = poverty / total_pov
  )  

# create indicator variable for race based on perctage of poc/nh-White in each tract. These percentage cut offs were determined by Marge Turner.
# also create indicator for tracts in 'High Poverty', with 40% or higher poverty rate meaning the tract has a high level of poverty
race_pov18 <- race_pov18 %>%
  mutate(
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"Mixed Race and Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )

#two county names and fips codes were changed [CHECK FROM Peace code -- how do we know what changed?]
#edit the GEOIDs to match the current fips codes. 
#race_pov18 <- race_pov18 %>% 
#mutate(GEOID = case_when(
#GEOID ==  "46113940500" ~ "46102940500",
#GEOID ==  "46113940800" ~ "46102940800",
#GEOID ==  "46113940900" ~ "46102940900", 
#GEOID ==  "02270000100" ~ "02158000100",
#TRUE ~ GEOID
#))

#puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
#enviro_haz18 <- enviro_haz18 %>%
#filter(state!= "72")

#join to race indicator file
race_enviro18 <- left_join(race_pov18, enviro_haz18, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx), total_pop, 0))

#census tracts with zero population (2018 - 645); (2014 - 618)
filter(race_enviro18, total_pop == 0)

#census tracts with zero population that are missing hazard index (2018- 508); (2014 - 508)
filter(race_enviro18, total_pop==0, is.na(haz_idx))

#census tracts with population greater than 0 that are missing hazard index (2018- 33); (2014 - 46)
filter(race_enviro18, total_pop>0, is.na(haz_idx))

#census tracts with population greater than 100 that are missing hazard index (2018 - 29); (2014 - 30)
filter(race_enviro18, total_pop>100, is.na(haz_idx))

#census tracts with zero population counted in poverty total metric (2018- 147); (2014 - 147)
filter(race_enviro18, total_pov == 0, total_pop != 0)

#census tracts with zero population counted in poverty total metric 
#also have hazard index missing (2018 - 7); (2014 - 10)
filter(race_enviro18, total_pov == 0, total_pop != 0, is.na(haz_idx))

#### (4) CREATE COUNTY LEVEL ESTIMATES for 2018 ####

###CALCULATE FOR 2018###
##calculate 2018 avg county level hazard index 
all_environment18 <- race_enviro18 %>%
  group_by(state, county) %>%
  summarise(environmental = weighted.mean(haz_idx, total_pop, na.rm = TRUE), 
            na_pop = sum(na_pop),
            county_pop = sum (total_pop)) %>%
  ungroup()

#calculate percent population of each county that has missing tract hazard information
all_environment18 <- all_environment18 %>%
  mutate(na_perc = na_pop / county_pop,
         subgroup = "All",
         subgroup_type = "all") %>%
  select(-c(na_pop, county_pop))

##calculate county/poverty type index
pov_environment18 <- race_enviro18 %>% 
  mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty,
                                   poverty_type == "Not High Poverty" ~ (total_pov - poverty)),
         na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
  group_by(year, state, county, poverty_type) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE),
            na_pop = sum(na_pop, na.rm = TRUE),
            subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup()%>%
  mutate(geoid = str_c(state,county),
         na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop))%>%
  filter(!is.na(poverty_type))                                                                       

#check max percent of population of county that has missing information 
#all_environment18 %>%
#pull(na)perc) %>%
#max()

#expand dataset for every county/poverty_type 
expand_pov18 <- pov_environment18 %>%
  expand(geoid, poverty_type)

#make dataset of unique state/county pairs to join to 
state_county18 <- race_enviro18 %>%
  transmute(geoid = str_c(state, county), state, county) %>%
  distinct()

#join dataset on expanded dataset, join with geo varibale, and add subgroup type variables
pov_environment_exp18 <- left_join(expand_pov18, 
                                   pov_environment18 %>%
                                     select(geoid, poverty_type, environmental, na_perc),
                                   by=c("geoid",
                                        "poverty_type")) %>%
  left_join(state_county18, by = "geoid") %>%
  rename(subgroup = poverty_type) %>%
  mutate(subgroup_type = "poverty")

###Average county level hazard by race/ethnicity###
#weight the index by total population for tracts that have mixed race and ethnicity
#weight by number of people of color for tracts that are majority non-white
#calculate missingness 

haz_by_race18 <- race_enviro18 %>%
  mutate(weighting_ind = case_when(
    race_ind == "Mixed Race and Ethnicity" ~ total_pop,
    race_ind == "Majority Non-White" ~ poc,
    race_ind == "Majority White, Non-Hispanic" ~ wnh
  ),
  na_pop = if_else(is.na(haz_idx) | is.na(race_ind), weighting_ind, 0)) %>%
  group_by(state, county, race_ind) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE),
            na_pop = sum(na_pop, na.rm = TRUE),
            subgroup_pop = sum(weighting_ind, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, county),
         na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop)) %>%
  filter(!is.na(race_ind))                                           

#expand dataset for every county/race/ethnicity 
expand_race18 <- haz_by_race18 %>%
  expand(geoid,race_ind)

#join to expanded, add geo variables, and add subgroup variables 
haz_by_race_exp18 <- left_join(expand_race18, 
                               haz_by_race18 %>%
                                 select(geoid, race_ind, environmental, na_perc),
                               by=c("geoid", "race_ind")) %>%
  left_join(state_county18, by = "geoid") %>%
  rename(subgroup = race_ind) %>%
  mutate(subgroup_type = "race-ethnicity")

###APPEND DATA### #Final data should be 18,852 (3,142 counties*6 sub-groups)
final_data_cnty18 <- all_environment18 %>% #21,994 observations -- trying to drop the subgroup NAs   #[CHECK - 
  bind_rows(pov_environment_exp18) %>%
  bind_rows(haz_by_race_exp18)

###Match File to Data Standards###

final_data_cnty18 <- final_data_cnty18 %>%
  select(-geoid) %>%
  mutate(year = 2018) %>%
  select(year, state, county, environmental, everything())%>%
  #create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(environmental_quality = if_else(na_perc >= .05,2,1)) %>%
  #select(-na_perc) %>%
  arrange(year,
          state,
          county,
          subgroup_type,
          subgroup) %>%
  select(year, state, county, subgroup_type, subgroup, environmental, environmental_quality) %>%
  
  #save file 
  #write_csv(final_data_cnty18, "06_neighborhoods/environment/data/output/environment_county18.csv")

quality_2_3 <- final_data_cnty18 %>%
  filter (environmental_quality != 1) #10 observations are 2



#### 2014 COUNTY ####

##MERGE 2014 FILE WITH CROSSWALK##
hazidx14_merge <- tidylog::left_join(x = crosswalk_cnty, y = haz_idx14, 
                                     by= "tract")

#check which did not join 
#hazidx14_nomerge <- anti_join(crosswalk, haz_idx14, by = "tract")

#split tract into state and county 
enviro_haz14 <- hazidx14_merge %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
         state = str_sub(tract, start = 1, end = 2),
         county = str_sub(tract, start = 3, end = 5),
         tract = str_sub(tract, start = 6, end = 11))

#change year to 2014 from 2018 (the year from the crosswalk file)
enviro_haz14$year <- 2014

####(2) create tract-level indicators of poverty and race for counties in US by population weighting tracts####

###POPULATION WEIGHT TRACTS - 2014###

# pull total population and white, non-Hispanic population, total for poverty calculation, and total in poverty
# by tract from the ACS
state_fips <- unique(urbnmapr::states$state_fips)
pull_acs <- function(state_fips) {
  tidycensus::get_acs(geography = "tract", 
                      variables = c("total_pop" = "B02001_001",
                                    "wnh" = "B03002_003", 
                                    "total_pov" = "B17001_001", 
                                    "poverty" = "B17001_002"),
                      year = 2014,
                      state = state_fips,
                      geometry = FALSE,
                      output = "wide"
  )
}
acs14 <- map_df(state_fips, pull_acs)

####CREATE INDICATORS FOR RACE AND POVERTY for 2014#### 

# use acs data to create a variable for percent poc, by tract
race_pov14 <- acs14 %>%
  transmute(GEOID = GEOID,
            name = NAME,
            total_pop = total_popE,
            wnh = wnhE,
            poc = total_pop - wnh, 
            percent_poc = poc/total_pop, 
            total_pov = total_povE, 
            poverty = povertyE, 
            percent_pov = poverty / total_pov
  )  

# create indicator variable for race based on perctage of poc/nh-White in each tract. These percentage cut offs were determined by Marge Turner.
# also create indicator for tracts in 'High Poverty', with 40% or higher poverty rate meaning the tract has a high level of poverty
race_pov14 <- race_pov14 %>%
  mutate(
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"Mixed Race and Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )

#four county names and fips codes were changed                #CHECK - Total tract 18846, should be 18,850 
# edit the GEOIDs to match the current fips codes.            #These lines are from Peace CodeDid not change these in this version.
#race_pov14 <- race_pov14 %>%                                 #Did not change these in this version
  #mutate(GEOID = case_when(                                  #If I do, total tracts increases to 18,852
    #GEOID ==  "46113940500" ~ "46102940500",
    #GEOID ==  "46113940800" ~ "46102940800",
    #GEOID ==  "46113940900" ~ "46102940900", 
    #GEOID ==  "02270000100" ~ "02158000100",
    #TRUE ~ GEOID
  #))

##Merge with enviro_haz14 data 

#puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
#enviro_haz14 <- enviro_haz14 %>%
#filter(state!= "72")

#join to race indicator file
race_enviro14 <- left_join(race_pov14, enviro_haz14, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx), total_pop, 0))

##Check missingness##

#number of tracts with pop > 0 & missing poverty rates: #[CHECK - WHY?]

#census tracts with zero population (2018 - 645); (2014 - 618)
filter(race_enviro14, total_pop == 0)
#census tracts with zero population that are missing hazard index (2018- 508); (2014 - 508)
filter(race_enviro14, total_pop==0, is.na(haz_idx))
#census tracts with population greater than 0 that are missing hazard index (2018- 33); (2014 - 46)
filter(race_enviro14, total_pop>0, is.na(haz_idx))
#census tracts with population greater than 100 that are missing hazard index (2018 - 29); (2014 - 30)
filter(race_enviro14, total_pop>100, is.na(haz_idx))
#census tracts with zero population counted in poverty total metric (2018- 147); (2014 - 147)
filter(race_enviro14, total_pov == 0, total_pop != 0)
#census tracts with zero population counted in poverty total metric 
#also have hazard index missing (2018 - 7); (2014 - 10)
filter(race_enviro14, total_pov == 0, total_pop != 0, is.na(haz_idx))

##calculate 2014 avg county level hazard index 
all_environment14 <- race_enviro14 %>%
  group_by(state, county) %>%
  summarise(environmental = weighted.mean(haz_idx, total_pop, na.rm = TRUE), 
            na_pop = sum(na_pop),
            county_pop = sum (total_pop)) %>%
  ungroup()

#calculate percent population of each county that has missing tract hazard information
all_environment14 <- all_environment14 %>%
  mutate(na_perc = na_pop / county_pop,
         subgroup = "All",
         subgroup_type = "all") %>%
  select(-c(na_pop, county_pop))

##calculate county/poverty type index
pov_environment14 <- race_enviro14 %>% 
  mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty,
                                   poverty_type == "Not High Poverty" ~ (total_pov - poverty)),
         na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
  group_by(year, state, county, poverty_type) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE),
            na_pop = sum(na_pop, na.rm = TRUE),
            subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup()%>%
  mutate(geoid = str_c(state,county),
         na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop))%>%
filter(!is.na(poverty_type))                                                                       

#check max percent of population of county that has missing information 
#all_environment18 %>%
#pull(na)perc) %>%
#max()

#expand dataset for every county/poverty_type 
expand_pov14 <- pov_environment14 %>%
  expand(geoid, poverty_type)

#make dataset of unique state/county pairs to join to 
state_county14 <- race_enviro14 %>%
  transmute(geoid = str_c(state, county), state, county) %>%
  distinct()

#join dataset on expanded dataset, join with geo varibale, and add subgroup type variables
pov_environment_exp14 <- left_join(expand_pov14, 
                                   pov_environment14 %>%
                                     select(geoid, poverty_type, environmental, na_perc),
                                   by=c("geoid",
                                        "poverty_type")) %>%
  left_join(state_county14, by = "geoid") %>%
  rename(subgroup = poverty_type) %>%
  mutate(subgroup_type = "poverty")

###Average county level hazard by race/ethnicity###
#weight the index by total population for tracts that have mixed race and ethnicity
#weight by number of people of color for tracts that are majority non-white
#calculate missingness 

haz_by_race14 <- race_enviro14 %>%
  mutate(weighting_ind = case_when(
    race_ind == "Mixed Race and Ethnicity" ~ total_pop,
    race_ind == "Majority Non-White" ~ poc,
    race_ind == "Majority White, Non-Hispanic" ~ wnh
  ),
  na_pop = if_else(is.na(haz_idx) | is.na(race_ind), weighting_ind, 0)) %>%
  group_by(state, county, race_ind) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE),
            na_pop = sum(na_pop, na.rm = TRUE),
            subgroup_pop = sum(weighting_ind, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, county),
         na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop)) %>%
  filter(!is.na(race_ind))                                        

#expand dataset for every county/race/ethnicity 
expand_race14 <- haz_by_race14 %>%
  expand(geoid,race_ind)

#join to expanded, add geo variables, and add subgroup variables 
haz_by_race_exp14 <- left_join(expand_race14, 
                               haz_by_race14 %>%
                                 select(geoid, race_ind, environmental, na_perc),
                               by=c("geoid", "race_ind")) %>%
  left_join(state_county14, by = "geoid") %>%
  rename(subgroup = race_ind) %>%
  mutate(subgroup_type = "race-ethnicity")

###APPEND DATA### #Final data should be 18,852 (3,142 counties*6 sub-groups)
final_data_cnty14 <- all_environment14 %>% 
  bind_rows(pov_environment_exp14) %>%
  bind_rows(haz_by_race_exp14)

###Match File to Data Standards###

final_data_cnty14 <- final_data_cnty14 %>%
  select(-geoid) %>%
  mutate(year = 2014) %>%
  select(year, state, county, environmental, everything())%>%
  #create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(environmental_quality = if_else(na_perc >= .05,2,1)) %>%
  #select(-na_perc) %>%
  arrange(year,
          state,
          county,
          subgroup_type,
          subgroup) %>%
  select(year, state, county, subgroup_type, subgroup, environmental, environmental_quality) 

#save file 
write_csv(final_data_cnty14, "06_neighborhoods/environment/data/output/environment_county.csv")

#create complete file 
final_data_cnty <- final_data_cnty18 %>% 
  rbind(final_data_cnty14)

#check 
quality_2_3 <- final_data_cnty %>%
  filter (environmental_quality != 1)


  #####PLACE FILES #####

# Description: Code to create city-level Environmental Qulaity indicators

#For 2014 and 2018:
#(1) import city-level crosswalk
#(2) merge with tract-level data, including population data previoudly pulled in to create the county file
#(3) create subgroups 
#(4) Filter to unique places 

#pull in city crosswalk dowloaded from geocorr (geocorr2022_tract_to_place.csv)          [CHECK] #Problem that it's 2020 tracts and not 2018?
crosswalk_city <- read.csv("geographic-crosswalks/data/geocorr2022_tract_to_place.csv")
#afact2 is place to tract
#afact is tract to place (how much of a tract is falling in that place)

#clean crosswalk to prepare for merge
  #county should be 3 digits - make all 5 digits by adding leading zero then shorten to the last 3 digits 
  crosswalk_city$county <- str_pad(crosswalk_city$county, 5, side = "left", pad = "0")
  crosswalk_city$county <- str_sub(crosswalk_city$county, start = 3, end = 5)

  #add leading zero to state
  crosswalk_city$state <- str_pad(crosswalk_city$state, 2, side = "left", pad = "0")

  #remove period (".") from tract, add end zero then and add a leading zero
  crosswalk_city$tract2 <- str_replace(crosswalk_city$tract, "[.]","") 
  crosswalk_city$tract2 <- str_pad(crosswalk_city$tract2, 5, side = "right", pad = "0") 
  crosswalk_city$tract2 <- str_pad(crosswalk_city$tract2, 6, side = "left", pad = "0")
  crosswalk_city$place <- str_pad(crosswalk_city$place, 5, side = "left", pad = "0")
  
  #concatenate state, county, tract to match the haz_idx file and keep needed columns
  crosswalk_city$tract3 <- paste(crosswalk_city$state,crosswalk_city$county,crosswalk_city$tract2)
  crosswalk_city$tract3 <- gsub(" ", "", crosswalk_city$tract3)
  crosswalk_city <- crosswalk_city %>%
    select(place,tract3,afact)
  colnames(crosswalk_city) <- c("place", "GEOID", "afact")

  #### 2018 PLACE ####
  
  #2018 merge tract hazard indicators including poverty and race to places - left join since places (city crosswalk) has more observations
  tract_place_haz18 <- tidylog::left_join(x = crosswalk_city, y = race_enviro18, #73,056 tracts with hazard and population data
                                       by= "GEOID")

  test1 <- tidylog::inner_join(x = crosswalk_city, y = race_enviro18, #pull in data with population
                              by= "GEOID")
  
  #write_csv(crosswalk_city,"06_neighborhoods/environment/data/output/crosswalk_city_v2.csv")
  #write_csv(race_enviro18,"06_neighborhoods/environment/data/output/race_pov_enviro18.csv" )
  
  no_join2 <- anti_join(by = "geoid", x = state_places_pop18, y = crosswalk_city) 
  #0 observations -- so places get lost elsewhere (all the places are in the crosswalk)
  #test which tracts/place didn't join 
 
   nj <- anti_join(by = "GEOID", x = crosswalk_city, y = race_enviro18)
  #91,614 observations of 141,771 do not join

  #check which don't join 
  test_tract_place_haz18 <- tract_place_haz18 %>%
    mutate(geoid = str_c(state, place), state, place)
  no_join_tract_place <- anti_join(by = "geoid", x = state_places_pop18, y = test_tract_place_haz18) #118 places lost
  
  #drop those that did not match (from 141,771 to 50,157)
  #test_tract_place_haz18 <-  tract_place_haz18 %>%
    #drop_na(total_pop) #[CHECK -- mark as na instead of drop? ]
  
  #Create "All" observations 
  #calculate place population for tracts and haz_idx weighting by amount of tract in place and tract total population
  all_enviro_place18  <- tract_place_haz18 %>%
    mutate(tract_pop = (total_pop*afact)) %>% #to account for the fact that only part of the tract population is in the place
    group_by(state, place) %>%
    summarise(environmental = weighted.mean(haz_idx, tract_pop, na.rm = TRUE),
          na_pop = sum(na_pop),
          place_pop = sum (tract_pop)) %>% 
          ungroup()
  
  #calculate percent population of each county that has missing tract hazard information
  all_enviro_place18 <- all_enviro_place18 %>%
    mutate(na_perc = na_pop / place_pop,
        subgroup = "All",
        subgroup_type = "all") %>%
  select(-c(na_pop, place_pop))
    
  #create geoid for filtering later
  all_enviro_place18 <- all_enviro_place18 %>%
    mutate(geoid = str_c(state, place), state, place)
  
  #check join with places 
  no_join_all1 <- anti_join(by = "geoid", x = state_places_pop18, y = all_enviro_place18) #118 don't join observations 
  
  #check max percent of population of county that has missing information [CHECK Peace Code - Why?]
  #enviro_place18%>%
  #pull(na)perc%>%
  #max()

###create place level index by race###
  pov_enviro_place18 <- tract_place_haz18 %>%
    mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty,
                                     poverty_type == "Not High Poverty" ~ (total_pov - poverty)),
           na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
    group_by(state, place, poverty_type) %>%
    summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), #Multiplied weight by % in Tract
              na_pop = sum(na_pop, na.rm = TRUE),
              subgroup_pop = sum(weighting_ind, na.rm=TRUE)
    ) %>%
    ungroup()%>%
    mutate(geoid = str_c(state,place),
           na_perc = na_pop / subgroup_pop) %>%
    select(-c(na_pop, subgroup_pop))%>%
    filter(!is.na(poverty_type)) 
  
  #make dataset of unique state/county pairs (from 8912 to 1,536 distinct state/place)
  
  #limit to population cutoff places
  #places_pop <- read_csv("geographic-crosswalks/data/place-populations.csv")
  #match data types 
  #places_pop$state <- as.integer(places_pop$state)
  #places_pop$place <- as.integer(places_pop$place)
  
  #keep only 2018 data to prepare for merge (should leave us with 486 obs total)
  #keep <- c(2018)
  #places_pop <- filter(places_pop, year %in% keep)
  #add leading zero to place 
  #places_pop$state <- str_pad(places_pop$state, 2, side = "left", pad = "0")
  #places_pop$place <- str_pad(places_pop$place, 5, side = "left", pad = "0")

  #test_state_place18 <- places_pop %>%
    #transmute(geoid = str_c(state, place), state, place) %>%
    #distinct()%>%
    #filter(!is.na(geoid))
  
  state_place18 <- tract_place_haz18 %>%
    transmute(geoid = str_c(state, place), state, place) %>%
    distinct()%>%
    filter(!is.na(geoid)) 
  
  #expand poverty/place dataset for every place/poverty_type (from 1,596 to 3,072) -- [CHECK - aren't we only supposed to have 486?]
  expand_pov_place18 <- pov_enviro_place18 %>%
    expand(geoid, poverty_type)
  
  #join dataset on expanded dataset, join with geo varibale, and add subgroup type variables
  pov_env_exp_place18 <- left_join(expand_pov_place18,
                                         pov_enviro_place18 %>%
                                          select(geoid, poverty_type, environmental, na_perc),
                                         by=c("geoid",
                                              "poverty_type")) %>%
    left_join(state_place18, by = "geoid") %>%
    rename(subgroup = poverty_type) %>%
    mutate(subgroup_type = "poverty")

  ###Average place level hazard by race/ethnicity###
  #weight the index by total population for tracts that have mixed race and ethnicity 
  #weight by number of people of color for tracts that are majority non-whire
  #[CHECK] weight by 
  #calculate missingness 
  
  haz_by_race_place18 <- tract_place_haz18 %>%
    mutate(weighting_ind = case_when(race_ind == "Mixed Race and Ethnicity" ~ total_pop,
                                     race_ind == "Majority Non-White" ~ poc,
                                     race_ind == "Majority White, Non-Hispanic" ~wnh),
           na_pop = if_else(is.na(haz_idx) | is.na(race_ind), weighting_ind, 0)) %>%
    group_by(state, place, race_ind) %>%
    summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), ##[CHECK - weight by afact??]##
              na_pop = sum(na_pop, na.rm = TRUE),
              subgroup_pop = sum(weighting_ind*afact, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    mutate(geoid = str_c(state, place),
           na_perc = na_pop / subgroup_pop) %>%  ##WHAT IS THIS DOING 
    select(-c(na_pop, subgroup_pop)) %>%
    filter(!is.na(race_ind))
  
  #expand dataset for every place/race/ethnicity 
  expand_race_place18 <- haz_by_race_place18 %>%
    expand(geoid,race_ind)
  
  #join to expanded, add geo variables, and add subgroup variables 
  haz_by_race_exp_place18 <- left_join(expand_race_place18,
                                       haz_by_race_place18 %>%
                                         select(geoid, race_ind, environmental, na_perc),
                                         by=c("geoid", "race_ind")) %>%
    left_join(state_place18, by = "geoid") %>%
    rename(subgroup = race_ind) %>%
    mutate(subgroup_type = "race-ethnicity")
  
  #match data types 
  #enviro_place18$state <- as.integer(enviro_place18$state)
  
  ###APPEND DATA### 9,216 obs (?)
  bind_data_place18 <- all_enviro_place18 %>%
    bind_rows(pov_env_exp_place18) %>%
    bind_rows(haz_by_race_exp_place18) %>%
  #organize data 
  #select(-geoid) %>%
  #create quality variable where quality is 2 if value is missing by more than 5 percent
    mutate(
      environmental_quality = if_else(na_perc >= .05,2,1),
      year = 2018
           ) %>%
    select(-na_perc) 
  
  #limit to population cutoff places [using state_place18??]
  places_pop18 <- read_csv("geographic-crosswalks/data/place-populations.csv")
  #match data types 
  places_pop18$state <- as.integer(places_pop18$state)
  places_pop18$place <- as.integer(places_pop18$place)
  
  #keep only 2018 data to prepare for merge (should leave us with 486 obs total)
  keep <- c(2018)
  places_pop18 <- filter(places_pop18, year %in% keep)
  #add leading zero to place 
  places_pop18$state <- str_pad(places_pop18$state, 2, side = "left", pad = "0")
  places_pop18$place <- str_pad(places_pop18$place, 5, side = "left", pad = "0")
  
  state_places_pop18 <- places_pop18 %>%
  transmute(geoid = str_c(state, place), state, place) #%>%
  #distinct()%>%
  #filter(!is.na(geoid))
  
  #places <- state_place18 %>%
    #select(-c(state,place))
  
 final_data_place18 <- filter(bind_data_place18,   
                                    geoid %in% state_places_pop18$geoid)
 
 #check missing places - #118 *6 = 708
 no_join <- anti_join(by = "geoid", x = state_places_pop18, y = final_data_place18)
 write_csv(no_join,"06_neighborhoods/environment/data/output/no_join_places.csv")
 
 #check against crosswalk file 
 crosswalk_city$state <- str_sub(crosswalk_city$GEOID, start = 1, end = 2)
 crosswalk_city <-  crosswalk_city %>%
   mutate(geoid = str_c(state, place), state, place)
 
#match to data standards
 final_data_place18 <-  final_data_place18 %>%
   select(-geoid) %>% 
   arrange(year,
            state,
            place,
            subgroup_type,
            subgroup)%>%
    select(year, state, place, subgroup_type, subgroup, environmental, environmental_quality) 
    #should have 2,904 but only have 2,208; 118 places do not join (missing 118*6 observations = 708 + 2,208 = 2,916)
  
 final_place_all18 <- final_data_place18 %>%
    filter(subgroup == "All")
 
 
 #### 2014 PLACE FILE ####
  