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
  mutate(na_tract_pop = if_else(is.na(tcost_idx), total_population, 0)) %>%
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
   #for data quality. See line 231 of the code. End of data check 1.

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
  mutate(nohh_tract_pop = if_else(num_hh == 0, total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(nohh_tract_county_sum = sum(nohh_tract_pop))

    #Merge with ACS county data to calculate the percent of the county population 
    #made up by the tract with N/A transit values.
test_data2 <- left_join(county_pop, population_test2, by = "GEOID")
test_data2 <- test_data2 %>%
  mutate(perc_nohh = ((nohh_tract_county_sum/total_population)*100)) %>%
  mutate(perc_nohh = round(perc_nohh, digits = 2))

    #As a result of this, counties with more than 10% missingness were marked
    #for data quality. See line 231 of the code. End of data check 2. 


#STEP 3: to add the breakdown by race. First, need to create categories:
  #1. > 60% white
  #2. 40-60% white/POC
  #3. > 60% POC 
tracts_with_pop <- tracts_with_pop %>%
  mutate(perc_white = if_else(num_hh > 0, hh_white_lt50ami / num_hh, 0), 
         perc_POC = if_else(num_hh > 0, ((hh_black_lt50ami + hh_hisp_lt50ami + hh_ai_pi_lt50ami) / num_hh), 0),
         perc_total = perc_white + perc_POC)

#map_dbl(tracts_with_pop, ~sum(is.na(.x))) 
  #We know that these percentages, as shown by perc_total, are not perfect.
  #see data notes.

  #Create using both for 50%ami households - 
  #define category as when one group is over .6, 
  #and others go in the middle category if at least one group has more than .4
  #if there's not enough data to make that determination, set to missing.
tracts_with_pop <- tracts_with_pop%>%
  mutate(
    race_category = case_when(
      is.na(perc_white) | is.na(perc_POC) ~ as.character(NA), 
      perc_white >= 0.6 ~ "majority_white",
      perc_POC >= 0.6 ~ "majority_poc",
      perc_white >= 0.4 | perc_POC >= 0.4 ~ "no_majority",
      perc_white & perc_POC <.4 ~ as.character(NA)
    )
  )

  ###DATA CHECK #3: for tracts with race information about less than 90%
      #or more than 105% of households, what percentage of the county does the tract make up?
      #if more than 10%, flag for poor data quality. 5522 tracts fit this criteria.
test_data_race_categories <- tracts_with_county_pop %>%
  mutate(perc_white = if_else(num_hh > 0, hh_white_lt50ami / num_hh, 0), 
         perc_POC = if_else(num_hh > 0, ((hh_black_lt50ami + hh_hisp_lt50ami + hh_ai_pi_lt50ami) / num_hh), 0),
         perc_total = perc_white + perc_POC,
         perc_total = round(perc_total, digits = 2)) 
population_test3 <- test_data_race_categories %>%
  mutate(coverage_flag = if_else((perc_total < .9 | perc_total > 1.05), total_population, 0)) %>%
  group_by(GEOID) %>%
  summarise(coverage_flag_pop = sum(coverage_flag))
test_data3 <- left_join(county_pop, population_test3, by = "GEOID")
test_data3 <- test_data3 %>%
  mutate(perc_coverage_flag = ((coverage_flag_pop/total_population)*100),
         perc_coverage_flag = round(perc_coverage_flag, digits = 2))
  #583 counties have tracts with incomplete race data making up 10% or more 
  #of the total county population. Of the 583 counties, 267 have these inaccurate
  #tracts making up 10-24% of the county population, and 316 have these inaccurate
  #tracts making up 24%+ of the county population (85 of these 306 counties have
  #poor race data quality in 100% of their tracts). They will all be flagged for
  #data quality in the final dataset.


#STEP 4: USE POPULATION WEIGHTS BY # HOUSEHOLDS <50% AMI TO CREATE COUNTY-WIDE INDICATORS.
  #We generated county average index values by population weighting tract averages. 
  #The way we ultimately decided to do this was using the number of households <50% AMI, 
  #which more closely aligns with the definition for the index than just the overall population number.
  #That number is in the AFFH dataset (num_hh) so we already have it.
  #The code withholds n/as from calculation.
county_transport_stats <- tracts_with_pop %>%
  group_by(state, county) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh, na.rm = TRUE),
            mean_trans = weighted.mean(x = trans_idx, w = num_hh, na.rm = TRUE)) %>%
  ungroup()

  #Format the data and add in data quality measures.
county_transport_stats <- county_transport_stats %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0"),
         county = str_pad(string = county, width = 3, side = "left", pad = "0"),
         GEOID = str_c(state, county, collapse = NULL),
         mean_tcost = round(mean_tcost, digits = 2),
         mean_trans = round(mean_trans, digits = 2)) %>%
  rename(geoid = GEOID)

  #For transit indices data quality: counties will generally be given a 1,
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

county_transport_stats <- county_transport_stats %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_tcost2, true = 2, false = 1)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_trans2, true = 2, false = 1)) %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_tcost3, true = 3, false = mean_tcost_quality)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_trans3, true = 3, false = mean_trans_quality)) %>%
  select(-geoid) %>%
  mutate(subgroup = "all") %>%
  mutate(subgroup_type = "all")

#STEP 5: CREATE COUNTY INDICATORS BY RACE. Follows same procedure as above.
county_transport_stats_by_race_interim <- tracts_with_pop %>%
  group_by(state, county, race_category) %>%
  summarize(mean_tcost = weighted.mean(x = tcost_idx, w = num_hh, na.rm = TRUE),
            mean_trans = weighted.mean(x = trans_idx, w = num_hh, na.rm = TRUE)) %>%
  ungroup()

  #Format the data and add in race-specific data quality measures.
county_transport_stats_by_race_interim <- county_transport_stats_by_race_interim %>%
  add_column(year = 2016, .before = "state") %>%
  mutate(state = str_pad(string = state, width = 2, side ="left", pad = "0"),
         county = str_pad(string = county, width = 3, side = "left", pad = "0"),
         GEOID = str_c(state, county, collapse = NULL),
         mean_tcost = round(mean_tcost, digits = 2),
         mean_trans = round(mean_trans, digits = 2)) %>%
  rename(geoid = GEOID)

  #expand the data to have 3 values for each county
county_expander <- expand_grid(
  count(county_transport_stats_by_race_interim, year, state, county) %>% select(-n),
  race_category = c("majority_white", "majority_poc", "no_majority")

  )

county_transport_stats_by_race <- left_join(county_expander, county_transport_stats_by_race_interim, by = c("year", "state", "county", "race_category"))

    #For reviewer: Please note that I know there MUST be a better way of doing this but 
    #I wanted to finish on time and didn't have the ability to figure it out! I copied
    #and pasted the fips codes here from the earlier data quality exercise. but I'm sure
    #you could flag it in that dataset and then maybe append it to this one? although
    #in that exercise the file was 3142 long instead of this one broken out by counties...
    #anyway, apologies for this:
problem_counties_race_data2 <- c("20121", #	Miami County, Kansas
                             "29001", #	Adair County, Missouri
                             "32033", #	White Pine County, Nevada
                             "53009", #	Clallam County, Washington
                             "49041",	# Sevier County, Utah
                             "06103",	# Tehama County, California
                             "39115", # Morgan County, Ohio
                             "05081",	# Little River County, Arkansas
                             "13053", #	Chattahoochee County, Georgia
                             "37139", #	Pasquotank County, North Carolina
                             "35001", #	Bernalillo County, New Mexico
                             "12123", #	Taylor County, Florida
                             "41035", #	Klamath County, Oregon
                             "19129", #	Mills County, Iowa
                             "37113", #	Macon County, North Carolina
                             "08071", #	Las Animas County, Colorado
                             "38017", #	Cass County, North Dakota
                             "19117", #	Lucas County, Iowa
                             "01111", #	Randolph County, Alabama
                             "53019", #	Ferry County, Washington
                             "36041", #	Hamilton County, New York
                             "35053", #	Socorro County, New Mexico
                             "08081", #	Moffat County, Colorado
                             "26073", #	Isabella County, Michigan
                             "01079", #	Lawrence County, Alabama
                             "04007", #	Gila County, Arizona
                             "06101", #	Sutter County, California
                             "01133", #	Winston County, Alabama
                             "39127", #	Perry County, Ohio
                             "20169", #	Saline County, Kansas
                             "20095", #	Kingman County, Kansas
                             "40017", #	Canadian County, Oklahoma
                             "17051", #	Fayette County, Illinois
                             "30111", #	Yellowstone County, Montana
                             "06095", #	Solano County, California
                             "32007", #	Elko County, Nevada
                             "55009", #	Brown County, Wisconsin
                             "29131", #	Miller County, Missouri
                             "53053", #	Pierce County, Washington
                             "38035", #	Grand Forks County, North Dakota
                             "18179", #	Wells County, Indiana
                             "53035", #	Kitsap County, Washington
                             "45027", #	Clarendon County, South Carolina
                             "06043", #	Mariposa County, California
                             "38101", #	Ward County, North Dakota
                             "47115", #	Marion County, Tennessee
                             "37039", #	Cherokee County, North Carolina
                             "31177", #	Washington County, Nebraska
                             "53051", #	Pend Oreille County, Washington
                             "48425", #	Somervell County, Texas
                             "46013", #	Brown County, South Dakota
                             "45035", #	Dorchester County, South Carolina
                             "51199", #	York County, Virginia
                             "46099", #	Minnehaha County, South Dakota
                             "22109", #	Terrebonne Parish, Louisiana
                             "56009", #	Converse County, Wyoming
                             "55053", #	Jackson County, Wisconsin
                             "20045", #	Douglas County, Kansas
                             "27001", #	Aitkin County, Minnesota
                             "37133", #	Onslow County, North Carolina
                             "42119", #	Union County, Pennsylvania
                             "49045", #	Tooele County, Utah
                             "46079", #	Lake County, South Dakota
                             "21047", #	Christian County, Kentucky
                             "22057", #	Lafourche Parish, Louisiana
                             "47143", #	Rhea County, Tennessee
                             "48325", #	Medina County, Texas
                             "29161", #	Phelps County, Missouri
                             "06109", #	Tuolumne County, California
                             "08043", #	Fremont County, Colorado
                             "20011", #	Bourbon County, Kansas
                             "05035", #	Crittenden County, Arkansas
                             "37137", #	Pamlico County, North Carolina
                             "27023", #	Chippewa County, Minnesota
                             "55007", #	Bayfield County, Wisconsin
                             "54039", #	Kanawha County, West Virginia
                             "05059", #	Hot Spring County, Arkansas
                             "30093", #	Silver Bow County, Montana
                             "53017", #	Douglas County, Washington
                             "56037", #	Sweetwater County, Wyoming
                             "36093", #	Schenectady County, New York
                             "53057", #	Skagit County, Washington
                             "29009", #	Barry County, Missouri
                             "51107", #	Loudoun County, Virginia
                             "37083", #	Halifax County, North Carolina
                             "53031", #	Jefferson County, Washington
                             "53065", #	Stevens County, Washington
                             "48395", #	Robertson County, Texas
                             "39097", #	Madison County, Ohio
                             "39141", #	Ross County, Ohio
                             "53073", #	Whatcom County, Washington
                             "02016", #	Aleutians West Census Area, Alaska
                             "26065", #	Ingham County, Michigan
                             "12013", #	Calhoun County, Florida
                             "17101", #	Lawrence County, Illinois
                             "50025", #	Windham County, Vermont
                             "47123", #	Monroe County, Tennessee
                             "13273", #	Terrell County, Georgia
                             "15007", #	Kauai County, Hawaii
                             "26031", #	Cheboygan County, Michigan
                             "41041", #	Lincoln County, Oregon
                             "32019", #	Lyon County, Nevada
                             "51119", #	Middlesex County, Virginia
                             "53003", #	Asotin County, Washington
                             "41031", #	Jefferson County, Oregon
                             "06089", #	Shasta County, California
                             "26109", #	Menominee County, Michigan
                             "21127", #	Lawrence County, Kentucky
                             "05027", #	Columbia County, Arkansas
                             "53049", #	Pacific County, Washington
                             "20103", #	Leavenworth County, Kansas
                             "48335", #	Mitchell County, Texas
                             "13091", #	Dodge County, Georgia
                             "47125", #	Montgomery County, Tennessee
                             "45069", #	Marlboro County, South Carolina
                             "01131", #	Wilcox County, Alabama
                             "13039", #	Camden County, Georgia
                             "22075", #	Plaquemines Parish, Louisiana
                             "53029", #	Island County, Washington
                             "48035", #	Bosque County, Texas
                             "41029", #	Jackson County, Oregon
                             "22009", #	Avoyelles Parish, Louisiana
                             "30089", #	Sanders County, Montana
                             "21005", #	Anderson County, Kentucky
                             "12093", #	Okeechobee County, Florida
                             "48069", #	Castro County, Texas
                             "39101", #	Marion County, Ohio
                             "55125", #	Vilas County, Wisconsin
                             "05015", #	Carroll County, Arkansas
                             "26053", #	Gogebic County, Michigan
                             "05037", #	Cross County, Arkansas
                             "36033", #	Franklin County, New York
                             "51101", #	King William County, Virginia
                             "21175", #	Morgan County, Kentucky
                             "48357", #	Ochiltree County, Texas
                             "49021", #	Iron County, Utah
                             "18059", #	Hancock County, Indiana
                             "22045", #	Iberia Parish, Louisiana
                             "48093", #	Comanche County, Texas
                             "44009", #	Washington County, Rhode Island
                             "53037", #	Kittitas County, Washington
                             "38053", #	McKenzie County, North Dakota
                             "13317", #	Wilkes County, Georgia
                             "32510", #	Carson City, Nevada
                             "23029", #	Washington County, Maine
                             "48371", #	Pecos County, Texas
                             "48401", #	Rusk County, Texas
                             "29007", #	Audrain County, Missouri
                             "47087", #	Jackson County, Tennessee
                             "44005", #	Newport County, Rhode Island
                             "12049", #	Hardee County, Florida
                             "13103", #	Effingham County, Georgia
                             "55031", #	Douglas County, Wisconsin
                             "01103", #	Morgan County, Alabama
                             "48337", #	Montague County, Texas
                             "06063", #	Plumas County, California
                             "46135", #	Yankton County, South Dakota
                             "53033", #	King County, Washington
                             "30029", #	Flathead County, Montana
                             "51059", #	Fairfax County, Virginia
                             "35061", #	Valencia County, New Mexico
                             "53015", #	Cowlitz County, Washington
                             "22113", #	Vermilion Parish, Louisiana
                             "06013", #	Contra Costa County, California
                             "01053", #	Escambia County, Alabama
                             "53077", #	Yakima County, Washington
                             "05149", #	Yell County, Arkansas
                             "53027", #	Grays Harbor County, Washington
                             "20133", #	Neosho County, Kansas
                             "01043", #	Cullman County, Alabama
                             "31019", #	Buffalo County, Nebraska
                             "37051", #	Cumberland County, North Carolina
                             "37185", #	Warren County, North Carolina
                             "04021", #	Pinal County, Arizona
                             "29169", #	Pulaski County, Missouri
                             "51700", #	Newport News city, Virginia
                             "31119", #	Madison County, Nebraska
                             "17021", #	Christian County, Illinois
                             "48485", #	Wichita County, Texas
                             "06067", #	Sacramento County, California
                             "01055", #	Etowah County, Alabama
                             "29073", #	Gasconade County, Missouri
                             "13113", #	Fayette County, Georgia
                             "47053", #	Gibson County, Tennessee
                             "41019", #	Douglas County, Oregon
                             "26067", #	Ionia County, Michigan
                             "40081", #	Lincoln County, Oklahoma
                             "48001", #	Anderson County, Texas
                             "26077", #	Kalamazoo County, Michigan
                             "12051", #	Hendry County, Florida
                             "45043", #	Georgetown County, South Carolina
                             "41043", #	Linn County, Oregon
                             "26103", #	Marquette County, Michigan
                             "30049", #	Lewis and Clark County, Montana
                             "01071", #	Jackson County, Alabama
                             "28001", #	Adams County, Mississippi
                             "22069", #	Natchitoches Parish, Louisiana
                             "31153", #	Sarpy County, Nebraska
                             "39001", #	Adams County, Ohio
                             "04015", #	Mohave County, Arizona
                             "26143", #	Roscommon County, Michigan
                             "34011", #	Cumberland County, New Jersey
                             "06115", #	Yuba County, California
                             "22103", #	St. Tammany Parish, Louisiana
                             "45025", #	Chesterfield County, South Carolina
                             "53067", #	Thurston County, Washington
                             "37195", #	Wilson County, North Carolina
                             "21089", #	Greenup County, Kentucky
                             "36019", #	Clinton County, New York
                             "32023", #	Nye County, Nevada
                             "36031", #	Essex County, New York
                             "24009", #	Calvert County, Maryland
                             "36105", #	Sullivan County, New York
                             "41005", #	Clackamas County, Oregon
                             "48279", #	Lamb County, Texas
                             "18063", #	Hendricks County, Indiana
                             "16017", #	Bonner County, Idaho
                             "23009", #	Hancock County, Maine
                             "21219", #	Todd County, Kentucky
                             "51683", #	Manassas city, Virginia
                             "27005", #	Becker County, Minnesota
                             "51510", #	Alexandria city, Virginia
                             "41039", #	Lane County, Oregon
                             "32003", #	Clark County, Nevada
                             "06007", #	Butte County, California
                             "54037", #	Jefferson County, West Virginia
                             "36081", #	Queens County, New York
                             "18137", #	Ripley County, Indiana
                             "20099", #	Labette County, Kansas
                             "08005", #	Arapahoe County, Colorado
                             "39119", #	Muskingum County, Ohio
                             "24027", #	Howard County, Maryland
                             "51153", #	Prince William County, Virginia
                             "48469", #	Victoria County, Texas
                             "34001", #	Atlantic County, New Jersey
                             "55045", #	Green County, Wisconsin
                             "53071", #	Walla Walla County, Washington
                             "36099", #	Seneca County, New York
                             "41033", #	Josephine County, Oregon
                             "21073", #	Franklin County, Kentucky
                             "26027", #	Cass County, Michigan
                             "37061", #	Duplin County, North Carolina
                             "18005", #	Bartholomew County, Indiana
                             "04027", #	Yuma County, Arizona
                             "48491", #	Williamson County, Texas
                             "06077", #	San Joaquin County, California
                             "08099", #	Prowers County, Colorado
                             "13153", #	Houston County, Georgia
                             "35035", #	Otero County, New Mexico
                             "39057", #	Greene County, Ohio
                             "50023", #	Washington County, Vermont
                             "01045", #	Dale County, Alabama
                             "19193", #	Woodbury County, Iowa
                             "41059", #	Umatilla County, Oregon
                             "12113", #	Santa Rosa County, Florida
                             "48181", #	Grayson County, Texas
                             "32001", #	Churchill County, Nevada
                             "06035", #	Lassen County, California
                             "39005", #	Ashland County, Ohio
                             "31055", #	Douglas County, Nebraska
                             "21065", #	Estill County, Kentucky
                             "55111", #	Sauk County, Wisconsin
                             "53041", #	Lewis County, Washington
                             "53061", #	Snohomish County, Washington
                             "25005", #	Bristol County, Massachusetts
                             "47051", #	Franklin County, Tennessee
                             "48373") #	Polk County, Texas
                             
    #Counties with more than 24% missingness will get a 3 for data quality
problem_counties_race_data3 <- c("02013", #	Aleutians East Borough, Alaska
                             "02050", #	Bethel Census Area, Alaska
                             "02060", #	Bristol Bay Borough, Alaska
                             "02070", #	Dillingham Census Area, Alaska
                             "02100", #	Haines Borough, Alaska
                             "02105", #	Hoonah-Angoon Census Area, Alaska
                             "02130", #	Ketchikan Gateway Borough, Alaska
                             "02158", #	Kusilvak Census Area, Alaska
                             "02164", #	Lake and Peninsula Borough, Alaska
                             "02180", #	Nome Census Area, Alaska
                             "02185", #	North Slope Borough, Alaska
                             "02188", #	Northwest Arctic Borough, Alaska
                             "02195", #	Petersburg Borough, Alaska
                             "02198", #	Prince of Wales-Hyder Census Area, Alaska
                             "02220", #	Sitka City and Borough, Alaska
                             "02230", #	Skagway Municipality, Alaska
                             "02275", #	Wrangell City and Borough, Alaska
                             "02282", #	Yakutat City and Borough, Alaska
                             "02290", #	Yukon-Koyukuk Census Area, Alaska
                             "06003", #	Alpine County, California
                             "08053", #	Hinsdale County, Colorado
                             "15005", #	Kalawao County, Hawaii
                             "20019", #	Chautauqua County, Kansas
                             "26095", #	Luce County, Michigan
                             "27087", #	Mahnomen County, Minnesota
                             "30003", #	Big Horn County, Montana
                             "30035", #	Glacier County, Montana
                             "30079", #	Prairie County, Montana
                             "31113", #	Logan County, Nebraska
                             "31173", #	Thurston County, Nebraska
                             "32009", #	Esmeralda County, Nevada
                             "32021", #	Mineral County, Nevada
                             "35021", #	Harding County, New Mexico
                             "35031", #	McKinley County, New Mexico
                             "38025", #	Dunn County, North Dakota
                             "38079", #	Rolette County, North Dakota
                             "38085", #	Sioux County, North Dakota
                             "38095", #	Towner County, North Dakota
                             "40001", #	Adair County, Oklahoma
                             "40005", #	Atoka County, Oklahoma
                             "40013", #	Bryan County, Oklahoma
                             "40021", #	Cherokee County, Oklahoma
                             "40029", #	Coal County, Oklahoma
                             "40033", #	Cotton County, Oklahoma
                             "40035", #	Craig County, Oklahoma
                             "40041", #	Delaware County, Oklahoma
                             "40061", #	Haskell County, Oklahoma
                             "40069", #	Johnston County, Oklahoma
                             "40075", #	Kiowa County, Oklahoma
                             "40077", #	Latimer County, Oklahoma
                             "40091", #	McIntosh County, Oklahoma
                             "40097", #	Mayes County, Oklahoma
                             "40105", #	Nowata County, Oklahoma
                             "40107", #	Okfuskee County, Oklahoma
                             "40111", #	Okmulgee County, Oklahoma
                             "40115", #	Ottawa County, Oklahoma
                             "40121", #	Pittsburg County, Oklahoma
                             "40127", #	Pushmataha County, Oklahoma
                             "40133", #	Seminole County, Oklahoma
                             "40135", #	Sequoyah County, Oklahoma
                             "41025", #	Harney County, Oregon
                             "46007", #	Bennett County, South Dakota
                             "46017", #	Buffalo County, South Dakota
                             "46031", #	Corson County, South Dakota
                             "46041", #	Dewey County, South Dakota
                             "46065", #	Hughes County, South Dakota
                             "46071", #	Jackson County, South Dakota
                             "46073", #	Jerauld County, South Dakota
                             "46091", #	Marshall County, South Dakota
                             "46095", #	Mellette County, South Dakota
                             "46102", #	Oglala Lakota County, South Dakota
                             "46121", #	Todd County, South Dakota
                             "46123", #	Tripp County, South Dakota
                             "46137", #	Ziebach County, South Dakota
                             "47061", #	Grundy County, Tennessee
                             "47153", #	Sequatchie County, Tennessee
                             "48023", #	Baylor County, Texas
                             "48045", #	Briscoe County, Texas
                             "48235", #	Irion County, Texas
                             "48263", #	Kent County, Texas
                             "48269", #	King County, Texas
                             "48311", #	McMullen County, Texas
                             "48393", #	Roberts County, Texas
                             "48447", #	Throckmorton County, Texas
                             "55078", #	Menominee County, Wisconsin
                             "37155", #	Robeson County, North Carolina
                             "40125", #	Pottawatomie County, Oklahoma
                             "40123", #	Pontotoc County, Oklahoma
                             "02150", #	Kodiak Island Borough, Alaska
                             "40101", #	Muskogee County, Oklahoma
                             "30047", #	Lake County, Montana
                             "04001", #	Apache County, Arizona
                             "40113", #	Osage County, Oklahoma
                             "30085", #	Roosevelt County, Montana
                             "40117", #	Pawnee County, Oklahoma
                             "40023", #	Choctaw County, Oklahoma
                             "40145", #	Wagoner County, Oklahoma
                             "26033", #	Chippewa County, Michigan
                             "40099", #	Murray County, Oklahoma
                             "40037", #	Creek County, Oklahoma
                             "46109", #	Roberts County, South Dakota
                             "40131", #	Rogers County, Oklahoma
                             "30105", #	Valley County, Montana
                             "30101", #	Toole County, Montana
                             "35045", #	San Juan County, New Mexico
                             "02090", #	Fairbanks North Star Borough, Alaska
                             "26097", #	Mackinac County, Michigan
                             "38071", #	Ramsey County, North Dakota
                             "49013", #	Duchesne County, Utah
                             "35006", #	Cibola County, New Mexico
                             "49037", #	San Juan County, Utah
                             "40089", #	McCurtain County, Oklahoma
                             "02122", #	Kenai Peninsula Borough, Alaska
                             "40079", #	Le Flore County, Oklahoma
                             "46023", #	Charles Mix County, South Dakota
                             "30091", #	Sheridan County, Montana
                             "15001", #	Hawaii County, Hawaii
                             "40095", #	Marshall County, Oklahoma
                             "20085", #	Jackson County, Kansas
                             "04005", #	Coconino County, Arizona
                             "38005", #	Benson County, North Dakota
                             "40015", #	Caddo County, Oklahoma
                             "40043", #	Dewey County, Oklahoma
                             "20013", #	Brown County, Kansas
                             "27031", #	Cook County, Minnesota
                             "15009", #	Maui County, Hawaii
                             "31045", #	Dawes County, Nebraska
                             "30015", #	Chouteau County, Montana
                             "02110", #	Juneau City and Borough, Alaska
                             "13309", #	Wheeler County, Georgia
                             "46129", #	Walworth County, South Dakota
                             "40063", #	Hughes County, Oklahoma
                             "06105", #	Trinity County, California
                             "46103", #	Pennington County, South Dakota
                             "30005", #	Blaine County, Montana
                             "29149", #	Oregon County, Missouri
                             "20159", #	Rice County, Kansas
                             "56013", #	Fremont County, Wyoming
                             "40049", #	Garvin County, Oklahoma
                             "40051", #	Grady County, Oklahoma
                             "46047", #	Fall River County, South Dakota
                             "06027", #	Inyo County, California
                             "30087", #	Rosebud County, Montana
                             "17107", #	Logan County, Illinois
                             "04017", #	Navajo County, Arizona
                             "55041", #	Forest County, Wisconsin
                             "37173", #	Swain County, North Carolina
                             "40143", #	Tulsa County, Oklahoma
                             "40067", #	Jefferson County, Oklahoma
                             "31147", #	Richardson County, Nebraska
                             "55113", #	Sawyer County, Wisconsin
                             "15003", #	Honolulu County, Hawaii
                             "46015", #	Brule County, South Dakota
                             "48031", #	Blanco County, Texas
                             "38055", #	McLean County, North Dakota
                             "02020", #	Anchorage Municipality, Alaska
                             "02261", #	Valdez-Cordova Census Area, Alaska
                             "40039", #	Custer County, Oklahoma
                             "13037", #	Calhoun County, Georgia
                             "40147", #	Washington County, Oklahoma
                             "16061", #	Lewis County, Idaho
                             "40119", #	Payne County, Oklahoma
                             "06009", #	Calaveras County, California
                             "27007", #	Beltrami County, Minnesota
                             "40103", #	Noble County, Oklahoma
                             "31185", #	York County, Nebraska
                             "40071", #	Kay County, Oklahoma
                             "46053", #	Gregory County, South Dakota
                             "16009", #	Benewah County, Idaho
                             "05105", #	Perry County, Arkansas
                             "40031", #	Comanche County, Oklahoma
                             "55003", #	Ashland County, Wisconsin
                             "48389", #	Reeves County, Texas
                             "31043", #	Dakota County, Nebraska
                             "25007", #	Dukes County, Massachusetts
                             "38061", #	Mountrail County, North Dakota
                             "46101", #	Moody County, South Dakota
                             "40083", #	Logan County, Oklahoma
                             "48175", #	Goliad County, Texas
                             "40059", #	Harper County, Oklahoma
                             "05129", #	Searcy County, Arkansas
                             "06049", #	Modoc County, California
                             "37165", #	Scotland County, North Carolina
                             "48151", #	Fisher County, Texas
                             "28069", #	Kemper County, Mississippi
                             "40137", #	Stephens County, Oklahoma
                             "29035", #	Carter County, Missouri
                             "40019", #	Carter County, Oklahoma
                             "06015", #	Del Norte County, California
                             "08083", #	Montezuma County, Colorado
                             "04012", #	La Paz County, Arizona
                             "38105", #	Williams County, North Dakota
                             "38015", #	Burleigh County, North Dakota
                             "38067", #	Pembina County, North Dakota
                             "41057", # Tillamook County, Oregon
                             "16029", #	Caribou County, Idaho
                             "21165", #	Menifee County, Kentucky
                             "27095", #	Mille Lacs County, Minnesota
                             "37075", #	Graham County, North Carolina
                             "48099", #	Coryell County, Texas
                             "20151", #	Pratt County, Kansas
                             "46085", #	Lyman County, South Dakota
                             "06023", #	Humboldt County, California
                             "55013", #	Burnett County, Wisconsin
                             "16039", #	Elmore County, Idaho
                             "31161", #	Sheridan County, Nebraska
                             "35039", #	Rio Arriba County, New Mexico
                             "40073", #	Kingfisher County, Oklahoma
                             "27155", #	Traverse County, Minnesota
                             "30001", #	Beaverhead County, Montana
                             "08067", #	La Plata County, Colorado
                             "31013", #	Box Butte County, Nebraska
                             "30041", #	Hill County, Montana
                             "31107", #	Knox County, Nebraska
                             "46027", #	Clay County, South Dakota
                             "48313", #	Madison County, Texas
                             "19171", #	Tama County, Iowa
                             "19189", #	Winnebago County, Iowa
                             "47121", #	Meigs County, Tennessee
                             "46037", #	Day County, South Dakota
                             "30073", #	Pondera County, Montana
                             "32013", #	Humboldt County, Nevada
                             "22085", #	Sabine Parish, Louisiana
                             "40027", #	Cleveland County, Oklahoma
                             "48399", #	Runnels County, Texas
                             "04009", #	Graham County, Arizona
                             "27127", #	Redwood County, Minnesota
                             "48253", #	Jones County, Texas
                             "49047", #	Uintah County, Utah
                             "06021", #	Glenn County, California
                             "35055", #	Taos County, New Mexico
                             "37103", #	Jones County, North Carolina
                             "28099", #	Neshoba County, Mississippi
                             "06045", #	Mendocino County, California
                             "48281", #	Lampasas County, Texas
                             "40141", #	Tillman County, Oklahoma
                             "13007", #	Baker County, Georgia
                             "48233", #	Hutchinson County, Texas
                             "55115", #	Shawano County, Wisconsin
                             "27021", #	Cass County, Minnesota
                             "41053", #	Polk County, Oregon
                             "27029", #	Clearwater County, Minnesota
                             "35027", #	Lincoln County, New Mexico
                             "51036", #	Charles City County, Virginia
                             "16073", #	Owyhee County, Idaho
                             "19133", #	Monona County, Iowa
                             "37093", #	Hoke County, North Carolina
                             "19095", #	Iowa County, Iowa
                             "51610", #	Falls Church city, Virginia
                             "22003", #	Allen Parish, Louisiana
                             "13241", #	Rabun County, Georgia
                             "02240", #	Southeast Fairbanks Census Area, Alaska
                             "54059", #	Mingo County, West Virginia
                             "40109", #	Oklahoma County, Oklahoma
                             "40011", #	Blaine County, Oklahoma
                             "27173", #	Yellow Medicine County, Minnesota
                             "20021", #	Cherokee County, Kansas
                             "12047", #	Hamilton County, Florida
                             "05083", #	Logan County, Arkansas
                             "46029", #	Codington County, South Dakota
                             "26153", #	Schoolcraft County, Michigan
                             "05113", # Polk County, Arkansas
                             "10001", #	Kent County, Delaware
                             "40085", #	Love County, Oklahoma
                             "29059", #	Dallas County, Missouri
                             "20043", #	Doniphan County, Kansas
                             "41065", #	Wasco County, Oregon
                             "06093", #	Siskiyou County, California
                             "16011", #	Bingham County, Idaho
                             "28101", #	Newton County, Mississippi
                             "08051", #	Gunnison County, Colorado
                             "12043", #	Glades County, Florida
                             "05009", #	Boone County, Arkansas
                             "31137", #	Phelps County, Nebraska
                             "46035", #	Davison County, South Dakota
                             "29119", #	McDonald County, Missouri
                             "53047", #	Okanogan County, Washington
                             "47177", #	Warren County, Tennessee
                             "16049", #	Idaho County, Idaho
                             "37099", #	Jackson County, North Carolina
                             "13277", #	Tift County, Georgia
                             "20061", #	Geary County, Kansas
                             "16067", #	Minidoka County, Idaho
                             "20161", #	Riley County, Kansas
                             "16075", #	Payette County, Idaho
                             "41011", #	Coos County, Oregon
                             "12003", #	Baker County, Florida
                             "35043", #	Sandoval County, New Mexico
                             "21007", #	Ballard County, Kentucky
                             "17115", #	Macon County, Illinois
                             "16085", #	Valley County, Idaho
                             "35007", #	Colfax County, New Mexico
                             "18175", #	Washington County, Indiana
                             "30013", #	Cascade County, Montana
                             "02170", #	Matanuska-Susitna Borough, Alaska
                             "16069", #	Nez Perce County, Idaho
                             "40047", #	Garfield County, Oklahoma
                             "40003", #	Alfalfa County, Oklahoma
                             "38003", #	Barnes County, North Dakota
                             "51820", #	Waynesboro city, Virginia
                             "01027", #	Clay County, Alabama
                             "35057", #	Torrance County, New Mexico
                             "51081", #	Greensville County, Virginia
                             "05087", #	Madison County, Arkansas
                             "19137", #	Montgomery County, Iowa
                             "20125", #	Montgomery County, Kansas
                             "51127", #	New Kent County, Virginia
                             "26089", #	Leelanau County, Michigan
                             "51183", #	Sussex County, Virginia
                             "24041", #	Talbot County, Maryland
                             "17169", #	Schuyler County, Illinois
                             "05039", #	Dallas County, Arkansas
                             "19149", #	Plymouth County, Iowa
                             "05097", #	Montgomery County, Arkansas
                             "48077", #	Clay County, Texas
                             "51009") #	Amherst County, Virginia

    #note: I double checked the regular transit index data quality flags, and the 
    #counties that were flagged for that were at least a 2 or 3 for the race data
    #quality as well, so don't need to add anything to account for that. 
    #And, this sets index values and data quality to n/a if both indices equal 0
    #since we created them in the expansion (not all counties could have 3 race categories)

county_transport_stats_by_race <- county_transport_stats_by_race %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_race_data2, true = 2, false = 1)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_race_data2, true = 2, false = 1)) %>%
  mutate(mean_tcost_quality = if_else(condition = geoid %in% problem_counties_race_data3, true = 3, false = mean_tcost_quality)) %>%
  mutate(mean_trans_quality = if_else(condition = geoid %in% problem_counties_race_data3, true = 3, false = mean_trans_quality)) %>%
  mutate(mean_tcost = if_else(mean_tcost == 0 & mean_trans == 0, as.numeric(NA), mean_tcost)) %>%
  mutate(mean_trans = if_else(mean_tcost == 0 & mean_trans == 0, as.numeric(NA), mean_trans)) %>%
  mutate(mean_trans_quality = if_else(is.na(mean_trans), as.numeric(NA), mean_trans_quality)) %>%
  mutate(mean_tcost_quality = if_else(is.na(mean_tcost), as.numeric(NA), mean_tcost_quality)) %>%
  mutate(subgroup_type = "race-ethnicity") %>%
  rename(subgroup = race_category) %>%
  select(-geoid)

    #Join the race breakdown dataset to the original dataset
county_transport_stats_by_race_final <- rbind(county_transport_stats_by_race, county_transport_stats)

    #And format to fit data standards
county_transport_stats_by_race_final <- county_transport_stats_by_race_final[, c(1, 2, 3, 9, 4, 5, 6, 7, 8)]
county_transport_stats_by_race_final <- county_transport_stats_by_race_final %>%
  arrange(year, state, county, subgroup_type, subgroup)

    #Write out final CSV
write_csv(county_transport_stats_by_race_final, "output/county_transport_stats_by_race_final.csv")