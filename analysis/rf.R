library(randomForest)
library(e1071)

bcg_lc <- read.csv("analysis/data/raw/bcg_lc_042922.csv", header = TRUE)
bcg_lc <- bcg_lc[,c(1:4,9:24)]

bcg_lc <- bcg_lc[complete.cases(bcg_lc),]

set.seed(123)
i <- sample(nrow(bcg_lc),0.2 * nrow(bcg_lc))
test <- bcg_lc[i,]
train <- bcg_lc[-i,]

hqpa <- as.factor(train[, 'hq'])
trf <- tuneRF(train[,8:ncol(train)], train[, "levPropNum"])
mt <-  trf[which.min(trf[,2]), 1]

hqrf <- randomForest(train[,8:ncol(train)], train[, "levPropNum"], mtry=mt, 
                     ntree=250)

varImpPlot(hqrf)

hqpd <- as.data.frame(predict(hqrf, test))

hq_test_pd <- cbind(test,hqpd)
colnames(hq_test_pd)[21] <- "pdhq"

hq_test_pd$correct <- hq_test_pd$hq == hq_test_pd$pdhq

dim(hq_test_pd[hq_test_pd$correct == TRUE & hq_test_pd$hq ==1,])[1]/dim(hq_test_pd)[1]

#helper function to calcultae how good we are doing...
get_class<-function(P){
  C <- vector(mode='numeric',length=dim(P)[1]);
  b <- 1/dim(P)[1]; #cuttoff point for class models
  for(i in 1:dim(P)[1]){  #for each row
    C[i] <- which.max(P[i,])-1; #take the maximum estimate of the classes
  }
  C
}

get_accuracy<-function(T,P){
  S <- vector(mode='numeric',length=length(T));
  for(i in 1:length(T)){
    if(T[i]==1 && P[i]==1){ S[i] <- 1; }
  }
  n <- sum(S)/sum(T); #proportion of true correct
  m <- sum(S)/sum(P); #proportion of guesses correct
  2*(n*m)/(n+m)       #harmonic mean (F1 accuracy measure)
}

S  <- svm(as.factor(hq) ~ coreforest + rc_sqkm + ag + slp_mean + openwater + wetland, data = train, kernel='radial',gamma=0.25,cost=0.5) #look at the radial kernel above...
P1 <- predict(S,test)

t_prd <- cbind(test,P1)
t_prd$correct <- t_prd$hq == t_prd$P1
get_accuracy(t_prd$hq, t_prd$P1)


