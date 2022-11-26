library(jsonlite)

pred_hq <- fromJSON("data/pred_hq.json", flatten=TRUE)
catch   <- read.csv("analysis/data/drainage_area_length.csv", header = TRUE)

for(i in 1:21){
  n <- 14 + i
  hq_cat_length_km <- ifelse(pred_hq[,n] > 0.5, pred_hq$cat_length_km, 0)
  pred_hq <- cbind(pred_hq, hq_cat_length_km)
  colnames(pred_hq)[length(pred_hq)] <- paste("l_cfr_",i-1)
}


pred_length_hq <- merge(catch[], pred_hq[,c(1,36:56)], 
                        by = "HydroID", all = TRUE)

write.csv(pred_length_hq[,c(1,4:24)],
          "analysis/data/pred_hq_length.csv", row.names = FALSE)

##Create json from calculated length of hq

hq_length <- read.csv("analysis/data/lc_results/statewide_pred_hq_length_accum_attr.csv",
                      header = TRUE)
hq_length <- hq_length[hq_length$HydroID %in% pred_hq$HydroID,]
hq_length_JSON <- toJSON(hq_length[,c(22,1:21)], 
                         dataframe = "rows", pretty = TRUE)
write(hq_length_JSON, "data/length_hq.json")

  
