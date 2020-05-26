library(rvest)
library(tidyverse)
library(stringr)

# Get the delay from robots.txt
source("robotstxt-delay.R")

stop_at <- 6664
chunk_size <- 20  # Write to output every x games
last <- 0

GetJeopGame <- function(gameID) {
  message("Fetching game #", gameID)
  Sys.sleep(delay)
  
  url <- paste0("http://www.j-archive.com/showgame.php?game_id=", gameID)
  
  html_scrape <- read_html(url)
  
  ### Get the episode date
  header <- html_scrape %>%
    html_node("h1") %>%
    html_text() %>%
    strsplit(" - ") %>%
    unlist()
  
  number <- str_extract(header[1], "[0-9]+")
  date <- as.Date(header[2], format = "%A, %B %d, %Y")
  
  players <-  html_scrape %>%
    html_nodes(".contestants") %>%
    html_text() %>%
    strsplit(",") %>%
    map(~ .[1]) %>%
    unlist() %>%
    rev()
  
  scores <- html_scrape %>%
    html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "score_positive", " " ))] | //*[contains(concat( " ", @class, " " ), concat( " ", "score_negative", " " ))]') %>%
    html_text() %>%
    gsub('\\$|,', '', .) %>%
    as.numeric()
  
  if(length(scores) == 15) {
    gameInfo <- tibble(gameID,
                           episode = as.numeric(number),
                           date,
                           podium = rep(1:3, 5),
                           player = rep(players, 5),
                           position = factor(c(
                             rep("commercial", 3),
                             rep("beforeDJ", 3),
                             rep("beforeFJ", 3),
                             rep("final",    3),
                             rep("coryat", 3)), levels = c("commercial", "beforeDJ", "beforeFJ", "final", "coryat")),
                           score = scores)
    return(gameInfo)
  } else {
    return(tibble(gameID,
                      episode = NA,
                      date = NA,
                      podium = NA,
                      player = NA,
                      position = NA,
                      score = NA)
    )
  }
  
}


while (last < stop_at) {
  
  # Find the last game scraped
  if (file.exists("data/all_games.csv")) {
    last <- read_csv("data/all_games.csv", col_types = cols()) %>%
      pull(gameID) %>% max()
  } else {
    last <- 0
  }
  
  # If we've scraped the last game, stop
  if (last >= stop_at) break
  
  gamesScraped <- map_dfr((last + 1):(last + chunk_size), ~ GetJeopGame(.)) 
  
  new_games <- gamesScraped %>%
    mutate(adjScore = case_when(
      date < as.Date("26-Nov-2001", format = "%d-%b-%Y") ~ score * 2,
      date >= as.Date("26-Nov-2001", format = "%d-%b-%Y") ~ score
    ))
  
  # Write the output
  if (file.exists("data/all_games.csv")) {
    old_games <- read_csv("data/all_games.csv", col_types = cols())
    games <- bind_rows(old_games, new_games) 
  } else {
    games <- new_games
  }
  write_csv(games, "data/all_games.csv")
  message("Writing after ", last + chunk_size)
}
