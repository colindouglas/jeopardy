library(tidyverse)
games <- read_csv("data/all_games.csv") %>%
  mutate(position = factor(position, levels = c("commercial", "beforeDJ", "beforeFJ", "final", "coryat")),
         podium = factor(podium, levels = 1:3))

games %>%
  filter(!(position %in% c("coryat", NA))) %>%
  ggplot(aes(x = position, y = score)) +
  geom_line(aes(group = interaction(podium, episode), color = podium))
 
 games %>%
  filter(position == "final") %>%
  ggplot(aes(x = adjScore)) +
  geom_density(aes(fill = podium), alpha = 0.3)


topScores <- games %>%
  filter(position == "final") %>%
  group_by(player) %>%
  summarize(games = n(), adjScore = sum(adjScore), date = mean(date)) %>%
  arrange(desc(adjScore))

kj <- games %>% 
  filter(position == "final", player == "Ken Jennings")

library(ggrepel)
topScores %>% 
  filter(games > 10, games < 50) %>%
  ggplot(aes(x = games, y = adjScore)) +
  geom_point() + geom_text_repel(aes(label = player))

winners <- games %>%
  group_by(episode) %>%
  filter(position == "final") %>%
  filter(adjScore == max(adjScore))

losers <- games %>%
  group_by(episode) %>%
  filter(position == "final") %>%
  filter(adjScore != max(adjScore))

losers %>%
  ggplot(aes(x = adjScore)) +
  geom_density(data = winners, fill = "green", alpha = 0.3) +
  geom_density(data = losers, fill = "red", alpha = 0.3)