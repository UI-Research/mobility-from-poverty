calc_survey_mean <- function(.data, .geo_level) {
  
  .data %>%
    as_survey_rep(
      weights = perwt, 
      repweights = matches("repwtp[0-9]+"),
      type = "JK1",
      scale = 4 / 80,
      rscales = rep(1, 80), 
      mse = TRUE
    ) %>% 
    group_by(year, crosswalk_period, statefip, {{ .geo_level }}) %>% 
    summarise(
      share_in_preschool = survey_mean(preschool, vartype = "ci"),
      n = n(),
      geographic_allocation_quality = unweighted(mean(geographic_allocation_quality))
    ) %>%
    ungroup()
  
}