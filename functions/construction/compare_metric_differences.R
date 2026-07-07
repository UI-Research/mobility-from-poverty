#' Compare Metric Differences Between Data Versions
#'
#' Expands basic data comparison by quantifying row-level differences for a
#' specific metric and surfacing the largest absolute changes.
#'
#' @param data_list A named list containing `local` and `catalog` data frames.
#' @param header Character string shown as the section title.
#' @param metric Character string naming the metric to compare.
#' @param top_n Integer. Number of largest differences to display.
#'
#' @return NULL. Prints markdown-ready summaries and tables.
#'
#' @export
compare_metric_differences <- function(data_list,
                                       header,
                                       metric = "share_employed",
                                       top_n = 25) {

  if (knitr::is_html_output()) {
    cat(
      "<style>\n",
      ".cmp-diff-table { border-collapse: collapse; width: 100%; white-space: nowrap; font-size: 0.9rem; }\n",
      ".cmp-diff-table th, .cmp-diff-table td { border: 1px solid #d9d9d9; padding: 6px 8px; }\n",
      ".cmp-diff-table th { background: #f6f6f6; }\n",
      "</style>\n",
      sep = ""
    )
  }

  render_table <- function(df,
                           searchable = FALSE,
                           default_page_size = 12,
                           compact = TRUE,
                           digits = 4) {
    if (knitr::is_html_output()) {
      numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
      if (length(numeric_cols) > 0) {
        df[numeric_cols] <- lapply(df[numeric_cols], function(x) round(x, digits))
      }

      # Wrap wide tables in a horizontal scroll container for cleaner rendering.
      cat("<div style='overflow-x:auto; max-width:100%; border:1px solid #e5e5e5; border-radius:6px; padding:4px;'>\n")
      print(
        knitr::kable(
          df,
          format = "html",
          row.names = FALSE,
          table.attr = "class='cmp-diff-table'"
        )
      )
      cat("</div>\n")
    } else {
      print(knitr::kable(df, digits = digits, row.names = FALSE))
    }
    cat("\n\n")
  }

  cat("### Largest ", metric, " Differences: ", header, "\n\n", sep = "")

  local <- data_list[["local"]]
  catalog <- data_list[["catalog"]]

  if (!metric %in% names(local) || !metric %in% names(catalog)) {
    cat("Metric `", metric, "` not found in both versions.\n\n", sep = "")
    return(NULL)
  }

  shared_cols <- intersect(names(local), names(catalog))

  id_priority <- c(
    "year", "state", "state_name", "county", "county_name",
    "place", "place_name", "tract", "puma", "subgroup_type", "subgroup"
  )

  key_cols <- intersect(id_priority, shared_cols)

  if (length(key_cols) == 0) {
    key_cols <- setdiff(shared_cols, c(metric, paste0(metric, c("_lb", "_ub", "_quality"))))
  }

  if (length(key_cols) == 0) {
    cat("Unable to determine join keys for comparison.\n\n")
    return(NULL)
  }

  local_sel <- dplyr::select(local, dplyr::all_of(c(key_cols, metric)))
  catalog_sel <- dplyr::select(catalog, dplyr::all_of(c(key_cols, metric)))

  local_metric_sym <- rlang::sym(paste0(metric, "_local"))
  catalog_metric_sym <- rlang::sym(paste0(metric, "_catalog"))

  diff_df <- dplyr::inner_join(
    local_sel,
    catalog_sel,
    by = key_cols,
    suffix = c("_local", "_catalog")
  )

  diff_df$value_local <- suppressWarnings(as.numeric(diff_df[[rlang::as_name(local_metric_sym)]]))
  diff_df$value_catalog <- suppressWarnings(as.numeric(diff_df[[rlang::as_name(catalog_metric_sym)]]))
  diff_df$diff <- diff_df$value_local - diff_df$value_catalog
  diff_df$abs_diff <- abs(diff_df$diff)
  diff_df$pct_diff <- ifelse(
    is.na(diff_df$value_catalog) | diff_df$value_catalog == 0,
    NA_real_,
    100 * diff_df$diff / diff_df$value_catalog
  )

  compared <- diff_df[!is.na(diff_df$value_local) & !is.na(diff_df$value_catalog), , drop = FALSE]

  if (nrow(compared) == 0) {
    cat("No comparable non-missing rows found for this metric.\n\n")
    return(NULL)
  }

  changed <- compared[compared$abs_diff > 0, , drop = FALSE]

  cat("**Summary:**\n\n")
  summary_tbl <- dplyr::tibble(
    matched_rows = nrow(compared),
    changed_rows = nrow(changed),
    share_changed = scales::percent(nrow(changed) / nrow(compared), accuracy = 0.1),
    max_abs_diff = max(compared$abs_diff, na.rm = TRUE),
    median_abs_diff = stats::median(compared$abs_diff, na.rm = TRUE)
  )
  render_table(summary_tbl, searchable = FALSE, default_page_size = 5, compact = TRUE, digits = 6)

  if ("year" %in% names(compared)) {
    cat("**Largest absolute differences by year:**\n\n")
    by_year <- compared |>
      split(compared$year) |>
      lapply(function(df) {
        data.frame(
          year = df$year[[1]],
          rows_compared = nrow(df),
          rows_changed = sum(df$abs_diff > 0),
          max_abs_diff = max(df$abs_diff, na.rm = TRUE),
          median_abs_diff = stats::median(df$abs_diff, na.rm = TRUE)
        )
      }) |>
      dplyr::bind_rows()
    by_year <- by_year[order(-by_year$max_abs_diff, -by_year$rows_changed), , drop = FALSE]
    render_table(by_year, searchable = FALSE, default_page_size = 15, compact = TRUE, digits = 6)
  }

  cat("**Top places with largest absolute differences:**\n\n")

  display_cols <- c(
    intersect(c("year", "state_name", "state", "place_name", "place", "subgroup_type", "subgroup"), names(compared)),
    "value_catalog", "value_local", "diff", "abs_diff", "pct_diff"
  )

  compared_ordered <- compared[order(-compared$abs_diff), , drop = FALSE]
  n_rows <- min(top_n, nrow(compared_ordered))
  top_tbl <- compared_ordered[seq_len(n_rows), display_cols, drop = FALSE]

  pretty_names <- c(
    year = "Year",
    state_name = "State",
    state = "State FIPS",
    place_name = "Place",
    place = "Place FIPS",
    subgroup_type = "Subgroup Type",
    subgroup = "Subgroup",
    value_catalog = "Catalog",
    value_local = "Local",
    diff = "Difference",
    abs_diff = "Absolute Difference",
    pct_diff = "% Difference"
  )
  names(top_tbl) <- dplyr::coalesce(pretty_names[names(top_tbl)], names(top_tbl))

  render_table(top_tbl, searchable = TRUE, default_page_size = 25, compact = TRUE, digits = 6)
}
