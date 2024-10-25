library(tidyverse)
library(janitor)
library(ipumsr)
library(here)

get_housing_microdata = function(
    county_years, ## the years for which to produce county-level estimates
    place_years) {  ## the years for which to produce place-level estimates
 
  ####----Setup-----####
  temporary_data_path <- here("02_housing", "data", "temp")
  
  if (!dir.exists(temporary_data_path)) {
    dir.create(temporary_data_path, recursive = TRUE)
  }

  ####----Download housing microdata from IPUMS API-----####
  # More information on the API can be found here: <https://cran.r-project.org/web/packages/ipumsr/vignettes/ipums-api.html>
  # If you don't already have one, you will need register for an IPUMS API key here: <https://uma.pop.umn.edu/usa/registration/new>

  extract_housing_microdata <- function(year) {
    define_extract_micro(
      collection = "usa",
      description = "Housing microdata extract", # description of extract
      samples = c(paste0("us", year, "a")), # use ACS data
      variables = c(
        "HHWT", ## household weight -- appropriate for statements about households
        "PERWT", ## person weight -- appropriate for statements about individuals
        "PERNUM", 
        "ADJUST", 
        "STATEFIP", ## 2-character state FIPS code
        "PUMA", ## code identifying the public-use microdata area (PUMA)
        "GQ", ## "general quarters"--identifies the household type
        "OWNERSHP", 
        "OWNCOST", 
        "RENT", 
        "RENTGRS", 
        "HHINCOME",
        "VALUEH", 
        "VACANCY", 
        "EDUC", 
        "EDUCD", 
        "GRADEATT", 
        "EMPSTAT", 
        "AGE", 
        "KITCHEN", 
        "PLUMBING"),
      data_structure = "rectangular") %>% 
      submit_extract() %>% 
      wait_for_extract() %>% 
      download_extract(download_dir = temporary_data_path) %>% 
      read_ipums_ddi() %>% 
      # roughly 3.3 million records
      read_ipums_micro() %>% 
      rename(
        "puma" = "PUMA",
        "statefip" = "STATEFIP") %>%
      mutate(
        statefip = sprintf("%0.2d", as.numeric(statefip)),
        puma = sprintf("%0.5d", as.numeric(puma))) %>% 
      arrange(statefip, puma) %>%
      # save temp file with API pull
      write_csv(here(temporary_data_path, paste0("housing_microdata_", year, ".csv")))
  }
  
  # Apply the function across all relevant years
  walk(county_years, extract_housing_microdata)
  
  # Function for querying the API - vacant unit data
  extract_vacancy_microdata <- function(year) {
    define_extract_usa(
      collection = "usa",
      description = "Vacancy microdata extract",
      samples = c(paste0("us", year, "a")),
      variables = list( ## a list is necessary to accommodate the var_spec() object
        "HHWT", 
        var_spec("GQ", case_selections = c("0")), # just download cases where GQ == 0 (vacant)
        "ADJUST", 
        "STATEFIP", 
        "PUMA", 
        "VALUEH", 
        "VACANCY",
        "RENTGRS",
        "RENT", 
        "KITCHEN", 
        "PLUMBING"),
      data_structure = "hierarchical") %>% 
      submit_extract() %>% 
      wait_for_extract() %>% 
      download_extract(download_dir = temporary_data_path) %>% 
      read_ipums_ddi() %>% 
      read_ipums_micro() %>% 
      rename(
        "puma" = "PUMA",
        "statefip" = "STATEFIP") %>%
      mutate(
        statefip = sprintf("%0.2d", as.numeric(statefip)),
        puma = sprintf("%0.5d", as.numeric(puma))) %>% 
      arrange(statefip, puma) %>%
      write_csv(here(temporary_data_path, paste0("vacancy_microdata_", year, ".csv")))
  }
  
  # Apply the function across all relevant years
  walk(county_years, extract_vacancy_microdata)
  
  ####----Prepare PUMA-to-Geography-of-Interest Crosswalks----####
  # Function to write lightly tailored crosswalks to a temporary folder for subsequent use
  puma_geography_crosswalk <- function(year, geography) {
    crosswalk_period = year
    
    if (as.numeric(crosswalk_period) < 2022) {
      crosswalk_period = "pre-2022"
    } 
    
    crosswalk = here("geographic-crosswalks", "data", paste0("crosswalk_puma_to_", geography, ".csv")) %>%
      read_csv() %>% 
      filter(
        statefip != 72, ## dropping PR-based records
        crosswalk_period == !!crosswalk_period,
        afact != 0) 
    
    crosswalk %>%
      write_csv(here(temporary_data_path, paste0("crosswalked_pumas_", geography, "_", year, ".csv")))
    
    crosswalk %>%
      { if (geography == "place") group_by(., statefip, place) else group_by(., statefip, county) } %>%
      summarize(puma_flag = mean(geographic_allocation_quality)) %>%
      write_csv(here(temporary_data_path, paste0("crosswalked_pumas_quality_", geography, "_", year, ".csv")))
  }
  
  ## Apply the function across all relevant geography-years
  walk(place_years, ~ puma_geography_crosswalk(year = .x, geography = "place"))
  walk(county_years, ~ puma_geography_crosswalk(year = .x, geography = "county"))
  
  message(
    "2021 is missing data for place fips 72122 in Georgia. That city was incorporated 
in 2016 and the pre-2022 crosswalk uses places from 2014 so it is not  captured. 
Given the limitations from GeoCorr I (Amy Rogin) don't think we can manually add it back in.")
  
  # Quality-check the rows in each generate crosswalk
  # check number of unique places in data
  stopifnot(
    # 2022 data
    read_csv(here(temporary_data_path, "crosswalked_pumas_place_2022.csv")) %>% 
      distinct(statefip, place) %>% nrow() == 486,
    # 2021 data
    read_csv(here(temporary_data_path, "crosswalked_pumas_place_2021.csv")) %>% 
      distinct(statefip, place) %>% nrow() == 485)
  
  # check number of unique counties in data
  walk(
    county_years,
    ~ stopifnot(
      read_csv(here(temporary_data_path, paste0("crosswalked_pumas_county_", .x, ".csv"))) %>% 
        distinct(statefip, county) %>% nrow() == 3143))
  
  ####----Apply the crosswalks to the corresponding microdata----####
  # Function for applying crosswalks to microdata
  prepare_microdata <- function(year, geography) {
    # read in appropriate crosswalk 
    puma_crosswalk <- read_csv(here(temporary_data_path, paste0("crosswalked_pumas_", geography, "_", year, ".csv")))
    
    # keep only vars we need
    acs_data <- read_csv(here(temporary_data_path, paste0("housing_microdata_", year, ".csv"))) %>%
      select(
        HHWT, 
        ADJUST, 
        statefip, 
        puma, 
        GQ,
        OWNERSHP, 
        OWNCOST, 
        RENT, 
        RENTGRS, 
        HHINCOME,
        VALUEH, 
        VACANCY, 
        PERNUM, 
        PERWT, 
        EDUC, 
        EDUCD, 
        GRADEATT,
        EMPSTAT, 
        AGE) %>% 
      mutate(
        statefip = str_pad(statefip, side = "left", width = 2, pad = "0"),
        puma = str_pad(puma, side = "left", width = 5, pad = "0")) %>% 
      # Merge the microdata PUMAs to places
      left_join(puma_crosswalk, by = c("statefip", "puma")) %>%  ## 3060 rows
      { if (geography == "place") mutate(., geography_code = str_c(statefip, place)) else mutate(., geography_code = str_c(statefip, county)) } %>% 
      ## Will: why is this necessary... this is a red flag
      distinct()
    
    # Drop any observations with NA or 0 for afact (i.e. there is no place of interest overlapping this PUMA)
    acs_data %>% 
      # removed 1,839,362 rows (49%), 1,942,397 rows remaining
      tidylog::filter(!is.na(afact)) %>% 
      # no rows removed
      tidylog::filter(afact > 0) %>%
      mutate(
        # the weight of each person/household is adjusted by the area of the PUMA that falls into a given place
        across(.cols = c(PERWT , HHWT), .fns = ~ .x * afact), 
        # adjusts dollar-denominated variables by the Census's 12-month adjustment factor
        across(.cols = c(HHINCOME, RENTGRS, OWNCOST), .fns = ~ .x * ADJUST)) %>%
      write_csv(here(temporary_data_path, paste0(geography, "_prepared_microdata_", year, ".csv")))
  }
  
  # Apply crosswalks to all geography-year combinations
  walk(county_years, ~ prepare_microdata(year = .x, geography = "county"))
  walk(place_years, ~ prepare_microdata(year = .x, geography = "place"))
}
