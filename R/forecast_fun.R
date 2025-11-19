#' generate forecasts
#'
#' @inheritParams mod_funs
#' @inheritParams setup_data
#' @inheritParams fit_mods
#' @inheritParams performance_weights
#' @inherit mod_funs details
#' @inherit performance_weights details
#' @param df
#' @param include
#' @param perf_yrs
#' @param wt_yrs
#' @param ... other arguments from `mod_funs` or `performance_weights`
#'
#' @return A list of two dataframes: *fits* is the output of the call to `fit_mods()` and potentially useful information about models that failed to fit. *forecasts* is the output of a call to `performance_weights()` with ensemble forecasts, forecasts from component models, and performance measures
#' @export
#'
forecast_fun<-function(df=summer_chinook_2024,
                       include=c(
  "constIntOnly",
  "tvIntOnly",
  "tvSlope",
  "constLM",
  "tvCRzeroInt",
  "constCRzeroInt",
  "tvInt"
) ,
transformation = log,
inverse_transformation = exp,
scale_x = FALSE,
scale_y = FALSE,
perf_yrs = 15,
wt_yrs = NULL,
covariates = tibble(ReturnYear=numeric(0)),
...
){
  start_time<-Sys.time()

  if(is.null(wt_yrs)){
    wt_yrs2<-perf_yrs
  }else{
    wt_yrs2<-wt_yrs
  }

  #convert brood tabel to return table
  if(any(colnames(df)=="BroodYear")){
   df2<- brood_to_return(df)
  }else{
    df2<-df
  }


  min_yrs_stck<-df2 |> dplyr::group_by(Stock) |> dplyr::summarise(n=dplyr::n()) |> dplyr::filter(n==min(n)) |> dplyr::pull(n)


  if( any((wt_yrs2+perf_yrs)>(min_yrs_stck-5))){
    warning(paste("wt_yrs + perf_yrs is greater the number of years of observation minus 5 for at least one stock." ))
  }

    num_forecasts<-wt_yrs2+perf_yrs




     #minimum age
  min_age<- sort(as.numeric(substr(colnames(df2)[grepl("Age",colnames(df2))],4,4)))[1]


  mod_list<-mod_funs(include,...)
  setup<-setup_data(df2,mod_list,n_forecasts = num_forecasts)
  fits<-fit_mods(setup,transformation,scale_x,scale_y,covariates)
  ensembles<-performance_weights(fits,
                                 perf_yrs,
                                 wt_yrs2,
                                 transformation,
                                 inverse_transformation,
                                 scale_y)


elapsed<-Sys.time()-start_time
  print(paste("Time for model fitting was",round(elapsed,1),attr(elapsed, "units")))

  #add observations of minimum age for plotting
  ensembles<-ensembles |> dplyr::full_join(

    df2 |>
      dplyr::select(Stock,ReturnYear,dplyr::contains("Age")) |> tidyr::pivot_longer(dplyr::contains("Age"),names_to="Age",values_to="Obs") |> mutate(Age=readr::parse_number(Age)),
    by=c("Stock", "Age", "ReturnYear", "Obs")
  )

  list(fits=fits,
       forecasts=ensembles)
}
