###############################################################################

# Description: Code to create county-level Economic Connectedness (one of two Social Capital Gates Mobility Metrics)  
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/social_capital_county.csv (won't be on Github)
# Data downloaded from Opportunity Insights Social Capital Atlas
# Author: Tina Chelidze											   
# Date: September 10, 2022

# (1)  download data from socialcapital.org											
# (2)  import and clean the data file				   
# (3)  use crosswalk to check any missing counties	
# (4)  create a data quality tag
# (5)  final file cleaning and export to csv file	

###############################################################################
  
    # Set working directory to [gitfolder]. Update path as necessary to your local metrics repo
    setwd("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty")

    # Libraries you'll need
    library(sf)
    library(tidyr)
    library(dplyr)
    library(readr)


# (1) download data from socialcapital.org
  
#     access via https://data.humdata.org/dataset/social-capital-atlas	
#     Social Capital Atlas - US Counties.csv is saved in [gitfolder]/06_neighborhoods/social-capital/data
  

# (2) open and clean the file (separate county and state codes, fill in missing zeroes)
  
     # open data
      ec_raw <- read.csv("06_neighborhoods/social-capital/data/social_capital_county.csv")

     # add leading zeroes where they are missing (2-digit state FIP + 3-digit county FIP  = 5 digit code)
      ec_raw$county <- sprintf("%05d", as.numeric(ec_raw$county))
  
     # keep only relevant data
      ec_raw <- ec_raw %>% select(county, county_name, ec_county, ec_se_county)
      
     # remove observations with missing data for our EC variable
      ec_raw %>% drop_na(ec_county)

     # rename the FIPS variable to avoid confusion
      ec_raw <- ec_raw %>% 
        rename("totalFIPS" = "county")

     # create a new column for the state FIPS
      ec_raw$state <- as.numeric(substr(ec_raw$totalFIPS, 1, 2))
     # add in the lost leading zeroes
      ec_raw$state <- sprintf("%02d", as.numeric(ec_raw$state))
     # create a new column for the county FIPS
      ec_raw$county <- as.numeric(substr(ec_raw$totalFIPS, 3, 5))
     # add in the lost leading zeroes
      ec_raw$county <- sprintf("%03d", as.numeric(ec_raw$county))
     # create a column for the year of this data
      ec_raw$year <- "2022"
      
     # save as temporary data file
      write.csv(ec_raw,"06_neighborhoods/social-capital/data/social-capital-county-clean.csv", row.names = FALSE)
      

# (3)  use crosswalk to check any missing counties	
      
      # import the county file
      county_pop <- read.csv("geographic-crosswalks/data/county-populations.csv")
      
      # add in the lost leading zeroes for the county FIP
      county_pop$county <- sprintf("%03d", as.numeric(county_pop$county))
      # add in the lost leading zeroes for the state FIP
      county_pop$state <- sprintf("%02d", as.numeric(county_pop$state))

      # keep the most recent year of population data (not 2022, but 2020)
      county_pop <- filter(county_pop, year > 2019)
      
      # merge the county file into the ec data file (left join, since county file has more observations)
      merged_ec <- merge(county_pop, ec_raw, by=c("state", "county"), all.x = TRUE)
      
      # check how many missing values (counties without EC data)
      sum(is.na(merged_ec$ec_county))
          # 126 counties without EC data

      
# (4)   create data quality tag
      merged_ec <- merged_ec %>%
        mutate(data_quality = case_when(ec_county >= 0 ~ 1))
      
      
# (5)   final file cleaning and export to csv file									   
      
      # keep only relevant data (dropping population data, keeping EC data year only)
      merged_ec <- merged_ec %>% select(year.y, state, county, state_name, county_name.x, ec_county, ec_se_county, data_quality)
      
      # rename the needed variable to avoid confusion
      merged_ec <- merged_ec %>% 
        rename("county_name" = "county_name.x")
      merged_ec <- merged_ec %>% 
        rename("year" = "year.y")
      
      # explort as .csv
      write_csv(merged_ec, "06_neighborhoods/social-capital/final_data/economic_connectedness_county_2022.csv")
      
      
      