#' Prep data for each Stock/Age/n_years and  fit the models
#'
#' @param dat tible returned from `setup_data` function
#'
#'@details
#' Can take several seconds as it is conducting maximum likeihood optimization for many models (n mdel * n stocks * n forecasts)
#'
#'
#' @return tible
#' @export
fit_mods<-function(dat){

fits<-  dat |>
  mutate(xy_og=purrr::map2(data,Age, ~.x |>
                             dplyr::select(BroodYear, y=paste0("Age",.y), x=paste0("Age", .y-1)) |>
                             dplyr::filter(!is.na(x))),
         ## For the retrospective fits, replace the last y with NA to get forecasts
         xy_dat=purrr::map2(xy_og,model_name,~.x |>
                              dplyr::mutate(y=dplyr::if_else(BroodYear==max(BroodYear),NA_real_,log(y)),
                                                     mod_name=.y,
                                                     x=dplyr::if_else(stringr::str_detect(mod_name,"IntOnly"),1,log(x)))),
         # Debug=FALSE runs the optimization in C++ so its faster.
         MLE=purrr::map2(xy_dat,model, purrr::safely(~dlm::dlmMLE(y=.x$y, x.mat=cbind(.x$x),parm=rep(0,3),build=.y,hessian=FALSE,debug=FALSE))),
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
