## ---- eval = FALSE, message=FALSE-------------------------------------------------------------------------------------
#  library(crunch)
#  login()

## ---- results='hide', echo=FALSE, message=FALSE-----------------------------------------------------------------------
library(crunch)
library(httptest)
start_vignette("fork-and-merge")
login()

## ----message=FALSE, results='hide'------------------------------------------------------------------------------------
ds <- newDataset(SO_survey, "stackoverflow_survey")

## ----forcevarcat1, include=FALSE--------------------------------------------------------------------------------------
# Force catalog so that catalog is loaded at a consistent time
ds <- forceVariableCatalog(ds)

## ----fork dataset-----------------------------------------------------------------------------------------------------
forked_ds <- forkDataset(ds)

## ----forcevarcat2, include=FALSE--------------------------------------------------------------------------------------
# Force catalog so that catalog is loaded at a consistent time
forked_ds <- forceVariableCatalog(forked_ds)

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
wave2 <- newDataset(SO_survey, "SO_survey_wave2")


## ----state change4, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----fork-and-append, results='hide'----------------------------------------------------------------------------------
ds_fork <- forkDataset(ds)
ds_fork <- appendDataset(ds_fork, wave2)

## ---------------------------------------------------------------------------------------------------------------------
nrow(ds)
nrow(ds_fork)

## ----state change5, include=FALSE-------------------------------------------------------------------------------------
change_state()

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
house_ds <- newDataset(house_table, "House Size")

## ----fork and merge recode, message=FALSE, results='hide'-------------------------------------------------------------
ds_fork <- forkDataset(ds)
ds_fork <- merge(ds_fork, house_ds, by = "Respondent")

## ----state change7, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----check new data---------------------------------------------------------------------------------------------------
crtabs(~ TabsSpaces + HouseholdSize, ds_fork)

## ----state change8, include=FALSE-------------------------------------------------------------------------------------
change_state()

## ----final mergeFork--------------------------------------------------------------------------------------------------
ds <- mergeFork(ds, ds_fork)
ds$HouseholdSize

## ---- results='hide', echo=FALSE, message=FALSE-----------------------------------------------------------------------
end_vignette()

