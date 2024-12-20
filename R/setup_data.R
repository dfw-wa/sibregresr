#' Setup data
#'
#'  puts data into a list column with different subsets (different numbers of years excluded) in each row, for fitting
#'
#' @param df Input data. Either a return table or a brood table. Column names: Stock, ReturnYear (or BroodYear), and for each age (e.g., Age3). Must be in that format.
#' @param n_forecasts number of one-year ahead forecasts to conduct
#' @param mod_list list of model functions as returned from `mod_funs` function call
#'
#' @return tibble with list columns
#' @export
setup_data<-function(df,
                     mod_list=mod_funs(),
                     n_forecasts=20
                    ){


  if(n_forecasts>(nrow(df)-5)){
    stop("n_forecasts is greater the number of years of observation minus 5. Please enter a smaller number of forecasts")
  }

  if(any(colnames(df)=="BroodYear")){
    df2<- brood_to_return(df)
  }else{
    df2<-df
  }



  df2 |>
    group_by(Stock) |>
    (\(dat)
    bind_rows(dat,
              dplyr::filter(dat,ReturnYear==max(ReturnYear)) |>
                mutate(ReturnYear=ReturnYear+1) |>
                mutate(across(contains("Age"),\(x)x=NA)))
    )()|>
    tidyr::nest() %>% dplyr::mutate(n=dim(data[[1]])[1]) |>
    ## Slice the data to re-fit subsets of data with years trimmed off the end
    crossing(n_years=c(-(1:(n_forecasts+1)))) |>
    mutate(Actual=purrr::map2(data,n_years, ~dplyr::slice(.x, nrow(.x)+.y+1)),
           data=purrr::map2(data, n_years, ~return_to_brood(head(.x, n=.y),FALSE))) |>
    ## the list of PC1 models sourced in `pc1_mods.r`
    crossing(tibble(model_name=names(mod_list),
                    model=mod_list),
             # the ages for which you want forecasts
             Age=sort(as.numeric(substr(colnames(df2)[grepl("Age",colnames(df2))],4,4)))[-1]) |>
    mutate(Actual=purrr::map2_dbl(Actual,Age,~.x |> pull(paste0("Age",.y)))) |>
    dplyr::arrange(Stock,Age,n_years) #if you have n_years.

}
