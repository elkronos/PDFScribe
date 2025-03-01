# Call the OpenAI API with retries and exponential backoff.
call_openai_api <- function(text_chunk, api_url) {
  max_attempts <- 3
  attempt <- 1
  while (attempt <= max_attempts) {
    request_body <- if (grepl("turbo", opt$model, ignore.case = TRUE) ||
                        grepl("gpt-4", opt$model, ignore.case = TRUE)) {
      list(
        model = opt$model,
        messages = list(list(role = "user", content = text_chunk)),
        temperature = opt$temperature
      )
    } else {
      list(
        model = opt$model,
        prompt = text_chunk,
        max_tokens = 1024,
        temperature = opt$temperature
      )
    }
    
    res <- httr::POST(
      url = api_url,
      body = request_body,
      encode = "json",
      add_headers(
        Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")),
        `Content-Type` = "application/json"
      )
    )
    
    if (!httr::http_error(res)) {
      res_content <- httr::content(res, as = "parsed")
      if (!is.null(res_content$error)) {
        flog.error("API error: %s", res_content$error$message)
      } else if (!is.null(res_content$choices)) {
        if (!is.null(res_content$choices[[1]]$message)) {
          return(res_content$choices[[1]]$message$content)
        } else {
          return(res_content$choices[[1]]$text)
        }
      }
    }
    flog.warn("API call attempt %d failed. Retrying...", attempt)
    Sys.sleep(2^(attempt - 1))
    attempt <- attempt + 1
  }
  stop("API call failed after maximum attempts for current chunk")
}