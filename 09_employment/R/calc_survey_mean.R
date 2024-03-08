calc_survey_mean <- function(.data) {
  
  .data %>%
    as_survey_rep(
      weights = perwt, 
      repweights = matches("repwtp[0-9]+"),
      type = "JK1",
      scale = 4 / 80,
      rscales = rep(1, 80), 
      mse = TRUE
    ) %>% 
    group_by(year, crosswalk_period, statefip, county) %>% 
    summarise(
      share_employed = survey_mean(employed, vartype = "ci"),
      weighted_n = n(),
      geographic_allocation_quality = unweighted(mean(geographic_allocation_quality))
    ) %>%
    ungroup()
  
}