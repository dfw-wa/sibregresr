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
#' The penalized complexity model puts penalties on the mean of the coefficients \eqn{\beta_t} for each year \eqn{t} and the standard deviation of the steps in the random walk. So if the coefficients are:
#'
#' \deqn{\beta_t = \beta_{t-1} + \omega_t \\ \omega_t \sim \mathcal{N}(0,\sigma)}
#'
#' this model puts exponential-gamma penalties on both \eqn{\bar{\beta}} and \eqn{\sigma}.
#'
#' \deqn{\bar{\beta},~\sigma \sim \text{exp}(\lambda) \\ \lambda \sim \text{Gamma}(\text{Shape}=10,~\text{Scale}=1)}
#'
#' Additionally, \eqn{0.05*\text{log}(\bar{\beta}, \sigma)} for all \eqn{\bar{\beta}}s and \eqn{\sigma}s is added to the log-likelihood to keep their values from shrinking so small as to cause numerical problems during optimization.

#' @return a list with two components: the fitted TMB model object, which has the NLL and the linear predictors in the report(), as well as the outfut from the call to TMBhelper::fit_tmb(), which is used to optimize the model.
#' @export
#'
pen_dlm<-function(dat,form=stats::formula("y~x"),
                  regu=c(.05,.05),gamma_shape=10,gamma_scale=1){

options(na.action = "na.pass")
mod_mat<-stats::model.matrix(form,data=dat)

n_coefs<-ncol(mod_mat)

n_years<-nrow(mod_mat)

data<-list(
  y=utils::head(dat,-1)$y,
  mod_mat=mod_mat,
  n_coefs=n_coefs,
  n_years=n_years
)


#parameters


params<-list(

log_exp_rate= (numeric(2)+2),

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
exp_rate<-exp(log_exp_rate)
#
nll<-0
#
coefs<-matrix(0,n_years,n_coefs)
coefs[1,]<-coef_inits
for(i in 2:n_years){
  coefs[i,]<-coefs[i-1,]+coef_inovations[i-1,]
}


for ( i in 1:n_coefs){
  nll<- nll - sum(RTMB::dnorm(coef_inovations[,i],0,innov_sd[i],log=TRUE)) # penalize year-to-year variations
}

coef_means<-(RTMB::apply(coefs,2,mean))
nll<-nll - sum(RTMB::dnorm(coef_means,0,mean_sd,log=TRUE)) #penalize mean of coefficients across years



nll<-nll - sum(RTMB::dexp(mean_sd,exp_rate[1],log=TRUE))- sum(regu[1]*mean_log_sd)
nll<-nll - sum(RTMB::dexp(innov_sd,exp_rate[2],log=TRUE))- sum (regu[2]*innov_log_sd)

nll<-nll - sum(RTMB::dgamma(x=exp_rate,shape=gamma_shape,scale=gamma_scale,log=TRUE))

pred<-RTMB::apply(coefs*mod_mat,1,sum)

nll<- nll-sum(RTMB::dnorm((y),(utils::head(pred,-1)),resid_sd,log=TRUE))
RTMB::REPORT(pred)
RTMB::REPORT(nll)
nll
}


obj <- RTMB::MakeADFun(f, params,random=c("coef_inovations","coef_inits"),silent =TRUE)


#optimize

parameter_estimates = stats::nlminb(
  start = obj$par,
  objective = obj$fn,
  gradient = obj$gr,
  control =  list(eval.max = 1e4,
                  iter.max = 1e4,
                  trace = 0)
)


# Re-run to further decrease final gradient
parameter_estimates = stats::nlminb(
  start = parameter_estimates$par,
  objective = obj$fn,
  gradient = obj$gr,
  control =  list(eval.max = 1e4,
                  iter.max = 1e4,
                  trace = 0)
)

## Run some Newton steps
for (i in 1:2) {
  g = as.numeric(obj$gr(parameter_estimates$par))
  h = stats::optimHess(parameter_estimates$par, fn = obj$fn, gr = obj$gr)
  parameter_estimates$par = parameter_estimates$par - solve(h, g)
  parameter_estimates$objective = obj$fn(parameter_estimates$par)
}


return(list(
  obj=obj
))
}

