# Regression checks on the generated data for the Ocean Acidity indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are at the
# bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 1 dataset(s)", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nFigure images\n")
# Figures 2 and 3 have no data; the site shows EPA's image. Hashes from data-raw/PROVENANCE.md.
images <- c(
  "acidity_download2_2024.png"         = "22111a116b2c4d6f03a7ded7592581cf16410e8f139e4c37908f60d2ee8a6cbd",
  "acidity_download-ph-scale_2021.png" = "1c4d2a518c71ab495759b78a64189243e7338c35548d338f949b477e86a25ae9"
)
for (f in names(images)) {
  p <- file.path("images", f)
  check(sprintf("images/%s is present and unchanged", f),
        file.exists(p) && identical(file_sha256(p), images[[f]]))
}

cat("\nValue snapshots\n")
f1 <- rd("ocean_carbon_dioxide_acidity.csv")
check("ocean_carbon_dioxide_acidity.csv: 2181 rows", nrow(f1) == 2181L)
check("ocean_carbon_dioxide_acidity.csv: columns station, decimal_year, measure, value, unit",
      identical(names(f1), c("station", "decimal_year", "measure", "value", "unit")))
check("units: pH for pH, micro-atmospheres for pCO2",
      all(f1$unit[f1$measure == "pH"] == "pH") &&
      all(f1$unit[f1$measure == "pCO2"] == "micro-atmospheres"))

# station, measure, rows, first year/value, last year/value, min, max (source order)
f1_snap <- read.csv(text = "
station,measure,n,first_year,first_value,last_year,last_value,min,max
Hawaii,pH,330,1988.833333,8.1097,2022.668493,8.0341,8.0272,8.1508
Hawaii,pCO2,330,1988.833333,330.9,2022.668493,408.8,298.3,412.1
Canary Islands,pH,143,1995.7507,8.0765,2009.8607,8.045,8.045,8.1331
Canary Islands,pCO2,143,1995.7507,377.6526,2009.8607,412.5473,323.7588,412.6208109
Bermuda,pH,415,1983.6959,8.07,2015.95,8.095,7.998,8.181
Bermuda,pCO2,415,1983.6959,363.187,2015.95,355.49,272.018,451.785
Cariaco,pH,210,1995.950685,8.0597,2017.032877,8.044,7.944,8.1234
Cariaco,pCO2,195,1995.950685,400.9259855,2017.032877,373.5639285,299.4675843,566.2994148
", colClasses = "character")

check("station/measure series are exactly the eight expected, in order",
      identical(unique(paste(f1$station, f1$measure)), paste(f1_snap$station, f1_snap$measure)))
for (i in seq_len(nrow(f1_snap))) {
  e <- f1_snap[i, ]
  s <- f1[f1$station == e$station & f1$measure == e$measure, ]
  v <- as.numeric(s$value)
  k <- nrow(s)
  check(sprintf("%s %s: %s rows", e$station, e$measure, e$n), k == as.integer(e$n))
  check(sprintf("%s %s: first row %s = %s", e$station, e$measure, e$first_year, e$first_value),
        k > 0 && s$decimal_year[1] == e$first_year && s$value[1] == e$first_value)
  check(sprintf("%s %s: last row %s = %s", e$station, e$measure, e$last_year, e$last_value),
        k > 0 && s$decimal_year[k] == e$last_year && s$value[k] == e$last_value)
  check(sprintf("%s %s: min %s, max %s", e$station, e$measure, e$min, e$max),
        k > 0 && s$value[which.min(v)] == e$min && s$value[which.max(v)] == e$max)
}

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
