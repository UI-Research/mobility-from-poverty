#Transportation Index county calculations by race

library(tidyverse)
library(tidycensus)
library(purrr)

#STEP 1: read in the data we need. Because of the way it is on HUD's website,
  #it must be downloaded first and then read in as a CSV. 
  #The CSV file is saved on box and should be downloaded and this directory set
  #up and edited before the code is run.
affh_transit_data <- read_csv("data/AFFH_tract_AFFHT0006_July2020.csv", 
                           col_types = cols(
                             .default = col_double(),
                             category = col_character(),
                             stusab = col_character(),
                             state_name = col_character(),
                             county_name = col_character()
                           ))

  #Only keep the variables we need for this analysis, which are the geographic 
  #variables, the two transit indexes, and the number of households less than 50% AMI, 
  #which we will use for weighting, as well as the race variables.
  #This also filters out tracts that are in Puerto Rico because we are not 
  #including them in this work and they do not have index values.
  #and, adds leading zeroes to the GEOID in this dataset so that we will be
  #able to join it to ACS data later for data checks.

affh_transit_data <- affh_transit_data %>%
  select(GEOID = geoid, 
                 state, 
                 state_name, 
                 county, 
                 county_name, 
                 tract,
                 tcost_idx, 
                 trans_idx, 
                 num_hh = hh_lt50ami_all, 
                 hh_white_lt50ami,
                 hh_black_lt50ami, 
                 hh_hisp_lt50ami, 
                 hh_ai_pi_lt50ami) %>%
  filter(state_name != "Puerto Rico") %>%
  mutate(GEOID = str_pad(string = GEOID, width = 11, side = "left", pad = "0"))

#STEP 2: Pull in ACS population data at the tract level. 
  #This was used for two data quality checks and population information was used 
  #in creation of final file.
my_states <- fips_codes %>% 
  filter(!state %in% c("PR", "UM", "VI", "GU", "AS", "MP")) %>%
  pull(state) %>%
  unique()

acs_tract_pop <- map_dfr(
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

  #Join the AFFH transit data with the ACS population data,
  #rename total tract population to match, filter to tracts that have
  #some population, add leading zeroes to state and county, create
  #county-level GEOID to use in data checks.
full_data <- left_join(acs_tract_pop, affh_transit_data, by = "GEOID") %>%  
  rename(total_population = B01003_001E) %>%
  filter(total_population > 0) %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county)) %>%
  select(-B01003_001M)

  #Test with anti_join to make sure it worked properly.
stopifnot(
  anti_join(acs_tract_pop, affh_transit_data, by = "GEOID") %>%
    nrow() == 0
)

  #Note that 179 tracts that have population and no transit information. In order
  #to determine if this will cause a data quality problem, we figured out how
  #much of the county's population they comprised.

  #DATA CHECK #1: TRACTS WITH N/A INDEX VALUES BUT NO POPULATION: 
    #WHAT PERCENTAGE OF THEIR COUNTY DO THEY MAKE UP? 
   #Flag tract-level population for tracts in question 
   #(tracts that have population but do not have transit index values)
stopifnot(
  full_data %>%
    filter(is.na(tcost_idx) | is.na(trans_idx)) %>%
    nrow() == 179
)

datacheck1 <- full_data %>%
  mutate(na_tract_pop = if_else(is.na(tcost_idx), total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(missing_pop_county_sum = sum(na_tract_pop))

    #Get county population from ACS.
acs_county_pop <- map_dfr(
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

    #rename county pop variable to use later
acs_county_pop <- acs_county_pop %>%
  rename(total_population = B01003_001E) %>%
  select(-B01003_001M)

    #Merge datasets and calculate the percent of the county population made up 
    #by the tract with N/A transit values (proportion_na_tracts).
    #set data quality to 3 if the proportion missing is higher than 25% of the county,
    #and to 2 if higher than 10%.
datacheck1 <- left_join(acs_county_pop, datacheck1, by = "GEOID")

stopifnot(
  anti_join(acs_county_pop, datacheck1, by = "GEOID") %>%
    nrow() == 0
)

datacheck1 <- datacheck1 %>%
  mutate(proportion_na_tracts = (missing_pop_county_sum/total_population),
         datacheck1 = case_when(
                      proportion_na_tracts >= 0.25 ~ 3,
                      proportion_na_tracts >= 0.10 ~ 2,
                      TRUE ~ 1)
                      ) %>%
  select(GEOID, datacheck1)

  ###DATA CHECK #2: Tracts that have index values but no households under 50% AMI
      #One downside of using number of households at 50%AMI to population weight
      #the data is that there are 149 tracts that have 0 households <50% AMI but 
      #do have transit index values >0. 
      #These will be effectively zeroed out during the county-average process.
      #Want to take a similar approach to flagging potential data quality concerns here: 
      #if one of these tracts makes up more than 10% of county population, 
      #will flag its data quality as 2.
datacheck2 <- full_data %>%
  mutate(nohh_tract_pop = if_else(num_hh == 0, total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(nohh_tract_county_sum = sum(nohh_tract_pop))

    #Merge with ACS county data to calculate the percent of the county population 
    #made up by the tract with 0 households at 50%AMI (proportion_nohh)
    #set data quality to 3 if the proportion missing is higher than 25% of the county,
    #and to 2 if higher than 10%.
datacheck2 <- left_join(acs_county_pop, datacheck2, by = "GEOID")

stopifnot(
  anti_join(acs_county_pop, datacheck2, by = "GEOID") %>%
    nrow() == 0
)

datacheck2 <- datacheck2 %>%
  mutate(proportion_nohh = (nohh_tract_county_sum/total_population),
         datacheck2 = case_when(
                       proportion_nohh >= 0.25 ~ 3,
                       proportion_nohh >= 0.10 ~ 2,
                        TRUE ~ 1)
                       ) %>%
  select(GEOID, datacheck2)


#STEP 3: USE POPULATION WEIGHTS BY # HOUSEHOLDS <50% AMI TO CREATE COUNTY-WIDE INDICATORS.
#We generated county average index values by population weighting tract averages. 
#The way we ultimately decided to do this was using the number of households <50% AMI, 
#which more closely aligns with the definition for the index than just the overall population number.
#That number is in the AFFH dataset (num_hh) so we already have it.
#The code withholds n/as from calculation.
#Also, formats data and adds data quality checks.
county_transport_stats <- full_data %>%
  group_by(state, county) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh, na.rm = TRUE),
            mean_transit = weighted.mean(x = trans_idx, w = num_hh, na.rm = TRUE)) %>%
  ungroup() %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(GEOID = str_c(state, county, collapse = NULL))

#add data quality measures from the tests
county_transport_stats <- left_join(county_transport_stats, datacheck1, by = "GEOID")

stopifnot(
  anti_join(county_transport_stats, datacheck1, by = "GEOID") %>%
    nrow() == 0
)

county_transport_stats <- left_join(county_transport_stats, datacheck2, by = "GEOID")

stopifnot(
  anti_join(county_transport_stats, datacheck2, by = "GEOID") %>%
    nrow() == 0
)

county_transport_stats <- county_transport_stats %>% 
  mutate(
    mean_tcost_quality = case_when(
      datacheck1 == 2 | datacheck2 == 2 ~ 2,
      datacheck1 == 3 | datacheck2 == 3 ~ 3,
      TRUE ~ 1
    ),
    mean_transit_quality = mean_tcost_quality,
    subgroup = "All",
    subgroup_type = "All") %>%
  select(-datacheck1, -datacheck2, -GEOID)

rm(datacheck1, datacheck2)


#STEP 4: add the breakdown by race. First, need to create categories:
  #1. > 60% white
  #2. 40-60% white/POC
  #3. > 60% POC 

  #(We know that these percentages, as shown by perc_total, are not perfect. See data notes.)
  #For the categories, create using both for 50%ami households - 
  #define category as when one group is over .6, 
  #and others go in the middle category if at least one group has more than .4
  #if there's not enough data to make that determination, set to missing.
full_data <- full_data %>%
  mutate(perc_white = if_else(num_hh > 0, hh_white_lt50ami / num_hh, 0), 
         perc_POC = if_else(num_hh > 0, ((hh_black_lt50ami + hh_hisp_lt50ami + hh_ai_pi_lt50ami) / num_hh), 0),
         perc_total = perc_white + perc_POC) %>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "Predominantly White",
      perc_POC >= 0.6 ~ "Predominantly People of Color",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "No Predominant Racial Group",
      perc_white < 0.4 & perc_POC < 0.4 ~ as.character(NA)
    )
  )

  ###DATA CHECK #3: for tracts with race information about less than 90%
      #or more than 105% of households, what percentage of the county does the tract make up?
      #if more than 10%, flag for poor data quality. 5025 tracts fit this criteria.
datacheck3 <- full_data %>%
  mutate(datacoverageflag = if_else((perc_total < 0.9 | perc_total > 1.05), total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(datacoverageflag_pop = sum(datacoverageflag))

datacheck3 <- left_join(acs_county_pop, datacheck3, by = "GEOID") 

stopifnot(
  anti_join(acs_county_pop, datacheck3, by = "GEOID") %>%
    nrow() == 0
)

datacheck3 <- datacheck3 %>%
  mutate(proportion_datacoverageflag = (datacoverageflag_pop/total_population),
         mean_tcost_quality = case_when(
                              proportion_datacoverageflag >= 0.25 ~ 3,
                              proportion_datacoverageflag >= 0.10 ~ 2,
                              TRUE ~ 1),
         mean_transit_quality = mean_tcost_quality) %>%
  select(GEOID, mean_tcost_quality, mean_transit_quality)
  
  #1151 counties have some incomplete race data.
  #605 counties have tracts with incomplete race data making up 10% or more 
  #of the total county population. Of the 605 counties, 295 have these inaccurate
  #tracts making up 10-24% of the county population, and 310 have these inaccurate
  #tracts making up 25%+ of the county population (85 of these 310 counties have
  #poor race data quality in 100% of their tracts). They will all be flagged for
  #data quality in the final dataset.

#STEP 5: Create county indicators by race following same procedure as above,
  #and join to data quality check
county_transport_stats_by_race_interim <- full_data %>%
  group_by(state, county, race_category) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh, na.rm = TRUE),
            mean_transit = weighted.mean(x = trans_idx, w = num_hh, na.rm = TRUE)) %>%
  ungroup() %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(GEOID = str_c(state, county))

county_transport_stats_by_race_interim <- left_join(county_transport_stats_by_race_interim, datacheck3, by = "GEOID")

stopifnot(
  anti_join(county_transport_stats_by_race_interim, datacheck3, by = "GEOID") %>%
    nrow() == 0
)

rm(datacheck3)

  #expand the data to have 3 values for each county
county_expander <- expand_grid(
  count(county_transport_stats_by_race_interim, year, state, county) %>% select(-n),
  race_category = c("Predominantly White", "Predominantly People of Color", "No Predominant Racial Group")
  )

county_transport_stats_by_race <- left_join(county_expander, county_transport_stats_by_race_interim, by = c("year", "state", "county", "race_category")) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category) %>%
  select(-GEOID)

rm(county_expander)

    #Join the race breakdown dataset to the original dataset
county_transport_stats_by_race_final <- bind_rows(county_transport_stats_by_race, county_transport_stats)

    #And format to fit data standards
county_transport_stats_by_race_final <- county_transport_stats_by_race_final[, c("year", "state", "county", "subgroup_type", "subgroup", "mean_tcost", "mean_transit", "mean_tcost_quality", "mean_transit_quality")]

county_transport_stats_by_race_final <- county_transport_stats_by_race_final %>%
  arrange(year, state, county, subgroup_type, subgroup)

    #Write out final CSV for subgroup analysis
write_csv(county_transport_stats_by_race_final, "output/county_transport_stats_by_race_final.csv")

    #Write out final CSV for county transportation stats only
county_transport_stats <- county_transport_stats %>%
  select(-subgroup, -subgroup_type)

write_csv(county_transport_stats, "output/county_transport_stats.csv")
