/*************************/
  air qaulity program: 
  created by: rebecca marx
  updated on: august 5, 2022
Description: 
(1)creates tract-level indicators of poverty and race for counties in US
*/
  /*************************/
  
#install packages
  # install.packages("devtools")
  # devtools::install_github("UrbanInstitute/urbnmapr")
  library(tidyverse)
  library(tidycensus)
  library(tm)
  library(purrr)
  library(urbnmapr)
  library(skimr)
  library(rvest)
  library(httr)

####STEP ONE: PULL AIR QUALITY DATA FROM EPA WITH API####
#request api key 
#user ID: rmarx@urban.org
#key: khakibird13

#url base <- "https://aqs.epa.gov/aqsweb/airdata/download_files.html#Annual"

## get number of records
#request <- GET(paste0(url_base, "&$select=id&$top=1"))
#results <- jsonlite::fromJSON(rawToChar(request$content))
#count <- results$metadata$count


####STEP 1: LOAD EPA AIR QUALITY DATA####

epa_aqi_data <- read.csv("data/annual_aqi_by_county_2021.csv")

#Only keep needed variabales: year, state, county/city, X90th.Percentile.AQI 
#and rename them to match formatting protocol
epa_aqi_data <- epa_aqi_data %>% 
  select(Year, State, County, X90th.Percentile.AQI) 

  colnames (epa_aqi_data) <- c("year", "state", "county", "aqi") 
  
####STEP 2: LOAD FIPS DATA AND FORMAT FOR JOIN###

  data("fips_codes")
  fips_data <- fips_codes 
  fips_data$county <- removeWords(fips_data$county," County")
  fips_data <- subset(fips_data, select = -c(state))
  colnames (fips_data) <- c("state_code", "state", "county_code","county")
  
####STEP 3: JOIN FIPS AND EPA DATA FOR FIPS IDS####
  aqi_fips2 <- left_join(fips_data,epa_aqi_data, by=c("state","county"))
  aqi_fips1 <- merge(fips_data,epa_aqi_data,by=c('state','county'))
  
      