#' Compare Local and Catalog Data Frames
#'
#' Compares a local data frame with a remote catalog version to identify 
#' differences in observations and variables. Outputs formatted markdown sections
#' suitable for use with `results: asis` in Quarto/R Markdown documents.
#'
#' @param list A named list containing two data frames: `local` and `catalog`.
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
compare_data <- function(list, header) {
  
  # Output markdown header for this comparison section
  cat("### ", header, "\n\n") 
  
  # Extract local and catalog data frames from the input list
  local <- list[["local"]]
  catalog <- list[["catalog"]]
  
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
  
  # For local: find which shared variables have non-NA values in differing rows
  # This identifies variables that actually changed (not just structural differences)
  if (nrow(only_in_local) > 0 && length(vars_shared) > 0) {
    vars_diff_local <- only_in_local |>
      select(any_of(vars_shared)) |>
      summarise(across(everything(), ~sum(!is.na(.)))) |>
      pivot_longer(everything(), names_to = "variable", values_to = "n_rows") |>
      filter(n_rows > 0) |>
      pull(variable)
  } else {
    vars_diff_local <- character(0)
  }
  
  # For catalog: find which shared variables have non-NA values in differing rows
  if (nrow(only_in_catalog) > 0 && length(vars_shared) > 0) {
    vars_diff_catalog <- only_in_catalog |>
      select(any_of(vars_shared)) |>
      summarise(across(everything(), ~sum(!is.na(.)))) |>
      pivot_longer(everything(), names_to = "variable", values_to = "n_rows") |>
      filter(n_rows > 0) |>
      pull(variable)
  } else {
    vars_diff_catalog <- character(0)
  }
  
  # --- COMBINE RESULTS: SCHEMA + VALUE DIFFERENCES ---
  
  # Combine variables that are either new/removed OR have changed values in local
  vars_with_diffs_local <- unique(c(vars_only_local, vars_diff_local))
  
  cat("**Variables in local that differ from catalog (new or changed values):**\n\n")
  if (length(vars_with_diffs_local) > 0) {
    cat(paste("-", vars_with_diffs_local, collapse = "\n"), "\n")
  } else {
    cat("None\n")
  }
  cat("\n")
  
  # Combine variables that are either new/removed OR have changed values in catalog
  vars_with_diffs_catalog <- unique(c(vars_only_catalog, vars_diff_catalog))
  
  cat("**Variables in catalog that differ from local (new or changed values):**\n\n")
  if (length(vars_with_diffs_catalog) > 0) {
    cat(paste("-", vars_with_diffs_catalog, collapse = "\n"), "\n")
  } else {
    cat("None\n")
  }
  cat("\n")
  
}