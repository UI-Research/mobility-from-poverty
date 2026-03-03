library(quarto)
library(tidyverse)

combine_files <- list.files("V:/Centers/HFP/JWalsh/mobility-from-poverty/10_construct-database") %>% 
  as_tibble() %>% 
  filter(str_detect(value, "construct"), str_detect(value, ".qmd")) %>% 
  print(n = 30) %>% 
  pull()

render_all <- function(file) {
  
  quarto_render(here::here("10_construct-database", file))
  
}

map(combine_files, render_all)
