###############################################################################

# Description: Code to create county-level Social Associatations ratio (one of two Social Capital Gates Mobility Metrics)  
# Data:  [gitfolder]/06_neighborhoods/social-capital/data/cbp20co.csv (won't be on Github)
# Data downloaded from: Census County Business Patterns 2020
# Author: Tina Chelidze											   
# Date: December 10, 2022

# (1)  download social organization data from https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html (this is the numerator)										
# (2)  import and clean the data file	
# (3)  download population data from ACS (this is the denominator)
# (4)  merge the data file(s) & construct the ratio (Numerator/Denominator)
# (5)  final file cleaning and export to .csv file	

###############################################################################

# Set working directory to [gitfolder]. Update path as necessary to your local metrics repo
setwd("C:/Users/tchelidze/Documents/GitHub/mobility-from-poverty")

# Libraries you'll need
library(sf)
library(tidyr)
library(dplyr)
library(readr)

# (1) download data from the Census County Business Patterns survey

#     access via https://www.census.gov/data/datasets/2020/econ/cbp/2020-cbp.html
#     import the text file into Excel to convert to CSV
#     cbp20co.csv is saved in [gitfolder]/06_neighborhoods/social-capital/data under the tina branch


# (2) import and clean the CBP data file 
# This means a) open the data, b) fill in fips missing zeroes, c) isolate to only the following NAICS, 
# d) collapse & keep only relevant variables, and e) add the year of these data
# codes: 813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, and 813920
# These are the codes/associations included in the County Health Rankings metric
# See here for more: https://www.countyhealthrankings.org/explore-health-rankings/county-health-rankings-model/health-factors/social-economic-factors/family-and-social-support/social-associations?year=2022


# a) open the data
        sa_raw <- read.csv("06_neighborhoods/social-capital/data/cbp20co.csv")

        
# b) fill in the fips missing zeroes
       
        # add in the lost leading zeroes for the state FIP
        sa_raw$fipstate <- sprintf("%02d", as.numeric(sa_raw$fipstate))
        
        # add in the lost leading zeroes for county FIP
        sa_raw$fipscty <- sprintf("%03d", as.numeric(sa_raw$fipscty))
  
        
# c) keep the NAICS organization codes we want
        keep = c(813410, 713950, 713910, 713940, 711211, 813110, 813940, 813930, 813910, 813920)
        sa_raw <- filter(sa_raw, naics %in% keep)
     
           
# d) collapse (aggregate org #s so there is only 1 value per county) & keep only relevant variables 
#    Note: "est" is the number of organizations (stands for establishments)
        
        # keep only relevant data
        sa_raw <- sa_raw %>% select(fipstate, fipscty, est)
        # remove observations with missing data for our orgs variable
        sa_raw %>% drop_na(est)
        
        # aggregate the total # of orgs per county
        sa_raw <- aggregate(.~ fipstate + fipscty, data=sa_raw, FUN=sum) 
            # 9462 observations to 2910 observations

        
# e) add the year of these data as a variable
        sa_raw$year <- "2020"


# (3)  download population data from ACS (this is the denominator)
      # no need to do this if we use our county file which already has these data
        pop_20 <- read.csv("geographic-crosswalks/data/county-populations.csv")
        
        # add in the lost leading zeroes for the state FIP & rename for merge
        pop_20$state <- sprintf("%02d", as.numeric(pop_20$state))
        pop_20 <- pop_20 %>% 
          rename("fipstate" = "state")
        
        # add in the lost leading zeroes for county FIP & rename for merge
        pop_20$county <- sprintf("%03d", as.numeric(pop_20$county))
        pop_20 <- pop_20 %>% 
          rename("fipscty" = "county")
        
        # keep the year we want
        keepyr = c(2020)
        pop_20 <- filter(pop_20, year %in% keepyr)
        
        # keep the variables we want
        pop_20 <- pop_20 %>% select(year, fipstate, fipscty, population)

        
        
# (4)  merge the data file(s) & construct the ratio (Numerator/Denominator)
        
        # merge the county pop file into the social associations file (left join, since county file has more observations)
        merged_sa <- merge(pop_20, sa_raw, by=c("fipstate", "fipscty"), all.x = TRUE)
        
        # clean up
        merged_sa <- merged_sa %>% select(year.x, fipstate, fipscty, est, population)
        merged_sa <- merged_sa %>% 
          rename("year" = "year.x")
        
        # create the Social Associations ratio metric (socassn)
            # The original calls for "Number of membership associations per 10,000 population"
            # so we first divide the population by 10,000
            merged_sa$popratio <- as.numeric(as.character(merged_sa$population)) / 10000
        
        merged_sa$socassn <- merged_sa$est / merged_sa$popratio
        
        # round the ratio metric to one decimal point (as they do in County Health Rankings)
        merged_sa$socassn <- round(merged_sa$socassn, digits = 1) 

    
# (5)  final file cleaning and export to .csv file	
        
        # data quality flag (we have no issues with this metric except overall missings)
          # this is so that the missing values transfer as missing values
        merged_sa$quality <- merged_sa$socassn / 1
          # this is replacing all non-missings with 1 
        merged_sa$quality[merged_sa$quality > 0] <- 1 
        
        # keep what we need
        merged_sa <- merged_sa %>% select(year, fipstate, fipscty, socassn, quality)

        # export our file as a .csv
        write_csv(merged_sa, "06_neighborhoods/social-capital/final_data/social_associations_county_2022.csv")
        
        
        
        