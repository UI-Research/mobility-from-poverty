###############################################################################

# Description: Code to create city-level Economic Connectedness (one of two Social Capital Gates Mobility Metrics)  
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/social_capital_zip.csv (won't be on Github)
# Data downloaded from Opportunity Insights Social Capital Atlas
# Author: Tina Chelidze											   
# Date: September 29, 2022

# (1)  download data from socialcapital.org											
# (2)  import and clean the data file				   
# (3)  merge with the 2010 ZCTA -> 2021 Census Place crosswalk
# (4)  collapse estimates to unique Places
# (5)  create data quality marker for number of observations collapsed)
# (6)  check against official Census Place file & limit to population cutoff Places
# (7)  final file cleaning and export to csv file	

###############################################################################

# Set working directory to [gitfolder]. Update path as necessary to your local metrics repo
setwd("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty")

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)
library(tigris)


# (1) download data from socialcapital.org

#     access via https://data.humdata.org/dataset/social-capital-atlas	
#     Social Capital Atlas - US Zip Codes is saved in [gitfolder]/06_neighborhoods/social-capital/data
#     NOTE: in the paper (https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf), they state that "Zip Codes" is shorthand for 2010 ZCTA designations


# (2) import and clean the file (separate county and state codes, fill in missing zeroes)

      # open data
      ec_zip_raw <- read.csv("06_neighborhoods/social-capital/data/social_capital_zip.csv")

      # add leading zeroes where they are missing (ZCTA codes are 5 digits)
      ec_zip_raw$zip <- sprintf("%05d", as.numeric(ec_zip_raw$zip))

      # keep only relevant data
      ec_zip_raw <- ec_zip_raw %>% select(zip, county, ec_zip, ec_se_zip)

      # remove observations with missing data for our EC variable
      ec_zip_raw <- ec_zip_raw %>% drop_na(ec_zip)
            ### There were 4048 missing observations deleted

      # rename the FIPS variable to avoid confusion
      ec_zip_raw <- ec_zip_raw %>% 
        rename("totalFIPS" = "county")

      # create a new column for the state FIPS
      ec_zip_raw$state <- as.numeric(substr(ec_zip_raw$totalFIPS, 1, 2))
      # add in the lost leading zeroes
      ec_zip_raw$state <- sprintf("%02d", as.numeric(ec_zip_raw$state))
      # create a new column for the county FIPS
      ec_zip_raw$county <- as.numeric(substr(ec_zip_raw$totalFIPS, 3, 5))
      # add in the lost leading zeroes (county code should have 3 digits)
      ec_zip_raw$county <- sprintf("%03d", as.numeric(ec_zip_raw$county))
      # create a column for the year of this data
      ec_zip_raw$year <- "2022"

      # save as temporary data file
      write.csv(ec_zip_raw,"06_neighborhoods/social-capital/data/social-capital-city-clean.csv", row.names = FALSE)

      

# (3)  merge with the 2010 ZCTA -> 2021 Census Place crosswalk
      
      # import the 2010 ZCTA -> 2021 Census Place crosswalk file
      ZCTA_Place <- read.csv("geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv")
      
      # clean up the crosswalk file to prepare for the merge:
      
      # rename the ZCTA abd state FIPS variables to avoid confusion
      ZCTA_Place <- ZCTA_Place %>% 
        rename("zip" = "ZCTA5CE10")
            # adjust the leading zeroes now
            ZCTA_Place$zip <- sprintf("%05d", as.numeric(ZCTA_Place$zip))
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("state" = "STATEFP")
            # adjust the leading zeroes now
            ZCTA_Place$state <- sprintf("%02d", as.numeric(ZCTA_Place$state))
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("place" = "PLACEFP")
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("place_name" = "NAMELSAD")
            
      
      # keep only the variables we will need
      ZCTA_Place <- ZCTA_Place %>% select(zip, state, place, place_name, IntersectArea, ZCTAinPlace)
      
      
      # merge the places crosswalk into the ec data file (left join, since places file has more observations)
      merged_ec_city <- merge(ZCTA_Place, ec_zip_raw, by=c("state", "zip"))
      

# (4)  collapse estimates to unique Places (include quality marker for number of observations collapsed)
      
      # create a new variable that tracks the number of ZCTAs falling in each Place (duplicates)
      merged_ec_city <- merged_ec_city %>% group_by(place, place_name) %>%
        mutate(num_ZCTAs_in_place = 1:n())
      
      # create the merged file where the EC variable (and its SE?) are averaged per Place, weighted by the % area of the ZCTA in that Place
      # and also include a sum of the duplicate tracker variable
      test2 <- merged_ec_city %>% 
              group_by(state, place_name) %>% 
              summarize(qual_marker = sum(num_ZCTAs_in_place), new_ec_zip = weighted.mean(ec_zip, ZCTAinPlace), new_ec_se_zip = weighted.mean(ec_se_zip, ZCTAinPlace))
      
      
# (5)  create data quality marker for number of observations collapsed)
      # (this is based on the quality of the merge/amount of weighting required)
              # Data Quality 1 = 1 ZCTA in the Place (perfect match)
              # Data Quality 2 = 2-5 ZCTAs in the Place
              # Data Quality 3 = 5+ ZCTAs in the Place
      
      test2 <- test2 %>%
        mutate(data_quality = case_when(qual_marker == 1 ~ 1,
                                        qual_marker > 1 & qual_marker <= 5 ~ 2,
                                        qual_marker > 5 ~ 3))
      
      
      
      # drop missing values
      test2 <- test2 %>% drop_na(new_ec_zip)
          # lost 1650 observations (21625 - 19975)
      
     
      
# (6)  check against Census Place file & limit to population cutoff Places

      # bring in the population-cutoff Place file
      places_pop <- read.csv("geographic-crosswalks/data/city_state_2020_population.csv")
      
      # rename & adapt variables to prepare for merge (state FIPS is called "state" in the data file, not "fips")
      places_pop <- places_pop %>% 
        rename("state" = "fips")
      places_pop$state <- sprintf("%02d", as.numeric(places_pop$state))
      test2 <- test2 %>%
        rename("cityname" = "place_name")
      
      # merge places_pop with data file in order to get final EC city data
      ec_city_data <- merge(places_pop, test2, by=c("cityname", "state"), all.x=TRUE)

      

# (7)  final file cleaning and export to csv file									   

      # remove the missing data
      ec_city_data <- ec_city_data %>% drop_na(new_ec_zip)
            # 168 missing observations (486-318)
            # 318 cities for which we have this data
      
      # keep only the variables we want
      ec_city_data <- ec_city_data %>% select(cityname, state, population2020, statename, state_abbr, new_ec_zip, new_ec_se_zip, data_quality)
      
      
      # rename the needed variable to avoid confusion
      ec_city_data <- ec_city_data %>% 
        rename("ec_zip" = "new_ec_zip")
      ec_city_data <- ec_city_data %>% 
        rename("ec_se_zip" = "new_ec_se_zip")
      
      # explort as .csv
      write_csv(ec_city_data, "06_neighborhoods/social-capital/final_data/economic_connectedness_city_2022.csv")
      

