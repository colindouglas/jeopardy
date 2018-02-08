library(rvest)
library(tidyverse)
library(stringr)

GetJeopGame <- function(gameID) {
  Sys.sleep(1)
  
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
    unlist()
  
  scores <- html_scrape %>%
    html_nodes(".score_positive") %>%
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
    return(data_frame(""))
  }
}

firstGameID <- 5902

games <- map_dfr(5890:5902, ~ GetJeopGame(.))

games %>%
  filter(position != "coryat") %>%
  ggplot(aes(x = position, y = score)) +
  geom_point(aes(color = podium)) +
  geom_smooth(aes(group = podium, color = podium))
#  geom_line(aes(group = interaction(podium, episode), color = podium))

games %>%
  filter(position == "final") %>%
  ggplot(aes(x = score)) +
  geom_density(aes(fill = podium), alpha = 0.3)
