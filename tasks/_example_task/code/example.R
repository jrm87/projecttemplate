#!/usr/bin/env Rscript
# example.R — Skeleton R script with optparse argument parsing.
#
# Usage:
#   Rscript code/example.R --input input/data.csv --output output/result.csv
#
# This script demonstrates the pattern for production R scripts:
#   1. Parse command-line arguments (no hardcoded paths)
#   2. Read from input/
#   3. Process data
#   4. Write to output/

library(optparse)

# --- Command-line arguments ---
option_list <- list(
  make_option("--input", type = "character", default = "input/data.csv",
              help = "Path to input data file"),
  make_option("--output", type = "character", default = "output/result.csv",
              help = "Path to output file")
)
opt <- parse_args(OptionParser(option_list = option_list))

# --- Read input ---
cat("Reading input from:", opt$input, "\n")
# data <- data.table::fread(opt$input)

# --- Process ---
cat("Processing data...\n")
# result <- data[, .(mean_val = mean(value)), by = group]

# --- Write output ---
cat("Writing output to:", opt$output, "\n")
# data.table::fwrite(result, opt$output)

cat("Done.\n")
