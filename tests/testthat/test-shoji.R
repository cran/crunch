context("Shoji")

test_that("is.shoji", {
    fo <- list(element = "shoji:view", self = 2, description = 3)
    expect_false(is.shoji(fo))
    expect_true(is.shoji.like(fo))
    class(fo) <- "shoji"
    expect_true(is.shoji(fo))
})

test_that("ShojiObject init and is", {
    expect_true(is.shojiObject(ShojiObject(element = 1, self = 2, description = 3)))
    expect_false(is.shojiObject(5))
    fo <- list(element = 1, self = 2, description = 3)
    class(fo) <- "shoji"
    expect_false(is.shojiObject(fo))
    expect_true(is.shojiObject(ShojiObject(
        element = 1, self = 2, description = 3,
        foo = 4, junk = 5
    )))
    sh <- ShojiObject(
        element = 1, self = 2, description = 3, foo = 4, junk = 5,
        body = list(a = 12, f = 66)
    )
    expect_identical(sh@self, 2)
})

test_that("ShojiCatalog", {
    fo <- structure(list(
        element = 1, self = 2, description = 3,
        index = list(`/a` = list(4), `/b` = list(5))
    ),
    class = "shoji"
    )
    sho <- ShojiObject(fo)
    expect_false(is.catalog(sho))
    expect_error(index(sho))
    fo$element <- "shoji:catalog" ## TODO: implement ShojiObject subclassing
    sho <- ShojiCatalog(fo)
    expect_true(is.catalog(sho))
    expect_identical(index(sho), fo$index)
    expect_true(is.catalog(sho[1]))
    expect_error(sho[2:3], "Subscript out of bounds: 3")
    expect_error(sho[2:10], "Subscript out of bounds: 3:10")
    expect_true(is.catalog(sho[c(TRUE, FALSE)]))
    expect_error(
        sho[c(TRUE, FALSE, TRUE)],
        "Subscript out of bounds: got 3 logicals, need 2"
    )
    expect_identical(sho[TRUE], sho)
    expect_identical(sho["/a"], sho[1]) # nolint
    expect_error(sho[c("/a", "c")], "Undefined elements selected: c") # nolint
})

with_mock_crunch({
    full.urls <- DatasetCatalog(crGET("https://app.crunch.io/api/datasets/all"))
    rel.urls <- DatasetCatalog(
        crGET("https://app.crunch.io/api/datasets/all", query = list(relative = "on"))
    )
    test_that("urls() method returns absolute URLs", {
        expect_identical(urls(full.urls), urls(rel.urls))
    })

    test_that("ShojiCatalog can use any method it has to index", {
        expect_equal(
            full.urls["https://app.crunch.io/api/users/notme/",
                secondary = owners(full.urls)
            ],
            full.urls[1]
        )
        expect_equal(
            full.urls[["https://app.crunch.io/api/users/notme/",
            secondary = owners(full.urls)]],
            full.urls[[1]]
        )
    })

    test_that("shojiURL", {
        ds <- cachedLoadDataset("test ds")
        expect_identical(
            shojiURL(ds, "catalogs", "variables"),
            "https://app.crunch.io/api/datasets/1/variables/"
        )
        expect_error(
            shojiURL(ds, "catalogs", "NOTACATALOG"),
            paste0(
                "No URL ", dQuote("NOTACATALOG"), " in collection ",
                dQuote("catalogs")
            )
        )
    })
})

with_test_authentication({
    ds <- newDataset(df[1:2, 1:2])
    test_that("refresh", {
        ds2 <- ds
        ds2@body$name <- "something else"
        expect_false(identical(ds2@body$name, ds@body$name))
        expect_false(identical(ds2@body$name, refresh(ds2)@body$name))
        expect_identical(refresh(ds2)@body$name, ds@body$name)
    })
})
