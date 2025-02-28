#' Setup data
#'
#'  puts data into a list column with different subsets (different numbers of years excluded) in each row, for fitting
#'
#' @param df Input data. A return table oColumn names: Stock, ReturnYear, and abundance for each age (e.g., Age3). Must be in that format.
#' @param n_forecasts number of one-year ahead forecasts to conduct
#' @param mod_list list of model functions as returned from `mod_funs` function call
#'
#' @return tibble with list columns
#' @export
setup_data<-function(df,
                     mod_list=mod_funs(),
                     n_forecasts=20
                    ){


  min_yrs_stck<-df |> dplyr::group_by(Stock) |> dplyr::summarise(n=dplyr::n()) |> dplyr::filter(n==min(n)) |> dplyr::pull(n)

  if(n_forecasts>(min_yrs_stck-5)){
    warning("n_forecasts is greater the number of years of observation minus 5 for at last one stocks")
  }

  # if(any(colnames(df)=="BroodYear")){
  #   df2<- brood_to_return(df)
  # }else{
  #   df2<-df
  # }



  df |>
    group_by(Stock) |>
    (\(dat)
    bind_rows(dat,
              dplyr::filter(dat,ReturnYear==max(ReturnYear)) |>
                mutate(ReturnYear=ReturnYear+1) |>
                mutate(across(contains("Age"),\(x)x=NA)))
    )()|>
    # left_join(covariates,by="ReturnYear") |>
    tidyr::nest() %>% dplyr::mutate(n=dim(data[[1]])[1]) |>
    ## Slice the data to re-fit subsets of data with years trimmed off the end
    crossing(n_years=c(-(1:(min(n-5,n_forecasts)+1)))) |>
    mutate(Actual=purrr::map2(data,n_years, ~dplyr::slice(.x, nrow(.x)+.y+1)),
           data=purrr::map2(data, n_years, ~return_to_brood(head(.x, n=.y),FALSE))) |>
    crossing(tibble(model_name=names(mod_list),
                    model=mod_list),
             # the ages for which you want forecasts
             Age=sort(as.numeric(substr(colnames(df)[grepl("Age",colnames(df))],4,4)))[-1]) |>
    mutate(Actual=purrr::map2_dbl(Actual,Age,~.x |> pull(paste0("Age",.y)))) |>
    dplyr::arrange(Stock,Age,n_years) #if you have n_years.

}
