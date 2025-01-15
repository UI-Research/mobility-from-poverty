## This script wraps a standard ipumsr::read_ipums_micro() query workflow, addressing
## two common challenges: (1) the default workflow downloads arbitrarily named raw
## data files that are sequentially numbered and dependent on the total number of extracts
## submitted by a given user; and (2) the default workflow does provide an inbuilt
## capacity to check for a local version of the query before re-submitting to the API. 
## This script addresses these challenges by taking a user-supplied filename and
## file directory, checking if there is an existing file at that path, and otherwise
## downloading the microdata extract (again user-specified) to the given filepath.

## Authors: Original code from Aaron R. Williams, extended by Will Curran-Groome
## Last Updated: 01/08/2025
 
read_ipums_micro_cached = function(
    filename, ## name of the file (not the full path)--do not include a file extension
    download_directory, ## wherever the data will be downloaded to--must be a relative path
    extract_definition, ## the object resulting from define_extract_micro()
    refresh = FALSE) { ## if true, execute the API query, even if data are already stored locally
  
  ## if the file doesn't already exist, submit the extract definition to the api
  if (!file.exists(here(download_directory, str_c(filename, ".xml"))) | refresh == TRUE) {
    
    # submit the extract to IPUMS USA for processing
    submitted_extract <- submit_extract(extract_definition)
    
    # access the extract number, stored in the return value of submit_extract
    extract_number <- str_pad(
      submitted_extract$number, 
      width = 5, 
      side = "left", 
      pad = "0")
    
    # pause the code until the extract is prepared
    wait_for_extract(submitted_extract)
    # This will save the extract files to the current directory
    # use the download_dir argument to specify a different location
    # The return value is the path to the DDI codebook file, which can then be passed to read_ipums_micro to read the data
    path_to_ddi_file <- download_extract(submitted_extract, download_dir = download_directory)
    
    # rename files so they don't depend on the extract number, which changes from 
    # extract to extract and user to user
    file.rename(
      from = here(
        download_directory, 
        str_glue("usa_{extract_number}.dat.gz", extract_number = extract_number)),
      to = here(download_directory, str_c(filename, ".dat.gz")))
    
    file.rename(
      from = here(
        download_directory, 
        str_glue("usa_{extract_number}.xml", extract_number = extract_number)),
      to = here(download_directory, str_c(filename, ".xml")))
    
  } else {
    warning("Data are being read from a local path. If you have changed the arguments
            to your define_micro_extract() call, you should delete the existing data
            file at the specified local path and then re-execute this function, which
            will then query the IPUMS API for the updated data and save it to disk.")
    path_to_ddi_file <- here(download_directory, str_c(filename, ".xml"))
  }
  
  data <- read_ipums_micro(
    ddi = here(download_directory, str_c(filename, ".xml")), 
    data_file = here(download_directory, str_c(filename, ".dat.gz")))
  
  return(data)
}