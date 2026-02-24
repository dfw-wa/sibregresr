# Setup data

puts data into a list column with different subsets (different numbers
of years excluded) in each row, for fitting

## Usage

``` r
setup_data(
  df,
  mod_list = mod_funs(),
  n_forecasts = 20,
  include_youngest = FALSE
)
```

## Arguments

- df:

  Input data. A return table oColumn names: Stock, ReturnYear, and
  abundance for each age (e.g., Age3). Must be in that format.

- mod_list:

  list of model functions as returned from `mod_funs` function call

- n_forecasts:

  number of one-year ahead forecasts to conduct

## Value

tibble with list columns
