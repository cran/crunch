## ----setup, include=FALSE---------------------------------------------------------------------------------------------
knitr::opts_chunk$set(eval = FALSE)

## ---------------------------------------------------------------------------------------------------------------------
#  suppressPackageStartupMessages({
#      library(purrr)
#      library(crunch)
#  })
#  
#  options("crunch.show.progress" = FALSE)
#  
#  login()
#  ds <- newExampleDataset()

## ---------------------------------------------------------------------------------------------------------------------
#  deck <- newDeck(ds, "Q3 Pets Deck", is_public = TRUE)
#  private_deck <- newDeck(ds, "Private Deck")
#  
#  # If no `vizType` is specified, defaults to a table
#  slide <- newSlide(deck, ~q1, title = "Table of Favorite Pet")
#  
#  # Example of setting a vizType and filter
#  slide <- newSlide(
#      deck,
#      mean(ndogs) ~ country,
#      title = "Dot Plot of Mean Dogs by Country",
#      display_settings = list(vizType = "dotplot"),
#      filter = ds$q1 == "Dog"
#  )
#  
#  deck <- refresh(deck)

## ---------------------------------------------------------------------------------------------------------------------
#  ds <- refresh(ds)
#  decks(ds)
#  
#  private_deck <- decks(ds)[["Private Deck"]]
#  
#  slide <- newSlide(
#      private_deck,
#      ~q1,
#      title = "Bar Plot of Favorite Pet",
#      display_settings = list(vizType = "groupedBarPlot")
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  # Move title to subtitle and change the title
#  slide <- slides(deck)[["Table of Favorite Pet"]]
#  subtitle(slide) <- title(slide)
#  title(slide) <- "Cats are the most popular"
#  
#  
#  # Rename a category
#  slide <- slides(deck)[[2]]
#  transforms(slide) <- list(
#      rows_dimension = makeDimTransform(rename = c("AUS" = "Australia"))
#  )

## ---- include=FALSE---------------------------------------------------------------------------------------------------
#  ### Reordering slides on a deck
#  #### Problem
#  # You want to rearrange the order slides on an existing deck.
#  
#  #### Solution
#  # TODO: This is not currently possible from R :(
#  # (Note this controls the order of the slides in a deck, which controls how they appear in the web app's
#  # deck viewer and Excel and PowerPoint exports, but does not change order or position of an existing
#  # Crunch Dashboard)

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- slides(deck)[[1]]
#  
#  if (FALSE) { # Not actually run for example
#      delete(slide)
#  }

## ---------------------------------------------------------------------------------------------------------------------
#  is.public(private_deck) <- TRUE # now public

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1,
#      title = "Univariate frequency: Favorite Pet"
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1 + country,
#      title = "Bivariate frequency: Favorite Pet by country"
#  )
#  
#  # A third dimension is possible, which will usually result in a tabbed result:
#  slide <- newSlide(
#      deck,
#      ~q1 + country + wave,
#      title = "Trivariate frequency: Favorite Pet by country by wave"
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~allpets,
#      title = "Categorical array: default order"
#  )
#  
#  slide <- newSlide(
#      deck,
#      ~categories(allpets) + subvariables(allpets),
#      title = "Categorical array: categories on rows dimension"
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      mean(ndogs) ~ 1,
#      title = "Mean Number of Dogs"
#  )
#  
#  slide <- newSlide(
#      deck,
#      mean(ndogs) ~ country,
#      title = "Mean Number of Dogs by Country"
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  # There's only one MR available on this dataset, so we repeat the same one twice to illustrate
#  slide <- newSlide(
#      deck,
#      ~scorecard(allpets, allpets),
#      title = "Scorecard"
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1,
#      title = "Favorite pet using default palette",
#      display_settings = list(vizType = "groupedBarPlot"),
#      transform = list(
#          rows_dimension = makeDimTransform(colors = defaultPalette(ds))
#      )
#  )
#  
#  graph_pal <- palettes(ds)[["purple palette"]]
#  slide <- newSlide(
#      deck,
#      ~categories(petloc) + subvariables(petloc),
#      title = "Pets by location using another palette",
#      display_settings = list(vizType = "horizontalBarPlot"),
#      transform = list(
#          rows_dimension = makeDimTransform(colors = graph_pal)
#      )
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1,
#      title = "Favorite pet using colors from R",
#      display_settings = list(vizType = "groupedBarPlot"),
#      transform = list(
#          rows_dimension = makeDimTransform(colors = c("#af8dc3", "#f7f7f7", "#7fbf7b"))
#      )
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1,
#      title = "Favorite pet excluding birds",
#      display_settings = list(vizType = "groupedBarPlot"),
#      transform = list(
#          rows_dimension = makeDimTransform(hide = "Bird")
#      )
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  slide <- newSlide(
#      deck,
#      ~q1 + country,
#      title = "Favorite pet by country horizontal bar plot",
#      display_settings = list(vizType = "horizontalBarPlot")
#  )
#  
#  
#  slide <- newSlide(
#      deck,
#      ~q1 + wave,
#      title = "Favorite pet over time timeplot",
#      display_settings = list(vizType = "timeplot")
#  )

## ---------------------------------------------------------------------------------------------------------------------
#  template_deck <- newDeck(ds, "Templates", is_public = TRUE)
#  slide <- newSlide(
#      template_deck,
#      ~q1,
#      title = "Donut with value labels",
#      display_settings = list(vizType = "donut", showValueLabels = TRUE),
#      viz_specs = list(
#          default = list(
#              format = list(
#                  decimal_places = list(percentages = 0L, other = 2L),
#                  show_empty = FALSE
#              )
#          )
#      )
#  )
#  
#  # Setting the slide `display_setting` and `viz_specs` directly:
#  slide <- newSlide(
#      deck,
#      ~country,
#      title = "Country donut with value labels",
#      display_settings = displaySettings(template_deck[["Donut with value labels"]]),
#      viz_specs = vizSpecs(template_deck[["Donut with value labels"]])
#  )
#  
#  # How to print out the structure in a format that can be copy and pasted into your code
#  print(dput(displaySettings(template_deck[["Donut with value labels"]])))

## ---------------------------------------------------------------------------------------------------------------------
#  deck <- newDeck(ds, "Full Dataset Topline Deck", is_public = TRUE)
#  
#  var_aliases <- aliases(variables(ds))
#  
#  slides <- lapply(var_aliases, function(alias) {
#      slide_query <- as.formula(paste0("~", alias))
#      slide_title <- paste0("Topline - ", name(ds[[alias]]))
#  
#      newSlide(deck, slide_query, title = slide_title)
#  })

## ---------------------------------------------------------------------------------------------------------------------
#  deck <- newDeck(ds, "Folder Topline Deck", is_public = TRUE)
#  
#  folder <- cd(ds, "Key Pet Indicators")
#  var_aliases <- aliases(variables(folder))
#  
#  slides <- lapply(var_aliases, function(alias) {
#      slide_query <- as.formula(paste0("~", alias))
#      slide_title <- paste0("Topline - ", name(ds[[alias]]))
#  
#      newSlide(deck, slide_query, title = slide_title)
#  })

## ---------------------------------------------------------------------------------------------------------------------
#  deck <- newDeck(ds, "Crosstabs Deck", is_public = TRUE)
#  
#  demo_vars <- aliases(variables(cd(ds, "Dimensions")))
#  var_aliases <- setdiff(aliases(variables(ds)), demo_vars) # don't cross demo vars with themselves
#  
#  slides <- lapply(var_aliases, function(alias) {
#      # Add a slide before crosstabs of the univariate frequency
#      all_query <- as.formula(paste0("~", alias))
#      all_title <- paste0("Frequency - ", name(ds[[alias]]))
#  
#      newSlide(deck, all_query, title = all_title)
#  
#      lapply(demo_vars, function(demo_alias) {
#          crosstab_query <- as.formula(paste0("~", demo_alias, " + ", alias))
#          crosstab_title <- paste0("Crosstab - ", name(ds[[alias]]), " by ", name(ds[[demo_alias]]))
#  
#          newSlide(deck, crosstab_query, title = crosstab_title)
#      })
#  })

## ---------------------------------------------------------------------------------------------------------------------
#  cat_slide <- function(alias, ds, deck) {
#      slide_query <- as.formula(paste0("~", alias))
#      slide_title <- paste0(name(ds[[alias]]))
#      newSlide(
#          deck,
#          slide_query,
#          title = slide_title,
#          display_settings = list(vizType = "donut")
#      )
#  }
#  
#  mr_slide <- function(alias, ds, deck) {
#      slide_query <- as.formula(paste0("~", alias))
#      slide_title <- paste0(name(ds[[alias]]))
#      newSlide(
#          deck,
#          slide_query,
#          title = slide_title,
#          display_settings = list(vizType = "groupedBarPlot")
#      )
#  }
#  
#  numeric_slide <- function(alias, ds, deck) {
#      slide_query <- as.formula(paste0("mean(", alias, ") ~ wave"))
#      slide_title <- paste0(name(ds[[alias]]), " over time")
#      newSlide(
#          deck,
#          slide_query,
#          title = slide_title,
#          display_settings = list(vizType = "timeplot")
#      )
#  }
#  
#  deck <- newDeck(ds, "Slides Customized by Variable Type", is_public = TRUE)
#  
#  var_aliases <- c("q1", "allpets", "ndogs")
#  slides <- lapply(var_aliases, function(alias) {
#      switch(
#          type(ds[[alias]]),
#          "categorical" = cat_slide(alias, ds, deck),
#          "multiple_response" = mr_slide(alias, ds, deck),
#          "numeric" = numeric_slide(alias, ds, deck),
#      )
#  })

