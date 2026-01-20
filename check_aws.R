# Set folder path, .gz, and .xml variables

s3_dir <- "metric_name/data/acs"
my_bucket <- "mobility-from-poverty-test"

extract_date <- "01_16_26"

extract_name <- "umf_data_2024_1year_acs"
folder_path <- here::here("data", "temp", "raw")
extract_gz_filename <- paste0(extract_name, "_umf.dat.gz")
extract_xml_filename <- paste0(extract_name, "_umf.xml")


#Check if file exists in AWS

aws.s3::object_exists(paste0(s3_dir, "/", extract_name, "_", extract_date, ".rds"), bucket = my_bucket)
  
aws.s3::bucket_exists(my_bucket)
