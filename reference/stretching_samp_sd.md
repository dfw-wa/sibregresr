# Stretching sample SD

Stretching sample SD

## Usage

``` r
stretching_samp_sd(x, window_size = Inf, sample_sd = FALSE)
```

## Arguments

- x:

  a vector of errors

- window_size:

  the maximum number of values to include in mean

- sample_sd:

  boolean whether to subtract one from denominator so as to calculate a
  sample standard deviation. I think this would only be approporiate if
  bias correction were being applied.
