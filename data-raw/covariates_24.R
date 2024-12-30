## code to prepare `covariates_24` dataset goes here
covariates_24<-read_csv(here::here("data-raw","data","covariates.csv")) |> rename("ReturnYear"="year")

usethis::use_data(covariates_24, overwrite = TRUE)
