library(rvest)
library(tidyverse)

# Clean up any raw clue data leftover from last time that we may have missed
source("clues-cleanup.R")

# Get the delay from robots.txt
source("robotstxt-delay.R")

# Function for scraping HTML boards of games, given a list of game IDs
# Returns the raw HTML of the game page in a list, for future parsing
get_game <- function(gameID) {
  url <- paste0("http://www.j-archive.com/showgame.php?game_id=", gameID)
  Sys.sleep(delay)
  message(paste0("Fetching game @ ", url))
  read_html(url)
}

get_games <- function(gameIDs) map(gameIDs, ~ get_game(.))

# Parses the HTML of a game page into a df of clues
get_clues <- function(html) {
  
  header <- html %>%
    html_node("h1") %>%
    html_text() %>%
    strsplit(" - ") %>%
    unlist()
  
  game_id <- as.numeric(str_extract(header[1], "[0-9]+"))
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
                      response = map(clue_answers, ~ .[!(. %in% bad_strings)])) %>%
    rowwise() %>%
    mutate(response = paste(response, collapse = " "))
  
  # Pull out the raw clue text
  clues_raw <- html %>%
    html_nodes(".clue") %>%
    html_text() %>%
    str_split("\\n")
  
  # Final Jep extraction
  final_answer <- answers_raw[grepl("clue_FJ", answers_raw)] %>% 
    str_extract('"correct_response.*</em>') %>%
    paste0("<", .) %>%
    gsub('<.*?>', ' ', .) %>%
    trimws()
  
  # Construct the data frame
  clue_df <- tibble(episode = game_id,
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
    add_row(episode = game_id,
            date = game_date,
            round = "FJ",
            row = 1,
            col = 1, 
            category = categories[13],
            value = NA,
            pick_order = NA,
            #clue = trimws(clues_raw[[61]][[2]]),
            clue_index = "clue_FJ_1_1",
            response = final_answer) %>%
    mutate(dailydouble = grepl("DD", value)) %>%
    mutate(value = str_extract(value, "[0-9]+") %>% as.numeric()) %>%
    mutate(response = ifelse(response == "NULL", NA, as.character(response)))
  
  message("Found ", nrow(clue_df), " clues from game on ", game_date)
  
  return(clue_df)
}


# Read in a list of games we know about
games_all <- read_csv(file = "data/all_games.csv", col_types = cols()) %>%
  arrange(desc(date)) %>%
  distinct(gameID, episode)

# Load the clues we've already scraped
all_clues <- read_csv("data/clues_clean.csv", col_types = cols()) %>% 
  select(-response_clean, -q_number)

all_clues_dist <- all_clues %>%
  distinct(episode)

# Find the games we haven't scraped yet
games_todo <- anti_join(games_all, all_clues_dist, by = "episode") %>% pull(gameID)

# Using a for loop, don't care
for (game_id in games_todo) {
      # Get the gameboard
      gameboard <- get_game(game_id)
      
      # Get the clues from the gameboard
      clues <- get_clues(gameboard)
      
      # Add the new clues to the df of clues
      all_clues <- bind_rows(all_clues, clues)
      
      # Write the raw clues to a CSV at each step, so we can bail mid-process without losing data
      write_csv(all_clues, path = "data/clues_raw.csv", na = "")
}

# Cleanup the raw clue data at the end
source("clues-cleanup.R")


