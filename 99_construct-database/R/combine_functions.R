##Combine file functions 

##This function is used to ensure that the lower bound of a 95% confidence interval is always below the estimate and the upper bound of the a 95% confidence interval is always above the estimate. 

#' Test the bounds of a confidence interval relative to the estimate
#'
#' @param data The data frame of interest
#' @param estimate The unquoted name of the estimate variable
#' @param lb The unquoted name of the lower bound variable
#' @param ub The unquoted name of the upper bound variable
#'
test_bounds <- function(data, estimate, lb, ub) {
  
  subset <- bind_rows(
    data |>
      filter({{ ub }} < {{ lb }}),
    data |>
      filter({{ estimate }} > {{ ub }}),
    data |>
      filter({{ estimate  }} < {{ lb }}),
  )
  
  stopifnot(nrow(subset) == 0)
  
}

##This function is used to test that the geographic FIPs codes are the expected length upon reading in each final file. It will stop the run if failed.

#' Test FIPS code length during CSV read
#'
#' @param file The final data file of interest
#' @param geography The geographic level of the file being tested
#'
safe_read_csv <- function(file, geography) {
  
  data <- read_csv(file) 
  
  if (geography == "county") {
  state_pass <- all(str_length(pull(data, state)) == 2)
  geo_pass <- all(str_length(pull(data, county)) == 3)
  }
  else if (geography == "place") {
    state_pass <- all(str_length(pull(data, state)) == 2)
    geo_pass <- all(str_length(pull(data, place)) == 5)
  }
  if (!state_pass) {
    
    stop("Error: all state FIPS codes aren't of length 2")
    
  }
  if (!geo_pass) {
    
    stop("Error: all geo FIPS codes aren't of correct length")
    
  }
  
  return(data)
  
}

#' Helper function to silence output from testing code
#'
#' @param data A data frame
#'
quiet <- function(data) {
  
  quiet <- data
  
}
