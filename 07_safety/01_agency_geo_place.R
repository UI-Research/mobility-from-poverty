# Agency to geography crosswalk, place demographics
# Agency data from 2020 NIBRS NACJD batch extract and 2012 LEAIC crosswalk
# Description: Create crosswalk from agencies to county geographies 

# Code by Ashlin Oglesby-Neal
# Last updated 2023-04-06

library(tidyverse)
library(skimr)
library(tidycensus)
library(tidylog) # library to show join output
# set Census API once
# census_api_key("", install=TRUE)

# 1 Load data----
# 2020 NIBRS batch header from NACJD
bat <- read_tsv("07_safety/data/38566-0001-Data.tsv")

# NIBRS state numbers
# are in alphabetical order, do not follow FIPS numbers
nibrs_states <- read_csv("07_safety/data/nibrs_states.csv")

# county populations file from Urban
pop <- read_delim("07_safety/data/place-populations.txt",
                  delim = ",")

# LEAIC crosswalk 2012
# need for agencies that are missing county information
lecw <- read_tsv("07_safety/data/35158-0001-Data.tsv")

# county-place crosswalk from Missourri Census Data Center
# https://mcdc.missouri.edu/applications/geocorr2022.html
cp_cw <- read_csv("07_safety/data/geocorr2022_2310102243.csv")

# 2a Process Urban crosswalk----
# *filter crosswalk that Urban created to 2020 only
pop20 <- pop %>%
  filter(year==2020) %>%
  mutate(place_name = str_to_title(place_name),
         GEOID = str_c(state,place),
         city = str_remove(place_name, " City"))

geos <- pop20$GEOID

# *filter Urban crosswalk to states so can fix state numbers in NIBRS data
pop_st <- pop %>%
  select(c(state, state_name)) %>%
  distinct()

# 2b Process county-place crosswalk----
cp_cw_ur <- cp_cw %>%
  filter(place!= "Place code") %>%
  mutate(GEOID = str_c(state,place)) %>% 
  filter(GEOID %in% geos)
skim(cp_cw_ur)
# some counties correspond to multiple places

# filter to only counties that correspond with one place
cp_cw_ur <- cp_cw_ur %>%
  group_by(state,county) %>%
  mutate(n = n()) %>%
  ungroup() %>%
  filter(n == 1)

# 2c Process agency information----
# use agency batch header info from NACJD 2020
# rename and reduce to only necessary vars
# then merge to get full state names and FIPS state numbers
ba <- bat %>% 
  rename(ori = BH003, # ori is unique agency identifier used across multiple files
         agency_type = BH012,
         state_num_nibrs = BH002,
         state_abb = BH008,
         city = BH007,
         core_city = BH013,
         fips_county_1 = BH054,
         fips_county_2 = BH055,
         fips_county_3 = BH056,
         fips_county_4 = BH057,
         msa_1 = BH021,
         msa_2 = BH025,
         msa_3 = BH029,
         msa_4 = BH033,
         msa_5 = BH037,
         pop_1 = BH019,
         pop_2 = BH023,
         pop_3 = BH027,
         pop_4 = BH031,
         pop_5 = BH035) %>%
  select(c(ori, agency_type, state_abb, state_num_nibrs, city, core_city, starts_with("fips"), 
           starts_with("msa"), starts_with("pop"))) %>%
  mutate(year=2021,
         state_num_nibrs = str_pad(state_num_nibrs, 2, pad = "0"),
         county = str_pad(fips_county_1, 3, pad = "0"),
         city = str_to_title(city),
         pop_total = pop_1 + pop_2 + pop_3 + pop_4 + pop_5) %>%
  left_join(nibrs_states, by = c("state_abb", "state_num_nibrs")) %>%
  left_join(pop_st, by="state_name")

# check the distribution of agency types
ba %>% count(agency_type) %>%
  mutate(pct = n/nrow(ba))
#1 city, 2 county, 3 college, 5 special, 7 tribal

# remove state agencies since cover multiple counties
# 4 is state police and 6 is other state agency
ba <- ba %>%
  filter(agency_type != 4 & agency_type != 6)

# clean LEAIC crosswalk
# limit to useful info from LEAIC crosswalk
# remove agencies with invalid ORI
lecw_nrw <- lecw %>%
  mutate(place = str_pad(FPLACE, 5, pad = "0"),
         GEOID = str_c(FIPS_ST, place)) %>%
  select(ORI9, GEOID, FIPS_ST, FIPS_COUNTY, place, UANAME, LG_NAME) %>%
  rename(ori = ORI9) %>%
  filter(ori != "-1") 

# merge to 2020 agency batch
ba_cw <- ba %>%
  left_join(lecw_nrw, by = "ori")

# how many are new agencies not in 2012 crosswalk
skim(ba_cw$place) #481
ba_cw %>%
  filter(is.na(place)) %>%
  skim(pop_total)
  # most are from counties with small populations

# check bigger ones
ba_cw %>%
  filter(is.na(place) & pop_total > 70000) 

# variety of agency types
ba_cw %>%
  filter(is.na(place)) %>%
  count(agency_type)

# attempt merging based on city name
ba_cw_mis <- ba_cw %>%
  filter(is.na(place)) %>%
  select(ori, state_abb, state, city, county) %>%
  left_join(pop20, by = c("state","city"))
skim(ba_cw_mis)

# check remaining cities that do not merge
cit <- ba_cw_mis %>%
  filter(is.na(place)) %>%
  count(state_abb, city)
  # augusta GA, winston salem, indianapolis

# for remaining agencies with no place, merge based on county-place CW
ba_cw_mis2 <- ba_cw_mis %>%
  filter(is.na(place)) %>%
  mutate(state_county = str_c(state, county)) %>%
  select(ori, state_abb, city, state_county) %>%
  left_join(cp_cw_ur, by = c("state_county"="county"))
skim(ba_cw_mis2)
 # 15% match, pretty good since limiting to only Urban places

cit <- ba_cw_mis2 %>%
  filter(is.na(place)) %>%
  count(state_abb, city)

# combine agency-place data frames back together
ba_cw_all <- ba_cw %>%
  filter(!is.na(place)) %>%
  bind_rows(ba_cw_mis) %>%
  filter(!is.na(place)) %>%
  bind_rows(ba_cw_mis2) %>%
  select(ori, place) %>%
  mutate(place = ifelse(place=="99999", NA, place))
  # 293 agencies still missing place, 14 were 99999 indicating not a place


# limit to places in Urban crosswalk
ba_cw_pl <- ba %>%
  left_join(ba_cw_all, by="ori") %>%
  mutate(GEOID = str_c(state, place)) %>%
  filter(GEOID %in% geos)
  # reduces from 19038 agencies to 1097

# 3 Place-level demographics----
# check variables
v21 <- load_variables(2021, "acs5")

# Pull 2021 ACS data at the Census Place level
place_demo <- get_acs(geography = "place",
                       variables = c(total_people = "B01003_001",
                                     age_m_1014 = "B01001_005", 
                                     age_m_1517 = "B01001_006",
                                     age_f_1014 = "B01001_029", 
                                     age_f_1517 = "B01001_030",
                                     age_m_1014_white = "B01001A_005", 
                                     age_m_1014_black = "B01001B_005",
                                     age_m_1014_aian = "B01001C_005", 
                                     age_m_1014_asin = "B01001D_005",
                                     age_m_1014_nhpi = "B01001E_005", 
                                     age_m_1014_othr = "B01001F_005",
                                     age_m_1014_twom = "B01001G_005",
                                     age_m_1014_white_nh = "B01001H_005",
                                     age_m_1014_hispanic = "B01001I_005",
                                     age_m_1517_white = "B01001A_006", 
                                     age_m_1517_black = "B01001B_006",
                                     age_m_1517_aian = "B01001C_006", 
                                     age_m_1517_asin = "B01001D_006",
                                     age_m_1517_nhpi = "B01001E_006", 
                                     age_m_1517_othr = "B01001F_006",
                                     age_m_1517_twom = "B01001G_006",
                                     age_m_1517_white_nh = "B01001H_006", 
                                     age_m_1517_hispanic = "B01001I_006",
                                     age_f_1014_white = "B01001A_020", 
                                     age_f_1014_black = "B01001B_020",
                                     age_f_1014_aian = "B01001C_020", 
                                     age_f_1014_asin = "B01001D_020",
                                     age_f_1014_nhpi = "B01001E_020", 
                                     age_f_1014_othr = "B01001F_020",
                                     age_f_1014_twom = "B01001G_020",
                                     age_f_1014_white_nh = "B01001H_020",
                                     age_f_1014_hispanic = "B01001I_020",
                                     age_f_1517_white = "B01001A_021", 
                                     age_f_1517_black = "B01001B_021",
                                     age_f_1517_aian = "B01001C_021", 
                                     age_f_1517_asin = "B01001D_021",
                                     age_f_1517_nhpi = "B01001E_021",
                                     age_f_1517_othr = "B01001F_021",
                                     age_f_1517_twom = "B01001G_021",
                                     age_f_1517_white_nh = "B01001H_021", 
                                     age_f_1517_hispanic = "B01001I_021"),
                       year = 2021,
                       survey = "acs5",
                       output = "wide",
                       geometry = FALSE)

# get rid of E in name of variables and drop MOE
place_demo <- place_demo %>%
  select(-c(ends_with("M"))) %>%
  rename_with(~ sub("E$", "", .x), everything())

# Construct age and race/ethnicity groups
place_demo <- place_demo %>%
  mutate(
    age_1017 = age_m_1014 + age_m_1517 + age_f_1014 + age_f_1517,
    age_1017_white = age_m_1014_white + age_m_1517_white + age_f_1014_white + age_f_1517_white,
    age_1017_black = age_m_1014_black + age_m_1517_black + age_f_1014_black + age_f_1517_black,
    age_1017_aian = age_m_1014_aian + age_m_1517_aian + age_f_1014_aian + age_f_1517_aian,
    age_1017_asin = age_m_1014_asin + age_m_1517_asin + age_f_1014_asin + age_f_1517_asin,
    age_1017_nhpi = age_m_1014_nhpi + age_m_1517_nhpi + age_f_1014_nhpi + age_f_1517_nhpi,
    age_1017_othr = age_m_1014_othr + age_m_1517_othr + age_f_1014_othr + age_f_1517_othr,
    age_1017_twom = age_m_1014_twom + age_m_1517_twom + age_f_1014_twom + age_f_1517_twom,
    age_1017_hispanic = age_m_1014_hispanic + age_m_1517_hispanic + age_f_1014_hispanic + age_f_1517_hispanic,
    age_1017_white_nh = age_m_1014_white_nh + age_m_1517_white_nh + age_f_1014_white_nh + age_f_1517_white_nh,
  )

# limit to only variables needed for analysis
# limit to only places in Urban place crosswalk file
# manually create two or more race variable
place_demos <- place_demo %>%
  select(GEOID, total_people, starts_with("age_1017")) %>%
  filter(GEOID %in% pop20$GEOID) %>%
  mutate(year=2021,
         age_1017_asian_other = age_1017_aian + age_1017_asin + age_1017_nhpi +
           age_1017_othr + age_1017_twom)
# goes from 31,908 to 486 places

# 4 Make place-level file----
# note - do not know if agencies cover multiple places, relying on primary place

# make final agency-place file with only places in urban CW
# select only necessary variables
ba_pl_ur <- ba_cw_pl %>%
  select(c(ori, state, place, core_city, agency_type, GEOID)) %>%
  filter(!is.na(place)) %>%
  ungroup()
skim(ba_pl_ur)

# count how many agencies per place
place_agency <- ba_pl_ur %>%
  filter(!is.na(place)) %>%
  group_by(state, place) %>%
  summarize(n_agencies = n_distinct(ori),
            n_core_city = sum(core_city==1),
            core_city = max(core_city),
            n_agen_city = sum(agency_type==1),
            n_agen_cnty = sum(agency_type==2),
            n_agen_univ = sum(agency_type==3),
            n_agen_spcl = sum(agency_type==5),
            n_agen_trbl = sum(agency_type==7)) %>%
  ungroup() %>%
  mutate(GEOID = str_c(state, place))
skim(place_agency)
  # 470 places have agencies, 16 do not
  # max of 35 agencies, 2 core agencies in a place


# 5 Combine county-level agency and demographic info----
place_demo_agency <- place_demos %>%
  left_join(place_agency, by = "GEOID")


# check file
skim(place_demo_agency)
# 16 places have no agencies
place_demo_agency %>%
  filter(is.na(n_agencies)) %>%
  skim()
# most are in state 06 california

# 6 Save files----
# place demographics only
write_csv(place_demos, file = "07_safety/modified data/2021_place_demo.csv")

# place demographics plus agency info
write_csv(place_demo_agency, file = "07_safety/modified data/2021_place_demo_agency.csv")

# agency-place level file filtered to only Urban cw places
write_csv(ba_pl_ur, file = "07_safety/modified data/2021_agency_place.csv")