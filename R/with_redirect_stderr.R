#' Temporarily redirect the standard error to a file
#'
#' This method allows to capture all texts sent to the *standard error*
#' stream (stderr).
#' In contrast with [utils::capture.output()], which only operates at
#' the R level and deals with R objects, this method truly redirects the
#' stream at a low (system) level.
#' Thus, the redirection works for low-level system calls, including
#' external processes invoked through [base::system()].
#'
#' @details
#' # Known problems
#'
#' The redirection does not seem to work when invoked in the R Console
#' provided by the PyCharm IDE.
#' In this case, try using the R Console directly from a terminal.
#'
#' @param expression The code to evaluate while redirecting stderr.
#' @param file The file to which all text will be redirected.
#' @param append Whether to append to the file, when it already exists.
#'   By default (false), the file is truncated. If the file does not exist,
#'   it is created.
#'
#' @return NULL
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
#' }
#'
#' @export
#'
with_redirect_stderr <- function (expression, file, append = FALSE) {
  # Redirect stderr to the desired file.
  old_fd <- begin_redirect_stderr(file, append)

  # Evaluate the code.
  eval(expression)

  # Revert back to the old stderr
  end_redirect_stderr(old_fd)

  invisible(NULL)
}
