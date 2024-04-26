finalize_metric <- function(.data, .geo_level) {
  
  .data %>%
    arrange(year, statefip, {{ .geo_level }}) %>%
    mutate(
      share_employed_lb = pmax(share_employed_low, 0),
      share_employed_ub = pmin(share_employed_upp, 1)
    ) %>%
    select(-share_employed_low, -share_employed_upp, -weighted_n)
  
}