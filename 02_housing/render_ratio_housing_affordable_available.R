## Note: this code is significantly adopted, at times verbatim, from:
## https://posit.co/blog/parameterized-quarto/

library(tidyverse)
library(quarto)
library(here)
library(xfun)

parameters = tibble(
  geography = c("county", "place"),
  county_years = list(c(2022))) %>%
  mutate(
    place_years = county_years,
    years = map_chr(county_years, ~ str_c(.x, collapse = "_")),
    output_file = str_c("ratio_housing_affordable_available_", geography, "_", years, ".html"),
    execute_params = pmap(
      list(geography, county_years, place_years, output_file),
      function(geography, county_years, place_years, output_file) { 
        list(
          geography = geography, 
          output_file = output_file,
          county_years = county_years,
          place_years = place_years)})) %>% 
  select(-c(geography, county_years, place_years, years, output_file))

in_dir(
  dir = here("02_housing"),
  expr = pwalk(
    .l = parameters,                     
    .f = quarto_render, 
    input = "ratio_housing_affordable_available.qmd",
    output_format = "all",
    execute = TRUE,
    .progress = TRUE))
