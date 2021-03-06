% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/batches.R
\name{cleanseBatches}
\alias{cleanseBatches}
\title{Remove batches from a dataset}
\usage{
cleanseBatches(dataset, keep = c("imported", "appended"))
}
\arguments{
\item{dataset}{CrunchDataset}

\item{keep}{character the statuses that you want to keep. By default, batches
that don't have either "imported" or "appended" status will be deleted.}
}
\value{
\code{dataset} with the specified batches removed.
}
\description{
Sometimes append operations do not succeed, whether due to conflicts between
the two datasets or other server-side issues. Failed appends can leave behind
"error" status batch records, which can cause confusion. This function lets
you delete batches that don't match the status or statuses you want to keep.
}
