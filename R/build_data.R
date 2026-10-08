# Build tidy long-format data for the Ocean Acidity indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Ocean Acidity",
  slug                    = "ocean-acidity",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ocean-acidity/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/acidity_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Ocean Carbon Dioxide Levels and Acidity, 1983-2022 ----

f1_path <- file.path(raw_dir, "ocean-acidity_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# Four station blocks side by side, each with its own decimal-year column and
# separated by blank spacer columns. Cariaco samples pH and pCO2 on different
# dates, so it carries one year column per measure.
f1_series <- data.frame(
  station  = c("Hawaii", "Hawaii", "Canary Islands", "Canary Islands",
               "Bermuda", "Bermuda", "Cariaco", "Cariaco"),
  measure  = rep(c("pH", "pCO2"), 4),
  year_col = c("Hawaii Year", "Hawaii Year",
               "Canary Islands Year", "Canary Islands Year",
               "Bermuda Year", "Bermuda Year",
               "Cariaco Year (pH)", "Cariaco Year (pCO2)"),
  value_col = c("Hawaii pH", "Hawaii pCO2",
                "Canary Islands pH", "Canary Islands pCO2",
                "Bermuda pH", "Bermuda pCO2",
                "Cariaco pH", "Cariaco pCO2"),
  stringsAsFactors = FALSE
)
F1_UNITS <- c(pH = "pH", pCO2 = "micro-atmospheres")

assert_headers(
  f1_raw,
  id_cols          = unique(f1_series$year_col),
  expected_headers = c(f1_series$value_col, ""),
  what             = "ocean-acidity_fig-1.csv"
)
if (sum(names(f1_raw) == "") != 3L ||
    any(unlist(f1_raw[names(f1_raw) == ""]) != "")) {
  stop("ocean-acidity_fig-1.csv: expected three empty spacer columns.", call. = FALSE)
}

f1 <- bind_rows(lapply(seq_len(nrow(f1_series)), function(i) {
  s <- f1_series[i, ]
  yr <- trimws(f1_raw[[s$year_col]])
  v  <- trimws(f1_raw[[s$value_col]])
  if (any(v != "" & yr == "")) {
    stop("ocean-acidity_fig-1.csv: ", s$value_col, " has a value with no year.", call. = FALSE)
  }
  keep <- v != ""
  data.frame(station = s$station, year = yr[keep], measure = s$measure,
             value = v[keep], unit = unname(F1_UNITS[s$measure]),
             stringsAsFactors = FALSE)
}))
bad <- is.na(suppressWarnings(as.numeric(c(f1$year, f1$value))))
if (any(bad)) stop("ocean-acidity_fig-1.csv: non-numeric year or value.", call. = FALSE)
assert_conservation(f1_raw, f1_series$value_col, nrow(f1), "ocean-acidity_fig-1.csv")

write_csv_stable(f1, file.path(out_dir, "ocean_carbon_dioxide_acidity.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

f1_columns <- list(
  col("station", "string",  "Ocean time-series station: Hawaii, Canary Islands, Bermuda, or Cariaco."),
  col("year",    "number",  "Sampling date as a decimal year, as published."),
  col("measure", "string",  "pH (acidity) or pCO2 (partial pressure of dissolved carbon dioxide)."),
  col("value",   "number",  "Measured value, in the unit named in `unit`."),
  col("unit",    "string",  "pH for pH; micro-atmospheres for pCO2.")
)
stopifnot(identical(vapply(f1_columns, `[[`, "", "name"), names(f1)))

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "ocean_carbon_dioxide_acidity.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "ocean-acidity_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = f1_columns
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
