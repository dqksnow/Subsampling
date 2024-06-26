#' Optimal Subsampling Methods for Quantile Models
#' @export
#' @details
#' Additional details... briefly introduce the idea.
#'
#' @param formula An object of class "formula" which describes the model to be
#'  fitted.
#' @param data A data frame containing the variables in the model. Usually it
#' contains a response vector and a design matrix.
#'     The binary response vector that takes the value of 0 or 1, where 1 means
#'      the event occurred.
#'     The design matrix contains predictor variables. A column representing
#'     the intercept term with all 1's will be automatically added.
#' @param tau The quantile.
#' @param n.plt The pilot subsample size (the first-step subsample size).
#' These samples will be used to estimate the pilot estimator.
#' @param n.ssp The expected optimal subsample size (the second-step subsample
#' size).
#' @param B TBD
#' @param boot TBD
#' @param criterion The criterion of optimal subsampling probabilities.
#' @param sampling.method The sampling method for drawing the optimal subsample.
#' @param likelihood The type of the maximum likelihood function used to
#' calculate the optimal subsampling estimator.
#'
#' @return
#' \describe{
#'   \item{model.call}{the model}
#'   \item{beta.plt}{pilot estimator}
#'   \item{beta.ssp}{optimal subsample estimator}
#'   \item{est.cov.ssp}{covariance matrix of \code{beta.ssp}}
#'   \item{index.plt}{index of pilot subsample}
#'   \item{index.ssp}{index of optimal subsample}
#' }
#'
#' @examples
#' #quantile regression
#' set.seed(1)
#' N <- 1e6
#' B <- 10
#' tau <- 0.75
#' beta.true <- rep(1, 7)
#' d <- length(beta.true) - 1
#' corr  <- 0.5
#' sigmax  <- matrix(0, d, d)
#' for (i in 1:d) for (j in 1:d) sigmax[i, j] <- corr^(abs(i-j))
#' X <- MASS::mvrnorm(N, rep(0, d), sigmax)
#' err <- rnorm(N, 0, 1) - qnorm(tau)
#' Y <- beta.true[1] + X %*% beta.true[-1] + 
#' err * rowMeans(abs(X))
#' data <- as.data.frame(cbind(Y, X))
#' formula <- Y ~ X
#' n.plt <- 1000
#' n.ssp <- 1000
#' optL.results <- subsampling.quantile(formula,data,tau = tau,n.plt = n.plt,
#' n.ssp = n.ssp,B,boot = TRUE,criterion = 'OptL',
#' sampling.method = 'WithReplacement',likelihood = 'Weighted')
#' summary(optL.results)
#' uni.results <- subsampling.quantile(formula,data,tau = tau,n.plt = n.plt,
#' n.ssp = n.ssp,B,boot = TRUE,criterion = 'Uniform',
#' sampling.method = 'WithReplacement', likelihood = 'Weighted')
#' summary(uni.results)

subsampling.quantile <- function(formula,
                                 data,
                                 tau,
                                 n.plt,
                                 n.ssp,
                                 B = 10,
                                 boot = TRUE,
                                 criterion = c('OptL', 'Uniform'),
                                 sampling.method = c('WithReplacement',
                                                     'Poisson'),
                                 likelihood = c('Weighted')
                                 ) {
  
  model.call <- match.call()
  mf <- model.frame(formula, data)
  Y <- model.response(mf, "numeric")
  X <- model.matrix(formula, mf)
  colnames(X)[1] <- "intercept"
  N <- nrow(X)
  d <- ncol(X)
  
  criterion <- match.arg(criterion)
  sampling.method <- match.arg(sampling.method)
  likelihood <- match.arg(likelihood)
  
  ## check inputs
  if (n.ssp * B > 0.1 * N) {
    warning("The total subsample size n.ssp*B exceeds the recommended maximum
    value (10% of full sample size).")
  }
  
  if (boot == FALSE | B == 1){
    n.ssp <- n.ssp * B
    B <- 1
    boot <- FALSE
  }
  
  ## create a list to store variables
  inputs <- list(X = X, Y = Y, tau = tau, N = N, d = d,
                 n.plt = n.plt, n.ssp = n.ssp, B = B, boot = boot, 
                 criterion = criterion, sampling.method = sampling.method,
                 likelihood = likelihood
                 )
  
  if (criterion %in% c("OptL")) {
    
    ## pilot step
    plt.results <- quantile.plt.estimation(inputs)
    beta.plt <- plt.results$beta.plt
    Ie.full <- plt.results$Ie.full
    index.plt <- plt.results$index.plt
    
    ## subsampling and boot step
    ssp.results <- quantile.ssp.estimation(inputs,
                                           Ie.full = Ie.full,
                                           index.plt = index.plt
                                           )
    Betas.ssp <- ssp.results$Betas.ssp
    beta.ssp <- ssp.results$beta.ssp
    est.cov.ssp <- ssp.results$est.cov.ssp
    index.ssp <- ssp.results$index.ssp
    
    results <- list(model.call = model.call,
                    beta.plt = beta.plt,
                    beta = beta.ssp,
                    est.cov = est.cov.ssp,
                    index.plt = index.plt,
                    index = index.ssp,
                    N = N,
                    subsample.size.expect = c(n.ssp, B)
                    )
    class(results) <- c("subsampling.quantile", "list")
    return(results)
  } else if (criterion == "Uniform"){
    ### subsampling and boot step
    uni.results <- quantile.ssp.estimation(inputs)
    Betas.uni <- uni.results$Betas.ssp
    beta.uni <- uni.results$beta.ssp
    est.cov.uni <- uni.results$est.cov.ssp
    index.uni <- uni.results$index.ssp
    results <- list(model.call = model.call,
                    beta.plt = NA,
                    beta = beta.uni,
                    est.cov = est.cov.uni,
                    index = index.uni,
                    N = N,
                    subsample.size.expect = c(n.ssp, B)
                    )
    class(results) <- c("subsampling.quantile", "list")
    return(results)
  }
}
###############################################################################