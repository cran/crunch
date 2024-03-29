#' Summary insertions
#'
#' Just like `subtotals()`s, summary statistics can
#' be inserted into cubes. `SummaryStat()` makes an object of type `SummaryStat`
#' which can be added on to a CrunchCube's `insertions` to add the specified
#' summary statistic. Currently only `mean` and `median` are supported; both
#' use weighted algorithms to go from counts and numeric values of
#' categories to the expected statistic. Although `SummaryStat` objects can be
#' made by hand, it is recommended instead to use the `addSummaryStat()`
#' function which is much quicker and easier to simply add a summary
#' statistic to an existing CrunchCube.
#'
#' Summary statistics are intended only for CrunchCube objects, and are not able
#' to be set on Crunch variables.
#'
#' @inheritSection noTransforms Removing transforms
#'
#' @param name character the name of the summary statistic
#' @param stat a function to calculate the summary (e.g. `mean` or `median`)
#' @param categories character or numeric the category names or ids to be
#' included in the summary statistic, if empty all categories
#' @param position character one of "relative", "top", or "bottom". Determines
#' the position of the subtotal or heading, either at the top, bottom, or
#' relative to another category in the cube (default)
#' @param includeNA should missing categories be included in the summary?
#' @param after character or numeric if `position` is "relative", then the
#' category name or id to position the subtotal or heading after
#' @param before character or numeric if `position` is relative (and the
#' insertion type allows it - currently only MR subtotals).
#' @param x for `is.SummaryStat()` only, an object to test if
#' it is a `SummaryStat` object
#'
#' @name SummaryStat
NULL

#' @rdname SummaryStat
#' @export
SummaryStat <- function(name,
                        stat,
                        categories = NULL,
                        position = c("relative", "top", "bottom"),
                        after = NULL,
                        before = NULL,
                        includeNA = FALSE) {
    # match.args position
    position <- match.arg(position)
    validatePosition(position, after)

    if (!(stat %in% names(summaryStatInsertions))) {
        halt(
            dQuote(stat), " is not a known summary statistic for insertions. ",
            "Available stats are: ", serialPaste(names(summaryStatInsertions))
        )
    }

    return(new("SummaryStat", list(
        name = name,
        stat = stat,
        categories = categories,
        position = position,
        after = after,
        before = before,
        includeNA = includeNA
    )))
}

#' @importFrom stats weighted.mean
# a list of possible summary statistics to use as an insertion
meanInsert <- function(element, var_cats, includeNA = FALSE) {
    # grab category combinations, and then sum those categories.
    combos <- unlist(arguments(element, var_cats))
    which.cats <- names(var_cats[ids(var_cats) %in% combos])
    num_values <- values(var_cats[which.cats])

    return(function(vec) weighted.mean(num_values, vec, includeNA = includeNA))
}

medianInsert <- function(element, var_cats, vec, includeNA = FALSE) {
    # grab category combinations, and then sum those categories.
    combos <- unlist(arguments(element, var_cats))
    which.cats <- names(var_cats[ids(var_cats) %in% combos])
    # the num_values will be used in the function below, which confuses lintr
    num_values <- values(var_cats[which.cats]) # nolint

    return(function(vec) {
        counts <- vec

        # TODO: do something smarter about NA categories that have counts / have
        # numeric values if a user cares
        ok <- !is.na(counts)

        # weighted median function
        num_values <- num_values[ok]
        counts <- counts[ok]
        o <- order(num_values)
        num_values <- num_values[o]
        counts <- counts[o]
        perc <- cumsum(counts) / sum(counts)
        # if any of the bins are 0.5, return the mean of that and the one above it.
        if (any(!is.na(perc) & perc == 0.5)) {
            n <- which(perc == 0.5)
            return((num_values[n] + num_values[n + 1]) / 2)
        }

        # otherwise return the first bin that is more than 50%
        over0.5 <- which(perc > 0.5)
        if (length(over0.5 > 0)) {
            out <- num_values[min(over0.5)]
        } else {
            out <- NA
        }
        return(out)
    })
}

summaryStatInsertions <- list(
    "mean" = meanInsert,
    "median" = medianInsert
)

#' @rdname SummaryStat
#' @export
is.SummaryStat <- function(x) inherits(x, "SummaryStat") %||% FALSE

#' @rdname SummaryStat
#' @export
are.SummaryStats <- function(x) unlist(lapply(x, inherits, "SummaryStat")) %||% FALSE

setMethod("initialize", "SummaryStat", function(.Object, ...) {
    .Object <- callNextMethod()
    # unlist, to flatten user inputs like list(1:2)
    .Object$categories <- unlist(.Object$categories)
    return(.Object)
})

#' @rdname makeInsertion
#' @export
setMethod("makeInsertion", "SummaryStat", function(x, var_items, alias) {
    if (is.null(arguments(x))) {
        # if there are no arguments, use all category ids
        args <- ids(var_items)
    } else {
        args <- arguments(x, var_items)
    }

    return(.Insertion(
        anchor = anchor(x, var_items),
        name = name(x),
        `function` = x$stat,
        args = arguments(x, var_items),
        includeNA = x$includeNA
    ))
})


#' Add summary statistics to a CrunchCube
#'
#' Use `addSummaryStat()` to add a summary statistic to a CrunchCube object. If
#' not otherwise specified, the summary statistic will be `mean` and be placed
#' at the bottom of the cube. You can change those defaults by passing any value
#' you can use with `SummaryStat()` (e.g. `position`, `categories`, `after`).
#'
#' @param cube a CrunchCube to add stats to
#' @param stat a character with the summary statistic to include (default: "mean")
#' @param var a character with the name of the dimension variable to add the
#' summary statistic for generally the alias of the variable in Crunch, but
#' might include Crunch functions like `rollup()`, `bin()`, etc.
#' @param margin which margin should the summary statistic be applied for (used
#' in the cases of categorical arrays where a variable might contribute more
#' than one margin)
#' @param ... options to pass to `SummaryStat()` (e.g., position, after, etc.)
#'
#' @return a CrunchCube with the summary statistic Insertion added to the
#' transforms of the variable specified
#'
#' @seealso SummaryStat
#'
#' @examples
#' \dontrun{
#' pet_feelings
#' #                   animals
#' # feelings            cats dogs
#' #  extremely happy      9    5
#' #  somewhat happy      12   12
#' #  neutral             12    7
#' #  somewhat unhappy    10   10
#' #  extremely unhappy   11   12
#'
#' # add a mean summary statistic to a CrunchCube
#' addSummaryStat(pet_feelings, stat = "mean", var = "feelings")
#' #                 animals
#' # feelings                      cats             dogs
#' #  extremely happy                9                5
#' #   somewhat happy               12               12
#' #          neutral               12                7
#' # somewhat unhappy               10               10
#' # extremely unhappy               11               12
#' #             mean 4.90740740740741 4.34782608695652
#'
#' # we can also store the CrunchCube for use elsewhere
#' pet_feelings <- addSummaryStat(pet_feelings, stat = "mean", var = "feelings")
#' pet_feelings
#' #                 animals
#' # feelings                      cats             dogs
#' #  extremely happy                9                5
#' #   somewhat happy               12               12
#' #          neutral               12                7
#' # somewhat unhappy               10               10
#' # extremely unhappy               11               12
#' #             mean 4.90740740740741 4.34782608695652
#'
#' # `addSummaryStat` returns a CrunchCube that has had the summary statistic
#' # added to it, so that you can still use the Crunch logic for multiple
#' # response variables, missingness, etc.
#' class(pet_feelings)
#' # [1] "CrunchCube"
#' # attr(,"package")
#' # [1] "crunch"
#'
#' # Since `pet_feelings` is a CrunchCube, although it has similar properties
#' # and behaviors to arrays, it is not a R array:
#' is.array(pet_feelings)
#' # [1] FALSE
#'
#' # cleanup transforms
#' transforms(pet_feelings) <- NULL
#' # add a median summary statistic to a CrunchCube
#' pet_feelings <- addSummaryStat(pet_feelings, stat = "median", var = "feelings")
#' pet_feelings
#' #                 animals
#' # feelings             cats    dogs
#' #  extremely happy       9       5
#' #   somewhat happy      12      12
#' #          neutral      12       7
#' # somewhat unhappy      10      10
#' # extremely unhappy      11      12
#' #           median       5       5
#'
#' # additionally, if you want a true matrix object from the CrunchCube, rather
#' # than the CrunchCube object itself, `applyTransforms()` will return the
#' # array with the summary statistics (just like subtotals and headings)
#' pet_feelings_array <- applyTransforms(pet_feelings)
#' pet_feelings_array
#' #                 animals
#' # feelings             cats    dogs
#' #  extremely happy       9       5
#' #   somewhat happy      12      12
#' #          neutral      12       7
#' # somewhat unhappy      10      10
#' # extremely unhappy      11      12
#' #           median       5       5
#'
#' # and we can see that this is an array and no longer a CrunchCube
#' is.array(pet_feelings_array)
#' # [1] TRUE
#' }
#'
#' @export
addSummaryStat <- function(cube, stat = c("mean", "median"), var, margin, ...) {
    stat <- match.arg(stat)

    if (!missing(var)) {
        validateNamesInDims(var, cube, what = "variables")
        margin <- which(names(cube) %in% var)
    } else if (!missing(margin)) {
        # TODO: use check_margin() when index-redux is mergedin
        if (any(margin > length(dim(cube)))) {
            halt(
                "Margin ", max(margin),
                " exceeds Cube's number of dimensions (",
                length(dim(cube)), ")"
            )
        }
    } else {
        halt("Must supply either a `margin` or `var` argument.")
    }

    # setup default options
    opts <- list(..., stat = stat)
    # no name? default to stat
    if (is.null(opts$name)) opts$name <- stat
    # after and position? default to bottom
    if (is.null(opts$after) & is.null(opts$position)) opts$position <- "bottom"

    summary_stat <- do.call(SummaryStat, opts)

    for (one_margin in margin) {
        if (is.null(transforms(cube)[[one_margin]])) {
            transes <- Transforms(insertions = Insertions(summary_stat))
            transforms(cube)[[one_margin]] <- transes
        } else {
            inserts <- append(
                transforms(cube)[[one_margin]]$insertions,
                list(summary_stat)
            )
            transforms(cube)[[one_margin]]$insertions <- inserts
        }
    }

    return(cube)
}
