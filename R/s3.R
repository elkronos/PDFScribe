# S3 upload with retry logic.
s3_upload_with_retry <- function(file, bucket, object_name) {
  max_attempts <- 3
  attempt <- 1
  while (attempt <= max_attempts) {
    tryCatch({
      aws.s3::put_object(file = file, object = object_name, bucket = bucket)
      return(TRUE)
    }, error = function(e) {
      flog.warn("S3 upload attempt %d failed for %s: %s", attempt, object_name, e$message)
    })
    Sys.sleep(2^(attempt - 1))
    attempt <- attempt + 1
  }
  flog.error("S3 upload failed after maximum attempts for %s", object_name)
  return(FALSE)
}