# import required libraries
library(terra)
library(stringr)

# raster references
# https://cran.rstudio.com/web/packages/terra/terra.pdf
# https://rspatial.org/terra/spatial/Spatialdata.pdf
# https://rspatial.org/terra/analysis/analysis.pdf


# set working directory
setwd("D:/HQEval_spatial_data/")

r_path <- "raster/"
sf_path <- "vector/"

# functions to cycle through lc years, reclassify for a particular land cover
# and calc zonal stats for catchment polys(i.e. pct lc by catchment)

# assumes .tif file ending with year (e.g. "landcover_1985.tif")
# r_files = raster file list, l_spec = landcover reclass specifictions (matrix)
# l_type = type of land cover being reclassified
reclass_lc <- function(r_file,l_spec,l_type){
  for (i in 1:(length(r_file))){
    lc_yr <- str_sub(r_file[i],-8,-5)
    lc <- rast(paste0(r_path,r_file[i]))
    rc <- classify(lc, mat,include.lowest=FALSE)
    writeRaster(rc,paste0("raster/ag_",lc_yr,".tif"),overwrite=TRUE)
  }
}

extract_lc <- function(r_file,poly,l_type){
  for (i in 1:(length(r_file))){
    lc_yr <- str_sub(r_file[i],-8,-5)
    lc <- rast(paste0(r_path,r_file[i]))
    l_ex <- extract(lc, poly, fun=function(x,...)length(na.omit(x)),df=TRUE)
    ex <- extract(lc, poly, fun=sum, na.rm=TRUE, df=TRUE)
    df <- data.frame(poly$HydroID,l_ex[,2],ex[,2])
    df[,3] <- df[,3]-1
    df$pct <- df[,3]/df[,2]
    colnames(df) <- c("HydroID","cnt",paste0(l_type,"_",lc_yr,"_sum"),paste0(l_type,"_",lc_yr,"_pct"))
    write.csv(df,paste0(l_type,"_",lc_yr,".csv"),row.names=FALSE)
  }
}

# list files
grids    <- list.files(r_path, pattern = "*.tif$")
lc_grids <- list.files(r_path, pattern = "landcover_*")
ag_grids <- list.files(r_path, pattern = "ag_*")

### reclassify #################################################################
c_spec <- cbind(from = c(-Inf, 3, 4), to = c(3, 4, Inf), becomes = c(0, 1, 0))
c_type <- "ag"

reclass_lc(lc_grids,c_spec,c_type)

ag <- rast(paste0(r_path,'ag_1985.tif'))

### extract by poly ############################################################

#read-in the polygon shapefile
poly <- vect(paste0(sf_path,"Catchments01_CT.shp"))

#import raster file
# s <- rast(paste0(rf_path, grids))
# l <- extract(s, poly, fun=function(x,...)length(na.omit(x)),df=TRUE)
# 
# l <- data.frame(poly$HydroID,l[,2])
# colnames[l] <- c("HydroID","Cnt")

extract_lc(ag_grids,poly,"ag")

