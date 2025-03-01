#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)       # Command-line argument parsing
  library(pdftools)       # PDF text extraction
  library(jsonlite)       # JSON output handling
  library(httr)           # HTTP requests (OpenAI API)
  library(futile.logger)  # Logging
  library(future)         # Concurrency
  library(future.apply)   # Parallel apply functions
  library(aws.s3)         # AWS S3 integration
  library(progressr)      # Progress reporting with future.apply
})

# --- Command Line Options ---
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", default = NULL,
              help = "Directory with PDF files to process", metavar = "path"),
  make_option(c("-o", "--output_dir"), type = "character", default = "output",
              help = "Directory to save output JSON files", metavar = "path"),
  make_option(c("-b", "--s3_bucket"), type = "character", default = NULL,
              help = "S3 bucket name for uploading results (optional)"),
  make_option(c("-p", "--parallelism"), type = "integer", default = 1,
              help = "Number of parallel processes to use (must be > 0)", metavar = "int"),
  make_option(c("-k", "--api_key"), type = "character", default = NULL,
              help = "OpenAI API key (or set OPENAI_API_KEY env variable)"),
  make_option(c("-m", "--model"), type = "character", default = "text-davinci-003",
              help = "OpenAI model to use (e.g., 'text-davinci-003' or 'gpt-3.5-turbo')"),
  make_option(c("-t", "--temperature"), type = "double", default = 0.7,
              help = "Sampling temperature for the API", metavar = "double"),
  make_option(c("-r", "--recursive"), action = "store_true", default = FALSE,
              help = "Recursively search for PDFs in subdirectories"),
  make_option(c("-g", "--log_file"), type = "character", default = "processing.log",
              help = "Path to the log file", metavar = "path"),
  make_option(c("-l", "--log_level"), type = "character", default = "INFO",
              help = "Logging level (DEBUG, INFO, WARN, ERROR)", metavar = "level")
)
opt <- parse_args(OptionParser(option_list = option_list))

main <- function() {
  # Setup logging and validate inputs
  initialize_logging()
  validate_inputs(opt)
  prepare_output_directory(opt)
  
  # List PDF files and process in parallel
  pdf_files <- list_pdf_files(opt$input_dir, opt$recursive)
  plan(multisession, workers = opt$parallelism)
  # ... process each PDF ...
}

if (interactive() || identical(environment(), globalenv())) {
  main()
}
