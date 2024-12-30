## code to prepare `summer_chinook_2024` dataset goes here

summer_chinook_2024<-readxl::read_xlsx("data-raw/data/SummerChinook.xlsx",sheet=1)


usethis::use_data(summer_chinook_2024, overwrite = TRUE)


