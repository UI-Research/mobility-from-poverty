# Punitive policing - juvenile arrest
# Data from NIBRS 2021 arrestee segment and group B arrest segment
# Description: Create juvenile arrest metrics
# Geography: place

# Code by Ashlin Oglesby-Neal
# Last updated 2023-04-11

library(tidyverse)
library(skimr)

# 1 Load data----
# 2021 NIBRS group A arrestee segment from Jacob Kaplan
arr <- readRDS("07_safety/data/nibrs_arrestee_segment_2021.rds")

# 2021 NIBRS group B arrest segment from Jacob Kaplan
arr_b <- readRDS("07_safety/data/nibrs_group_b_arrest_report_segment_2021.rds")

# places in Urban file with demographics
place_demos <- read_csv("07_safety/modified data/2021_place_demo.csv")

# agencies linked to places in Urban file
ba_pl_ur <- read_csv("07_safety/modified data/2021_agency_place.csv")

# crime categories from 2021.1 National Incident-Based Reporting System User Manual
property <- c("all other larceny", "arson", "bribery", "burglary/breaking and entering",
              "counterfeiting/forgery", "credit card/atm fraud", 
              "destruction/damage/vandalism of property", "embezzlement",
              "extortion/blackmail", "false pretenses/swindle/confidence game",
              "hacking/computer invasion", "identity theft", "impersonation",
              "motor vehicle theft", "pocket-picking", "purse-snatching", "robbery",
              "shoplifting", "stolen property offenses (receiving, selling, etc.)",
              "theft from building", "theft from coin-operated machine or device",
              "theft from motor vehicle", "theft of motor vehicle parts/accessories",
              "welfare fraud", "wire fraud")
person <- c("aggravated assault", "fondling (incident liberties/child molest)",
            "human trafficking - commercial sex acts", "human trafficking - involuntary servitude",
            "incest", "intimidation", "kidnapping/abduction", 
            "murder/nonnegligent manslaughter", "negligent manslaughter", "rape",
            "sexual assault with an object", "simple assault", "sodomy",
            "statutory rape")


# 2 Process data----
# combine group A and group B files
## rename variable and select only necessary variables from group B
arr_b <- arr_b %>%
  rename(incident_number = arrest_transaction_incident_num) %>%
  select(year, ori, incident_number, ucr_arrest_offense_code, age_of_arrestee, race_of_arrestee,
         ethnicity_of_arrestee) %>%
  mutate(group = "B")

## bind group b file with group a file
arr_ab <- arr %>%
  select(year, ori, incident_number, ucr_arrest_offense_code, age_of_arrestee, race_of_arrestee,
         ethnicity_of_arrestee) %>%
  mutate(group = "A") %>%
  bind_rows(arr_b)

rm(arr, arr_b)
gc()

# limit to under age 18
table(arr_ab$age_of_arrestee)
ar_juv <- arr_ab %>%
  mutate(age = as.numeric(age_of_arrestee)) %>%
  filter(age < 18)
# forcing NA over over 98 years old and unknown since not using

skim(ar_juv)
ar_juv %>% group_by(group) %>% skim()

# summarize by agency
ar_juv_agency <- ar_juv %>%
  mutate(property = ifelse(ucr_arrest_offense_code %in% property, 1, 0),
         violent = ifelse(ucr_arrest_offense_code %in% person, 1, 0)) %>%
  filter(age >= 10) %>%
  group_by(ori) %>%
  summarize(arr_total = n(),
            arr_prop = sum(property==1),
            arr_viol = sum(violent==1),
            age_10_14 = sum(age >= 10 & age <= 14),
            age_15_17 = sum(age >= 15 & age <= 17),
            race_aian = sum(race_of_arrestee == "american indian/alaskan native"),
            race_asian = sum(race_of_arrestee == "asian"),
            race_black = sum(race_of_arrestee == "black"),
            race_nhpi = sum(race_of_arrestee == "native hawaiian or other pacific islander"),
            race_unkno = sum(race_of_arrestee == "unknown"),
            race_white = sum(race_of_arrestee == "white"),
            ethn_hispanic = sum(ethnicity_of_arrestee == "hispanic origin"),
            ethn_nonhisp = sum(ethnicity_of_arrestee == "not of hispanic origin"),
            group_a = max(group=="A"),
            group_b = max(group=="B")
  ) %>%
  ungroup() %>%
  mutate(race_asian_other = race_aian + race_asian + race_nhpi)

ar_juv_agency %>% count(group_a, group_b)
# 682 agencies only have Group B arrests of juveniles

# make narrow version with just needed variables
ar_juv_agency <- ar_juv_agency %>%
  select(ori, arr_total, arr_viol, arr_prop, starts_with("race"), ethn_hispanic)


# 3 Merge geography----
# start with full universe of agencies in Urban places, merge on juvenile arrests
ar_juv_agency_geo <- ba_pl_ur %>%
  left_join(ar_juv_agency, by = "ori") 


# 4 Summarize by place----
# count number of arrests from reporting agencies in each place
ar_juv_place <- ar_juv_agency_geo %>%
  group_by(state, place) %>%
  # AR: there are some agencies with no data and this summarize statement
  # makes it so that the value is zero instead of missing (ori - CA0300400)
  summarize(across(arr_total:ethn_hispanic, ~sum(.x, na.rm=TRUE))) %>%
  mutate(GEOID = str_c(state, place)) %>%
  ungroup()


# 5 Calculate reporting rate for any arrest----
# Agencies may actually have zero juvenile arrests, so starting from full file
ar_any <- arr_ab %>%
  group_by(ori) %>%
  summarize(arr_total_any = n()) %>%
  ungroup()

# merge geography
# indicate reporting by place-agency
ar_any_agency_geo <- ba_pl_ur %>%
  left_join(ar_any, by = "ori") %>%
  mutate(reporting = ifelse(is.na(arr_total_any), 0, 1))

# summarize by place
# count number of agencies reporting, also weighted count
# create percentage reporting
ar_any_place <- ar_any_agency_geo %>%
  group_by(state, place) %>%
  summarize(n = n(), 
            n_reporting = sum(reporting),
            n_core_city = sum(core_city),
            n_core_city_rpt = sum(core_city==1 & reporting==1),
            across(arr_total_any, ~sum(.x, na.rm=TRUE))) %>%
  mutate(agencies_reporting = n_reporting / n,
         core_reporting = n_core_city_rpt / n_core_city,
         core_reporting = ifelse(is.nan(core_reporting), NA, core_reporting),
         GEOID = str_c(state, place)) %>%
  ungroup()

skim(ar_any_place)
# rate of reporting better when calculate based on all arrests and include A & B

# merge back to juvenile arrest file
ar_juv_place <- ar_juv_place %>%
  left_join(ar_any_place, by = c("GEOID", "state", "place")) 

skim(ar_juv_place)


# 6 Calculate rates----
# Merge demographic file
ar_juv_place_demo <- place_demos %>%
  left_join(ar_juv_place, by = "GEOID")

skim(ar_juv_place_demo)

# Calculate arrest rates
juv_arrest_by_place <- ar_juv_place_demo %>%
  mutate(juv_arrest_rate = arr_total / age_1017 * 100000,
         juv_arrest_rate_violent = arr_viol / age_1017 * 100000,
         juv_arrest_rate_property = arr_prop / age_1017 * 100000,
         juv_arrest_rate_white = race_white / age_1017_white * 100000,
         juv_arrest_rate_black = race_black / age_1017_black * 100000,
         #juv_arrest_rate_aian  = race_aian / age_1017_aian * 100000,
         juv_arrest_rate_asian_other = race_asian_other / age_1017_asian_other * 100000,
         #juv_arrest_rate_nhpi  = race_nhpi / age_1017_nhpi * 100000,
         juv_arrest_rate_hispanic  = ethn_hispanic / age_1017_hispanic * 100000)


# suppress data using populations < 30 people
juv_arrest_by_place <- juv_arrest_by_place %>%
  mutate(juv_arrest_rate = ifelse(age_1017 < 30, NA, juv_arrest_rate),
         juv_arrest_rate_violent = ifelse(age_1017 < 30, NA, juv_arrest_rate_violent),
         juv_arrest_rate_property = ifelse(age_1017 < 30, NA, juv_arrest_rate_property),
         juv_arrest_rate_white = ifelse(age_1017_white < 30, NA, juv_arrest_rate_white),
         juv_arrest_rate_black = ifelse(age_1017_black < 30, NA, juv_arrest_rate_black),
         #juv_arrest_rate_aian = ifelse(age_1017_aian < 30, NA, juv_arrest_rate_aian),
         juv_arrest_rate_asian_other = ifelse(age_1017_asian_other < 30, NA, juv_arrest_rate_asian_other),
         #juv_arrest_rate_nhpi = ifelse(age_1017_nhpi < 30, NA, juv_arrest_rate_nhpi),
         juv_arrest_rate_hispanic = ifelse(age_1017_hispanic < 30, NA, juv_arrest_rate_hispanic))

# check rates
juv_arrest_by_place %>%
  select(starts_with("juv_arrest_rate")) %>%
  skim()


# 7 Make quality indicators----
# compare all reporting plus core reporting
juv_arrest_by_place <- juv_arrest_by_place %>%
  mutate(all_juv_arrest_rate_quality = case_when(
    agencies_reporting == 1 ~ 1,
    agencies_reporting >= 0.8 ~ 2,
    agencies_reporting > 0 ~ 3,
    agencies_reporting == 0 ~ NA_real_),
    juv_arrest_rate_quality = case_when(
      agencies_reporting == 1 ~ 1,
      agencies_reporting >= 0.8 | core_reporting==1 ~ 2,
      agencies_reporting > 0 ~ 3,
      agencies_reporting == 0 ~ NA_real_),
    all_juv_arrest_rate_quality = ifelse(age_1017 < 30, NA, all_juv_arrest_rate_quality),
    juv_arrest_rate_quality = ifelse(age_1017 < 30, NA, juv_arrest_rate_quality)
  )

# check distribution based on definition
juv_arrest_by_place %>%
  count(all_juv_arrest_rate_quality, juv_arrest_rate_quality)
# with core reporting, 79 places move from 3 to 2

# 8 Save data----
juv_arrest_by_place_2021 <- juv_arrest_by_place %>%
  mutate(year=2021,
         across(starts_with("juv_arrest"), 
                ~ifelse(is.na(juv_arrest_rate_quality), NA, .x)),
         state = ifelse(is.na(state), str_sub(GEOID, 1, 2), state),
         place = ifelse(is.na(place), str_sub(GEOID, 3, 7), place)) %>%
  select(c(year, state, place, starts_with("juv_arrest"), age_1017, age_1017_white,
           age_1017_black, age_1017_asian_other, age_1017_hispanic,
           agencies_reporting, core_reporting))

skim(juv_arrest_by_place_2021)

check <- juv_arrest_by_place_2021 %>%
  filter(is.na(juv_arrest_rate_black) & !is.na(juv_arrest_rate_white))
# less than 30 black youth

# file with only total juvenile arrest rates
juv_arrest_place_2021 <- juv_arrest_by_place_2021 %>%
  select(year, state, place, juv_arrest_rate, juv_arrest_rate_violent,
         juv_arrest_rate_property, juv_arrest_rate_quality)

skim(juv_arrest_place_2021)
# note 16 places have 0 agencies, so NA for all metrics
write_csv(juv_arrest_place_2021, file = "07_safety/modified data/2021_juv_arrest_rate_place.csv")

# long form file with juvenile arrest rates by subgroup
# pivot longer subgroup populations
# create all row with overall juvenile population and arrest rate
juv_pop_2021_subgroup <- juv_arrest_by_place_2021 %>%
  mutate(age_1017_all = age_1017) %>%
  select(year, state, place, age_1017_all, age_1017_white, age_1017_black, 
         age_1017_asian_other, age_1017_hispanic, juv_arrest_rate_quality) %>%
  pivot_longer(cols = contains("age_1017"), 
               names_to = "subgroup",
               values_to = "age_1017",
               values_drop_na = TRUE,
               names_pattern = "age_1017_(.*)")

# pivot longer subgroup arrest rates
juv_arrest_2021_subgroup <- juv_arrest_by_place_2021 %>%
  mutate(juv_arrest_rate_all = juv_arrest_rate) %>%
  select(year, state, place, juv_arrest_rate_all, juv_arrest_rate_white, juv_arrest_rate_black,
         juv_arrest_rate_asian_other, juv_arrest_rate_hispanic) %>%
  pivot_longer(cols = contains("juv_arrest_rate_"), 
               names_to = "subgroup",
               values_to = "juv_arrest_rate",
               values_drop_na = TRUE,
               names_pattern = "juv_arrest_rate_(.*)")

# combine into one file
# replace quality indicators with missing if subgroup population < 30
juv_arrest_place_2021_subgroup <- juv_pop_2021_subgroup %>%
  left_join(juv_arrest_2021_subgroup, by = c("year", "state", "place", "subgroup")) %>%
  mutate(subgroup_type = "race-ethnicity",
         juv_arrest_rate_quality = ifelse(age_1017 < 30, NA, juv_arrest_rate_quality)) %>%
  select(-age_1017)

skim(juv_arrest_place_2021_subgroup)
juv_arrest_place_2021_subgroup %>% count(juv_arrest_rate_quality, is.na(juv_arrest_rate))

write_csv(juv_arrest_place_2021_subgroup, file = "07_safety/modified data/2021_juv_arrest_rate_place_subgroup.csv")