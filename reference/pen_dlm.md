# penalized DLM in RTMB

function to fit a penalized dynamic linear regression model.

The penalized complexity model puts penalties on the across-year means
\\\bar{\beta}\\ of each coefficient \\\beta_t\\ for each year \\t\\, and
the standard deviation of the steps in the random walk. So if the
coefficients are:

\$\$\beta_t = \beta\_{t-1} + \omega_t \\ \omega_t \sim
\mathcal{N}(0,\sigma)\$\$

\$\$\bar{\beta}\sim \mathcal{N}(0,\tau)\$\$

This model puts exponential-gamma penalties on all \$\$ and \$\$
parameters, for which there is a unique parameter for each predictor in
the model:

\$\$\tau,~\sigma \sim \text{exp}(\lambda) \\ \lambda \sim
\text{Gamma}(\text{Shape}=10,~\text{Scale}=1)\$\$

where two unique \\\lambda\\ parameters are fit for every predictor in
the model.

Additionally, \\0.05\*\text{log}(\tau, \sigma)\\ for all \\\tau\\s and
\\\sigma\\s is added to the log-likelihood to keep their values from
shrinking so small as to cause numerical problems during optimization.

## Usage

``` r
pen_dlm(
  dat,
  form = y ~ x,
  regu = c(0.01, 0.01),
  gamma_shape = 10,
  gamma_scale = 1,
  exp_rate = c(1, 1)
)
```

## Arguments

- dat:

  dataframe with response and predictors

- form:

  formula specifying linear predictor

- regu:

  to avoid the standard deviations shrinking too small and running into
  numerical issues, the log of the standard deviation multiplied be
  these values are added to the log-likelihood (subtracted from the
  negative log-likelihood). Defaults are .05 and .05 for the penalties
  on the mean of the coefficients and the year-to-year variability.

- gamma_shape:

  shape paramter for the gamma prior on the expential distributions rate
  paramters.

- gamma_scale:

  scale paramter for the gamma prior on the expential distributions rate
  paramters.

## Value

a list with two components: the fitted TMB model object, which has the
NLL and the linear predictors in the report(), as well as the outfut
from the call to TMBhelper::fit_tmb(), which is used to optimize the
model.
