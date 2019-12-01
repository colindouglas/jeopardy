library(tidyverse)
library(ggrepel)


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


topScores <- winners %>%
  filter(position == "final") %>%
  group_by(player) %>%
  summarize(games = n(), adjScore = sum(adjScore), date = mean(date)) %>%
  arrange(desc(adjScore))

kj <- games %>% 
  filter(position == "final", player == "Ken Jennings")


topScores %>% 
  filter(games > 10, games < 50) %>%
  ggplot(aes(x = games, y = adjScore)) +
  geom_point() + geom_text_repel(aes(label = player))

winners <- games %>%
  group_by(episode) %>%
  filter(position == "final") %>%
  filter(adjScore == max(adjScore)) %>%
  arrange(adjScore)

losers <- games %>%
  group_by(episode) %>%
  filter(position == "final") %>%
  filter(adjScore != max(adjScore)) %>%
  arrange(adjScore)

losers %>%
  ggplot(aes(x = adjScore)) +
  geom_histogram(data = winners, binwidth = 1000, fill = "green", alpha = 0.3) +
  geom_histogram(data = losers, binwidth = 1000, fill = "red", alpha = 0.3) +
  scale_x_continuous(name = "$") +
  coord_cartesian(ylim = c(0, 500))

topScores %>%
  filter(adjScore < 500000) %>%
ggplot(aes(x = adjScore)) +
  geom_histogram(binwidth = 2000)


chisq <- data_frame(
  x = seq(1, 500000, by = 500),
  y = dchisq(seq(1, 500000, by = 500), 8000000)
)

chisq %>%
  ggplot(aes(x = x, y = y)) +
  geom_line()

games %>%
  filter(position == "coryat") %>%
  ggplot(aes(x = podium, y = adjScore)) +
  geom_boxplot() +
  scale_y_continuous(name = "Coryat Score") +
  scale_x_discrete(name = "Podium Position")

games %>%
  filter(position == "coryat") %>%
  group_by(podium) %>%
  summarize(median_score = median(adjScore), IQR_score = IQR(adjScore))

games %>%
  lm(adjScore ~ podium, data = .) %>%
  broom::tidy()
