#Note for reviewer: this file is set up similarly to the original script, but is
  #slightly pared down in terms of the different tests we ran along the way (that
  #did not result in a different quality rating.)
  #It also does not contain the different tests we ran to decide which variables
  #to use and how best to structure the calculations. Those can be found in the 
  #file labeled 'preliminary.' 
  #Depending on your preferences, I can add some or all of that back in.

library(tidyverse)
library(tidycensus)
library(purrr)

#STEP 1: read in the data we need. Because of the way it is on HUD's website,
  #it must be downloaded first and then read in as a CSV. 
  #The CSV file is saved on box and should be downloaded and this directory set
  #up and edited before the code is run.
transport_vars <- read_csv("data/AFFH_tract_AFFHT0006_July2020.csv", 
                           col_types = cols(
                             .default = col_double(),
                             category = col_character(),
                             stusab = col_character(),
                             state_name = col_character(),
                             county_name = col_character()
                           ))

  #To only keep the variables we need for this analysis, which are the geographic 
  #variables, the two indexes, and the number of households less than 50% AMI, 
  #which we will use for weighting, as well as the race variables.
  #This also filters out tracts that are in Puerto Rico because we are not 
  #including them in this work and they do not have index values.

transport_stats <- transport_vars %>%
  select(GEOID = geoid, state, state_name, county, county_name, tract,
         tcost_idx, trans_idx, num_hh = hh_lt50ami_all, hh_white_lt50ami,
         hh_black_lt50ami, hh_hisp_lt50ami, hh_ai_pi_lt50ami) %>%
  filter(state_name != "Puerto Rico")

  #The GEOID does not have leading zeroes in this dataset.
  #This adds it so we can join to ACS data later for the data checks.
transport_stats <- transport_stats %>%
  mutate(GEOID = str_pad(string = GEOID, width = 11, side = "left", pad = "0"))


#STEP 2: Pull in ACS population data at the tract level. 
  #This was used for two data quality checks and population information was used 
  #in creation of final file.
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

  #Join the AFFH transit data with the ACS population data & rename total tract population:
full_data <- left_join(population_var, transport_stats, by = "GEOID")
full_data <- full_data %>%  
  rename(total_population = B01003_001E)

  #Test with anti_join to make sure it worked properly.
stopifnot(
  anti_join(population_var, transport_stats, by = "GEOID") %>%
    nrow() == 0
)

  #Filtering to census tracts that have some population. 
tracts_with_pop <- filter(full_data, total_population > 0) 

  #Note that 179 tracts that have population and no transit information. In order
  #to determine if this will cause a data quality problem, we figured out how
  #much of the county's population they comprised: Data Check #1, below.

  #DATA CHECK #1: TRACTS WITH N/A INDEX VALUES BUT NO POPULATION: 
    #WHAT PERCENTAGE OF THEIR COUNTY DO THEY MAKE UP? 
    #First, create new county-level GEOID:
tracts_with_county_pop <- tracts_with_pop %>%
  rename(geoid = GEOID) %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county))

   #Flag tract-level population for tracts in question 
   #(tracts that have population but do not have transit index values)
population_test <- tracts_with_county_pop %>%
  mutate(na_tract_pop = ifelse(is.na(tcost_idx), total_population, 0)) %>%
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

    #rename county pop variable to use later
county_pop <- rename(county_pop, total_population = B01003_001E)

   #Merge datasets and calculate the percent of the county population made up 
    #by the tract with N/A transit values.
test_data <- left_join(county_pop, population_test, by = "GEOID")
test_data <- test_data %>%
  mutate(perc_na = ((missing_pop_county_sum/total_population)*100)) %>%
  mutate(perc_na = round(perc_na, digits = 2))

   #As a result of this, counties with more than 10% missingness were marked
   #for data quality. See lines ?????? of the code. End of data check 1.

  ###DATA CHECK #2: Tracts that have index values but no households under 50% AMI
      #One downside of this method is that there are 149 tracts that have 0 
      #households <50% AMI but do have transit index values >0. 
      #These will be effectively zeroed out during the county-average process.
test_data2 <- full_data %>%
  rename(geoid = GEOID) %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL))

    #Want to take a similar approach to flagging potential data quality concerns here: 
    #if one of these tracts makes up more than 10% of county population, 
    #will flag its data quality as 2.
population_test2 <- test_data2 %>%
  mutate(nohh_tract_pop = ifelse(num_hh == 0, total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(nohh_tract_county_sum = sum(nohh_tract_pop))

    #Merge with ACS county data to calculate the percent of the county population 
    #made up by the tract with N/A transit values.
test_data2 <- left_join(county_pop, population_test2, by = "GEOID")
test_data2 <- test_data2 %>%
  mutate(perc_nohh = ((nohh_tract_county_sum/total_population)*100)) %>%
  mutate(perc_nohh = round(perc_nohh, digits = 2))

    #As a result of this, counties with more than 10% missingness were marked
    #for data quality. See lines ?????? of the code. End of data check 2. 


#STEP 3: to add the breakdown by race. First, need to create categories:
  #1. > 60% white
  #2. 40-60% white/POC
  #3. > 60% POC 
tracts_with_pop <- tracts_with_pop%>%
  mutate(perc_white = (hh_white_lt50ami/num_hh), 
         perc_POC = ((hh_black_lt50ami + hh_hisp_lt50ami + hh_ai_pi_lt50ami)/num_hh)) %>%
  mutate(perc_total = perc_white + perc_POC) %>%
 
  #We know that these percentages, as shown by perc_total, are not perfect.
  #see data notes.

  #Create using both for 50%ami households - 
  #define category as when one group is over .6, 
  #and others go in the middle category if at least one group has more than .4
tracts_with_pop  <- tracts_with_pop %>%       
  mutate(race_category1 = if_else((perc_POC < .6 & (perc_POC > .4 | perc_POC == .4)) | (perc_white < .6 & (perc_white > .4 | perc_white == .4)), 2, 0)) %>%
  mutate(race_category1 = if_else((perc_white > .6 | perc_white == .6), 1, race_category1)) %>%
  mutate(race_category1 = if_else((perc_POC > .6 | perc_POC == .6), 3, race_category1)) 
      
#data quality calculation: what percentage of the category of the county does it make up? 10-24 or 25+
#thresholds to use:race information for at least 90% of 50%amiHH and over 105%

  ###DATA CHECK #3: Flagging tracts where we have race data on <90% or >105% 50%AMI HHs,
    #if that tract makes up more than 10% of its county.
test_data_race_categories <- tracts_with_county_pop %>%
  mutate(perc_white = (hh_white_lt50ami/num_hh), 
         perc_POC = ((hh_black_lt50ami + hh_hisp_lt50ami + hh_ai_pi_lt50ami)/num_hh)) %>%
  mutate(perc_total = perc_white + perc_POC)
population_test3 <- test_data_race_categories %>%
  mutate(coverage_flag = ifelse((perc_total < .9 | perc_total > 1.05), total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(coverage_flag_pop = sum(coverage_flag))
  #Note for reviewer: I think the summarise isn't working properly, as it is marking 189 counties as N/A.
  #at least some of these (e.g. LA County) do have tracts that should be flagged - also not sure
  #what part of the calculation would create a n/a?
  #Not sure what to do about that or what implications that might have for
  #the final data quality results. 
test_data3 <- left_join(county_pop, population_test3, by = "GEOID")
test_data3 <- test_data3 %>%
  mutate(perc_coverage_flag = ((coverage_flag_pop/total_population)*100)) %>%
  mutate(perc_coverage_flag = round(perc_coverage_flag, digits = 2))

  #As noted above, these results might be inaccurate. But they appear to indicate
  #that 545 counties have tracts with incomplete race data making up 10% or more 
  #of the total county population. Of the 545 counties, 253 have these inaccurate
  #tracts making up 10-24% of the county population, and 292 have these inaccurate
  #tracts making up 25%+ of the county population. Note that 82 counties have poor
  #race data quality in 100% of their tracts.


#STEP 4: USE POPULATION WEIGHTS BY # HOUSEHOLDS <50% AMI TO CREATE COUNTY-WIDE INDICATORS BY RACE.
  #We generated county average index values by population weighting tract averages. 
  #The way we ultimately decided to do this was using the number of households <50% AMI, 
  #which more closely aligns with the definition for the index than just the overall population number.
  #That number is in the AFFH dataset (the num_hh variable defined in line 20) so we already have it.
  #The code withholds n/as from calculation.
county_transport_stats_by_race <- tracts_with_pop %>%
  group_by(state, county, race_category2) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh, na.rm = TRUE),
            mean_trans = weighted.mean(x = trans_idx, w = num_hh, na.rm = TRUE)) %>%
  ungroup()


#STEP 5: Format the data and add in data quality measures.
county_transport_stats_by_race <- county_transport_stats_by_race %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0")) %>%
  mutate(county = str_pad(string = county, width = 3, side = "left", pad = "0")) %>%
  mutate(GEOID = str_c(state, county, collapse = NULL)) %>%
  mutate(mean_tcost = round(mean_tcost, digits = 2)) %>%
  mutate(mean_trans = round(mean_trans, digits = 2)) %>%
  rename(geoid = GEOID)

  #For data quality: counties will generally be given a 1,
    #except for the counties flagged by the two data quality exercises.
    #Counties with 10-24% missingness will get a 2
problem_counties_tcost2 <- c("08043", # (Fremont County, Colorado)	flagged for n/a index values
                             "30101", # (Toole County, Montana) flagged for n/a index values
                             "42119", # (Union County, Pennsylvania) flagged for nonzero index values but 0 households <50% AMI
                             "48001", # (Anderson County, Texas) 	flagged for nonzero index values but 0 households <50% AMI
                             "39097", # (Madison County, Ohio) flagged for nonzero index values but 0 households <50% AMI
                             "48099") # (Coryell County, Texas) flagged for nonzero index values but 0 households <50% AMI

problem_counties_trans2 <- c("08043", # (Fremont County, Colorado)	flagged for n/a index values
                             "30101", # (Toole County, Montana) flagged for n/a index values
                             "42119", # (Union County, Pennsylvania) flagged for nonzero index values but 0 households <50% AMI
                             "48001", # (Anderson County, Texas) 	flagged for nonzero index values but 0 households <50% AMI
                             "48099") # (Coryell County, Texas) flagged for nonzero index values but 0 households <50% AMI

    #note, Madison County Ohio is not flagged for a data quality issue for 
      #transit trips index because it is 0, so having a 0 weight does not change it.
    #Counties with more than 24% missingness will get a 3 for data quality
problem_counties_tcost3 <- c("48253", # (Jones County, Texas) flagged for n/a index values
                             "02185", # (North Slope Borough, Alaska) flagged for n/a index values	
                             "51081", # (Greensville County, Virginia)	flagged for n/a index values
                             "51183") # (Sussex County, Virginia) flagged for n/a index values

problem_counties_trans3 <- c("48253", # (Jones County, Texas) flagged for n/a index values
                             "02185", # (North Slope Borough, Alaska) flagged for n/a index values	
                             "51081", # (Greensville County, Virginia)	flagged for n/a index values
                             "51183") # (Sussex County, Virginia) flagged for n/a index values

#NOTE: AFTER SETTLING ON RACE DATA QUALITY MEASURES, WILL NEED TO NOTE THEM HERE.

county_transport_stats_by_race <- county_transport_stats_by_race %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_tcost2, true = 2, false = 1)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_trans2, true = 2, false = 1)) %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_tcost3, true = 3, false = mean_tcost_quality)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_trans3, true = 3, false = mean_trans_quality))

county_transport_stats_by_race <- county_transport_stats_by_race %>%
  select(-geoid)

#Write out final CSV
write_csv(county_transport_stats_by_race, "output/county_transport_stats_by_race.csv")
