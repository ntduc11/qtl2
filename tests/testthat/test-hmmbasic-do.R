context("basic HMM functions in Diversity Outcross")

test_that("DO nalleles works", {
    expect_equal(nalleles("do"), 8)
})

test_that("DO check_geno works", {

    # observed genotypes
    for(i in 0:5) {
        # Autosome
        expect_true(test_check_geno("do", i, TRUE, FALSE, FALSE, 20))
        # Female X
        expect_true(test_check_geno("do", i, TRUE, TRUE, TRUE, 20))
        # Male X
        expect_true(test_check_geno("do", i, TRUE, TRUE, FALSE, 20))
    }
    for(i in c(-1, 6)) {
        # Autosome
        expect_false(test_check_geno("do", i, TRUE, FALSE, FALSE, 20))
        # Female X
        expect_false(test_check_geno("do", i, TRUE, TRUE, TRUE, 20))
        # Male X
        expect_false(test_check_geno("do", i, TRUE, TRUE, FALSE, 20))
    }

    # true genotypes, autosome and female X
    for(i in 1:36) {
        # Autosome
        expect_true(test_check_geno("do", i, FALSE, FALSE, FALSE, 20))
        # Female X
        expect_true(test_check_geno("do", i, FALSE, TRUE, TRUE, 20))
    }
    for(i in c(0, 37)) {
        # Autosome
        expect_false(test_check_geno("do", i, FALSE, FALSE, FALSE, 20))
        # Female X
        expect_false(test_check_geno("do", i, FALSE, TRUE, TRUE, 20))
    }

    # true genotypes, autosome and female X
    for(i in 36 + 1:8) {
        expect_true(test_check_geno("do", i, FALSE, TRUE, FALSE, 20))
    }
    for(i in c(0:36, 36+9)) {
        expect_false(test_check_geno("do", i, FALSE, TRUE, FALSE, 20))
    }

})

test_that("DO n_gen works", {

    expect_equal(test_ngen("do", FALSE), 36)
    expect_equal(test_ngen("do", TRUE),  36+8)

})

test_that("DO possible_gen works", {

    # autosome
    expect_equal(test_possible_gen("do", FALSE, FALSE, 20), 1:36)

    # X female
    expect_equal(test_possible_gen("do", TRUE, TRUE, 20), 1:36)

    # X male
    expect_equal(test_possible_gen("do", TRUE, FALSE, 20), 36+(1:8))

})

test_that("DO init works", {

    hom <- cumsum(1:8)
    het <- (1:36)[!((1:36) %in% cumsum(1:8))]
    male <- 36 + (1:8)

    for(i in hom) {
        # autosome and female X
        expect_equal(test_init("do", i, FALSE, FALSE, 20), log(1/64))
        expect_equal(test_init("do", i, TRUE,  TRUE,  20), log(1/64))
    }

    for(i in het) {
        # autosome and female X
        expect_equal(test_init("do", i, FALSE, FALSE, 20), log(1/32))
        expect_equal(test_init("do", i, TRUE,  TRUE,  20), log(1/32))
    }

    for(i in male)
        expect_equal(test_init("do", i, TRUE,  FALSE, 20), log(1/8))

})


test_that("DO emit works", {

    fgen <- c(1,3,0,1,3,0,1,3) # founder genotypes; 0=missing, 1=AA, 3=BB
    err <- 0.01

    # Autosome or female X
    # truth = homA: AA (1), AD (7), AG (22), DD (10), DG (25), GG (28)
    expected <- log(c(1-err, err/2, err/2, 1-err/2, err))
    for(trueg in c(1,7,22,10,25,28)) {
        for(obsg in 1:5) {
            expect_equal(test_emit("do", obsg, trueg, err, fgen, FALSE, FALSE, 20), expected[obsg])
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE,  TRUE, 20), expected[obsg])
        }
    }
    # truth = het: AB (2), AE (11), AH (29), BD (8), BG (23), DE (14), DH (32), EG (26), GH (35)
    expected <- log(c(err/2, 1-err, err/2, 1-err/2, 1-err/2))
    for(trueg in c(2,11,29,8,23,14,32,26,35)) {
        for(obsg in 1:5) {
            expect_equal(test_emit("do", obsg, trueg, err, fgen, FALSE, FALSE, 20), expected[obsg])
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE,  TRUE, 20), expected[obsg])
        }
    }
    # truth = homB: BB (3), BE (12), BH (30), EE (15), EH (33), HH (36)
    expected <- log(c(err/2, err/2, 1-err, err, 1-err/2))
    for(trueg in c(3,12,30,15,33,36)) {
        for(obsg in 1:5) {
            expect_equal(test_emit("do", obsg, trueg, err, fgen, FALSE, FALSE, 20), expected[obsg])
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE,  TRUE, 20), expected[obsg])
        }
    }
    # truth = A-: AC (4), AF (16), CD (9), DF (19), CG (24), FG (27)
    expected <- log(c(1-err,1,err,1-err,err))
    for(trueg in c(4,16,9,19,24,27)) {
        for(obsg in 1:5) {
            expect_equal(test_emit("do", obsg, trueg, err, fgen, FALSE, FALSE, 20), expected[obsg])
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE,  TRUE, 20), expected[obsg])
        }
    }
    # truth = B-: BC (5), BF (17), CE (13), EF (20), CH (31), FH (34)
    expected <- log(c(err,1,1-err,err,1-err))
    for(trueg in c(5,17,13,20,31,34)) {
        for(obsg in 1:5) {
            expect_equal(test_emit("do", obsg, trueg, err, fgen, FALSE, FALSE, 20), expected[obsg])
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE,  TRUE, 20), expected[obsg])
        }
    }

    # male X: treat het as missing
    # truth = hemA: A (1+36), D (4+36), G (7+36)
    expected <- log(c(1-err, 1, err, 1-err, err))
    for(trueg in 36+c(1,4,7))
        for(obsg in 1:5)
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE, FALSE, 20), expected[obsg])
    # truth = hemB: BB (2+36), E (5+36), H (8+36)
    expected <- log(c(err, 1, 1-err, err, 1-err))
    for(trueg in 36+c(2,5,8))
        for(obsg in 1:5)
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE, FALSE, 20), expected[obsg])
    # truth = missing: C (3+36), F (6+36)
    expected <- rep(0,5)
    for(trueg in 36+c(3,6))
        for(obsg in 1:5)
            expect_equal(test_emit("do", obsg, trueg, err, fgen,  TRUE, FALSE, 20), expected[obsg])


})

test_that("DO step works", {

    skip_on_cran()

    ng <- 36
    trmat <- matrix(nrow=ng, ncol=ng)
    # autosome
    for(rf in c(0.01, 0.001, 0.0001)) {
        for(ngen in c(6, 12, 50)) {

            for(gl in 1:ng)
                for(gr in 1:ng)
                    trmat[gl,gr] <- test_step("do", gl, gr, rf, FALSE, FALSE, ngen)

            # no missing values
            expect_true(all(!is.na(trmat)))
            # all in (-Inf, 0]
            expect_true(all(trmat > -Inf & trmat <= 0))
            # rows sum to 1
            expect_equal( rowSums(exp(trmat)), rep(1, ng))

            # maximum value on the diagonal
            expect_equal( apply(trmat, 1, which.max), 1:ng)
        }
    }

    # female X
    for(rf in c(0.01, 0.001, 0.0001)) {
        for(ngen in c(6, 12, 50)) {

            for(gl in 1:ng)
                for(gr in 1:ng)
                    trmat[gl,gr] <- test_step("do", gl, gr, rf, TRUE, TRUE, ngen)

            # no missing values
            expect_true(all(!is.na(trmat)))
            # all in (-Inf, 0]
            expect_true(all(trmat > -Inf & trmat <= 0))
            # rows sum to 1
            expect_equal( rowSums(exp(trmat)), rep(1, ng))

            # maximum value on the diagonal
            expect_equal( apply(trmat, 1, which.max), 1:ng)
        }
    }

    # male X
    ng <- 8
    trmat <- matrix(nrow=ng, ncol=ng)
    for(rf in c(0.01, 0.001, 0.0001)) {
        for(ngen in c(6, 12, 50)) {

            for(gl in 1:ng)
                for(gr in 1:ng)
                    trmat[gl,gr] <- test_step("do", 36+gl, 36+gr, rf, TRUE, FALSE, ngen)

            # no missing values
            expect_true(all(!is.na(trmat)))
            # all in (-Inf, 0]
            expect_true(all(trmat > -Inf & trmat <= 0))
            # rows sum to 1
            expect_equal( rowSums(exp(trmat)), rep(1, ng))

            # maximum value on the diagonal
            expect_equal( apply(trmat, 1, which.max), 1:ng)
        }
    }

})

test_that("geno_names works", {
    auto <- c("AA", "AB", "BB", "AC", "BC", "CC", "AD", "BD", "CD", "DD",
              "AE", "BE", "CE", "DE", "EE", "AF", "BF", "CF", "DF", "EF", "FF",
              "AG", "BG", "CG", "DG", "EG", "FG", "GG", "AH", "BH", "CH", "DH",
              "EH", "FH", "GH", "HH")
    X <- c(auto, paste0(LETTERS[1:8], "Y"))

    expect_equal(geno_names("do", LETTERS[1:8], FALSE), auto)
    expect_equal(geno_names("do", LETTERS[1:8], TRUE), X)
})

test_that("nrec works", {

    skip_on_cran()

    # X chr male
    for(i in 36+(1:8)) {
        for(j in 36+(1:8)) {
            expect_equal(test_nrec("do", i, j, TRUE, FALSE, 0), as.numeric(i!=j))
            # hs should be the same, too
            expect_equal(test_nrec("hs", i, j, TRUE, FALSE, 0), as.numeric(i!=j))
        }
    }

    # autosome or X chr female
    g <- sapply(1:36, mpp_decode_geno, 8, FALSE)
    expected <- resultA <- resultX <- matrix(ncol=ncol(g), nrow=ncol(g))
    resultAhs <- resultXhs <- resultA
    for(i in 1:ncol(g)) {
        for(j in 1:ncol(g)) {
            if((g[1,i] == g[1,j] && g[2,i]==g[2,j]) ||
               (g[1,i] == g[2,j] && g[2,i]==g[1,j])) expected[i,j] <- 0
            else if(g[1,i] != g[1,j] && g[2,i]!=g[2,j] &&
                    g[1,i] != g[2,j] && g[2,i]!=g[1,j]) expected[i,j] <- 2
            else expected[i,j] <- 1

            resultA[i,j] <- test_nrec("do", i, j, FALSE, FALSE, 0)
            resultX[i,j] <- test_nrec("do", i, j, TRUE, TRUE, 0)
            resultAhs[i,j] <- test_nrec("hs", i, j, FALSE, FALSE, 0)
            resultXhs[i,j] <- test_nrec("hs", i, j, TRUE, TRUE, 0)
        }
    }
    expect_equal(resultA, expected)
    expect_equal(resultX, expected)
    expect_equal(resultAhs, expected)
    expect_equal(resultXhs, expected)
})
