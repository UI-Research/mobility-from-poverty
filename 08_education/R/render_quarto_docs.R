library(quarto)
library(here)


quarto_render(
  input = here::here("08_education", "preschoole_place_calculate.qmd"),
  output_file = here::here("08_education", "Calculate access to pre-kindergarten 2016.html"),
  execute_params = list(year = "2016"),
  execute_dir = here::here(),
)
