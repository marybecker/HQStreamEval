library(lubridate)

# read in data

f <- read.csv("analysis/data/raw/fish_bcg_030522.csv",header=TRUE)
b <- read.csv("analysis/")


summary(raw_f$reachLen)

unique(substr(raw_f$date,6,7))
