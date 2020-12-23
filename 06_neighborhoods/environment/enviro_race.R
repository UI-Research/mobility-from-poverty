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


dir.create("06_neighborhoods/environment/data", showWarnings = FALSE)

####STEP ONE: PULL RACE VARIABLES FROM ACS####
# pull total population and white, non-Hispanic population by tract from the ACS
state_fips <- unique(urbnmapr::states$state_fips)
pull_acs <- function(state_fips) {
  tidycensus::get_acs(geography = "tract", 
          variables = c("total_pop" = "B02001_001","wnh" = "B03002_003"),
          year = 2014,
          state = state_fips,
          geometry = FALSE,
          output = "wide")
}
acs <- map_df(state_fips, pull_acs)


####STEP TWO: CREATE INDICATORS FOR RACE#### 

# use acs data to create a variable for percent poc, by tract
race<- acs %>%
  transmute(GEOID = GEOID,
            name = NAME,
            total_pop = total_popE,
            wnh = wnhE,
            poc = total_pop - wnh, 
            percent_poc = poc/total_pop
    )  


# create indicator variable for race based on perctage of poc/nh-White in each tract. These percentage cut offs were determined by Marge Turner.
race_indicator <- race %>%
  mutate(
    GEOID = as.numeric(GEOID),
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"No Predominant Racial Group",
      percent_poc >= .6 ~ "Predominantly People of Color",
      percent_poc <= .6 ~ "Predominantly White, Non-Hispanic")
  )


# create state and county level fips from geoids
state_county <- race_indicator %>%
  mutate(
  state = str_sub(GEOID, 1, 2),
  county = str_sub(GEOID, 3, 5),
  GEOID = as.numeric(GEOID)
  ) 


####STEP THREE: PULL IN AIR QUALITY INDEX FROM AFFH DATA####


#use completed haz_idx file previously created and add leading zeros to state and county fips to match acs file
enviro <- read.csv("./tract_level_enviro.csv") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0"))%>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0"))%>%
  mutate(GEOID = as.numeric(GEOID))
  
#keep relevant variables
enviro_idx <- enviro %>%
  select(-NAME, -estimate, -moe)

#join to race indicator file
race_enviro <- left_join(race_indicator, enviro_idx, by="GEOID")


# drop census tracts with zero population (618): 
race_tracts_with_pop <- filter(race_enviro, total_pop > 0)

####STEP FOUR: CREATE POVERTY METRICS ####
#pull HUD AFFH data on poverty
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

# puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
affh <- affh %>%
  select(GEOID = geoid, pct_poor) %>%
  filter(state_name!= "Puerto Rico")

# two county names and fips codes were changed.
# edit the GEOIDs to match the current fips codes. 
affh <- affh %>%
  mutate(
    GEOID = str_pad(GEOID, width = 11, "left", "0"),
    GEOID = case_when(
      GEOID ==  "46102940500" ~ "46113940500", 
      GEOID ==  "46102940800" ~ "46113940800",
      GEOID ==  "46102940900" ~ "46113940900", 
      GEOID == "02158000100" ~ "02270000100",
      TRUE ~ GEOID
    )
  )
# tracts where pct_poor <= 40 (40% or higher poverty rate) has a high level of poverty
# create indicator for poverty rate
poverty_indicator <- affh %>%
  mutate (
    poverty_type = case_when(
      pct_poor <= 40 ~ "high_poverty",
      pct_poor >  40 ~ "low_poverty"
    )
  )

# join to race and hazard index file
poverty_indicator <- poverty_indicator %>%
  mutate(GEOID = as.numeric(GEOID))
haz_poverty_race <- left_join(race_enviro, poverty_indicator, by="GEOID")

# drop census tracts with zero population:
haz_poverty_race <- filter(haz_poverty_race, total_pop > 0)


####STEP FIVE: CHECK MISSINGNESS ####
#number of tracts with pop > 0 & missing poverty rates:

tracts_with_pop_na <- filter (haz_poverty_race) %>%
  filter (is.na(poverty_type))

#there are 168 census tracts with missing poverty rates
#this is significant: use acs to fill in missing data
state_fips <- unique(urbnmapr::states$state_fips)
poverty_acs <- function(state_fips) {
  tidycensus::get_acs(geography = "tract", 
                      variables = c("total_pop" = "B17026_001", "poverty_status" = "B17026_002"),
                      year = 2014,
                      state = state_fips,
                      geometry = FALSE,
                      output = "wide")
}
pov_acs <- map_df(state_fips, poverty_acs)

# use acs data to create a variable for percent in poverty, by tract
poverty <- pov_acs %>%
  transmute(GEOID = GEOID,
            name = NAME,
            total_pop = total_popE,
            poverty_status = poverty_statusE,
            percent_in_poverty = poverty_status/total_pop * 100
  )  

# tracts where percent_in_poverty >= 40 (40% or higher poverty rate) has a high level of poverty
# drop if population = 0.
poverty <- filter(poverty, total_pop > 0)


# create indicator for poverty rate
poverty_acs_indicator <- poverty %>%
  mutate (
    poverty_type = case_when(
      percent_in_poverty >= 40 ~ "high_poverty",
      percent_in_poverty < 40 ~ "low_poverty"
    )
  )

#merge this with other data
poverty_acs_indicator <- poverty_acs_indicator %>%
  mutate(GEOID = as.numeric(GEOID))
poverty_from_acs<- left_join(tracts_with_pop_na, poverty_acs_indicator, by="GEOID")
# the ACS can only fill in 6/163 missing observations. The other census tracts do not have a population. 
#This will be noted in README file, and these tracts will have a data quality of 2.

#number of tracts with pop>0 & missing hazard indices:
tracts_haz_na <- filter (haz_poverty_race) %>%
  filter (is.na(haz_idx))
#there are 22 census tracts with missing hazard indices. 
# this is not significant. drop these tracts:


#number of tracts with pop > 0 & missing race:
tracts_race_na <- filter (haz_poverty_race) %>%
  filter (is.na(race_ind))
#there are zero tracts with missing race indices and a population > 0.

#drop tracts with missing environmental quality. Keep tracts with missing poverty rates, but note the unrealiability: 
environment_poverty_race  <- haz_poverty_race %>%
  drop_na(haz_idx)


####STEP SIX: CREATE COUNTY LEVEL ESTIMATES####
# calculate avg county level hazard index
all_environment_quality <- enviro %>%
  drop_na(haz_idx) %>%
  dplyr::group_by(state, county) %>%
  summarize(environmental_quality = mean(haz_idx)) %>%
  ungroup()


#avg county level hazard, by income level
income_indicator <- haz_poverty_race %>%
  mutate(GEOID = as.numeric(GEOID)) %>%
  select(-state, -county, -haz_idx, -pct_poor, -tract, -total_pop, -wnh, -poc, -percent_poc, -state_name, -county_name, -env_qual_high_pov, -env_qual_score_low_pov, -race_ind)
income_environment_quality <- left_join(income_indicator, enviro, by="GEOID")

income_environment_quality <- income_environment_quality %>%
  dplyr::group_by(state, county,poverty_type) %>%
  summarize(environmental_quality = mean(haz_idx)) %>%
  ungroup() %>%
  mutate(geoid = str_c(state, county))


# there should be an indicator for low and high income per county.
# fill in for counties:

expanded <- income_environment_quality %>%
  expand(geoid, poverty_type) 

income_environmental_quality <- left_join(expanded, income_environment_quality, by=c("geoid", "poverty_type"))

#avg county level hazard, by raceethnicity
race_tracts_with_pop <- race_tracts_with_pop %>%
  select (-total_pop, -wnh, -poc, -percent_poc, -name, -na_pop) %>%
  mutate(GEOID = as.numeric(GEOID))

raceethnicity_environment_quality <- race_tracts_with_pop %>%
  dplyr::group_by(state, county, state_name, county_name, race_ind) %>%
  summarize(environmental_quality = mean(haz_idx)) %>%
  ungroup() %>%
  mutate(geoid = str_c(state,county))

# there should be an environmental quality indicator for majority white, no majority, and majority poc per county.
# fill in for counties:

expand_race <- raceethnicity_environment_quality %>%
  filter(!is.na(environmental_quality)) %>%
  expand(geoid,race_ind) 

raceethnicity_environment_quality <- left_join(expand_race, raceethnicity_environment_quality, by=c("geoid", "race_ind"))


####STEP SEVEN: OUTPUT DATA####
#make file match data standards
raceethnicity_environment_quality <- raceethnicity_environment_quality  %>%
  add_column(year = 2014, .before = "state") %>%
  add_column(quality_flag = 1, .after = "environmental_quality") %>%
  select(-geoid, -state_name, -county_name) 

raceethnicity_environment_quality <- raceethnicity_environment_quality[,c("year", "state", "county", "race_ind", "environmental_quality", "quality_flag")]

write_csv(raceethnicity_environment_quality, "county_level_enviro_raceethnicity.csv")


income_environmental_quality <- income_environmental_quality  %>%
  add_column(year = 2014, .before = "state") %>%
  add_column(quality_flag = 1, .after = "environmental_quality") %>%
  select(-geoid)

income_environmental_quality <- income_environmental_quality[,c("year", "state", "county", "poverty_type", "environmental_quality", "quality_flag")]
write_csv(income_environmental_quality, "county_level_enviro_income.csv")





