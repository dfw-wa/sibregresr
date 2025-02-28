

#' plot observations and forecasts by age
#'
#' @param forecasts output of a call to `forecaste_fun`
#' @param mod_name name of the model that you want to plot forecasts for. options are:
#'  "AICc_weight" ,"MAPE_weight","MeanSA_weight","RMSE_weight","constIntOnly","tvIntOnly","tvIntSlope","tvSlope","constLM","tvCRzeroInt","constCRzeroInt",or "tvInt"
#' @return a ggplot object
#' @export
#'
#'@description
#' The black points are observations and the red points are the forecasts. Thick part of errorbar spans 50% prediciton ainteval and thin part spans 90% interval.
#'

make_plot<-function(forecasts,mod_name,include_50_CI=TRUE,include_90_CI=TRUE){

plot<-  forecasts |>
    dplyr::ungroup() |>
    dplyr::filter(model_name==mod_name|Age==min(Age),
           ReturnYear>=min(ReturnYear[!is.na(Pred)])) |>
    dplyr::mutate(age2=ifelse(Age==max(Age)|max(Age)==(min(Age)+1),"Total adult",paste("Age",Age))
           ) |>

    ggplot2::ggplot(ggplot2::aes(x=ReturnYear))+
    ggplot2::geom_line(ggplot2::aes(y = Obs),lwd=.5,lty=2)+
    ggplot2::geom_point(ggplot2::aes(y = Obs),size=2)+
    ggplot2::geom_point(ggplot2::aes(y=Pred),col="firebrick4",size=2,alpha=.75)+
    ggplot2::facet_wrap(~age2,ncol = 1,scales="free_y")+
    ggplot2::ylab("Run Size (thousands)")+ggplot2::theme(axis.title.x = ggplot2::element_blank()) +
    ggplot2::scale_y_continuous(labels = scales::unit_format(suffix="",scale = 1e-3),limits = c(0, NA),
                       expand = ggplot2::expansion(mult = c(0, 0.05)))


if(include_50_CI){
  plot<- plot+ ggplot2::geom_linerange(ggplot2::aes(ymin=L50,ymax=U50),col="firebrick4",alpha=.75,lwd=1.25)
}

if(include_90_CI){
  plot<- plot+ ggplot2::geom_linerange(ggplot2::aes(ymin=L90,ymax=U90),col="firebrick4",alpha=.75)
}


plot
}
