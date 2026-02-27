#' penalized DLM in RTMB
#'
#' @description
#' function to fit a penalized dynamic linear regression model.
#'
#'
#' @param dat dataframe with response and predictors
#' @param form formula specifying linear predictor
#' @param regu to avoid the standard deviations shrinking too small and running into numerical issues, the log of the standard deviation multiplied be these values are added to the log-likelihood (subtracted from the negative log-likelihood). Defaults are .05 and .05 for the penalties on the mean of the coefficients and the year-to-year variability.
#' @param gamma_shape shape paramter for the gamma prior on the expential distributions rate paramters.
#' @param gamma_scale scale paramter for the gamma prior on the expential distributions rate paramters.
#'
#'@description
#' The penalized complexity model puts penalties on the across-year means \eqn{\bar{\beta}} of each coefficient \eqn{\beta_t} for each year \eqn{t}, and the standard deviation of the steps in the random walk. So if the coefficients are:
#'
#' \deqn{\beta_t = \beta_{t-1} + \omega_t \\ \omega_t \sim \mathcal{N}(0,\sigma)}
#'
#' \deqn{\bar{\beta}\sim \mathcal{N}(0,\tau)}
#'
#' This model puts exponential-gamma penalties on all $\tau$ and $\sigma$ parameters, for which there is a unique parameter for each predictor in the model:
#'
#' \deqn{\tau,~\sigma \sim \text{exp}(\lambda) \\ \lambda \sim \text{Gamma}(\text{Shape}=10,~\text{Scale}=1)}
#'
#' where two unique \eqn{\lambda} parameters are fit for every predictor in the model.
#'
#' Additionally, \eqn{0.05*\text{log}(\tau, \sigma)} for all \eqn{\tau}s and \eqn{\sigma}s is added to the log-likelihood to keep their values from shrinking so small as to cause numerical problems during optimization.

#' @return a list with two components: the fitted TMB model object, which has the NLL and the linear predictors in the report(), as well as the output from the call to TMBhelper::fit_tmb(), which is used to optimize the model.
#' @export
#'
pen_dlm<-function(dat,form=y~x,
                  regu=c(.01,.01),gamma_shape=10,gamma_scale=1,exp_rate=c(1,1)){



options(na.action = "na.pass")
mod_mat<-stats::model.matrix(form,data=dat)

missing_ind<-which(is.na(mod_mat))


n_coefs<-ncol(mod_mat)

n_years<-nrow(mod_mat)

data<-list(
  y=utils::head(dat,-1)$y,
  mod_mat=mod_mat,
  n_coefs=n_coefs,
  n_years=n_years,
  exp_rate=exp_rate,
  missing_ind=missing_ind
)


#parameters


params<-list(
  missing_cov=numeric(length(missing_ind))+.05,
# log_exp_rate= (numeric(2)+2),

coef_inits=numeric(n_coefs)+1,

coef_inovations=matrix(.05,n_years-1,n_coefs),

mean_log_sd = numeric(n_coefs),

innov_log_sd = numeric(n_coefs),

resid_log_sd = 0
)


#likelihood
f <- function(parms) {
  "[<-" <- RTMB::ADoverload("[<-")
  RTMB::getAll(data, parms, warn=FALSE)


mean_sd<-exp(mean_log_sd)
innov_sd<-exp(innov_log_sd)
resid_sd<-exp(resid_log_sd)
# exp_rate<-exp(log_exp_rate)
#
nll<-0
#
coefs<-array(list(),c(n_years))
coefs[[1]]<-coef_inits
for(i in 2:n_years){
  coefs[[i]]<-coefs[[i-1]]+coef_inovations[i-1,]
}

## convert to normal array
coefs <- do.call("c",coefs)
dim(coefs) <- c(n_coefs,n_years)
coefs<-t(coefs)
RTMB::REPORT(coefs)

for ( i in 1:n_coefs){
  nll<- nll - sum(RTMB::dnorm(coef_inovations[,i],0,innov_sd[i],log=TRUE)) # penalize year-to-year variations
}

coef_means<-(RTMB::apply((coefs),2,mean))
nll<-nll - sum(RTMB::dnorm(coef_means,0,mean_sd,log=TRUE)) #penalize mean of coefficients across years



nll<-nll - sum(RTMB::dexp(mean_sd, exp_rate[1],log=TRUE))- sum(regu[1]*mean_log_sd)
nll<-nll - sum(RTMB::dexp(innov_sd, exp_rate[2],log=TRUE))- sum (regu[2]*innov_log_sd)

# nll<-nll - sum(RTMB::dgamma(x=exp_rate,shape=gamma_shape,scale=gamma_scale,log=TRUE))
mod_mat[missing_ind]<-missing_cov
nll<- nll-sum(RTMB::dnorm(missing_cov,0,1,log=TRUE))

pred<-RTMB::apply(coefs*mod_mat,1,sum)

nll<- nll-sum(RTMB::dnorm((y),(utils::head(pred,-1)),resid_sd,log=TRUE))
RTMB::REPORT(pred)
RTMB::REPORT(nll)

nll
}


obj <- RTMB::MakeADFun(f, params,random=c("coef_inovations","coef_inits","missing_cov"),silent =TRUE)


#optimize

parameter_estimates = stats::nlminb(
  start = obj$par,
  objective = obj$fn,
  gradient = obj$gr,
  control =  list(eval.max = 1e3,
                  iter.max = 1e3,
                  trace = 0)
)


# Re-run to further decrease final gradient
# parameter_estimates = stats::nlminb(
#   start = parameter_estimates$par,
#   objective = obj$fn,
#   gradient = obj$gr,
#   control =  list(eval.max = 1e4,
#                   iter.max = 1e4,
#                   trace = 0)
# )

## Run some Newton steps
# for (i in 1:2) {
#   g = as.numeric(obj$gr(parameter_estimates$par))
#   h = stats::optimHess(parameter_estimates$par, fn = obj$fn, gr = obj$gr)
#   parameter_estimates$par = parameter_estimates$par - solve(h, g)
#   parameter_estimates$objective = obj$fn(parameter_estimates$par)
# }


return(list(
  obj=obj
))
}



#' R2D2 penalized DLM in RTMB
#'
#' @description
#' function to fit a penalized dynamic linear regression model.
#'
#'
#' @param dat dataframe with response and predictors
#' @param form formula specifying linear predictor
#' @param regu to avoid the standard deviations shrinking too small and running into numerical issues, the log of the standard deviation multiplied be these values are added to the log-likelihood (subtracted from the negative log-likelihood). Defaults are .05 and .05 for the penalties on the mean of the coefficients and the year-to-year variability.
#' @param gamma_shape shape paramter for the gamma prior on the expential distributions rate paramters.
#' @param gamma_scale scale paramter for the gamma prior on the expential distributions rate paramters.
#'
#'@description
#' The penalized complexity model puts penalties on the across-year means \eqn{\bar{\beta}} of each coefficient \eqn{\beta_t} for each year \eqn{t}, and the standard deviation of the steps in the random walk. So if the coefficients are:
#'
#' \deqn{\beta_t = \beta_{t-1} + \omega_t \\ \omega_t \sim \mathcal{N}(0,\sigma)}
#'
#' \deqn{\bar{\beta}\sim \mathcal{N}(0,\tau)}
#'
#' This model puts exponential-gamma penalties on all $\tau$ and $\sigma$ parameters, for which there is a unique parameter for each predictor in the model:
#'
#' \deqn{\tau,~\sigma \sim \text{exp}(\lambda) \\ \lambda \sim \text{Gamma}(\text{Shape}=10,~\text{Scale}=1)}
#'
#' where two unique \eqn{\lambda} parameters are fit for every predictor in the model.
#'
#' Additionally, \eqn{0.05*\text{log}(\tau, \sigma)} for all \eqn{\tau}s and \eqn{\sigma}s is added to the log-likelihood to keep their values from shrinking so small as to cause numerical problems during optimization.

#' @return a list with two components: the fitted TMB model object, which has the NLL and the linear predictors in the report(), as well as the output from the call to TMBhelper::fit_tmb(), which is used to optimize the model.
#' @export
#'
r2d2_dlm<-function(dat,form=y~x,
                  alpha_dirichlet = NULL,#1 / p_cov,
                  scale_evol      = TRUE,
                  R2_a            = 0.5,
                  R2_b            = NULL,#p_cov / 2,
                  rho_a           = 3.0,
                  rho_b           = 2.0,
                  intercept_n_equiv = 3.0,       # intercept gets ~3 average-predictor-equivalents.
                  sd_init_intercept = 3.0      # vague prior on initial intercept level (change to 1 if standardize y
                  ){

  T_total <- nrow(dat)
  options(na.action = "na.pass")
  X_cov<-stats::model.matrix(form,data=dat)
  X_cov<-X_cov[,-1]

  X_cov <- scale(X_cov)  # standardize using all rows including forecast year
  #Should swtich to standardize using only the historical data and then apply the same centering/scaling to the forecast-year covariates, so the standardization isn't contaminated by the values we're trying to predict with.

  # Observed response: last year is NA (forecast target)
  y <- dat$y


  p_cov<-ncol(X_cov)

  if (is.null(alpha_dirichlet)) {
    alpha_dirichlet2 <- 1 / p_cov
  }else{
    alpha_dirichlet2<-alpha_dirichlet
  }

  if (is.null(R2_b)) {
    R2_b2 <- p_cov / 2
  }else{
    R2_b2<-R2_b
  }

  dat_mod <- list(
    y               = y,
    X_cov           = X_cov,
    alpha_dirichlet = alpha_dirichlet2,
    scale_evol      = scale_evol,
    R2_a            = R2_a,
    R2_b            = R2_b2,
    rho_a           = rho_a,
    rho_b           = rho_b,
    intercept_n_equiv = intercept_n_equiv,       # intercept gets ~3 average-predictor-equivalents.
    sd_init_intercept = sd_init_intercept      # vague prior on initial intercept level (change to 1 if standardize y)
  )


  nll_fn <- function(pars) {
    RTMB::getAll(pars, dat_mod)

    Tobs <- length(y)
    p    <- ncol(X_cov)

    # --- Transform parameters ---
    R2      <- RTMB::plogis(logit_R2)
    sigma_y <- exp(log_sigma_y)
    tau     <- sigma_y * sqrt(R2 / (1.0 - R2 + 1e-10))

    # Softmax for xi (log_xi_raw[1] fixed to 0 via map)
    log_xi_raw_stable <- log_xi_raw - max(log_xi_raw)
    xi <- exp(log_xi_raw_stable) / sum(exp(log_xi_raw_stable))

    # Inverse-logit for rho
    rho <- RTMB::plogis(logit_rho)

    # T_scale for evolution variance normalization
    # Use number of observed years, not total including forecast
    T_obs_count <- sum(!is.na(y))
    T_scale <- 1.0
    if (scale_evol) {
      T_scale <- max((T_obs_count - 1) / 2.0, 1.0)
    }

    # Intercept innovation SD (tied to tau)
    sd_evol_int <- tau * sqrt(intercept_n_equiv / (p * T_scale))

    nll <- 0.0

    # =================================================================
    # PRIORS AND JACOBIANS
    # =================================================================

    # (1) Beta prior on R2 + Jacobian for logit transform
    #     Combined: -a * log(R2) - b * log(1 - R2)
    nll <- nll - R2_a * log(R2 + 1e-15) -
      R2_b * log(1.0 - R2 + 1e-15)

    # (2) Dirichlet on xi + Jacobian for softmax transform
    #     Combined: -alpha * log(xi_j)
    for (j in 1:p) {
      nll <- nll - alpha_dirichlet * log(xi[j] + 1e-15)
    }

    # (3) Beta prior on rho + Jacobian for logit transform
    #     Combined: -rho_a * log(rho_j) - rho_b * log(1 - rho_j)
    for (j in 1:p) {
      nll <- nll - rho_a * log(rho[j] + 1e-15) -
        rho_b * log(1.0 - rho[j] + 1e-15)
    }

    # (4) Jacobian for log_sigma_y -> sigma_y
    nll <- nll - log_sigma_y

    # =================================================================
    # INTERCEPT (outside R2D2, but tied to tau)
    # =================================================================

    # (5a) Initial intercept: vague prior
    nll <- nll - RTMB::dnorm(beta_int[1], 0.0, sd_init_intercept, log = TRUE)

    # (5b) Intercept evolution
    for (t in 2:Tobs) {
      nll <- nll - RTMB::dnorm(beta_int[t], beta_int[t-1], sd_evol_int, log = TRUE)
    }

    # =================================================================
    # COVARIATE COEFFICIENTS (under R2D2)
    # =================================================================

    # (6) Initial state: beta_cov_{j,1} ~ N(0, sd_init_j)
    for (j in 1:p) {
      sd_init <- sqrt(rho[j] * xi[j] * tau^2 + 1e-10)
      nll <- nll - RTMB::dnorm(beta_cov[1, j], 0.0, sd_init, log = TRUE)
    }

    # (7) Covariate coefficient evolution
    for (j in 1:p) {
      sd_evol <- sqrt((1.0 - rho[j]) * xi[j] * tau^2 / T_scale + 1e-10)
      for (t in 2:Tobs) {
        nll <- nll - RTMB::dnorm(beta_cov[t, j], beta_cov[t-1, j], sd_evol, log = TRUE)
      }
    }

    # =================================================================
    # OBSERVATION LIKELIHOOD (skip NAs for forecast year)
    # =================================================================

    # (8) y_t ~ N(mu_t, sigma_y)
    for (t in 1:Tobs) {
      if (!is.na(y[t])) {
        mu <- beta_int[t] + sum(X_cov[t, ] * beta_cov[t, ])
        nll <- nll - RTMB::dnorm(y[t], mu, sigma_y, log = TRUE)
      }
    }

    # =================================================================
    # FORECAST AND REPORTING
    # =================================================================

    # Forecast: linear predictor for the last (NA) year
    mu_forecast <- beta_int[Tobs] + sum(X_cov[Tobs, ] * beta_cov[Tobs, ])

    RTMB::ADREPORT(R2)
    RTMB::ADREPORT(tau)
    RTMB::ADREPORT(sigma_y)
    RTMB::ADREPORT(xi)
    RTMB::ADREPORT(rho)
    RTMB::ADREPORT(sd_evol_int)
    RTMB::ADREPORT(mu_forecast)
    RTMB::ADREPORT(beta_int)
    RTMB::ADREPORT(beta_cov)
    RTMB::REPORT(mu_forecast)
    RTMB::REPORT(nll)

    return(nll)
  }

  # ===========================================================================
  # 3. Set up parameters and fit
  # ===========================================================================

  pars <- list(
    logit_R2    = 0,                           # R2 = 0.5
    log_sigma_y = log(sd(y, na.rm = TRUE)),
    log_xi_raw  = rep(0, p_cov),              # first element fixed via map
    logit_rho   = rep(0.5, p_cov),            # rho ~ 0.62
    beta_int    = rep(0, T_total),             # intercept random effects
    beta_cov    = matrix(0, T_total, p_cov)    # covariate coefficient random effects
  )

  # Fix first element of log_xi_raw for simplex identifiability
  xi_map <- 1:p_cov
  xi_map[1] <- NA
  map_list <- list(
    log_xi_raw = as.factor(xi_map)
  )

  obj <- RTMB::MakeADFun(
    func       = nll_fn,
    parameters = pars,
    random     = c("beta_int", "beta_cov"),
    map        = map_list,
    silent     = TRUE
  )

  # --- Optimization pass 1 ---
  cat("=== Optimization pass 1 (nlminb) ===\n")
  opt1 <- nlminb(
    start     = obj$par,
    objective = obj$fn,
    gradient  = obj$gr,
    control   = list(iter.max = 1000, eval.max = 2000)
  )
  cat("  Message:", opt1$message, "\n")
  cat("  NLL:", opt1$objective, "\n")

  # --- Optimization pass 2 ---
  cat("\n=== Optimization pass 2 (nlminb from pass 1) ===\n")
  opt2 <- nlminb(
    start     = opt1$par,
    objective = obj$fn,
    gradient  = obj$gr,
    control   = list(iter.max = 1000, eval.max = 2000)
  )
  cat("  Message:", opt2$message, "\n")
  cat("  NLL:", opt2$objective, "\n")
  cat("  NLL change:", opt2$objective - opt1$objective, "\n")

  # --- Optimization pass 3 (BFGS) ---
  cat("\n=== Optimization pass 3 (BFGS) ===\n")
  opt3 <- optim(
    par     = opt2$par,
    fn      = obj$fn,
    gr      = obj$gr,
    method  = "BFGS",
    control = list(maxit = 1000)
  )
  cat("  Convergence:", opt3$convergence, "(0 = success)\n")
  cat("  NLL:", opt3$value, "\n")
  cat("  NLL change:", opt3$value - opt2$objective, "\n")

  # Re-run to further decrease final gradient
  # parameter_estimates = stats::nlminb(
  #   start = parameter_estimates$par,
  #   objective = obj$fn,
  #   gradient = obj$gr,
  #   control =  list(eval.max = 1e4,
  #                   iter.max = 1e4,
  #                   trace = 0)
  # )

  ## Run some Newton steps
  # for (i in 1:2) {
  #   g = as.numeric(obj$gr(parameter_estimates$par))
  #   h = stats::optimHess(parameter_estimates$par, fn = obj$fn, gr = obj$gr)
  #   parameter_estimates$par = parameter_estimates$par - solve(h, g)
  #   parameter_estimates$objective = obj$fn(parameter_estimates$par)
  # }


  return(list(
    obj=obj
  ))
}




