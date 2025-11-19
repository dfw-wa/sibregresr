# sibregresr

This package is for forecasting salmon returns using sibling regression.
The core functions produce model average predictions (i.e., ensembles)
of dynamic linear models (DLMs) with sibling predictors. The package
also has functionality to forecast using DLMs with penalized-complexity
priors, which can be an alternative to model averaging.

See the *Overview* article for more details and information on package
functionality.

## Installation

You can install sibregresr from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("wdfw-fp/sibregresr")
```

## Example

Below is an example of fitting an ensemble of 7 variations on a sibling
regression DLM and evaluating performance over 15 years. A beta version
plotting and table function are called to view the ensemble forecasts
with weights based on mean absolute percent errors.

See the *Overview* article for more details and examples.

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
#> [1] "Time for model fitting was 15.5 secs"

make_table(forecast$forecasts,"MAPE_weight")
```

![](reference/figures/README-example-1.png)

``` r

make_plot(forecast$forecasts,"MAPE_weight")
```

![](reference/figures/README-example-3.png)

``` R
Copyright 2025 Mark Sorel, Ben Cox, Thomas Buehrens

Licensed under the Apache License, Version 2.0 (the "License");
you may not use the files in this repository except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
