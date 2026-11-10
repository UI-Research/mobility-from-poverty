#' Combine Predictor Notes
#'
#' Concatenates every `*/predictor-notes.md` in folder order into
#' `documentation/all-predictor-notes.md`. Each predictor gets a `#` heading,
#' its YAML front matter goes in a `yaml` code block, and its section headings
#' move down one level so the combined file has one outline.
#'
#' @param output Path of the combined file.
#'
#' @return The output path, invisibly.
#'
#' @examples
#' \dontrun{
#' source(here::here("functions", "documentation", "combine_predictor_notes.R"))
#' combine_predictor_notes()
#' }
combine_predictor_notes <- function(
    output = here::here("documentation", "all-predictor-notes.md")) {

  files <- sort(Sys.glob(here::here("[0-9][0-9]_*", "predictor-notes.md")))
  stopifnot(length(files) > 0)

  sections <- purrr::map_chr(files, function(file) {
    lines <- readLines(file, warn = FALSE)
    yaml_end <- which(lines == "---")[2]
    yaml <- lines[2:(yaml_end - 1)]
    body <- lines[(yaml_end + 1):length(lines)]
    body <- sub("^(#+ )", "#\\1", body)

    paste(
      c(
        paste("#", basename(dirname(file))),
        "",
        "```yaml", yaml, "```",
        body
      ),
      collapse = "\n"
    )
  })

  header <- c(
    "# Predictor notes",
    "",
    "This file is built by `functions/documentation/combine_predictor_notes.R` from each predictor folder's `predictor-notes.md`. Edit those files, not this one.",
    ""
  )

  dir.create(dirname(output), showWarnings = FALSE)
  writeLines(c(header, paste(sections, collapse = "\n\n")), output)

  invisible(output)
}
