% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R, R/AllGenerics.R, R/insertions.R
\docType{class}
\name{Insertions-class}
\alias{Insertions-class}
\alias{Insertions}
\alias{Insertion-class}
\alias{Insertion}
\alias{.Insertion}
\alias{anchor}
\alias{anchors}
\alias{anchor<-}
\alias{arguments}
\alias{arguments<-}
\alias{func}
\alias{funcs}
\alias{func<-}
\alias{anchor<-,Insertion-method}
\alias{anchor<-,Subtotal-method}
\alias{anchor<-,Heading-method}
\alias{anchor<-,SummaryStat-method}
\alias{subtotals<-,Insertion,ANY-method}
\alias{arguments<-,Insertion-method}
\alias{arguments<-,Subtotal-method}
\alias{arguments<-,Heading-method}
\alias{arguments<-,SummaryStat-method}
\alias{arguments,Insertion-method}
\alias{arguments,Subtotal-method}
\alias{arguments,Heading-method}
\alias{arguments,SummaryStat-method}
\alias{anchor,Insertion-method}
\alias{anchor,Subtotal-method}
\alias{anchor,Heading-method}
\alias{anchor,SummaryStat-method}
\alias{func,Insertion-method}
\alias{func,Subtotal-method}
\alias{func,Heading-method}
\alias{func,SummaryStat-method}
\alias{anchors,Insertions-method}
\alias{funcs,Insertions-method}
\title{Insert categories in transformations}
\usage{
Insertions(..., data = NULL)

Insertion(...)

.Insertion(..., data = NULL)

anchor(x, ...)

anchors(x)

anchor(x) <- value

arguments(x, ...)

arguments(x) <- value

func(x)

funcs(x)

\S4method{anchor}{Insertion}(x) <- value

\S4method{anchor}{Subtotal}(x) <- value

\S4method{anchor}{Heading}(x) <- value

\S4method{anchor}{SummaryStat}(x) <- value

\S4method{subtotals}{Insertion,ANY}(x) <- value

\S4method{arguments}{Insertion}(x) <- value

\S4method{arguments}{Subtotal}(x) <- value

\S4method{arguments}{Heading}(x) <- value

\S4method{arguments}{SummaryStat}(x) <- value

\S4method{arguments}{Insertion}(x)

\S4method{arguments}{Subtotal}(x, var_items)

\S4method{arguments}{Heading}(x)

\S4method{arguments}{SummaryStat}(x, var_items)

\S4method{anchor}{Insertion}(x, ...)

\S4method{anchor}{Subtotal}(x, var_items)

\S4method{anchor}{Heading}(x, var_items)

\S4method{anchor}{SummaryStat}(x, var_items)

\S4method{func}{Insertion}(x)

\S4method{func}{Subtotal}(x)

\S4method{func}{Heading}(x)

\S4method{func}{SummaryStat}(x)

\S4method{anchors}{Insertions}(x)

\S4method{funcs}{Insertions}(x)
}
\arguments{
\item{...}{additional arguments to \code{[}, ignored}

\item{data}{For the constructor functions \code{Insertion} and
\code{Insertions}, you can either pass in attributes via \code{...} or you
can create the objects with a fully defined \code{list} representation of
the objects via the \code{data} argument. See the examples.}

\item{x}{For the attribute getters and setters, an object of class
Insertion or Insertions}

\item{value}{For \verb{[<-}, the replacement Insertion to insert}

\item{var_items}{categories (from \code{\link[=categories]{categories()}}) or subvariables (from
\code{\link[=subvariables]{subvariables()}} to used by the \code{arguments} and \code{anchor} methods when
needed to translate between category/subvariable names and category
ids/aliases.}
}
\description{
Insertions allow you to insert new categories into a categorical-like
response on a variable's \link[=Transforms]{transformations}.
}
\section{Working with Insertions}{

Insertions are used to add information about a variable or CrunchCube that
extends the data in the dataset but does not alter it. This new data
includes: aggregations like \link[=SubtotalsHeadings]{subtotals} that sum the count
of more than on category together or \link[=SubtotalsHeadings]{headings} which can
be added between categories.

\code{Insertions} objects are containers for individual \code{Insertion} objects. The
individual \code{Insertion}s contain all the information needed to calculate,
apply, and display insertions to CrunchCubes and categorical variables.

An \code{Insertion} must have two properties:
\itemize{
\item \code{anchor} - which is the id of the category the insertion should follow
\item \code{name} - the string to display
}

Additionally, \code{Insertions} may also have the following two properties (though
if they have one, they must have the other):
\itemize{
\item \code{function} - the function to use to aggregate (e.g. "subtotal")
\item \code{args} - the category ids to use as operands to the \code{function} above.
}

Although it is possible to make both subtotals and headings using \code{Insertion}
alone, it is much easier and safer to use the functions
\link[=SubtotalsHeadings]{Subtotal()} and \link[=SubtotalsHeadings]{Heading()} instead.
Not only are they more transparent, they also are quicker to type, accept
both category names as well as ids, and have easier to remember argument
names.
}

