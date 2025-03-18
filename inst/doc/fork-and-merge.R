## ----eval = FALSE, message=FALSE--------------------------------------------------------------------------------------
# library(crunch)

## ----results='hide', echo=FALSE, message=FALSE------------------------------------------------------------------------
library(crunch)
set_crunch_opts("crunch.api" = "https://team.crunch.io/api/")
library(httptest)
run_cleanup <- !dir.exists("fork-and-merge")
ds_to_delete <- c()
httpcache::clearCache()
start_vignette("fork-and-merge")


# The usual redactor does not work, because the end of the UUIDs for variables
# are stable between datasets (the first variable ends with "000000")
# and so we have a clash when using variables from merged dataests
# So this redactor should be the same as the other except for the variable UUID handling
# (For context, we have to redact so we don't get paths that are too long to subtmit to CRAN)
#
# Eventually this should probably be the default, but it only really affects
# this vignette and I don't feel like fixing everything (other vignettes, as well as crplyr?)
set_redactor(function(response) {
    ## Remove multipart form fields because POST sources/ sends a tmpfile path
    ## that's different every time, so the request will never match.
    response$request$fields <- NULL
    response %>%
        redact_auth() %>%
        gsub_response("([0-9a-f]{6})[0-9a-f]{26}", "\\1") %>% ## Prune UUIDs
        httptest::gsub_response("([0-9A-Za-z]{4})[0-9A-Za-z]{18}[0-9]{4}([0-9]{2})", "\\1\\2") %>% # UUIDs in variables now too
        gsub_response(
            "https.//(app|team).crunch.io/api/progress/[^\"].*?/",
            "https://\\1.crunch.io/api/progress/"
        ) %>% ## Progress is meaningless in mocks
        gsub_response("https.//(app|team).crunch.io", "") %>% ## Shorten URL
        gsub_response("https%3A%2F%2F(app|team).crunch.io", "") ## Shorten encoded URL
})
set_requester(function(request) {
    request$fields <- NULL
    request %>%
        gsub_request("https.//(app|team).crunch.io", "") ## Shorten URL
})

## ----message=FALSE, results='hide'------------------------------------------------------------------------------------
my_project <- newProject("examples/rcrunch vignette data")
ds <- newDataset(SO_survey, "stackoverflow_survey", project = my_project)

## ----forcevarcat1, include=FALSE--------------------------------------------------------------------------------------
# Force catalog so that catalog is loaded at a consistent time
ds <- forceVariableCatalog(ds)
ds_to_delete[length(ds_to_delete) + 1] <- self(ds)

## ----fork dataset-----------------------------------------------------------------------------------------------------
forked_ds <- forkDataset(ds, project = "examples/rcrunch vignette data")

## ----forcevarcat2, include=FALSE--------------------------------------------------------------------------------------
# Force catalog so that catalog is loaded at a consistent time
forked_ds <- forceVariableCatalog(forked_ds)
ds_to_delete[length(ds_to_delete) + 1] <- self(forked_ds)

## ----state change1, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----create Multiple Response Variable--------------------------------------------------------------------------------
forked_ds$ImportantHiringCA <- makeArray(forked_ds[, c("ImportantHiringTechExp", "ImportantHiringPMExp")],
    name = "importantCatArray")

## ----forcevarcat3, include=FALSE--------------------------------------------------------------------------------------
# Force catalog so that catalog is loaded at a consistent time
forked_ds <- forceVariableCatalog(forked_ds)

## ----compare datasets-------------------------------------------------------------------------------------------------
all.equal(names(forked_ds), names(ds))

## ----state change2, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----merging----------------------------------------------------------------------------------------------------------
ds <- mergeFork(ds, forked_ds)

## ----check successful merge-------------------------------------------------------------------------------------------
ds$ImportantHiringCA

## ----state change3, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----upload wave 2, message=FALSE, results='hide'---------------------------------------------------------------------
wave2 <- newDataset(SO_survey, "SO_survey_wave2", project = my_project)

## ----state change4, include=FALSE-------------------------------------------------------------------------------------
change_state()
ds_to_delete[length(ds_to_delete) + 1] <- self(wave2)

## ----fork-and-append, results='hide'----------------------------------------------------------------------------------
ds_fork <- forkDataset(ds, project = "examples/rcrunch vignette data")
ds_fork <- appendDataset(ds_fork, wave2)

## ---------------------------------------------------------------------------------------------------------------------
nrow(ds)
nrow(ds_fork)

## ----state change5, include=FALSE-------------------------------------------------------------------------------------
change_state()
ds_to_delete[length(ds_to_delete) + 1] <- self(ds_fork)

## ---------------------------------------------------------------------------------------------------------------------
ds <- mergeFork(ds, ds_fork)

## ---------------------------------------------------------------------------------------------------------------------
nrow(ds)

## ----state change6, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----create recode data, message=FALSE, results='hide'----------------------------------------------------------------
house_table <- data.frame(Respondent = unique(as.vector(ds$Respondent)))
house_table$HouseholdSize <- sample(
    1:5,
    nrow(house_table),
    TRUE
)
house_ds <- newDataset(house_table, "House Size", project = my_project)

## ----fork and merge recode, message=FALSE, results='hide'-------------------------------------------------------------
ds_fork <- forkDataset(ds, project = "examples/rcrunch vignette data")
ds_fork <- merge(ds_fork, house_ds, by = "Respondent")

## ----state change7, include=FALSE-------------------------------------------------------------------------------------
change_state()
ds_to_delete[length(ds_to_delete) + 1] <- self(house_ds)
ds_to_delete[length(ds_to_delete) + 1] <- self(ds_fork)

## ----check new data---------------------------------------------------------------------------------------------------
crtabs(~ TabsSpaces + HouseholdSize, ds_fork)

## ----state change8, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----final mergeFork--------------------------------------------------------------------------------------------------
ds <- mergeFork(ds, ds_fork)
ds$HouseholdSize

## ----results='hide', echo=FALSE, message=FALSE------------------------------------------------------------------------
end_vignette()
if (run_cleanup) {
    for (ds_id in ds_to_delete) with_consent(deleteDataset(ds_id))
    with_consent(delete(my_project))
}


