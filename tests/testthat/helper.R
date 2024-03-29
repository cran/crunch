Sys.setlocale("LC_COLLATE", "C") ## What CRAN does
set.seed(666)

"%>%" <- magrittr::`%>%`

skip_on_jenkins <- function(...) {
    if (nchar(Sys.getenv("JENKINS_HOME"))) {
        skip(...) # nolint
    }
}

fromJSON <- jsonlite::fromJSON
loadLogfile <- httpcache::loadLogfile
cacheLogSummary <- httpcache::cacheLogSummary
requestLogSummary <- httpcache::requestLogSummary
uncached <- httpcache::uncached

## .onAttach stuff, for testthat to work right
## See other options in inst/crunch-test.R
crunch:::set_crunch_opts(
    crunch.debug = FALSE,
    crunch.timeout = 20, ## In case an import fails to start, don't wait forever
    crunch.require.confirmation = TRUE,
    crunch.check.updates = FALSE,
    crunch.namekey.dataset = "alias",
    crunch.namekey.array = "alias",
    crunch.already.shown.folders.msg = TRUE,
    crunch.names.includes.hidden.private.variables = FALSE
)

options(
    digits.secs = 3,
    # httpcache.log="",
    # crayon options for testing on travis
    crayon.enabled = TRUE,
    crayon.colors = 256
)
crunch:::.onLoad()

## Test serialize and deserialize
cereal <- function(x) fromJSON(toJSON(x), simplifyVector = FALSE)


datasetFixturePath <- function(filename) {
    # Try in mocks tempdir
    path <- file.path(tempdir(), "mocks/dataset-fixtures", filename)
    if (file.exists(path)) return(path)

    # Next check if we're in tests folder
    path <- file.path("../mocks/dataset-fixtures", filename)
    if (file.exists(path)) return(path)

    # Finally if we're in package home
    path <- file.path("mocks/dataset-fixtures", filename)
    if (file.exists(path)) return(path)

    halt("Could not find ", filename)
}

newDatasetFromFixture <- function(filename) {
    if (filename == "apidocs") {
        ## This one has been moved into the package and renamed
        return(suppressMessages(newExampleDataset("pets")))
    }

    ## Grab csv and json from "dataset-fixtures" and make a dataset
    m <- fromJSON(datasetFixturePath(paste0(filename, ".json")),
        simplifyVector = FALSE
    )
    return(suppressMessages(createWithMetadataAndFile(
        m,
        datasetFixturePath(paste0(filename, ".csv"))
    )))
}

## Data frames to make datasets with
df <- data.frame(
    v1 = c(rep(NA_real_, 5), rnorm(15)),
    v2 = c(letters[1:15], rep(NA_character_, 5)),
    v3 = 8:27,
    v4 = as.factor(LETTERS[2:3]),
    v5 = as.Date(0:19, origin = "1955-11-05"),
    v6 = TRUE,
    stringsAsFactors = FALSE
)

mrdf <- data.frame(
    mr_1 = c(1, 0, 1, NA_real_),
    mr_2 = c(0, 0, 1, NA_real_),
    mr_3 = c(0, 0, 1, NA_real_),
    v4 = as.factor(LETTERS[2:3]),
    stringsAsFactors = FALSE
)

mrdf.setup <- function(dataset, pattern = "mr_", name = ifelse(is.null(selections),
                           "CA", "MR"
                       ), selections = NULL) {
    cast.these <- grep(pattern, names(dataset))
    dataset[cast.these] <- lapply(
        dataset[cast.these],
        castVariable, "categorical"
    )
    if (is.null(selections)) {
        dataset[[name]] <- makeArray(dataset[cast.these], name = name)
    } else {
        dataset[[name]] <- makeMR(dataset[cast.these],
            name = name,
            selections = selections
        )
    }
    return(dataset)
}
