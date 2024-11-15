## Note: this code is significantly adopted, at times verbatim, from:
## https://posit.co/blog/parameterized-quarto/

library(tidyverse)
library(quarto)

parameters = tibble(
  geography = c("county", "place"),
  county_years = list(c(2021, 2022), c(2021, 2022)),
  place_years = list(c(2021, 2022), c(2021, 2022))) %>%
  mutate(
    output_format = "html",
    years = map_chr(county_years, ~ str_c(.x, collapse = "_")),
    output_file = str_c("ratio_housing_affordable_availabe_", geography, "_", years, ".html"),
    execute_params = pmap( # Named list of parameters
      list(geography, county_years, place_years),
      function(geography, county_years, place_years) { 
        list(
          geography = geography, 
          county_years = county_years,
          place_years = place_years)})) %>% 
  select(-c(geography, county_years, place_years, years))

pwalk(
  .l = parameters,                     
  .f = quarto_render, 
  input = here("02_housing", "ratio_housing_affordable_available.qmd"),
  .progress = TRUE )