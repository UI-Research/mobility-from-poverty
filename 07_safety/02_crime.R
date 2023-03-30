# Exposure to crime - violent and property crime rates
# Data from NIBRS 2021, text file, offense segment
# Description: Create exposure to crime metrics
# Geography: county

# Code by Ashlin Oglesby-Neal
# Last updated 2023-03-30

library(tidyverse)
library(skimr)

# 1 Load data----
# 2021 NIBRS offense segment
# retrieved from full text file by Jacob Kaplan
ofs <- readRDS("07_safety/data/nibrs_offense_segment_2021.rds")

# 2021 NIBRS full text file - original file that Jacob extracted data from
# inc <- read_tsv("Data/2021_NIBRS_NATIONAL_MASTER_FILE_ENC.txt", n_max=10000)

# load agency and county files
# counties with demographics and number of agencies
county_demo_agency <- read_csv("07_safety/modified data/2021_county_demo_agency.csv")

# agencies linked to counties and weight for each county
ba_long_wt <- read_csv("07_safety/modified data/2021_agency_weights_by_county.csv")

# county demographics only
county_demos <- read_csv("07_safety/modified data/2021_county_demo.csv")

# 2 Process crime data----
# reduce data to only necessary vars
of <- ofs %>%
  select(c(ori, ucr_offense_code))
rm(ofs)
gc()

# indicate violent and property crimes
# crime types
crimes <- of %>% count(ucr_offense_code)

# categories from 2021.1 National Incident-Based Reporting System User Manual
property <- c("all other larceny", "arson", "bribery", "burglary/breaking and entering",
              "counterfeiting/forgery", "credit card/atm fraud", 
              "destruction/damage/vandalism of property", "embezzlement",
              "extortion/blackmail", "false pretenses/swindle/confidence game",
              "hacking/computer invasion", "identity theft", "impersonation",
              "motor vehicle theft", "pocket-picking", "purse-snatching", 
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

# indicate property and violent crimes
of <- of %>%
  mutate(property = ifelse(ucr_offense_code %in% property, 1, 0),
         violent = ifelse(ucr_offense_code %in% person, 1, 0))

# aggregate by agency
of_agency <- of %>%
  group_by(ori) %>%
  summarize(all = n(),
            violent = sum(violent),
            property = sum(property)) %>%
  ungroup()

# 3 Merge geography----
# start with full universe of agencies, merge on crime
# multiply stats by weight
# indicate agencies that are reporting
of_agency_geo <- ba_long_wt %>%
  left_join(of_agency, by = "ori") %>%
  mutate(across(all:property, ~.x * weight),
         reporting = ifelse(is.na(all), 0, 1))

# check what percent of crime is special agencies (5) - very small
of_agency_geo %>%
  group_by(agency_type) %>%
  summarize(n = n(), 
            n_rpt = sum(!is.na(all)),
            crime = sum(all, na.rm=TRUE)) %>%
  ungroup() %>%
  mutate(pct = crime / sum(crime),
         pct_report = n_rpt / n)

# 4 Summarize by county----
# count number of crimes and number of reporting agencies
of_agency_county <- of_agency_geo %>%
  group_by(state, county) %>%
  summarize(n = n(),
            n_wt = sum(weight),
            n_reporting = sum(reporting),
            n_reporting_wt = sum(reporting * weight),
            n_core_city = sum(core_city),
            n_core_city_rpt = sum(core_city==1 & reporting==1),
            across(all:property, ~sum(.x, na.rm=TRUE))) %>%
  mutate(agencies_reporting = n_reporting / n,
         agencies_reporting_wt = n_reporting_wt / n_wt,
         core_reporting = n_core_city_rpt / n_core_city,
         GEOID = str_c(state, county)) %>%
  ungroup()

skim(of_agency_county)

# 5 Calculate rates----
# Merge demographic file to get population denominator
of_county_demo <- county_demo_agency %>%
  select(c(GEOID, total_people)) %>%
  left_join(of_agency_county, by = "GEOID")

skim(of_county_demo)

# Calculate crime rates
of_by_county <- of_county_demo %>%
  mutate(crime_violent_rate = violent / total_people * 100000,
         crime_property_rate = property / total_people * 100000)


# suppress data using population of less than 30 people
of_by_county <- of_by_county %>%
  mutate(crime_violent_rate = ifelse(total_people < 30, NA, crime_violent_rate),
         crime_property_rate = ifelse(total_people < 30, NA, crime_property_rate))

# check rates
of_by_county %>%
  select(ends_with("_rate")) %>%
  skim()
  # missing for 7 counties with no law enforcement agencies

# 7 Make quality indicators----
of_by_county <- of_by_county %>%
  mutate(
    all_crime_rate_quality = case_when(
      agencies_reporting == 1 ~ 1,
      agencies_reporting >= 0.8 ~ 2,
      agencies_reporting > 0 ~ 3,
      agencies_reporting == 0 ~ NA_real_),
    crime_rate_quality = case_when(
      agencies_reporting == 1 ~ 1,
      agencies_reporting >= 0.8 | core_reporting==1 ~ 2,
      agencies_reporting > 0 ~ 3,
      agencies_reporting == 0 ~ NA_real_)
  )

# check distribution based on definition
of_by_county %>%
  count(all_crime_rate_quality, crime_rate_quality)
  # very similar - core reporting moves 192 counties from 3 to 2 

# 8 Save data----
of_by_county_2021 <- of_by_county %>%
  mutate(year=2021,
         across(c(crime_violent_rate, crime_property_rate), 
                ~ifelse(is.na(crime_rate_quality), NA, .x)),
         state = ifelse(is.na(state), str_sub(GEOID, 1, 2), state),
         county = ifelse(is.na(county), str_sub(GEOID, 3, 5), county)) %>%
  select(c(year, state, county, total_people, starts_with("crime"),
           agencies_reporting, core_reporting))

skim(of_by_county_2021)

write_csv(of_by_county_2021, file = "07_safety/modified data/2021_crime_rate_county.csv")

