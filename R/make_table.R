

#' Make results table
#'
#' @inheritParams make_plot
#' @param forecast_year years to include in the table. default ot the last forecasts year in forecasts input
#' @return
#' @export
#'
#' @examples
make_table<-function(forecasts,mod_name,forecast_year=NULL ){
if(is.null(forecast_year)){
  forecast_year<-max(forecasts$ReturnYear)
}
   dplyr::ungroup(forecasts) |>
    dplyr::filter(model_name%in%mod_name,
           ReturnYear%in%(forecast_year)) |>
    dplyr::mutate( Age=ifelse(Age==max(Age),"Total",Age),
                   dplyr::across(is.numeric,round),
                   dplyr::across(is.numeric,format,big.mark=","),
            `90%CI`=paste(L90,"-",U90),
            `50%CI`=paste(L50,"-",U50)) |>
    dplyr::select(Age,Forecast=Pred,`50%CI`,`90%CI`,MAPE,RMSE,MPE,MEr,model_name) |>
    flextable::flextable() |>
    flextable::autofit()

}



make_big_table<-function(dat){

  dat |>dplyr::ungroup() |>
    dplyr::filter(n_sd==max(n_sd,na.rm=T)) |>
    dplyr::mutate( Age=ifelse(Age==max(Age),"Total",Age)) |>
    dplyr::select(Stock,Age,ReturnYear,model_name,Observed=Obs,Forecast=Pred,Er,Pct_Er=PE,MAPE,RMSE,L90:U90)
}
