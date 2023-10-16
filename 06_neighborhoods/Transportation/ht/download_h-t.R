#Gabe Morrison note 2023-10-16:
#The code below programatically pulls data at the census tract scale by state
# from the CNT website for the 2017 and 2019 CNT data and saves it in a data/
# subdirectory.

# I have already ran this code and will upload it to box. Note that with the
# boxr R package, you can access that data programatically and do not need
# to scrape the CNT website repeatedly. I would encourage adding if else logic
# to the script to check if the data is on box, and, if not, then scrape CNT.
# To see documentation I wrote about using boxr, see: https://urban-institute.atlassian.net/l/cp/73u1Vx5a
# and reach out to me if you cannot access that page.



library(tidyverse)

fips <- unique(fips_codes$state_code)
fips <- fips[1:51]

url_2019_temp <- "https://htaindex.cnt.org/download/download.php?data_yr=2019&focus=tract&geoid="
url_2017_temp <- "https://htaindex.cnt.org/download/download.php?data_yr=2019&focus=tract&geoid="

files_2019 <- map_chr(fips, ~paste0("ht_", .x, "_2019.csv"))
url_2019 <- map_chr(fips, ~paste0(url_2019_temp, .x))

files_2017 <- map_chr(fips, ~paste0("data/ht_", .x, "_2017.csv"))
url_2017 <- map_chr(fips, ~paste0(url_2017_temp, .x))

map2(url_2019, files_2019, download.file)

map2(url_2017, files_2017, download.file)
