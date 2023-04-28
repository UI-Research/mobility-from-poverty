get_years <- function(.data, var, max = FALSE) {
  
  years <- .data %>%
    dplyr::filter({{ var }} > 0) %>%
    dplyr::pull(year) %>%
    unique() %>%
    sort() 
  
  if (max) {
    
    years <- max(years)
    
  }
  
  years %>%
    paste(collapse = ", ")
  
}