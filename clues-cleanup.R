library(tidyverse)
library(tidytext)

message("Cleaning up clues.csv >> clues.db")

round_abbrev <- c("J" = "J",
                  "DJ" = "D",
                  "FJ" = "F")

clues <- read_csv(file = "data/clues.csv", col_types = cols())  %>%
  mutate(q_number = paste0(episode, round_abbrev[round], row, col),
         date = format(date, "%b %d, %Y")) %>%
  distinct(q_number, .keep_all = TRUE) 

# This takes the stop words out of the responses
responses_no_stopwords <- clues %>%
  unnest_tokens(., word, response) %>%
  anti_join(stop_words, by = c("word" = "word")) %>%
  group_by(q_number) %>%
  summarize(response_clean = paste(word, collapse = ' '))

# I honestly have no idea what I'm doing here
# But I'm sure there's a good reason for it
clues_clean <- clues %>%
  mutate(category = gsub("\\(.+\\)", "", category),
         response = gsub("\\(.+\\)", "", response),
         response = gsub("([\\])", "", response)) %>%
  filter(!is.na(value)) %>%
  left_join(responses_no_stopwords, by = "q_number")

#write_csv(clues_clean, path = "data/clues_clean.csv", na = "")

# Make SQL connection, write table
source("SQL-connection.R")

field_types <- toupper(
  c("episode" = "integer" , 
                 "date" = "character", 
                 "round" = "character", 
                 "row" = "integer", 
                 "col" = "integer", 
                 "category" = "character", 
                 "value" = "integer", 
                 "pick_order" = "integer", 
                 "clue" = "text", 
                 "clue_index" = "character", 
                 "response" = "text", 
                 "dailydouble" = "logical", 
                 "q_number" = "character",
                 "response_clean" = "text"))


DBI::dbWriteTable(con = cluedb, name = "clues", value = clues_clean, overwrite = TRUE, field.types = field_types)
DBI::dbDisconnect(cluedb)
