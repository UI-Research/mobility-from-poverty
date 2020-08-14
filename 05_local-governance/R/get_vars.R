#' Title
#'
#' @param year 
#' @param vars 
#'
#' @return
#' @export
#'
#' @examples
get_vars <- function(year, vars, geography) {
  
  state_fips <- paste0("state:", unique(urbnmapr::states$state_fips))
  
  # pull the total population for tracts and counties
  population <- map_df(state_fips, ~getCensus(name = "acs/acs5",
                                              vars = "B01003_001E", # TOTAL POPULATION 
                                              region = paste0(geography, ":*"),
                                              regionin = .x,
                                              vintage = year))
  
  acs_profile <- map_df(state_fips, ~getCensus(name = "acs/acs5/profile",
                                               vars = vars, 
                                               region = paste0(geography, ":*"),
                                               regionin = .x,
                                               vintage = year))
  
  if (geography == "tract") {
    
    combined_data <- left_join(population, acs_profile, by = c("state", "county", "tract"))
    
  } else if (geography == "county") {
    
    combined_data <- left_join(population, acs_profile, by = c("state", "county"))
    
  } else if (geography == "place") {
    
    combined_data <- left_join(population, acs_profile, by = c("state", "place"))
    
  } else if (geography == "county subdivision") {
    
    combined_data <- left_join(population, acs_profile, by = c("state", "county", "county_subdivision"))
    
  }
    
  combined_data <- combined_data %>%
    mutate(geography = geography) %>%
    as_tibble()

  return(combined_data)
  
}