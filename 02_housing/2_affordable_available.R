###################################################################

# ACS Code: Affordable and available housing metric, subgroup
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# and code by Tina Chelidze in R for 2022-2023
# Process:
# (1) Housekeeping
# (2) Import microdata (PUMA Place combination already done)
# (3) Create a Vacant unit dataframe (vacant units will not be accounted for when we isolate households in Steps 4 & 5)
#     Note that to get vacant unit data, need to pull a separate extract from IPUMS; see instructions below.
#       (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:
#       (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#               This "total_monthly_cost" variable will be used to calculate affordability in Step 6
#       (3c) Now create accurate gross rent variable for vacant units for rent: 
#       (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#             vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per place).
#       (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#               This "RENTGRS" variable will be used to calculate affordability in Step 6
# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)
#       (4a) Merge the 2 files
#       (4b) Bring in county_place crosswalk
#       (4c) Merge FMR file with crosswalk on county
#       (4d) Create place_level_income_limits (weight by FMR population in collapse)
# (5) Generate households_2021: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)
# (6) Merge Vacant with place_level_income_limits
#       (6a) create same 30%, 50%, and 80% AMI affordability indicators
# (7) Create the housing metric
#       (7a) Summarize households_2021 and vacant both by place
#       (7b) Merge them by place
#       (7c) Calculate share_affordable_30/50/80AMI
# (8) Create Data Quality marker
# (9) Clean and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(tidyverse)
library(ipumsr)
library(readxl)

###################################################################

# (2) Import housing affordability data (created in housing.R)

# (2a) Import files

# Either run "housing.R" OR: Import the already prepared housing affordability and vacancy files 

households_2021 <- read_csv("data/temp/households_2021.csv")

vacant_2021 <- read_csv("data/temp/vacant_2021.csv")

# (2b) Combine into one 

housing_full <- left_join(households_2021, vacant_2021)

###################################################################
# (3) Filter data to only rental units (OWNERSHP == 2) or units that are vacant-for-rent (VACANCY == 1)


############################### FOR INDICATOR #9 ############################### 

### Reset workspace so that exported tables/graphs go to correct folder
setwd("G:/Planning/OPCD Research & Analysis/EDI Monitoring/HDRI/Data/2023 Data Update")

### Filters data to only rental units (OWNERSHP == 2) or units that are vacant-for-rent (VACANCY == 1)
renters <- data %>% filter(OWNERSHP == 2 | data$VACANCY == 1)
### Filters renters to only units with full kitchen and plumbing
renters <- renters %>% filter(renters$KITCHEN == 4 & renters$PLUMBING == 20) ###Full kitchen & plumbing

### View resulting table
View(renters)

### Creates a list of all the years with data, which will be referred to throughout this script
years <- min(renters$YEAR):max(renters$YEAR)

### Creates blank table which will ultimately show the supply/demand for housing units affordable at each standard income bracket
market <- as.data.frame(matrix(nrow = 5*length(years), ncol = 10))
### Names columns in table
colnames(market) <- c("INCOME", "YEAR", "SUPPLY", "SUPPLY_TOTAL", "SUPPLY_PERCENT", "SUPPLY_CUMULATIVE", "DEMAND", "DEMAND_TOTAL", "DEMAND_PERCENT", "DEMAND_CUMULATIVE")

### Names income brackets and converts to a "factor" so they will appear in the correct order on graphs
market$INCOME <- rep(c("0 - 30%", "30 - 50%", "50 - 80%", "80 - 120%", "Above 120%"), length(years))
market$INCOME <- factor(market$INCOME, levels = c("0 - 30%", "30 - 50%", "50 - 80%", "80 - 120%", "Above 120%"), ordered = TRUE) 
### Fills in "YEAR" column with all available years
market$YEAR <- rep(min(years):max(years), each = 5)

### Fills in number of units renting for each income bracket in each year (SUPPLY) and the number of households in each income bracket (DEMAND)
### Loops through these calculations for each year individually
for (year in years){
  ###Fills in number of housing units in given rent bracket for the specified year
  market$SUPPLY[market$INCOME == "0 - 30%" & market$YEAR == year] <- sum(renters$HHWT[renters$RHUD30 == 1 & renters$YEAR == year])
  market$SUPPLY[market$INCOME == "30 - 50%" & market$YEAR == year] <- sum(renters$HHWT[renters$RHUD50 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$RHUD30 == 1 & renters$YEAR == year])
  market$SUPPLY[market$INCOME == "50 - 80%" & market$YEAR == year] <- sum(renters$HHWT[renters$RHUD80 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$RHUD50 == 1 & renters$YEAR == year])
  market$SUPPLY[market$INCOME == "80 - 120%" & market$YEAR == year] <- sum(renters$HHWT[renters$RHUD120 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$RHUD80 == 1 & renters$YEAR == year])
  market$SUPPLY[market$INCOME == "Above 120%" & market$YEAR == year] <- sum(renters$HHWT[renters$RHUD120 == 0 & renters$YEAR == year])
  
  ###Fills in total number of housing units during the given year (regardless of gross rent)
  market$SUPPLY_TOTAL[market$YEAR == year] <- sum(renters$HHWT[renters$YEAR == year])
  
  ###Fills in number of households in given income bracket for the specified year
  market$DEMAND[market$INCOME == "0 - 30%" & market$YEAR == year] <- sum(renters$HHWT[renters$AMI30 == 1 & renters$YEAR == year])
  market$DEMAND[market$INCOME == "30 - 50%" & market$YEAR == year] <- sum(renters$HHWT[renters$AMI50 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$AMI30 == 1 & renters$YEAR == year])
  market$DEMAND[market$INCOME == "50 - 80%" & market$YEAR == year] <- sum(renters$HHWT[renters$AMI80 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$AMI50 == 1 & renters$YEAR == year])
  market$DEMAND[market$INCOME == "80 - 120%" & market$YEAR == year] <- sum(renters$HHWT[renters$AMI120 == 1 & renters$YEAR == year])-sum(renters$HHWT[renters$AMI80 == 1 & renters$YEAR == year])
  market$DEMAND[market$INCOME == "Above 120%" & market$YEAR == year] <- sum(renters$HHWT[renters$AMI120 == 0 & renters$YEAR == year])
  
  ###Fills in total number of households during the given year (regardless of income)
  market$DEMAND_TOTAL[market$YEAR == year] <- sum(renters$HHWT[renters$VACANCY == 0 & renters$YEAR == year])
}

### Calculates proportion of TOTAL housing market falling into each income bracket
market$SUPPLY_PERCENT <- market$SUPPLY/market$SUPPLY_TOTAL
market$DEMAND_PERCENT <- market$DEMAND/market$DEMAND_TOTAL

### Calculates position values for graph labels
market$SUPPLY_CUMULATIVE <- ifelse(market$INCOME == "0 - 30%", market$SUPPLY, NA)
market$SUPPLY_CUMULATIVE <- ifelse(market$INCOME == "30 - 50%", market$SUPPLY + lag(market$SUPPLY, 1), market$SUPPLY_CUMULATIVE)
market$SUPPLY_CUMULATIVE <- ifelse(market$INCOME == "50 - 80%", market$SUPPLY + lag(market$SUPPLY, 1) + lag(market$SUPPLY, 2), market$SUPPLY_CUMULATIVE)
market$SUPPLY_CUMULATIVE <- ifelse(market$INCOME == "80 - 120%", market$SUPPLY + lag(market$SUPPLY, 1) + lag(market$SUPPLY, 2) + lag(market$SUPPLY, 3), market$SUPPLY_CUMULATIVE)
market$SUPPLY_CUMULATIVE <- ifelse(market$INCOME == "Above 120%", market$SUPPLY + lag(market$SUPPLY, 1) + lag(market$SUPPLY, 2) + lag(market$SUPPLY, 3) + lag(market$SUPPLY, 4), market$SUPPLY_CUMULATIVE)
market$DEMAND_CUMULATIVE <- ifelse(market$INCOME == "0 - 30%", market$DEMAND, NA)
market$DEMAND_CUMULATIVE <- ifelse(market$INCOME == "30 - 50%", market$DEMAND + lag(market$DEMAND, 1), market$DEMAND_CUMULATIVE)
market$DEMAND_CUMULATIVE <- ifelse(market$INCOME == "50 - 80%", market$DEMAND + lag(market$DEMAND, 1) + lag(market$DEMAND, 2), market$DEMAND_CUMULATIVE)
market$DEMAND_CUMULATIVE <- ifelse(market$INCOME == "80 - 120%", market$DEMAND + lag(market$DEMAND, 1) + lag(market$DEMAND, 2) + lag(market$DEMAND, 3), market$DEMAND_CUMULATIVE)
market$DEMAND_CUMULATIVE <- ifelse(market$INCOME == "Above 120%", market$DEMAND + lag(market$DEMAND, 1) + lag(market$DEMAND, 2) + lag(market$DEMAND, 3) + lag(market$DEMAND, 4), market$DEMAND_CUMULATIVE)

### Exports full table as CSV
write.csv(market, "Market.csv", row.names = FALSE)

### Exports table showing total number of housing units in each rent bracket, with each rent bracket as a different column (for AGOL)
write.csv(market %>% select(YEAR, INCOME, SUPPLY) %>% spread(INCOME, SUPPLY, fill = 0), "Market_Supply.csv", row.names = FALSE)
### Exports table showing percent of housing units in each rent bracket, with each rent bracket as a different column (for AGOL)
write.csv(market %>% select(YEAR, INCOME, SUPPLY_PERCENT) %>% spread(INCOME, SUPPLY_PERCENT, fill = 0), "Market_Supply_Percent.csv", row.names = FALSE)
### Exports table showing total number of households in each income bracket, with each income bracket as a different column (for AGOL)
write.csv(market %>% select(YEAR, INCOME, DEMAND) %>% spread(INCOME, DEMAND, fill = 0), "Market_Demand.csv", row.names = FALSE)
### Exports table showing total number of households in each income bracket, with each income bracket as a different column (for AGOL)
write.csv(market %>% select(YEAR, INCOME, DEMAND_PERCENT) %>% spread(INCOME, DEMAND_PERCENT, fill = 0), "Market_Demand_Percent.csv", row.names = FALSE)

############
############
############

### Creates blank table which will ultimately show the supply of housing units affordable and available at each standard income bracket
AA <- as.data.frame(matrix(nrow = 9*4*length(years), ncol = 5))
### Names columns in table
colnames(AA) <- c("INCOME", "CATEGORIES", "YEAR", "VALUE", "CUMULATIVE")

### Names income brackets
AA$INCOME <- rep(c("0 - 30%", "0 - 50%", "0 - 60%", "0 - 80%", "0 - 100%", "0 - 120%", "0 - 150%", "0 - 200%", "All Renters"), each = 4*length(years))
AA$INCOME <- factor(AA$INCOME, levels = c("0 - 30%", "0 - 50%", "0 - 60%", "0 - 80%", "0 - 100%", "0 - 120%", "0 - 150%", "0 - 200%", "All Renters"), ordered = TRUE)

### Creates affordability/availability categories
AA$CATEGORIES <- c("Vacant", "Affordable/Available (Not Rent Burdened)", "Affordable/Available (Rent Burdened)", "Affordable/Unavailable")
AA$CATEGORIES <- factor(AA$CATEGORIES, levels = c("Affordable/Unavailable", "Affordable/Available (Rent Burdened)", "Affordable/Available (Not Rent Burdened)", "Vacant"), ordered = TRUE) 

### Fills in "YEAR" column with all available years
AA$YEAR <- rep(min(years):max(years), each = 4)

### Creates one graph for each year, showing supply of units per 100 renting households at a variety of income levels
for (year in years) {
  ### Filters data by year
  renters1 <- renters %>% filter(YEAR == year)
  
  ### For given income bracket (in this case, 0-30% AMI), calculates the TOTAL population at that AMI (POP), the number with that AMI renting at an affordable level (ATRENT),
  ### and the number of units affordable at AMI being rented by people with a higher AMI (DOWNRENT).
  ### From there, calculates the following:
  ### Number of vacant units affordable at AMI per 100 renting households
  ### Number of occupied units affordable at AMI where the occupants are paying <30% of their income on housing costs, per 100 renting households
  ### Number of occupied units affordable at AMI where occupants are nonetheless paying >=30% of their income on housing costs, per 100 renting households
  ### Number of occupied units affordable at AMI rented by occupants at a higher AMI, per 100 renting households
  
  POP30 <- sum(renters1$HHWT[renters1$AMI30 == 1])
  ATRENT30 <- sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$VACANCY == 0])
  DOWNRENT30 <- sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$VACANCY == 1])/POP30)
  AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP30)
  AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP30)
  AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year] <- 100*(DOWNRENT30/POP30)
  
  POP50 <- sum(renters1$HHWT[renters1$AMI50 == 1])
  ATRENT50 <- sum(renters1$HHWT[renters1$RHUD50 == 1 & renters1$AMI50 == 1 & renters1$VACANCY == 0])
  DOWNRENT50 <- sum(renters1$HHWT[renters1$RHUD50 == 1 & renters1$AMI50 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 50%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD50 == 1 & renters1$VACANCY == 1])/POP50)
  AA$VALUE[AA$INCOME == "0 - 50%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD50 == 1 & renters1$AMI50 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP50)
  AA$VALUE[AA$INCOME == "0 - 50%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD50 == 1 & renters1$AMI50 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP50)
  AA$VALUE[AA$INCOME == "0 - 50%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year] <- 100*(DOWNRENT50/POP50)
  
  POP60 <- sum(renters1$HHWT[renters1$AMI60 == 1])
  ATRENT60 <- sum(renters1$HHWT[renters1$RHUD60 == 1 & renters1$AMI60 == 1 & renters1$VACANCY == 0])
  DOWNRENT60 <- sum(renters1$HHWT[renters1$RHUD60 == 1 & renters1$AMI60 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 60%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD60 == 1 & renters1$VACANCY == 1])/POP60)
  AA$VALUE[AA$INCOME == "0 - 60%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD60 == 1 & renters1$AMI60 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP60)
  AA$VALUE[AA$INCOME == "0 - 60%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD60 == 1 & renters1$AMI60 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP60)
  AA$VALUE[AA$INCOME == "0 - 60%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year] <- 100*(DOWNRENT60/POP60)
  
  POP80 <- sum(renters1$HHWT[renters1$AMI80 == 1])
  ATRENT80 <- sum(renters1$HHWT[renters1$RHUD80 == 1 & renters1$AMI80 == 1 & renters1$VACANCY == 0])
  DOWNRENT80 <- sum(renters1$HHWT[renters1$RHUD80 == 1 & renters1$AMI80 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 80%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD80 == 1 & renters1$VACANCY == 1])/POP80)
  AA$VALUE[AA$INCOME == "0 - 80%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD80 == 1 & renters1$AMI80 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP80)
  AA$VALUE[AA$INCOME == "0 - 80%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD80 == 1 & renters1$AMI80 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP80)
  AA$VALUE[AA$INCOME == "0 - 80%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year]  <- 100*(DOWNRENT80/POP80)
  
  POP100 <- sum(renters1$HHWT[renters1$AMI100 == 1])
  ATRENT100 <- sum(renters1$HHWT[renters1$RHUD100 == 1 & renters1$AMI100 == 1 & renters1$VACANCY == 0])
  DOWNRENT100 <- sum(renters1$HHWT[renters1$RHUD100 == 1 & renters1$AMI100 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 100%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD100 == 1 & renters1$VACANCY == 1])/POP100)
  AA$VALUE[AA$INCOME == "0 - 100%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD100 == 1 & renters1$AMI100 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP100)
  AA$VALUE[AA$INCOME == "0 - 100%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD100 == 1 & renters1$AMI100 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP100)
  AA$VALUE[AA$INCOME == "0 - 100%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year]  <- 100*(DOWNRENT100/POP100)
  
  POP120 <- sum(renters1$HHWT[renters1$AMI120 == 1])
  ATRENT120 <- sum(renters1$HHWT[renters1$RHUD120 == 1 & renters1$AMI120 == 1 & renters1$VACANCY == 0])
  DOWNRENT120 <- sum(renters1$HHWT[renters1$RHUD120 == 1 & renters1$AMI120 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 120%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD120 == 1 & renters1$VACANCY == 1])/POP120)
  AA$VALUE[AA$INCOME == "0 - 120%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD120 == 1 & renters1$AMI120 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP120)
  AA$VALUE[AA$INCOME == "0 - 120%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD120 == 1 & renters1$AMI120 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP120)
  AA$VALUE[AA$INCOME == "0 - 120%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year]  <- 100*(DOWNRENT120/POP120)
  
  POP150 <- sum(renters1$HHWT[renters1$AMI150 == 1])
  ATRENT150 <- sum(renters1$HHWT[renters1$RHUD150 == 1 & renters1$AMI150 == 1 & renters1$VACANCY == 0])
  DOWNRENT150 <- sum(renters1$HHWT[renters1$RHUD150 == 1 & renters1$AMI150 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 150%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD150 == 1 & renters1$VACANCY == 1])/POP150)
  AA$VALUE[AA$INCOME == "0 - 150%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD150 == 1 & renters1$AMI150 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP150)
  AA$VALUE[AA$INCOME == "0 - 150%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD150 == 1 & renters1$AMI150 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP150)
  AA$VALUE[AA$INCOME == "0 - 150%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year]  <- 100*(DOWNRENT150/POP150)
  
  POP200 <- sum(renters1$HHWT[renters1$AMI200 == 1])
  ATRENT200 <- sum(renters1$HHWT[renters1$RHUD200 == 1 & renters1$AMI200 == 1 & renters1$VACANCY == 0])
  DOWNRENT200 <- sum(renters1$HHWT[renters1$RHUD200 == 1 & renters1$AMI200 == 0 & renters1$VACANCY == 0])
  AA$VALUE[AA$INCOME == "0 - 200%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD200 == 1 & renters1$VACANCY == 1])/POP200)
  AA$VALUE[AA$INCOME == "0 - 200%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD200 == 1 & renters1$AMI200 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP200)
  AA$VALUE[AA$INCOME == "0 - 200%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD200 == 1 & renters1$AMI200 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP200)
  AA$VALUE[AA$INCOME == "0 - 200%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year]  <- 100*(DOWNRENT200/POP200)
  
  POP <- sum(renters1$HHWT)
  AA$VALUE[AA$INCOME == "All Renters" & AA$CATEGORIES == "Vacant" & AA$YEAR == year]  <- 100*(sum(renters1$HHWT[renters1$VACANCY == 1])/POP)
  AA$VALUE[AA$INCOME == "All Renters" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP)
  AA$VALUE[AA$INCOME == "All Renters" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP)
  
  AA$CUMULATIVE <- ifelse(AA$CATEGORIES == "Vacant", AA$VALUE, NA)
  AA$CUMULATIVE <- ifelse(AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)", AA$VALUE + lag(AA$VALUE, 1), AA$CUMULATIVE)
  AA$CUMULATIVE <- ifelse(AA$CATEGORIES == "Affordable/Available (Rent Burdened)", AA$VALUE + lag(AA$VALUE, 1) + lag(AA$VALUE, 2), AA$CUMULATIVE)
  AA$CUMULATIVE <- ifelse(AA$CATEGORIES == "Affordable/Unavailable", AA$VALUE + lag(AA$VALUE, 1) + lag(AA$VALUE, 2) + lag(AA$VALUE, 3), AA$CUMULATIVE)
}

### Exports table combining all years
write.csv(AA, "Affordability_Full.csv", row.names = FALSE)

### Exports table with each column as a separate affordability/availability category (for ArcGIS Online), 
### with all four separate categories as well as two compressed categories (Affordable/Available or Affordable/Unavailable)
write.csv(AA %>% select(INCOME, CATEGORIES, YEAR, VALUE) %>% 
            spread(CATEGORIES, VALUE, fill = 0) %>% 
            mutate(`Affordable/Available` = `Vacant` + `Affordable/Available (Not Rent Burdened)` + `Affordable/Available (Rent Burdened)`), "Affordability.csv", row.names = FALSE)
