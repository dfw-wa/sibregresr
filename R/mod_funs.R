#' functions to build models
#'
#' @param include vector of names of models to include. Default is all options
#' @param penDLM_formula an optional r formula object to pass to the penalized DLM model. Default is NULL, which would use the defaulte value formula("y~x") from the pen_dlm function.
#' @param penDLM_regu scaler for the addition of the log of standard deviations to the log-likelihood as a regularizer. See penealized_dlm help for more details
#' @param penDLM_gamma_shape shape parameter for the gamma prior on the exponential distribution rate parameter. See penealized_dlm help for more details
#' @param penDLM_gamma_scale scale parameter for the gamma prior on the exponential distribution rate parameter.See penealized_dlm help for more details
#'
#' @return a list of functions that return (unoptimized) dlm model objects
#'
#' @details
#' Model options are:
#'
#' - constLM --	Sibling regression with constant slope and intercept.
#' - tvInt --	Sibling regression with  time-varying intercept.
#' - tvSlope --	Sibling regression with time-varying slope.
#' - tvIntSlope --	Sibling regression with time-varying slope and intercept. This model is not inlcuded by default because it generally converges to one of the simpler model. In other words, it is exceedingly rare for the data to support this complex of a model and this including it in an ensemble leads to double weighting one of the simpler models.
#' - tvCRzeroInt --	Time varying "cohort ratio" model. Time varying slope, Intercept=0.
#' - constCRzeroInt --	Constant "cohort ratio" model. Constant slope, Intercept=0.
#' - tvIntOnly --	Time-varying Intercept-only model. Random walk on return, no sibling predictor.
#' - constIntOnly --	Constant Intercept-only model. Long-term average, no sibling predictor.
#' - PenDlm -- A dynamic linear model the like "tvIntSlope" but with penalized-complexity priors on the year-to-year variation and the mean of the covariate values. This model also can accommodate additional predictors (e.g., environmental covariates). This model is not included by defaults
#'
#' @export
mod_funs<-function(include=c(
  "constIntOnly",
  "tvIntOnly",
  "tvSlope",
  "constLM",
  "tvCRzeroInt",
  "constCRzeroInt",
  "tvInt"
),
penDLM_formula=NULL,
penDLM_regu=NULL,
penDLM_gamma_shape=NULL,
penDLM_gamma_scale=NULL){

#   # Constant Intercept-only model
constIntOnly <- function(parm,x.mat){
  parm <- exp(parm)
  return( dlm::dlmModReg(X=x.mat, dV=parm[1], dW=0, addInt=FALSE))
}

# Random walk- time-varying intercept only
tvIntOnly <- function(parm,x.mat){
  parm <- exp(parm)
  return( dlm::dlmModReg(X=x.mat, dV=parm[1], dW=parm[2], addInt=FALSE))
}

# Time-varying Intercept and Slope
tvIntSlope <- function(parm, x.mat){
  parm <- exp(parm)
  return(dlm::dlmModReg(X=x.mat, dV=parm[1], dW=c(parm[2], parm[3] )))
}

# Time-varying slope
tvSlope <- function(parm, x.mat){
  parm <- exp(parm)
  return( dlm::dlmModReg(X=x.mat, dV=parm[1], dW=c(0, parm[2] )))
}

# Linear regression constant slope/intercept
constLM <- function(parm, x.mat){
  parm <- exp(parm)
  return( dlm::dlmModReg(X=x.mat, dV=parm[1], dW=c(0, 0)))
}

# Time-varying Cohort ratio (i.e., zero intercept model)
tvCRzeroInt <- function(parm, x.mat){
  parm <- exp(parm)
  return( dlm::dlmModReg(X=x.mat, dV=parm[1], dW=c(parm[2]), addInt=FALSE))
}

# Constant cohort ratio (i.e., zero intercept model)
constCRzeroInt <- function(parm, x.mat){
  parm <- exp(parm)
  return(dlm::dlmModReg(X=x.mat, dV=parm[1],dW=c(0), addInt=FALSE))
}

# Time-varying intercept, constant slope
tvInt <- function(parm, x.mat){
  parm <- exp(parm)
  return(dlm::dlmModReg(X=x.mat, dV=parm[1],dW=c(parm[2], 0)))
}


pen_dlm_out<-pen_dlm

if(!is.null(penDLM_formula)){
  formals(pen_dlm_out)$form<-penDLM_formula
}

if(!is.null(penDLM_regu)){
  formals(pen_dlm_out)$regu<-penDLM_regu
}

if(!is.null(penDLM_gamma_shape)){
  formals(pen_dlm_out)$gamma_shape<-penDLM_gamma_shape
}

if(!is.null(penDLM_gamma_scale)){
  formals(pen_dlm_out)$gamma_scale<-penDLM_gamma_scale
}


all_funs<-list(
  "constIntOnly" = constIntOnly,
  "tvIntOnly" = tvIntOnly,
  "tvIntSlope" = tvIntSlope,
  "tvSlope" = tvSlope,
  "constLM" = constLM,
  "tvCRzeroInt" = tvCRzeroInt,
  "constCRzeroInt" = constCRzeroInt,
  "tvInt" = tvInt,
  "PenDlm" = pen_dlm_out
)

all_funs[include]


}
