# run_homelessness.R
# Runner script for homelessness metric

library(quarto)
library(here)

# Render for county
quarto_render(
  here("12_housing-stability", "homelessness.qmd"),
  execute_params = list(geography = "county", years = 2019:2022)
)

# Render for place
quarto_render(
  here("12_housing-stability", "homelessness.qmd"),
  execute_params = list(geography = "place", years = 2019:2022)
)
