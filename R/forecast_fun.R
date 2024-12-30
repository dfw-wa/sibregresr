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
#' @return A tibble with ensemble forecasts, forecasts from component models, and performance measures
#' @export
#'
forecast_fun<-function(df=summer_chinook_2023,
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
transformation = log,
inverse_transformation = exp,
scale_x = FALSE,
scale_y = FALSE,
perf_yrs = 15,
wt_yrs = NULL,
...
){


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


  if( (wt_yrs2+perf_yrs)>(nrow(df)-5)){
    num_forecasts<-nrow(df)-5
    warning(paste("wt_yrs + perf_yrs is greater the number of years of observation minus 5. Only",num_forecasts,"will be made for model averaging and evaluation." ))
  }else{
    num_forecasts<-wt_yrs2+perf_yrs
  }




     #minimum age
  min_age<- sort(as.numeric(substr(colnames(df2)[grepl("Age",colnames(df2))],4,4)))[1]


  mod_list<-mod_funs(include)
  setup<-setup_data(df2,mod_list,n_forecasts = num_forecasts)
  fits<-fit_mods(setup)
  ensembles<-performance_weights(fits,perf_yrs,wt_yrs2)
  #add observations of minimum age for plotting
  ensembles |> dplyr::bind_rows(

    df2 |>
      dplyr::select(Stock,ReturnYear,Obs=paste0("Age",min_age)) |> dplyr::mutate(Age=min_age)
  )

}
