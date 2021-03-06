# fit a single-QTL model at a single position, adjusting for polygenes with an LMM
#
fit1_pg <-
    function(genoprobs, pheno, kinship,
             addcovar=NULL, nullcovar=NULL, intcovar=NULL,
             weights=NULL, contrasts=NULL, zerosum=TRUE, se=FALSE,
             hsq=NULL, reml=TRUE, ...)
{
    # deal with the dot args
    dotargs <- list("...")
    tol <- grab_dots(dotargs, "tol", 1e-12)
    if(!is_pos_number(tol)) stop("tol should be a single positive number")
    check_extra_dots(dotargs, "tol")

    # check that the objects have rownames
    check4names(pheno, addcovar, NULL, intcovar, nullcovar)

    # force things to be matrices
    if(!is.null(addcovar)) {
        if(!is.matrix(addcovar)) addcovar <- as.matrix(addcovar)
        if(!is.numeric(addcovar)) stop("addcovar is not numeric")
    }
    if(!is.null(nullcovar)) {
        if(!is.matrix(nullcovar)) nullcovar <- as.matrix(nullcovar)
        if(!is.numeric(nullcovar)) stop("nullcovar is not numeric")
    }
    if(!is.null(intcovar)) {
        if(!is.matrix(intcovar)) intcovar <- as.matrix(intcovar)
        if(!is.numeric(intcovar)) stop("intcovar is not numeric")
    }
    if(!is.null(contrasts)) {
        if(!is.matrix(contrasts)) contrasts <- as.matrix(contrasts)
        if(!is.numeric(contrasts)) stop("contrasts is not numeric")
    }

    # make sure pheno is a vector
    if(is.matrix(pheno) || is.data.frame(pheno)) {
        if(ncol(pheno) > 1)
            warning("Considering only the first phenotype.")
        rn <- rownames(pheno)
        pheno <- pheno[,1]
        names(pheno) <- rn
        if(!is.numeric(pheno)) stop("pheno is not numeric")
    }

    # genoprobs is a matrix?
    if(!is.matrix(genoprobs))
        stop("genoprobs should be a matrix, individuals x genotypes")

    # make sure contrasts is square n_genotypes x n_genotypes
    if(!is.null(contrasts)) {
        ng <- ncol(genoprobs)
        if(ncol(contrasts) != ng || nrow(contrasts) != ng)
            stop("contrasts should be a square matrix, ", ng, " x ", ng)
    }

    # make sure kinship is for a single chromosome and get IDs
    did_decomp <- is_kinship_decomposed(kinship)
    kinship <- check_kinship_onechr(kinship)
    kinshipIDs <- check_kinship(kinship, 1)

    # multiply kinship matrix by 2; rest is using 2*kinship
    # see Almasy & Blangero (1998) https://doi.org/10.1086/301844
    kinship <- double_kinship(kinship)

    # find individuals in common across all arguments
    # and drop individuals with missing covariates or missing *all* phenotypes
    ind2keep <- get_common_ids(genoprobs, pheno, kinshipIDs, weights,
                               addcovar, nullcovar, intcovar, complete.cases=TRUE)

    if(length(ind2keep)<=2) {
        if(length(ind2keep)==0)
            stop("No individuals in common.")
        else
            stop("Only ", length(ind2keep), " individuals in common: ",
                 paste(ind2keep, collapse=":"))
    }

    if(did_decomp) { # if did decomposition already, make sure it was with exactly
        if(length(kinshipIDs) != length(ind2keep) ||
           any(sort(kinshipIDs) != sort(ind2keep)))
            stop("Decomposed kinship matrix was with different individuals")
        else
            ind2keep <- kinshipIDs # force them in same order
    }

    # omit individuals not in common
    genoprobs <- genoprobs[ind2keep,,drop=FALSE]
    pheno <- pheno[ind2keep]
    if(!is.null(addcovar)) addcovar <- addcovar[ind2keep,,drop=FALSE]
    if(!is.null(nullcovar)) nullcovar <- nullcovar[ind2keep,,drop=FALSE]
    if(!is.null(intcovar)) intcovar <- intcovar[ind2keep,,drop=FALSE]
    if(!is.null(weights)) weights <- weights[ind2keep]

    # square-root of weights; multiply things by weights
    weights <- sqrt_weights(weights)
    kinship <- weight_kinship(kinship, weights)
    pheno <- weight_matrix(pheno, weights)
    addcovar <- weight_matrix(addcovar, weights)
    intcovar <- weight_matrix(intcovar, weights)
    nullcovar <- weight_matrix(nullcovar, weights)
    genoprobs <- weight_matrix(genoprobs, weights)
    intercept <- weights; if(is_null_weights(weights)) intercept <- rep(1,length(pheno))

    # make sure addcovar is full rank when we add an intercept
    addcovar <- drop_depcols(addcovar, TRUE, tol)

    # make sure columns in intcovar are also in addcovar
    addcovar <- force_intcovar(addcovar, intcovar, tol)

    # eigen decomposition of kinship matrix
    if(!did_decomp)
        kinship <- decomp_kinship(kinship[ind2keep, ind2keep])

    # estimate hsq if necessary
    if(is.null(hsq)) {
        nullresult <- calc_hsq_clean(Ke=kinship, pheno=as.matrix(pheno),
                                     addcovar=cbind(addcovar, nullcovar),
                                     Xcovar=NULL, is_x_chr=FALSE, weights=weights, reml=reml,
                                     cores=1, check_boundary=TRUE, tol=tol)
        hsq <- as.numeric(nullresult$hsq)
    }

    # eigen-vectors and weights
    eigenvec <- kinship$vectors
    wts <- 1/sqrt(hsq*kinship$values + (1-hsq))

    # fit null model
    fit0 <- fit1_pg_addcovar(cbind(intercept, addcovar, nullcovar),
                             pheno,
                             matrix(ncol=0, nrow=length(pheno)),
                             eigenvec, wts, se, tol)

    # multiply genoprobs by contrasts
    if(!is.null(contrasts))
        genoprobs <- genoprobs %*% contrasts

    if(is.null(intcovar)) { # just addcovar
        if(is.null(addcovar)) addcovar <- matrix(nrow=length(ind2keep), ncol=0)
        fitA <- fit1_pg_addcovar(genoprobs, pheno, addcovar, eigenvec, wts, se, tol)
    }
    else {                  # intcovar
        fitA <- fit1_pg_intcovar(genoprobs, pheno, addcovar, intcovar,
                                 eigenvec, wts, se, tol)
    }

    # lod score
    n <- length(pheno)
    lod <- (n/2)*log10(fit0$rss/fitA$rss)

    # names of coefficients
    coef_names <- scan1coef_names(genoprobs, addcovar, intcovar)

    # fitted values
    fitted <- setNames(fitA$fitted, names(pheno))
    resid <- pheno - fitted

    # center the QTL effects at zero and add an intercept
    if(zerosum && is.null(contrasts)) {
        ng <- dim(genoprobs)[2]
        whval <- seq_len(ng)
        mu <- mean(fitA$coef[whval], na.rm=TRUE)
        fitA$coef <- c(fitA$coef, mu)
        fitA$coef[whval] <- fitA$coef[whval] - mu

        coef_names <- c(coef_names, "intercept")

        if(se) {
            fitA$SE <- c(fitA$SE, sqrt(mean(fitA$SE[whval]^2, na.rm=TRUE)))
        }
    }

    if(se) # results include standard errors
        return(list(lod=lod,
                    coef=stats::setNames(fitA$coef, coef_names),
                    SE=stats::setNames(fitA$SE, coef_names),
                    fitted=fitted, resid=resid))
    else
        return(list(lod=lod,
                    coef=stats::setNames(fitA$coef, coef_names),
                    fitted=fitted, resid=resid))
}
