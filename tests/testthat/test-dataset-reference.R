context("datasetReference")

with_mock_crunch({
    ds <- cachedLoadDataset("test ds")
    ds_url <- self(ds)
    test_that("datasetReference methods", {
        expect_identical(ds_url, "https://app.crunch.io/api/datasets/1/")
        expect_identical(datasetReference(ds), ds_url)
        expect_identical(datasetReference(ds$gender), ds_url)
        expect_identical(datasetReference(ds$mymrset$subvar1), ds_url)
        expect_identical(datasetReference(ds$gender == "Male"), ds_url)
        expect_identical(datasetReference(multitables(ds)), ds_url)
        expect_identical(datasetReference(multitables(ds)[[1]]), ds_url)
        expect_null(datasetReference(1))
        expect_null(datasetReference("not a ds url"))
        expect_identical(
            datasetReference(
                "https://app.crunch.io/api/datasets/1/variables/mymrset/subvariables/subvar1"
            ),
            ds_url
        )
    })
})
