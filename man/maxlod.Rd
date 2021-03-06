% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/max_scan1.R
\name{maxlod}
\alias{maxlod}
\title{Overall maximum LOD score}
\usage{
maxlod(scan1_output, map = NULL, chr = NULL)
}
\arguments{
\item{scan1_output}{An object of class \code{"scan1"} as returned by
\code{\link[=scan1]{scan1()}}.}

\item{map}{A list of vectors of marker positions, as produced by
\code{\link[=insert_pseudomarkers]{insert_pseudomarkers()}}.}

\item{chr}{Optional vector of chromosomes to consider.}
}
\value{
A single number: the maximum LOD score across all columns and positions for
the selected chromosomes.
}
\description{
Find overall maximum LOD score in genome scan results, across all positions and columns.
}
\examples{
# read data
iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2"))

# insert pseudomarkers into map
map <- insert_pseudomarkers(iron$gmap, step=1)

# calculate genotype probabilities
probs <- calc_genoprob(iron, map, error_prob=0.002)

# grab phenotypes and covariates; ensure that covariates have names attribute
pheno <- iron$pheno
covar <- match(iron$covar$sex, c("f", "m")) # make numeric
names(covar) <- rownames(iron$covar)
Xcovar <- get_x_covar(iron)

# perform genome scan
out <- scan1(probs, pheno, addcovar=covar, Xcovar=Xcovar)

# overall maximum
maxlod(out)

# maximum on chromosome 2
maxlod(out, map, "2")
}
