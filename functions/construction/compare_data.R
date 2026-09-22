#' Compare Local and Catalog Data Frames
#'
#' Compares a local data frame with a remote catalog version to identify 
#' differences in observations and variables. Outputs formatted markdown sections
#' suitable for use with `results: asis` in Quarto/R Markdown documents.
#'
#' @param data_list A named list containing two data frames: `local` and `catalog`.
#'   Both should have comparable structures for meaningful comparison.
#' @param header Character string. The header text to display for this comparison
#'   section (typically the file name being compared).
#'
#' @return NULL. The function outputs formatted text and tables directly via 
#'   `cat()` and `print()` for rendering in markdown documents.
#'
#' @details 
#' The function performs the following comparisons:
#' \itemize{
#'   \item Identifies observations (rows) unique to local or catalog datasets
#'   \item Counts differing observations by year
#'   \item Lists variables (columns) present in only one dataset
#'   \item Identifies shared variables that have different values
#' }
#'
#' This function requires `dplyr`, `tidyr`, and `knitr` packages and is 
#' designed to be called within a `walk2()` loop with `results: asis`.
#'
#' @examples
#' \dontrun{
#' data_list <- list(
#'   local = read_csv("local_file.csv"),
#'   catalog = read_csv("https://example.com/catalog_file.csv")
#' )
#' compare_data(data_list, "mobility-metrics_county.csv")
#' }
#'
#' @export
compare_data <- function(data_list, header) {
  
  # Output markdown header for this comparison section
  cat("### ", header, "\n\n") 
  
  # Extract local and catalog data frames from the input list
  local <- data_list[["local"]]
  catalog <- data_list[["catalog"]]
  
  if (identical(as.data.frame(local), as.data.frame(catalog))) {
    
    cat("Files are identical!\n\n")
    
    return(NULL)
    
  }
  
  # Get all shared column names to use as join keys
  by_all <- intersect(names(local), names(catalog))
  
  # --- COMPARE OBSERVATIONS (ROWS) ---
  
  # Find observations that exist in local but not in catalog
  # (includes both new rows and rows with changed values)
  only_in_local <- anti_join(
    local, 
    catalog, 
    by = by_all,
    na_matches = "na"
  )
  
  # Display count of differing observations in local, grouped by year
  cat("**Observations only in local (or values changed):**\n\n")
  print(knitr::kable(count(only_in_local, year)))
  cat("\n\n")
  
  # Find observations that exist in catalog but not in local
  # (includes both removed rows and rows with changed values)
  only_in_catalog <- anti_join(
    catalog,
    local, 
    by = by_all,
    na_matches = "na"
  )
  
  # Display count of differing observations in catalog, grouped by year
  cat("**Observations only in catalog (or values changed):**\n\n")
  print(knitr::kable(count(only_in_catalog, year)))
  cat("\n\n")
    
  # --- COMPARE VARIABLES (COLUMNS) ---
  
  # Find variables that exist in only one dataset (schema differences)
  vars_only_local <- setdiff(names(local), names(catalog))
  vars_only_catalog <- setdiff(names(catalog), names(local))
  
  cat("**Variables only in local:**\n\n")
  if (length(vars_only_local) > 0) {
    cat(paste("-", vars_only_local, collapse = "\n"), "\n")
  } else {
    cat("None\n")
  }
  cat("\n")
  
  cat("**Variables only in catalog:**\n\n")
  if (length(vars_only_catalog) > 0) {
    cat(paste("-", vars_only_catalog, collapse = "\n"), "\n")
  } else {
    cat("None\n")
  }
  cat("\n")
  
  # --- IDENTIFY SHARED VARIABLES WITH VALUE DIFFERENCES ---
  
  # Get all variables that exist in both datasets
  vars_shared <- intersect(names(local), names(catalog))
  
  mae <- vector(mode = "numeric", length = length(vars_shared))
  median <- vector(mode = "numeric", length = length(vars_shared))
  vars_differ <- vector(mode = "logical", length = length(vars_shared))
  vars_obs_differ <- vector(mode = "numeric", length = length(vars_shared))
  names(mae) <- vars_shared
  names(median) <- vars_shared
  names(vars_differ) <- vars_shared
  names(vars_obs_differ) <- vars_shared
  for (var in vars_shared) {

    vars_differ[var] <- identical(pull(local, var), pull(catalog, var))


    # compare the first values
    local_vec <- pull(local, var)
    catalog_vec <- pull(catalog, var)[1:length(local_vec)]
    
    # calcualte MAE
    if (is.numeric(pull(local, var))) {

      mae[var] <- mean(abs(local_vec - catalog_vec), na.rm = TRUE)
      median[var] <- median(abs(catalog_vec), na.rm = TRUE)

    }
    # compare for equivalence and correctly handle NA
    result <- local_vec != catalog_vec
    both_na <- is.na(local_vec) & is.na(catalog_vec)
    result[is.na(result)] <- TRUE # one side is NA, treat as different
    result[both_na] <- FALSE      # both NA, treat as same
    
    vars_obs_differ[var] <- sum(result)
    
  }

  mae_diffs <- mae[mae != 0]
  median <- median[mae != 0]
  vars_with_diffs <- vars_shared[!vars_differ]
  vars_num_diffs <- vars_obs_differ[!vars_differ]
  
  # --- COMBINE RESULTS: SCHEMA + VALUE DIFFERENCES ---
  
  cat("**Variables in local that differ from catalog (new or changed values):**\n\n")
  if (length(vars_with_diffs) > 0) {
    cat(paste("-", 
    paste0(vars_with_diffs, " (", vars_num_diffs, ")"), 
    paste0("(", round(mae_diffs[vars_with_diffs], 6),"/", round(median[vars_with_diffs], 4), ")"), 
    collapse = "\n"), "\n")
  } else {
    cat("None\n")
  }
  cat("\n")
  
}