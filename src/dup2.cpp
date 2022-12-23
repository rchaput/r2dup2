/*
 * This file defines helper functions to access low-level system calls
 * in R, such as `open`, `dup2`, etc.
 *
 * Thus, this file defines 2 functions to wrap the calls to `dup2`:
 * - `begin_redirect_stderr`: redirects stderr to the specified file, and
 *   returns a copy of the previous stderr. This copy is useful to revert
 *   the redirection afterwards.
 * - `end_redirect_stderr`: redirects stderr to the copy of its original
 *   file descriptor, thus effectively reverting the redirection. After
 *   calling this method, writing to stderr will work as originally.
 *
 * To be used, this file must be sourced, via the Rcpp package:
 * `Rcpp::sourceCpp("src/dup2.cpp")`
 *
 * The functions must be called like so:
 * ```R
 * old_fd <- begin_redirect_stderr("path/to/file.err", FALSE)
 * # Your code here ...
 * end_redirect_stderr(old_fd)
 * ```
 */

#include <Rcpp.h>
#include <fcntl.h>          // For `open`, `O_WRONLY`, etc.
#include <unistd.h>         // For `dup`, `dup2`
#include <sys/errno.h>      // For `errno`

using namespace Rcpp;


/*
 * Helper function to get the oflags when we want to open a file.
 *
 * Only 2 modes are currently supported:
 *  - `w` (for `write`): create file if it does not exist.
 *  - `a` (for `append`): append to existing file.
 *
 * See `man 2 open` for details on what are oflags, O_WRONLY, and
 * other flags.
 */
int get_oflag(String mode) {
    if (mode == String("w")) {
        // Write only, Create if it does not exist.
        return O_WRONLY | O_CREAT;
    } else if (mode == String("a")) {
        // Write only, Append to file.
        return O_WRONLY | O_APPEND;
    } else {
        stop("Unrecognized mode: %s", mode.get_cstring());
    }
    return -1;
}


/*
 * Simplified helper function to get oflags.
 *
 * This is a less error-prone version of `get_oflag(String mode)`.
 * The boolean parameter `append` controls the behaviour:
 *  - When `true`, new text will be appended to the existing file.
 *  - When `false`, the file will be truncated.
 */
int get_oflag(bool append) {
    String mode = (append) ? String("a") : String("w");
    int oflag = get_oflag(mode);
    return oflag;
}


//' Redirect stderr to a given file.
//'
//' This function redirects the standard error (stderr) to a new file
//' descriptor, pointing to the file at `filepath`.
//'
//' @param filepath The path to the desired file. Must not be null.
//'
//' @param append Controls whether the text should be appended if the
//'   file already exists. By default (`false`), truncates the file.
//'
//' @return An integer corresponding to the file descriptor of the old
//'   stderr, so that the redirection can be later reverted.
//'
//' @seealso [end_redirect_stderr()].
// [[Rcpp::export]]
int begin_redirect_stderr(String filepath, bool append = false) {

    // 1. Make a copy of STDERR (so we can undo the replacement after).
    int old_stderr = dup(STDERR_FILENO);
    if (old_stderr < 0) {
        stop("Error while calling dup in begin_redirect_stderr: errno=%d",
             errno);
    }

    // 2. Open the (potentially new) file as a file descriptor
    int oflag = get_oflag(append);
    int mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH; // rw-r-r
    int fd = open(filepath.get_cstring(), oflag, mode);
    if (fd < 0) {
        stop("Error while calling open in begin_redirect_stderr: errno=%d",
             errno);
    }

    // 3. Replace the previous STDERR with the new fd
    int res = dup2(fd, STDERR_FILENO);
    if (res < 0) {
        stop("Error while calling dup2 in begin_redirect_stderr: errno=%d",
             errno);
    }
    close(fd);

    return old_stderr;
}


//' Reverts the redirection of stderr.
//'
//' This function redirects the standard error (stderr) to its old file
//' descriptor (usually, this ultimately means the R Console).
//'
//' @param old_stderr The file descriptor to the old (previous) stderr,
//'   before the redirection. This corresponds to the return value of
//'   [begin_redirect_stderr()].
//'
//' @return The result code, usually equal to `2`. A negative value,
//'   such as `-1`, indicates an error.
//'
//' @seealso [begin_redirect_stderr()].
// [[Rcpp::export]]
int end_redirect_stderr(int old_stderr) {
    int res = dup2(old_stderr, STDERR_FILENO);
    if (res < 0) {
        stop("Error while calling dup2 in end_redirect_stderr: errno=%d",
             errno);
    }
    close(old_stderr);
    return res;
}
