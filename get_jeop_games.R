library(rvest)
library(tidyverse)
library(stringr)


GetJeopGame <- function(gameID) {
  print(paste("Fetching game #", gameID))
  Sys.sleep(0.5)

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
  
 #  return(data_frame(gameID, length = length(scores))) #debug
 
 if(length(scores) == 15) {
   gameInfo <- data_frame(gameID,
                          episode = number,
                          date,
                          podium = factor(rep(1:3, 5), levels = 1:3),
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
   return(data_frame(gameID,
                     episode = NA,
                     date = NA,
                     podium = NA,
                     player = NA,
                     position = NA,
                     score = NA)
   )
 }
 
}

gamesScraped <- map_dfr(1:5902, ~ GetJeopGame(.)) 

games <- gamesScraped %>%
  mutate(adjScore = case_when(
    date < as.Date("26-Nov-2001", format = "%d-%b-%Y") ~ score * 2,
    date >= as.Date("26-Nov-2001", format = "%d-%b-%Y") ~ score
  ))

write_csv(games, "data/all_games.csv")