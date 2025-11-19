# plot observations and forecasts by age

The black points are observations and the red points are the forecasts.
Thick part of errorbar spans 50% prediciton ainteval and thin part spans
90% interval.

## Usage

``` r
make_plot(forecasts, mod_name, include_50_CI = TRUE, include_90_CI = TRUE)
```

## Arguments

- forecasts:

  output of a call to `forecaste_fun`

- mod_name:

  name of the model that you want to plot forecasts for. options are:
  "AICc_weight"
  ,"MAPE_weight","MeanSA_weight","RMSE_weight","constIntOnly","tvIntOnly","tvIntSlope","tvSlope","constLM","tvCRzeroInt","constCRzeroInt",or
  "tvInt"

## Value

a ggplot object
