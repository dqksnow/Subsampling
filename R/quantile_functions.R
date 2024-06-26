###############################################################################
quantile.plt.estimation <- function(inputs){
  N <- inputs$N
  n.plt <- inputs$n.plt
  tau <- inputs$tau
  
  index.plt <- sample(N, n.plt, replace = TRUE)
  results <- quantreg::rq(inputs$Y[index.plt] ~ inputs$X[index.plt, ] - 1,
                          tau = tau)
  beta.plt <- results$coefficients
  Ie.full <- (c(inputs$Y - inputs$X %*% beta.plt) < 0)
  return(
    list(
      beta.plt = beta.plt,
      Ie.full = Ie.full,
      index.plt = index.plt
    )
  )
}
###############################################################################
quantile.sampling <- function(N, n.ssp, p.ssp, tau, sampling.method, criterion){
  if (sampling.method == "Poisson"){
    if (criterion == "Uniform") {
      index.ssp <- which(runif(N) <= n.ssp/N)
    } else {
      index.ssp <- which(runif(N) <= p.ssp)
    }
  } else if (sampling.method == "WithReplacement") {
    if (criterion == "Uniform") {
      index.ssp <- sample(1:N, n.ssp, replace = TRUE)
    } else {
      index.ssp <- sample(1:N, n.ssp, replace = TRUE, prob = p.ssp)
    }
  }
  return(index.ssp)
}
###############################################################################
quantile.ssp.estimation <- function(inputs,
                                    Ie.full = NA,
                                    index.plt = NA
                                    ) {
  N <- inputs$N
  n.plt <- inputs$n.plt
  n.ssp <- inputs$n.ssp
  tau <- inputs$tau
  d <- inputs$d
  B <- inputs$B
  criterion <- inputs$criterion
  sampling.method <- inputs$sampling.method
  boot <- inputs$boot
  
  
  if (criterion == "Uniform"){
    p.ssp <- NA
  } else if (criterion %in% c("OptL")) {
    p.ssp <- abs(tau - Ie.full) * sqrt(rowSums(inputs$X^2))
    if (sampling.method == "Poisson"){
      dm <- N * sum(p.ssp[index.plt]) / n.plt
      p.ssp <- n.ssp * p.ssp / dm
    } else if (sampling.method == "WithReplacement") {
      p.ssp <- p.ssp / sum(p.ssp)
    }
  }
  
  if (boot == TRUE) {
    Betas.ssp <- matrix(NA, nrow = d, ncol = B)
    Index.ssp <- list()
    if (sampling.method == "Poisson"){
      if (criterion == "Uniform") {
        index.ssp <- which(runif(N) <= B*n.ssp/N)
      } else {
        index.ssp <- which(runif(N) <= B*p.ssp)
      }
      each.ssp.length <- length(index.ssp) %/% B
      remainder <- length(index.ssp) %% B
      if (remainder > 0) { # handle remainders
        each.ssp <- split(index.ssp, c(rep(1:B, each = each.ssp.length),
                                       rep(1:remainder, each = 1)))
      } else {
        each.ssp <- split(index.ssp, rep(1:B, each = each.ssp.length))
      }
      for(i in 1:B){
        if (criterion == "Uniform") {
          fit <- quantreg::rq(inputs$Y[each.ssp[[i]]] ~ 
                                inputs$X[each.ssp[[i]], ] - 1,
                              tau = tau)
        } else {
          fit <- quantreg::rq(inputs$Y[each.ssp[[i]]] ~ 
                                inputs$X[each.ssp[[i]], ] - 1,
                              tau = tau,
                              weights = 1 / pmin(p.ssp[each.ssp[[i]]], 1))
        }
        Betas.ssp[, i] <- fit$coefficients
        Index.ssp[[i]] <- each.ssp[[i]]
      }
    } else if (sampling.method == "WithReplacement") {
      for(i in 1:B){
        index.ssp <- quantile.sampling(N, n.ssp, p.ssp, tau,
                                       sampling.method, criterion)
        if (criterion == "Uniform") {
          fit <- quantreg::rq(inputs$Y[index.ssp] ~ inputs$X[index.ssp, ] - 1,
                              tau = tau)
        } else {
          fit <- quantreg::rq(inputs$Y[index.ssp] ~ inputs$X[index.ssp, ] - 1,
                              tau = tau,
                              weights = 1 / pmin(p.ssp[index.ssp], 1))
        }
        Betas.ssp[, i] <- fit$coefficients
        Index.ssp[[i]] <- index.ssp
      }
    }
    beta.ssp.mean <- rowMeans(Betas.ssp)
  } else if (boot == FALSE) {
    index.ssp <- quantile.sampling(N, n.ssp, p.ssp, tau,
                                   sampling.method, criterion)
    if (criterion == "Uniform") {
      fit <- quantreg::rq(inputs$Y[index.ssp] ~ inputs$X[index.ssp, ] - 1,
                          tau = tau)
    } else {
      fit <- quantreg::rq(inputs$Y[index.ssp] ~ inputs$X[index.ssp, ] - 1,
                          tau = tau,
                          weights=1 / pmin(p.ssp[index.ssp], 1))
    }
    beta.ssp <- fit$coefficients
  }
  
  ## return results
  if (boot == TRUE) {
    Beta.ssp.centered <- Betas.ssp - beta.ssp.mean
    mean.outer.prod <- Beta.ssp.centered %*% t(Beta.ssp.centered)
    if(sampling.method == "Poisson"){
      est.cov.ssp <- mean.outer.prod / (B*(B-1))
    } else {
      r.ef <- ifelse(criterion == "Uniform",
                     1 - (n.ssp*B-1)/N/2,
                     1 - (sum(p.ssp^2) / n.ssp^2) * (n.ssp*B - 1) / 2)
      est.cov.ssp <- mean.outer.prod / (r.ef * B*(B-1))
    }
    return(list(Betas.ssp = Betas.ssp,
                beta.ssp = beta.ssp.mean,
                est.cov.ssp = est.cov.ssp,
                index.ssp = Index.ssp
                )
           )
  } else if (boot == FALSE) {
    return(list(Betas.ssp = NA,
                beta.ssp = beta.ssp,
                est.cov.ssp = NA,
                index.ssp = index.ssp
                )
           )
  }
}

###############################################################################
#' Main results summary
#'
#' @param object A list object output by the main function, which contains the
#'  results of the estimation of the parameters, the estimation of the
#'  covariance matrix, subsample index, etc.
#'
#' @return A data frame will be printed.
#' @export
#'
#' @examples
#' #logistic regression
#' set.seed(1)
summary.subsampling.quantile <- function(object) {
  coef <- object$beta
  se <- sqrt(diag(object$est.cov))
  N <- object$N
  cat("Model Summary\n\n")
  cat("\nCall:\n")
  cat("\n")
  print(object$model.call)
  cat("\n")
  cat("Subsample Size:\n")
  cat("\n")
  cat("Coefficients:\n")
  cat("\n")
  coef_table <- data.frame(
    Estimate = round(coef, digits = 4),
    `Std. Error` = round(se, digits = 4),
    `z value` = round(coef / se, digits = 4),
    `Pr(>|z|)` = format.p.values(2 * (1 - pnorm(abs(coef / se))),
                                 threshold = 0.0001),
    check.names = FALSE
  )
  rownames(coef_table) <- names(coef)
  print(coef_table)
  # Add more summary information as needed
}
