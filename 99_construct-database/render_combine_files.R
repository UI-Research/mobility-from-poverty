library(quarto)
library(tidyverse)

combine_files <- list.files("99_construct-database") %>% 
  as_tibble() %>% 
  filter(str_detect(value, "construct"), str_detect(value, ".qmd")) %>% 
  print(n = 30) %>% 
  pull()

render_all <- function(file) {
  
  quarto_render(here::here("99_construct-database", file))
  
}

map(combine_files, render_all)
