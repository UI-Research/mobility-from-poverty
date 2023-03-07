get_years <- function(.data, var) {
  
  .data %>%
    dplyr::filter({{ var }} > 0) %>%
    dplyr::pull(year) %>%
    unique() %>%
    sort() %>%
    paste(collapse = ", ")
  
}