###################################################################

# Digital Access metric, non-subgroup
# Tina Chelidze 2022-2023
# Using ACS 2021 tables
# Process:
# (1) Housekeeping
# (2) Pull demographics for Census Places and Census Counties
# (3) Clean and reshape to move data into the vars we want
# (4) Calculate the digital access metric
# (5) Create a data quality flag
# (6) Cleaning and export

###################################################################

# (1) Housekeeping
# Set working directory to [gitfolder]: Open mobility-from-poverty.Rproj to make sure all file paths will work

# Libraries you'll need
library(censusapi)
library(tidycensus)
library(tidyverse)

###################################################################
# (1) Housekeeping

# Explore where to pull data from
apis <- listCensusApis()
View(apis)

acs5_vars <- listCensusMetadata(name="2021/acs/acs5", type = "variables")
head(acs5_vars)

acs_geos <- listCensusMetadata(name = "acs/acs5", vintage = 2021, type = "geography")


# Here are all the codes we need for the population denominator(s): 

# RACE variables
# B03002_003E # Not Hispanic or Latino, White Alone
# B03002_004E # Not Hispanic or Latino, Black of African American Alone
# B03002_005E # Not Hispanic or Latino, American Indian and Alaska Native alone
# B03002_006E # Not Hispanic or Latino, Asian Alone
# B03002_007E # Not Hispanic or Latino, Native Hawaiian and Other Pacific Islander alone
# B03002_008E # Not Hispanic or Latino, some other race alone
# B03002_009E # Not Hispanic or Latino, two or more races

# RACE variables that will match the ones that are available for digital access (see below)
# we cannot use the set above, because broadband access not split out by non-hispanic racial subgroups, only totals
# B02001_002E # White Alone
# B02001_003E # Black or African American Alone
# B02001_004E # American Indian and Alaska Native Alone
# B02001_005E # Asian Alone
# B02001_006E # Native Hawaiian and Other Pacific Islander Alone
# B02001_007E # Some other race alone
# B02001_008E # Two or more races
# B03001_003E # Hispanic or Latino (total)


# PRESENCE OF A COMPUTER AND TYPE OF BROADBAND INTERNET SUBSCRIPTION IN HOUSEHOLD, by races (9 vars)
# B28009A_004E # White Alone
# B28009B_004E # Black or African American Alone
# B28009C_004E # American Indian and Alaska Native Alone
# B28009D_004E # Asian Alone
# B28009E_004E # Native Hawaiian and other Pacific Islander Alone
# B28009F_004E # Some Other Race Alone
# B28009G_004E # Two or More Races
# B28009H_004E # White Alone, not Hispanic or Latino (won't use this since not consistent, it's the only one)
# B28009I_004E # Hispanic or Latino


###################################################################
# (2) Pull demographics for Census Places and Census Counties

# First, list & save variables of interest as a vector
popvars <- c(
  "B02001_002E",
  "B02001_003E", 
  "B02001_004E",
  "B02001_005E",
  "B02001_006E",
  "B02001_007E",
  "B02001_008E",
  "B03001_003E"
)

digitalvars <- c(
  "B28009A_004E",
  "B28009B_004E", 
  "B28009C_004E",
  "B28009D_004E",
  "B28009E_004E",
  "B28009F_004E",
  "B28009G_004E",
  "B28009I_004E"
)


# Pull ACS data at the Census Place and Census County levels
# first, all the demographic populations
places_pop <- get_acs(geography = "place",
                      variables = popvars,
                      year = 2021)

county_pop <- get_acs(geography = "county",
                      variables = popvars,
                      year = 2021)

# now all the digital access data
places_digital <- get_acs(geography = "place",
                          variables = digitalvars,
                          year = 2021)

county_digital <- get_acs(geography = "county",
                          variables = digitalvars,
                          year = 2021)


###################################################################
# (3) Clean and reshape to move data into the vars we want

# Drop moe before reshape
places_pop <- places_pop %>% 
  select(GEOID, NAME, variable, estimate)
county_pop <- county_pop %>% 
  select(GEOID, NAME, variable, estimate)

places_digital <- places_digital %>% 
  select(GEOID, NAME, variable, estimate)
county_digital <- county_digital %>% 
  select(GEOID, NAME, variable, estimate)


# Reshape the datasets so we can see all the population values per row
wide_county_pop <- county_pop %>%
  pivot_wider(names_from = variable, values_from = estimate)
wide_places_pop <- places_pop %>%
  pivot_wider(names_from = variable, values_from = estimate)

wide_county_digital <- county_digital %>%
  pivot_wider(names_from = variable, values_from = estimate)
wide_places_digital <- places_digital %>%
  pivot_wider(names_from = variable, values_from = estimate)



# Rename vars for clarity
wide_county_pop <- wide_county_pop %>% 
  rename(
    "white" = "B02001_002",
            "black" = "B02001_003", 
            "aian" = "B02001_004",
            "asian" = "B02001_005",
            "nhpi" = "B02001_006",
            "other" = "B02001_007",
            "two_or_more" = "B02001_008",
            "hispanic" = "B03001_003"
  )

wide_places_pop <- wide_places_pop %>% 
  rename(
    "white" = "B02001_002",
            "black" = "B02001_003", 
            "aian" = "B02001_004",
            "asian" = "B02001_005",
            "nhpi" = "B02001_006",
            "other" = "B02001_007",
            "two_or_more" = "B02001_008",
            "hispanic" = "B03001_003"
  )



wide_county_digital <- wide_county_digital %>% 
  rename(
    "white_digital" = "B28009A_004",
    "black_digital" = "B28009B_004", 
    "aian_digital" = "B28009C_004",
    "asian_digital" = "B28009D_004",
    "nhpi_digital" = "B28009E_004",
    "other_digital" = "B28009F_004",
    "two_or_more_digital" = "B28009G_004",
    "hispanic_digital" = "B28009I_004"
  )

wide_places_digital <- wide_places_digital %>% 
  rename(
    "white_digital" = "B28009A_004",
    "black_digital" = "B28009B_004", 
    "aian_digital" = "B28009C_004",
    "asian_digital" = "B28009D_004",
    "nhpi_digital" = "B28009E_004",
    "other_digital" = "B28009F_004",
    "two_or_more_digital" = "B28009G_004",
    "hispanic_digital" = "B28009I_004"
  )

# Collapse the detailed groups into the same four racial groups of interest from the above section

# Construct asian_other & total (combined values)
wide_county_pop <- wide_county_pop %>%
  mutate(
    asian_other = aian + asian + nhpi + other + two_or_more,
    total_people = asian_other + hispanic + white + black
  )

wide_places_pop <- wide_places_pop %>%
  mutate(
    asian_other = aian + asian + nhpi + other + two_or_more,
    total_people = asian_other + hispanic + white + black
  )

wide_county_digital <- wide_county_digital %>%
  mutate(
    asian_other_digital = aian_digital + asian_digital + nhpi_digital + other_digital + two_or_more_digital,
    total_people_digital = asian_other_digital + hispanic_digital + white_digital + black_digital
  )

wide_places_digital <- wide_places_digital %>%
  mutate(
    asian_other_digital = aian_digital + asian_digital + nhpi_digital + other_digital + two_or_more_digital,
    total_people_digital = asian_other_digital + hispanic_digital + white_digital + black_digital
  )



# Keep only the vars we need
wide_county_pop <- wide_county_pop %>% select(GEOID, 
                                              NAME, 
                                              total_people, 
                                              asian_other, 
                                              black, 
                                              hispanic, 
                                              white)

wide_places_pop <- wide_places_pop %>% select(GEOID, 
                                              NAME, 
                                              total_people, 
                                              asian_other, 
                                              black, 
                                              hispanic, 
                                              white)

wide_county_digital <- wide_county_digital %>% select(GEOID, 
                                                      NAME, 
                                                      total_people_digital, 
                                                      asian_other_digital, 
                                                      black_digital, 
                                                      hispanic_digital, 
                                                      white_digital)

wide_places_digital <- wide_places_digital %>% select(GEOID, 
                                                      NAME, 
                                                      total_people_digital, 
                                                      asian_other_digital, 
                                                      black_digital, 
                                                      hispanic_digital, 
                                                      white_digital)


###################################################################
# (4) Calculate the digital access metric

# Merge the geography files together to have all variables together
digital_access_county <- left_join(wide_county_pop, wide_county_digital, by=c("GEOID"))
digital_access_city <- left_join(wide_places_pop, wide_places_digital, by=c("GEOID"))

# Now calculate the metric: share with digital access
digital_access_county <- digital_access_county %>%
  mutate(
    digital_access_total = total_people_digital / total_people,
    digital_access_asian_other = asian_other_digital / asian_other, 
    digital_access_black = black_digital / black, 
    digital_access_hispanic = hispanic_digital / hispanic,
    digital_access_white = white_digital / white
  )

digital_access_city <- digital_access_city %>%
  mutate(
    digital_access_total = total_people_digital / total_people,
    digital_access_asian_other = asian_other_digital / asian_other, 
    digital_access_black = black_digital / black, 
    digital_access_hispanic = hispanic_digital / hispanic,
    digital_access_white = white_digital / white
  )


###################################################################
# (5) Create a data quality flag

# For any ratio that's being calculated with a count of individuals less than 30, make the flag = 1
digital_access_county <- digital_access_county %>% 
  mutate(total_size_flag = case_when((total_people_digital < 30 | total_people < 30) ~ 1,
                                     (total_people_digital >= 30 & total_people >= 30) ~ 0),
         asian_size_flag = case_when((asian_other_digital < 30 | asian_other < 30) ~ 1,
                                     (asian_other_digital >= 30 & asian_other >= 30) ~ 0),
         black_size_flag = case_when((black_digital < 30 | black < 30) ~ 1,
                                     (black_digital >= 30 & black >= 30) ~ 0),
         hispanic_size_flag = case_when((hispanic_digital < 30 | hispanic < 30) ~ 1,
                                        (hispanic_digital >= 30 & hispanic >= 30) ~ 0),
         white_size_flag = case_when((white_digital < 30 | white < 30) ~ 1,
                                     (white_digital >= 30 & white >= 30) ~ 0))

digital_access_city <- digital_access_city %>% 
  mutate(total_size_flag = case_when((total_people_digital < 30 | total_people < 30) ~ 1,
                                     (total_people_digital >= 30 & total_people >= 30) ~ 0),
         asian_size_flag = case_when((asian_other_digital < 30 | asian_other < 30) ~ 1,
                                     (asian_other_digital >= 30 & asian_other >= 30) ~ 0),
         black_size_flag = case_when((black_digital < 30 | black < 30) ~ 1,
                                     (black_digital >= 30 & black >= 30) ~ 0),
         hispanic_size_flag = case_when((hispanic_digital < 30 | hispanic < 30) ~ 1,
                                        (hispanic_digital >= 30 & hispanic >= 30) ~ 0),
         white_size_flag = case_when((white_digital < 30 | white < 30) ~ 1,
                                     (white_digital >= 30 & white >= 30) ~ 0))

# Generate the quality var
digital_access_county <- digital_access_county %>% 
  mutate(digital_access_total_quality = case_when((total_size_flag == 1) ~ 2,
                                                  (total_size_flag == 0) ~ 1),
         digital_access_asian_other_quality = case_when((asian_size_flag == 1) ~ 2,
                                                        (asian_size_flag == 0) ~ 1),
         digital_access_black_quality = case_when((black_size_flag == 1) ~ 2,
                                                  (black_size_flag == 0) ~ 1),
         digital_access_hispanic_quality = case_when((hispanic_size_flag == 1) ~ 2,
                                                     (hispanic_size_flag == 0) ~ 1),
         digital_access_white_quality = case_when((white_size_flag == 1) ~ 2,
                                                  (white_size_flag == 0) ~ 1))


digital_access_city <- digital_access_city %>% 
  mutate(digital_access_total_quality = case_when((total_size_flag == 1) ~ 2,
                                                  (total_size_flag == 0) ~ 1),
         digital_access_asian_other_quality = case_when((asian_size_flag == 1) ~ 2,
                                                        (asian_size_flag == 0) ~ 1),
         digital_access_black_quality = case_when((black_size_flag == 1) ~ 2,
                                                  (black_size_flag == 0) ~ 1),
         digital_access_hispanic_quality = case_when((hispanic_size_flag == 1) ~ 2,
                                                     (hispanic_size_flag == 0) ~ 1),
         digital_access_white_quality = case_when((white_size_flag == 1) ~ 2,
                                                  (white_size_flag == 0) ~ 1))


###################################################################
# (6) Prepare the data for saving & export final Metrics files

# merge in the final County & Places files to isolate the data we need for each
county_file <- read_csv("geographic-crosswalks/data/county-populations.csv")

places_file <- read_csv("geographic-crosswalks/data/place-populations.csv")

# add in the lost leading zeroes for the state/county FIPs & state/place FIPs

county_file <- county_file %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))
county_file <- county_file %>%
  mutate(county = sprintf("%0.3d", as.numeric(county)))


places_file <- places_file %>%
  mutate(state = sprintf("%0.2d", as.numeric(state)))
places_file <- places_file %>%
  mutate(place = sprintf("%0.5d", as.numeric(place)))

# create a concatenated GEOID based on state + county & state + place
county_file$GEOID <- paste(county_file$state,county_file$county, sep = "")

places_file$GEOID <- paste(places_file$state,places_file$place, sep = "")


# keep the most recent year of population data (not 2022, but 2020)
county_file <- filter(county_file, year > 2019)

places_file <- filter(places_file, year > 2019)


# merge the data files into the population files (left join, since data files have more observations)
county_digital_access_by_race <- left_join(county_file, digital_access_county, by=c("GEOID"))

place_digital_access_by_race <- left_join(places_file, digital_access_city, by=c("GEOID"))


# RESHAPE TO PREPARE EXPORT
# reshape each of these from wide to long (so that there are 5 obs per place -- all, white, black, asian, other)

# COUNTY first
county_digital_access_race <- county_digital_access_by_race %>% 
  select(year, state, county, digital_access_total, digital_access_asian_other, 
         digital_access_black, digital_access_hispanic, digital_access_white)
# rename subgroup vars for the merge
county_digital_access_race <- county_digital_access_race %>% 
  rename(
    "All" = "digital_access_total",
    "Other Races and Ethnicities" = "digital_access_asian_other", 
    "Black" = "digital_access_black",
    "Hispanic" = "digital_access_hispanic",
    "White" = "digital_access_white",
  )
county_digital_access <- gather(county_digital_access_race, 
                                key="subgroup", 
                                value="digital_access", 
                                4:8)
county_digital_access <- county_digital_access %>%
  arrange(state, county)
# 3143 obs (counties) * 5 race groups = 15,715 obs -- accurate


# do the same for the quality variable so you can merge it back in (I could not get this to reshape two column pairs at once)
county_digital_access_qual <- county_digital_access_by_race %>% 
  select(year, state, county, digital_access_total_quality, digital_access_asian_other_quality, 
         digital_access_black_quality, digital_access_hispanic_quality, 
         digital_access_white_quality)

# rename subgroup vars for the merge
county_digital_access_qual <- county_digital_access_qual %>% 
  rename(
    "All" = "digital_access_total_quality",
    "Other Races and Ethnicities" = "digital_access_asian_other_quality", 
    "Black" = "digital_access_black_quality",
    "Hispanic" = "digital_access_hispanic_quality",
    "White" = "digital_access_white_quality",
  )
county_digital_access_qual <- gather(county_digital_access_qual, 
                                key="subgroup", 
                                value="digital_access_quality", 
                                4:8)
county_digital_access_qual <- county_digital_access_qual %>%
  arrange(state, county)


# merge them back together so we have the data and quality in one df
county_digital_access <- left_join(county_digital_access, county_digital_access_qual, by=c("state", "county", "subgroup"))



# now PLACE
place_digital_access_race <- place_digital_access_by_race %>% 
  select(year, state, place, digital_access_total, digital_access_asian_other, 
         digital_access_black, digital_access_hispanic, digital_access_white)
# rename subgroup vars for the merge
place_digital_access_race <- place_digital_access_race %>% 
  rename(
    "All" = "digital_access_total",
    "Other Races and Ethnicities" = "digital_access_asian_other", 
    "Black" = "digital_access_black",
    "Hispanic" = "digital_access_hispanic",
    "White" = "digital_access_white",
  )
place_digital_access <- gather(place_digital_access_race, 
                                key="subgroup", 
                                value="digital_access", 
                                4:8)
place_digital_access <- place_digital_access %>%
  arrange(state, place)
# 486 obs (places) * 5 race groups = 2,430 obs -- accurate


# do the same for the quality variable so you can merge it back in (I could not get this to reshape two column pairs at once)
place_digital_access_qual <- place_digital_access_by_race %>% 
  select(year, state, place, digital_access_total_quality, digital_access_asian_other_quality, 
         digital_access_black_quality, digital_access_hispanic_quality, 
         digital_access_white_quality)

# rename subgroup vars for the merge
place_digital_access_qual <- place_digital_access_qual %>% 
  rename(
    "All" = "digital_access_total_quality",
    "Other Races and Ethnicities" = "digital_access_asian_other_quality", 
    "Black" = "digital_access_black_quality",
    "Hispanic" = "digital_access_hispanic_quality",
    "White" = "digital_access_white_quality",
  )
place_digital_access_qual <- gather(place_digital_access_qual, 
                                     key="subgroup", 
                                     value="digital_access_quality", 
                                     4:8)
place_digital_access_qual <- place_digital_access_qual %>%
  arrange(state, place)


# merge them back together so we have the data and quality in one df
place_digital_access <- left_join(place_digital_access, place_digital_access_qual, by=c("state", "place", "subgroup"))


# Add in the subgroup_type variable accordingly
county_digital_access <- county_digital_access %>% 
  mutate(subgroup_type = case_when((subgroup %in% c("All")) ~ "all",
                                   (subgroup %in% c("All",
                                                    "Other Races and Ethnicities",
                                                    "Black",
                                                    "White",
                                                    "Hispanic")) ~ "race-ethnicity"))

place_digital_access <- place_digital_access %>% 
  mutate(subgroup_type = case_when((subgroup %in% c("All")) ~ "all",
                                   (subgroup %in% c("All",
                                                    "Other Races and Ethnicities",
                                                    "Black",
                                                    "White",
                                                    "Hispanic")) ~ "race-ethnicity"))


# Create accurate Year var
county_digital_access <- county_digital_access %>%
  mutate(
    year = 2021
  )

place_digital_access <- place_digital_access %>%
  mutate(
    year = 2021
  )


# Keep only relevant variables
county_digital_access <- county_digital_access %>% 
  select(year, state, county, 
         subgroup_type, subgroup,
         digital_access, digital_access_quality)

place_digital_access <- place_digital_access %>% 
  select(year, state, place, 
         subgroup_type, subgroup,
         digital_access, digital_access_quality)

# Export each of the files as CSVs
# view(county_digital_access)
# view(place_digital_access)
write_csv(county_digital_access, "08_education/digital_access_county_2021.csv")

write_csv(place_digital_access, "08_education/digital_access_city_2021.csv")



