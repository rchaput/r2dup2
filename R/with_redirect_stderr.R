#' Temporarily redirect the standard error to a file
#'
#' This method allows to capture all texts sent to the *standard error*
#' stream (stderr).
#' In contrast with [utils::capture.output()], which only operates at
#' the R level and deals with R objects, this method truly redirects the
#' stream at a low (system) level.
#' Thus, the redirection works for low-level system calls, including
#' external processes invoked through [base::system()], [base::system2()],
#' or similar.
#'
#' @details
#' # Known problems
#'
#' The redirection does not seem to work when invoked in the R Console
#' provided by the PyCharm IDE.
#' In this case, try using the R Console directly from a terminal.
#'
#' @param expression The code to evaluate while redirecting stderr.
#' @param file The file to which all text will be redirected. By default,
#'   (`NULL`), a temporary file is automatically created, and the captured
#'   text is returned by the function.
#' @param append Whether to append to the file, when it already exists.
#'   By default (`FALSE`), the file is truncated. If the file does not exist,
#'   it is created. This argument has no effect when `file` is `NULL`.
#'
#' @return The return value depends on the `file` parameter:
#'   * When `file` is `NULL`, the function returns the captured text,
#'     as returned by [base::readLines()].
#'   * Otherwise, the function does not return anything (an invisible `NULL`).
#'
#' @examples
#' \dontrun{
#' with_redirect_stderr(file = "test.err", {
#'   system("echo This line will be written to test.err! >&2")
#' })
#'
#' with_redirect_stderr(file = "test.err", append = TRUE, {
#'   system("echo This will not truncate the previous line! >&2")
#' })
#'
#' stderr <- with_redirect_stderr({
#'   system("echo Redirecting to a variable also works! >&2")
#' })
#' }
#'
#' @export
#'
with_redirect_stderr <- function (expression, file = NULL, append = FALSE) {

  # If the user did not specify a file, create a temporary one
  if (is.null(file)) {
    filepath <- tempfile(fileext = ".err")
    if (append) {
      # Using `append` is irrelevant, since we create a temporary file
      warning("`append` should not be `TRUE` when `file` is `NULL`")
    }
  } else {
    filepath <- file
  }

  # Redirect stderr to the desired file.
  old_fd <- begin_redirect_stderr(filepath, append)

  # Evaluate the code.
  eval(expression)

  # Revert back to the old stderr
  end_redirect_stderr(old_fd)

  if (is.null(file)) {
    # Read the temporary file's contents, delete the file, and return
    # the contents to the user
    lines <- readLines(filepath)
    unlink(filepath)
    lines
  } else {
    invisible(NULL)
  }
}
