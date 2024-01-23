## API Pull Function

#Using the API, read in the IPUMS micro data. To check on available surveys you can use the function get_sample_info("usa"). 
#This function allows the user to chose the survey year and type (for example 2021a is the 1-year ACS data).

extract_ipums <- function(extract_name, extract_description, survey){
  
  #Check if extract already exists in your directory. If it does this function will read in the existing data.
  if(!file.exists(here::here("data", "temp", "raw", paste0(extract_name, "_umf.dat.gz")))){
    
    #If extract does not exist, create the extract using the IPUMS API
    usa_ext_umf <-
      define_extract_usa(
        description = extract_description,
        samples = c(survey),
        variables = c(
          "ADJUST",
          "STATEFIP",
          "PUMA",
          "GQ",
          "HHINCOME",
          "AGE",
          "EMPSTAT",
          "VACANCY",
          "PERNUM",
          "RACE",
          "HISPAN"
          
        )
      )
    
    #Submit the extract. 
    usa_ext_umf_submitted <- submit_extract(usa_ext_umf)
    
    usa_ext_complete <- wait_for_extract(usa_ext_umf_submitted)
    
    #The directory is set to download into the "raw" data folder inside of the universal data/temp. If the data already exists this step will be skipped.
    filepath <-
      download_extract(
        usa_ext_umf_submitted,
        download_dir = here::here("data", "temp", "raw"),
        progress = FALSE
      )
    
    #Rename extract file
    
    ipums_files <-
      list.files(paste0(here::here("data", "temp", "raw")), full.names = TRUE) %>%
      as_tibble() %>%
      filter(str_detect(value, "dat.gz|xml"), !str_detect(value, "umf")) %>%
      pull()
    
    file.rename(ipums_files, c(
      here::here("data", "temp", "raw", paste0(extract_name, "_umf.dat.gz")),
      here::here("data", "temp", "raw", paste0(extract_name, "_umf.xml"))
    ))
    
  }
  
  # Read extract file
  ddi <-
    read_ipums_ddi(here::here("data", "temp", "raw", paste0(extract_name, "_umf.xml")))
  
  micro_data <-
    read_ipums_micro(
      ddi,
      data_file = here::here("data", "temp", "raw", paste0(extract_name, "_umf.dat.gz"))
    )
  
  #Lower variable names and get rid of unnecessary variables
  acs_imported <- micro_data %>%
    rename_with(tolower) %>% 
    select(-serial, -cbserial, -raced, -strata, - cluster, -hispand, -empstatd)
  
  #Zap labels and reformat State and PUMA variable
  acs_imported <- acs_imported %>%
    mutate(  
      across(c(sample, gq, race, hispan), ~ as_factor(.x)),
      across(c(statefip, puma, hhincome, vacancy, age, empstat), ~zap_labels(.x)),
      statefip = sprintf("%0.2d", as.numeric(statefip)),
      puma = sprintf("%0.5d", as.numeric(puma))
    )
  
  #Return the ACS data set
  return(acs_imported)
  
}