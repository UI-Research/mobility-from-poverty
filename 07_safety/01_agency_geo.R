# Agency to geography crosswalk, county demographics
# Data from 2020 NIBRS NACJD batch extract
# Description: Create crosswalk from agencies to county geographies 

# Code by Ashlin Oglesby-Neal
# Last updated 2023-04-06

library(tidyverse)
library(skimr)
library(tidycensus)

# set Census API once
# census_api_key("", install=TRUE)

# 1 Load data----
# 2020 NIBRS batch header from NACJD
bat <- read_tsv("07_safety/data/38566-0001-Data.tsv")

# NIBRS state numbers
# are in alphabetical order, do not follow FIPS numbers
nibrs_states <- read_csv("07_safety/data/nibrs_states.csv")

# county populations file from Urban
pop <- read_delim("07_safety/data/county-populations.txt",
                  delim = ",")

# LEAIC crosswalk 2012
# need for agencies that are missing county information
lecw <- read_tsv("07_safety/data/35158-0001-Data.tsv")

# 2 Process Urban crosswalk----
# *filter crosswalk that Urban created to 2020 only
pop20 <- pop %>%
  filter(year==2020) %>%
  mutate(county_name = str_to_title(county_name),
         GEOID = str_c(state, county))

# *filter Urban crosswalk to states so can fix state numbers in NIBRS data
pop_st <- pop %>%
  select(c(state, state_name)) %>%
  distinct()

# 3 Process agency information----
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

# examine NIBRS agency info
skim(ba)
table(ba$fips_county_1)
# a lot of counties have value of zero, which is not valid FIPS code

# subset data to examine further
ba0 <- ba %>%
  filter(fips_county_1==0)
# includes DC, Baltimore

# see if remaining ORIs in 2012 LEAIC crosswalks
sum(ba0$ori %in% lecw$ORI9)
# 232 agencies are in it

# *limit to useful info from LEAIC crosswalk
# remove agencies with invalid ORI
lecw_nrw <- lecw %>%
  select(ORI9, FIPS_COUNTY) %>%
  rename(ori = ORI9,
         county = FIPS_COUNTY) %>%
  filter(ori != "-1") 


# merge to ORIs missing county
ba0_cw <- ba0 %>%
  select(-c(county)) %>%
  left_join(lecw_nrw, by = "ori")

# check remaining agencies that do not merge\
ba00 <- ba0_cw %>%
  filter(is.na(county))
# 25 agencies still have no county, some in US territories
# will be excluded from county-level analysis
# all are tribal or special agencies

# combine back to original data
# replace fips county 1 with updated county number from LEAIC
ba_full <- ba %>%
  filter(fips_county_1 != 0) %>%
  bind_rows(ba0_cw) %>%
  filter(!is.na(county)) %>%
  mutate(fips_county_1 = county)


# 3 County-level demographics----
# check variables
v21 <- load_variables(2021, "acs5")

# Pull 2021 ACS data at the Census County level
county_demo <- get_acs(geography = "county",
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
# note, two or more race variable not appearing, may not be available at county level

# get rid of E in name of variables and drop MOE
county_demo <- county_demo %>%
  rename_with(~ sub("E$", "", .x), everything()) %>%
  select(-c(ends_with("M")))

# Construct age and race/ethnicity groups
county_demo <- county_demo %>%
  mutate(
    age_1017 = age_m_1014 + age_m_1517 + age_f_1014 + age_f_1517,
    age_1017_white = age_m_1014_white + age_m_1517_white + age_f_1014_white + age_f_1517_white,
    age_1017_black = age_m_1014_black + age_m_1517_black + age_f_1014_black + age_f_1517_black,
    age_1017_aian = age_m_1014_aian + age_m_1517_aian + age_f_1014_aian + age_f_1517_aian,
    age_1017_asin = age_m_1014_asin + age_m_1517_asin + age_f_1014_asin + age_f_1517_asin,
    age_1017_nhpi = age_m_1014_nhpi + age_m_1517_nhpi + age_f_1014_nhpi + age_f_1517_nhpi,
    age_1017_othr = age_m_1014_othr + age_m_1517_othr + age_f_1014_othr + age_f_1517_othr,
    #age_1017_twom = age_m_1014_twom + age_m_1517_twom + age_f_1014_twom + age_f_1517_twom,
    age_1017_hispanic = age_m_1014_hispanic + age_m_1517_hispanic + age_f_1014_hispanic + age_f_1517_hispanic,
    age_1017_white_nh = age_m_1014_white_nh + age_m_1517_white_nh + age_f_1014_white_nh + age_f_1517_white_nh,
  )

# limit to only variables needed for analysis
# limit to only counties in Urban county crosswalk file
# manually create two or more race variable
county_demos <- county_demo %>%
  select(GEOID, total_people, starts_with("age_1017")) %>%
  filter(GEOID %in% pop20$GEOID) %>%
  mutate(year=2021,
         age_1017_twom = age_1017 - age_1017_white - age_1017_black - 
           age_1017_aian - age_1017_asin - age_1017_nhpi - age_1017_othr,
         age_1017_asian_other = age_1017_aian + age_1017_asin + age_1017_nhpi +
           age_1017_othr + age_1017_twom)
# goes from 3,221 to 3,143 counties

# 4 Make county-level file----
# See how many agencies cover 2 and 3 counties
sum(!is.na(ba_full$fips_county_2)) # 676
sum(!is.na(ba_full$fips_county_3)) # 60

# make long form
ba_long <- ba_full %>%
  mutate(across(starts_with("fips"), ~str_pad(., 3, pad = "0"))) %>%
  select(c(ori, state, core_city, agency_type, starts_with("fips"))) %>%
  pivot_longer(-c(ori, state, core_city, agency_type), values_to = "county") %>%
  filter(!is.na(county)) %>%
  ungroup()

# add 2021 county population only
ba_long <- ba_long %>%
  mutate(GEOID = str_c(state,county)) %>%
  left_join(select(county_demos, c(GEOID, total_people)), by = "GEOID")

# check whether all counties merge
skim(ba_long) 
# 5 agencies (2 counties) not in file, will drop

# make agency weights based on population of counties they cover
ba_long_wt <- ba_long %>%
  filter(!is.na(total_people)) %>%
  group_by(ori) %>%
  mutate(weight = total_people / sum(total_people)) %>%
  ungroup()

# limit to only counties in Urban crosswalk
ba_long_wt <- ba_long_wt %>%
  filter(GEOID %in% pop20$GEOID)

# count how many agencies per county
county_agency <- ba_long_wt %>%
  group_by(state, county) %>%
  summarize(n_agencies = n_distinct(ori),
            n_core_city = sum(core_city==1),
            core_city = max(core_city),
            n_agen_city = sum(agency_type==1),
            n_agen_cnty = sum(agency_type==2),
            n_agen_univ = sum(agency_type==3),
            n_agen_spcl = sum(agency_type==5),
            n_agen_trbl = sum(agency_type==7)) %>%
  ungroup() %>%
  mutate(GEOID = str_c(state, county))

# check county-level data
skim(county_agency)
# Cook County has 171 non-state and non-federal agencies!; Allegheny has 135


# 5 Combine county-level agency and demographic info----
county_demo_agency <- county_demos %>%
  left_join(county_agency, by = "GEOID")

# limit to only counties in Urban crosswalk
county_demo_agency <- county_demo_agency %>%
  filter(GEOID %in% pop20$GEOID)
# 3143 counties

# check file
skim(county_demo_agency)
# 7 counties have no agencies
county_demo_agency %>%
  filter(is.na(n_agencies)) %>%
  skim()
# generally small counties (48 to 7,015 people)

# 6 Save files----
# county demographics only
write_csv(county_demos, file = "07_safety/modified data/2021_county_demo.csv")

# county demographics plus agency info
write_csv(county_demo_agency, file = "07_safety/modified data/2021_county_demo_agency.csv")

# agency-county level file
write_csv(ba_long_wt, file = "07_safety/modified data/2021_agency_weights_by_county.csv")