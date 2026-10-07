library(fastLink)
library(arrow)
library(dplyr)

renv::snapshot()

clean <- read_parquet("data_sampled/cases_sampled.parquet")
corrupted <- read_parquet("data_sampled/corrupted_cases_labeled.parquet")
answers <- read_parquet("data_sampled/cases_answer_key.parquet")

nrow(answers)
nrow(clean)
nrow(corrupted)

glimpse(clean)

clean |> select("ddl_case_id", "")
