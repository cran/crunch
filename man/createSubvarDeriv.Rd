% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make-array.R
\name{createSubvarDeriv}
\alias{createSubvarDeriv}
\title{Create subvariable derivation expressions}
\usage{
createSubvarDeriv(var, str, delim, selected, not_selected, unanswered)
}
\arguments{
\item{var}{The variable containing the delimited responses}

\item{str}{A string whose presence indicates a selection}

\item{delim}{The delimiter separating the responses}

\item{selected}{A character string used to indicate a selection, defaults to
"selected"}

\item{not_selected}{Character string identifying non-selection, defaults to
"not_selected"}

\item{unanswered}{Character string indicating non-response, defaults to NA.}
}
\value{
A VariableDefinition
}
\description{
This function creates a single subvariable definition based on a character string
to search for and an originating variable. It uses regex to determine whether
a string is present in a delimited list, then substitutes the user supplied values
to indicate selection, non-selection, and missingness.
}
\keyword{internal}
