% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/general_glm_main_function.R
\name{glm.subsampling}
\alias{glm.subsampling}
\title{Optimal Subsampling Methods for Generalized Linear Models}
\usage{
glm.subsampling(
  formula,
  data,
  n.plt,
  n.ssp,
  family = c("binomial", "poisson", "gamma"),
  criterion = c("OptL", "OptA", "LCC", "Uniform"),
  sampling.method = c("Poisson", "WithReplacement"),
  likelihood = c("LogOddsCorrection", "Weighted"),
  alpha = 0.1,
  b = 2
)
}
\arguments{
\item{formula}{An object of class "formula" which describes the model to be
fitted.}

\item{data}{A data frame containing the variables in the model. Usually it
contains a response vector and a design matrix.
The binary response vector that takes the value of 0 or 1, where 1 means
the event occurred.
The design matrix contains predictor variables. A column representing
the intercept term with all 1's will be automatically added.}

\item{n.plt}{The pilot subsample size (the first-step subsample size).
These samples will be used to estimate the pilot estimator as well as to
estimate the optimal sampling probability.}

\item{n.ssp}{The expected optimal subsample size (the second-step subsample
size).}

\item{family}{defalut = 'binomial'.}

\item{criterion}{The criterion of optimal subsampling probabilities,
currently there are three choices \code{OptA}, \code{OptL}, and \code{LCC}.}

\item{sampling.method}{The sampling method for drawing the optimal subsample,
currently there are two choices \code{WithReplacement} and \code{Poisson}.}

\item{likelihood}{The type of the maximum likelihood function used to
calculate the optimal subsampling estimator, currently there are two choices
\code{Weighted} and \code{LogOddsCorrection}.}

\item{alpha}{Mixture proportions of optimal subsampling probability and
uniform subsampling probability. Default = 0.1.}

\item{b}{This parameter controls the upper threshold for optimal subsampling
probabilities.}
}
\value{
\describe{
\item{beta.plt}{pilot estimator}
\item{beta.ssp}{optimal subsample estimator}
\item{beta.cmb}{combined estimator of \code{beta.plt} and \code{beta.ssp}}
\item{var.ssp}{covariance matrix of \code{beta.ssp}}
\item{var.cmb}{covariance matrix of \code{beta.cmb}}
\item{index.plt}{index of pilot subsample}
\item{index.ssp}{index of optimal subsample}
}
}
\description{
Optimal Subsampling Methods for Generalized Linear Models
}
\details{
Additional details... briefly introduce the idea.
}
\examples{
# logistic regression
set.seed(1)
N <- 1e4
beta0 <- rep(-0.5, 7)
d <- length(beta0) - 1
X <- matrix(0, N, d)
generate_rexp <- function(x) x <- rexp(N, rate = 2)
X <- apply(X, 2, generate_rexp)
Y <- as.integer(rbinom(N, 1, 1 - 1 / (1 + exp(beta0[1] + X \%*\% beta0[-1]))))
print(paste('N: ', N))
print(paste('sum(Y): ', sum(Y)))
data <- as.data.frame(cbind(Y, X))
formula <- Y ~ .
n.plt <- 500
n.ssp <- 1000
subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'binomial', criterion = "OptL", sampling.method = 'Poisson',
likelihood = "LogOddsCorrection")
summary(subsampling.results)
subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'binomial', criterion = "OptL",
sampling.method = 'WithReplacement', likelihood = "Weighted")
summary(subsampling.results)
Uni.subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'binomial', criterion = 'Uniform')
summary(Uni.subsampling.results)
############################################################################
# poisson regression
set.seed(1)
N <-  1e4
beta0 <- rep(0.5, 7)
d <- length(beta0) - 1
X <- matrix(runif(N * d), N, d)
epsilon <- runif(N)
lambda <- exp(beta0[1] + X \%*\% beta0[-1])
Y <- rpois(N, lambda)
hist(Y)
data <- as.data.frame(cbind(Y, X))
formula <- Y ~ .
n.plt <- 200
n.ssp <- 600
subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'poisson', criterion = "OptL", sampling.method = 'Poisson',
likelihood = "Weighted")
summary(subsampling.results)
subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'poisson', criterion = "OptL", sampling.method = 'WithReplacement',
likelihood = "Weighted")
summary(subsampling.results)
Uni.subsampling.results <- glm.subsampling(formula, data, n.plt, n.ssp,
family = 'poisson', criterion = 'Uniform')
summary(Uni.subsampling.results)
}
