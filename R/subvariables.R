##' Subvariables in Array Variables
##'
##' Multiple-response and categorical-array variables contain a set of 
##' subvariables within them. The Subvariables class encapsulates them.
##'
##' Subvariables can be accessed from array variables (including multiple
##' response) with the \code{subvariables} method. They can be assigned back
##' with the \code{subvariables<-} setter, but there are limitations to what
##' is supported. Specifically, you can reorder subvariables, but you cannot
##' add or remove subvariables by \code{subvariables<-} assignment.
##'
##' Subvariables have a \code{names} attribute that can be accessed, showing
##' the display names of the subvariables. These can be set with the 
##' \code{names<-} method. 
##'
##' Finally, subvariables can be accessed as regular (categorical) variables
##' with the \code{$} and \code{[[} extract methods. 
##' 
##' See the vignette on array variables for further details and examples.
##'
##' @param x A Variable or Subvariables object
##' @param value For the setters, the appropriate values to set
##'
##' @name Subvariables
##' @aliases Subvariables subvariables subvariables<-
##' @seealso \code{\link{subvars-extract}} \code{\link{describe-catalog}} \code{vignette("array-variables", package="crunch")}
NULL

##' @rdname Subvariables
##' @export
setMethod("subvariables", "CategoricalArrayVariable", function (x) {
    tup <- tuple(x)
    catalog_url <- tup$subvariables_catalog %||% tup@index_url
    vars <- VariableCatalog(crGET(catalog_url))
    return(Subvariables(vars[x@body$subvariables]))
})

##' @rdname Subvariables
##' @export
setMethod("subvariables<-", c("CategoricalArrayVariable", "ANY"),
    function (x, value) {
        halt("Can only assign an object of class Subvariables")
    })
##' @rdname Subvariables
##' @export
setMethod("subvariables<-", c("CategoricalArrayVariable", "Subvariables"),
    function (x, value) {
        old <- x@body$subvariables
        new <- urls(value)
        if (!setequal(old, new)) {
            halt("Can only reorder, not change, subvariables")
        }
        return(setCrunchSlot(x, "subvariables", new))
    })

##' @rdname describe-catalog
##' @export
setMethod("names", "Subvariables", function (x) {
    vapply(index(x), function (a) a$name, character(1), USE.NAMES=FALSE)
})

##' @rdname describe-catalog
##' @export
setMethod("names<-", "Subvariables", function (x, value) {
    stopifnot(is.character(value), length(x) == length(value),
        !any(duplicated(value)))
    index(x) <- mapply(function (tuple, val) {
            tuple[["name"]] <- val
            return(tuple)
        }, tuple=index(x), val=value, SIMPLIFY=FALSE, USE.NAMES=TRUE)
    crPATCH(self(x), body=toJSON(index(x)))
    return(x)
})

##' @rdname describe-catalog
##' @export
setMethod("aliases", "Subvariables", function (x) {
    vapply(index(x), function (a) a$alias, character(1), USE.NAMES=FALSE)
})

##' @rdname describe-catalog
##' @export
setMethod("aliases<-", "Subvariables", function (x, value) {
    stopifnot(is.character(value), length(x) == length(value),
        !any(duplicated(value)))
    index(x) <- mapply(function (tuple, val) {
            tuple[["alias"]] <- val
            return(tuple)
        }, tuple=index(x), val=value, SIMPLIFY=FALSE, USE.NAMES=TRUE)
    crPATCH(self(x), body=toJSON(index(x)))
    return(x)
})

##' Extract and modify subsets of subvariables
##'
##' @param x Subvariables or an array Variable (which contains subvariables)
##' @param i which subvariables to extract
##' @param name For \code{$}, the name (not alias) of the subvariable to
##' extract
##' @param j Invalid
##' @param drop Invalid
##' @param ... additional arguments
##' @param value For updating, a CrunchExpr
##' @return A subset of \code{x} if extracting, otherwise \code{x} duly modified
##' @name subvars-extract
NULL

##' @rdname subvars-extract
##' @export
setMethod("[[", c("Subvariables", "character"), function (x, i, ...) {
    i <- match(i, names(x))
    if (is.na(i)) return(NULL)
    callNextMethod(x, i, ...)    
})
##' @rdname subvars-extract
##' @export
setMethod("[[", c("Subvariables", "ANY"), function (x, i, ...) {
    out <- VariableTuple(index_url=self(x), entity_url=urls(x)[i],
        body=index(x)[[i]])
    if (!is.null(out)) {
        out <- entity(out)
    }
    return(out)
})
##' @rdname subvars-extract
##' @export
setMethod("$", "Subvariables", function (x, name) x[[name]])

##' @rdname subvars-extract
##' @export
setMethod("[", c("Subvariables", "character"), function (x, i, ...) {
    w <- match(i, names(x))
    if (any(is.na(w))) {
        halt("Undefined subvariables selected: ", serialPaste(i[is.na(w)]))
    }
    return(x[w])
})

##' @rdname subvars-extract
##' @export
setMethod("[[<-", 
    c("Subvariables", "character", "missing", "CrunchVariable"), 
    function (x, i, value) {
        i <- match(i, names(x))
        if (is.na(i)) {
            halt("subscript out of bounds")
        }
        callNextMethod(x, i, value)    
    })
##' @rdname subvars-extract
##' @export
setMethod("[[<-", 
    c("Subvariables", "ANY", "missing", "CrunchVariable"), 
    function (x, i, value) {
        if (self(value) != urls(x)[i]) {
            halt("Cannot add or remove subvariables")
        }
        index(x)[[self(value)]] <- tuple(value)@body
        return(x)
    })
##' @rdname subvars-extract
##' @export
setMethod("[[<-", 
    c("Subvariables", "ANY", "missing", "NULL"),
    function (x, i, value) {
        halt("Cannot add or remove subvariables")
    })
##' @rdname subvars-extract
##' @export
setMethod("[[<-", 
    c("Subvariables", "ANY", "missing", "ANY"),
    function (x, i, value) {
        halt("Can only assign Variables into an object of class Subvariables")
    })

##' @rdname subvars-extract
##' @export
setMethod("[<-", c("Subvariables", "character", "missing", "Subvariables"), 
    function (x, i, value) {
        w <- match(i, names(x))
        if (any(is.na(w))) {
            halt("Undefined subvariables selected: ", serialPaste(i[is.na(w)]))
        }
        callNextMethod(x, w, value)
    })
##' @rdname subvars-extract
##' @export
setMethod("[<-", c("Subvariables", "ANY", "missing", "Subvariables"), 
    function (x, i, value) {
        inbound <- vapply(value, function (a) self(a), character(1))
        if (!all(inbound %in% urls(x)[i])) {
            halt("Cannot add or remove subvariables")
        }
        index(x)[i] <- index(value)
        names(index(x))[i] <- inbound
        return(x)
    })
##' @rdname subvars-extract
##' @export
setMethod("[<-", c("Subvariables", "ANY", "missing", "ANY"), 
    function (x, i, value) {
        halt("Can only assign Variables into an object of class Subvariables")
    })

##' @export
as.list.Subvariables <- function (x, ...) lapply(names(x), function (i) x[[i]])

##' @rdname subvars-extract
##' @export
setMethod("[", "CategoricalArrayVariable", function (x, i, ...) {
    return(subvariables(x)[i, ...])
})
## Special methods so as not to conflict with c("CrunchVariable", "numeric")

##' @rdname subvars-extract
##' @export
setMethod("[", c("CategoricalArrayVariable", "numeric"), function (x, i, ...) {
    return(subvariables(x)[i, ...])
})
##' @rdname subvars-extract
##' @export
setMethod("[", c("CategoricalArrayVariable", "logical"), function (x, i, ...) {
    return(subvariables(x)[i, ...])
})
##' @rdname subvars-extract
##' @export
setMethod("[[", "CategoricalArrayVariable", function (x, i, ...) {
    return(subvariables(x)[[i, ...]])
})
##' @rdname subvars-extract
##' @export
setMethod("$", "CategoricalArrayVariable", 
    function (x, name) subvariables(x)[[name]])