summarize_metric <- function(.data, var, quality_var, decimals = 2) {
  
  cat("#### **Variable:** ")
  
  .data %>%
    dplyr::select({{ var }}) %>%
    names() %>%
    paste0("`", ., "`") %>%
    cat()
  
  cat("\n")
  
  cat("**Summary**")
  
  cat("\n")
  
  .data %>%
    summarize(
      `Min.` = min({{ var }}, na.rm = TRUE),
      Median = median({{ var }}, na.rm = TRUE),
      Mean = mean({{ var }}, na.rm = TRUE),
      `Max.` = max({{ var }}, na.rm = TRUE),
      `NA's` = sum(is.na({{ var }}))
    ) %>%
    gt::gt() %>%
    gt::fmt_number(columns = 1:4, decimals = decimals) %>%
    gt::opt_css(
      css = "
        .gt_table {
          margin-left: 0 !important;
        }
      "
    ) %>%
    gt::as_raw_html() %>%
    cat()
  
  cat("\n")
  
  cat("**Data Quality**")
  
  cat("\n")
  
  dplyr::count(.data, {{ quality_var }}) %>%
    dplyr::mutate(
      quality_label = case_when(
        {{ quality_var }} == 1 ~ "Strong",
        {{ quality_var }} == 2 ~ "Marginal",
        {{ quality_var }} == 3 ~ "Weak",
        TRUE ~ NA_character_
      )       
    ) %>%
    dplyr::select({{ quality_var }}, quality_label, n) %>%
    gt::gt() %>%
    gt::opt_css(
      css = "
        .gt_table {
          margin-left: 0 !important;
        }
      "
    ) %>%    
    gt::as_raw_html() %>%
    cat()

  cat("\n")
  cat("\n")
  cat("\n")
  
}