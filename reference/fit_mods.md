# Prep data for each Stock/Age/n_years and fit the models

Prep data for each Stock/Age/n_years and fit the models

## Usage

``` r
fit_mods(
  dat,
  transformation = log,
  scale_x = FALSE,
  scale_y = FALSE,
  covariates = tibble(ReturnYear = numeric(0))
)
```

## Arguments

- dat:

  tible returned from `setup_data` function

- transformation:

  transformation to be conducted on a response and predictors. default
  is log

- scale_x:

  boolean whether to scale the predictor data prior to fitting

- scale_y:

  boolean whether to scale the response data prior to fitting

- covariates:

  data frame of covariates to add to data. must contain "ReturnYear" or
  "BroodYear" field, which is used to perform the join with the salmon
  return data. Missing values in covariates are ok, and are fit as
  random effects with normal(0,1) hyperdistribution. Therefore it is
  importand to scale covariates especially if there are missing values.

## Value

tible

## Details

Can take several seconds as it is conducting maximum likeihood
optimization for many models (n mdel \* n stocks \* n forecasts)
