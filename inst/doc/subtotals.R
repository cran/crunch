## ---- message=FALSE---------------------------------------------------------------------------------------------------
library(crunch)

## ---- results='hide', include = FALSE---------------------------------------------------------------------------------
set_crunch_opts("crunch.api" = "https://app.crunch.io/api/")
options(width=120)
library(httptest)
if (!dir.exists("subtotals")) {

    if ("example vignette ds - subtotal" %in% listDatasets()) {
        ds <- loadDataset("example vignette ds - subtotal")
        with_consent(deleteDataset("example vignette ds - subtotal"))
    }
    
    ds <- newExampleDataset()
    name(ds) <- "example vignette ds - subtotal"
    lvls <- c("Love", "Like", "Neutral", "Dislike", "Hate")
    ds$like_dogs <- factor(rep(lvls, c(4, 4, 8, 2, 2)), lvls)
    ds$like_cats <- factor(rep(lvls, c(3, 5, 1, 6, 5)), rev(lvls))
    
    httpcache::clearCache()
}
start_vignette("subtotals")
ds <- loadDataset("example vignette ds - subtotal")

## ----no subtotals-----------------------------------------------------------------------------------------------------
subtotals(ds$q1)

## ----state change1, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----add some subtotals-----------------------------------------------------------------------------------------------
subtotals(ds$q1) <- list(
    Subtotal(
        name = "Mammals",
        categories = c("Cat", "Dog"),
        after = "Dog"
    ),
    Subtotal(
        name = "Can speak on command",
        categories = c("Dog", "Bird"),
        after = "Bird"
    )
)

## ----state change2, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----new subtotals----------------------------------------------------------------------------------------------------
subtotals(ds$q1)

## ----crunch app output, echo = FALSE----------------------------------------------------------------------------------
knitr::include_graphics("images/webapp_subtotals.png")

## ----add subtotal diff------------------------------------------------------------------------------------------------
subtotals(ds$like_dogs) <- list(
    Subtotal(
        name = "Love minus Dislike & Hate",
        categories = c("Love"),
        negative = c("Dislike", "Hate"),
        position = "top"
    )
)

## ----add mr subtotal--------------------------------------------------------------------------------------------------
subtotals(ds$allpets) <- list(
    Subtotal(
        name = "Any mammal",
        c("allpets_1", "allpets_2"),
        position = "top"
    )
)

## ----state change3, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----remove some headings---------------------------------------------------------------------------------------------
subtotals(ds$like_dogs) <- NULL

## ----save some subtotals----------------------------------------------------------------------------------------------
pet_type_subtotals <- list(
    Subtotal(
        name = "Love minus Dislike & Hate",
        categories = c("Love"),
        negative = c("Dislike", "Hate"),
        position = "top"
    )
)

## ----check some categories--------------------------------------------------------------------------------------------
subtotals(ds$like_dogs) <- pet_type_subtotals
subtotals(ds$like_cats) <- pet_type_subtotals

## ----show some categories---------------------------------------------------------------------------------------------
subtotals(ds$like_dogs)
subtotals(ds$like_cats)

## ----show subtotals---------------------------------------------------------------------------------------------------
crtabs(~like_dogs, data = ds)

## ----show subtotals only----------------------------------------------------------------------------------------------
subtotalArray(crtabs(~like_dogs, data = ds))

## ----noTransforms-----------------------------------------------------------------------------------------------------
noTransforms(crtabs(~like_dogs, data = ds))

## ---------------------------------------------------------------------------------------------------------------------
# addSummaryStat is a convenient way to add mean/median
addSummaryStat(crtabs(~q1, ds), margin = 1)

cube <- crtabs(~q1, data = ds)
transforms(cube)$q1$insertions <- list(Heading("Mammals", position = "top"), Heading("Other", after = "Dog"))
cube

## ---- include=FALSE---------------------------------------------------------------------------------------------------
end_vignette()

