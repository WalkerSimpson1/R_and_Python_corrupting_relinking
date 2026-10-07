library(fastLink)
library(arrow)
library(dplyr)

clean <- read_parquet("data_sampled/cases_sampled.parquet") |> as.data.frame()
corrupted <- read_parquet("data_sampled/corrupted_cases_labeled.parquet") |> as.data.frame()
answers <- read_parquet("data_sampled/cases_answer_key.parquet") |> as.data.frame()

nrow(answers)
nrow(clean)
nrow(corrupted)

glimpse(clean)


clean_trimmed <- clean |> 
select(ddl_case_id, 
state_name, 
judge_position, 
disp_name_s, 
date_of_filing, 
date_of_decision, 
district_name,
court_name,
type_name_s,
female_defendant,
female_petitioner)

corrupted_trimmed <- corrupted |>
select(record_id, 
state_name, 
judge_position, 
disp_name_s, 
date_of_filing, 
date_of_decision, 
district_name,
court_name,
type_name_s,
female_defendant,
female_petitioner)


clean_trimmed <- clean_trimmed |>
mutate(
    date_of_filing = as.numeric(date_of_filing),
    date_of_decision = as.numeric(date_of_decision))

corrupted_trimmed <- corrupted_trimmed |>
mutate(
    date_of_filing = as.numeric(date_of_filing),
    date_of_decision = as.numeric(date_of_decision)
)


blocks <- blockData(
    dfA = corrupted_trimmed,
    dfB = clean_trimmed,
    varnames = c("state_name", "judge_position", "disp_name_s")
)

length(blocks)
