if (file.exists("data/clues_raw.csv")) {
  
  clues_raw <- read_csv(file = "data/clues_raw.csv") %>%
    mutate(q_number = paste(episode, "-", case_when(round == "J" ~ "J",
                                                    round == "DJ" ~ "D",
                                                    round == "FJ" ~ "F",
                                                    TRUE ~ "X"), row, col, sep = ""))
  
  if (file.exists("data/clues_clean")) {
    clues_clean <- read_csv(file = "data/clues_clean.csv")# %>%
    #select(names(clues_raw))
    
    clues <- bind_rows(clues_clean, clues_raw) %>%
      distinct(episode, round, row, col, value, .keep_all = TRUE)
    
  } else {
    clues <- clues_raw
  }
  
  # This takes the stop words out of the responses
  responses_no_stopwords <- clues %>%
    unnest_tokens(word, response) %>% 
    anti_join(stop_words, by = c("word" = "word")) %>%
    group_by(q_number) %>% 
    summarise(response_clean = paste(word, collapse =' '))
  
  # I honestly have no idea what I'm doing here
  # But I'm sure there's a good reason for it
  clues_clean <- clues %>%
    mutate(category = gsub("\\(.+\\)", "", category),
           response = gsub("\\(.+\\)", "", response),
           response = gsub("([\\])", "", response)) %>%
    filter(!is.na(value)) %>%
    left_join(responses_no_stopwords, by = "q_number")
  
  write_csv(clues_clean, path = "data/clues_clean.csv", na = "")
}
