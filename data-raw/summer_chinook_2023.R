## code to prepare `summer_chinook_2023` dataset goes here

summer_chinook_2023<-readxl::read_xlsx("data-raw/data/SummerChinook.xlsx",sheet=1)


usethis::use_data(summer_chinook_2023, overwrite = TRUE)
