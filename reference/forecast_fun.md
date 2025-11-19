# generate forecasts

generate forecasts

## Usage

``` r
forecast_fun(
  df = summer_chinook_2024,
  include = c("constIntOnly", "tvIntOnly", "tvSlope", "constLM", "tvCRzeroInt",
    "constCRzeroInt", "tvInt"),
  transformation = log,
  inverse_transformation = exp,
  scale_x = FALSE,
  scale_y = FALSE,
  perf_yrs = 15,
  wt_yrs = NULL,
  covariates = tibble(ReturnYear = numeric(0)),
  ...
)
```

## Arguments

- df:

  Input data. A return table oColumn names: Stock, ReturnYear, and
  abundance for each age (e.g., Age3). Must be in that format.

- include:

  vector of names of models to include. Default is all options

- transformation:

  transformation to be conducted on a response and predictors. default
  is log

- inverse_transformation:

  the inverse of the transformation that was conducted on the response
  prior to fitting (default is exp)

- scale_x:

  boolean whether to scale the predictor data prior to fitting

- scale_y:

  boolean whether to scale the response data prior to fitting

- perf_yrs:

  maximum number of years of predictions to include in performance
  metrics. Set to infinity to use a stretching window.

- wt_yrs:

  number of years of one-step-ahed predictions to use to calculate
  performance-based model weights (i.e., MAPE and RMSE). If null (the
  default) the same number of years is used to calculate weights as is
  used to evaluate performance of ensemble and individual models.

- covariates:

  data frame of covariates to add to data. must contain "ReturnYear" or
  "BroodYear" field, which is used to perform the join with the salmon
  return data. Missing values in covariates are ok, and are fit as
  random effects with normal(0,1) hyperdistribution. Therefore it is
  importand to scale covariates especially if there are missing values.

- ...:

  other arguments from `mod_funs` or `performance_weights`

## Value

A list of two dataframes: *fits* is the output of the call to
[`fit_mods()`](https://wdfw-fp.github.io/sibregresr/reference/fit_mods.md)
and potentially useful information about models that failed to fit.
*forecasts* is the output of a call to
[`performance_weights()`](https://wdfw-fp.github.io/sibregresr/reference/performance_weights.md)
with ensemble forecasts, forecasts from component models, and
performance measures

## Details

The models available in this package are variations of a sibling
regression model with time-varying intercept and slope:
\$\$\left\\\begin{aligned}\mathrm{log}(y\_{a,t}) & =\alpha_t +
\mathrm{log}(y\_{a-1,t-1}) \beta_t + v_t, & \quad &v_t \sim
\mathcal{N}\left(0, V_t\right), \\\alpha_t & = \alpha\_{t-1} +
w\_{\alpha, t}, & \quad & w\_{\alpha, t} \sim \mathcal{N}\left(0,
W\_{\alpha, t}\right), \\\beta_t & = \beta\_{t-1} + w\_{\beta, t}, &
\quad & w\_{\beta, t} \sim \mathcal{N}\left(0, W\_{\beta,
t}\right),\end{aligned}\right.\$\$

where \\\alpha_t\\ and \\\beta_t\\ are an intercept and a slope for
returns of the previous age in the previous year, respectively, and both
are allowed to vary across years as random walks with process error
variances \\w\_{\alpha, t}\\ and \\w\_{\beta, t}\\ respectively. The
residual \\v_t\\ is assumed to be normally distributed around zero with
variance \\V_t\\. Together with a vague prior distribution for the
values of \\\alpha_0\\ and \\\beta_0\\ (the slope and intercept prior to
the first year) these equations define the "full" sibling regression
models. However, this "full" model may be overly complex for optimal
prediction, and is difficult to fit in practice. Simplified versions of
this model are included, as described below.

Model options are:

- constLM – Sibling regression with constant slope and intercept.

- tvInt – Sibling regression with time-varying intercept.

- tvSlope – Sibling regression with time-varying slope.

- tvIntSlope – Sibling regression with time-varying slope and intercept
  (i.e., the "full" mode). This model is not included by default because
  it generally converges to one of the simpler model. In other words, it
  is exceedingly rare for the data to support this complex of a model
  and this including it in an ensemble leads to double weighting one of
  the simpler models.

- tvCRzeroInt – Time varying "cohort ratio" model. Time varying slope,
  Intercept=0.

- constCRzeroInt – Constant "cohort ratio" model. Constant slope,
  Intercept=0.

- tvIntOnly – Time-varying Intercept-only model. Random walk on return,
  no sibling predictor.

- constIntOnly – Constant Intercept-only model. Long-term average, no
  sibling predictor.

- PenDlm – A dynamic linear model the like "tvIntSlope" but with
  penalized-complexity priors on the year-to-year variation and the mean
  of the covariate values. This model also can accommodate additional
  predictors (e.g., environmental covariates). This model is not
  included by defaults
