#' functions to build models
#'
#' @param include vector of names of models to include. Default is all options
#' @param ... named arguments passed through to `pen_dlm` or `r2d2_dlm` (or both, if the argument name exists in both). Use the actual argument names from those functions (e.g. `form`, `regu`, `gamma_shape`, `R2_a`, etc.).
#'
#' @return a list of functions that return (unoptimized) dlm model objects
#'
#' @details
#'
#' The models available in this package are variations of a sibling regression model with time-varying intercept and slope:
#' \deqn{\left\{\begin{aligned}\mathrm{log}(y_{a,t}) & =\alpha_t + \mathrm{log}(y_{a-1,t-1}) \beta_t + v_t, & \quad &v_t \sim \mathcal{N}\left(0, V_t\right), \\\alpha_t & = \alpha_{t-1} + w_{\alpha, t}, & \quad & w_{\alpha, t} \sim \mathcal{N}\left(0, W_{\alpha, t}\right), \\\beta_t & = \beta_{t-1} + w_{\beta, t}, & \quad & w_{\beta, t} \sim \mathcal{N}\left(0, W_{\beta, t}\right),\end{aligned}\right.}
#'
#' where \eqn{\alpha_t} and \eqn{\beta_t} are an intercept and a slope for returns of the previous age in the previous year, respectively, and both are allowed to vary across years as random walks with process error variances \eqn{w_{\alpha, t}} and \eqn{w_{\beta, t}} respectively. The residual \eqn{v_t} is assumed to be normally distributed around zero with variance \eqn{V_t}. Together with a vague prior distribution for the values of \eqn{\alpha_0} and \eqn{\beta_0} (the slope and intercept prior to the first year) these equations define the "full" sibling regression models. However, this "full" model may be overly complex for optimal prediction, and is difficult to fit in practice. Simplified versions of this model are included, as described below.
#'
#' Model options are:
#'
#' - constLM --	Sibling regression with constant slope and intercept.
#' - tvInt --	Sibling regression with  time-varying intercept.
#' - tvSlope --	Sibling regression with time-varying slope.
#' - tvIntSlope --	Sibling regression with time-varying slope and intercept (i.e., the "full" mode). This model is not included by default because it generally converges to one of the simpler model. In other words, it is exceedingly rare for the data to support this complex of a model and this including it in an ensemble leads to double weighting one of the simpler models.
#' - tvCRzeroInt --	Time varying "cohort ratio" model. Time varying slope, Intercept=0.
#' - constCRzeroInt --	Constant "cohort ratio" model. Constant slope, Intercept=0.
#' - tvIntOnly --	Time-varying Intercept-only model. Random walk on return, no sibling predictor.
#' - constIntOnly --	Constant Intercept-only model. Long-term average, no sibling predictor.
#' - PenDlm -- A dynamic linear model the like "tvIntSlope" but with penalized-complexity priors on the year-to-year variation and the mean of the covariate values. This model also can accommodate additional predictors (e.g., environmental covariates). This model is not included by defaults
#'
#'
#'
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
...){

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

r2d2_dlm_out<-r2d2_dlm

dots <- list(...)
pen_dlm_formals  <- names(formals(pen_dlm))
r2d2_dlm_formals <- names(formals(r2d2_dlm))

for(nm in names(dots)){
  if(nm %in% pen_dlm_formals)  formals(pen_dlm_out)[[nm]]  <- dots[[nm]]
  if(nm %in% r2d2_dlm_formals) formals(r2d2_dlm_out)[[nm]] <- dots[[nm]]
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
  "PenDlm" = pen_dlm_out,
  "r2d2DLM"=r2d2_dlm_out
)

all_funs[include]


}
