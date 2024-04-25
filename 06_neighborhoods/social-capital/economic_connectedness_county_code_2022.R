###############################################################################

# Description: Code to create county-level Economic Connectedness (one of two Social Capital Gates Mobility Metrics)  
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/    .csv (won't be on Github)
# Data downloaded from Opportunity Insights Social Capital Atlas
# Author: Tina Chelidze											   
# Date: September 10, 2022

# (1)  download data from socialcapital.org											
# (2)  import and clean the data file				   
# (3)  use crosswalk to check any missing counties	
# (4)  create a data quality tag
# (5)  final file cleaning and export to csv file	

###############################################################################
  
    # Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

    # Libraries you'll need
    library(sf)
    library(tidyverse)


# (1) download data from socialcapital.org
  
#     access via https://data.humdata.org/dataset/social-capital-atlas	

      # Specify URL where source data file is online
      url <- "https://data.humdata.org/dataset/85ee8e10-0c66-4635-b997-79b6fad44c71/resource/ec896b64-c922-4737-b759-e4bd7f73b8cc/download/social_capital_county.csv"
      
      # Specify destination where file should be saved (the .gitignore folder for your local branch)
      destfile <- "06_neighborhoods/social-capital/temp/social_capital_county.csv"
      
      # Import the data file & save locally
      download.file(url, destfile)
  

# (2) open and clean the file (separate county and state codes, fill in missing zeroes)
  
     # open data
      ec_raw <- read_csv("06_neighborhoods/social-capital/temp/social_capital_county.csv")

     # add leading zeroes where they are missing (2-digit state FIP + 3-digit county FIP  = 5 digit code)
      ec_raw <- ec_raw %>%
        mutate(county = sprintf("%0.5d", as.numeric(county)))
  
     # keep only relevant data
      ec_raw <- ec_raw %>% 
        select(county, county_name, ec_county, ec_se_county)
      
     # remove observations with missing data for our EC variable
      ec_raw <- ec_raw %>% 
        drop_na(ec_county)

     # rename the FIPS variable to avoid confusion
      ec_raw <- ec_raw %>% 
        rename(totalFIPS = county)

     # create a new column for the state & county FIPS & create year variable
      ec_raw <- ec_raw %>%
        mutate(
          state = str_sub(totalFIPS, start = 1, end = 2),
          county = str_sub(totalFIPS, start = 3, end = 5),
          year = 2022
        )
      
     # save as temporary data file in the same .gitignore folder
      write_csv(ec_raw,"06_neighborhoods/social-capital/temp/social-capital-county-clean.csv")
      

# (3)  use crosswalk to check any missing counties	
      
      # import the county file
      county_pop <- read_csv("geographic-crosswalks/data/county-populations.csv")
      
      # add in the lost leading zeroes for the county FIP
      county_pop <- county_pop %>%
        mutate(county = sprintf("%0.3d", as.numeric(county)))
      # add in the lost leading zeroes for the state FIP
      county_pop <- county_pop %>%
        mutate(state = sprintf("%0.2d", as.numeric(state)))

      # keep the most recent year of population data (not 2022, but 2020)
      county_pop <- filter(county_pop, year == 2020)
      
      # merge the county file into the ec data file (left join, since county file has more observations)
      merged_ec <- left_join(county_pop, ec_raw, by=c("state", "county"))
      # sort by state county
      merged_ec <- merged_ec %>%
        arrange(state, county)
      
      # check how many missing values (counties without EC data)
      sum(is.na(merged_ec$ec_county))
          # 126 counties without EC data

      
# (4)   create data quality flag and add confidence interval
      merged_ec <- merged_ec %>%
        mutate(data_quality = case_when(ec_county >= 0 ~ 1))
      
      merged_ec <- merged_ec %>%
        mutate(
          ec_se_county_lb = ec_county - qnorm(0.975) * ec_se_county,
          ec_se_county_ub = ec_county + qnorm(0.975) * ec_se_county
        )
      
# (5)   final file cleaning and export to csv file									   
      
      # keep only relevant data (dropping population data, keeping EC data year only)
      merged_ec <- merged_ec %>% 
        select(year.y, state, county, state_name, county_name.x, ec_county, ec_se_county_lb, ec_se_county_ub, data_quality)
      
      
      # rename the needed variable to avoid confusion
      merged_ec <- merged_ec %>% 
        rename(county_name = county_name.x)
      merged_ec <- merged_ec %>% 
        rename(year = year.y)
      merged_ec <- merged_ec %>% 
        rename(ec_county_quality = data_quality) %>%
        
      #G. Morrison addition March 2023 to clean table and prepare for join
        select(-c(state_name, county_name)) %>%
        rename(economic_connectedness = ec_county,
               economic_connectedness_quality = ec_county_quality,
               economic_connectedness_lb = ec_se_county_lb,
               economic_connectedness_ub = ec_se_county_ub)
      
      # export as .csv
      write_csv(merged_ec, "06_neighborhoods/social-capital/final/economic_connectedness_county_2022.csv")
      
      
      