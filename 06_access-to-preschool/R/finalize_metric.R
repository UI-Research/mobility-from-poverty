finalize_metric <- function(.data, .geo_level) {
  
  .data %>%
    arrange(year, statefip, {{ .geo_level }}) %>%
    mutate(
      share_in_preschool_lb = pmax(share_in_preschool_low, 0),
      share_in_preschool_ub = pmin(share_in_preschool_upp, 1)
    ) %>%
    select(-share_in_preschool_low, -share_in_preschool_upp, -n)
  
}