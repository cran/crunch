#' @include transform.R
NULL

#' @rdname showTransforms
#' @export
setMethod("showTransforms", "CrunchCube", function(x) {
    if (all(vapply(transforms(x), is.null, logical(1)))) {
        print(cubeToArray(x))
        return(invisible(x))
    } else {
        appliedTrans <- applyTransforms(x)

        # evaluate which categories should be kept
        keep_cats <- evalUseNA(as.array(x), dimensions(x), useNA = x@useNA)

        # if the row dimension is categorical, make styles
        if (getDimTypes(x)[1] %in% c("categorical", "ca_categories")) {
            try({
                row_cats <- Categories(data = index(variables(x))[[1]]$categories)
                # subset the categories by those that evaleUseNA thinks we should keep:
                row_cats <- row_cats[which(keep_cats[[1]])]
                row_styles <- transformStyles(transforms(x)[[1]], row_cats)
            }, silent = TRUE)
        }
        # If row_styles doesn't exist, make it null
        if (!exists("row_styles")) {
            row_styles <- NULL
        }

        # if the columns dimension is categorical, make styles
        cat_dims <- c("categorical", "ca_categories")
        if (length(dim(x)) > 1 && getDimTypes(x)[2] %in% cat_dims) {
            try({
                col_cats <- Categories(data = index(variables(x))[[2]]$categories)
                # subset the categories by those that evaleUseNA thinks we should keep:
                col_cats <- col_cats[which(keep_cats[[2]])]
                col_styles <- transformStyles(transforms(x)[[2]], col_cats)
            }, silent = TRUE)
        }
        # If col_styles doesn't exist, make it null
        if (!exists("col_styles")) {
            col_styles <- NULL
        }


        if (length(dim(appliedTrans)) > 0 & length(dim(appliedTrans)) <= 2) {
            tryCatch({
                out <- prettyPrint2d(
                    appliedTrans,
                    row_styles = row_styles,
                    col_styles = col_styles
                )
                cat(unlist(out), sep = "\n")
            }, error = function(e) {
                # if prettyPrinting doesn't work, just print without prettiness
                print(appliedTrans)
            })
        } else {
            # styling is hard
            print(appliedTrans)
        }

        return(invisible(appliedTrans))
    }
})

#' @rdname applyTransforms
#' @export
setMethod("subtotalArray", "CrunchCube", function(x, headings = FALSE) {
    includes <- c("subtotals")
    if (headings) {
        includes <- c(includes, "headings")
    }
    applyTransforms(x, include = includes)
})

#' Calculate the transforms from a CrunchCube
#'
#' `applyTransforms` calculates transforms (e.g. [Subtotals][SubtotalsHeadings]) on a CrunchCube.
#' Currently only the row transforms are supported. This is useful if you want
#' to use the values from the subtotals of the CrunchCube in an analysis.
#'
#' Including the `include` argument allows you to specify which parts of the
#' CrunchCube to return. The options can be any of the following: "cube_cells"
#' for the untransformed values from the cube itself, "subtotals" for the
#' subtotal insertions, and "headings" for any additional headings. Any
#' combination of these can be given, by default all will be given.
#'
#' `subtotalArray(cube)` is a convenience function that is equivalent to
#' `applyTransforms(cube, include = c("subtotals"))`
#'
#' @param x a CrunchCube
#' @param array an array to use, if not using the default array from the cube
#' itself. (Default: not used, pulls an array from the cube directly)
#' @param transforms_list list of transforms to be applied (default:
#' `transforms(x)`)
#' @param dims_list list of dimensions that correspond to `array` (default:
#' `dimensions(x)`)
#' @param useNA `useNA` parameter from the CrunchCube to use (default:
#' `x@useNA`)
#' @param ... arguments to pass to `calcTransforms`, for example `include`
#' @param headings for `subtotalArray`: a logical indicating if the headings
#' should be included with the subtotals (default: `FALSE`)
#'
#' @return an array with any transformations applied
#'
#' @examples
#' \dontrun{
#' # to get an array of just the subtotals
#' subtotalArray(crtabs(~opinion, ds))
#' #    Agree Disagree
#' #       47       35
#'
#' # to get the full array with the subtotals but not headings
#' applyTransforms(crtabs(~opinion, ds), include = c("cube_cells", "subtotals"))
#' #             Strongly Agree             Somewhat Agree                      Agree
#' #                         23                         24                         47
#' # Neither Agree nor Disagree          Strongly Disagree                   Disagree
#' #                         18                         19                         35
#' #          Somewhat Disagree
#' #                         16
#' # to get the full array with the headings but not subtotals
#' applyTransforms(crtabs(~opinion, ds), include = c("cube_cells", "headings"))
#' #               All opinions             Strongly Agree             Somewhat Agree
#' #                         NA                         23                         24
#' # Neither Agree nor Disagree          Strongly Disagree          Somewhat Disagree
#' #                         18                         19                         16
#' }
#'
#' @aliases subtotalArray
#' @export
applyTransforms <- function(x,
                            array = cubeToArray(x),
                            transforms_list = transforms(x),
                            dims_list = dimensions(x),
                            useNA = x@useNA,
                            ...) {
    trans_indices <- which(vapply(transforms_list, Negate(is.null), logical(1)))

    if (!missing(x)) {
        # we don't need to try and transform ca_items!
        trans_indices <- trans_indices[getDimTypes(x)[trans_indices] != "ca_items"]
    }

    # evaluate which categories should be kept
    keep_cats <- evalUseNA(array, dims_list, useNA = useNA)

    # TODO: separate out the calculation of subtotals from others (like summary
    # stats) since a subtotal can have a mean, we need to calculate all
    # subtotals first and then calculate. Alternatively, change the process for
    # insertion function generation.

    # Try to calculate the transforms for any dimension that has them, but
    # fail silently if they aren't calculable We use a for loop so that failing
    # one dimension doesn't break others. We could possibly use something like
    # abind::abind here and bind together the insertion vectors in array form,
    # but that would add a dependency
    errors <- list()
    na_mask <- data.frame()
    for (d in trans_indices) {
        tryCatch({
            # if we have an mr or categorical array items, we skip quickly. We
            # include all _items here (including subvariable_items) here because
            # we might be getting a subset of dimensions and only have
            # subvariable_items without the corresponding dim to correctly
            # identify
            if (
                endsWith(getDimTypes(dims_list)[[d]], "_items") |
                    endsWith(getDimTypes(dims_list)[[d]], "_selections")
            ) {
                next
            }

            var_cats <- Categories(data = variables(dims_list)[[d]]$categories)

            # TODO: calculate category/element changes

            # make a list of insertion functions to be used when calculating
            # below
            insert_funcs <- makeInsertionFunctions(
                # only the kept categories must be passed
                var_cats[keep_cats[[d]]],
                transforms_list[[d]],
                cats_in_array = dimnames(array)[[d]],
                ...
            )

            # calculate the insertions, respecting the na_mask that is passeds
            array <- maskAndApplyInserts(array, na_mask, d, insert_funcs)

            # re-calculate the na_mask to include numbers that should be
            # censored from this transform going forward
            na_mask <- calculate_na_mask(array, na_mask, d, insert_funcs)
        },
        error = function(e) {
            assign("errors", append(errors, d), envir = parent.env(environment()))
        }
        )
    }

    if (length(errors) > 0) {
        warning(
            "Transforms for dimensions ", serialPaste(errors),
            " were malformed and have been ignored.",
            call. = FALSE
        )
    }

    # if there are any transforms, then we need to subset the output.
    array <- subsetTransformedCube(array, dims_list, useNA)

    return(array)
}

# mask the array before calculations so that no values are being calculated from
# those that they shouldn't be (for example, don't treat means as if they were
# actually counts and do weighted means of the means)
maskAndApplyInserts <- function(array, na_mask, d, insert_funcs) {
    # get the coordinates of in the array that must be masked and turn them into
    # NAs
    var_coord_cols <- startsWith(colnames(na_mask), "Var")
    array[as.matrix(na_mask[, var_coord_cols])] <- NA

    # do the actual transforms calculations for the dimension d
    array <- applyAgainst(
        X = array,
        MARGIN = d,
        FUN = calcTransforms,
        insert_funcs = insert_funcs,
        dim_names = names(insert_funcs)
    )

    # replace any values that had been masked with their previous values. We
    # only have to do this if the na_mask has anything in it, and it will break
    # if there's nothing in it
    insert_types <- attributes(insert_funcs)$types
    if (length(na_mask) > 0) {
        # we use the id_map to map from positions in just the categories to the
        # positions after things have been inserted.
        id_map <- which(insert_types == "Category")
        names(id_map) <- seq_along(id_map)
        na_mask[, d] <- id_map[na_mask[, d]]
        var_coord_cols <- startsWith(colnames(na_mask), "Var")
        if (!(all(is.na(array[as.matrix(na_mask[, var_coord_cols])])))) {
            halt("Trying to overwrite uncensored values something is wrong")
        }
        array[as.matrix(na_mask[, var_coord_cols])] <- na_mask$values
    }

    return(array)
}

# given an array, na_mask, and insertion functions calculate a new na_mask that
# adds which elements in dimension d must be masked before further calculation
calculate_na_mask <- function(array, na_mask, d, insert_funcs) {
    # Find the coordinates of the cells that must be masked (for now this is
    # just SummaryStats, but this should be any insertion that isn't allowed to
    # have insertions calcualted from it)
    ind_to_mask <- which(attributes(insert_funcs)$types == "SummaryStat")
    coords <- lapply(dim(array), function(to) seq_len(to))
    coords[[d]] <- ind_to_mask

    # add the new set of coordinates to the old na_mask since we iteratively
    # apply transforms
    na_mask_new <- expand.grid(coords)
    na_mask_new$values <- array[as.matrix(na_mask_new)]
    na_mask <- rbind(na_mask, na_mask_new)

    return(na_mask)
}

makeInsertionFunctions <- function(var_cats, transforms, cats_in_array = NULL, ...) {
    ### Insertions
    # collate insertions with categories for rearranging and calculation purposes
    # we need the categories to know what order the the cube cells should be in
    # and where to insert insertions (as they are `anchor`ed) to a category id.
    dots <- list(...)
    if ("include" %in% names(dots)) {
        includes <- dots$include
    } else {
        # defaults if none are given
        includes <- c("subtotals", "headings", "cube_cells", "other_insertions")
    }

    cat_insert_map <- mapInsertions(
        transforms$insertions,
        var_cats,
        include = includes
    )

    # generate the functions to use (this makes it much cheaper to vapply later)
    transforms_funcs <- makeTransFuncs(cat_insert_map, cats_in_array, var_cats)
    names(transforms_funcs) <- names(cat_insert_map)

    # determine the types based on the cat_insert_map to be used later
    types <- getInsertionTypes(cat_insert_map, cats_in_array)
    attributes(transforms_funcs)$types <- types

    # remove any NULLs above
    transforms_funcs <- Filter(Negate(is.null), transforms_funcs)
    attributes(transforms_funcs)$types <- types[!is.na(types)]

    return(transforms_funcs)
}

makeTransFuncs <- function(cat_insert_map, cats_in_array, var_cats) {
    # loop through the insertion map and make a function for each element in the
    # map (either insertion or category) we use base::lapply here because we
    # want to return a true list and not something of class AbstractCategories
    # (which is what would happen with normal dispatch)
    return(base::lapply(cat_insert_map, function(element) {
        # if element is a category, simply return the value
        if (is.category(element)) {
            if (!is.null(cats_in_array) && !name(element) %in% cats_in_array) {
                # if this category is in the cat_insert_map, but isn't in the
                # list of cats_in_array, we should return NULL which will be
                # removed later. This will prevent No Data categories from
                # failing when applying transforms to non-cube arrays that might
                # not have them
                return(NULL)
            }

            id <- which(ids(var_cats) %in% id(element))
            which.cat <- names(var_cats[id])
            return(function(vec) vec[[which.cat]])
        }

        # if element is a heading return NA (since there is no value to be
        # calculated but we need a placeholder non-number)
        if (is.Heading(element)) {
            return(function(vec) NA)
        }

        # if element is a subtotal, sum the things it corresponds to which are
        # found with arguments()
        if (is.Subtotal(element)) {
            # grab category combinations, and then sum the positive and subtract negative
            positive <- unlist(arguments(element, var_cats))
            positive_ids <- which(ids(var_cats) %in% positive)
            which.positive <- names(var_cats[positive_ids])

            negative <- unlist(subtotalTerms(element, var_cats)$negative) #nolint
            negative_ids <- which(ids(var_cats) %in% negative)
            which.negative <- names(var_cats[negative_ids])

            return(function(vec) {
                sum(vec[which.positive]) - sum(vec[which.negative])
            })
        }

        # if element is a summaryStat, grab the function from
        # summaryStatInsertions to use.
        if (is.SummaryStat(element)) {
            statFunc <- summaryStatInsertions[[func(element)]](element, var_cats)

            return(function(vec) statFunc(vec))
        }

        # finally, check if there are other functions, if there are warn, and
        # then return NA
        known_inserts <- c("subtotal", names(summaryStatInsertions))
        unknown_funcs <- !(element[["function"]] %in% known_inserts)
        if (unknown_funcs) {
            warning(
                "Transform functions other than subtotal are not supported.",
                " Applying only subtotals and ignoring ", element[["function"]]
            )
        }
        return(function(vec) NA)
    }))
}

getInsertionTypes <- function(cat_insert_map, cats_in_array) {
    return(vapply(cat_insert_map, function(element) {
        # if element is a category, simply return the value
        if (is.category(element)) {
            if (!is.null(cats_in_array) && !name(element) %in% cats_in_array) {
                return(NA_character_)
            }
            return("Category")
        }

        if (is.Heading(element)) {
            return("Heading")
        }

        if (is.Subtotal(element)) {
            return("Subtotal")
        }

        if (is.SummaryStat(element)) {
            return("SummaryStat")
        }

        known_inserts <- c("subtotal", names(summaryStatInsertions))
        unknown_funcs <- !(element[["function"]] %in% known_inserts)
        if (unknown_funcs) {
            return("Unknown")
        }
    }, character(1)))
}

#' apply a function against a dimension
#'
#' Similar to other `apply` functions, this takes an array and applies the
#' function against the  dimensions (specified in the `MARGIN` argument). These
#' dimensions must be a single number (unlike many `apply` functions). See the
#' examples below, where we use the function `add_one_hundred` to add `100` on
#' to the end of each `MARGIN`.
#'
#' `FUN` can be any function that takes a vector and returns a vector, but one
#' common use case is a function that adds new entries to the vector,
#' effectively expanding the array in the dimension given.
#'
#'
#' @param X an array
#' @param MARGIN the dimension to apply the function against
#' @param FUN the function to be applied
#' @param ... optional arguments to `FUN``
#'
#' @return an array with the function applied
#' @keywords internal
#'
#' @examples
#' array <- array(c(1:24), dim = c(4, 3, 2))
#' array
#' # , , 1
#' #
#' #      [,1] [,2] [,3]
#' # [1,]    1    5    9
#' # [2,]    2    6   10
#' # [3,]    3    7   11
#' # [4,]    4    8   12
#' #
#' # , , 2
#' #
#' #      [,1] [,2] [,3]
#' # [1,]   13   17   21
#' # [2,]   14   18   22
#' # [3,]   15   19   23
#' # [4,]   16   20   24
#'
#' add_one_hundred <- function(x) c(x, 100)
#'
#' crunch:::applyAgainst(array, 1, add_one_hundred)
#' # , , 1
#' #
#' #      [,1] [,2] [,3]
#' # [1,]    1    5    9
#' # [2,]    2    6   10
#' # [3,]    3    7   11
#' # [4,]    4    8   12
#' # [5,]  100  100  100
#' #
#' # , , 2
#' #
#' #      [,1] [,2] [,3]
#' # [1,]   13   17   21
#' # [2,]   14   18   22
#' # [3,]   15   19   23
#' # [4,]   16   20   24
#' # [5,]  100  100  100
#'
#' crunch:::applyAgainst(array, 2, add_one_hundred)
#' # , , 1
#' #
#' #      [,1] [,2] [,3] [,4]
#' # [1,]    1    5    9  100
#' # [2,]    2    6   10  100
#' # [3,]    3    7   11  100
#' # [4,]    4    8   12  100
#' #
#' # , , 2
#' #
#' #      [,1] [,2] [,3] [,4]
#' # [1,]   13   17   21  100
#' # [2,]   14   18   22  100
#' # [3,]   15   19   23  100
#' # [4,]   16   20   24  100
#'
#' crunch:::applyAgainst(array, 3, add_one_hundred)
#' # , , 1
#' #
#' #      [,1] [,2] [,3]
#' # [1,]    1    5    9
#' # [2,]    2    6   10
#' # [3,]    3    7   11
#' # [4,]    4    8   12
#' #
#' # , , 2
#' #
#' #      [,1] [,2] [,3]
#' # [1,]   13   17   21
#' # [2,]   14   18   22
#' # [3,]   15   19   23
#' # [4,]   16   20   24
#' #
#' # , , 3
#' #
#' #      [,1] [,2] [,3]
#' # [1,]  100  100  100
#' # [2,]  100  100  100
#' # [3,]  100  100  100
#' # [4,]  100  100  100
applyAgainst <- function(X, MARGIN, FUN, ...) {
    names_of_dims <- names(dimnames(X))
    ndims <- length(dim(X))

    # find the off-margins to calculate over
    if (ndims < 2) {
        # We only have one dimension to apply over, do so quickly without
        # futzing with off_margins, etc.
        return(as.array(FUN(X, ...)))
    }

    off_margins <- seq_along(dim(X))[-MARGIN]

    # calculate the FUN
    X <- apply(X, off_margins, FUN, ...)

    # aperm necesary because anything other than when off_margins is
    # not c(2), c(2,3), etc. will return in an incorrect order
    # microbenchmarking indicates that aperm is not particularly
    # expensive even on large arrays
    X <- aperm(X, append(2:ndims, 1, after = MARGIN - 1))

    # re-attach names
    names(dimnames(X)) <- names_of_dims

    return(X)
}

subsetTransformedCube <- function(array, dimensions, useNA) {
    # subset variable categories to only include non-na
    dims <- dim(array)
    if (is.null(dims)) {
        # if there are no dimensions, this isn't an array, just return the value
        return(array)
    }

    keep_all <- lapply(
        seq_along(dims),
        function(i) {
            out <- rep(TRUE, dims[i])
            names(out) <- dimnames(array)[[i]]
            return(out)
        }
    )
    names(keep_all) <- names(dimensions)[seq_along(keep_all)]
    keep_these_cube_dims <- evalUseNA(array, dimensions[seq_along(keep_all)], useNA)

    # remove the categories determined to be removable above
    keep_these <- mapply(function(x, y) {
        not_ys <- y[!y]
        x[names(not_ys)] <- not_ys
        return(x)
    }, keep_all,
    keep_these_cube_dims,
    SIMPLIFY = FALSE,
    USE.NAMES = TRUE
    )

    # match up those in keep_these that are already in array
    array_dimnames <- dimnames(array)
    for (i in seq_along(array_dimnames)) {
        to_keep <- names(keep_these[[i]]) %in% array_dimnames[[i]]
        keep_these[[i]] <- keep_these[[i]][to_keep]
    }

    array <- subsetCubeArray(array, keep_these)

    return(array)
}

#' @rdname Transforms
#' @export
setMethod("transforms", "CrunchCube", function(x) {
    transforms(variables(x))
})

#' @rdname Transforms
#' @export
setMethod("transforms", "VariableCatalog", function(x) {
    transes <- lapply(x, function(i) {
        i$view$transform
    })

    transes_out <- lapply(transes, function(i) {
        # TODO: when other transforms are implemented, this should check those too.

        # if insertions are null return NULL
        if (is.null(i$insertions) || length(i$insertions) == 0) {
            return(NULL)
        }

        # get the insertions
        inserts <- Insertions(data = i$insertions)
        # subtype insertions so that Subtotal, Heading, etc. are their rightful selves
        inserts <- subtypeInsertions(inserts)

        return(Transforms(
            insertions = inserts,
            categories = NULL,
            elements = NULL
        ))
    })

    names(transes_out) <- aliases(x)
    return(TransformsList(data = transes_out))
})

#' @rdname Transforms
#' @export
setMethod("transforms<-", c("CrunchCube", "ANY"), function(x, value) {
    if (!is.null(names(value))) {
        # check if the names of the dimensions and the transforms match
        validateNamesInDims(names(value), x, what = "transforms")

        transforms_list <- TransformsList(data = value)
        transforms(x)[names(value)] <- transforms_list
    } else {
        transforms(x) <- TransformsList(data = value)
    }

    return(invisible(x))
})

#' @rdname crunch-extract
#' @export
setMethod("[[<-", c("TransformsList", "ANY", "missing", "NULL"), function(x,
                                                                          i,
                                                                          j,
                                                                          value) {
    # if we remove a transform, we must set a Transform filled with NULLs and
    # not totally remove the item itself
    x[[i]] <- Transforms(insertions = NULL, elements = NULL, categories = NULL)
    return(x)
})

#' @rdname Transforms
#' @export
setMethod("transforms<-", c("CrunchCube", "TransformsList"), function(x, value) {
    dims <- dimensions(x)
    dimnames <- names(dims)
    stopifnot(length(value) == length(dims))

    # check if the names of the dimensions and the names of the transforms line up
    validateNamesInDims(names(value), x, what = "transforms")

    vars <- variables(x)
    # replace the transforms for each dimension
    dims <- CubeDims(mapply(function(dim, val, var) {
        if (!is.MR(var)) {
            var_items <- categories(var)
        } else {
            var_items <- subvariables(var)
        }
        val$insertions <- Insertions(
            data = lapply(val$insertions, makeInsertion, var_items = var_items, alias = alias(var))
        )
        dim$references$view$transform <- jsonprep(val)
        return(dim)
    }, dim = dims, val = value, var = vars, SIMPLIFY = FALSE))

    # replace names, replace the dimensions and return the cube
    names(dims) <- dimnames
    dimensions(x) <- dims
    return(invisible(x))
})

#' error iff the names are not a dimension in the cube provided
#'
#' @param names the names to check for in the cube
#' @param cube a CrunchCube object to check
#' @param what a character describing what is being checked (default: transforms
#' ) to include in the error to make it easier for users to see what is failing.
#'
#' @keywords internal
validateNamesInDims <- function(names, cube, what = "transforms") {
    dimnames <- names(dimensions(cube))

    # check if the names of the dimensions and the names of the transforms line up
    if (any(!(names %in% dimnames))) {
        halt(
            "The names of the ", what, " supplied (",
            serialPaste(dQuote(names)), ") do not match the dimensions of the cube (",
            serialPaste(dQuote(dimnames)), ")."
        )
    }
}


#' @rdname Transforms
#' @export
setMethod("transforms<-", c("CrunchCube", "NULL"), function(x, value) {
    dims <- dimensions(x)
    dimnames <- names(dims)
    dims <- CubeDims(lapply(dims, function(x) {
        if (!is.null(x$references$view$transform)) {
            x$references$view$transform <- value
        }
        return(x)
    }))
    names(dims) <- dimnames
    dimensions(x) <- dims
    return(invisible(x))
})

# TODO: add an easy way to append insertions, etc. to a cube's transforms

#' Remove transformations from a CrunchCube
#'
#' @section Removing transforms:
#' `noTransforms()` is useful if you don't want to see or use any transformations like
#' Subtotals and Headings. This action only applies to the CrunchCube object in
#' R: it doesn't actually change the variables on Crunch servers or the query
#' that generated the CrunchCube.
#'
#' @param cube a CrunchCube
#'
#' @return the CrunchCube with no transformations
#'
#' @examples
#' \dontrun{
#' # A CrunchCube with a heading and subtotals
#' crtabs(~opinion, ds)
#' #               All opinions
#' #             Strongly Agree 23
#' #             Somewhat Agree 24
#' #                      Agree 47
#' # Neither Agree nor Disagree 18
#' #          Somewhat Disagree 16
#' #          Strongly Disagree 19
#' #                   Disagree 35
#'
#' noTransforms(crtabs(~opinion, ds))
#' #             Strongly Agree             Somewhat Agree Neither Agree nor Disagree
#' #                         23                         24                         18
#' #          Somewhat Disagree          Strongly Disagree
#' #                         16                         19
#' }
#'
#' @export
noTransforms <- function(cube) {
    transforms(cube) <- NULL
    return(cube)
}
