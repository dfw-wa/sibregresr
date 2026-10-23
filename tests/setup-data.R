library(sibregresr)

make_stock <- function(stock, n) {
  data.frame(
    Stock = stock,
    ReturnYear = seq.int(2025L - n, 2024L),
    Age3 = seq_len(n) + 100,
    Age4 = seq_len(n) + 200
  )
}

stocks <- list(
  make_stock("short", 13),
  make_stock("long", 16),
  make_stock("minimum", 5)
)
models <- list(PenDlm = function(dat, form = y ~ x) NULL)
combined <- suppressWarnings(setup_data(
  do.call(rbind, stocks), mod_list = models, n_forecasts = 11
))

for (stock in stocks) {
  alone <- suppressWarnings(setup_data(
    stock, mod_list = models, n_forecasts = 11
  ))
  together <- combined[combined$Stock == stock$Stock[1], ]
  stopifnot(
    identical(together$n_years, alone$n_years),
    identical(together$Actual, alone$Actual),
    identical(together$data, alone$data),
    length(alone$n_years) == min(nrow(stock) - 4L, 11L) + 1L,
    sum(alone$n_years == -1L) == 1L
  )
}

reversed <- suppressWarnings(setup_data(
  do.call(rbind, rev(stocks)), mod_list = models, n_forecasts = 11
))
stopifnot(
  identical(combined$Stock, reversed$Stock),
  identical(combined$n_years, reversed$n_years),
  identical(combined$Actual, reversed$Actual),
  identical(combined$data, reversed$data)
)
