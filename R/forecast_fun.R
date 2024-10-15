#' generate forecasts
#'
#' @inheritParams mod_funs
#' @inheritParams setup_data
#' @inheritParams performance_weights
#' @inherit mod_funs details
#' @inherit performance_weights details
#'
#' @return A tibble with ensemble forecasts, forecasts from component models, and performance measures
#' @export
#'
forecast_fun<-function(df=summer_chinook_2023,
                       type="brood",
                       include=c(
  "constIntOnly",
  "tvIntOnly",
  "tvIntSlope",
  "tvSlope",
  "constLM",
  "tvCRzeroInt",
  "constCRzeroInt",
  "tvInt"
) ,
perf_yrs = 15){


  mod_list<-mod_funs(include)
  setup<-setup_data(df,type,mod_list,n_forecasts = perf_yrs*2)
  fits<-fit_mods(setup)
  ensembles<-performance_weights(fits,perf_yrs)
}
