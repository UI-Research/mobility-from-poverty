library(tidyverse)
if (!requireNamespace("stringdist", quietly = TRUE)) {
  install.packages("stringdist")
}

#' Validate that all geographies in a crosswalk file are present in a metric file
#'
#' This function checks whether all geographic identifiers (GEOIDs) constructed
#' from a crosswalk file are present in a corresponding metric file.
#'
#' @param crosswalk_path Path to the CSV crosswalk file.
#' @param metric_path Path to the CSV metric file.
#' @param crosswalk_geo_cols Optional character vector of column names in the crosswalk to build the GEOID. This should include a state column (e.g., `"state"`, `"statefip"`, or `"statefp"`) and one geography detail column (e.g., `"county"` or `"place"`). In most cases, this does not need to be specified: the function will attempt to infer these columns automatically. However, if your crosswalk file uses non-standard column names (e.g., `"STATEFP10"` or `"COUNTYCD"`), you should pass the appropriate column names explicitly.
#' @param metric_geo_cols Optional character vector of column names in the metric file to build the GEOID. Same requirements and inference behavior as `crosswalk_geo_cols`. You only need to provide this if your metric file uses non-standard column names for state or geography.
#' @param years Optional numeric vector of years to restrict the check.
#' @param crosswalk_years Optional numeric vector of valid years for the crosswalk.
#' @return Invisibly returns a tibble with summary validation results.
validate_geographies <- function(crosswalk_path,
                                 metric_path,
                                 crosswalk_geo_cols = NULL,
                                 metric_geo_cols = NULL,
                                 years = NULL) {
  crosswalk_file <- fs::path_file(crosswalk_path)
  metric_file <- fs::path_file(metric_path)

  crosswalk <- readr::read_csv(crosswalk_path, show_col_types = FALSE)
  metric <- readr::read_csv(metric_path, show_col_types = FALSE)

  crosswalk <- crosswalk %>%
    rename(state = any_of(c("state", "statefip", "statefp", "STATEFP"))) %>%
    filter(state != "72")

  metric <- metric %>%
    rename(state = any_of(c("state", "statefip", "statefp", "STATEFP")))

  tmp <- filter_by_crosswalk_year_logic(
    crosswalk, metric, years
  )

  crosswalk <- tmp[[1]]
  metric <- tmp[[2]]

  crosswalk_geo_cols <- crosswalk_geo_cols %||% infer_geo_cols(crosswalk)
  metric_geo_cols    <- metric_geo_cols    %||% infer_geo_cols(metric)

  if (!is.null(crosswalk_geo_cols) && length(crosswalk_geo_cols) < 2) {
    stop(glue::glue(
      "crosswalk_geo_cols must include at least two column names (e.g., one for state and one for county/place). You provided: {paste(crosswalk_geo_cols, collapse = ', ')}"
    ))
  }

  if (!is.null(metric_geo_cols) && length(metric_geo_cols) < 2) {
    stop(glue::glue(
      "metric_geo_cols must include at least two column names (e.g., one for state and one for county/place). You provided: {paste(metric_geo_cols, collapse = ', ')}"
    ))
  }

  validate_columns(crosswalk_geo_cols, names(crosswalk), "crosswalk")
  validate_columns(metric_geo_cols, names(metric), "metric")

  # Build GEOIDs
  crosswalk_geoids <- crosswalk %>%
    mutate(geoid = str_c(!!!syms(crosswalk_geo_cols))) %>%
    distinct(geoid)

  metric_geoids <- metric %>%
    mutate(geoid = str_c(!!!syms(metric_geo_cols))) %>%
    distinct(geoid)

  # Compare GEOIDs
  missing_geoids <- setdiff(crosswalk_geoids$geoid, metric_geoids$geoid)
  all_present <- length(missing_geoids) == 0

  # Output
  if (all_present) {
    cli::cli_alert_success(
      "All geoids in {.file {crosswalk_file}} are present in {.file {metric_file}}."
    )
  } else {
    cli::cli_alert_warning(
      "Found {length(missing_geoids)} missing geoids from {.file {crosswalk_file}} not present in {.file {metric_file}}."
    )
    cli::cli_text("Missing GEOIDs:")
    cli::cli_ul(missing_geoids)
    cli::cli_text("Check your crosswalk logic and determine if this is expected.")
  }

  tibble::tibble(
    crosswalk_file = crosswalk_file,
    metric_file = metric_file,
    all_present = all_present,
    n_missing = length(missing_geoids),
    missing_geoids = list(missing_geoids)
  ) %>% invisible()
}

#' Filter crosswalk and metric data by year or crosswalk period logic
#'
#' This helper function aligns the temporal scope of crosswalk and metric data.
#' It filters both datasets based on available year information or `crosswalk_period`
#' when applicable.
#'
#' @param crosswalk A crosswalk data frame.
#' @param metric A metric data frame.
#' @param years Optional numeric vector of years to restrict the analysis.
#'
#' @return A list of two data frames: the filtered crosswalk and metric datasets.
#' @keywords internal
filter_by_crosswalk_year_logic <- function(crosswalk, metric, years = NULL) {
  if (!is.null(years)) {
    if (!"year" %in% names(metric)) {
      cli::cli_abort(
        "You specified {.field years}, but the metric file has no {.field year} column."
      )
    }

    available_years <- unique(metric$year)
    missing_years <- setdiff(years, available_years)

    if (length(missing_years) == length(years)) {
      cli::cli_abort(
        "None of the specified years ({.val {paste(years, collapse = ', ')}}) exist in the metric file.\nAvailable years: {.val {paste(available_years, collapse = ', ')}}"
      )
    }

    if (length(missing_years) > 0) {
      cli::cli_alert_warning(
        "Some specified years are not in the metric file: {.val {paste(missing_years, collapse = ', ')}}"
      )
    }

    metric <- metric %>% filter(year %in% years)
  }

  if ("year" %in% names(crosswalk)) {
    if (!"year" %in% names(metric)) {
      cli::cli_abort(
        "The crosswalk has a {.field year} column, but the metric file does not."
      )
    }

    effective_years <- intersect(unique(metric$year), unique(crosswalk$year))
    if (length(effective_years) == 0) {
      cli::cli_abort(
        "No overlapping {.field year} values found between metric and crosswalk."
      )
    }

    metric <- metric %>% filter(year %in% effective_years)
    crosswalk <- crosswalk %>% filter(year %in% effective_years)

  } else if ("crosswalk_period" %in% names(crosswalk)) {
    if (!"year" %in% names(metric)) {
      cli::cli_abort(
        "Crosswalk uses {.field crosswalk_period}, but the metric file has no {.field year} column."
      )
    }

    metric <- metric %>%
      mutate(.cw_period = case_when(
        year <= 2021 ~ "pre-2022",
        year >= 2022 ~ "2022",
        TRUE ~ NA_character_
      ))

    unmatched_periods <- setdiff(unique(metric$.cw_period), unique(crosswalk$crosswalk_period))
    if (length(unmatched_periods) > 0) {
      cli::cli_alert_warning(
        "Some metric years map to periods not present in the crosswalk: {.val {paste(unmatched_periods, collapse = ', ')}}"
      )
    }

    metric <- metric %>% filter(.cw_period %in% unique(crosswalk$crosswalk_period))
    crosswalk <- crosswalk %>% filter(crosswalk_period %in% unique(metric$.cw_period))

    metric <- metric %>% select(-.cw_period)
  }

  return(list(crosswalk, metric))
}

#' Infer geography columns in a dataset
#'
#' Attempts to infer which columns correspond to state and geography
#' (e.g., county or place). Used when the user does not specify explicit columns.
#'
#' @param df A data frame from which to infer geography columns.
#' @return A character vector with inferred column names.
infer_geo_cols <- function(df) {
  if ("county" %in% names(df)) return(c("state", "county"))
  if ("place" %in% names(df)) return(c("state", "place"))
  stop("Could not infer geography columns. Expecting one of: county or place.")
}

#' Suggest the closest valid column name using fuzzy matching
#'
#' Uses string distance matching to suggest corrections for misspecified column names.
#'
#' @param x A character scalar; the column name to check.
#' @param choices Character vector of available column names.
#' @return The closest match among available columns.
suggest_closest <- function(x, choices) {
  distances <- stringdist::stringdist(x, choices)
  closest <- choices[which.min(distances)]
  return(closest)
}

#' Validate that specified columns exist in a data frame
#'
#' Checks whether the user-specified columns exist in the available columns.
#' If any are missing, suggests likely alternatives based on string distance.
#'
#' @param specified_cols Character vector of expected column names.
#' @param available_cols Character vector of actual column names.
#' @param context A string indicating the origin of the check (e.g., "metric", "crosswalk").
#'
#' @return Stops execution with an informative error message if any column is missing.
validate_columns <- function(specified_cols, available_cols, context) {
  missing_cols <- setdiff(specified_cols, available_cols)

  if (length(missing_cols) > 0) {
    suggestions <- purrr::map_chr(
      missing_cols,
      ~ {
        if (length(available_cols) == 0) {
          return("no columns available")
        }
        suggest_closest(.x, available_cols)
      }
    )

    msg <- glue::glue(
      "The following {context} columns do not exist:\n",
      "{paste(missing_cols, collapse = ', ')}\n\n",
      "Did you mean:\n",
      "{paste(glue::glue('{missing_cols} → {suggestions}'), collapse = '\n')}"
    )
    cli::cli_abort(msg)
  }
}


