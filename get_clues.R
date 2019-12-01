library(rvest)
library(tidyverse)
library(tidytext)


## Function for scraping HTML boards of games, given a start ID and an end ID
get_games <- function(gameIDs) {
  map(gameIDs, function(gameID) {
    Sys.sleep(2)
    print(paste0("Fetching game ", gameID))
    return(read_html(paste0("http://www.j-archive.com/showgame.php?game_id=", gameID)))
  })
}

## Function to get the clues from the HTML board of a game
get_clues <- function(html) {
  
  header <- html %>%
    html_node("h1") %>%
    html_text() %>%
    strsplit(" - ") %>%
    unlist()
  
  game_id <- str_extract(header[1], "[0-9]+")
  game_date <- lubridate::mdy(header[2])

  # Extract the categories
  categories <- html %>%
    html_nodes(".category") %>%
    html_text() %>%
    str_replace_all(., "\n", "") %>%
    trimws(.)
  
  # Extract the raw response 
  answers_raw <- html %>%
    html_nodes("table tr td div") %>%
    html_attr("onmouseover")
  
  # Extract the clue position from the response
  clue_positions <- answers_raw %>%
    str_extract("clue_(DJ|J)_[1-6]_[1-5]")
  
  # Extract the clue answer from the response (technically the question)
  clue_answers <- answers_raw %>%
    str_extract('"correct_response\\".*</em>') %>% 
    str_split(., pattern = "[><]")
  
  # A list of things to chop out of the answer
  bad_strings <- c('\"correct_response\"', '/em', 'i', '', '/i')
  
  # Make a dataframe of responses by position
  responses <- tibble(clue_index = clue_positions,
                      response = map(clue_answers, ~ .[!(. %in% bad_strings)]))
  
  # Pull out the raw clue text
  clues_raw <- html %>%
    html_nodes(".clue") %>%
    html_text() %>%
    str_split("\\n")
  
  # Final Jep extraction
  final_answer <- answers_raw[grepl("clue_FJ", answers_raw)] %>% 
    str_extract('"correct_response.*</em>') %>%
    str_split(., pattern = "[<>]") %>%
    unlist()
  
  # Construct the data frame
  clue_df <- tibble(number = game_id,
                    date = game_date,
                    round = rep(c("J", "DJ"), each = 30),
                    row = c(rep(1:5, each = 6), rep(1:5, each = 6)),
                    col = c(rep(1:6, times = 5), rep(1:6, times = 5)),
                    category = c(rep(categories[1:6], times = 5), rep(categories[7:12], times = 5)),
                    value = map(clues_raw, ~ .[5])[1:60] %>% unlist(),
                    pick_order = as.numeric(unlist(map(clues_raw, ~ .[6])[1:60])),
                    clue = trimws(map(clues_raw, ~ .[9]))[1:60]) %>%
    mutate(clue_index = paste0("clue_", round, "_", col, "_", row)) %>%
    left_join(responses, by = "clue_index") %>%
    add_row(number = game_id,
            date = game_date,
            round = "FJ",
            row = 1,
            col = 1, 
            category = categories[13],
            value = NA,
            pick_order = NA,
            #clue = trimws(clues_raw[[61]][[2]]),
            clue_index = "clue_FJ_1_1",
            response = final_answer[2]) %>%
    mutate(dailydouble = grepl("DD", value)) %>%
    mutate(value = gsub(pattern = "DD:", replacement = "", x = value),
           value = gsub(pattern = "[$,]", replacement = "", x = value)) %>%
    mutate(response = ifelse(response == "NULL", NA, as.character(response)))
  
  
  return(clue_df)
}


# Get the games
games <- read_csv(file = "data/all_games.csv") %>% 
  pull(gameID) %>% 
  unique() %>% 
  get_games()

clues <- map_dfr(games, ~ get_clues(.)) %>%
  mutate(q_number = paste(number, "-", case_when(round == "J" ~ "J",
                                                 round == "DJ" ~ "D",
                                                 round == "FJ" ~ "F",
                                                 TRUE ~ "X"), row, col, sep = ""))

clues %>%
  write_csv(path = "data/clues_raw.csv", na = "")

responses_no_stopwords <- clues %>%
  unnest_tokens(word, response) %>% 
  anti_join(stop_words, by = c("word" = "word")) %>%
  group_by(q_number) %>% 
  summarise(response_clean = paste(word,collapse =' '))

clues_clean <- clues %>%
  mutate(category = gsub("\\(.+\\)", "", category),
         response = gsub("\\(.+\\)", "", response),
         response = gsub("([\\])", "", response)) %>%
  filter(!is.na(value)) %>%
  left_join(responses_no_stopwords, by = "q_number")


clues_clean %>%
  write_csv(path = "data/clues_clean.csv", na = "")
