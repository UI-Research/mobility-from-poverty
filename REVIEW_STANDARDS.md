# Mobility Metrics: Data Review Standards

Standards for reviewing PRs that update metric data. The review checklist below is what to check on every PR. The reference sections after it explain each standard in detail.

## PR Review Checklist

When reviewing a PR that updates a metric, check these in order:

### 1. Does the QMD call `evaluate_final_data()` before writing the CSV?

Every metric QMD should source the test function and call it on the final data frame right before `write_csv()`. If the call is missing, the automated checks (column order, FIPS formatting, value ranges, row counts, duplicates, quality flags) won't run.

```r
source(here::here("functions", "testing", "evaluate_final_data_checks.R"))
# ... build final_data ...
evaluate_final_data(metric_var = "share_employed", data = final_data, geo = "county", ...)
write_csv(final_data, here("path/to/final.csv"))
```

If the function call is commented out or missing, flag it.

### 2. Are crosswalk joins in the right direction?

This is the most common source of missing geographies. The crosswalk must be the left table:

```r
# Correct: crosswalk on the left
crosswalk %>% left_join(metric_data, by = c("state", "county"))

# Wrong: drops geographies the metric doesn't cover
metric_data %>% left_join(crosswalk, by = c("state", "county"))
```

A reversed join turns 3,144 expected rows into, say, 2,991. Look for `left_join` calls where the metric data is on the left side.

Good metrics verify joins explicitly. Look for (and encourage) patterns like `anti_join()` to check for unmatched rows, or `stopifnot(nrow(result) == expected)` after a join.

### 3. Do the row counts look right?

If the PR includes final data CSVs, check the row count per year. The expected counts are:

- **County**: exactly 3,144 for 2022+, 3,141-3,143 for earlier years
- **Place**: exactly 486 for 2018+, 485-486 for earlier years

If a metric is significantly below these counts, the crosswalk join is likely wrong (see #2).

### 4. Are FIPS codes stored as character, not numeric?

Look for `read_csv()` calls that don't specify column types. If `state`, `county`, or `place` get read as numeric, leading zeros are dropped (e.g., Alabama becomes `1` instead of `"01"`). The fix is usually `col_types` in `read_csv()` or `mutate(state = str_pad(state, 2, pad = "0"))`.

### 5. Does the code use `here::here()` for all file paths?

No `setwd()`, no absolute paths, no bare relative paths like `"data/file.csv"`. All paths should go through `here::here()`.

### 6. If the PR adds a new year of data:

- Is the new year added to `metrics_technical_spec_2026.csv`?
- Are evaluation forms updated (if using the legacy system)?
- **Check for hardcoded year lists.** Several QMDs have Connecticut exclusion filters like `filter(!(state == "09" & year %in% c(2022, 2023, 2024)))`. If you're adding 2025 data, those lists need updating or the new year's CT rows will be wrong.
- Does the code handle year-specific edge cases? In particular:
  - **2020**: most ACS-based metrics skip 2020 entirely (low COVID response rates)
  - **2022+**: Connecticut replaced 8 counties with 9 planning regions. If the metric uses tract-level data, it needs the right crosswalk for 2022+.
  - **Pre-2020**: Valdez-Cordova AK (`02261`) hadn't split yet. Some metrics harmonize this forward, others don't.

### 7. Are `share_*` values between 0 and 1?

Shares are proportions, not percentages. A value of `52.3` instead of `0.523` means the metric wasn't divided by 100. Similarly, `_quality` columns should only contain 1, 2, 3, or NA.

### 8. For subgroup files: is the structure right?

Subgroup data should be long format with `subgroup_type` and `subgroup` columns after `county`/`place`. Check that "All" is included as a subgroup value, and that race-ethnicity values match the standard labels (see Subgroup Conventions below).

### 9. Are suppressed counties added back as NA?

Most ACS-based metrics suppress counties with fewer than 30 effective observations. The standard pattern is: filter out small-sample counties, calculate the metric, then join the suppressed counties back in so they appear as NA rows. If the "join back" step is missing, the final data will have fewer rows than expected (see #3). Look for the pattern:

```r
# 1. Identify counties to suppress
small_counties <- data %>% filter(effective_sample < 30)

# 2. Calculate metric on remaining counties
results <- data %>% filter(effective_sample >= 30) %>% ...

# 3. Join suppressed counties back as NA (this step is sometimes missing)
results <- bind_rows(results, small_counties %>% mutate(metric = NA))
```

### 10. Watch for `filter()` silently dropping NA rows

In R, `filter(x != "foo")` drops rows where `x` is NA. If NAs should be kept, use `filter(x != "foo" | is.na(x))`. This comes up when filtering out specific states, years, or subgroups. If a metric's row count is slightly off, a filter that accidentally dropped NAs is a common cause.

---

## Reference

The sections below document each standard in detail.

## Data Structure

### Column Order
Every final dataset must start with columns in this exact order:
1. `year` (4-digit numeric)
2. `state` (2-character FIPS, zero-padded)
3. `county` or `place` (3-character or 5-character FIPS, zero-padded)
4. `subgroup_type` (only in subgroup files)
5. `subgroup` (only in subgroup files)

Metric columns, quality flags, and confidence intervals follow after these.

### FIPS Code Formatting
- `state`: 2-character string with leading zero (e.g., `"01"` for Alabama)
- `county`: 3-character string with leading zero (e.g., `"001"`)
- `place`: 5-character string with leading zeros (e.g., `"03076"`)
- FIPS codes must be character type, not numeric (numeric drops leading zeros)

### Variable Naming Conventions
| Prefix | Meaning | Typical Range |
|---|---|---|
| `share_*` | Proportion/percentage | 0 to 1 |
| `pctl_*` | Percentile value | Varies by metric |
| `rate_*` | Rate per population | Non-negative |
| `count_*` | Raw count | Non-negative |
| `index_*` | Index value | Varies by metric |
| `ratio_*` | Ratio | Varies by metric |
| `*_quality` | Data quality flag | 1, 2, 3, or NA |
| `*_lb` | Confidence interval lower bound | Same range as metric |
| `*_ub` | Confidence interval upper bound | Same range as metric |

### Quality Flags
Quality flag columns (`*_quality`) must only contain:
- `1` = strong/high quality
- `2` = marginal/limited issues
- `3` = weak/serious issues
- `NA` = not calculable

When a metric value is NA, the corresponding `_quality`, `_lb`, and `_ub` columns must also be NA (and vice versa).

## Expected Row Counts

### County Files
| Years | Expected Count | Reason |
|---|---|---|
| Pre-2020 | 3,141-3,143 | Varies by metric geography harmonization |
| 2020-2021 | 3,142-3,143 | Valdez-Cordova AK split adds 1 county |
| 2022+ | Exactly 3,144 | CT planning regions replace 8 counties with 9 |

### Place/City Files
| Years | Expected Count | Reason |
|---|---|---|
| Pre-2018 | 485-486 | |
| 2018+ | Exactly 486 | |

If a metric has fewer rows than expected (e.g., 2,991 counties instead of 3,143), it likely means the crosswalk join dropped geographies. This is the most common data bug.

## Subgroup Conventions

### Structure
Subgroup data is in long format with two additional columns:
- `subgroup_type`: category of disaggregation (e.g., `"race-ethnicity"`, `"income"`, `"all"`)
- `subgroup`: specific group within the type

### Required Subgroup Values
The `"all"` subgroup type with subgroup value `"All"` must always be present.

Standard race-ethnicity values (when applicable):
- `"Black, Non-Hispanic"`
- `"Hispanic"`
- `"Other Races and Ethnicities"`
- `"White, Non-Hispanic"`

### Sorting
Subgroup files must be sorted by: year, state, county/place, subgroup_type, subgroup (alphabetically).

## Crosswalk Join Conventions

The crosswalk must always be the left (X) table in joins:
```r
# Correct
crosswalk %>% left_join(metric_data, by = c("state", "county"))

# Wrong - drops geographies not in metric_data
metric_data %>% left_join(crosswalk, by = c("state", "county"))
```

This ensures every geography in the crosswalk appears in the output, even if the metric has no data for it (those rows get NA).

## Value Ranges

Metric-specific expected ranges are defined in `data/technical_specification/metrics_technical_spec_2026.csv` in the `RANGE` column. The `evaluate_final_data()` function in `functions/testing/evaluate_final_data_checks.R` enforces these automatically.

Common ranges:
- `share_*` variables: 0 to 1 (proportions, not percentages)
- `rate_learning`: -3 to 3 (SEDA learning rates are standardized)
- `index_air_hazard`: 0 to 100

If the RANGE column is empty for a metric, the range check is skipped.

## Common Pitfalls

### Connecticut Planning Regions (2022+)
Starting in 2022, Connecticut replaced its 8 counties with 9 planning regions. This adds 1 net geography (3,143 -> 3,144 counties). Metrics that use tract-level data need a tract-to-planning-region crosswalk for 2022+ data. Check:
- Does the metric handle both pre-2022 (county) and 2022+ (planning region) geographies?
- Is the crosswalk file in `geographic-crosswalks/data/` correct for the data year?

### Shannon County FIPS Change
Shannon County, SD changed its name to Oglala Lakota County and its FIPS from `46113` to `46102`. Metrics should handle this so both old and new FIPS map to the same geography.

### 2020 ACS Exclusion
The 2020 ACS 1-year estimates are excluded from most metrics because of low response rates during COVID. If a metric uses ACS data, verify that year 2020 is handled correctly (typically skipped entirely).

### Valdez-Cordova AK Split
In the 2020 Census, Valdez-Cordova Census Area (`02261`) was split into Chugach Census Area (`02063`) and Copper River Census Area (`02066`). This changes the county count from 3,142 to 3,143 starting in 2020.

## Testing

### Automated Checks
The testing function in `functions/testing/evaluate_final_data_checks.R` runs these checks:
1. Column order
2. Column names match tech spec
3. FIPS code formatting
4. Subgroup values match tech spec
5. Expected years present
6. NA alignment across metric, quality, and CI columns
7. Value ranges (from tech spec RANGE column)
8. No duplicate rows
9. Quality flag values (only 1, 2, 3, or NA)
10. Row counts per year within expected range

### Geography Validation
The function in `functions/testing/check_crosswalk_geoids_present.R` validates that all GEOIDs from a crosswalk file are present in a metric file. This is a separate, more granular check than the row count check.

### How to Run
```r
source(here::here("functions", "testing", "evaluate_final_data_checks.R"))

# Non-subgroup data
evaluate_final_data(
  metric_var = "share_employed",
  data = final_data,
  geo = "county",
  all_expected_years = TRUE,
  subgroups = FALSE,
  confidence_intervals = TRUE
)

# Subgroup data
evaluate_final_data(
  metric_var = "share_employed",
  data = final_data_subgroups,
  geo = "county",
  all_expected_years = TRUE,
  subgroups = TRUE,
  subgrp_type = c("all", "race-ethnicity", "disability", "gender"),
  confidence_intervals = TRUE
)
```

## File Paths
- Always use `here::here()` for paths. Never `setwd()` or absolute paths.
- Final data CSVs go in each metric's `data/final/` subdirectory.
- Intermediate data in `data/` subdirectories is gitignored.

## Technical Specification
The source of truth for metric expectations is `data/technical_specification/metrics_technical_spec_2026.csv`. It defines:
- Expected variable names and quality columns
- Expected years per geography and subgroup type
- Whether confidence intervals are present
- Expected value ranges
- Final data file paths
