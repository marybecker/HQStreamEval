library(randomForest)
library(e1071)

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

hqrf <- randomForest(train[,9:ncol(train)],hqpa)

varImpPlot(hqrf)

hqpd <- as.data.frame(predict(hqrf, test))

hq_test_pd <- cbind(test,hqpd)
colnames(hq_test_pd)[21] <- "pdhq"

hq_test_pd$correct <- hq_test_pd$hq == hq_test_pd$pdhq

dim(hq_test_pd[hq_test_pd$correct == TRUE & hq_test_pd$hq ==1,])[1]/ dim(hq_test_pd[which(hq_test_pd$hq ==1), ])[1]


