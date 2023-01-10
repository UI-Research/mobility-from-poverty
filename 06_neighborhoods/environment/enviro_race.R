# enviro_race. R
# creates tract-level indicators of poverty and race for counties in US
# created by Peace Gwam
# updated on 2020-12-22


# install.packages("devtools")
# devtools::install_github("UrbanInstitute/urbnmapr")
library(tidyverse)
library(tidycensus)
library(purrr)
library(urbnmapr)
library(skimr)
#to use tidycensus, use census_api_key function to set api key. download api key from https://api.census.gov/data/key_signup.html

options(scipen = 999)

#add data folder in current directory, if not available already
dir.create("data", showWarnings = FALSE)

####STEP ONE: PULL RACE VARIABLES FROM ACS####
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
                      output = "wide")
}
acs <- map_df(state_fips, pull_acs)


####STEP TWO: CREATE INDICATORS FOR RACE AND POVERTY#### 

# use acs data to create a variable for percent poc, by tract
race_pov<- acs %>%
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
race_pov <- race_pov %>%
  mutate(
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"Mixed Race and Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )


# two county names and fips codes were changed.
# edit the GEOIDs to match the current fips codes. 
race_pov <- race_pov %>% 
  mutate(GEOID = case_when(
    GEOID ==  "46113940500" ~ "46102940500",
    GEOID ==  "46113940800" ~ "46102940800",
    GEOID ==  "46113940900" ~ "46102940900", 
    GEOID ==  "02270000100" ~ "02158000100",
    TRUE ~ GEOID
  ))


####STEP THREE: PULL IN AIR QUALITY INDEX FROM AFFH DATA####


# pull hud affh data on air quality
# AFFH data is available via the Urban Institute Data Catalog here: 
# https://datacatalog.urban.org/dataset/data-and-tools-fair-housing-planning/resource/12d878f5-efcc-4a26-93e7-5a3dfc505819 
# code book is here: https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2020/07/31/AFFH-Data-Documentation.pdf

affh <- read_csv("data/AFFH_tract_AFFHT0006_July2020.csv", 
                 col_types = cols(
                   .default = col_double(),
                   category = col_character(),
                   stusab = col_character(),
                   state_name = col_character(),
                   county_name = col_character()
                 ))


# keep only variables needed for analyses
enviro_stats <- affh %>%
  select(GEOID = geoid, state, state_name, county, county_name, tract, haz_idx) 


#puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
enviro_stats<- enviro_stats %>%
  filter(state_name!= "Puerto Rico")

# add leading zeros to GEOID to match with the acs
enviro_stats <- enviro_stats %>%
  mutate(
    GEOID = str_pad(string = GEOID,
                    width = 11,
                    side = "left",
                    pad = "0")
  )

#add state/county/tract variables
enviro_stats <- enviro_stats%>%
  mutate(
    state = str_sub(GEOID, 1, 2), 
    county = str_sub(GEOID, 3, 5), 
    tract = str_sub(GEOID, 6, 11)
  )


#join to race indicator file
race_enviro <- left_join(race_pov, enviro_stats, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx), total_pop, 0))



####STEP FOUR: CHECK MISSINGNESS ####
#number of tracts with pop > 0 & missing poverty rates:

#census tracts with zero population (618): 
filter(race_enviro, total_pop == 0)

#census tracts with population that are missing hazard index (508)
filter(race_enviro, total_pop==0, is.na(haz_idx))

#census tracts with population greater than 0 that are missing hazard index (22)
filter(race_enviro, total_pop>0, is.na(haz_idx))

#census tracts with population greater than 100 that are missing hazard index (22)
filter(race_enviro, total_pop>100, is.na(haz_idx))

#census tracts with zero population counted in poverty total metric (147)
filter(race_enviro, total_pov == 0, total_pop != 0)

#census tracts with zero population counted in poverty total metric 
#also have hazard index missing (10)
filter(race_enviro, total_pov == 0, total_pop != 0, is.na(haz_idx))

####STEP FIVE: CREATE COUNTY LEVEL ESTIMATES####
### calculate avg county level hazard index
all_environment <- race_enviro %>%
  group_by(state, county) %>%
  summarise(environmental = weighted.mean(haz_idx, total_pop, na.rm=TRUE), 
            na_pop = sum(na_pop), 
            county_pop = sum(total_pop)) %>%
  ungroup() 

#create percent of the population of each county has has missing tract hazard information
all_environment <- all_environment %>% 
  mutate(na_perc = na_pop / county_pop, 
         subgroup = "All", 
         subgroup_type = "all") %>% 
  select(-c(na_pop, county_pop))

#check max percent of population of county that has missing hazard information
all_environment %>% 
  pull(na_perc) %>% 
  max()


###create county level hazard index by race
#checked transportation code; excluded tracts that do not have poverty information, which we replicate here
#we weight the index by number in poverty if it is a high poverty area, and the number not in poverty
#if it is a low poverty area. we also count percent missing by those na's in order to more accurately
#track missingness.
pov_environment <- race_enviro %>%
  mutate(weighting_ind = case_when(poverty_type == "High Poverty" ~ poverty, 
                                   poverty_type == "Not High Poverty" ~ (total_pov - poverty)), 
    na_pop = if_else(is.na(haz_idx) | is.na(poverty_type), weighting_ind, 0)) %>%
  group_by(state, county,state_name, county_name, poverty_type) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE), 
            na_pop = sum(na_pop, na.rm = TRUE), 
            subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, county), 
         na_perc = na_pop / subgroup_pop) %>% 
  select(-c(na_pop, subgroup_pop)) %>% 
  filter(!is.na(poverty_type))

#make dataset of unique state/county pairs
state_county <- race_enviro %>% 
  transmute(geoid = str_c(state, county), state, county, state_name, county_name) %>% 
  distinct()

# there should be an indicator for low and high income per county.
# expand dataset for every county/poverty_type

expanded <- pov_environment %>%
  expand(geoid, poverty_type) 

#join dataset on expanded dataset, join with geo variables, and add subgroup type variables
pov_environment_exp <- left_join(expanded, 
                                         pov_environment %>% 
                                           select(geoid, poverty_type, environmental, na_perc), 
                                         by=c("geoid", 
                                              "poverty_type")) %>% 
  left_join(state_county, by = "geoid") %>% 
  rename(subgroup = poverty_type) %>% 
  mutate(subgroup_type = "poverty")


###avg county level hazard, by raceethnicity
#we choose to weight the index by total population for tracts that have 
#Mixed Race and Ethnicity, weight by number of people of color for tracts
#that are Majority Non-White, and weight by white, non hispanic 
#people in tracts that are predominantly white. we calculate missingness
#based off of these weights as well. 
haz_by_race <- race_enviro %>% 
  mutate(weighting_ind = case_when(
    race_ind == "Mixed Race and Ethnicity" ~ total_pop, 
    race_ind == "Majority Non-White" ~ poc,
    race_ind == "Majority White, Non-Hispanic" ~ wnh
  ), 
    na_pop = if_else(is.na(haz_idx) | is.na(race_ind), 
                          weighting_ind,
                          0)) %>%
  group_by(state, county, state_name, county_name, race_ind) %>%
  summarise(environmental = weighted.mean(haz_idx, weighting_ind, na.rm = TRUE), 
  na_pop = sum(na_pop, na.rm = TRUE), 
  subgroup_pop = sum(weighting_ind, na.rm=TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, county), 
         na_perc = na_pop / subgroup_pop) %>% 
  select(-c(na_pop, subgroup_pop)) %>% 
  filter(!is.na(race_ind))


# there should be an environmental quality indicator for majority white, no majority, and majority poc per county.
# fill in for counties:

expand_race <- haz_by_race %>%
  expand(geoid,race_ind) 

#join to expanded dataset, add geo variables, and add subgroup variables
haz_by_race_exp <- left_join(expand_race, 
                             haz_by_race %>% 
                               select(geoid, race_ind, environmental, na_perc), 
                             by=c("geoid", "race_ind")) %>% 
  left_join(state_county, by = "geoid") %>% 
  rename(subgroup = race_ind) %>% 
  mutate(subgroup_type = "race-ethnicity")

####STEP SIX: Append DATA####

final_dat<- all_environment %>% 
  bind_rows(pov_environment_exp) %>% 
  bind_rows(haz_by_race_exp) 

####STEP SEVEN: Make File Match Data Standards####
final_dat <- final_dat %>% 
  select(-c(geoid, state_name, county_name)) %>% 
  mutate(year = 2014) %>% 
  select(year, state, county, environmental, everything()) %>% 
  #we choose to make the quality variable 2 if missing value is missing by more than 5 percent
  mutate(environmental_quality = if_else(na_perc >= .05, 2, 1)) %>% 
  #select(-na_perc) %>% 
  arrange(year, 
          state, 
          county, 
          subgroup_type,
          subgroup) %>%
  select(year, state, county, subgroup_type, subgroup, environmental, environmental_quality)


#Check to make sure that environmental quality and environmental have the same amount of missings
stopifnot(sum(is.na(final_dat$environmental_quality)) == sum(is.na(final_dat$environmental)))


####STEP EIGHT: Write Out File####
final_dat %>% 
  filter(subgroup == "All") %>% 
  select(-subgroup, -subgroup_type) %>%
  write_csv("enviro.csv")

final_dat %>% 
  filter(subgroup_type %in% c("all", "race-ethnicity")) %>%
  write_csv("enviro_race-ethnicity.csv")

final_dat %>% 
  filter(subgroup_type %in% c("all", "poverty")) %>%
  write_csv("enviro_poverty.csv")


