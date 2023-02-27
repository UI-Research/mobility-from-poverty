library(tidyverse)
library(readxl)
library(writexl)

# Create a vector of state names for the respective URLs from County Health Rankings
## After the first pass at this, I realized four states had slightly different URLs, so
## doing it in two steps and then combining the vectors
in_state1 <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
               "Connecticut", "Delaware", "District%20of%20Columbia", "Florida", "Georgia", "Hawaii",
               "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
               "Maryland", "Massachusetts", "Michigan", "Mississippi", "Missouri",
               "Montana", "Nevada", "New%20Hampshire", "New%20Jersey",
               "New%20York", "North%20Carolina", "North%20Dakota", "Oklahoma", "Oregon",
               "Pennsylvania", "Rhode%20Island", "South%20Carolina", "South%20Dakota", "Tennessee",
               "Texas", "Utah", "Vermont", "Virginia", "Washington", "West%20Virginia", "Wisconsin",
               "Wyoming"
)

in_state2 <- c("Minnesota", "Nebraska", "New Mexico", "Ohio")

# Create a vector of each state's URL using the above vector
my_URLs1 <- paste0("https://www.countyhealthrankings.org/sites/default/files/media/document/2022%20County%20Health%20Rankings%20",
                   in_state1,
                   "%20Data%20-%20v1.xlsx")


my_URLs2 <- paste0("https://www.countyhealthrankings.org/sites/default/files/media/document/2022%20County%20Health%20Rankings%20",
                   in_state2,
                   "%20Data%20-%20v1_0.xlsx")

all_URLs <- c(my_URLs1, my_URLs2)

# Create a vector of state names for downloading each excel file from CHR
out_state <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
               "Connecticut", "Delaware", "District-of-Columbia", "Florida", "Georgia", "Hawaii",
               "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
               "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
               "Montana", "Nebraska", "Nevada", "New-Hampshire", "New-Jersey", "New-Mexico",
               "New-York", "North-Carolina", "North-Dakota", "Ohio", "Oklahoma", "Oregon",
               "Pennsylvania", "Rhode-Island", "South-Carolina", "South-Dakota", "Tennessee",
               "Texas", "Utah", "Vermont", "Virginia", "Washington", "West-Virginia", "Wisconsin",
               "Wyoming"
)

# Download all Excel files from the respective URLs
if (!file.exists(paste0("04_health/access-health-services/data/", out_state, ".xlsx"))) {
  download.file(all_URLs, destfile = paste0("04_health/access-health-services/data/", out_state, ".xlsx"))
}

# Read in, clean, and append each Excel sheet
my_data <- map_df(out_state,
                  ~{readxl::read_excel(path = paste0("04_health/access-health-services/data/", .x, ".xlsx"),
                                       sheet = "Ranked Measure Data",
                                       skip = 1
                  ) %>%
                      select(`FIPS`, `# Primary Care Physicians`, `Primary Care Physicians Rate`,
                             `Primary Care Physicians Ratio`) %>%
                      rename(fips = "FIPS",
                             # state_name = "State",
                             # county_name = "County",
                             number_pc_phys = "# Primary Care Physicians",
                             pc_phys_rate = "Primary Care Physicians Rate",
                             pc_phys_ratio = "Primary Care Physicians Ratio") %>%
                      filter(!str_detect(fips, '000$')) %>%
                      mutate(pc_phys_rate = round(pc_phys_rate, 2)) %>%
                      mutate(pop_per_1_pcp = gsub(':1', '', pc_phys_ratio))
                    # drop_na(county_name)
                  }
)

# Write out final data
writexl::write_xlsx(my_data,
                    path = "04_health/access-health-services/data/ratio_pop_per_pcp.xlsx")



  
  
  
  

