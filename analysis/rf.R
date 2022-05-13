library(randomForest)
library(sf)
library(rmapshaper)
library(jsonlite)


bcg_lc <- read.csv("analysis/data/raw/bcg_lc_042922.csv", header = TRUE)
bcg_lc <- bcg_lc[,c(1:4,9:24)]
bcg_lc <- bcg_lc[complete.cases(bcg_lc),]

bcg_lc_1 <- bcg_lc[bcg_lc$hq==1, ]
bcg_lc_0 <- bcg_lc[bcg_lc$hq==0, ]
i <- sample(nrow(bcg_lc_0),704)
bcg_lc_0 <- bcg_lc_0[i, ]

bcg_lc <- rbind(bcg_lc_1, bcg_lc_0)
i <- sample(nrow(bcg_lc), nrow(bcg_lc))
bcg_lc <- bcg_lc[i, ]



i <- sample(nrow(bcg_lc),0.2 * nrow(bcg_lc))
test <- bcg_lc[i,]
train <- bcg_lc[-i,]

hqpa <- as.factor(train[, 'hq'])
# trf <- tuneRF(train[,8:ncol(train)], train[, "levPropNum"])
# mt <-  trf[which.min(trf[,2]), 1]
# hqrf <- randomForest(train[,8:ncol(train)], train[, "levPropNum"], mtry=mt, 
#                      ntree=250)

hqrf <- randomForest(train[,c(12,15:17,19:20)],hqpa)
hqrf
varImpPlot(hqrf)

partialPlot(hqrf, train, coreforest)

# hqpd <- as.data.frame(predict(hqrf, test,type="prob"))
hqpd <- as.data.frame(predict(hqrf, test))

hq_test_pd <- cbind(test,hqpd)
colnames(hq_test_pd)[21] <- "pdhq"

hq_test_pd$correct <- hq_test_pd$hq == hq_test_pd$pdhq

dim(hq_test_pd[hq_test_pd$correct == TRUE & hq_test_pd$hq ==1,])[1]/ dim(hq_test_pd[which(hq_test_pd$hq ==1), ])[1]

## Predict for all catchments using most recent landcover data set (2015)

catch <- st_read(dsn = "data/catchments.geojson",
                 layer = "catchments")
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

lc_typ <- c("ag", "coreforest", "dev", "fragforest", "openwater", "wetland")

lc_stc <- c("HydroID","area_sqkm", "length_km", "sum_strdrf_pct", 
            "catch_strdrf_pct", "rc_sqkm", "ag_2015_pct", 
            "coreforest_2015_pct", "dev_2015_pct", "fragforest_2015_pct",
            "openwater_2015_pct" ,"wetland_2015_pct")

lcd <- lcd[ , lc_stc]
colnames(lcd)[7:12] <- lc_typ

lcd <- lcd[which(lcd$HydroID %in% catch$HydroID), ]
lcd <- lcd[complete.cases(lcd), ]
lcd <- lcd[which(is.finite(lcd$sum_strdrf_pct)),]


r <- seq(0.01, 0.20, by = 0.01)
lcdp <- as.data.frame(predict(hqrf, lcd, type="prob"))
colnames(lcdp)[2] <- "hqp"

for(i in 1:length(r)){
  lcd_alt <- lcd
  lcd_alt$coreforest  <- lcd_alt$coreforest - r[i]
  lcd_alt$dev         <- lcd_alt$dev + r[i]
  lcdp_alt <- as.data.frame(predict(hqrf, lcd_alt, type="prob"))
  colnames(lcdp_alt)[2] <- paste0("cfr_",r[i]*100)
  lcdp <- cbind(lcdp, lcdp_alt)
}

c <- seq(2, 42, by = 2)

lcdp <- cbind(lcd, lcdp[ ,c(c)])
lcdp_hq <- lcdp[lcdp$hqp >= 0.5, ]
row.names(lcdp_hq) <- lcdp_hq$HydroID
catch <- catch[catch$HydroID %in% lcdp_hq$HydroID, ]
# catch <- merge(catch, lcdp, by = "HydroID")
catch <- ms_simplify(catch, keep = 0.1, keep_shapes = TRUE)

sf::st_write(catch,
             dsn = "data/catchments_hq.geojson",
             layer = "catchments_hq.geojson",
             append = FALSE)

lcdp_hq_to_json <- data.frame(HydroID = lcdp_hq$HydroID, 
                              lcd = lcdp_hq$cfr_1)
lcdp_hq_json <- jsonlite::toJSON(lcdp_hq, dataframe = "rows", pretty = TRUE)
write(lcdp_hq_json, "data/pred_hq.json")




sum(lcdp[lcdp$hqp >= 0.5, c("length_km")])
sum(lcdp[lcdp$cfr_2 >= 0.5, c("length_km")])
sum(lcdp[lcdp$cfr_10 >= 0.5, c("length_km")])


