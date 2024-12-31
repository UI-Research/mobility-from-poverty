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
    
    rm(micro_data)
    
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
    
    # my-bucket 
    my_bucket <- "mobility-from-poverty-test"
    
    # write file to S3
    tmp <- tempfile()
    on.exit(unlink(tmp))
    saveRDS(acs_imported, file = tmp)
    
    # put object with an upload progress bar
    put_object(tmp, object = paste0(s3_dir, "/", extract_name, ".rds"), bucket = my_bucket, 
               show_progress = TRUE, multipart = TRUE)
    
    aws.s3::object_exists(paste0(s3_dir, "/", extract_name, ".rds"), bucket=my_bucket)
    aws.s3::bucket_exists(bucket = my_bucket)
    
    
    # save an in-memory R object into S3
    s3save(acs_imported, bucket = "bucket", object = paste0(s3_dir, "/", extract_name, ".rds"))
    
 
    #Return the ACS data set
    return(acs_imported)
    
    

