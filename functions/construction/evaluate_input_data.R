#' Evaluate quality of .csv files created by metric leads
#'
#' @param data A data frame
#' @param geography "county" or "place"
#' @param subgroups A character vector of subgroups expected in the subgroup file
#'
#' @return The function will give warnings if the data do not meet certain criteria. 
#' Returns a tibble with the number of geoids per year.
#'
evaluate_input_data <- function(data, geography = "county", subgroups = NULL, confidence_intervals = TRUE) {
  
  # check that the file has the necessary columns
  # check that the first few columns are year, state
  data_names <- names(data)
  
  if(data_names[1] != "year"){warning("Year is not the first column")}
  if(data_names[2] != "state"){warning("State is not the second column")}
  if(!data_names[3] %in% c("county", "place")){warning("Place/County is not the third column")}
  
  if (!is.null(subgroups)) {
    
    if(data_names[4] != "subgroup_type"){warning("Subgroup file but subgroup_type is not the fourth column")}
    if(data_names[5] != "subgroup"){warning("Subgroup file but subgroup is not the fifth column")}
    
  }

  #Check if confidence intervals and data quality NA values align 
  if (confidence_intervals) {
    
    if(sum(is.na(select(data, ends_with("_lb")))) != sum(is.na(select(data, ends_with("_quality")))))
    {warning("Lower bound confidence interval and quality flag are not aligned on NAs")}
    
    if(sum(is.na(select(data, ends_with("_ub")))) != sum(is.na(select(data, ends_with("_quality")))))
    {warning("Upper bound confidence interval and quality flag are not aligned on NAs")}
    
    if(sum(is.na(select(data, ends_with("_ub")))) != sum(is.na(select(data, ends_with("_lb")))))
    {warning("Upper and lower bound confidence intervals are not aligned on NAs")}
    
  }
  
  # check fips
  if (geography == "county") {
    
    data_geoid <- data |>
      dplyr::mutate(geoid = paste0(state, county)) |>
      dplyr::mutate(geo_id_length = stringr::str_length(geoid))
  
  }
  
  if (geography == "place") {
    
    data_geoid <- data |>
      dplyr::mutate(geoid = paste0(state, place)) |>
      dplyr::mutate(geo_id_length = stringr::str_length(geoid))
    
  }
  
  # are there missing leading zeros?
  if(length(unique(dplyr::pull(data_geoid, geo_id_length))) != 1) 
    {warning("Leading zeros are missing in GEOID")}
  
  # check to see if the data are sorted
  data_sorted <- data |>
    dplyr::arrange(year, state, {{geography}})
  
  all.equal(data, data_sorted)
  
  # check subgroups
  if (!is.null(subgroups)) {
    
    observed_subgroups <- sort(unique(dplyr::pull(data, subgroup)))
    
    if(any(observed_subgroups != sort(c("All", subgroups))))
    {warning("Subgroup values do not align with expected subgroups")}
    
    
  }
  
  data_geoid |>
    dplyr::distinct(year, geoid) |>
    dplyr::count(year)
  
}