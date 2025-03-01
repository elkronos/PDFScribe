# PDFScribe

PDFScribe is an R-based package designed to process PDF documents. It extracts text (and images, if needed), samples content from the PDFs, and automatically builds structured requests for AI analysis. The package supports processing PDFs stored locally or on Amazon S3, leverages parallel processing to improve performance, and incorporates robust error handling and logging.

## Features

- **PDF Extraction:** Reads and validates PDF files using extraction tools.
- **Content Sampling:** Samples pages using reservoir sampling and extracts key “anchor” text.
- **AI Prompt Generation:** Automatically constructs structured prompts for AI analysis.
- **Local & S3 Integration:** Processes PDFs from local directories and S3.
- **Parallel Processing:** Utilizes multiple cores for concurrent PDF processing.
- **Robust Logging & Error Handling:** Provides detailed logs and retry mechanisms for API calls and file operations.
- **Comprehensive Testing:** Includes a suite of UAT tests using the `testthat` framework.

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/PDFScribe.git
   cd PDFScribe
