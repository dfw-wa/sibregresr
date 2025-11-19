# Calculate AICc for a dlm model object given the data and npar

Calculate AICc for a dlm model object given the data and npar

## Usage

``` r
get_AIC(y, mod, npar, mod_type = "dlm")
```

## Arguments

- y:

  response data

- mod:

  dlm model model object

- npar:

  number of parameters

- mod_type:

  either "dlm" if one of the 8 models fitted with `dlm` package or
  "RTMB" if the penalized dlm fit with the `RTMB` package.

## Value

real, AICc
