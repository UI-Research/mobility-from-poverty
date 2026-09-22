calc_survey_mean_subgroup_college <- function(.data, .geo_level, .subgroup) {
  
  .data %>%
    as_survey_rep(
      weights = perwt, 
      repweights = matches("repwtp[0-9]+"),
      type = "JK1",
      scale = 4 / 80,
      rscales = rep(1, 80), 
      mse = TRUE
    ) %>% 
    group_by(year, crosswalk_period, statefip, {{ .geo_level }}, {{ .subgroup }}) %>% 
    summarise(
      share_hs_degree = survey_mean(college_ready, vartype = "ci"),
      n = n(),
      geographic_allocation_quality = unweighted(mean(geographic_allocation_quality))
    ) %>%
    ungroup()
  
}