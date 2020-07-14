library(tidyverse)
library(rvest)

get_living_wages <- function(county_id) {
  
  # create the county url
  url <- paste0("https://livingwage.mit.edu/counties/", county_id)
  
  # read html content from the url
  mit <- read_html(url)
  
  # parse to the information from the CSS selector(s) of interest
  raw_text <- html_nodes(mit, css = ".results .wage_title~ td , .results .wage_title+ td") %>%
    html_text()
  
  # clean the text to create a numeric variable
  clean_text <- raw_text %>%
    str_replace_all(pattern = "\n", replace = "") %>%
    str_replace_all(pattern = " ", replace = "") %>%
    str_replace(pattern = "\\$", replace = "") %>%
    as.numeric()
  
  # create a tibble
  clean_data <- tibble(
    county_id = county_id,
    adults = c(rep("1 Adult", times = 4), 
               rep("2 Adults (1 Working)", times = 4), 
               rep("2 Adults (Both Working)", times = 4)),
    children = rep(c("0 Children", "1 Child", "2 Children", "3 Children"), times = 3),
    living_wage = clean_text
  )
  
  return(clean_data)

}

get_living_wages("18049")

# map_df(c("18049", "29189"), 
#        get_living_wages)





