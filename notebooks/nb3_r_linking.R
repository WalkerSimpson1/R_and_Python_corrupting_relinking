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

table(clean_trimmed$state_name)
dfA_test <- corrupted_trimmed |> filter(state_name == "Uttarakhand")
dfB_test <- clean_trimmed |> filter(state_name == "Uttarakhand")
nrow(dfA_test)
nrow(dfB_test)

fl_test <- fastLink(
    dfA = dfA_test,
    dfB = dfB_test,
    varnames = c("judge_position",
                    "disp_name_s",
                    "date_of_filing",
                    "date_of_decision",
                    "district_name",
                    "court_name",
                    "type_name_s",
                    "female_defendant",
                    "female_petitioner"),
    stringdist.match = c("district_name", "court_name"),
    numeric.match= c("date_of_filing", "date_of_decision")
)

summary(fl_test)

test_matches <- data.frame(
    record_id = dfA_test$record_id[fl_test$matches$inds.a],
    ddl_case_id = dfB_test$ddl_case_id[fl_test$matches$inds.b]
)

nrow(test_matches)
head(test_matches)
test_checked <- test_matches |> left_join(answers, by = "record_id")

nrow(test_checked)
head(test_checked)

precision_test <- mean(test_checked$ddl_case_id.x == test_checked$ddl_case_id.y)
precision_test

recall_test <- sum(test_checked$ddl_case_id.x == test_checked$ddl_case_id.y) / nrow(dfA_test)
recall_test

states <- unique(clean_trimmed$state_name)

all_matched <- list()

for (s in states) {
    print(s)
    if (s %in% names(all_matched)) next
    dfA_s <- corrupted_trimmed |> filter(state_name == s)
    dfB_s <- clean_trimmed |> filter(state_name == s)
    if (nrow(dfA_s) < 20) next
    fl_s <- fastLink(
        dfA = dfA_s, 
        dfB = dfB_s,
        varnames = c("judge_position",
                    "disp_name_s",
                    "date_of_filing",
                    "date_of_decision",
                    "district_name",
                    "court_name",
                    "type_name_s",
                    "female_defendant",
                    "female_petitioner"),
        stringdist.match = c("district_name", "court_name"),
        numeric.match= c("date_of_filing", "date_of_decision"), 
        n.cores = 1
    )
    all_matched[[s]] <- data.frame(
    record_id = dfA_s$record_id[fl_s$matches$inds.a],
    ddl_case_id = dfB_s$ddl_case_id[fl_s$matches$inds.b]
    )
}
setdiff(states, names(all_matched))
skipped <- setdiff(states, names(all_matched))
sum(corrupted_trimmed$state_name %in% skipped)
table(corrupted_trimmed$state_name[corrupted_trimmed$state_name %in% skipped])
final_r <- bind_rows(all_matched)
final_r |> write_parquet("data_sampled/final_r.parquet")

research_result_r <- final_r |> left_join(answers, by = "record_id", suffix = c("", "_true"))

correct_r <- sum(research_result_r$ddl_case_id == research_result_r$ddl_case_id_true)
precision <- correct_r / nrow(research_result_r)
precision
recall <- correct_r / 50000
recall
