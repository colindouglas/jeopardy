# Jeopardy Questions

These scripts scrape data about Jeopardy games from [J! Archive](https://www.j-archive.com).

* `get-games.R` scrapes general game info, such as contestant, score at each commercial break, and podium position. Data are saved in `data/games.csv`. This data set was last updated May 2020.
* `get-clues.R` uses the data from scraped in `get-games.R` to scrape the clues and responses from each board. Data are saved in `data/clues.csv`.
  * As of May 2020, the clues data set not exhaustive, and only contains about 100 games worth of clues.
* `clues-cleanup.R` does some minor text processing, then writes the data to a SQLite table called `clues` at `flask/clues.db`.
* `SQL-connection.R` and `rt-delay.R` are helper scripts to set an SQL connection and get the delay parameter from robots.txt respectively.
* `flask/` contains a Flask app that randomly serves up a Jeopardy question
