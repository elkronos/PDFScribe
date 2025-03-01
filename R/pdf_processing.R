# --- PDF Files Listing ---
list_pdf_files <- function() {
  pdf_pattern <- "\\.pdf$"
  pdf_files <- if (opt$recursive) {
    list.files(opt$input_dir, pattern = pdf_pattern, full.names = TRUE, recursive = TRUE)
  } else {
    list.files(opt$input_dir, pattern = pdf_pattern, full.names = TRUE)
  }
  
  if (length(pdf_files) == 0) {
    flog.error("No PDF files found in %s. Exiting.", opt$input_dir)
    stop("No PDF files to process.")
  }
  flog.info("Found %d PDF files in %s", length(pdf_files), opt$input_dir)
  return(pdf_files)
}

# Validate PDF header to ensure file integrity.
check_pdf_validity <- function(pdf_path) {
  con <- file(pdf_path, "rb")
  header <- readBin(con, "raw", n = 5)
  close(con)
  return(rawToChar(header) == "%PDF-")
}

# Split text into chunks based on a maximum character limit.
chunk_text <- function(text, max_chars) {
  lines <- unlist(strsplit(text, "\n"))
  chunks <- character()
  current_chunk <- ""
  
  for (line in lines) {
    if (nchar(current_chunk) == 0) {
      candidate <- line
    } else {
      candidate <- paste(current_chunk, line, sep = "\n")
    }
    if (nchar(candidate) > max_chars) {
      chunks <- c(chunks, current_chunk)
      current_chunk <- line
    } else {
      current_chunk <- candidate
    }
  }
  if (nchar(current_chunk) > 0) {
    chunks <- c(chunks, current_chunk)
  }
  return(chunks)
}

# --- PDF Processing ---
process_pdf <- function(pdf_path) {
  flog.info("Processing file: %s", pdf_path)
  
  # Validate PDF format
  if (!check_pdf_validity(pdf_path)) {
    flog.error("File %s is not a valid PDF.", pdf_path)
    return(list(file = basename(pdf_path), error = "Invalid PDF file"))
  }
  
  file_size <- file.info(pdf_path)$size
  flog.debug("File size of %s: %d bytes", pdf_path, file_size)
  
  file_base <- sub("\\.pdf$", "", basename(pdf_path), ignore.case = TRUE)
  output_file <- file.path(opt$output_dir, paste0(file_base, ".json"))
  if (file.exists(output_file)) {
    flog.info("Output for %s already exists. Skipping.", basename(pdf_path))
    return(list(file = basename(pdf_path), status = "skipped"))
  }
  
  # Extract text with error handling
  text_pages <- tryCatch({
    pdftools::pdf_text(pdf_path)
  }, error = function(e) {
    flog.error("Error reading PDF %s: %s", pdf_path, e$message)
    return(NULL)
  })
  if (is.null(text_pages)) {
    return(list(file = basename(pdf_path), error = "Failed to extract text"))
  }
  
  text_content <- paste(text_pages, collapse = "\n")
  if (nchar(text_content) < 100) {
    flog.warn("PDF %s may be image-based or encrypted.", pdf_path)
  }
  
  # Determine API endpoint based on model
  api_url <- if (grepl("turbo", opt$model, ignore.case = TRUE) ||
                 grepl("gpt-4", opt$model, ignore.case = TRUE)) {
    "https://api.openai.com/v1/chat/completions"
  } else {
    "https://api.openai.com/v1/completions"
  }
  
  max_chars <- 3000
  result_text <- if (nchar(text_content) > max_chars) {
    flog.info("Splitting large PDF %s into chunks.", pdf_path)
    chunks <- chunk_text(text_content, max_chars)
    responses <- sapply(chunks, function(chunk) {
      call_openai_api(chunk, api_url)
    })
    paste(responses, collapse = "\n")
  } else {
    call_openai_api(text_content, api_url)
  }
  
  result_data <- list(file = basename(pdf_path), result = result_text)
  # Convert to JSON and write using writeLines for clarity.
  json_output <- jsonlite::toJSON(result_data, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json_output, con = output_file)
  flog.info("Saved result for %s to %s", basename(pdf_path), output_file)
  
  # S3 upload (if bucket specified)
  if (!is.null(opt$s3_bucket)) {
    if (s3_upload_with_retry(output_file, opt$s3_bucket, basename(output_file))) {
      flog.info("Uploaded %s to S3.", basename(output_file))
    } else {
      flog.error("Failed to upload %s to S3.", basename(output_file))
    }
  }
  
  flog.info("Finished processing %s", pdf_path)
  return(result_data)
}
