#' Collapse an array from a CrunchCube by summing across dimensions to remove
#'
#' Typically when collapsing a crosstab you can just sum across the dimensions
#' that you want to collapse across. However, because we have array-type
#' questions/dimensions we have to be a little bit smarter. We cannot sum across
#' any subvariable dimension (dimension types ending with "_items") because that
#' would inflate the number of respondents by approximately the number of
#' subvariables. Instead, we take the mean across any "_items" dimension. In
#' principle, we could just take a single item or `unique` across the "_items"
#' dimensions, however due to floating point differences + rounding there are
#' minute differences that pop up, `mean` smooths over those tiny differences.
#'
#' `dimSums` returns a cube that retains the dimensions given in `margin` and
#' collapses all the others. This is useful if you want to get counts that are
#' equivalent to a univariate cube from a multivariate cube. For example
#' `dimSums(crtabs(~ fruit + pets, ds), 1)` will be equal to `crtabs(~ fruit,
#' ds)` and `dimSums(crtabs(~ fruit + pets, ds), 2)` will be equal to `crtabs(~
#' pets, ds)`.
#'
#' @param x the CrunchCube to collapse
#' @param margin the margins that should be summed within (in other words: the
#'   dimension that will be retained)
#'
#' @return a duly-collapsed CrunchCube
#' @keywords internal
#'
dimSums <- function(x, margin = NULL) {
    # ensure that we have sensible margin input
    selecteds <- is.selectedDimension(x@dims)
    check_margins(margin, selecteds)

    # ensure that the cube is a counts cube
    only_count_cube(x)

    # translate from user-cube margins to real-cube margins and establish the
    # two groups of margins: those to collapse and those to keep
    margins_to_keep <- user2realMargin(margin, cube = x)
    margins_to_collapse <- setdiff(seq_along(x@dims), margins_to_keep)

    # if there are any _items in the margin to collapse, be wary! Since there
    # are (likely) multiple items in the array, each row of the dataset would
    # have more than on item here. If we simply summed across them (like we do
    # with other measures below) then we would inflate the number of responses.
    collapsed_items <- endsWith(getDimTypes(x)[margins_to_collapse], "_items")

    # grab the old cube structure and over-write it with new subset data.
    out <- x

    # iterate through measures, collapsing the dimension(s) specified.
    out@arrays[] <- lapply(
        out@arrays,
        collapse_dims,
        margins_to_collapse = margins_to_collapse,
        collapsed_items = collapsed_items
    )

    # we needed to include the selected dim of MRs in off_margins above, but
    # when subsetting dimensions we definitely do not want them to be included.
    out@dims <- out@dims[margins_to_keep]

    return(out)
}


only_count_cube <- function(cube) {
    # ensure that the cube is a counts cube
    measure_types <- vapply(
        names(cube@arrays),
        function(measure) cubeMeasureType(cube, measure),
        character(1)
    )

    noncounts <- setdiff(measure_types, c("count", ".unweighted_counts"))
    if (length(noncounts) > 0) {
        msg <- c(
            "You can't use CrunchCubes with measures other than count. ",
            "The cube you provided included measures: ",
            serialPaste(sort(noncounts))
        )
        halt(msg)
    }
}

#' Collapse an array from a CrunchCube by summing
#'
#' This is an internal function that powers `dimSums()`
#'
#' @param array_in the array from a CrunchCube to collapse
#' @param margins_to_collapse the margins that should be collapsed
#' @param collapsed_items vector of logicals if any of the dimensions in
#'   `margins_to_collapse` are of the `_items` type
#'
#' @return a duly-collapsed array
#' @keywords internal
collapse_dims <- function(array_in,
                          margins_to_collapse,
                          collapsed_items) {
    # off_margins here are the margins that we want to keep, however because we
    # treat items dimensions differently, we need to add them to the
    # off_margins, and deal with them after we collapse by summing
    off_margins <- setdiff(seq_along(dim(array_in)), margins_to_collapse)

    # If there are any "_items" dimensions in margins_to_collapse, add them to
    # off_margins so that we can later mean across any items dimension
    items_to_collapse <- margins_to_collapse[collapsed_items]
    off_margins <- sort(c(off_margins, items_to_collapse))

    # collapse margins to collapse by runing the sumacross them
    array <- as.array(apply(array_in, off_margins, sum))

    # now, we need to get rid of the extra items dimensions that we want to
    # collapse across. We cannot simply sum across them because they
    # represent more than one observation per row; and we don't want to
    # double/triple/etc. count those observations. Instead we take the mean.
    # Another option would be to just take the unique value or first value
    # (since they should all be the same at this point given that they have
    # been collapsed above), however there are tiny differences due to
    # floating-point precision and weighting in the calculation in ZZ9.
    if (any(collapsed_items)) {
        # mean across any items dimension
        result_dim <- seq_along(dim(array))
        final_names <- dimnames(array)[which(!off_margins %in% items_to_collapse)]
        array <- as.array(apply(
            array,
            setdiff(result_dim, which(off_margins %in% items_to_collapse)),
            mean,
            na.rm = TRUE
        ))
        dimnames(array) <- final_names
    }

    # add attributes back
    attributes(array)$variable$type <- attributes(array_in)$variable$type
    attributes(array)$measure_type <- attributes(array_in)$measure_type

    return(array)
}
