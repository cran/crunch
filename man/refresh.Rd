% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/dataset.R, R/shoji.R,
%   R/variable.R
\name{refresh}
\alias{refresh}
\alias{refresh,CrunchDataset-method}
\alias{refresh,ShojiObject-method}
\alias{refresh,CrunchVariable-method}
\title{Get a fresh copy from the server}
\usage{
refresh(x)

\S4method{refresh}{CrunchDataset}(x)

\S4method{refresh}{ShojiObject}(x)

\S4method{refresh}{CrunchVariable}(x)
}
\arguments{
\item{x}{pretty much any Crunch object}
}
\value{
a new version of \code{x}
}
\description{
Crunch objects generally keep themselves in sync with the server when you
manipulate them, but some operations cause the local version to diverge from
the version on the server. For instance, someone else may have
modified the dataset you're working on, or maybe
you have modified a variable outside of the context of its dataset.
\code{refresh()} allows you to get back in sync.
}
