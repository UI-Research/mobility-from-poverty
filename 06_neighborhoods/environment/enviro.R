# enviro. R
# pulls enviromental idicators from HUD AFFH data and population weighs observations 
# created by Peace Gwam
# updated on 2020-09-16


#install.packages("devtools")
#devtools::install_github("UrbanInstitute/urbnmapr")
library(tidyverse)
library(tidycensus)
library(purrr)
library(urbnmapr)

#to use tidycensus, use census_api_key function to set api key. download api key from https://api.census.gov/data/key_signup.html

####STEP ONE: PULL AND MERGE DATA####

# pull 2010-2014 5 yr acs data - total population per tract 
state_fips <- unique(urbnmapr::states$state_fips)
acs <- function(state_fips) {
  get_acs(geography = "tract",
          variables  = "B01003_001", 
          year = 2014,
          key = key,
          state = state_fips,
          geometry = FALSE)
}
acs <- map_df(state_fips, acs)

# remove variable column: 
acs <- acs %>%
  select(-variable)


# pull hud affh data on air quality
# AFFH data is available via the Urban Institute Data Catalog here: 
# https://datacatalog.urban.org/dataset/data-and-tools-fair-housing-planning/resource/12d878f5-efcc-4a26-93e7-5a3dfc505819 
# code book is here: https://urban-data-catalog.s3.amazonaws.com/drupal-root-live/2020/07/31/AFFH-Data-Documentation.pdf
affh <- read_csv("raw/AFFH_tract_AFFHT0006_July2020.csv", 
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
  mutate(GEOID = as.character(GEOID),
          GEOID = str_pad(string = GEOID,
                          width = 11,
                          side = "left",
                          pad = "0"))

# two county names and fips codes were changed.
# edit the GEOIDs to match the current fips codes. 
enviro_stats <- enviro_stats%>%
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

# join affh data with acs data
full_data <- full_join(acs, enviro_stats, by="GEOID")

####STEP TWO: VALIDATE AND CLEAN MERGED DATA ####

# check merge
# note that now the census tracts match, but the county_names do not. this will not be in the final file.
anti_join(acs, enviro_stats, by="GEOID")
anti_join(enviro_stats, acs, by="GEOID")

full_data <- full_data %>%
  mutate(na_pop= if_else(condition=is.na(haz_idx), true=estimate, false=0))
####STEP THREE: WEIGH OBSERVATIONS BY POPULATION ####

# calculate average county level haz_idx, weighted by population
county_enviro_stats <- full_data %>%
  group_by(state, county) %>%
  mutate(county_pop = sum(estimate)) %>%
  summarize(na_pop = sum(na_pop)/sum(estimate), 
            haz_idx = weighted.mean(x = haz_idx, w = estimate, na.rm = TRUE)) %>%
  ungroup() 

####STEP FOUR: EXPORT DATA ####

#make file match data standards
county_enviro_stats <- county_enviro_stats %>%
  add_column(year = 2014, .before = "state") %>%
  add_column(quality_flag = 1, .after = "haz_idx") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL)) %>% 
  select(-GEOID)

##output data
write_csv(county_enviro_stats, "county_level_enviro.csv")

####STEP FIVE: DATA QUALITY CHECKS - NOT IN FINAL DATA SET ####

#number of tracts with 0 population
tracts_with_nopop <- filter(full_data, estimate == 0)
# there are 618 tracts with 0 population

#number of tracts with 0 population & missing haz_idx
tracts_with_nopop_na <- filter(tracts_with_nopop) %>%
  filter(is.na(haz_idx))

#number of tracts with pop > 0 & missing haz_idx
tracts_with_pop_na <- filter (full_data, estimate > 0) %>%
  filter (is.na(haz_idx))

# check if missing haz_idx in final dataset
stopifnot(   
  county_enviro_stats %>%
    filter(is.na(haz_idx)) %>%
    nrow()==0
)



