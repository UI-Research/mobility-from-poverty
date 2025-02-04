# API Rep Weight Pull Function
# 
# Using the API, read in the IPUMS micro data replicate weights for individuals between 19 and 20 years old. To check on available surveys you can use the function get_sample_info('usa'). 
# This function allows the user to chose the survey year and type (for example 2021a is the 1-year ACS data).
#
# Function call: ipums_repwt_employment
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

# Add library here for filepath
library(here)
library(ipumsr)
library(aws.s3)
library(tidyverse)

ipums_repwt_employment_aws <- function(extract_name, extract_date, extract_description, survey){
  
  # Set folder path, .gz, and .xml variables
  folder_path <- here("data", "temp", "raw")
  extract_gz_filename <- paste0(extract_name, "_umf.dat.gz")
  extract_xml_filename <- paste0(extract_name, "_umf.xml")
  
  
  #Check if file exists in AWS
  
  if (aws.s3::object_exists(paste0(s3_dir, "/", extract_name, "_", extract_date, ".rds"), bucket = my_bucket)){
    
    acs_imported <- s3read_using(FUN=readRDS, 
                                 bucket = my_bucket, 
                                 object=paste0(s3_dir, "/", extract_name, "_", extract_date, ".rds"))
  } else{
  
  # Create the folder path if it doesn't exist
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
  
  #Create a list of employed years for the extract specifications 
  employed_years <- tibble(as.character(25:54)) %>% 
    pull()
  # Check if extract already exists in your directory. If it does this function will read in the existing data.
  if(!file.exists(here(folder_path, extract_gz_filename))){
    
    #If extract does not exist, create the extract using the IPUMS API. Note for employment opportunities we only need 25 and 54 year olds.
    usa_ext_umf <-
      define_extract_usa(
        description = extract_description,
        samples = c(survey),
        variables = list(
          var_spec("AGE", 
                   case_selections = employed_years),
          "REPWTP",
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
        progress = FALSE
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
  
  #Lower variable names and get rid of unnecessary variables
  acs_imported <- micro_data %>%
    rename_with(tolower) %>% 
    select(-serial, -strata, -cluster, -year,
           -pernum, -perwt, -hhwt, -gq, -age) %>% 
    mutate(sample = as_factor(sample),
           unique_person_id = paste0(sample, cbserial, cbpernum))
  
  
  # my-bucket 
  my_bucket <- "mobility-from-poverty-test"
  
  # write file to S3
  tmp <- tempfile()
  on.exit(unlink(tmp))
  saveRDS(acs_imported, file = tmp, compress = TRUE)
  
  # put object with an upload progress bar
  put_object(tmp, object = paste0(s3_dir, "/", extract_name, "_", extract_date, ".rds"), bucket = my_bucket, 
             show_progress = FALSE, multipart = TRUE)
  
  }

  #Return the ACS data set
  return(acs_imported)
  
}