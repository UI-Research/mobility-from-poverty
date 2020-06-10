library(tidyverse)
library(censusapi)
source("R/census_api_key.R")
source("R/get_vars.R")

# acs 5-year profile variables --------------------------------------------
# https://api.census.gov/data/2015/acs/acs5/profile/variables.html

vars <- c(
  # "DP02_0001E",  # Estimate!!HOUSEHOLDS BY TYPE!!Total households	
  # "DP03_0119PE", # Percent!!PERCENTAGE OF FAMILIES AND PEOPLE WHOSE INCOME IN THE PAST 12 MONTHS IS BELOW THE POVERTY LEVEL!!All families
  # "DP03_0119PM",
  "DP03_0128PE", # Estimate!!PERCENTAGE OF FAMILIES AND PEOPLE WHOSE INCOME IN THE PAST 12 MONTHS IS BELOW THE POVERTY LEVEL!!All people
  "DP03_0128PM"
)

# To do this we have to identify census tracts with poverty rates over 40% in 
# each county, count the number of residents in those tracts who are poor, sum 
# that up and divided it by the total number of poor residents in the county.
tracts <- get_vars(year = 2018, vars = vars)

tracts <- tracts %>%
  rename(people = B01003_001E,
         poverty = DP03_0128PE,
         poverty_moe = DP03_0128PM)


# tracts with adjusted codes
# -222222222 does not exist or the cell is too small
# -666666666 does not exist or the cell is too small

tracts %>%
  filter(poverty == -666666666)




# indicator for > 40
tracts <- tracts %>%
  mutate() %>%
  mutate(high_poverty = if_else(poverty > 40, people, 0))


# group by and summarize to the county level
tracts %>%
  group_by(state, county) %>%
  summarize(sum(people), sum(high_poverty))



# join to the county data












acs_profile_2015 <- acs_profile_2015 %>%
  as_tibble() %>%
  # rename(households = DP02_0001E,	
  #        poverty = DP03_0119PE, 
  #        poverty_moe = DP03_0119PM) %>%
  mutate(`Tract ID` = paste0(state, county, tract)) %>%
  select(-state, -county, -tract)

# recode missing values
acs_profile_2015 <- map_df(acs_profile_2015, ~ifelse(.x == -666666666, NA, .x))
acs_profile_2015 <- map_df(acs_profile_2015, ~ifelse(.x == -222222222, NA, .x))

# move from a 0 to 100 scale to a 0 to 1 scale
acs_profile_2015 <- acs_profile_2015 %>%
  mutate_at(.vars = vars(-households, -pop25, -`Tract ID`),
            .funs = ~. / 100)

write_csv(acs_profile_2015, path = "data/acs-profile.csv")
