# Calculates weighted average forecasts, performance metrics, and prediction intervals based on past performance

Calculates weighted average forecasts, performance metrics, and
prediction intervals based on past performance

## Usage

``` r
performance_weights(
  fits,
  perf_yrs = 15,
  wt_yrs = NULL,
  transformation = log,
  inverse_transformation = exp,
  scale_y = FALSE
)
```

## Arguments

- fits:

  data frame returned by `fit_mods` function

- perf_yrs:

  maximum number of years of predictions to include in performance
  metrics. Set to infinity to use a stretching window.

- wt_yrs:

  number of years of one-step-ahed predictions to use to calculate
  performance-based model weights (i.e., MAPE and RMSE). If null (the
  default) the same number of years is used to calculate weights as is
  used to evaluate performance of ensemble and individual models.

- transformation:

  the trnasformation that was conducted on the response prior to
  fitting(default is log)

- inverse_transformation:

  the inverse of the transformation that was conducted on the response
  prior to fitting (default is exp)

- scale_y:

  boolean whether the response was scaled prior to fitting

## Value

a data frame with predictions from component models and weighted average
models based on AICc, MAPE, and RMSE weights.

## Details

AICc weights \\w_m\\ for model \\m\\ are calculated as:
\$\$w_m=\frac{e^{-0.5\left(\mathrm{AIC}\_m-\mathrm{AIC}\_{\min
}\right)}}{\sum\_{i \in \mathcal{M}}
e^{-0.5\left(\mathrm{AIC}\_i-\mathrm{AIC}\_{\min }\right)}}\$\$

MAPE and RMSE weights are calculated as, for example:
\$\$w_m=\frac{\mathrm{MAPE}\_m^{-1}}{\sum\_{i \in \mathcal{M}}
\mathrm{MAPE}\_i^{-1}}\$\$

Prediction intervals are based on the standard deviation between
one-year ahead predictions (i.e., forecasts) and observations in log
space. The number of years included in the standard deviation
calculations is the minimum of the number of years available or the
values specified for `perf_yrs`. For example, if `perf_yrs = 15` but
only three years of an ensemble forecast had been generated prior to a
given year, those three years would be used to calculate the forecast
standard deviation and prediction intervals, however, if 20 years of the
ensemble forecast were available, only the most recent 15 years would be
used. The "n_sd" field in the output of a call to
[`forecast_fun()`](https://wdfw-fp.github.io/sibregresr/reference/forecast_fun.md)
provides the number of years used to calculate prediction intervals for
that forecast. The number of years used to calculate weights for an
ensemble forecast is conducted in the same way (i.e., all available up
to "wt_yrs") and the "n_wts" field in the output gives the number of
years used. This is not relevant for ensembles based on AICc weighting
as they are based on the AICc value for models fit for the current year.

- *model_name* is the name of the model used for forecast. It includes
  the compenent of the ensembles and the ensembles. Additionally, "best"
  is the model with the lowest MAPE over the perforance-evaluation
  period for a given year. Thgis is included to be be able to see the
  performance of picking the best-performaning model, whether than be an
  ensemble or one of the components, over multiple years. The
  "Model_name2" field indicates which model was the "best" for that
  year.

- *n_wts* = the number of years of forecasts and observations that were
  used to generate MAPE and RMSE weights for ensemble forecasts.

- Individual year metrics:

  - *Er* = forecast error

  - *AEr* = absolute forecast error

  - *PE*= percent errr,

  - *APE* = absolute percent error

  - *SQE* = square error

  - *logQ* = log (forecast/observed)- AlogQ = absolute logQ

- Multi-year bias metrics

  - *MEr* = mean error

  - *MPE* = mean percent error

  - *MeanlogQ* = mean logQ

- Multi-year precision metrics

  - *RMSE* = root mean square error

  - *MAer* = mean absolute error

  - *MAPE* = mean absolute percent error

  - *MeanSA* = mean absolute logQ

- *log_sd* = standard deviation from observed in log space for a the
  last *n_years* of forecasts (i.e., (sqrt(sum(logQ^2)/n)))

- *n_sd* = the number of years that were used to calculate sample
  standard deviation from observed
