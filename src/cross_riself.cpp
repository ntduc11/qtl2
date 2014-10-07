// RI selfing HMM functions

#include <math.h>
#include <Rcpp.h>
#include "cross.h"
#include "cross_riself.h"

enum gen {AA=1, BB=2};

bool RISELF::check_geno(int gen, bool is_observed_value,
                        bool ignored1, bool ignored2, IntegerVector ignored3)
{
    if(is_observed_value && gen==0) return true;

    if(gen==AA || gen==BB) return(true);

    throw std::range_error("invalid genotype");
    return false; // can't get here
}

double RISELF::init(int true_gen, bool ignored1, bool ignored2,
                    IntegerVector ignored3)
{
    check_geno(true_gen, false, ignored1, ignored2, ignored3);

    return -log(2.0);
}

double RISELF::emit(int obs_gen, int true_gen, double error_prob,
                    bool ignored1, bool ignored2, IntegerVector ignored3)
{
    check_geno(obs_gen, true, ignored1, ignored2, ignored3);
    check_geno(true_gen, false, ignored1, ignored2, ignored3);

    if(obs_gen==0) return 0.0; // missing

    if(obs_gen == true_gen) return log(1.0 - error_prob);
    else return log(error_prob);
}

double RISELF::step(int gen_left, int gen_right, double rec_frac,
                    bool ignored1, bool ignored2, IntegerVector ignored3)
{
    check_geno(gen_left, false, ignored1, ignored2, ignored3);
    check_geno(gen_right, false, ignored1, ignored2, ignored3);

    const double R = 2.0*rec_frac/(1+2.0*rec_frac);

    if(gen_left == gen_right) return log(1.0-R);
    else return log(R);
}

int RISELF::ngen(bool ignored1)
{
    return 2;
}

double RISELF::nrec(int gen_left, int gen_right,
                    bool ignored1, bool ignored2, IntegerVector ignored3)
{
    check_geno(gen_left, false, ignored1, ignored2, ignored3);
    check_geno(gen_right, false, ignored1, ignored2, ignored3);

    if(gen_left == gen_right) return 0.0;
    else return 1.0;
}

double RISELF::est_rec_frac(NumericMatrix gamma, bool is_X_chr)
{
    int n_gen = gamma.rows();
    int n_gen_sq = n_gen*n_gen;

    double denom = 0.0;
    for(int i=0; i<n_gen_sq; i++) denom += gamma[i];

    double diagsum = 0.0;
    for(int i=0; i<n_gen; i++) diagsum += gamma(i,i);

    double R = 1.0 - diagsum/denom;

    return 0.5*R/(1-R);
}
