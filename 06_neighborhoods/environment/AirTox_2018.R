#/*************************/
#  air quality program: 
#  created by: Rebecca Marx
#  updated on: February 23, 2023
#Description: 
#(1) creates tract level indicators of environmental hazards for 2014 and 2018 
#(2) creates tract-level indicators of poverty and race for counties in US
#*/
#  /*************************/

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
library (dplyr)


###Step 1: Import 2018 AirToxScreen Data and 2014 AFFH data 
#https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide

cancer_data18 <- read.csv("06_neighborhoods/environment/data/raw/2018_National_CancerRisk_by_tract_srcgrp.csv")
neuro_data18 <- read.csv("06_neighborhoods/environment/data/raw/2018_National_NeurHI_by_tract_srcgrp.csv")
resp_data18 <- read.csv("06_neighborhoods/environment/data/raw/2018_National_RespHI_by_tract_srcgrp.csv")

get_acs 

affh20 <- read.csv("06_neighborhoods/environment/data/raw/Solari_AFFH_tract_AFFHT0006_July2020.csv")

#Step 2: Only keep needed variabales##

cancer_data18 <- cancer_data18 %>% 
  select(Tract, Total.Cancer.Risk..per.million.) 

neuro_data18 <- neuro_data18 %>% 
  select(Tract, Total.Neurological..hazard.quotient.) 

resp_data18 <- resp_data18 %>% 
  select(Tract, Total.Respiratory..hazard.quotient.) 

##Step 3: Join Variables and rename##
#merge(cancer_data18, neuro_data18, by = 'Tract')

resp_cancer18 <- merge(x = resp_data18, y = cancer_data18, by = "Tract")

enviro18 <- merge(x = resp_cancer18, y = neuro_data18, by = "Tract")

colnames (enviro18_int) <- c("tract", "resp", "carc","neuro")

##Step 4: drop rows that are not tracts first row (tract = 0: Total US)# NEED TO DETERMINE WHAT ELSE TO DROP
#enviro18 = enviro18[-1,]

#desc(enviro18_int$tract)
#summarise(enviro18_int) detail

#enviro18_int$tract6 <- enviro18_int %>%
  #mutate(tract = str_sub(tract, start = -6, end = -1)) 

#enviro18_int$tract.c <- str_pad(enviro18_int$tract, 11, side = "left", pad = 0)

#enviro18_int$tract.c = as.character(enviro18_int$tract.c)

#enviro18_int$tract.0 <- sprintf("%.0f", as.numeric(enviro18_int$tract.c))


#for(i in nrow(enviro18_int)){
  #enviro18_int$tract.0[i] = ifelse(nchar(enviro18_int$tract.c[i]==10),paste("0",enviro18_int$tract.c[i],sep = ""),enviro18_int$tract.c[i])  
#}

#enviro18_int$tract.0[nchar(enviro18_int$tract.c)==10] = c("0",enviro18_int$tract.c[enviro18_int$tract.c]==10)

#enviro18_int$ <- enviro18 %>%
 #mutate(tract = str_sub(tract, start = 6, end = 11)) 
  #haz_idx18$tract <- sprintf("%011d", as.numeric(haz_idx18$tract))

#pull in tracts 
state_fips <- unique(urbnmapr::states$state_fips)
tracts18 <- get_acs(geography = "tract",
                      variable = "B02001_001",
                       state = state_fips,
                       geometry = FALSE,
                       year = 2018)

tracts18_2 <- tracts18 %>%
  select(GEOID)
colnames(tracts18_2) <- c("tract")

#merge to drop extra rows in AirTox
enviro18 <- tidylog::left_join(x = tracts18_2, y = enviro18_int, by = "tract")
enviro18$tract <- as.numeric(enviro18$tract)

#check diff between enviro18_int and enviro18
not_in_enviro18 <- setdiff(enviro18_int$tract,enviro18$tract)
not_in_enviro18 = as.data.frame(not_in_enviro18)

#check diff between enviro18 and tracts18_2
tracts18_not_in <- setdiff(tracts18_2$tract,enviro18_int$tract)
tracts18_not_in = as.data.frame(tracts18_not_in)

##Step 5: Calculate means and st. devs and store values##

resp_mean18 <- mean(enviro18$resp, na.rm = TRUE)
carc_mean18 <- mean(enviro18$carc, na.rm = TRUE)
neuro_mean18 <- mean (enviro18$neuro, na.rm = TRUE)

resp_stdv18 <- sd(enviro18$resp, na.rm = TRUE)
carc_stdv18 <- sd(enviro18$carc, na.rm = TRUE)
neuro_stdv18 <- sd(enviro18$neuro, na.rm = TRUE)

##Step 6: Calculate EnvHealth components
enviro18$resp2 <- (enviro18$resp - resp_mean18)/resp_stdv18
enviro18$carc2 <- (enviro18$carc - carc_mean18)/carc_stdv18
enviro18$neuro2 <- (enviro18$neuro - neuro_mean18)/neuro_stdv18

##Step 7: Calculate EnvHealth
enviro18$envhealth18 <- (enviro18$carc2 + enviro18$resp2 + enviro18$neuro2)*-1

##Step 8: Percentile Rank
enviro18$envhrank18 <- percent_rank(enviro18$envhealth18)

#Step 9: Set haz_idx between 0 and 100 
enviro18$haz_idx18 <- round(enviro18$envhrank18*100,0)

#keep what we need
haz_idx18 <- enviro18 %>% 
  select(tract, haz_idx18)

#add leading zeroes 
haz_idx18$tract <- str_pad(haz_idx18$tract, 11, side = "left", pad = "0")


#keep last six digits?
#haz_idx18$tract_extra <- haz_idx18 %>%
  #mutate(tract = str_sub(tract,start = 1, end = 6)) 


##Repeat for 2014##

###Step 1: Import 2014 AirToxScreen Data###
#https://www.epa.gov/AirToxScreen/2018-airtoxscreen-assessment-results#nationwide

cancer_data14 <- read.csv("~/GitHub/mobility-from-poverty/mobility-from-poverty/06_neighborhoods/environment/data/nata2014v2_national_cancerrisk_by_tract_srcgrp.csv")
neuro_data14 <- read.csv("~/GitHub/mobility-from-poverty/mobility-from-poverty/06_neighborhoods/environment/data/nata2014v2_national_neurhi_by_tract_srcgrp.csv")
resp_data14 <- read.csv("~/GitHub/mobility-from-poverty/mobility-from-poverty/06_neighborhoods/environment/data/nata2014v2_national_resphi_by_tract_srcgrp.csv")

#Step 2: Only keep needed variabales##

cancer_data14 <- cancer_data14 %>% 
  select(Tract, Total.Cancer.Risk..per.million.) 
#convert from factor to numeric
  cancer_data14$Total.Cancer.Risk..per.million. <- as.numeric(cancer_data14$Total.Cancer.Risk..per.million.)
  cancer_data14$Total.Cancer.Risk..per.million. <- cancer_data14$Total.Cancer.Risk..per.million. / 1000

neuro_data14 <- neuro_data14 %>% 
  select(Tract, Total.Neurological..hazard.quotient.) 

resp_data14 <- resp_data14 %>% 
  select(Tract, Total.Respiratory..hazard.quotient.) 

##Step 3: Join Variables and rename##
merge(cancer_data14, neuro_data14, by = Tract)

resp_cancer14 <- merge(x = resp_data14, y = cancer_data14, by = "Tract")

enviro14 <- merge(x = resp_cancer14, y = neuro_data14, by = "Tract")

colnames (enviro14) <- c("tract", "resp", "carc","neuro")

#drop first row (tract = 0: Total US)
enviro14 = enviro14[-1,]

##Step 5: Calculate means and st. devs and store values##

resp_mean14 <- mean(enviro14$resp)
carc_mean14 <- mean(enviro14$carc)
neuro_mean14 <- mean(enviro14$neuro)

resp_stdv14 <- sd(enviro14$resp)
carc_stdv14 <- sd(enviro14$carc)
neuro_stdv14 <- sd(enviro14$neuro)

##Step 6: Calculate EnvHealth14 components
enviro14$resp2 <- (enviro14$resp - resp_mean14)/resp_stdv14
enviro14$carc2 <- (enviro14$carc - carc_mean14)/carc_stdv14
enviro14$neuro2 <- (enviro14$neuro - neuro_mean14)/neuro_stdv14

##Step 7: Calculate EnvHealth14
enviro14$envhealth14 <- (enviro14$carc2 + enviro14$resp2 + enviro14$neuro2)*-1

##Step 8: Percentile Rank
enviro14$envhrank14 <- percent_rank(enviro14$envhealth14)

#Step 9: Set haz_idx between 0 and 100 
enviro14$haz_idx14 <- round(enviro14$envhrank14*100,0)

#keep what we need
haz_idx14 <- enviro14 %>% 
  select(tract, haz_idx14)



##COMPARE TO 2014 AFFH##

#Step 10: Import AFFH data and select haz_idx
affh20 <- read.csv("06_neighborhoods/environment/data/Solari_AFFH_tract_AFFHT0006_July2020.csv")

affh20 <- affh20 %>% 
  select(geoid, haz_idx) 
colnames (affh20) <- c("tract", "haz_idx_affh")

#Step 11: Join indexes by tract to compare values 

haz_idx <- merge(haz_idx14, haz_idx18, by = "tract")

haz_idx <- merge(haz_idx, affh20, by = "tract")

haz_idx <- haz_idx[,c(1,4,2,3)]

haz_idx$diff_14_affh <- haz_idx$haz_idx14 - haz_idx$haz_idx_affh

haz_idx$chng_14_18 <- haz_idx$haz_idx18 - haz_idx$haz_idx14

avg_diff_14_affh <- mean(haz_idx$diff_14_affh)

avg_change_14_18 <- mean(haz_idx$chng_14_18)


##Look at which tracts are not in the affh file##
missing_affh 


non_affh <- setdiff(enviro14$tract,affh20$tract)

non_affh = as.data.frame(non_affh)


#write.csv(haz_idx, "EnvHazIdx.csv", row.names = F)


##Procude the indicators file##



#add year variable
#haz_idx18$year <- 2018 

#add leading zeroes - pad to length of 11 characters
#haz_idx18$tract <- sprintf("%011d", as.numeric(haz_idx18$tract))
#invalid format '%011d'; use format %f, %e, %g or %a for numeric objects

#split tract into state and county 
#haz_idx18 <- haz_idx18 %>%
  #mutate(state = str_sub(tract, start = 1, end = 2),
         #county = str_sub(tract, start = 3, end = 5),
         #tract = str_sub(tract, start = 6, end = 11)) 

#trim tracts to 6-digit id 

#haz_idx18$tract <- sprintf("%011d", as.numeric(haz_idx18$tract))



##CROSSWALK## 

#import tract-county-crosswalk_2018.csv
crosswalk <- read.csv("geographic-crosswalks/data/tract-county-crosswalk_2018.csv")

#prep crosswalk file by adding leading zeroes to state and county 
crosswalk$state <- str_pad(crosswalk$state, 2, side = "left", pad = "0")

crosswalk$county <- str_pad(crosswalk$county, 3, side = "left", pad = "0")

crosswalk$tract <- str_pad(crosswalk$tract, 6, side = "left", pad = "0")

#concatenate crosswalk and remove spaces 
crosswalk$tract2 <- paste(crosswalk$state,crosswalk$county,crosswalk$tract)
crosswalk$tract2 <- gsub(" ", "", crosswalk$tract2)
crosswalk <- crosswalk %>%
  select(year,tract2)
colnames(crosswalk) <- c("year", "tract")

#look at difference between crosswalk and haz_idx file
#non_crosswalk <- setdiff(haz_idx18$tract, crosswalk$tract)
#non_crosswalk = as.data.frame(non_crosswalk)

#merge hazard and crosswalk files 
hazidx18_merge <- tidylog::inner_join(x = crosswalk, y = haz_idx18, 
                        by= "tract")

#split tract into state and county 
hazidx18_merge <- hazidx18_merge %>%
  mutate(GEOID = str_sub(tract, start = 1, end = 11),
          state = str_sub(tract, start = 1, end = 2),
           county = str_sub(tract, start = 3, end = 5),
           tract = str_sub(tract, start = 6, end = 11))
 
#re-order
enviro_haz18 <- hazidx18_merge[,c(1,5,6,2,3,4)]

##LOTS OF MISSING, NEED TO FIX##


##POPULATION WEIGHT TRACTS##

####STEP ONE: PULL RACE VARIABLES FROM ACS####
# pull total population and white, non-Hispanic population, total for poverty calculation, and total in poverty
# by tract from the ACS

state_fips <- unique(urbnmapr::states$state_fips)
pull_acs <- function(state_fips) {
  tidycensus::get_acs(geography = "tract", 
                      variables = c("total_pop" = "B02001_001",
                                    "wnh" = "B03002_003", 
                                    "total_pov" = "B17001_001", 
                                    "poverty" = "B17001_002"),
                      year = 2018,
                      state = state_fips,
                      geometry = FALSE,
                      output = "wide"
                     )
}
acs <- map_df(state_fips, pull_acs)


####STEP TWO: CREATE INDICATORS FOR RACE AND POVERTY#### 

# use acs data to create a variable for percent poc, by tract
race_pov<- acs %>%
  transmute(GEOID = GEOID,
            name = NAME,
            total_pop = total_popE,
            wnh = wnhE,
            poc = total_pop - wnh, 
            percent_poc = poc/total_pop, 
            total_pov = total_povE, 
            poverty = povertyE, 
            percent_pov = poverty / total_pov
  )  

# create indicator variable for race based on perctage of poc/nh-White in each tract. These percentage cut offs were determined by Marge Turner.
# also create indicator for tracts in 'High Poverty', with 40% or higher poverty rate meaning the tract has a high level of poverty
race_pov <- race_pov %>%
  mutate(
    race_ind = case_when(
      percent_poc > .4 & percent_poc < .6 ~"Mixed Race and Ethnicity",
      percent_poc >= .6 ~ "Majority Non-White",
      percent_poc <= .6 ~ "Majority White, Non-Hispanic"), 
    poverty_type = case_when(
      percent_pov < .4 ~ "Not High Poverty",
      percent_pov >=  .4 ~ "High Poverty")
  )


# two county names and fips codes were changed.
# edit the GEOIDs to match the current fips codes. 
#race_pov <- race_pov %>% 
  #mutate(GEOID = case_when(
    #GEOID ==  "46113940500" ~ "46102940500",
    #GEOID ==  "46113940800" ~ "46102940800",
    #GEOID ==  "46113940900" ~ "46102940900", 
    #GEOID ==  "02270000100" ~ "02158000100",
    #TRUE ~ GEOID
  #))

##Merge with enviro_haz18 data 

#puerto rico is available in the affh data but not apart of our analyses. drop all observations in puerto rico:
enviro_haz18 <- enviro_haz18 %>%
  filter(state!= "72")

#join to race indicator file
race_enviro <- left_join(race_pov, enviro_haz18, by="GEOID") %>% 
  mutate(na_pop= if_else(is.na(haz_idx18), total_pop, 0))


