#' Prep data for each Stock/Age/n_years and  fit the models
#'
#' @param dat tible returned from `setup_data` function
#' @param transformation transformation to be conducted on a response and predictors. default is log
#' @param scale_x boolean whether to scale the predictor data prior to fitting
#' @param scale_y boolean whether to scale the response data prior to fitting
#' @param covariates data frame of covariates to add to data. must contain "ReturnYear" field, which is used to perform the join with the salmon return data.

#'
#'@details
#' Can take several seconds as it is conducting maximum likeihood optimization for many models (n mdel * n stocks * n forecasts)
#'
#'
#' @return tible
#' @export
fit_mods<-function(dat,transformation=log,scale_x=FALSE,scale_y=FALSE,
                   covariates=tibble(ReturnYear=numeric(0))){

  fits<-  dat |>
    mutate(
      xy_og=purrr::map2(data,Age, ~.x |>
                          dplyr::select(BroodYear, y=paste0("Age",.y), x=paste0("Age", .y-1)) |>
                          dplyr::filter(!is.na(x)) |>
                          dplyr::mutate(ReturnYear=BroodYear+.y) |>
                          dplyr::left_join(covariates,by="ReturnYear") |>
                          dplyr::mutate(across(-c(ReturnYear,BroodYear,x,y),scale))),
      response_mu=purrr::map_dbl(xy_og,~mean(transformation(.x$y[.x$BroodYear!=max(.x$BroodYear)]))),
      response_sd=purrr::map_dbl(xy_og,~sd(transformation(.x$y[.x$BroodYear!=max(.x$BroodYear)]))),
      ## For the retrospective fits, replace the last y with NA to get forecasts
      xy_dat=purrr::map2(xy_og,model_name,~ {
        out<- .x |>
          dplyr::mutate(y=dplyr::if_else(BroodYear==max(BroodYear),NA_real_,transformation(y)),
                        mod_name=.y,
                        x=dplyr::if_else(stringr::str_detect(mod_name,"IntOnly"),1,transformation(x)),


          )

        if(scale_x&!stringr::str_detect(.y,"IntOnly")){
          out<- out |> mutate(x=scale(x))
        }
        if(scale_y){
          out<- out |> mutate(y=scale(y))
        }

        out
      }

                         )
      ,
      # Debug=FALSE runs the optimization in C++ so its faster.
      MLE=purrr::pmap(list(dat=xy_dat,fun=model,names=model_name),
                      purrr::safely(\(dat,fun,names){
                        if(names=="PenDlm"){
                          fun(dat)
                        }else{
                            dlm::dlmMLE(y=dat$y, x.mat=cbind(dat$x),parm=rep(0,3),build=fun,hessian=FALSE,debug=FALSE)
                        }
                      }
      )
      ),
      estimates=purrr::map(MLE,"result"),
      error=purrr::map(MLE,"error"))



  # Models that failed, none fail with full data sets but some retrospective fits were failing
  failed_fits<-fits  |>
    dplyr::filter(purrr::map_lgl(error, ~!is.null(.x))) |>
    dplyr::mutate(error=purrr::map_chr(error,as.character))
  #select(Stock, Age, n_years, model_name, error)

  if(nrow(failed_fits)>0){
    warning("There are ",nrow(failed_fits), " models that failed to fit. You can extract the failed models and the error messages from the returned object (e.g., fit) with \n
        fits |>
  dplyr::filter(purrr::map_lgl(error, ~!is.null(.x))) |>
  dplyr::mutate(error=purrr::map_chr(error,as.character))
        ")
    print(head(failed_fits))
  }

  fits
}
