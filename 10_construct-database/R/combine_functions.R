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
#'
safe_read_csv <- function(file) {
  
  data <- read_csv(file) 
  
  state_pass <- all(str_length(pull(data, state)) == 2)
  county_pass <- all(str_length(pull(data, county)) == 3)
  
  if (!state_pass) {
    
    stop("Error: all state FIPS codes aren't of length 2")
    
  }
  if (!county_pass) {
    
    stop("Error: all county FIPS codes aren't of length 3")
    
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
