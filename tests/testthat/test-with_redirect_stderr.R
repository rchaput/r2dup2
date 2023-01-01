# Helper function to write to stderr using the `echo` shell command
helper_echo <- function (message) {
  # The command to be executed is `echo >&2 {MESSAGE}`
  # where `>&2` performs the redirection to stderr.
  system2("echo", args = c(">&2", message))
}


test_that("redirection to a new file works", {
  # Create a new (temporary) file
  filepath <- tempfile(fileext = ".err")

  # Redirect stderr to this file
  # Generate one message
  message <- "This line should be the only one"
  r2dup2::with_redirect_stderr(file = filepath, append = FALSE, {
    helper_echo(message)
  })

  # Verify that the content of the file equals exactly to the given message
  lines <- readLines(filepath)
  expect_identical(lines, message)

  # Delete the temporary file
  unlink(filepath)
})


test_that("redirection to an existing file works", {
  # Create a new (temporary) file
  filepath <- tempfile(fileext = ".err")

  # Write one message to the file (make sure that there is a newline)
  previous_message <- "This is a previous message"
  cat(previous_message, file = filepath, sep = "\n")

  # Redirect stderr to this file
  # Generate one message
  message <- "This line should be preceded by the previous message"
  r2dup2::with_redirect_stderr(file = filepath, append = TRUE, {
    helper_echo(message)
  })

  # Verify that the contents equal exactly the previous message + the new one
  lines <- readLines(filepath)
  expect_identical(lines, c(previous_message, message))

  # Delete the temporary file
  unlink(filepath)
})


test_that("redirecting several messages works", {
  # Create a new (temporary) file
  filepath <- tempfile(fileext = ".err")

  # Redirect stderr to this file
  # Generate several messages
  messages <- c(
    "This is the 1st message",
    "It should be followed by the 2nd message",
    "The 3rd message is the last"
  )
  with_redirect_stderr(file = filepath, append = FALSE, {
    for (message in messages) {
      helper_echo(message)
    }
  })

  # Verify that the contents equal exactly the 3 messages
  lines <- readLines(filepath)
  expect_identical(lines, messages)

  # Delete file
  unlink(filepath)
})


test_that("sequential redirections with append work", {
  # Create a new temporary file
  filepath <- tempfile(fileext = ".err")

  # Redirect stderr to this file
  # Generate a message
  # (append set to false to make sure the file is initially empty)
  message1 <- "This is the 1st message"
  with_redirect_stderr(file = filepath, append = FALSE, {
    helper_echo(message1)
  })

  # Redirect in a second block
  # Generate a message
  message2 <- "This line should not truncate the first one"
  with_redirect_stderr(file = filepath, append = TRUE, {
    helper_echo(message2)
  })

  # Verify that the contents equal exactly the 2 messages
  lines <- readLines(filepath)
  expect_identical(lines, c(message1, message2))

  # Delete file
  unlink(filepath)
})


test_that("sequential redirections without append work", {
    # Create a new temporary file
  filepath <- tempfile(fileext = ".err")

  # Redirect stderr to this file
  # Generate a message
  # (append set to false to make sure the file is initially empty)
  message1 <- "This is the 1st message"
  with_redirect_stderr(file = filepath, append = FALSE, {
    helper_echo(message1)
  })

  # Redirect in a second block
  # Generate a message
  message2 <- "This line should replace the first one"
  with_redirect_stderr(file = filepath, append = FALSE, {
    helper_echo(message2)
  })

  # Verify that the contents equal only the 2nd message
  lines <- readLines(filepath)
  expect_identical(lines, message2)

  # Delete file
  unlink(filepath)
})


test_that("redirecting to a variable works", {
  # Generate a message
  message <- "This line should be returned by the function"
  # Capture stderr to a variable, by not specifying the file
  stderr <- with_redirect_stderr(file = NULL, {
    helper_echo(message)
  })

  # Verify that the returned value is the same as message
  expect_identical(stderr, message)
})
