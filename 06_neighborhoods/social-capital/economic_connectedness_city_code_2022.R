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
# (5)  check against official Census Place file & limit to population cutoff Places
# (6)  create data marker
# (7)  final file cleaning and export to csv file	

###############################################################################

# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)
library(tigris)


# (1) Download data from socialcapital.org

#     accessible via https://data.humdata.org/dataset/social-capital-atlas	
#     NOTE: in the paper (https://opportunityinsights.org/wp-content/uploads/2022/07/social-capital1_wp.pdf), they state that "Zip Codes" is shorthand for 2010 ZCTA designations
#     access via https://data.humdata.org/dataset/social-capital-atlas	

# Specify URL where source data file is online
url <- "https://data.humdata.org/dataset/85ee8e10-0c66-4635-b997-79b6fad44c71/resource/ab878625-279b-4bef-a2b3-c132168d536e/download/social_capital_zip.csv"

# Specify destination where file should be saved (the .gitignore folder for your local branch)
destfile <- "06_neighborhoods/social-capital/temp/social_capital_zip.csv"

# Import the data file & save locally
download.file(url, destfile)


# (2) Import and clean the file (separate county and state codes, fill in missing zeroes)

      # open data
      ec_zip_raw <- read.csv("06_neighborhoods/social-capital/temp/social_capital_zip.csv")

      # add leading zeroes where they are missing (ZCTA codes are 5 digits)
      ec_zip_raw <- ec_zip_raw %>%
        mutate(zip = sprintf("%0.5d", as.numeric(zip)))
      
      #add leading zeroes where they are missing for the concatenated FIPS (2 state + 3 county)
      ec_zip_raw <- ec_zip_raw %>%
        mutate(county = sprintf("%0.5d", as.numeric(county)))

      # keep only relevant data
      ec_zip_raw <- ec_zip_raw %>% 
        select(zip, county, ec_zip)

      # remove observations with missing data for our EC variable
      ec_zip_raw <- ec_zip_raw %>% 
        drop_na(ec_zip)
            ### There were 4048 missing observations deleted (23028 minus 18980)

      # rename the concatenated FIPS variable to avoid confusion
      ec_zip_raw <- ec_zip_raw %>% 
        rename("totalFIPS" = "county")

      # create a new column for the state FIPS
      ec_zip_raw$state <- as.numeric(substr(ec_zip_raw$totalFIPS, 1, 2))
      # add in the lost leading zeroes
      ec_zip_raw <- ec_zip_raw %>%
        mutate(state = sprintf("%0.2d", as.numeric(state)))
      # create a new column for the county FIPS
      ec_zip_raw$county <- as.numeric(substr(ec_zip_raw$totalFIPS, 3, 5))
      # add in the lost leading zeroes (county code should have 3 digits)
      ec_zip_raw <- ec_zip_raw %>%
        mutate(county = sprintf("%0.3d", as.numeric(county)))
      # create a column for the year of this data
      ec_zip_raw$year <- "2022"

      # save as temporary data file
      write_csv(ec_zip_raw,"06_neighborhoods/social-capital/temp/social-capital-city-clean.csv")

      

# (3)  Merge with the 2010 ZCTA -> 2021 Census Place crosswalk
      
      # import the 2010 ZCTA -> 2021 Census Place crosswalk file
      ZCTA_Place <- read_csv("geographic-crosswalks/data/2010_ZCTA_2021_Census_Places_Crosswalk.csv")
      
      # clean up the crosswalk file to prepare for the merge:
      
      # rename the ZCTA and state FIPS variables to avoid confusion
      ZCTA_Place <- ZCTA_Place %>% 
        rename("zip" = "ZCTA5CE10")
            # adjust the leading zeroes now
            ZCTA_Place <- ZCTA_Place %>%
              mutate(zip = sprintf("%0.5d", as.numeric(zip)))
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("state" = "STATEFP")
            # adjust the leading zeroes now
            ZCTA_Place <- ZCTA_Place %>%
              mutate(state = sprintf("%0.2d", as.numeric(state)))
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("place" = "PLACEFP")
            # adjust the leading zeroes now
            ZCTA_Place <- ZCTA_Place %>%
              mutate(place = sprintf("%0.5d", as.numeric(place)))
      
      ZCTA_Place <- ZCTA_Place %>% 
        rename("place_name" = "NAMELSAD")
      
      # make an indicator for ZIPs that fall wholly into a Place vs. partially (ZCTAinPlace < 1)
      ZCTA_Place <- ZCTA_Place %>%
        mutate(portionin = case_when(ZCTAinPlace == 1 ~ 1,
                                   ZCTAinPlace < 1 ~ 0))
      # check how many of these...
      sum(with(ZCTA_Place, portionin==1))
          # 2079 of these ZCTAs fall fully into a Census Place
      
      # find boundaries (I did not end up using this, but leaving it in)
      summary(ZCTA_Place)
          #mean=0.13, Q3=0.072
      # make an more detailed indicator for portion of ZIPs falling into each census place
      ZCTA_Place <- ZCTA_Place %>%
        mutate(mostlyin = case_when(ZCTAinPlace >= 0.5 ~ 1,
                                      ZCTAinPlace < 0.5 ~ 0))
      
      # keep only the variables we will need
      ZCTA_Place <- ZCTA_Place %>% select(zip, state, place, place_name, IntersectArea, ZCTAinPlace, portionin, mostlyin)
      
      # merge the ZIP/Places crosswalk into the ec data file (left join, since places file has more observations)
      merged_ec_city <- left_join(ZCTA_Place, ec_zip_raw, by=c("state", "zip"))
      
      # check if there are missings after the merge
      merged_ec_city <- merged_ec_city %>% drop_na(ec_zip)
          # No missings --> perfect match coverage. Number of obs stayed consistent at 54042

      

# (4)  Collapse estimates to unique Places 
      
      # Exploring options for data quality marker
      # create a new variable that tracks the number of ZCTAs falling in each Place (duplicates)
      merged_ec_city <- merged_ec_city %>% group_by(place, place_name) %>%
        mutate(num_ZCTAs_in_place = n())
      
      # create the merged file where the EC variable is averaged per Place (new_ec_zip_), weighted by the % area of the ZCTA in that Place
      # and also include total ZCTAs in Place & how many of those partially fall outside the Place 
      test2 <- merged_ec_city %>% 
              group_by(state, place_name) %>% 
              summarize(zip_total = mean(num_ZCTAs_in_place), zipsin = sum(portionin), new_ec_zip = weighted.mean(ec_zip, ZCTAinPlace))
      
      # drop missing values
      test2 <- test2 %>% drop_na(new_ec_zip)
          # lost 1915 observations (24967 minus 23052)
      
     
# (5) Check against Census Place file & limit to population cutoff Places

      # bring in the updated population-cutoff Places file
      places_pop <- read_csv("geographic-crosswalks/data/place-populations.csv")

      # adapt variables to prepare for merge 
      places_pop <- places_pop %>%
        mutate(state = sprintf("%0.2d", as.numeric(state)))
      
      # keep only 2020 data to prepare for merge (should leave us with 486 obs total)
      keep = c(2020)
      places_pop <- filter(places_pop, year %in% keep)
      
      # merge places_pop with data file in order to get final EC city data
      ec_city_data <- left_join(places_pop, test2, by=c("place_name", "state"))

      # check if there are missings
      ec_city_data <- ec_city_data %>% drop_na(new_ec_zip)
          # no missings!
      
      
# (6)  create data quality marker
      # create a ratio value to see how many of the ZIPs we aggregated fell fully into a Census Place boundary 
      ec_city_data <- ec_city_data %>%
        mutate(zipratio = zipsin/zip_total)
      # check the range on this
      summary(ec_city_data)
      # zipratio mean = 0, Q1 = 0, Q3 = 0.15
      
      # Data Quality 1 = 50% or more of the ZIPs fall mostly (>50%) in the census place 
      # Data Quality 2 = 15% to 50% of the ZIPs fall mostly (>50%) in the census place
      # Data Quality 3 = less than 15% of the ZIP falls mostly into the census place
      ec_city_data <- ec_city_data %>%
        mutate(data_quality = case_when(zipratio >= 0.5 ~ 1,
                                        zipratio < 0.5 & zipratio > 0.15 ~ 2,
                                        zipratio < 0.15 ~ 3))

# (7)  Final file cleaning and export to csv file									   

      # remove the missing data
#      ec_city_data <- ec_city_data %>% drop_na(new_ec_zip)
            # 168 missing observations (486 minus 318)
            # 318 cities for which we have this data
      
      # keep only the variables we want
      ec_city_data <- ec_city_data %>% select(year, state, place, place_name, new_ec_zip, data_quality)
      
      # rename the needed variable to avoid confusion
      ec_city_data <- ec_city_data %>% 
        rename("ec_zip" = "new_ec_zip")
      ec_city_data <- ec_city_data %>% 
        rename("_quality" = "data_quality")
      
      # explort as .csv
      write_csv(ec_city_data, "06_neighborhoods/social-capital/data/economic_connectedness_city_2022.csv")
      

