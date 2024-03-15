#' Test .csv files created by metric leads
#'
#' @param data A data frame
#' @param geography "county" or "place"
#' @param subgroups A character vector of subgroups expected in the subgroup file
#'
#' @return The function will fail if the data do not meet certain criteria. 
#' Returns a tibble with the number of geoids per year.
#'
test_input_data <- function(data, geography = "county", subgroups = NULL) {
  
  # check that the file has the necessary columns
  # check that the first few columns are year, state
  data_names <- names(data)
  
  stopifnot(data_names[1] == "year")
  stopifnot(data_names[2] == "state")
  stopifnot(data_names[3] == "county" | data_names[3] == "place")
  
  if (!is.null(subgroups)) {
    
    stopifnot(data_names[4] == "subgroup_type")
    stopifnot(data_names[5] == "subgroup")
    
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
  stopifnot(length(unique(dplyr::pull(data_geoid, geo_id_length))) == 1)
  
  # check to see if the data are sorted
  data_sorted <- data |>
    dplyr::arrange(year, state, {{geography}})
  
  all.equal(data, data_sorted)
  
  # check subgroups
  if (!is.null(subgroups)) {
    
    observed_subgroups <- sort(unique(dplyr::pull(data, subgroup)))
    
    stopifnot(all(observed_subgroups == c("All", subgroups)))
    
  }
  
  data_geoid |>
    dplyr::distinct(year, geoid) |>
    dplyr::count(year)
  
}
