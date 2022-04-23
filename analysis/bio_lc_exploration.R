library(ggplot2)
library(reshape2)

# read in data
bcg <- read.csv("analysis/data/raw/bug_fish_bcg_030522.csv",header = TRUE)
colnames(bcg)[which(colnames(bcg) =="hydroID")] <- "HydroID"
lc_base <- "analysis/data/lc_results/"
filenames <- list.files(path = lc_base, pattern = ".csv")
lcd <- data.frame()

for(i in filenames){
 f <- read.csv(paste0(lc_base,i), header = TRUE)
 if(dim(lcd)[1] == 0){
   lcd <- f
 }
 else{
   lcd <- merge(lcd, f, by = "HydroID")
 }
}

lcd$rc_sqkm <- lcd$rc_cnt / lcd$area_sqkm

# function to determine the available lc year closest to the sample year

closest_lcYr <- function(lc_yrs, samp_yr){
  lc_yrs[which(abs(lc_yrs - samp_yr) == min(abs(lc_yrs - samp_yr)))]
}

# determine the closest lc year to the sample year for all samples

lc_yrs <- c(1985, 1990, 1995, 2002, 2006, 2010, 2015)
bcg$lcYr <- 0

for(i in 1:dim(bcg)[1]){
  bcg[i,which(colnames(bcg)=="lcYr")] <- closest_lcYr(lc_yrs,bcg[i,3])[1]
}

# merge bcg and lcd with static lc variables
lc_stc <- c("area_sqkm", "length_km", "sum_strdrf_pct", "catch_strdrf_pct",
            "slp_mean", "rc_sqkm","HydroID")
bcg_lc <- merge(bcg,lcd[,c(lc_stc)],by = "HydroID")
lc_typ <- c("ag", "coreforest", "dev", "fragforest", "openwater", "wetland")
bcg_lc[lc_typ] <- NA

for(i in 1:dim(bcg_lc)[1]){
  h <- bcg_lc[i,1] #hydroID
  for(j in lc_typ){
    l <- j #lc type
    y <- bcg_lc[i,which(colnames(bcg_lc)=="lcYr")] #lc year for sample
    p <- paste0(l,"_",y) #combine together to find pattern
    r <- lcd[lcd$HydroID == h, grep(pattern = p,names(lcd))] #lc val for sampYr
    bcg_lc[i, which(colnames(bcg_lc)== l)] <- r
  }
}


ggplot(bcg_lc, aes(as.factor(hq),sum_strdrf_pct)) +
  geom_boxplot()

ggplot(bcg_lc, aes(as.factor(lcYr),levPropNum)) +
  geom_boxplot()

kruskal.test(sum_strdrf_pct ~ hq, data = bcg_lc)

cor(bcg_lc[complete.cases(bcg_lc),13:24], method = "kendall")

cor(bcg_lc[complete.cases(bcg_lc),13:24],
    bcg_lc[complete.cases(bcg_lc),9], method = "kendall")








