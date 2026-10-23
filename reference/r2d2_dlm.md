# R2D2 penalized DLM in RTMB

function to fit a dynamic linear regression model with r2dr shrinkage
prior.

## Usage

``` r
r2d2_dlm(
  dat,
  form = y ~ x,
  alpha_dirichlet = NULL,
  scale_evol = TRUE,
  R2_a = 0.5,
  R2_b = NULL,
  rho_a = 3,
  rho_b = 2,
  intercept_n_equiv = 3,
  sd_init_intercept = 1,
  phi_a = 3,
  phi_b = 2,
  weird_jacob = FALSE,
  log_correct = FALSE
)
```

## Arguments

- dat:

  dataframe with response and predictors

- form:

  formula specifying linear predictor

- alpha_dirichlet:

  if null, 1 / number of covariates

- scale_evol:

  whether to scale the variance of the dynamic part by the time series
  length so that it gets equivalent penalization as the initial value

- R2_a:

  alpha for beta prior on R2

- R2_b:

  alpha for beta prior on R2, if null (default) equal to number of
  covariates / 2

- rho_a:

  alpha for beta prior on split between static and dynamic. default puts
  slightly more weight on static.

- rho_b:

  beta for beta prior on split between static and dynamic. default puts
  slightly more weight on static.

- intercept_n_equiv:

  multiplier on the amount of variance given to average covariate, which
  is given to intercept.

- sd_init_intercept:

  sd on the intercept initial value

## Value

the fitted TMB model object, which has the NLL and the linear predictors
in the report()

## Details

Predictors are standardized using all rows except the final forecast
row. The same historical means and standard deviations are applied to
that row.
