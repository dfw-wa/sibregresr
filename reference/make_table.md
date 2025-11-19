# Make results table

Make results table

## Usage

``` r
make_table(forecasts, mod_name, forecast_year = NULL)
```

## Arguments

- forecasts:

  output of a call to `forecaste_fun`

- mod_name:

  name of the model that you want to plot forecasts for. options are:
  "AICc_weight"
  ,"MAPE_weight","MeanSA_weight","RMSE_weight","constIntOnly","tvIntOnly","tvIntSlope","tvSlope","constLM","tvCRzeroInt","constCRzeroInt",or
  "tvInt"

- forecast_year:

  years to include in the table. default ot the last forecasts year in
  forecasts input
