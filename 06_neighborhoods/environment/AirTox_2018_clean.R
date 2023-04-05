#/*************************/
#  air quality program: 
#  created by: Rebecca Marx
#  updated on: April 4, 2023
#Original data:
  #https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide
  #https://www.epa.gov/national-air-toxics-assessment/2014-nata-assessment-results
#Description: 

#create environmental hazard indicators
#(1) create tract level indicators of environmental hazards for 2018 
#(2) create tract level indicators of environmental hazards for 2014
#compare to affh data previoulsy used for the environmental indicator

#create county files 
#(3) population weight tract-level environmental indicators using poverty and race-identity subgroups for 2018
#(4) create county level environmental index by race-identity and poverty-level for 2018
#(5) population weight tract-level environmental indicators using poverty and race-identity subgroups for 2014
#(6) create county level environmental index by race-identity and poverty-level for 2014
#(7) bind 2018 and 2014 county files for final files 

#create place files 
#(8) prep city crosswalk data from geocorr
#(9) create place-level environmental indicators using poverty and race-idenity subgroups for 2018 and percent of tract in place
#(10) create place-level environmental indicators using poverty and race-idenity subgroups for 2014 and percent of tract in place
#(11) bind 2018 and 2014 place files for final files

#(12) all filles should be saved to mobility-from-poverty/06_neighborhoods/environment/data/output
#  /*************************/

#install packages
# install.packages("devtools")
# devtools::install_github("UrbanInstitute/urbnmapr")
library(tidyverse)
library(tidycensus)
library(tm)
library(urbnmapr)
library(skimr)
library(rvest)
library(httr)
library(readxl)

###### Create Environmental Indicators ######

##### (1) create tract level indicators of environmental hazards for 2018 #####

##Import 2018 AirToxScreen Data and 2014 AFFH data from mobility-from-poverty/06_neighborhoods/environment/data/raw ##
#https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide - Source Group data 

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

##Join Variables and rename## 
enviro18_int <- left_join(resp_data18, cancer_data18, by = "Tract") %>%
  left_join(neuro_data18, by = "Tract") 

colnames (enviro18_int) <- c("tract", "resp", "carc","neuro")

##Drop rows that are not tracts - rows where the last 6 digist are "0" are not tracts## 

#create a new varibale for filtering (Pull out last 6 digits)
enviro18_int$tract1 <- str_sub(enviro18_int$tract, start = 6, end = 11)

#filter to keep only tracts(tract1 != "000000") and drop tract1
enviro18 <- filter(enviro18_int, tract1 != "000000") %>%
  select(tract, resp, carc, neuro) 

##calculate means and st. devs and store values##

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


##### (2) create tract level indicators of environmental hazards for 2014 #####

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

#check which are in 2014 but not 2018 
test1 <- anti_join(by = "tract", x = haz_idx14, y = haz_idx18)
test2 <- anti_join(by = "tract", x= haz_idx18, y = haz_idx14)


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

###### Create County Files ######

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
  

###### (3) population weight tract-level environmental indicators using poverty and race-idenity subgroups for 2018 #####

##merge 2018 hazard and crosswalk file##
  
#filter out Puerto Rico and Virgin Islands
haz_idx18 <- haz_idx18 %>%
    mutate(state =str_sub(tract, 1, 2)) %>%
  filter(state != 72 & state != 78) %>%
  select(tract, haz_idx)

#update GEOIDs based on
#https://www.diversitydatakids.org/sites/default/files/
  #2020-02/ddk_coi2.0_technical_documentation_20200212.pdf
  haz_idx18 <- haz_idx18 %>%                                 
    mutate(tract = case_when(                                  
      tract ==  "36053940101" ~ "36053030101",
      tract ==  "36053940102" ~ "36053030102",
      tract ==  "36053940103" ~ "36053030103", 
      tract ==  "36053940200" ~ "36053030200",
      tract ==  "36053940300" ~ "36053030300",
      tract ==  "36053940401" ~ "36053030401",
      tract ==  "36053940700" ~ "36053030402",
      tract ==  "36053940403" ~ "36053030403",
      tract ==  "36053940600" ~ "36053030600",
      tract ==  "36065940100" ~ "36065024700",
      tract ==  "36065940000" ~ "36065024800",
      tract ==  "04019002701" ~ "04019002704",
      tract ==  "04019002903" ~ "04019002906",
      tract ==  "04019410501" ~ "04019004118", 
      tract ==  "04019410502" ~ "04019004121",
      tract ==  "04019410503" ~ "04019004125", 
      tract ==  "04019470400" ~ "04019005200", 
      tract ==  "04019470500" ~ "04019005300", 
      tract ==  "06037930401" ~ "06037137000",
      tract ==  "51515050100" ~ "51019050100",
      tract ==  "02270000100" ~ "02158000100",
      tract ==  "46113940500" ~ "46102940500",
      tract ==  "46113940800" ~ "46102940800",
      tract ==  "46113940900" ~ "46102940900", 
      TRUE ~ tract
    ))
  
hazidx18_merge <- tidylog::left_join(x = crosswalk_cnty, y = haz_idx18, 
                        by= "tract")
#532 rows in only x; 1 in only y 

#check which did not join
nomerge_hazidx18_1 <- anti_join(crosswalk_cnty, haz_idx18, by = "tract") 
sum(is.na(hazidx18_merge$haz_idx))
#532 are only in the crosswalk 

nomerge_hazidx18_2 <- anti_join(haz_idx18, crosswalk_cnty, by = "tract")
#one is only in haz_idx18 (36065940200)

           county = str_sub(tract, start = 3, end = 5),
#split tract into state and county 
enviro_haz18 <- hazidx18_merge %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
          state = str_sub(tract, start = 1, end = 2),
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

#create indicator variable for race based on perctage of poc/nh-White in each tract. These percentage cut offs were determined by Marge Turner.
#also create indicator for tracts in 'High Poverty', with 40% or higher poverty rate meaning the tract has a high level of poverty
race_pov18 <- race_pov18 %>%
  mutate(
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"No Majority Race/Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )

#puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
#enviro_haz18 <- enviro_haz18 %>%
#filter(state!= "72")

#join to race indicator file
race_pov_enviro18 <- left_join(race_pov18, enviro_haz18, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx), total_pop, 0))

#census tracts with zero population (2018 - 645)
filter(race_pov_enviro18, total_pop == 0)
#census tracts with zero population that are missing hazard index (2018- 508)
filter(race_pov_enviro18, total_pop==0, is.na(haz_idx))
#census tracts with population greater than 0 that are missing hazard index (2018- 33)
filter(race_pov_enviro18, total_pop>0, is.na(haz_idx))
#census tracts with population greater than 100 that are missing hazard index (2018 - 29)
filter(race_pov_enviro18, total_pop>100, is.na(haz_idx))
#census tracts with zero population counted in poverty total metric (2018- 147)
filter(race_pov_enviro18, total_pov == 0, total_pop != 0)
#census tracts with zero population counted in poverty total metric 
#also have hazard index missing (2018 - 7)
filter(race_pov_enviro18, total_pov == 0, total_pop != 0, is.na(haz_idx))


##### (4) create county level environmental index by race-identity and poverty-level for 2018 #####

##calculate 2018 avg county level hazard index 
all_environment18 <- race_pov_enviro18 %>%
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
#create a weighting indicator so weights can be applied to the appropriate subgroup 
pov_environment18 <- race_pov_enviro18 %>% 
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
  select(-c(na_pop, subgroup_pop)) 
                                                                 
#expand dataset for every county/poverty_type 
expand_pov18 <- pov_environment18 %>%
  expand(geoid, poverty_type)

#make dataset of unique state/county pairs to join to 
state_county18 <- race_pov_enviro18 %>%
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
  mutate(subgroup_type = "poverty") %>%
  filter(!is.na(subgroup))   

###average county level hazard by race/ethnicity###
#create a weighting indicator so weights can be applied to the appropriate subgroup 
#weight the index by total population for tracts that have mixed race and ethnicity
#weight by number of people of color for tracts that are majority non-white
#weight by number of white, non-hispanic people for tracts that are majority white, non-hispanic
#calculate missingness 

haz_by_race18 <- race_pov_enviro18 %>%
  mutate(weighting_ind = case_when(
    race_ind == "No Majority Race/Ethnicity" ~ total_pop,
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
bind_data_cnty18 <- all_environment18 %>% 
  bind_rows(pov_environment_exp18) %>%
  bind_rows(haz_by_race_exp18)

###match file to data standards###
final_data_cnty_sub18 <- bind_data_cnty18 %>%
  mutate(year = 2018) %>%
  #create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(environmental_quality = if_else(na_perc >= .05,2,1)) %>%
  #select(-na_perc) %>%
  arrange(year,
          state,
          county,
          subgroup_type,
          subgroup) %>%
  select(year, state, county, subgroup_type, subgroup, environmental, environmental_quality) 

#round environmental indicator to nearest integer
final_data_cnty_sub18$environmental <- round(final_data_cnty_sub18$environmental, digits = 0)

#save file 
write_csv(final_data_cnty_sub18, "06_neighborhoods/environment/data/output/environment_county_sub18.csv")

quality_2_3 <- final_data_cnty_sub18 %>%
  filter (environmental_quality != 1) #10 observations are 2

#save county-level file (no subgroups)
data_cnty18_final <- final_data_cnty_sub18 %>%
  filter(subgroup == "All")
#3142 obs
write_csv(data_cnty18_final,"06_neighborhoods/environment/data/output/environment_county18.csv")


#### 2014 COUNTY ####

#(5) population weight tract-level environmental indicators using poverty and race-idenity subgroups for 2014

#filter out Puerto Rico and Virgin Island
haz_idx14 <- haz_idx14 %>%
  mutate(state =str_sub(tract, 1, 2)) %>%
  filter(state != 72 & state != 78) %>%
  select(tract, haz_idx)

#update tract numbers 
haz_idx14 <- haz_idx14 %>%                                 
  mutate(tract = case_when(                                  
    tract ==  "36053940101" ~ "36053030101",
    tract ==  "36053940102" ~ "36053030102",
    tract ==  "36053940103" ~ "36053030103", 
    tract ==  "36053940200" ~ "36053030200",
    tract ==  "36053940300" ~ "36053030300",
    tract ==  "36053940401" ~ "36053030401",
    tract ==  "36053940700" ~ "36053030402",
    tract ==  "36053940403" ~ "36053030403",
    tract ==  "36053940600" ~ "36053030600",
    tract ==  "36065940100" ~ "36065024700",
    tract ==  "36065940000" ~ "36065024800",
    tract ==  "04019002701" ~ "04019002704",
    tract ==  "04019002903" ~ "04019002906",
    tract ==  "04019410501" ~ "04019004118", 
    tract ==  "04019410502" ~ "04019004121",
    tract ==  "04019410503" ~ "04019004125", 
    tract ==  "04019470400" ~ "04019005200", 
    tract ==  "04019470500" ~ "04019005300", 
    tract ==  "06037930401" ~ "06037137000",
    tract ==  "51515050100" ~ "51019050100",
    tract ==  "02270000100" ~ "02158000100",
    tract ==  "46113940500" ~ "46102940500",
    tract ==  "46113940800" ~ "46102940800",
    tract ==  "46113940900" ~ "46102940900", 
    TRUE ~ tract
  ))

##merge 2014 file with crosswalk##
hazidx14_merge <- tidylog::left_join(x = crosswalk_cnty, y = haz_idx14, 
                                     by= "tract")
#531 only in x; 1 only in y 

nomerge_hazidx14_1 <- anti_join(crosswalk_cnty, haz_idx14, by = "tract")
#531 only in crosswalk 

nomerge_hazidx14_2 <- anti_join(haz_idx14, crosswalk_cnty, by = "tract")
#one is only in haz_idx file (36065940200)

#split tract into state and county and change year to 2014 
enviro_haz14 <- hazidx14_merge %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
         state = str_sub(tract, start = 1, end = 2),
         county = str_sub(tract, start = 3, end = 5),
         tract = str_sub(tract, start = 6, end = 11),
         year = 2014)

####(2) create tract-level indicators of poverty and race for counties in US by population weighting tracts####

###population weight tracts - 2014###

#pull total population and white, non-Hispanic population, total for poverty calculation, and total in poverty
#by tract from the ACS
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

####create indicators for race and povery for 2014#### 

#use acs data to create a variable for percent poc, by tract
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
      percent_poc > .4 & percent_poc < .6 ~"No Majority Race/Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )

#four county names and fips codes were changed in 2015                
#edit the GEOIDs to match the current fips codes.             
race_pov14 <- race_pov14 %>%                                 
  mutate(GEOID = case_when(                                  
    GEOID ==  "46113940500" ~ "46102940500",
    GEOID ==  "46113940800" ~ "46102940800",
    GEOID ==  "46113940900" ~ "46102940900", 
    GEOID ==  "02270000100" ~ "02158000100",
    TRUE ~ GEOID
  ))

#join race/pov files to environmental indicator file   
race_pov_enviro14 <- left_join(race_pov14, enviro_haz14, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx), total_pop, 0))

##Check missingness##
#number of tracts with pop > 0 & missing poverty rates: 
#census tracts with zero population (2014 - 618)
filter(race_pov_enviro14, total_pop == 0)
#census tracts with zero population that are missing hazard index (2014 - 508)
filter(race_pov_enviro14, total_pop==0, is.na(haz_idx))
#census tracts with population greater than 0 that are missing hazard index (2014 - 46)
filter(race_pov_enviro14, total_pop>0, is.na(haz_idx))
#census tracts with population greater than 100 that are missing hazard index (2014 - 30)
filter(race_pov_enviro14, total_pop>100, is.na(haz_idx))
#census tracts with zero population counted in poverty total metric (2014 - 147)
filter(race_pov_enviro14, total_pov == 0, total_pop != 0)
#census tracts with zero population counted in poverty total metric 
#also have hazard index missing (2014 - 10)
filter(race_pov_enviro14, total_pov == 0, total_pop != 0, is.na(haz_idx))

#(6) create county level environmental index by race-identity and poverty-level for 2014

##calculate 2014 avg county level hazard index 
all_environment14 <- race_pov_enviro14 %>%
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

#check difference between 2014 and 2018
allenv_diff <- anti_join(by = c("state", "county"), x = all_environment18, y = all_environment14)

#calculate county/poverty type index (high poverty vs. not high poverty)
pov_environment14 <- race_pov_enviro14 %>% 
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

#expand dataset for every county/poverty_type 
expand_pov14 <- pov_environment14 %>%
  expand(geoid, poverty_type)

#make dataset of unique state/county pairs to join to 
state_county14 <- race_pov_enviro14 %>%
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

haz_by_race14 <- race_pov_enviro14 %>%
  mutate(weighting_ind = case_when(
    race_ind == "No Majority Race/Ethnicity" ~ total_pop,
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

###append data### #Final data should be 18,852 (3,142 counties*6 sub-groups)
bind_data_cnty14 <- all_environment14 %>% 
  bind_rows(pov_environment_exp14) %>%
  bind_rows(haz_by_race_exp14)

###Match File to Data Standards###

final_data_cnty_sub14 <- bind_data_cnty14 %>%
  mutate(year = 2014) %>%
  #create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(environmental_quality = if_else(na_perc >= .05,2,1)) %>%
  arrange(year,
          state,
          county,
          subgroup_type,
          subgroup) %>%
  select(year, state, county, subgroup_type, subgroup, environmental, environmental_quality)

#(7) bind 2018 and 2014 county files for final files 

#create complete file of 2014 and 2018 
final_data_cnty_sub <- final_data_cnty_sub18  %>% 
  bind_rows(final_data_cnty_sub14)

#round environmental indicator to nearest integer
final_data_cnty_sub$environmental <- round(final_data_cnty_sub$environmental, digits = 0)

#save file 
write_csv(final_data_cnty_sub, "06_neighborhoods/environment/data/output/environment_county_sub_all.csv")

#check 
quality_2_3 <- final_data_cnty_sub %>%
  filter (environmental_quality != 1)

data_cnty_all_final <- final_data_cnty_sub %>%
  filter(subgroup == "All")
#save file
write_csv(data_cnty_all_final, "06_neighborhoods/environment/data/output/environment_county_all.csv")


  #####PLACE FILES #####

#(8) prep city crosswalk data from geocorr

#pull in city crosswalk downloaded from geocorr (geocorr2018_tract_to_place.csv)          
crosswalk_city18 <- read_csv("geographic-crosswalks/data/geocorr2018_tract_to_place.csv")
#afact is tract to place (how much of a tract is falling in that place)

#clean crosswalk to prepare for merge
#county should be 3 digits - make all 5 digits by adding leading zero then shorten to the last 3 digits 
crosswalk_city18$county <- str_pad(crosswalk_city18$county, 5, side = "left", pad = "0")
crosswalk_city18$county <- str_sub(crosswalk_city18$county, start = 3, end = 5)

#add leading zero to state
crosswalk_city18$state <- str_pad(crosswalk_city18$state, 2, side = "left", pad = "0")
  
#perpare tract by multiplying by 100 to remove decimals then add the leading zero 
crosswalk_city18$tract2 <- crosswalk_city18$tract*100
crosswalk_city18$tract2 <- str_pad(crosswalk_city18$tract2, 6, side = "left", pad = "0")
  
#concatenate state, county, tract to match the haz_idx file and keep needed columns
crosswalk_city18$tract3 <- paste(crosswalk_city18$state,crosswalk_city18$county,crosswalk_city18$tract2)
crosswalk_city18$tract3 <- gsub(" ", "", crosswalk_city18$tract3)
crosswalk_city18 <- crosswalk_city18 %>%
  select(placefp,tract3,afact)
colnames(crosswalk_city18) <- c("place", "GEOID", "afact")

#add leading zero to place 
crosswalk_city18$place <- str_pad(crosswalk_city18$place, 5, side = "left", pad = "0")

##Try with 2022 geocorr##
#crosswalk_city22 <- read_csv("geographic-crosswalks/data/geocorr2022_tract_to_place.csv")
#clean crosswalk to prepare for merge
#county should be 3 digits - make all 5 digits by adding leading zero then shorten to the last 3 digits 
#crosswalk_city22$county <- str_pad(crosswalk_city22$county, 5, side = "left", pad = "0")
#crosswalk_city22$county <- str_sub(crosswalk_city22$county, start = 3, end = 5)

#add leading zero to state
#crosswalk_city22$state <- str_pad(crosswalk_city22$state, 2, side = "left", pad = "0")

#perpare tract by multiplying by 100 to remove decimals then add the leading zero 
#crosswalk_city22$tract2 <- crosswalk_city22$tract*100
#crosswalk_city22$tract2 <- str_pad(crosswalk_city22$tract2, 6, side = "left", pad = "0")

#concatenate state, county, tract to match the haz_idx file and keep needed columns
#crosswalk_city22$tract3 <- paste(crosswalk_city22$state,crosswalk_city22$county,crosswalk_city22$tract2)
#crosswalk_city22$tract3 <- gsub(" ", "", crosswalk_city22$tract3)
#crosswalk_city22 <- crosswalk_city22 %>%
  #select(place,tract3,afact)
#colnames(crosswalk_city22) <- c("place", "GEOID", "afact")

#add leading zero to place 
#crosswalk_city22$place <- str_pad(crosswalk_city22$place, 5, side = "left", pad = "0")


#### 2018 PLACE ####
  
###### (9) create place-level environmental indicators 
#using poverty and race-idenity subgroups for 2018 and percent of tract in place #####

#import places/pop file and prep to limit to population cutoff palces 
state_places_pop18 <- read_csv("geographic-crosswalks/data/place-populations.csv")
#match data types 
state_places_pop18$state <- as.integer(state_places_pop18$state)
state_places_pop18$place <- as.integer(state_places_pop18$place)
#keep only 2018 data (should leave us with 486 obs total)
keep <- c(2018)
state_places_pop18 <- filter(state_places_pop18, year %in% keep)
#add leading zero to state and place 
state_places_pop18$state <- str_pad(state_places_pop18$state, 2, side = "left", pad = "0")
state_places_pop18$place <- str_pad(state_places_pop18$place, 5, side = "left", pad = "0")
#add geoid
state_places_pop18 <-  state_places_pop18 %>%
  mutate(geoid = str_c(state, place))

#2018 merge tract hazard indicators including poverty and race to places - left join since places (city crosswalk) has more observations
tract_place_haz18 <- tidylog::left_join(x = crosswalk_city18, y = race_pov_enviro18, by = "GEOID")
#51 only in crosswalk; 552 only in race_pov_enviro18 

#tract_place_haz18_2 <- tidylog::left_join(x = crosswalk_city22, y = race_pov_enviro18, by = "GEOID")
#38,936 only in crosswalk; 11,899 only in race_pov_enviro18 

#check missing places
no_join18 <- tidylog::anti_join(x = state_places_pop18, y = tract_place_haz18, 
                       by = c("state", "place"))
#3 places do not join - only in state_places, not in tract_place_haz18 or crosswalk_city18 (06 37692, 13 49008, 13 72122)

#no_join22 <- tidylog::anti_join(x = state_places_pop18, y = tract_place_haz18_2, 
                                #by = c("state", "place"))
#1 place does not joing (52120)

#add missing row (state 16 place 52120) to tract_haz_place18 to match other files
tract_place_haz18 <- tract_place_haz18 <- 
  bind_rows(tract_place_haz18, no_join18) #CHECK 

#Create "All" observations 
#calculate place population for tracts and haz_idx weighting by amount of tract in place and tract total population
all_enviro_place18 <- tract_place_haz18 %>%
  mutate(tract_pop = (total_pop*afact)) %>% #to account for the fact that only part of the tract population is in the place
  mutate(na_pop_new = na_pop*afact) %>% #CHECK -- later just multiplie na_pop by afact in the sum line  
  group_by(state, place) %>%
  summarise(environmental = weighted.mean(haz_idx, tract_pop, na.rm = TRUE),
        na_pop = sum(na_pop_new),
        place_pop = sum (tract_pop)) %>% 
        ungroup()

sum(all_enviro_place18$na_pop_new, na.rm = TRUE)
sum(tract_place_haz18$na_pop, na.rm = TRUE)/2

tract_place_haz18$unique_col <- paste0(tract_place_haz18$GEOID, tract_place_haz18$place)
length(unique(tract_place_haz18$unique_col))
  
#calculate percent population of each county that has missing tract hazard information
all_enviro_place18 <- all_enviro_place18 %>%
  mutate(na_perc = na_pop / place_pop,
      subgroup = "All",
      subgroup_type = "all") %>%
select(-c(na_pop, place_pop))
    
#create geoid for filtering later
all_enviro_place18 <- all_enviro_place18 %>%
  mutate(geoid = str_c(state, place), state, place)
  
###create place level index by race###
pov_enviro_place18 <- tract_place_haz18 %>%
  mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty,
                                    poverty_type == "Not High Poverty" ~ (total_pov - poverty)),
          na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
  group_by(state, place, poverty_type) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), #Multiplied weight by % in Tract
            na_pop = sum(na_pop*afact, na.rm = TRUE), #CHECK - multiply na_pop by afact?
            subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup()%>%
  mutate(geoid = str_c(state,place),
          na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop))
  
#create file of unique states and places 
state_place18 <- tract_place_haz18 %>%
  transmute(geoid = str_c(state, place), state, place) %>%
  distinct()%>%
  filter(!is.na(geoid)) 
  
#expand poverty/place dataset for every place/poverty_type (from 1,596 to 3,072) 
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
#weight the index by total population for tracts that have mixed race and ethnicity * percentage of tract in place      #[CHECK]
#weight by number of people of color for tracts that are majority non-whire * percentage of tract in place              #[CHECK]
#calculate missingness 
  
haz_by_race_place18 <- tract_place_haz18 %>%
  mutate(weighting_ind = case_when(race_ind == "No Majority Race/Ethnicity" ~ total_pop,
                                    race_ind == "Majority Non-White" ~ poc,
                                    race_ind == "Majority White, Non-Hispanic" ~wnh),
          na_pop = if_else(is.na(haz_idx) | is.na(race_ind), weighting_ind, 0)) %>%
  group_by(state, place, race_ind) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), ##[CHECK - weight by afact??]##
            na_pop = sum(na_pop*afact, na.rm = TRUE), #CHECK 
            subgroup_pop = sum(weighting_ind*afact, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, place),
          na_perc = na_pop / subgroup_pop) %>%  
  select(-c(na_pop, subgroup_pop)) 
  
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
  
###APPEND DATA### 
bind_data_place18 <- all_enviro_place18 %>%
  bind_rows(pov_env_exp_place18) %>%
  bind_rows(haz_by_race_exp_place18) %>%
#organize data 
#create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(
    environmental_quality = if_else(na_perc >= .05,2,1),
    year = 2018
          ) %>%
  select(-na_perc) 
  
#keep only the places in the places_pop18 file 
final_data_place18 <- bind_data_place18 %>%
  filter(geoid %in% state_places_pop18$geoid) %>%
#filter out those with missing subgroup
  filter(!is.na(subgroup)) 

#match to data standards
 final_data_place18 <-  final_data_place18 %>%
   arrange(year,
            state,
            place,
            subgroup_type,
            subgroup)%>%
    select(year, state, place, subgroup_type, subgroup, environmental, environmental_quality) 
    #should have 2,916
 
#round environmental indicator to nearest integer
final_data_place18$environmental <- round(final_data_place18$environmental, digits = 0)
  
#save file as csv
write_csv(final_data_place18, "06_neighborhoods/environment/data/output/environment_place_sub18.csv")
 
#create a file with only place-level observations
final_place_all18 <- final_data_place18 %>%
  filter(subgroup == "All")
write_csv(final_place_all18, "06_neighborhoods/environment/data/output/environment_place_18.csv")
 
 
#### 2014 PLACE FILE ####
 
##### (10) create place-level environmental indicators using poverty and race-identity subgroups for 2014 and percent of tract in place #####
 
 
#prep place file to limit to population cutoff places 
state_places_pop14 <- state_places_pop18 %>%
  mutate(year = 2014)
 
#2014 merge tract hazard indicators including poverty and race to places - left join since places (city crosswalk) has more observations
tract_place_haz14 <- tidylog::left_join(x = crosswalk_city18, y = race_pov_enviro14, 
                                        by= "GEOID")
 
#check missing places - #118 *6 = 708
no_join14 <- anti_join(by = c("state","place"), x = state_places_pop14, y = tract_place_haz14)
#three places do not join (06 37692; 13 49008; 13 72122)
#if using city22 - one place does not join - place 52120 in state 16 (Idaho)
 
#add missing row (state 16 place 52120) to tract_haz_place14 match other files
tract_place_haz14 <- tract_place_haz14 %>%
   bind_rows(tract_place_haz14, no_join14)

#Create "All" observations for each place 
#calculate place population for tracts and haz_idx weighting by amount of tract in place and tract total population
all_enviro_place14  <- tract_place_haz14 %>%
  mutate(tract_pop = (total_pop*afact)) %>% #to account for the fact that only part of the tract population is in the place
  group_by(state, place) %>%
  summarise(environmental = weighted.mean(haz_idx, tract_pop, na.rm = TRUE),
            na_pop = sum(na_pop*afact), #CHECK 
            place_pop = sum (tract_pop)) %>% 
  ungroup()
 
#calculate percent population of each county that has missing tract hazard information
all_enviro_place14 <- all_enviro_place14 %>%
  mutate(na_perc = na_pop / place_pop,
        subgroup = "All",
        subgroup_type = "all") %>%
  select(-c(na_pop, place_pop))
 
#create geoid for filtering later
all_enviro_place14 <- all_enviro_place14 %>%
  mutate(geoid = str_c(state, place), state, place)
 
###create place level index by race###
pov_enviro_place14 <- tract_place_haz14 %>%
  mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty,
                                  poverty_type == "Not High Poverty" ~ (total_pov - poverty)),
        na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
  group_by(state, place, poverty_type) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), #Multiplied weight by % in Tract
            na_pop = sum(na_pop*afact, na.rm = TRUE),#CHECK 
            subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup()%>%
  mutate(geoid = str_c(state,place),
        na_perc = na_pop / subgroup_pop) %>%
  select(-c(na_pop, subgroup_pop))
 
#create file of unique states and places 
state_place14 <- tract_place_haz14 %>%
  transmute(geoid = str_c(state, place), state, place) %>%
  distinct()%>%
  filter(!is.na(geoid)) 
 
#expand poverty/place dataset for every place/poverty_type (from 1,596 to 3,072) 
expand_pov_place14 <- pov_enviro_place14 %>%
  expand(geoid, poverty_type)
 
#join dataset on expanded dataset, join with geo variable, and add subgroup type variables
pov_env_exp_place14 <- left_join(expand_pov_place14,
                                pov_enviro_place14 %>%
                                  select(geoid, poverty_type, environmental, na_perc),
                                by=c("geoid",
                                      "poverty_type")) %>%
  left_join(state_place14, by = "geoid") %>%
  rename(subgroup = poverty_type) %>%
  mutate(subgroup_type = "poverty")
 
###Average place level hazard by race/ethnicity###
#weight the index by total population for tracts that have mixed race and ethnicity * percentage of tract in place      #[CHECK]
#weight by number of people of color for tracts that are majority non-white * percentage of tract in place              #[CHECK]
#calculate missingness 
 
haz_by_race_place14 <- tract_place_haz14 %>%
  mutate(weighting_ind = case_when(race_ind == "No Majority Race/Ethnicity" ~ total_pop,
                                  race_ind == "Majority Non-White" ~ poc,
                                  race_ind == "Majority White, Non-Hispanic" ~wnh),
        na_pop = if_else(is.na(haz_idx) | is.na(race_ind), weighting_ind, 0)) %>%
  group_by(state, place, race_ind) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind*afact, na.rm = TRUE), ##[CHECK - weight by afact??]##
            na_pop = sum(na_pop*afact, na.rm = TRUE), #CHECK 
            subgroup_pop = sum(weighting_ind*afact, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, place),
        na_perc = na_pop / subgroup_pop) %>%  
  select(-c(na_pop, subgroup_pop)) 
 
#expand dataset for every place/race/ethnicity 
expand_race_place14 <- haz_by_race_place14 %>%
  expand(geoid,race_ind)
 
#join to expanded, add geo variables, and add subgroup variables 
haz_by_race_exp_place14 <- left_join(expand_race_place14,
                                    haz_by_race_place14 %>%
                                      select(geoid, race_ind, environmental, na_perc),
                                    by=c("geoid", "race_ind")) %>%
  left_join(state_place14, by = "geoid") %>%
  rename(subgroup = race_ind) %>%
  mutate(subgroup_type = "race-ethnicity")
 
###APPEND DATA### 9,216 obs (?)
bind_data_place14 <- all_enviro_place14 %>%
  bind_rows(pov_env_exp_place14) %>%
  bind_rows(haz_by_race_exp_place14) %>%
  #organize data 
  #create quality variable where quality is 2 if value is missing by more than 5 percent
  mutate(
    environmental_quality = if_else(na_perc >= .05,2,1),
    year = 2014
  ) %>%
  select(-na_perc) 
 
#keep only the places in the places_pop18 file 
final_data_place14 <- bind_data_place14 %>%
  filter(geoid %in% state_places_pop14$geoid) %>%
#filter out those with missing subgroup
  filter(!is.na(subgroup))
 
#match to data standards - soudl have 2,916
final_data_place14 <-  final_data_place14 %>%
  arrange(year,
          state,
          place,
          subgroup_type,
          subgroup)%>%
  select(year, state, place, subgroup_type, subgroup, environmental, environmental_quality) 

#file with only place-level observations - should have 486
final_place_all14 <- final_data_place14 %>%
  filter(subgroup == "All")

##### (11) bind 2018 and 2014 place files for final files ####
 
#bind 2014 and 2018 place data with subgroup observations
environment_place_all_sub <- final_data_place18 %>%
  bind_rows(final_data_place14)
 
#round environmental indicator to nearest integer
environment_place_all_sub$environmental <- round(environment_place_all_sub$environmental, digits = 0)
 
#save as a csv file 
write_csv(environment_place_all_sub, "06_neighborhoods/environment/data/output/environment_place_sub_all.csv")

#filter and save multi-year place file (no subgroups)
environment_place_all <- environment_place_all_sub %>%
  filter(subgroup == "All")
#972 observations - correct 
write_csv(environment_place_all_sub, "06_neighborhoods/environment/data/output/environment_place_all.csv")
 
  