# enviro. R
# pulls enviromental idicators from HUD AFFH data and population weighs observations 
# created by Peace Gwam
# updated on 2020-08-27


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
  select (-variable)



# pull hud affh data on air quality
# AFFH data is no longer available via hud.gov. use urban data catalog for access. 
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

# remove puerto rico from affh data because not part of analysis
affh <- affh %>%
  filter (state_name != "Puerto Rico")

# add leading zeros to GEOID to match with the acs
enviro_stats <- enviro_stats %>%
  mutate (GEOID = as.character(GEOID),
          GEOID = str_pad(string = GEOID,
                          width = 11,
                          side = "left",
                          pad = "0"))

# join acs data with affh data
full_data <- left_join(enviro_stats, acs, by = "GEOID")


####STEP TWO: VALIDATE AND CLEAN MERGED DATA ####

# identify census tracts not represented in affh data - 4 in US 
anti_join(acs, enviro_stats, by= c("GEOID"))

# drop census tracts not in affh data 
tracts_in_affh <- filter(full_data, !GEOID %in% c("02270000100", "46113940500", "46113940800", "46113940900"))


# drop the census tracts with no est. population:
tracts_with_pop <- filter(tracts_in_affh, estimate > 0)

# there are 26 remaining tracts that have population and no hazard information. These tracts have between 1 and 7778 people
# tracts with no hazard indices and a population greater than zero: 
tracts_with_pop %>%
  filter(is.na(haz_idx)) %>%
  

# the number of tracts without a hazard index and population > 0 are about 0.03% of all observations
# proceed by dropping the census tracts without haz_idx:
tracts_with_haz <- filter(tracts_with_pop, !is.na(haz_idx))

# check to make sure that observations have hazard indices and populations greater than zero:
stopifnot(
  !is.na(tracts_with_haz$haz_idx), 
  tracts_with_haz$estimate > 0
)


####STEP THREE: WEIGH OBSERVATIONS BY POPULATION ####

# calculate average county level haz_idx, weighted by population
county_enviro_stats <- tracts_with_haz %>%
  group_by(state, county) %>%
  summarize(mean_haz_idz = weighted.mean(x = haz_idx, w = estimate),
      ) %>%
  ungroup()


####STEP FOUR: EXPORT DATA ####

#make file match data standards
county_enviro_stats <- county_enviro_stats %>%
  add_column(year = 2014, .before = "state") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL)) %>% 
  select(-GEOID)

##output data
write_csv(county_enviro_stats, "county_level_enviro.csv")
