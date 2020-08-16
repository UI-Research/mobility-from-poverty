#Pull HUD AFFH Data on Transportation

library(tidyverse)
library(tidycensus)
library(purrr)

#First, read in the data. Because of the way it is on HUD's website, it must be downloaded first and then read in as CSV. The CSV file is saved on box and should be downloaded and this directory set up/edited before the code is run.
transport_vars <- read_csv("data/AFFH_tract_AFFHT0006_July2020.csv", 
                           col_types = cols(
                             .default = col_double(),
                             category = col_character(),
                             stusab = col_character(),
                             state_name = col_character(),
                             county_name = col_character()
                           ))

#To only keep the variables we need for this analysis, which are the geographic variables, the two indexes, and the number of households less than 50% AMI, which we will use for weighting.
#This also filters out tracts that are in Puerto Rico because we are not including them in this work and they do not have index values.
transport_stats <- transport_vars %>%
  select(GEOID = geoid, state, state_name, county, county_name, tract, tcost_idx, trans_idx, num_hh = hh_lt50ami_all) %>%
  filter(state_name != "Puerto Rico")

#The GEOID does not have leading zeroes in this dataset--this adds it so we can join to ACS data later for the data checks.
transport_stats <- transport_stats %>%
  mutate(GEOID = str_pad(string = GEOID, width = 11, side ="left", pad = "0"))

#Step 2: Pull in ACS population data at the tract level. This was used for some data quality checks--not used in final file. 
#acs_data <- load_variables(year = 2016, dataset = "acs5", cache = TRUE)
my_states <- fips_codes %>% 
 filter(!state %in% c("PR", "UM", "VI", "GU", "AS", "MP")) %>%
  pull(state) %>%
  unique()

population_var <- map_dfr(
  my_states,
  ~ get_acs(
    geography = "tract",
    state = .,
    table = "B01003",
    year = 2016,
    survey = "acs5",
    output = "wide"
    )
)

# Join the AFFH transit data with the ACS population data.
full_data <- left_join(population_var, transport_stats, by = "GEOID")

# Test with anti_join to make sure it worked properly.
stopifnot(
  anti_join(population_var, transport_stats, by = "GEOID") %>%
    nrow() == 0
)

# Checking to see if there are index values in tracts with no population:
tracts_with_pop <- filter(full_data, B01003_001E > 0)
# Answer: there are 637 census tracts with no population and no transit information.

# Checking to see if there are tracts remaining with N/A values for transit indices. 
tracts_with_pop %>%
 filter(is.na(tcost_idx)) %>%
  View

# There are 179 remaining tracts that have population and no transit information.These tracts have between 3-11317 people. These tracts span many states, mostly the most populous.
# Of the 179 tracts, 120 have populations over 1,000; 27 have populations over 5,000.


### DATA CHECK #1: TRACTS WITH N/A INDEX VALUES BUT NO POPULATION: WHAT PERCENTAGE OF THEIR COUNTY DO THEY MAKE UP? ###
#First, create new county-level GEOID
tracts_with_county_pop <- tracts_with_pop %>%
  rename(geoid = GEOID) %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL))

#Flag tract-level population for tracts in question (that have population but do not have transit index values).
population_test <- tracts_with_county_pop %>%
  mutate(na_tract_pop = ifelse(is.na(tcost_idx), B01003_001E, 0)) %>%
  group_by(GEOID) %>%
  summarise(missing_pop_county_sum = sum(na_tract_pop))

#Get county population from ACS.
county_pop <- map_dfr(
  my_states,
  ~ get_acs(
    geography = "county",
    state = .,
    table = "B01003",
    year = 2016,
    survey = "acs5",
    output = "wide"
  )
)

#Merge datasets and calculate the percent of the county population made up by the tract with N/A transit values.
test_data <- left_join(county_pop, population_test, by = "GEOID")
test_data <- test_data %>%
  mutate(perc_na = ((missing_pop_county_sum/B01003_001E)*100)) %>%
  mutate(perc_na = round(perc_na, digits = 2))

#We will set the data quality to a 2 for counties that have a N/A tract that makes up more than 10% of the county population. Including:
# 48253 (Jones County, Texas)
# 02185 (North Slope Borough, Alaska)	
# 51081 (Greensville County, Virginia)	
# 51183 (Sussex County, Virginia)
# 08043 (Fremont County, Colorado)	
# 30101 (Toole County, Montana)


### END OF DATA CHECK 1 BACK TO REMAINING DATA SET UP ###


# Next step: set both indices equal to 0 if they have N/A values.
tracts_with_pop <- tracts_with_pop %>%
  replace_na(list(tcost_idx = 0)) %>%
  replace_na(list(trans_idx = 0)) %>%
  view

# Test to see if this worked.
map_dbl(tracts_with_pop, ~sum(is.na(.)))

#In the first run, we used the total tract pop to weight to county level. This part of the code does that. We dropped this in favor of a different method, below.
#county_transport_stats2 <- tracts_with_pop %>%
 # group_by(state, county) %>%
#  summarize(mean_tcost2 = weighted.mean(x = tcost_idx, w = B01003_001E),
 #           mean_trans2 = weighted.mean(x = trans_idx, w = B01003_001E)) %>%
  # ungroup()

# to align file with naming conventions
#county_transport_stats2 <- county_transport_stats2 %>%
 # add_column(year = 2016, .before = "state") %>%
  #mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  #mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  #mutate(GEOID = str_c(state, county, collapse = NULL))
  
#export CSV
#write_csv(county_transport_stats2, "output/county_level_transit.csv", na = "NA", append = FALSE, col_names = TRUE)


### Instead: Use POPULATION WEIGHTS BY # HOUSEHOLDS <50% AMI ###
# We generated county average index values by population weighting tract averages. 
# The way we ultimately decided to do this was using the number of households <50% AMI, which more closely aligns with the definition for the index than just the overall population #.
# That number is in the AFFH dataset (the num_hh variable defined in line 20) so we already have it.
county_transport_stats <- tracts_with_pop %>%
  group_by(state, county) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh),
            mean_trans = weighted.mean(x = trans_idx, w = num_hh)) %>%
  ungroup()

#This output below compares the two versions: using total ACS pop to weight the indexes (mean_tcost2 & mean_trans2) and using AFFH # <50% AMI households to weight the indexes 
#county_transport_stats_compare <- right_join(county_transport_stats2, county_transport_stats, by = "GEOID") %>%
# select(GEOID, state = state.x, county = county.x, mean_tcost, mean_trans, mean_tcost2, mean_trans2)
# write_csv(county_transport_stats_compare, "output/county_level_transit_indexes.csv", na = "NA", append = FALSE, col_names = TRUE)


# Based on the results of this compare, the decision was made to use the # households <50% AMI instead of the total pop from ACS to weight the data. So, back to that... 
### SECOND ROUND OF DATA CHECKING: TRACTS THAT HAVE INDEX VALUES BUT NO HOUSEHOLDS UNDER 50% AMI ###
full_data %>%
  filter(tcost_idx >= 0, trans_idx >= 0) %>%
  filter(num_hh == 0) %>%
  view

#One downside of this method is that there are 149 tracts that have 0 households <50% AMI but do have transit index values >0. These were effectively zeroed out during the county-average process.
### DATA CHECK #2 ###
test_data2 <- full_data %>%
  rename(geoid = GEOID) %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL))

#Want to take a similar approach to flagging potential data quality concerns here: if one of these tracts makes up more than 10% of county population, will flag its data quality as 2.
population_test2 <- test_data2 %>%
  mutate(nohh_tract_pop = ifelse(num_hh == 0, B01003_001E, 0)) %>%
  group_by(GEOID) %>%
  summarise(nohh_tract_county_sum = sum(nohh_tract_pop))

#Merge with ACS county data to calculate the percent of the county population made up by the tract with N/A transit values.
test_data2 <- left_join(county_pop, population_test2, by = "GEOID")
test_data2 <- test_data2 %>%
  mutate(perc_nohh = ((nohh_tract_county_sum/B01003_001E)*100)) %>%
  mutate(perc_nohh = round(perc_nohh, digits = 2))

#write_csv(test_data2, "output/test_no_hh.csv", na = "NA", append = FALSE, col_names = TRUE)
#write_csv(full_data, "output/test_no_hh_compare.csv", na = "NA", append = FALSE, col_names = TRUE)
### END OF DATA CHECK 2 ###

### NOW THAT WE ARE SATISFIED, MAKING OUR FINAL DATASET ###
#And now, getting everything in the format that it needs to be in.
county_transport_stats <- county_transport_stats %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL)) %>%
  mutate(mean_tcost = round(mean_tcost, digits = 2)) %>%
  mutate(mean_trans = round(mean_trans, digits = 2)) %>%
  rename(geoid = GEOID)
  
#Plus, adding data quality values. Counties will generally be given a 1 except for the counties flagged by the two data quality exercises.
problem_counties_tcost <- c("48253", # (Jones County, Texas) flagged for n/a index values
                      "02185", # (North Slope Borough, Alaska) flagged for n/a index values	
                      "51081", # (Greensville County, Virginia)	flagged for n/a index values
                      "51183", # (Sussex County, Virginia) flagged for n/a index values
                      "08043", # (Fremont County, Colorado)	flagged for n/a index values
                      "30101", # (Toole County, Montana) flagged for n/a index values
                      "42119", # (Union County, Pennsylvania) flagged for nonzero index values but 0 households <50% AMI
                      "48001", # (Anderson County, Texas) 	flagged for nonzero index values but 0 households <50% AMI
                      "39097", # (Madison County, Ohio) flagged for nonzero index values but 0 households <50% AMI
                      "48099") # (Coryell County, Texas) flagged for nonzero index values but 0 households <50% AMI

problem_counties_trans <- c("48253", # (Jones County, Texas) flagged for n/a index values
                            "02185", # (North Slope Borough, Alaska) flagged for n/a index values	
                            "51081", # (Greensville County, Virginia)	flagged for n/a index values
                            "51183", # (Sussex County, Virginia) flagged for n/a index values
                            "08043", # (Fremont County, Colorado)	flagged for n/a index values
                            "30101", # (Toole County, Montana) flagged for n/a index values
                            "42119", # (Union County, Pennsylvania) flagged for nonzero index values but 0 households <50% AMI
                            "48001", # (Anderson County, Texas) 	flagged for nonzero index values but 0 households <50% AMI
                            "48099") # (Coryell County, Texas) flagged for nonzero index values but 0 households <50% AMI

#note, Madison County Ohio is not flagged for a data quality issue for transit trips index because it is 0, so having a 0 weight does not change it.
county_transport_stats <- county_transport_stats %>%
  mutate(mean_tcost_quality = if_else(condition = GEOID %in% problem_counties_tcost, true = 2, false = 1)) %>%
  mutate(mean_trans_quality = if_else(condition = GEOID %in% problem_counties_trans, true = 2, false = 1)) 

#Write out final CSV
write_csv(county_transport_stats, "output/county_transport_stats_final.csv", na = "NA", append = FALSE, col_names = TRUE)
