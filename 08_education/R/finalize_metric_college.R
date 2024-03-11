finalize_metric_college <- function(.data, .geo_level) {
  
  .data %>%
    arrange(year, statefip, {{ .geo_level }}) %>%
    mutate(
      share_hs_degree_lb = pmax(share_hs_degree_low, 0),
      share_hs_degree_ub = pmin(share_hs_degree_upp, 1)
    ) %>%
    select(-share_hs_degree_low, -share_hs_degree_upp, -n)
  
}