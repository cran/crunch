% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/projects.R
\name{newProject}
\alias{newProject}
\title{Create a new folder}
\usage{
newProject(name, members = NULL, catalog = projects(), ...)
}
\arguments{
\item{name}{character name for the project}

\item{members}{Optional character vector of emails or user URLs to add as
project members.}

\item{catalog}{ProjectFolder in which to create the new project. There is
only one project catalog currently, \code{\link[=projects]{projects()}}, but this is left here
so that all \verb{new*} functions follow the same pattern.}

\item{...}{Additional project attributes to set}
}
\value{
A \code{ProjectFolder} object.
}
\description{
This function creates a new project. You can achieve the same results by
assigning into the projects catalog, but this may be a more natural way to
think of the action, particularly when you want to do something with the
project entity after you create it.
}
\examples{
\dontrun{
proj <- newProject("A project name")
# That is equivalent to doing:
p <- projects()
p[["A project name"]] <- list()
proj <- p[["A project name"]]

proj2 <- newProject("Another project", members = "you@yourco.com")
# That is equivalent to doing:
p[["Another project"]] <- list(members = "you@yourco.com")
proj <- p[["Another project"]]
}
}
\seealso{
\code{\link[=mkdir]{mkdir()}}
}
