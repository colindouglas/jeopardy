# Get Tidy Jeopardy Games

These scripts scrape data about Jeopardy games from [J! Archive](https://www.j-archive.com). 

`get_jeop_games.R` scrapes general game info, such as contestant, score at each commercial break, and podium position. Data are saved in `data/all_games.csv`. This dataset was last updated February 2018.

`get_clues.R` uses the data from scraped in `get_jeo_games.R` to scrape the clues and responses from each board. Data are saved in `data/clues_clean.csv`. It is presently only a subset of clues, scraped mainly to test if the script works.
