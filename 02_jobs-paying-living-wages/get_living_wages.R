attempt_living_wages <- function(county_id, 
                                 sleep_time,
                                 user_agent = "Urban Institute Research Data Collector. GAcs@urban.org") {
  
  # create the county url
  url <- paste0("https://livingwage.mit.edu/counties/", county_id)
  
  # read html content from the url
  mit <- bow(url, 
             user_agent = user_agent,
             delay = 0) %>% 
    scrape()
  
  Sys.sleep(sleep_time)
  
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
  
  write_csv(clean_data, 
            here::here("09_employment", "mit-living-wage-scraped_12_15_22.csv"),
            append = TRUE)
  
  return(clean_data)
  
}

get_living_wages <- function(county_id, sleep_time) {
  
  tryCatch({
    
    attempt_living_wages(county_id, sleep_time)
    
  }, error = function(c) {
    tibble(county_id = county_id,
           adults = rep(as.character(NA), 12),
           children =  rep(as.character(NA), 12),
           living_wage =  rep(as.double(NA), 12))
  }
  )
}
