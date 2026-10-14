# Author: Ridhi Purohit
# Reference: Upgraded `evaluate_final_data.R` initially developed by John Walsh.
# Date Modified: 18-June-2025

library(here)
library(tidyverse)


#' Final data evaluation - test function
#' @description This functions runs checks on the final data.
#' 
#' Note: Prior to running this function users should read the guidance on creating final data files 
#' based on the Metric Technical Specification 2026.
#'
#' @param metric_var (character): The name of metric variable referenced in data. 
#' 
#' @param data (character): The data that is staged to be read out as the final file.
#' 
#' @param geo (character): Either "place" or "county" depending on the level of data being tested.
#' 
#' @param all_expected_years (logical): A TRUE or FALSE value indicating if data contains all expected metric years. 
#' If FALSE then the years being tested must be a set of all expected metric years.
#' 
#' @param subgroups (logical): A TRUE or FALSE value indicating if the final data has subgroups.
#' 
#' @param subgrp_type (character) : A vector providing the subgroup types to expect in data.
#' 
#' @param confidence_intervals  (logical): A TRUE or FALSE value indicating if the final data has confidence intervals.
#' 
#' @return: A series of test outcomes with a summary of errors encountered.
#' 
#' @example evaluate_final_data(
#'                              metric_var = "share_digital_access", 
#'                              data = df_final_data, 
#'                              geo = "county", 
#'                              all_expected_years = TRUE,
#'                              subgroups = TRUE, 
#'                              subgrp_type = c("all", "race-ethnicity", "income"),
#'                              confidence_intervals = FALSE,
#'                              )
#'  
#'                                
evaluate_final_data <- function(metric_var, 
                                data, 
                                geo, 
                                all_expected_years = TRUE,
                                subgroups = FALSE, 
                                subgrp_type = "all",
                                confidence_intervals = FALSE
) {
  
  # Read in the technical specification for the metric
  tech_spec_all <- get_tech_spec() 
  
  # Check if metric (and subgroup types) exists in technical specification
  check_metric_subgroup_exists(metric_var, tech_spec_all, geo, subgroups, subgrp_type)
  
  # Tech spec for relevant metric
  tech_spec <- get_subset_tech_spec(tech_spec_all, metric_var, geo, subgroups)
  
  if ( (isTRUE(subgroups)) & (!is.null(subgrp_type)) ) {
    
    # Check user provided subgroup types against subgroup types in data
    check_user_data_subgroup_types(data, subgrp_type)
    
    #Pull subgroup list from technical specification
    expected_subgroups <- get_expected_subgroups(tech_spec, subgrp_type)
    
  } 
  
  # Pull year list for overall or each subgroup type from technical specification
  expected_years <- get_expected_years(tech_spec, subgroups, subgrp_type)
  
  
  # Pull expected variable names
  expected_variables <- get_expected_metric_vars(tech_spec)

  # Pull expected value range from technical specification
  expected_range <- tech_spec %>%
    pull(range) %>%
    na.omit() %>%
    .[. != ""] %>%
    unique()

  range_bounds <- if (length(expected_range) > 0) parse_range(expected_range[1]) else NULL

  ### CHECKS
  
  checks <- list(
    
    list(
      # check that the file has the necessary columns in order
      # check that the first few columns are year, state, county/place, subgroup_type, subgroup
      chk = "Column Order",
      expr = function() check_col_order(data, subgroups),
      cond = TRUE,
      msg = "Columns are not in expected order: year, state, county/place, subgroup_type, subgroup."
    ),
    list(
      # Compare final data and technical specification variable titles
      chk = "Column Names",
      expr = function() check_column_names(data, expected_variables, geo, subgroups),  
      cond = TRUE,
      msg = "Column names don't match the expectation."
    ),
    list(
      # Check length of fips values
      chk = "FIPS Code",
      expr = function() check_fips_length(data, geo),
      cond = TRUE,
      msg = "Some FIPS codes have unexpected number of digits."
    ),
    list(
      # Check if expected subgroup values are present in final data
      chk = "Subgroup Values",
      expr = function() check_subgroup_values(data, expected_subgroups),
      cond = isTRUE(subgroups),
      msg = "Expected subgroups are missing in data."
    ),
    list(
      # Check if all expected years are present in final data or user provided years are present 
      # (must be a subset of all expected metric years)
      chk = ifelse(isTRUE(all_expected_years), "All Expected Metric Years", "User Provided Expected Metric Years"),
      expr = function() check_expected_years(data, expected_years, subgroups),
      cond = TRUE,
      msg = "Expected years are missing in data."
    ),
    list(
      # Check if confidence intervals and data quality NA values align
      chk = "Confidence Interval and Quality Variables NAs",
      expr = function() check_NA_across_rows(data),
      cond = isTRUE(confidence_intervals),
      msg = "Confidence interval and quality variables don't have NA values in alignemnet."
    ),
    list(
      # Check metric values fall within the expected range from the tech spec
      chk = "Value Ranges",
      expr = function() check_value_ranges(data, metric_var, range_bounds),
      cond = !is.null(range_bounds),
      msg = "Some metric values are outside the expected range from the tech spec."
    ),
    list(
      # Check for duplicate rows based on key columns
      chk = "Duplicate Rows",
      expr = function() check_duplicates(data, geo, subgroups),
      cond = TRUE,
      msg = "Duplicate rows detected in the data."
    ),
    list(
      # Check quality flag columns only contain valid values (1, 2, 3, or NA)
      chk = "Quality Flag Values",
      expr = function() check_quality_flag_values(data),
      cond = TRUE,
      msg = "Quality flag columns contain values other than 1, 2, 3, or NA."
    ),
    list(
      # Check number of unique geographies per year is within expected range
      chk = "Row Counts",
      expr = function() check_row_counts(data, geo),
      cond = TRUE,
      msg = "Number of unique geographies per year is outside the expected range."
    )
  )
  
  # Apply function to run each check
  check_results <- lapply(
    checks,
    function(check) {
      
      # Run check if condition is met otherwise return TRUE to handle subgroup tests
      if (check$cond) run_data_check(check$expr, check$msg, check$chk) else TRUE
    }
  )
  
  
  if (all(unlist(check_results))) {
    
    print("This data passes all tests!")
    
  } else {
    
    print("Some data checks failed. See messages above for details.")
    
  }
}

#------------------------- HELPER FUNCTIONS ------------------------------------

#' Runs all the data checks and catches any errors in execution
#' 
#' @param check_expr A function containing the check to run.
#' @param error_msg A message to display if the check fails.
#' @param chk A label for the check being run.
#' 
#' @returns TRUE if the check passes, FALSE if it fails.
#' 
run_data_check <- function(check_expr, error_msg, chk) {
  
  tryCatch(
    {
      
      check_expr()
      
      print(paste0("Check passed: ", chk))
      
      return (TRUE)
    },
    error = function(e) {
      
      print(paste0("Check failed: ", chk))
      
      message(paste0(error_msg, "\n Error Details: ", e$message))
      return (FALSE)
    }
  )
}


#' Reads the metrics technical specification
#' 
#' @returns A data frame containing the metrics technical specification.
#' 
get_tech_spec <- function() {
  
  
  # Read in the technical specification for the metric
  tech_spec_path <- "data/technical_specification/metrics_technical_spec_2026.csv"
  
  tech_spec <- read_csv(here::here(tech_spec_path), 
                        show_col_types = FALSE) %>% 
    janitor::clean_names() 
  
  return (tech_spec)
  
}


#' Subsets technical specification for relevant metric(s)
#' 
#' @param df_tech_spec The metrics technical specification data frame.
#' @param metric_var The metric variable to filter for.
#' @param geo The geography level to filter for.
#' @param subgroups Logical indicating if subgroups are used.
#' 
#' @returns A technical specification data frame filtered for the specified metric and geography.
#' 
get_subset_tech_spec <- function(df_tech_spec, metric_var, geo, subgroups) {
  
  # Subset data based on presence of subgroup
  if (isTRUE(subgroups)) {
    
    tech_spec <- df_tech_spec %>% 
      filter((metric %in% metric_var) & geography==geo)
  } else {
    
    tech_spec <- df_tech_spec %>% 
      filter((metric %in% metric_var) & geography==geo & subgroup_type=="all")
  }
  
  return (tech_spec)
  
}


#' Finds expected subgroups for metric if applicable
#' 
#' @param df_tech_spec The technical specification for relevant metric.
#' @param subgrp_type The subgroup type(s) to filter for.
#' 
#' @returns A character vector of expected subgroup values.
#' 
get_expected_subgroups <- function(df_tech_spec, subgrp_type) {
  
  expected_subgroups <- df_tech_spec %>% 
    filter(subgroup_type %in% subgrp_type) %>%
    pull(subgroup) %>% 
    strsplit(split = ";") %>% 
    unlist() %>% trimws() 
  
  return (expected_subgroups)
}


#' Finds expected years for metric if applicable
#' 
#' @param df_tech_spec The technical specification for relevant metric.
#' @param subgrp_type The applicable subgroup type(s) to filter for.
#' 
#' @returns A data frame of subgroup types and their years, or a unique vector 
#' of years if no subgroup type is provided.
#' 
get_expected_years <- function(df_tech_spec, subgroups, subgrp_type) {
  
  if (isTRUE(subgroups) & (!is.null(subgrp_type))) {
    
    expected_years <- df_tech_spec %>%
      filter(subgroup_type %in% subgrp_type) %>%
      select( subgroup_type, subgroup_years) %>%
      mutate(
        subgroup_years = map(subgroup_years, ~ as.numeric(trimws(unlist(strsplit(.x, ";")))))
      )
  } else {
    
    expected_years <- df_tech_spec %>%
      mutate(
        years = map(years, ~ as.numeric(trimws(unlist(strsplit(.x, ";")))))
      ) %>% 
      pull(years) %>%
      unlist() %>% 
      unique()
  }
  
  return (expected_years)
}


#' Finds expected metric related variables
#' 
#' @param df_tech_spec The technical specification for relevant metric.
#' 
#' @returns A character vector of expected variable names for the metric, 
#' including confidence interval variables if applicable.
#' 
get_expected_metric_vars <- function(df_tech_spec) {
  
  expected_variables <- df_tech_spec %>% 
    select(metric, quality) %>%
    unlist() %>%
    unique()
  
  if (any((df_tech_spec$has_ci) == "Yes")) {
    
    ci_vars <- df_tech_spec %>% 
      filter(has_ci == "Yes") %>% 
      select(ci_lower, ci_upper) %>% 
      unlist() %>% 
      unique()
    
    expected_variables <- sort(unique( c(expected_variables, ci_vars) ))
  }
  
  return (expected_variables)
  
} 


#--------------------- DATA EVALUATION FUNCTIONS -------------------------------

#' Checks if metric and/or subgroup is valid 
#' 
#' @param metric_var The metric variable to check in technical specification.
#' @param tech_spec A data frame containing metrics technical specification.
#' @param subgrp_type The applicable subgroup type(s) to check in technical specification for the metric.
#' 
#' @returns NULL (prints check results and stops execution of further checks)
#' 
check_metric_subgroup_exists <- function(metric_var, tech_spec, geo, subgroups, subgrp_type) {
  
  tryCatch(
    {
      geo_tech_spec <- tech_spec %>% filter(geography == geo)
      
      stopifnot( metric_var %in% geo_tech_spec$metric )
      
      print("Check passed: Metric Variable Name in Tech Spec")
    },
    error = function(e) {
      
      stop(
        paste0("\n Check failed: Metric Variable Name in Tech Spec",
               "\n Metric variable, '", metric_var, 
               "', is not present in the technical specification ",
               "for geography, '", geo, "'.", 
               "\n Details: ", e$message)
      )
    })
  
  
  tryCatch(
    
    if (isTRUE(subgroups) & (!is.null(subgrp_type))) {
      
      metric_spec <- tech_spec %>% filter(geography==geo, metric==metric_var)
      
      stopifnot( subgrp_type %in% metric_spec$subgroup_type  )
      
      print("Check passed: Subgroup Type Names in Tech Spec")
    },
    error = function(e) {
      
      stop(
        paste0("\n Check failed: Subgroup Type Names in Tech Spec",
               "\n Subgroup type(s) is not present in the technical specification for metric '", 
               metric_var, "'.", 
               "\n Details: ", e$message))
    }
  )
}

#' Checks if user provided subgroup type values match subgroup types in data
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param user_subgrp_type The user provided subgroup type(s) to check for the metric.
#' 
#' @returns NULL (prints check results and messages)
#' 
check_user_data_subgroup_types <- function(data, user_subgrp_type) {
  
  tryCatch(
    {
      data_subgrp_type <- data %>% pull(subgroup_type) %>% unique()
      
      stopifnot(all(sort(user_subgrp_type) == sort(data_subgrp_type)))
      
      print("Check passed: User Provided and Data Subgroup Type Values")
      
    }, 
    error = function(e) {
      
      print("Check failed: User Provided and Data Subgroup Type Values")
      
      message("User provided subgroup type are not present in the data.", 
              "\n Details: ", e$message)
    }
  )
}

#' Checks order of columns in data
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param subgroups A TRUE or FALSE value indicating if the final data has subgroups.
#' 
#' @returns NULL (throws error if column order is incorrect)
#' 
check_col_order <- function(data, subgroups) {
  # check that the file has the necessary columns
  # check that the first few columns are year, state
  data_names <- names(data)
  
  stopifnot(data_names[1] == "year")
  stopifnot(data_names[2] == "state")
  stopifnot(data_names[3] == "county" | data_names[3] == "place")
  
  if (isTRUE(subgroups)) {
    
    stopifnot(data_names[4] == "subgroup_type")
    stopifnot(data_names[5] == "subgroup")
    
  }
  
}


#' Checks if NAs in quality variable match with confidence interval variables
#' 
#' @param data The data that is staged to be read out as the final file.
#' 
#' @returns NULL (throws error if NAs are not aligned)
#' 
check_NA_across_rows <- function(data) {
  
  stopifnot(sum(is.na(select(data, ends_with("_lb")))) == sum(is.na(select(data, ends_with("_quality")))))
  stopifnot(sum(is.na(select(data, ends_with("_ub")))) == sum(is.na(select(data, ends_with("_quality")))))
  stopifnot(sum(is.na(select(data, ends_with("_ub")))) == sum(is.na(select(data, ends_with("_lb")))))
  
  stopifnot(
    apply( 
      data %>% select(ends_with("_lb"), ends_with("_ub"), ends_with("_quality")), 
      1, 
      function(row) { 
        if (any(is.na(row)))  all(is.na(row)) else TRUE
      })
  )
}


#' Checks FIPS codes are of correct length
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param geo  Either "place" or "county" depending on the level of data being tested.
#' 
#' @returns NULL (throws error if geoids are of mismatched length)
#' 
check_fips_length <- function(data, geo) {
  
  if (geo == "county") {
    
    data_geoid <- data |>
      dplyr::mutate(state = str_pad(state, width = 2, side = "left", pad = "0"),
                    county = str_pad(county, width = 3, side = "left", pad = "0"),
                    geoid = paste0(state, county),
                    geoid_length = stringr::str_length(geoid)) 
    
  }
  
  if (geo == "place") {
    
    data_geoid <- data |>
      dplyr::mutate(state = str_pad(state, width = 2, side = "left", pad = "0"),
                    place = str_pad(place, width = 5, side = "left", pad = "0"),
                    geoid = paste0(state, place),
                    geoid_length = stringr::str_length(geoid))
    
  }
  
  # are there missing leading zeros?
  stopifnot(length(unique(dplyr::pull(data_geoid, geoid_length))) == 1)
  
}


#' Checks column names for metric variables
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param expected_vars A character vector of expected variable names for the metric, 
#' including confidence interval variables if applicable.
#' @param geo  Either "place" or "county" depending on the level of data being tested.
#' @param subgroups A TRUE or FALSE value indicating if the final data has subgroups.
#' 
#'  @returns NULL (throws error if data column names aren't as expected)
#' 
check_column_names <- function(data, expected_vars, geo, subgroups) {
  
  if (isTRUE(subgroups)) {
    expected_vars_all <- sort(c(expected_vars, c("year", "state", geo, "subgroup_type", "subgroup")))
  } else {
    expected_vars_all <- sort(c(expected_vars, c("year", "state", geo)))
  }
  
  stopifnot(all(expected_vars_all == sort(colnames(data))))
  
}


#' Checks correctness of subgroup values for metric
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param expected_subgroups A character vector of expected subgroup values.
#' 
#' @returns NULL (throws error if subgroup values are incorrect)
#' 
check_subgroup_values <- function(data, expected_subgroups) {
  
  if (!"subgroup" %in% names(data)) {
    stop("No `subgroup` column found in data.")
  }
  
  created_subgroups <- sort(unique(dplyr::pull(data, subgroup)))
  
  stopifnot(all(created_subgroups == sort(expected_subgroups)))
  
}


#' Checks if required years are present 
#' 
#' @param data The data that is staged to be read out as the final file.
#' @param exp_years A data frame of subgroup types and their years, or a unique vector 
#' of years if no subgroup type is provided.
#' @param subgroups A TRUE or FALSE value indicating if the final data has subgroups.
#' 
#' @returns NULL (throws error if incorrect years are present for metric and/or subgroups,
#' throws warning if fewer than all expected metric years are present)
#'  
check_expected_years <- function(data, exp_years, subgroups) {

  if (isTRUE(subgroups)) {

    for (i in 1:nrow(exp_years)) {
      subgrp_type <- exp_years$subgroup_type[[i]]
      years <- exp_years$subgroup_years[[i]]

      data_years <- unique(dplyr::pull(data %>% filter(subgroup_type == subgrp_type), year))

      missing_years <- setdiff(years, data_years)

      if (length(missing_years) > 0) {
        warning(paste0("Subgroup type '", subgrp_type, "' is missing expected years: ",
                       paste(missing_years, collapse = ", "), "."))
      }

      stopifnot(all(data_years %in% years))
    }

  } else {

    data_years <- unique(dplyr::pull(data, year))

    missing_years <- setdiff(exp_years, data_years)

    if (length(missing_years) > 0) {
      warning(paste0("Metric is missing expected years: ",
                     paste(missing_years, collapse = ", "), "."))
    }

    stopifnot(all(data_years %in% exp_years))

  }
}


#' Parses a range string from the tech spec into numeric bounds
#'
#' Handles formats: "0-1", "0-50000", "-3 to 3", and empty/NA (returns NULL).
#'
#' @param range_str A character string describing the expected value range.
#' @returns A numeric vector c(min, max), or NULL if the range is empty/NA.
#'
parse_range <- function(range_str) {
  if (is.na(range_str) || trimws(range_str) == "") return(NULL)

  range_str <- trimws(range_str)

  if (grepl(" to ", range_str)) {
    parts <- strsplit(range_str, " to ")[[1]]
  } else {
    parts <- strsplit(range_str, "-")[[1]]
    # Handle leading negative sign: "-3-3" splits to c("", "3", "3")
    if (parts[1] == "" && length(parts) == 3) {
      parts <- c(paste0("-", parts[2]), parts[3])
    }
  }

  bounds <- as.numeric(trimws(parts))

  if (length(bounds) != 2 || any(is.na(bounds))) {
    warning(paste0("Could not parse range: '", range_str, "'"))
    return(NULL)
  }

  bounds
}


#' Checks that non-NA metric values fall within the expected range
#'
#' @param data The final data frame.
#' @param metric_var The metric variable name (column to check).
#' @param range_bounds A numeric vector c(min, max) from parse_range().
#'
#' @returns NULL (throws error if values are out of range)
#'
check_value_ranges <- function(data, metric_var, range_bounds) {
  if (is.null(range_bounds)) return(invisible(NULL))

  range_min <- range_bounds[1]
  range_max <- range_bounds[2]

  metric_vals <- data[[metric_var]]
  metric_vals <- metric_vals[!is.na(metric_vals)]

  if (length(metric_vals) == 0) return(invisible(NULL))

  out_of_range <- metric_vals < range_min | metric_vals > range_max

  if (any(out_of_range)) {
    n_bad <- sum(out_of_range)
    bad_range <- range(metric_vals[out_of_range])
    stop(paste0(
      n_bad, " values in '", metric_var, "' are outside expected range [",
      range_min, ", ", range_max, "]. ",
      "Observed range of violations: [", bad_range[1], ", ", bad_range[2], "]."
    ))
  }
}


#' Checks for duplicate rows based on key columns
#'
#' Key columns are (year, state, county/place) for non-subgroup data,
#' or (year, state, county/place, subgroup_type, subgroup) for subgroup data.
#'
#' @param data The final data frame.
#' @param geo Either "county" or "place".
#' @param subgroups Logical indicating if the data has subgroups.
#'
#' @returns NULL (throws error if duplicates are found)
#'
check_duplicates <- function(data, geo, subgroups) {
  if (isTRUE(subgroups)) {
    key_cols <- c("year", "state", geo, "subgroup_type", "subgroup")
  } else {
    key_cols <- c("year", "state", geo)
  }

  dupes <- data %>%
    dplyr::group_by(across(all_of(key_cols))) %>%
    dplyr::filter(n() > 1) %>%
    dplyr::ungroup()

  if (nrow(dupes) > 0) {
    n_dupe_keys <- dupes %>%
      dplyr::distinct(across(all_of(key_cols))) %>%
      nrow()
    stop(paste0(
      nrow(dupes), " duplicate rows found across ", n_dupe_keys,
      " key combinations. Key columns: ",
      paste(key_cols, collapse = ", "), "."
    ))
  }
}


#' Checks that quality flag columns only contain valid values
#'
#' Valid values are 1 (strong), 2 (marginal), 3 (weak), or NA.
#'
#' @param data The final data frame.
#'
#' @returns NULL (throws error if invalid quality flag values are found)
#'
check_quality_flag_values <- function(data) {
  quality_cols <- names(data)[grepl("_quality$", names(data))]

  if (length(quality_cols) == 0) return(invisible(NULL))

  allowed_values <- c(1, 2, 3)

  for (col in quality_cols) {
    vals <- data[[col]]
    vals <- vals[!is.na(vals)]

    invalid <- vals[!vals %in% allowed_values]

    if (length(invalid) > 0) {
      stop(paste0(
        "Column '", col, "' contains invalid quality flag values: ",
        paste(unique(invalid), collapse = ", "), ". ",
        "Expected only 1, 2, 3, or NA."
      ))
    }
  }
}


#' Checks that the number of unique geographies per year is within expected range
#'
#' Expected counts based on crosswalk analysis (county-populations.csv,
#' place-populations.csv):
#' - County pre-2022: 3,141 to 3,143 (varies due to Valdez-Cordova AK split)
#' - County 2022+: exactly 3,144 (CT planning regions added)
#' - Place pre-2018: 485 to 486
#' - Place 2018+: exactly 486
#'
#' @param data The final data frame.
#' @param geo Either "county" or "place".
#'
#' @returns NULL (throws error if geography count is outside expected range)
#'
check_row_counts <- function(data, geo) {
  if (!geo %in% c("county", "place")) return(invisible(NULL))

  geo_counts <- data %>%
    dplyr::group_by(year) %>%
    dplyr::summarise(
      n_geos = dplyr::n_distinct(state, .data[[geo]]),
      .groups = "drop"
    )

  # Apply year-specific expected ranges
  if (geo == "county") {
    bad_years <- geo_counts %>%
      dplyr::mutate(
        min_expected = ifelse(year >= 2022, 3144, 3141),
        max_expected = ifelse(year >= 2022, 3144, 3143)
      )
  } else {
    bad_years <- geo_counts %>%
      dplyr::mutate(
        min_expected = ifelse(year >= 2018, 486, 485),
        max_expected = ifelse(year >= 2018, 486, 486)
      )
  }

  bad_years <- bad_years %>%
    dplyr::filter(n_geos < min_expected | n_geos > max_expected)

  if (nrow(bad_years) > 0) {
    details <- paste0(
      "year ", bad_years$year, ": ", bad_years$n_geos,
      " geographies (expected ", bad_years$min_expected, "-",
      bad_years$max_expected, ")",
      collapse = "; "
    )
    stop(paste0("Unexpected number of unique geographies. ", details))
  }
}


