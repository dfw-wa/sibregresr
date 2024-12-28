#' functions to build models
#'
#' @param include vector of names of models to include. Default is all options
#' @param penDLM_formula an optional r formula object to pass to the penalized DLM model. Default is NULL, which would use the defaulte value formula("y~x") from the pen_dlm function.
#'
#' @return a list of functions that return (unoptimized) dlm model objects
#'
#' @details
#' Model options are:
#'
#' - constLM --	Sibling regression with constant slope and intercept.
#' - tvInt --	Sibling regression with  time-varying intercept.
#' - tvSlope --	Sibling regression with time-varying slope.
#' - tvIntSlope --	Sibling regression with time-varying slope and intercept.
#' - tvCRzeroInt --	Time varying "cohort ratio" model. Time varying slope, Intercept=0.
#' - constCRzeroInt --	Constant "cohort ratio" model. Constant slope, Intercept=0.
#' - tvIntOnly --	Time-varying Intercept-only model. Random walk on return, no sibling predictor.
#' - constIntOnly --	Constant Intercept-only model. Long-term average, no sibling predictor.
#'
#' @export
mod_funs<-function(include=c(
  "constIntOnly",
  "tvIntOnly",
  "tvIntSlope",
  "tvSlope",
  "constLM",
  "tvCRzeroInt",
  "constCRzeroInt",
  "tvInt"
),
penDLM_formula=NULL,
penDLM_exp_pen=NULL,
penDLM_regu=NULL){

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

if(!is.null(penDLM_exp_pen)){
  formals(pen_dlm_out)$exp_pen<-penDLM_exp_pen
}

if(!is.null(penDLM_regu)){
  formals(pen_dlm_out)$regu<-penDLM_regu
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
