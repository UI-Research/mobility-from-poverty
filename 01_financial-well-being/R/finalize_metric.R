finalize_metric <- function(.data, .geo_level) {
  
  .data %>%
    arrange(year, statefip, {{ .geo_level }}) %>%
    rename(
      pctl_income_20_lb = pctl_income_q20_low,
      pctl_income_20_ub = pctl_income_q20_upp,
      pctl_income_20 = pctl_income_q20,
      pctl_income_50_lb = pctl_income_q50_low,
      pctl_income_50_ub = pctl_income_q50_upp,
      pctl_income_50 = pctl_income_q50,
      pctl_income_80_lb = pctl_income_q80_low,
      pctl_income_80_ub = pctl_income_q80_upp,
      pctl_income_80 = pctl_income_q80,
    ) 
  
}