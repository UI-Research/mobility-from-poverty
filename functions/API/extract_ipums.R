# API Pull Function
# 
# Using the API, read in the IPUMS micro data. To check on available surveys you can use the function get_sample_info('usa'). 
# This function allows the user to chose the survey year and type (for example 2021a is the 1-year ACS data).
#
# Function call: extract_ipums
# Inputs:
#   extract_name (str): the name of the extract that will be saved in the data/temp/raw folder
#   extract_description (str): the metadata that will be attached to this extract
#   survey (list of str): the list of survey
# Outputs:
#   extract_name_umf.dat.gz in folder data/temp/raw
#   extract_name_umf.xml in folder data/temp/raw
#   folder data/temp/raw if it does not exist already
# Returns:
#   acs_imported (tibble) containing the extract required for analysis

extract_ipums <- function(extract_name, extract_description, survey){
  # Add library here for filepath
  library(here)
  
  # Set folder path, .gz, and .xml variables
  folder_path <- here("data", "temp", "raw")
  extract_gz_filename <- paste0(extract_name, "_umf.dat.gz")
  extract_xml_filename <- paste0(extract_name, "_umf.xml")
  
  # Create the folder path if it doesn't exist
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
  
  # Check if extract already exists in your directory. If it does this function will read in the existing data.
  if(!file.exists(here(folder_path, extract_gz_filename))){
    
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
          "HISPAN",
          "EDUCD",
          "GRADEATT",
          "SEX",
          "DIFFCARE",
          "DIFFSENS",
          "DIFFMOB",
          "DIFFPHYS",
          "DIFFREM",
          "CBPERNUM"
        )
      )
    
    #Submit the extract. 
    usa_ext_umf_submitted <- submit_extract(usa_ext_umf)
    
    usa_ext_complete <- wait_for_extract(usa_ext_umf_submitted)
    
    #The directory is set to download into the "raw" data folder inside of the universal data/temp. If the data already exists this step will be skipped.
    filepath <-
      download_extract(
        usa_ext_umf_submitted,
        download_dir = here(folder_path),
        progress = TRUE
      )
    
    #Rename extract file
    ipums_files <-
      list.files(paste0(here(folder_path)), full.names = TRUE) %>%
      as_tibble() %>%
      filter(str_detect(value, "dat.gz|xml"), !str_detect(value, "umf")) %>%
      pull()
    
    file.rename(ipums_files, c(
      here(folder_path, extract_gz_filename),
      here(folder_path, extract_xml_filename)
    ))
    
  }
  
  # Read extract file
  ddi <-
    read_ipums_ddi(here(folder_path, extract_xml_filename))
  
  micro_data <-
    read_ipums_micro(
      ddi,
      data_file = here(folder_path, extract_gz_filename)
    )

  #DDI is a codebook that is used by IPUMSR to format the micro data downloaded
  #Lower variable names and get rid of unnecessary variables
  acs_imported <- micro_data %>%
    rename_with(tolower) %>% 
    select(-serial, -raced, -strata, - cluster, -hispand, -empstatd)
  
  #Zap labels and reformat State and PUMA variable
  acs_imported <- acs_imported %>%
    mutate(  
      across(c(sample, gq, race, hispan), ~as_factor(.x)),
      across(c(sample, gq, race, hispan, sex, diffcare, diffsens, diffmob, diffphys, diffrem), ~as_factor(.x)),
      across(c(statefip, puma, hhincome, vacancy, age, empstat), ~zap_labels(.x)),
      statefip = sprintf("%0.2d", as.numeric(statefip)),
      puma = sprintf("%0.5d", as.numeric(puma)),
      unique_person_id = paste0(sample, cbserial, cbpernum)
    )
  
  #Return the ACS data set
  return(acs_imported)
  
}