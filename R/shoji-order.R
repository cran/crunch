setMethod("initialize", "ShojiOrder", function(.Object, ..., catalog_url = "") {
    .Object <- callNextMethod(.Object, ...)
    dots <- list(...)
    ents <- entitiesInitializer(.Object)
    if (length(dots) && !is.shoji(dots[[1]])) {
        .Object@graph <- ents(dots, url.base = NULL)
    } else {
        .Object@graph <- ents(.Object@graph, url.base = .Object@self)
    }
    .Object@catalog_url <- catalog_url
    return(.Object)
})

setMethod("initialize", "OrderGroup", function(.Object, group, entities,
                                               url.base = NULL, ...) {
    dots <- list(...)
    ents <- entitiesInitializer(.Object)
    if ("variables" %in% names(dots)) entities <- dots$variables
    if ("name" %in% names(dots)) group <- dots$name
    .Object@group <- group
    .Object@entities <- ents(entities, url.base)
    return(.Object)
})

setMethod("groupClass", "ShojiOrder", function(x) "OrderGroup")
setMethod("groupClass", "OrderGroup", function(x) "OrderGroup")
setMethod("entityClass", "ShojiOrder", function(x) "ShojiObject")
setMethod("entityClass", "OrderGroup", function(x) "ShojiObject")

.initEntities <- function(x, url.base = NULL, group.class = "OrderGroup",
                          entity.class = "ShojiObject") {
    ## Sanitize the inputs in OrderGroup construction/updating
    ## Result should be a list, each element being either a URL (character)
    ## or OrderGroup

    ## Valid inputs:
    ## 1) A catalog: take all urls
    ## 2) A character vector of urls
    ## 3) A list of
    ## a) entities: take self
    ## b) mixed character and OrderGroups
    ## c) mixed character and lists that should be OrderGroups (from JSON)
    if (is.catalog(x)) {
        return(.initEntities(urls(x), url.base = url.base))
    }
    if (is.character(x)) {
        return(.initEntities(as.list(x), url.base = url.base))
    }
    if (is.list(x)) {
        ## Init raw (fromJSON) groups, which have lists inside of lists
        raw.groups <- vapply(x, is.list, logical(1))
        x[raw.groups] <- lapply(
            x[raw.groups],
            function(a) do.call(
                    group.class,
                    list(group = names(a), entities = a[[1]], url.base = url.base)
                )
        )

        ## Get self if any are entities
        vars <- vapply(x, inherits, logical(1), what = entity.class)
        x[vars] <- lapply(x[vars], self)

        ## Now everything should be valid
        nested.groups <- vapply(
            x,
            function(a) inherits(a, group.class),
            logical(1)
        )
        string.urls <- vapply(
            x,
            function(a) is.character(a) && length(a) == 1,
            logical(1)
        )
        stopifnot(all(string.urls | nested.groups))

        ## Absolutize if needed
        if (!is.null(url.base)) {
            x[string.urls] <- lapply(x[string.urls], absoluteURL,
                base = url.base
            )
        }
        ## Make sure there are no names on the list--will throw off toJSON
        names(x) <- NULL
        return(x)
    }
    halt(class(x), " is an invalid input for entities")
}

orderEntitiesInit <- function(x) {
    gc <- groupClass(x)
    ec <- entityClass(x)
    return(function(entities, ...) {
        return(.initEntities(entities, ..., group.class = gc, entity.class = ec))
    })
}

setMethod("entitiesInitializer", "ShojiOrder", orderEntitiesInit)
setMethod("entitiesInitializer", "OrderGroup", orderEntitiesInit)

.setNestedGroupByName <- function(x, i, j, value) {
    grp <- groupClass(x)
    if (!inherits(value, "OrderGroup")) {
        ents <- entitiesInitializer(x)
        value <- ents(value)
    }

    ## Pull out the ones we're moving
    x <- setdiff_entities(x, value)

    i <- parseFolderPath(i)
    if (nchar(i[1]) == 0) {
        ## Means the path starts with "/", so we're going to start at the top
        ## level. And since this is a ShojiOrder, we're already at the top level
        ## so just pop the segment off
        i <- i[-1]
    }
    fun <- function(ord, path, val) {
        ## Recursive function for internal use
        if (!(path[1] %in% names(ord))) {
            ## Create an empty folder
            entities(ord) <- c(
                entities(ord), do.call(grp, list(name = path[1], entities = val))
            )
        } else if (length(path) == 1) {
            w <- match(path[1], names(ord))
            if (inherits(val, "OrderGroup")) {
                entities(ord[[w]]) <- entities(val)
            } else {
                entities(ord[[w]]) <- val
            }
        }
        if (length(path) > 1) {
            ## Recurse.
            ord[[match(path[1], names(ord))]] <- fun(ord[[path[1]]], path[-1], val)
        }
        return(ord)
    }
    if (length(i)) {
        x <- fun(x, i, value)
    } else {
        ## Moving to root level
        entities(x) <- value
    }

    return(removeMissingEntities(x))
}

#' @export
as.list.ShojiOrder <- function(x, ...) x@graph

#' @export
as.list.OrderGroup <- function(x, ...) x@entities

###############################
# 1. Extract from ShojiOrder
###############################

#' @rdname crunch-extract
#' @export
setMethod("[", c("ShojiOrder", "ANY"), function(x, i, ..., drop = FALSE) {
    x@graph <- x@graph[i]
    return(x)
})
#' @rdname crunch-extract
#' @export
setMethod("[", c("ShojiOrder", "character"), function(x, i, ..., drop = FALSE) {
    w <- match(i, names(x))
    if (any(is.na(w))) {
        halt("Undefined groups selected: ", serialPaste(i[is.na(w)]))
    }
    callNextMethod(x, w, ..., drop = drop)
})

#' @rdname crunch-extract
#' @export
setMethod("[[", c("ShojiOrder", "ANY"), function(x, i, ...) {
    x@graph[[i]]
})

#' @rdname crunch-extract
#' @export
setMethod("[[", c("ShojiOrder", "character"), function(x, i, ...) {
    ## i may be a path string, so split on the delimiter (default is "/")
    i <- parseFolderPath(i)
    if (nchar(i[1]) == 0) {
        ## Means the path starts with "/", so we're going to start at the top
        ## level. And since this is a ShojiOrder, we're already at the top level
        ## so just pop the segment off
        i <- i[-1]
    }
    for (segment in i) {
        ## since i may be a path vector, iterate over it
        x <- x[[match(segment, names(x))]]
    }
    return(x)
})

#' @rdname crunch-extract
#' @export
setMethod("$", "ShojiOrder", function(x, name) x[[name]])

###############################
# 2. Assign into ShojiOrder
###############################

#' @rdname crunch-extract
#' @export
setMethod(
    "[<-", c("ShojiOrder", "character", "missing", "ShojiOrder"),
    function(x, i, j, value) {
        stopifnot(class(x) == class(value)) ## So we don't cross subclasses
        w <- match(i, names(x))
        if (any(is.na(w))) {
            halt("Undefined groups selected: ", serialPaste(i[is.na(w)]))
        }
        callNextMethod(x, w, value = value)
    }
)
#' @rdname crunch-extract
#' @export
setMethod(
    "[<-", c("ShojiOrder", "ANY", "missing", "ShojiOrder"),
    function(x, i, j, value) {
        stopifnot(class(x) == class(value)) ## So we don't cross subclasses
        x@graph[i] <- value@graph
        return(x)
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "character", "missing", "list"),
    .setNestedGroupByName
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "character", "missing", "character"),
    .setNestedGroupByName
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "character", "missing", "OrderGroup"),
    .setNestedGroupByName
)


#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "ANY", "missing", "OrderGroup"),
    function(x, i, j, value) {
        if (length(entities(value))) {
            x <- setdiff_entities(x, value)
        }
        x@graph[[i]] <- value
        return(removeMissingEntities(x))
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "ANY", "missing", "ANY"),
    function(x, i, j, value) {
        halt(
            "Cannot assign an object of class ", dQuote(class(value)),
            " into a ", class(x)
        )
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "ANY", "missing", "NULL"),
    function(x, i, j, value) {
        x@graph[[i]] <- value
        return(x)
    }
)
#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "character", "missing", "NULL"),
    function(x, i, j, value) {
        w <- match(i, names(x))
        if (any(is.na(w))) {
            halt("Undefined group selected: ", serialPaste(i[is.na(w)]))
        }
        callNextMethod(x, w, value = value)
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("ShojiOrder", "character", "missing", "ShojiOrder"),
    function(x, i, j, value) {
        .setNestedGroupByName(x, i, j, entities(value))
    }
)

#' @rdname crunch-extract
#' @export
setMethod("$<-", "ShojiOrder", function(x, name, value) {
    x[[name]] <- value
    return(x)
})


###############################
# 3. Extract from OrderGroup
###############################

#' @rdname crunch-extract
#' @export
setMethod("[", c("OrderGroup", "ANY"), function(x, i, ..., drop = FALSE) {
    x@entities <- x@entities[i]
    return(x)
})
#' @rdname crunch-extract
#' @export
setMethod("[", c("OrderGroup", "character"), function(x, i, ..., drop = FALSE) {
    w <- match(i, names(x))
    if (any(is.na(w))) {
        halt("Undefined groups selected: ", serialPaste(i[is.na(w)]))
    }
    callNextMethod(x, w, ..., drop = drop)
})

#' @rdname crunch-extract
#' @export
setMethod("[[", c("OrderGroup", "character"), function(x, i, ...) {
    w <- match(i, names(x))
    if (any(is.na(w))) {
        halt("Undefined groups selected: ", serialPaste(i[is.na(w)]))
    }
    callNextMethod(x, w, ..., drop = drop)
})

#' @rdname crunch-extract
#' @export
setMethod("[[", c("OrderGroup", "ANY"), function(x, i, ...) {
    x@entities[[i]]
})

#' @rdname crunch-extract
#' @export
setMethod("$", "OrderGroup", function(x, name) x[[name]])

###############################
# 4. Assign into ShojiGroup
###############################

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "character", "missing", "list"),
    .setNestedGroupByName
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "character", "missing", "character"),
    .setNestedGroupByName
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "character", "missing", "ShojiOrder"),
    function(x, i, j, value) {
        .setNestedGroupByName(x, i, j, entities(value))
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "character", "missing", "OrderGroup"),
    function(x, i, j, value) {
        .setNestedGroupByName(x, i, j, entities(value))
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "ANY", "missing", "OrderGroup"),
    function(x, i, j, value) {
        stopifnot(class(x) == class(value)) ## So we don't cross subclasses
        entities(x)[[i]] <- value
        return(x)
    }
)

#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "numeric", "missing", "NULL"),
    function(x, i, j, value) {
        if (length(i) > 1 || i < 0) {
            halt("Illegal subscript")
        }
        entities(x) <- entities(x)[-i]
        return(x)
    }
)
#' @rdname crunch-extract
#' @export
setMethod(
    "[[<-", c("OrderGroup", "character", "missing", "NULL"),
    function(x, i, j, value) {
        w <- match(i, names(x))
        if (any(is.na(w))) {
            halt("Undefined group selected: ", serialPaste(i[is.na(w)]))
        }
        callNextMethod(x, w, value = value)
    }
)

#' @rdname crunch-extract
#' @export
setMethod("$<-", "OrderGroup", function(x, name, value) {
    x[[name]] <- value
    return(x)
})

setdiff_entities <- function(x, ents, remove.na = FALSE) {
    ## Remove "ents" (entity references) anywhere they appear in x (Order)
    if (!length(ents)) {
        ## It's empty, so nothing to setdiff
        return(x)
    }
    if (!is.character(ents)) {
        ## Get just the entity URLs
        ents <- entities(ents, simplify = TRUE)
    }

    if (inherits(x, "ShojiOrder") || inherits(x, "OrderGroup")) {
        entities(x) <- setdiff_entities(entities(x), ents)
    } else if (is.list(x)) {
        ## We're inside entities, which may have nested groups
        grps <- vapply(x, inherits, logical(1), what = "OrderGroup")
        x[grps] <- lapply(x[grps], setdiff_entities, ents)
        matches <- unlist(x[!grps]) %in% ents
        if (any(matches)) {
            ## Put in NAs so that any subsequent assignment into this object
            ## assigns into the right position. Then strip NAs after
            x[!grps][matches] <- rep(list(NA_character_), sum(matches))
        }
    }
    if (remove.na) {
        x <- removeMissingEntities(x)
    }
    return(x)
}

removeMissingEntities <- function(x) {
    ## Remove NA entries, left by setdiff_entities, from @graph/entities
    if (inherits(x, "ShojiOrder") || inherits(x, "OrderGroup")) {
        entities(x) <- removeMissingEntities(entities(x))
    } else if (is.list(x)) {
        ## We're inside entities, which may have nested groups
        grps <- vapply(x, inherits, logical(1), what = "OrderGroup")
        x[grps] <- lapply(x[grps], removeMissingEntities)
        drops <- vapply(x[!grps], is.na, logical(1))
        if (any(drops)) {
            x <- x[-which(!grps)[drops]]
        }
    }
    return(x)
}

#' Remove OrderGroups with no entities
#'
#' This function recurses through a \code{ShojiOrder}/\code{OrderGroup} and
#' removes any groups that contain no entities.
#'
#' @param x VariableOrder, DatasetOrder, VariableGroup, or DatasetGroup
#' @return \code{x} with empty groups removed.
#' @export
#' @keywords internal
removeEmptyGroups <- function(x) {
    if (inherits(x, "ShojiOrder") || inherits(x, "OrderGroup")) {
        entities(x) <- removeEmptyGroups(entities(x))
    } else if (is.list(x)) {
        ## We're inside entities, which may have nested groups
        grps <- vapply(x, inherits, logical(1), what = "OrderGroup")
        if (any(grps)) {
            empties <- vapply(
                x[grps], function(g) length(urls(g)) == 0,
                logical(1)
            )
            ## Recurse through non-empty groups
            if (any(!empties)) {
                nonempty <- which(grps)[!empties]
                x[nonempty] <- lapply(x[nonempty], removeEmptyGroups)
            }
            ## Drop empty groups
            if (any(empties)) {
                x <- x[-which(grps)[empties]]
            }
        }
    }
    return(x)
}

#' Remove nesting of groups within an order/group
#'
#' This function reduces a potentially nested order to its flattened
#' representation, containing no nested groups. Entities are ordered in the
#' result by their first appearance in the order object.
#'
#' @param x VariableOrder, DatasetOrder, VariableGroup, or DatasetGroup; or a
#' CrunchDataset or catalog that has an `ordering` property.
#' @return `x`, or its order resource, flattened.
#' @export
#' @keywords internal
flattenOrder <- function(x) {
    if (!(inherits(x, "ShojiOrder") || inherits(x, "OrderGroup"))) {
        ## Perhaps it's a dataset or catalog. Get its "ordering"
        x <- ordering(x)
    }
    entities(x) <- urls(x)
    return(x)
}

#' Get grouped or ungrouped OrderGroups
#'
#' "ungrouped" is an OrderGroup that contains all entities not found
#' in groups at a given level of nesting.
#' @param order.obj an subclass of ShojiOrder or OrderGroup
#' @return For `grouped()`, an Order/Group, respectively, with "ungrouped"
#' omitted. For `ungrouped()`, an OrderGroup subclass.
#' @seealso [`VariableOrder`]
#' @export
#' @keywords internal
grouped <- function(order.obj) {
    # TODO: deprecate and suggest a folder method
    Filter(Negate(is.character), order.obj)
}

#' @rdname grouped
#' @export
ungrouped <- function(order.obj) {
    # TODO: deprecate and suggest a folder method
    return(do.call(groupClass(order.obj), list(
        name = "ungrouped",
        entities = entities(Filter(is.character, order.obj))
    )))
}
