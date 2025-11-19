# Render a report of forecast results

There are two options: 1) provide an the output of a call to
[`forecast_fun()`](https://wdfw-fp.github.io/sibregresr/reference/forecast_fun.md)or
[`performance_weights()`](https://wdfw-fp.github.io/sibregresr/reference/performance_weights.md)
or 2) provide raw data and the specify the arguments as needed for a
call to
[`forecast_fun()`](https://wdfw-fp.github.io/sibregresr/reference/forecast_fun.md)

## Usage

``` r
forecast_report(
  forecasts = NULL,
  mod_name = "MAPE_weight",
  stocks = NULL,
  forecast_year = NULL,
  df = NULL,
  include = c("constIntOnly", "tvIntOnly", "tvSlope", "constLM", "tvCRzeroInt",
    "constCRzeroInt", "tvInt"),
  transformation = log,
  inverse_transformation = exp,
  scale_x = FALSE,
  scale_y = FALSE,
  perf_yrs = 15,
  wt_yrs = NULL,
  output_file = "Forcast report.docx",
  output_dir = getwd(),
  ...
)
```

## Arguments

- forecasts:

  an the output of a call to
  [`forecast_fun()`](https://wdfw-fp.github.io/sibregresr/reference/forecast_fun.md)
  or `performance_weights`

- mod_name:

  the forecast model / ensemble type to report forecasts from

- stocks:

  vector of names of stocks to include in report

- forecast_year:

  the year to report forecast for

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

- output_file:

  name of output file

- output_dir:

  directory for output file

- ...:

  other arguments from `mod_funs` or `performance_weights`

## Value

a knitted Rmarkdown document
