calc_income_quantiles <- function(.data, .geo_level) {
  
  .data %>%
    as_survey_rep(
      weights = hhwt, 
      repweights = matches("repwt[0-9]+"),
      type = "JK1",
      scale = 4 / 80,
      rscales = rep(1, 80), 
      mse = TRUE
    ) %>% 
    group_by(year, crosswalk_period, statefip, {{ .geo_level }}) %>% 
    summarise(
      pctl_income = survey_quantile(
        household_income, 
        quantiles = c(0.2, 0.5, 0.8), 
        vartype = "ci",
        na.rm = FALSE,
        qrule = "hf3"
      ),
      n = n()
    ) %>%
    ungroup()
  
}