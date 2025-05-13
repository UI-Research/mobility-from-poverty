# Read extract file
library(here)
library(ipumsr)
library(aws.s3)
library(tidyverse)


bucket <- "mobility-from-poverty-test"
s3_dir <- "metric_name/data/acs"
filename_gz <- "umf_data_14_preschool_umf.dat.gz"
filename_xml <- "umf_data_14_preschool_umf.xml"


aws.s3::object_exists(paste0(s3_dir, "/", filename_xml), bucket=bucket)
  
obj_key <- paste0(s3_dir, "/", filename_xml)

## Try putting the read_ipums_ddi function directly into the FUN argument below!!

ddi <- s3read_using(FUN=read_ipums_ddi, 
             bucket = bucket, 
             object=obj_key)

obj_key <- paste0(s3_dir, "/", filename_gz)

micro_data <- s3read_using(FUN=read_ipums_micro(ddi, .x), 
                           bucket = bucket, 
                           object=obj_key)

    
    
    temp_file <- tempfile()
    
    obj_key <- paste0(s3_dir, "/", filename_gz)
    
    aws.s3::save_object(object = obj_key,
                        bucket = bucket,
                        file = temp_file) 
    
## I have made it to this point but something breaks down between the read_ipums function and the file brought in from AWS
    micro_data <-
      read_ipums_micro(
        ddi,
        data_file = temp_file
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