#' Render a report of forecast results
#'
#' @inheritParams make_plot
#' @inheritParams forecast_fun
#' @inheritParams make_table
#' @param stocks vector of names of stocks to include in report
#' @param output_file name of output file
#' @param output_dir directory for output file
#' @param forecasts  an the output of a call to `forecast_fun()` or `performance_weights`
#' @param mod_name the forecast model / ensemble type  to report forecasts from
#' @param forecast_year the year to report forecast for
#'
#' @description
#' There are two options: 1) provide an the output of a call to `forecast_fun()`or `performance_weights()` or 2) provide raw data and the specify the arguments as needed for a call to `forecast_fun()`
#'
#'
#' @return a knitted Rmarkdown document
#' @export
#'
#' @examples
forecast_report<-function(
    forecasts=NULL,
    mod_name= "MAPE_weight",
    stocks=NULL,
    forecast_year=NULL,
    df = NULL,
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
    output_file = "Forcast report.docx",
    output_dir = getwd(),
    ...
){


  if(is.null(forecasts)){
    if(is.null(df)){
      stop("either forecasts or data must be supplied")
    }
    param_forecasts<-forecast_fun(df,include,transformation,inverse_transformation ,scale_x ,scale_y ,perf_yrs,wt_yrs)
  }else{
    param_forecasts<-forecasts
  }


  if(is.null(stocks)){
    stocks_out<-unique(forecasts$Stock)
  }else{
    stocks_out<-stocks
  }

  if(is.null(forecast_year)){
    forecast_year_out<-max(forecasts$ReturnYear)
  }else{
    forecast_year_out<-forecast_year
  }


  template_path <- system.file("rmarkdown", "Salmon_forecasts.Rmd", package = "sibregresr")

  if (template_path == "") {
    stop("Template file not found. Ensure it exists in the package.")
  }

  rmarkdown::render(
    input = template_path,
    output_file = file.path(output_dir, output_file),
    params = list(
      forecasts=param_forecasts,
      mod_name=mod_name,
      stocks=stocks_out,
      forecast_year=forecast_year_out
    )

    ,
    envir = new.env() # Avoids variable conflicts
  )

}
