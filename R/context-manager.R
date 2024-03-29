#' Context managers
#'
#' @param enter function to run before taking actions
#' @param exit function to run after taking actions
#' @param error optional function to run if an error is thrown
#' @param as character optional way to specify a default name for assigning
#' the return of the enter function.
#' @return an S3 class "contextManager" object
#' @seealso `with-context-manager`
#' @aliases contextManager
#' @export
ContextManager <- function(enter = function() {}, exit = function() {}, # nolint
                           error = NULL, as = NULL) {
    structure(list(enter = enter, exit = exit, error = error, as = as),
        class = "contextManager"
    )
}

#' Context manager's "with" method
#'
#' @param data [`contextManager`]
#' @param expr code to evaluate within that context
#' @param ... additional arguments. One additional supported argument is "as",
#' which lets you assign the return of your "enter" function to an object you
#' can access.
#' @return Nothing.
#' @name with-context-manager
#' @seealso [`ContextManager`]
#' @export
with.contextManager <- function(data, expr, ...) {
    env <- parent.frame()
    on.exit(data$exit())
    setup <- data$enter()
    dots <- list(...)
    as.name <- dots$as %||% data$as
    if (!is.null(as.name)) {
        assign(as.name, setup, envir = env)
        ## rm this after running? or add the rm step to the exit
    }
    if (is.function(data$error)) {
        tryCatch(eval(substitute(expr), envir = parent.frame()), error = data$error)
    } else {
        eval(substitute(expr), envir = parent.frame())
    }
}

#' Set some global options temporarily
#'
#' @param ... named options to set using `options()`
#' @param crunch named list of options to set in crunch's higher priority
#' options environment
#' @return an S3 class "contextManager" object
#' @seealso [`with-context-manager`] [`ContextManager`]
#' @export
temp.options <- function(..., crunch = list()) {
    new <- list(...)
    old <- sapply(names(new), envOrOption, simplify = FALSE)

    new_crunch <- crunch
    old_crunch <- sapply(names(new_crunch), get_crunch_opt, simplify = FALSE)
    return(ContextManager(
        function() {
            do.call(options, new)
            do.call(set_crunch_opts, new_crunch)
        },
        function() {
            do.call(options, old)
            do.call(set_crunch_opts, old_crunch)
        }
    ))
}

#' @rdname temp.options
#' @export
temp.option <- temp.options
