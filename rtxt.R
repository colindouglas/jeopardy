library(robotstxt)
# Get the crawl delay from robots.txt
rtxt <- robotstxt("https://j-archive.com")
delay <- as.numeric(rtxt$crawl_delay$value)