


#' penalized DLM in RTMB
#'
#' @param form formula specifying linear predictor
#' @param exp_pen rate parameters for the exponential penalties on the standard deviation of the mean of the paramemets and the random walk innovations, respectively. Default is 5 and 5
#' @param regu to avoid the standard deviations shrinking too small and running into numerical issues, the log of the standard deviation multiplied be these values are added to the log-likelihood (subtracted from the negative log-likelihood). Defaults are .01 and .01 for the two penalties.
#' @param dat dataframe with response and predictors
#'
#' @return a list with two components: the fitted TMB model object, which has the NLL and the linear predictors in the report(), as well as the outfut from the call to TMBhelper::fit_tmb(), which is used to optimize the model.
#' @export
#'
#' @examples
pen_dlm<-function(dat,form=formula("y~x"),exp_pen=c(5,5),
                  regu=c(.01,.01)){

options(na.action = "na.pass")
mod_mat<-model.matrix(form,data=dat)

n_coefs<-ncol(mod_mat)

n_years<-nrow(mod_mat)

data<-list(
  y=head(dat,-1)$y,
  mod_mat=mod_mat,
  n_coefs=n_coefs,
  n_years=n_years
)


#parameters


params<-list(

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
nll<-nll - sum(RTMB::dexp(mean_sd,exp_pen[1],log=TRUE))- sum(regu[1]*mean_log_sd)
nll<-nll - sum(RTMB::dexp(innov_sd,exp_pen[2],log=TRUE))- sum (regu[2]*innov_log_sd)


pred<-RTMB::apply(coefs*mod_mat,1,sum)

nll<- nll-sum(RTMB::dnorm((y),(head(pred,-1)),resid_sd,log=TRUE))
RTMB::REPORT(pred)
RTMB::REPORT(nll)
nll
}


obj <- RTMB::MakeADFun(f, params,random=c("coef_inovations","coef_inits"),silent =TRUE)


#optimize
fit<-TMBhelper::fit_tmb(obj,newtonsteps =2,getJointPrecision  =FALSE,quiet =TRUE)

return(list(
  obj=obj,
  fit=fit
))
}

