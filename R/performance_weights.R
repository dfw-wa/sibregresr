#' Calculated weighted average forecasts
#'
#' @param fits data frame returned by `fit_mods` function
#' @param perf_yrs maximum number of years of predictions to include in performance metrics. Set to infinity to use a stretching window.
#' @param wt_yrs  number of years of one-step-ahed predictions to use to calculate performance-based model weights (i.e., MAPE and RMSE). If null (the default) the same number of years is used to calculate weights as is used to evaluate performance of ensemble and individual models.
#'
#' @return a data frame with predictions from component models and weighted average models based on AICc, MAPE, and RMSE weights.
#'
#' @details
#' AICc weights are calculated as:
#'  $exp(-.5 deltaAICc) / sum(exp(-.5 deltaAICc))$
#' MAPE and RMSE weights are calculated as, for example:
#'  MAPE^-1 / sum(MAPE^-1)
#'
#' - *n_wts* = the number of years of forecasts and observations that were used to generate MAPE and RMSE weights for ensemble forecasts.
#' - Individual year metrics:
#'     - *Er* = forecast error
#'     - *AEr* = absolute forecast error
#'     - *PE*= percent errr,
#'     - *APE* = absolute percent error
#'     - *SQE* = square error
#'     - *logQ* = log (forecast/observed)- AlogQ = absolute logQ
#'  - Multi-year bias metrics
#'      - *MEr* = mean error
#'      - *MPE* = mean percent error
#'      - *MeanlogQ* = mean logQ
#'  - Multi-year precision metrics
#'      - *RMSE* = root mean square error
#'      - *MAer* = mean absolute error
#'      - *MAPE* = mean absolute percent error
#'      - *MeanSA* = mean absolute logQ
#'  - *log_sd* = standard deviation from observed in log space for a the last *n_years* of forecasts (i.e., (sqrt(sum(logQ^2)/n)))
#'  - *n_sd* = the number of years that were used to calculate sample standard deviation from observed
#' @export
performance_weights<-function(fits,
                              perf_yrs=15,
                              wt_yrs=NULL
){


  if(is.null(wt_yrs)){
    wt_yrs_2<-perf_yrs
  }else{
    wt_yrs_2<-wt_yrs
  }


  # Get the predictions, calculate error metrics
  preds_perf <- fits %>%
    dplyr::filter(purrr::map_lgl(error,is.null)) %>%
    mutate(build=purrr::pmap(tibble::lst(estimates, model, xy_dat), ~with(list(...), model(parm=estimates$par, x.mat=cbind(xy_dat$x)))),
           filter=purrr::map2(xy_dat, build, ~dlm::dlmFilter((.x$y), .y)),
           npar=purrr::map_dbl(build, get_npar),
           AICc=purrr::pmap_dbl(tibble::lst(dat=xy_dat,model=build, npar), ~with(list(...), get_AIC(dat$y, model, npar))),
           pred=purrr::map_dbl(filter, ~exp(.x$f[length(.x$f)])),
           ReturnYear = purrr::map2_int(xy_og,Age,~(tail(.x$BroodYear,1)+.y))) %>%
    dplyr::mutate(
      Er=pred-Actual,
      AEr=abs(Er),
      PE=100*((Er)/Actual),
      APE=abs(PE),
      SQE=(pred-Actual)^2,
      logQ=log(pred/Actual),
      AlogQ=abs(logQ)
    ) |>
    dplyr::group_by(Stock, Age, model_name) %>%
    dplyr::arrange(Stock,Age,ReturnYear) %>%
    dplyr::mutate(
      RMSE=dplyr::lag(sqrt(stretching_mean(SQE,window_size=wt_yrs_2)),1,default=NA),
      MAPE=dplyr::lag(100*stretching_mean(APE,window_size=wt_yrs_2),1,default=NA),
      MeanSA=dplyr::lag(100*(exp(stretching_mean(AlogQ,window_size=wt_yrs_2))-1),1,default=NA),
      n_wts= pmin(dplyr::lag(seq_along(APE),1),wt_yrs_2)
    ) %>%
    dplyr::group_by(Stock,Age,ReturnYear) %>%
    dplyr::mutate(across(RMSE:MeanSA,~(1/.x) / sum(1/.x), .names="{.col}_weight"),
                  deltaAICc= AICc - min(AICc),
                  AICc_weight=exp(-.5*deltaAICc) / sum(exp(-.5*deltaAICc))) |>
    # add ensembles
    (\(df)
     dplyr:: bind_rows(df,
                       dplyr::group_by(df,Stock,Age,Actual,ReturnYear,n_wts) %>%
                         dplyr::mutate(dplyr::across(c(RMSE_weight:MeanSA_weight),~.x*pred,.names="{.col}_pred"),
                                       AICc_weight_pred=log(pred)*AICc_weight) |>
                         dplyr::summarize_at(dplyr::vars(tidyselect::contains("_pred")),sum) |>
                         dplyr::mutate(AICc_weight_pred=exp(AICc_weight_pred)) |>
                         tidyr::pivot_longer(cols=RMSE_weight_pred:AICc_weight_pred,names_to = "model_name",values_to = "pred",names_pattern = "(.*)_pred")
     )
    )() |>
    #add performance of picking best model based on MAPE after each 10 year
    (\(df)
     dplyr::bind_rows(
       df,
       dplyr::group_by(df,Stock,Age,ReturnYear) |>
         dplyr::filter(MAPE==min(MAPE,na.rm=T)) |>
         dplyr::mutate(model_name2=model_name,
                       model_name="best")
       |>
         dplyr::group_by(Stock, Age) %>%
         dplyr::arrange(Stock,Age,ReturnYear) %>%
         dplyr::mutate(
           RMSE=dplyr::lag(sqrt(stretching_mean(SQE,window_size=wt_yrs_2)),1,default=NA),
           MAPE=dplyr::lag(100*stretching_mean(APE,window_size=wt_yrs_2),1,default=NA),
           MeanSA=dplyr::lag(100*(exp(stretching_mean(AlogQ,window_size=wt_yrs_2))-1),1,default=NA),
           n_wts= pmin(dplyr::lag(seq_along(APE),1),wt_yrs_2)
         ) |>
         dplyr::ungroup()))() |>
    # add totals across age
    dplyr::select(Stock,Age,model_name,ReturnYear,Obs=Actual,Pred=pred,n_wts,model_name2) |>
    dplyr::arrange(Stock,Age,model_name,ReturnYear)|>
    dplyr::filter(!is.na(Pred)) |>
    (\(df)
     bind_rows(
       df,
       (dplyr::group_by(df,Stock,ReturnYear,model_name) |>
          dplyr::summarize(dplyr::across(c(Obs,Pred,Age,n_wts),sum)))
     ))() |>
    #calculate error metrics
    dplyr::mutate(
      Er=Pred-Obs,
      AEr=abs(Er),
      PE=100*((Er)/Obs),
      APE=abs(PE),
      SQE=(Pred-Obs)^2,
      logQ=log(Pred/Obs),
      AlogQ=abs(logQ)
    ) |>
    group_by(Stock, Age, model_name) %>%
    dplyr::arrange(Stock,Age,ReturnYear) %>%
    dplyr::mutate(
      MEr = dplyr::lag(stretching_mean(Er,window_size=perf_yrs),1,default=NA),
      MPE = dplyr::lag(stretching_mean(PE,window_size=perf_yrs),1,default=NA),
      MeanlogQ = dplyr::lag(100*(exp(stretching_mean(logQ,window_size=perf_yrs))-1),1,default=NA),
      MAPE = dplyr::lag(stretching_mean(APE,window_size=perf_yrs),1,default=NA),
      MeanSA = dplyr::lag(100*(exp(stretching_mean(AlogQ,window_size=perf_yrs))-1),1,default=NA),
      RMSE = dplyr::lag(sqrt(stretching_mean(SQE,window_size=perf_yrs)),1,default=NA),
      MAEr = dplyr::lag(stretching_mean(AEr,window_size=perf_yrs),1,default=NA),
      n_sd = pmin(dplyr::lag(seq_along(logQ),1),perf_yrs),
      log_sd = dplyr::lag(stretching_samp_sd(logQ,window_size=perf_yrs),1) # sample standard deviation in log space
    )|>
    dplyr::arrange(model_name,Stock,Age,ReturnYear) |>
    dplyr::mutate(n_wts=ifelse(model_name%in%c("MAPE_weight_pred" ,"MeanSA_weight_pred", "RMSE_weight_pred" ),n_wts,NA),
                  L90=exp(log(Pred)+qnorm(.05,0,log_sd)),
                  L50=exp(log(Pred)+qnorm(.25,0,log_sd)),
                  U50=exp(log(Pred)+qnorm(.75,0,log_sd)),
                  U90=exp(log(Pred)+qnorm(.95,0,log_sd)))
}
