# r2dup2

> Author: <rchaput.pro@gmail.com>

## Description

**r2dup2** is a `R` package that allows you to redirect streams, especially
*stdout* and *stderr*, at the system level in `R`.

Its main rationale is that the default `r utils::capture.output` function
only redirects `R` messages: it does not truly redirect the system streams,
and thus fails with sub-processes, such as *pandoc* when using *RMarkdown*.

See for example:

```r
capture.output(file = "error.txt", type = "message", {
    cat("This will be printed to error.txt", file = stderr())
    message("This will also be printed to error.txt")
    system("echo But this will be printed to R Console instead of error.txt! >&2")
})
```

**r2dup2** instead uses the `dup2` C function to effectively redirect
streams in R.

## Installation

*Important*: this packages requires a POSIX-compliant system, such as
Linux, or macOS.
It will **not** work on Windows, as it uses low-level system calls that are
specific to POSIX.

It is recommended to use either *remotes* or *devtools* to install this
package:

```r
install.packages("remotes")
remotes::install_github("rchaput/r2dup2")
```

or, alternatively:

```r
install.packages("devtools")
devtools::install_github("rchaput/r2dup2")
```

## How to use
