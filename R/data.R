#' Summer chinook returns through 2024
#'
#' Output of TAC summer Chinook managment season run reconstructions through return to the Columbia River mouth year 2024
#'
#' @format ## `summer_chinook_2024`
#' A tibble with 28 rows and 6 columns
#' \describe{
#'   \item{BroodYear}{Brood year}
#'   \item{Age3, Age4, Age5, Age6}{returns by age}
#'   \item{Stock}{name of stock}
#'   ...
#' }
"summer_chinook_2024"



#' Table of predictors
#'
#' Various predictors pulled from the internet
#'
#' @format ## `covariates_24`
#' A tibble with 65 rows and 11 columns
#' \describe{
#'   \item{ReturnYear}{Brood year}
#'   \item{lag1_PDO lag2_PDO lag1_NPGO lag2_NPGO  lag1_fall_Nino3.4 lag2_fall_Nino3.4 smolt_sock lag1_log_socksmolt lag2_log_socksmolt pink_ind}{pssoble predictors: climate indices, sockeye smolt indices at Boneville Dam, and even-odd year index meants to represent the pink salmon cycle}
#'   ...
#' }
"covariates_24"
