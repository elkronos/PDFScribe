# --- Logging Setup ---
initialize_logging <- function() {
  log_levels <- list("DEBUG" = DEBUG, "INFO" = INFO, "WARN" = WARN, "ERROR" = ERROR)
  flog.threshold(log_levels[[toupper(opt$log_level)]])
  flog.appender(appender.file(opt$log_file))
  flog.info("Script started.")
}

# --- Input & Environment Validation ---
validate_inputs <- function() {
  if (is.null(opt$input_dir) || !dir.exists(opt$input_dir)) {
    stop(sprintf("Input directory is not provided or does not exist: %s", opt$input_dir))
  }
  if (opt$parallelism < 1) {
    stop("Parallelism must be a positive integer.")
  }
  if (dir.exists(opt$output_dir) && file.access(opt$output_dir, 2) != 0) {
    stop(sprintf("Output directory %s is not writable.", opt$output_dir))
  }
  
  # API Key Validation
  if (is.null(opt$api_key) && Sys.getenv("OPENAI_API_KEY") == "") {
    stop("OpenAI API key not provided. Supply via -k option or set the OPENAI_API_KEY environment variable.")
  } else if (!is.null(opt$api_key)) {
    Sys.setenv(OPENAI_API_KEY = opt$api_key)
    flog.debug("API key provided via command-line argument.")
  } else {
    flog.debug("API key obtained from environment variable.")
  }
}

# --- Output Directory Preparation ---
prepare_output_directory <- function() {
  if (!dir.exists(opt$output_dir)) {
    dir.create(opt$output_dir, recursive = TRUE)
    flog.info("Created output directory: %s", opt$output_dir)
  }
}