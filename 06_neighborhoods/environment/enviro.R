# enviro. R
# pulls enviromental idicators from HUD AFFH data and population weighs observations 
# created by Peace Gwam
# updated on 08-17-2020


#install.packages("devtools")
#devtools::install_github("UrbanInstitute/urbnmapr")
library(tidyverse)
library(tidycensus)
library(purrr)
library(urbnmapr)

census_api_key("021b4f58d83bd96aa25f2f4fd4e5570ef37ca284", install = TRUE, overwrite = TRUE)

####STEP ONE: PULL AND MERGE DATA####

# pull hud affh data on air quality
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


# add leading zeros to GEOID to match with the acs
enviro_stats <- enviro_stats %>%
  mutate (GEOID = as.character(GEOID),
          GEOID = str_pad(string = GEOID,
                          width = 11,
                          side = "left",
                          pad = "0"))

# pull 2010-2014 5 yr acs data - total population per tract
state_fips <- unique(urbnmapr::states$state_fips)
my_states <- function(state_fips) {
  get_acs(geography = "tract",
            variables  = "B01003_001", 
            year = 2014,
            key = key,
            state = state_fips,
            geometry = FALSE)
}
my_states <- map_df(state_fips, my_states)

# remove variable column to easily merge with Puerto Rico data below:
my_states$variable <- NULL
head(my_states)

# add acs data for Puerto Rico - affh data not available for other territories
puerto_rico <- get_acs(geography = "tract",
                    variables = "B01003_001",
                    survey = "acs5",
                    state = "PR",
                    cache_table = TRUE,
                    output = "wide",
                    year = 2014)

# rename variables to match acs pull for the states + DC
names (puerto_rico) [3] <- "estimate"
names (puerto_rico) [4] <- "moe"


# append acs data from all states, DC, and PR
acs <- rbind (my_states, puerto_rico)

# join acs data with affh data
full_data <- left_join(acs, enviro_stats, by = "GEOID")

####STEP TWO: VALIDATE AND CLEAN MERGED DATA ####

# identify census tracts not represented in affh data - 4 in US + PR
anti_join(acs, enviro_stats, by= c("GEOID"))

# drop census tracts not in affh data 
tracts_in_affh <- filter(full_data, !GEOID %in% c("02270000100", "46113940500", "46113940800", "46113940900"))


# there are 580 census tracts with N/A values for hazard indicies, with est. populations between 0 and 500
# drop the census tracts with no est. population:
tracts_with_pop<- filter(tracts_in_affh, estimate > 0)

# there are 26 remaining tracts that have population and no hazard information. These tracts have between 1 and 7778 people
# tracts with no hazard indices and a population greater than zero: 
tracts_with_pop %>%
  filter(is.na(haz_idx)) %>%
  View

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
  mutate(GEOID = str_c(state, county, collapse = NULL))




write_csv(county_enviro_stats, "output/county_level_enivro.csv", na = "NA", append = FALSE, col_names = TRUE)
