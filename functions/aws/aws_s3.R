library(aws.s3)
library(XML)


#' Save files to AWS S3 bucket
#' 
#' @description
#' This function writes and saves a locally stored file to bucket 
#' `mobility-from-poverty-test` in AWS S3.
#' 
#' @param s3_dir A folder/directory path in S3 where file should be saved.
#' @param local_file_path A local file path where the file to be copied to S3 exists.
#' 
#' @return This function copies a local file to S3 bucket.
#' 
#' @usage save_to_s3(s3_dir = "metric_name/data/acs", 
#' local_file_path = here::here("functions", "temp", "umf_data_14_16.dat.gz"))
#' 
save_to_s3 <- function(s3_dir, local_file_path) {
  
  bucket <- "mobility-from-poverty-test"
  
  obj_name <- basename(local_file_path)
  
  if(!aws.s3::object_exists(paste0(s3_dir, "/", obj_name), bucket=bucket)) {
    
    aws.s3::put_object(local_file_path, 
               bucket = bucket, 
               object = paste0(s3_dir, "/", obj_name),
               multipart = TRUE,
               show_progress = TRUE)  
    print(paste0("The following object was successfully upload to AWS S3 bucket ", 
                 bucket, "at location: ",
                 s3_dir, "/", obj_name ))
    
    } else {
    
    print(paste0("The following object already exists in AWS S3 bucket ", 
                 bucket, "at location: ",
                 s3_dir, "/", obj_name ))
  }
  
}



#' Read files from AWS S3 bucket
#' 
#' @description
#' This function reads a file from AWS S3 bucket `mobility-from-poverty-test`.
#' 
#' @param s3_dir A folder/directory path in S3 where file should be saved.
#' @param filename Name of the file to be read from S3.
#' 
#' @return This function reads and returns a file from S3 bucket for supported
#' file formats - csv, xml, and gz.
#' 
#' @usage read_from_s3(s3_dir = "metric_name/data/acs", 
#' filename = "umf_data_14_16.dat.gz")
#' 

read_from_s3 <- function(s3_dir, filename) {
  
  bucket <- "mobility-from-poverty-test"
  
  obj_key <- paste0(s3_dir, "/", filename)
  
  if(aws.s3::object_exists(obj_key, bucket = bucket)) {
    
    temp_file <- tempfile()
    
    aws.s3::save_object(object = obj_key,
                                     bucket = bucket,
                                     file = temp_file) 
    
    # determine file type
    ext <- tools::file_ext(obj_key)
    
    if (ext == "csv") {
      
      data <- read_csv(temp_file)
      
    } else if (ext == "gz") {
      
      unzip_file <- gunzip(temp_file, temporary = TRUE)
      data <- read.table(unzip_file, header = TRUE)
      
    } else if (ext == "xml") {
      
      data <- xmlParse(temp_file)
    } 
    print(paste0("Successfully read the following object from AWS S3: ", 
                 obj_key))
    
    return (data)
  
    } else {
    
      print(paste0("The following object does not exist in AWS S3: ", 
                   obj_key))
      return (NULL)
  }
}


#' Delete files from AWS S3 bucket
#' 
#' @description
#' This function deletes a file from AWS S3 bucket `mobility-from-poverty-test`.
#' 
#' @param obj_key A folder/directory path in S3 including the name of the file 
#' to be deleted.
#' 
#' @return This function deletes a file from S3 bucket.
#' 
#' @usage delete_from_s3(obj_key = "metric_name/data/acs/umf_data_14_16.dat.gz")
#' 
delete_from_s3 <- function(obj_key) {
  
  bucket <- "mobility-from-poverty-test"
  
  if(aws.s3::object_exists(obj_key, bucket = bucket)) {
    
    aws.s3::delete_object(obj_key, bucket = bucket)
    print(paste0("Successfully deleted the following object fom AWS S3: ", 
                 obj_key))
  } else {
    
    print(paste0("The following object does not exist in AWS S3 so ",
    "it could not be deleted: ", obj_key)) 
  }
}