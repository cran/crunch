#' Check a Crunch progress URL until it finishes
#'
#' You'll probably only call this function if progress polling times out and its
#' error message tells you to call `pollProgress` to resume.
#'
#' @param progress_url A Crunch progress URL
#' @param wait Number of seconds to wait between polling. This time is increased
#' 20 percent on each poll.
#' @param error_handler An optional function that takes the status object
#' when the progress is less than 0 (meaning the request failed)
#' @return The percent completed of the progress. Assuming the
#' `options(crunch.timeout)` (default: 15 minutes) hasn't been reached, this
#' will be 100. If the timeout is reached, it will be the last reported progress
#' value.
#' @export
#' @importFrom httpcache uncached
pollProgress <- function(progress_url, wait = .5, error_handler = NULL) {
    ## Configure polling interval. Will increase by rate (>1) until reaches max
    max.wait <- 30
    increase.by <- 1.2

    starttime <- Sys.time()
    timeout <- crunchTimeout()
    timer <- function(since, units = "secs") {
        difftime(Sys.time(), since, units = units)
    }
    ## Set up the progress bar
    pb <- setup_progress_bar(0, 100, style = 3)

    prog <- uncached(crGET(progress_url))
    status <- prog$progress
    update_progress_bar(pb, status)
    while (status >= 0 && status < 100 && timer(starttime) < timeout) {
        Sys.sleep(wait)
        prog <- uncached(crGET(progress_url))
        status <- prog$progress
        update_progress_bar(pb, status)
        wait <- min(max.wait, wait * increase.by)
    }
    close(pb)

    if (status < 0 && !is.null(error_handler)) {
        return(error_handler(prog))
    } else if (status < 0) {
        email <- "There was an error on the server. Please contact support@crunch.io"
        msg <- prog$message %||% email
        halt(msg)
    } else if (status != 100) {
        halt(
            "Your process is still running on the server. It is currently ",
            round(status), '% complete. Check `pollProgress("',
            progress_url, '")` until it reports 100% complete'
        )
    }
    return(status)
}

#' @importFrom utils txtProgressBar
setup_progress_bar <- function(...) {
    if (isTRUE(envOrOption("crunch.show.progress", TRUE, expect_lgl = TRUE))) {
        return(txtProgressBar(...))
    } else {
        ## Need to return a connection so that `close()` works in silent mode
        return(pipe(""))
    }
}

#' @importFrom utils setTxtProgressBar
update_progress_bar <- function(...) {
    if (isTRUE(envOrOption("crunch.show.progress", TRUE, expect_lgl = TRUE))) setTxtProgressBar(...)
}

crunchTimeout <- function() {
    opt <- envOrOption("crunch.timeout", expect_num = TRUE)
    if (!is.numeric(opt)) opt <- 900
    return(opt)
}

progressMessage <- function(msg) {
    if (isTRUE(envOrOption("crunch.show.progress", TRUE, expect_lgl = TRUE))) {
        message(msg)
    }
}
