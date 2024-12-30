#' Convert a Return Table to a Brood Table
#'
#' @param rt return table with column names: Stock, ReturnYear, and for each age (e.g., Age3). Must be in that format.
#' @param by_stock boolean for whether the data contians a Stock column.
#'
#' @return
#' @export
#'
return_to_brood <- function(rt,by_stock=TRUE){

  # Find the min age column in the return table (rt), then make "sym" for tidy eval below
  min_age <- colnames(rt)[stringr::str_detect(colnames(rt),"Age")] |>  min() |>  rlang::sym()

  if(by_stock){
    # Reshape the data, filter rows with complete min_age data
    rt |>
      dplyr::group_by(Stock) |>
      tidyr::pivot_longer(tidyselect::contains("Age"), names_to = "AgeName", values_to = "Return") |>
      dplyr::mutate(Age=readr::parse_number(AgeName)) |>
      dplyr::mutate(BroodYear=ReturnYear - Age) |>
      dplyr::select(-ReturnYear, -Age) |>
      tidyr::pivot_wider(names_from =AgeName, values_from = Return) |>
      # Unquo the min_age thing
      dplyr::filter(!is.na(!!min_age)) |>
      dplyr::ungroup() |>
      as.data.frame() |>
      dplyr::arrange(Stock,BroodYear)}
  else{
    rt |>
      tidyr::pivot_longer(tidyselect::contains("Age"), names_to = "AgeName", values_to = "Return") |>
      dplyr::mutate(Age=readr::parse_number(AgeName)) |>
      dplyr::mutate(BroodYear=ReturnYear - Age) |>
      dplyr::select(-ReturnYear, -Age) |>
      tidyr::pivot_wider(names_from =AgeName, values_from = Return) |>
      # Unquo the min_age thing
      dplyr::filter(!is.na(!!min_age)) |>
      dplyr::ungroup() |>
      as.data.frame() |>
      dplyr::arrange(BroodYear)

  }

}



#' Convert a brood table to a return table
#'
#' @param bt brood table with column names: Stock, BroodYear, and for each age (e.g., Age3). Must be in that format.
#'
#' @return
#' @export
#'
#' @examples
brood_to_return <- function(bt){
  bt |>  dplyr::group_by(Stock) |>
    tidyr::pivot_longer(cols=tidyselect::contains("Age"), names_to="AgeNames", values_to="Return") |>
    dplyr::arrange(AgeNames) |>
    dplyr::mutate(Age=readr::parse_number(AgeNames),
                  ReturnYear=BroodYear+Age) |>
    dplyr::filter(!is.na(Return)) |>
    dplyr::select(Stock, ReturnYear, AgeNames, Return) |>
    tidyr::pivot_wider(names_from=AgeNames, values_from=Return)
}

#
#' Get number of estimated parameters from a built dlm model object
#'
#' @param build built dlm model object
#'
#' @return integer. number of parameters
#'
#' @examples
get_npar <- function(build){

  # process variances (timestep to timestep)
  v_par <- length(which(diag(build$W)>0))

  # regression coeffs plus intercept
  betas <- ncol(build$C0)

  # number of parameters
  v_par + betas

}

#
#' Calculate AICc for a dlm model object given the data and npar
#'
#' @param y response data
#' @param mod dlm model model object
#' @param npar number of parameters
#'
#' @return real, AICc
#' @examples
get_AIC <- function(y, mod, npar, mod_type="dlm"){

  # y <- y[which(!is.na(y))] #
  # print(y)
  # n data points

  n <- length(which(!is.na(y)))

  # Negative log-likelihoods
  if(mod_type=="dlm"){
    nLL <- dlm::dlmLL(y, mod)
  }else{
    nLL=mod$obj$report()$nll
  }
  # Calculate Information Criteria (IC)
  AIC <- 2*npar +  2*nLL

  AICc <- AIC + (2*npar^2 + 2*npar) / (n -npar-1)

  AICc

}


#' Stretching mean
#'
#' @param x a vector of values
#' @param window_size the maximum number of values to include in mean
#'
#' @return
#' @export
#'
stretching_mean <- function(x, window_size = Inf) {
  n <- length(x)

  # If window_size is greater than or equal to the length of x, use cumulative mean
  if (window_size >= n) {
    return(cumsum(x) / seq_along(x))
  }

  # Calculate the stretching mean up to the window size
  stretching_part <- cumsum(x[1:window_size]) / seq_along(x[1:window_size])

  # Apply rolling mean for the rest of the values
  rolling_part <- zoo::rollmean(x, window_size, align = "right", fill = NA)

  # Combine the stretching and rolling parts
  c(stretching_part, rolling_part[(window_size + 1):n])
}


#' Stretching sample SD
#'
#' @param x a vector of errors
#' @param window_size the maximum number of values to include in mean
#' @param sample_sd boolean whether to subtract one from denominator so as to calculate a sample standard deviation. I think this would only be approporiate if bias correction were being applied.
#'
#' @return
#' @export
#'
stretching_samp_sd <- function(x, window_size = Inf, sample_sd=FALSE) {
  n <- length(x)

  # If window_size is greater than or equal to the length of x, use cumulative mean
  if (window_size >= n) {
    (return(sqrt(cumsum(x^2) / seq_along(x)-sample_sd)))
  }

  # Calculate the stretching mean up to the window size
  stretching_part <-sqrt( cumsum((x[1:window_size])^2) / (seq_along(x[1:window_size])-sample_sd))

  # Apply rolling mean for the rest of the values
  rolling_part <- sapply((window_size + 1):n, function(i) {
    sqrt(sum((x[(i - window_size + 1):i])^2)/(window_size-sample_sd))
  })


  # Combine the stretching and rolling parts
  c(stretching_part, rolling_part)
}
