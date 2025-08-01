#' Validate that all geographies in a crosswalk file are present in a metric file
#'
#' This function checks whether all geographic identifiers (GEOIDs) constructed
#' from a crosswalk file are present in a corresponding metric file.
#' It supports flexible naming for the state column (`"state"` or `"statefip"`),
#' and infers whether the geography is county- or place-based.
#' By default, it filters out Puerto Rico (`state == "72"`).
#'
#' Optionally, you can restrict the check to a subset of years in the metric file
#' (assuming the metric has a `year` column).
#'
#' If missing GEOIDs are found, the function prints a warning and lists them. It
#' also invisibly returns a tibble with the result.
#'
#' @param crosswalk_path Path to the CSV crosswalk file.
#' @param metric_path Path to the CSV metric file.
#' @param crosswalk_col_names Optional character vector of column names in the crosswalk to build the GEOID. Defaults to inferred `c("state", "county")` or `c("state", "place")`.
#' @param metric_col_names Optional character vector of column names in the metric file to build the GEOID. Same logic as `crosswalk_col_names`.
#' @param years Optional numeric vector of years to restrict the check. The metric file must contain a `year` column if this is specified.
#' @param crosswalk_years Optional numeric vector of years that the crosswalk is valid for. If specified, only metric years that intersect with this set will be used for validation.
#' 
#' @return Invisibly returns a tibble with:
#' \itemize{
#'   \item \code{crosswalk_file}: file name of the crosswalk
#'   \item \code{metric_file}: file name of the metric
#'   \item \code{all_present}: logical, whether all GEOIDs matched
#'   \item \code{n_missing}: count of missing GEOIDs
#'   \item \code{missing_geoids}: list-column of missing GEOIDs (character vector)
#' }
#'
#' @examples
#' result <- validate_geographies(
#'  crosswalk_path = here::here(
#'    "geographic-crosswalks",
#'    "data",
#'    "crosswalk_puma_to_county.csv"
#'  ),
#'  metric_path = here::here("01_financial-well-being", "final", "households_house_value_race_ethnicity_all_county.csv")
#' )
#' If there are missing geoids, extract the full list as a character vector
#' result$missing_geoids[[1]]

library(tidyverse)
if (!requireNamespace("stringdist", quietly = TRUE)) {
  install.packages("stringdist")
}
validate_geographies <- function(crosswalk_path,
                                 metric_path,
                                 crosswalk_col_names = NULL,
                                 metric_col_names = NULL,
                                 years = NULL,
                                 crosswalk_years = NULL) {
  crosswalk_file <- fs::path_file(crosswalk_path)
  metric_file <- fs::path_file(metric_path)

  crosswalk <- readr::read_csv(crosswalk_path, show_col_types = FALSE)
  metric <- readr::read_csv(metric_path, show_col_types = FALSE)

  crosswalk <- crosswalk %>%
    rename(state = any_of(c("state", "statefip"))) %>%
    filter(state != "72")

  metric <- metric %>%
    rename(state = any_of(c("state", "statefip")))


  # Optional: filter metric by years
  if (!is.null(years)) {
    if (!"year" %in% names(metric)) {
      stop("You specified 'years', but the metric file has no 'year' column.")
    }

    available_years <- unique(metric$year)
    missing_years <- setdiff(years, available_years)

    if (length(missing_years) == length(years)) {
      stop(
        glue::glue("None of the specified years ({paste(years, collapse = ', ')}) exist in the metric file.\nAvailable years: {paste(available_years, collapse = ', ')}")
      )
    }

    if (length(missing_years) > 0) {
      cli::cli_alert_warning(
        "Some specified years are not in the metric file: {paste(missing_years, collapse = ', ')}"
      )
    }

    effective_years <- years

    if (!is.null(crosswalk_years)) {
      out_of_scope_years <- setdiff(years, crosswalk_years)
      effective_years <- intersect(years, crosswalk_years)

      if (length(out_of_scope_years) > 0) {
        cli::cli_alert_warning(
          "The following years specified for the metric are not covered by the crosswalk ({paste(crosswalk_years, collapse = ', ')}): {paste(out_of_scope_years, collapse = ', ')}"
        )
      }
    }

    metric <- metric %>% filter(year %in% effective_years)
  }


  crosswalk_geo_cols <- crosswalk_col_names %||% infer_geo_cols(crosswalk)
  metric_geo_cols    <- metric_col_names    %||% infer_geo_cols(metric)

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

# Infer geography columns
  infer_geo_cols <- function(df) {
    if ("county" %in% names(df)) return(c("state", "county"))
    if ("place" %in% names(df)) return(c("state", "place"))
    stop("Could not infer geography columns. Expecting one of: county or place.")
  }


suggest_closest <- function(x, choices) {
  distances <- stringdist::stringdist(x, choices)
  closest <- choices[which.min(distances)]
  return(closest)
}

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
    stop(msg)
  }
}

result <- validate_geographies(
  crosswalk_path = here::here(
    "geographic-crosswalks",
    "data",
    "crosswalk_puma_to_county.csv"
  ),
  metric_path = here::here("01_financial-well-being", "final", "households_house_value_race_ethnicity_all_county.csv"),
 metric_col_names = "stte"
 )


# result <- validate_geographies(
#  crosswalk_path = here::here(
#    "geographic-crosswalks",
#    "data",
#    "crosswalk_puma_to_county.csv"
#  ),
#  metric_path = here::here("01_financial-well-being", "final", "households_house_value_race_ethnicity_all_county.csv")
# )
#
# result$missing_geoids[[1]]
validate_geographies(
  here::here("geographic-crosswalks","data","crosswalk_puma_to_county.csv"),
  here::here("08_education", "data", "final","digital_access_county_all_longitudinal.csv"),
  years = c("2018"),
  crosswalk_years = c("2020")
)
