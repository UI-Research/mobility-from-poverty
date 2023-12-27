###################################################################

# ACS Code: Affordable and available housing metric, subgroup
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by the Seattle Office of Planning & Community Dev
# for the displacement risk indicators

# Definitions of AFFORDABILITY and AVAILABILITY from page 20: 
# https://www.huduser.gov/portal/sites/default/files/pdf/Worst-Case-Housing-Needs-2021.pdf

# • Affordability measures the extent to which enough rental housing units of different costs
# can provide each renter household with a unit it can afford (based on the 30-percent-of-income standard). 
# Affordability, which is the broadest measure of the relative supply of the housing stock, addresses whether sufficient housing
# units would exist if allocated solely on the basis of cost. The affordable stock includes both
# vacant and occupied units.

# • Availability measures the extent to which affordable rental housing units are available
# to renters within a particular income range. Availability is a more restrictive concept because
# units that meet the definition must be available and affordable. Some renters choose to spend
# less than 30 percent of their incomes on rent, occupying housing that is affordable to renters of
# lower incomes. Those units thus are not available to lower-income renters. A unit is available at a
# given level of income if (1) it is affordable at that level, and (2) it is occupied by a renter either at
# that income level or at a lower level or is vacant. 


# Process:
# (1) Housekeeping
# (2) Import housing affordability measures calculated in 1_housing.R
# (3) AT rent and down rent -  A unit is available at a given level of income if (1) it is affordable at that
#     level, and (2) it is occupied by a renter either at that income level or at a lower level or is vacant. 
#     (3a) Calculate TOTAL population at each income level: 30AMI, 50AMI, 80AMI
#     (3a) Calculate the population at each AMI renting or owning at an affordable level (ATRENT)
#     (3b) Calculate number of units affordable at AMI being rented by people with a higher AMI (DOWNRENT)
#     (3c) Summarize ATRENT, DOWNRENT, and number of households/units in each income threshold by place
# (4) calculate the number of affordable and available units at each income level per 100 households
# (5) Create the Data Quality variable


# (6) Affordability and availability metrics 
#     (6a) Number of vacant units affordable at AMI per 100 renting households
#     (6b) Number of occupied units affordable at AMI where the occupants are paying <30% of their income on housing costs, per 100 renting households
#     (6c) Number of occupied units affordable at AMI where occupants are nonetheless paying >=30% of their income on housing costs, per 100 renting households
#     (6d) Number of occupied units affordable at AMI rented by occupants at a higher AMI, per 100 renting households

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
library(skimr)

###################################################################

# (2) Import housing affordability data (created in housing.R)

# Either run "housing.R" OR: Import the already prepared housing affordability and vacancy files 

# this file is at the household level still so we can 
# calculate the availability metric
households_2022 <- read_csv("data/temp/households_2022.csv")

# this file is at the place level for calculating the overall number
# of affordable and available units per 100 households in step XX
vacant_summed_2022 <- read_csv("data/temp/vacant_summed_2022.csv")

###################################################################

# (3) Availability -  A unit is available at a given level of income if (1) it is affordable at that
#     level, and (2) it is occupied by a renter either at that income level or at a lower level or is vacant. 
#     
#    -  supply is number of housing units in each income bracket. 
#         This is calculated in step 5 of the housing.R file (variables: Affordable80AMI_all, Affordable80AMI_renter, Affordable80AMI_owner)
#    -  demand is number of households in each income bracket 
#         This is calculated in step 5 of the housing.R file (variables: below80AMI, below50AMI, below30AMI)

#    (3a) Calculate the "at rent" number of units occupied at the appropriate income level or a lower level
#         Do this for all units, and for renter and owner subgroups 
#         e.g., unit is affordable at 30 AMI and household is below 30 AMI and the unit is occupied (include vacancy in step 4)


available_2022 <- households_2022 %>% 
  mutate(
    # AT RENT 30% AMI
    at_rent30_all = if_else(Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent30_renter = if_else(OWNERSHP == 2 & Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0),
    at_rent30_owner = if_else(OWNERSHP == 1 & Affordable30AMI_all == 1 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    # AT RENT 50% AMI
    at_rent50_all = if_else(Affordable50AMI_all == 1 & Below50AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent50_renter = if_else(OWNERSHP == 2 & Affordable50AMI_all == 1 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    at_rent50_owner = if_else(OWNERSHP == 1 & Affordable50AMI_all == 1 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    # AT RENT 80% AMI
    at_rent80_all = if_else(Affordable80AMI_all == 1 & Below80AMI == 1 & VACANCY == 0, 1, 0), 
    at_rent80_renter = if_else(OWNERSHP == 2 & Affordable80AMI_all == 1 & Below80AMI == 1  & VACANCY == 0, 1, 0),
    at_rent80_owner = if_else(OWNERSHP == 1 & Affordable80AMI_all == 1 & Below80AMI == 1  & VACANCY == 0, 1, 0), 
    
    # DOWN RENT 30% AMI 
    down_rent30_all = if_else(Affordable30AMI_all == 1 & Below30AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent30_renter = if_else(OWNERSHP == 2 & Affordable30AMI_all == 0 & Below30AMI == 1 & VACANCY == 0, 1, 0),
    down_rent30_owner = if_else(OWNERSHP == 1 & Affordable30AMI_all == 0 & Below30AMI == 1 & VACANCY == 0, 1, 0), 
    # DOWN RENT 50% AMI
    down_rent50_all = if_else(Affordable50AMI_all == 1 & Below50AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent50_renter = if_else(OWNERSHP == 2 & Affordable50AMI_all == 0 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    down_rent50_owner = if_else(OWNERSHP == 1 & Affordable50AMI_all == 0 & Below50AMI == 1  & VACANCY == 0, 1, 0),
    # DOWN RENT 80% AMI
    down_rent80_all = if_else(Affordable80AMI_all == 1 & Below80AMI == 0 & VACANCY == 0, 1, 0), 
    down_rent80_renter = if_else(OWNERSHP == 2 & Affordable80AMI_all == 0 & Below80AMI == 1  & VACANCY == 0, 1, 0),
    down_rent80_owner = if_else(OWNERSHP == 1 & Affordable80AMI_all == 0 & Below80AMI == 1  & VACANCY == 0, 1, 0)) 


# (3b) Summarize at_rent for each subgroup and number of units/households at each
#       income threshold by place
available_2022 <- available_2022 %>% 
  group_by(statefip, place) %>% 
  dplyr::summarise(across(matches("Below|Affordable|down_|at_"), ~sum(.x*HHWT, na.rm = TRUE)), 
                   HHobs_count = n()) %>% 
  rename("state" = "statefip") %>% 
  ungroup()

# test that the down rent and at rent values sum to the affordable value at each income bracket
available_2022 %>% 
  mutate(combine_rent = rowSums(select(.,"at_rent30_all", "down_rent30_all"), na.rm = TRUE), 
         rent_dif = Affordable30AMI_all - combine_rent) %>% 
  summary(rent_dif)

###################################################################
# (4) calculate the number of affordable and available units at each income level per 100 households
# this is the number of units that are rented to people at or below each income threshold
# plus the number of vacant units at that income threshold over the total number
# of households in each income bracket
available_2022_final <- available_2022 %>% 
  # join in vacancy data
  left_join(vacant_summed_2022, by = c("state", "place")) %>% 
  mutate(
    # number of affordable and available at 30 AMI per 100 households
    share_affordable_available_30ami_all = (at_rent30_all+Affordable30AMI_all_vacant)/Below30AMI*100, 
    share_affordable_available_30ami_renter = (at_rent30_renter+Affordable30AMI_renter_vacant)/Below30AMI*100, 
    share_affordable_available_30ami_owner = (at_rent30_owner+Affordable30AMI_owner_vacant)/Below30AMI*100, 
    
    # number of affordable and available at 50 AMI per 100 households
    share_affordable_available_50ami_all = (at_rent50_all+Affordable50AMI_all_vacant)/Below50AMI*100, 
    share_affordable_available_50ami_renter = (at_rent50_renter+Affordable50AMI_renter_vacant)/Below50AMI*100, 
    share_affordable_available_50ami_owner = (at_rent50_owner+Affordable50AMI_owner_vacant)/Below50AMI*100, 
    
    # number affordable and available at 80 AMI per 100 households
    share_affordable_available_80ami_all = (at_rent80_all+Affordable80AMI_all_vacant)/Below80AMI*100, 
    share_affordable_available_80ami_renter = (at_rent80_renter+Affordable80AMI_renter_vacant)/Below80AMI*100, 
    share_affordable_available_80ami_owner = (at_rent80_owner+Affordable80AMI_owner_vacant)/Below80AMI*100
    )

###################################################################

# (5) Create the Data Quality variable

# For Housing metric: total number of HH below 50% AMI (need to add HH + vacant units)
# Create a "Size Flag" for any place-level observations made off of less than 30 observed HH, vacant or otherwise
available_2022_final <- available_2022_final %>% 
  mutate(affordableHH_sum = HHobs_count + vacantHHobs_count,
         size_flag = case_when((affordableHH_sum < 30) ~ 1,
                               (affordableHH_sum >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
place_puma <- read_csv("data/temp/place_puma.csv")

place_puma <- place_puma %>% 
  rename("state" = "statefip")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
available_2022_final <- left_join(available_2022_final, place_puma, by=c("state","place"))

# Generate the quality var (naming it housing_quality to match Kevin's notation from 2018)
available_2022_final <- available_2022_final %>% 
  mutate(housing_quality = case_when(size_flag==0 & puma_flag==1 ~ 1, # 239 obs
                                     size_flag==0 & puma_flag==2 ~ 2, # 239 obs
                                     size_flag==0 & puma_flag==3 ~ 3, # 7 obs
                                     size_flag==1 ~ 3))

###################################################################

# (6) Clean and export

# (6a) subgroup file
# turn long for subgroup output
available_2022_subgroup <- available_2022_final %>%
  select(state, place, starts_with("share_affordable_"), housing_quality) %>% 
  # create year variable
  mutate(year = 2022) %>% 
  # seperate share_afforadable by AMI and the subgroup
  pivot_longer(cols = c(contains("share_affordable")), 
               names_to = c("available", "subgroup"),
               names_pattern = "(.+?(?=_[^_]+$))(_[^_]+$)", # this creates two columns - "share_affordable_XXAMI" and "_owner/_renter/_all"
               values_to = "value") %>% 
  # pivot_wider again so that each share_affordable by AMI is it's own column with subgroups as rows
  pivot_wider(
    names_from = available, 
    values_from = value
  ) %>% 
  # clean subgroup names and add subgroup type column 
  # remove leading underscore and capitalize words
  mutate(subgroup = str_remove(subgroup, "_") %>% str_to_title(),
         subgroup_type = "renter-owner" )

# (6b) overall file
# keep what we need
available_2022_overall <- available_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  select(year, state, place, share_affordable_available_80ami, share_affordable_available_50ami, share_affordable_available_30ami, housing_quality) %>% 
  arrange(year, state, place)

###################################################################

# (7) Quality check tests - see if state trends match 
#   National Low Income Housing Coalition Report - https://nlihc.org/gap

# this is a really rough comparison since there isn't really local level data for this measure
# so I'm using the 2021 report state level numbers to snif test our results
# the NLIHC report has state level numbers for the number of units that are
# affordable and available for 30AMI households and the range is 17 to 58
# our range is 21 to 59 

state_av <- available_2022_subgroup %>% 
  filter(subgroup == "All") %>% 
  group_by(state) %>% 
  summarise(across(starts_with("share_affordable"), 
                   ~ mean(.x, na.rm = TRUE))) 


range(state_av$share_affordable_available_30ami)


# For Housing metric: total number of HH below 50% AMI (need to add HH + vacant units)
# Create a "Size Flag" for any place-level observations made off of less than 30 observed HH, vacant or otherwise
housing_2022 <- housing_2022 %>% 
  mutate(affordableHH_sum = HHobs_count + vacantHHobs_count,
         size_flag = case_when((affordableHH_sum < 30) ~ 1,
                               (affordableHH_sum >= 30) ~ 0))

# bring in the PUMA flag file if you have not run "0_microdata.R" before this
place_puma <- read_csv("data/temp/place_puma.csv")

place_puma <- place_puma %>% 
  rename("state" = "statefip")

# Merge the PUMA flag in & create the final data quality metric based on both size and puma flags
housing_2022 <- left_join(housing_2022, place_puma, by=c("state","place"))

# Generate the quality var (naming it housing_quality to match Kevin's notation from 2018)
housing_2022 <- housing_2022 %>% 
  mutate(housing_quality = case_when(size_flag==0 & puma_flag==1 ~ 1, # 220 obs
                                     size_flag==0 & puma_flag==2 ~ 2, # 247 obs
                                     size_flag==0 & puma_flag==3 ~ 3, # 19 obs
                                     size_flag==1 ~ 3))


temp <- households_2022 %>% 
  select(matches("at_rent|down_rent")) %>% 
  # seperate share_afforadable by AMI and the subgroup
  pivot_longer(cols = c(contains("at_rent")), 
               names_to = c("available", "subgroup"),
               names_pattern = "(.*rent)(\\d{2})", # this creates two columns - "share_affordable_XXAMI" and "_owner/_renter/_all"
               values_to = "value")  
# pivot_wider again so that each share_affordable by AMI is it's own column with subgroups as rows
pivot_wider(
  names_from = available, 
  values_from = value
) 
# clean subgroup names and add subgroup type column 
# remove leading underscore and capitalize words
mutate(subgroup = str_remove(subgroup, "_") %>% str_to_title(),
       subgroup_type = "renter-owner" )
ggplot() %>% 
  geom_histogram(aes(at_r))


POP30 <- sum(renters1$HHWT[renters1$AMI30 == 1])
ATRENT30 <- sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$VACANCY == 0])
DOWNRENT30 <- sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 0 & renters1$VACANCY == 0])
AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Vacant" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$VACANCY == 1])/POP30)
AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Available (Not Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$BURDEN30 == 0 & renters1$VACANCY == 0])/POP30)
AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Available (Rent Burdened)" & AA$YEAR == year] <- 100*(sum(renters1$HHWT[renters1$RHUD30 == 1 & renters1$AMI30 == 1 & renters1$BURDEN30 == 1 & renters1$VACANCY == 0])/POP30)
AA$VALUE[AA$INCOME == "0 - 30%" & AA$CATEGORIES == "Affordable/Unavailable" & AA$YEAR == year] <- 100*(DOWNRENT30/POP30)


#     (5b) Calculate the population at each AMI renting or owning at an affordable level (ATRENT)
#     (5c) Calculate number of units affordable at AMI being rented by people with a higher AMI (DOWNRENT)
#     (5a) Number of people at 30AMI 
#         - At rent: renter is 30% of AMI and housing unit is 30% of AMI q
#     (5b) Number of people at 50AMI 
#     (5c) Number of people at 80AMI 

# (6) Affordability and availability metrics 
#     (6a) Number of vacant units affordable at AMI per 100 renting households
#     (6b) Number of occupied units affordable at AMI where the occupants are paying <30% of their income on housing costs, per 100 renting households
#     (6c) Number of occupied units affordable at AMI where occupants are nonetheless paying >=30% of their income on housing costs, per 100 renting households
#     (6d) Number of occupied units affordable at AMI rented by occupants at a higher AMI, per 100 renting households



###  For given income bracket (in this case, 0-30% AMI), calculates the TOTAL population at that AMI (POP), the number with that AMI renting at an affordable level (ATRENT),
### and the number of units affordable at AMI being rented by people with a higher AMI (DOWNRENT).
### From there, calculates the following:
### Number of vacant units affordable at AMI per 100 renting households
### Number of occupied units affordable at AMI where the occupants are paying <30% of their income on housing costs, per 100 renting households
### Number of occupied units affordable at AMI where occupants are nonetheless paying >=30% of their income on housing costs, per 100 renting households
### Number of occupied units affordable at AMI rented by occupants at a higher AMI, per 100 renting households


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
