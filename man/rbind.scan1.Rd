% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rbind_scan1.R
\name{rbind.scan1}
\alias{rbind.scan1}
\title{Join genome scan results for different chromosomes.}
\usage{
\method{rbind}{scan1}(...)
}
\arguments{
\item{...}{Genome scan objects of class \code{"scan1"}, as produced by \code{\link[=scan1]{scan1()}}.
Must have the same lod score columns.}
}
\value{
An object of class `"scan1", like the inputs, but with
the results for different sets of chromosomes combined.
}
\description{
Join multiple \code{\link[=scan1]{scan1()}} results for different
chromosomes; must have the same set of lod score column.
}
\details{
If components \code{addcovar}, \code{Xcovar},
\code{intcovar}, \code{weights}, \code{sample_size} do not match
between objects, we omit this information.

If \code{hsq} present, we simply \code{rbind()} the contents.
}
\examples{
grav2 <- read_cross2(system.file("extdata", "grav2.zip", package="qtl2"))
map <- insert_pseudomarkers(grav2$gmap, step=1)
probs <- calc_genoprob(grav2, map, error_prob=0.002)
phe <- grav2$pheno[,1,drop=FALSE]

out1 <- scan1(probs[,1], phe) # chr 1
out2 <- scan1(probs[,5], phe) # chr 5
out <- rbind(out1, out2)

}
\seealso{
\code{\link[=cbind.scan1]{cbind.scan1()}}, \code{\link[=scan1]{scan1()}}
}
