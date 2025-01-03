
# sibregresr

The goal of sibregresr is to predict salmon returns using sibling
regression. The regressions are conducted within a dynamic linear
modeling framework and model averaging is used.

## Installation

You can install the development version of sibregresr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("wdfw-fp/sibregresr")
```

## Example

``` r
library(sibregresr)

forecast<-forecast_fun(
  df = summer_chinook_2024,
  include = c("constIntOnly", "tvIntOnly", "tvSlope", "constLM",
    "tvCRzeroInt", "constCRzeroInt", "tvInt"),
  transformation = log,
  inverse_transformation = exp,
  scale_x = FALSE,
  scale_y = FALSE,
  perf_yrs = 15,
  wt_yrs = NULL,
)
#> [1] "Time for model fitting was 15.2 secs"

make_table(forecast$forecasts,"MAPE_weight")
```

<img src="man/figures/README-example-1.png" width="100%" />

``` r

make_plot(forecast$forecasts,"MAPE_weight")
```

<img src="man/figures/README-example-3.png" width="100%" />
