  # Add library here for filepath
  library(here)
  library(ipumsr)
  library(aws.s3)
  library(tidyverse)
  
  extract_name = "umf_data_14_preschool"
  extract_description = "Microdata pull for Access to Pre-K Metric Predictors. American Community Survey, 2014 (5-year)."
  survey = "us2014c"
  s3_dir = "metric_name/data/acs"
  
  
  # Set folder path, .gz, and .xml variables
  folder_path <- here("data", "temp", "raw")
  extract_gz_filename <- paste0(extract_name, "_umf.dat.gz")
  extract_xml_filename <- paste0(extract_name, "_umf.xml")

  # Create the folder path if it doesn't exist
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
  
  # Check if extract already exists in your directory. If it does this function will read in the existing data.
    
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
        download_dir =  here(folder_path),
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

  # Set AWS folder path, .gz, and .xml variables
  bucket <- "mobility-from-poverty-test"
    
aws.s3::put_object(paste0(folder_path, "/", extract_gz_filename),
                       bucket = bucket, 
                       object = paste0(s3_dir, "/", extract_gz_filename),
                       multipart = TRUE,
                       show_progress = TRUE)  
print(paste0("The following object was successfully upload to AWS S3 bucket ", 
                 bucket, "at location: ",
                 s3_dir, "/", extract_gz_filename))


aws.s3::put_object(paste0(folder_path, "/", extract_xml_filename),
                   bucket = bucket, 
                   object = paste0(s3_dir, "/", extract_xml_filename),
                   multipart = TRUE,
                   show_progress = TRUE)  
print(paste0("The following object was successfully upload to AWS S3 bucket ", 
             bucket, "at location: ",
             s3_dir, "/", extract_xml_filename ))

if (file.exists(paste0(folder_path, "/", extract_xml_filename))) {
  #Delete file if it exists
  file.remove(paste0(folder_path, "/", extract_xml_filename))
}

if (file.exists(paste0(folder_path, "/", extract_gz_filename))) {
  #Delete file if it exists
  file.remove(paste0(folder_path, "/", extract_gz_filename))
}
