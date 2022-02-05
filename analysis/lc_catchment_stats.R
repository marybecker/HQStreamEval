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

### functions ##################################################################

# functions to cycle through lc years, reclassify for a particular land cover
# and calc zonal stats for catchment polys(i.e. pct lc by catchment)

# assumes .tif file ending with year (e.g. "landcover_1985.tif")
# r_files = raster file list, l_spec = landcover reclass specifictions (matrix)
# l_type = type of land cover being reclassified
reclass_lc <- function(r_file,l_spec,l_type){
  for (i in 1:(length(r_file))){
    lc_yr <- str_sub(r_file[i],-8,-5) # get year
    lc <- rast(paste0(r_path,r_file[i])) # read in raster file
    rc <- classify(lc, mat,include.lowest=FALSE) # reclassify
    writeRaster(rc,paste0("raster/ag_",lc_yr,".tif"),overwrite=TRUE)
  }
}

extract_lc <- function(r_file,poly,l_type){
  for (i in 1:(length(r_file))){
    lc_yr <- str_sub(r_file[i],-8,-5) #get year
    lc <- rast(paste0(r_path,r_file[i])) #read in raster file
    # calc total cnt of pixels
    l_ex <- extract(lc, poly, fun=function(x,...)length(na.omit(x)),df=TRUE)
    # calc sun of (0,1) pixels
    ex <- extract(lc, poly, fun=sum, na.rm=TRUE, df=TRUE)
    df <- data.frame(poly$HydroID,l_ex[,2],ex[,2])
    df[,3] <- df[,3]-1
    df$pct <- df[,3]/df[,2] # calc proportion land cover
    colnames(df) <- c("HydroID","cnt",paste0(l_type,"_",lc_yr,"_sum"),
                      paste0(l_type,"_",lc_yr,"_pct"))
    write.csv(df,paste0(l_type,"_",lc_yr,".csv"),row.names=FALSE)
  }
}


### reclassify #################################################################

# list files
grids    <- list.files(r_path, pattern = "*.tif$")
lc_grids <- list.files(r_path, pattern = "landcover_*")

c_spec <- cbind(from = c(-Inf, 3, 4), to = c(3, 4, Inf), becomes = c(0, 1, 0))

reclass_lc(lc_grids,c_spec,"ag")

### extract by poly ############################################################

# get only specified landcover grids
ag_grids <- list.files(r_path, pattern = "ag_*")

#read-in the polygon shapefile of river catchments
poly <- vect(paste0(sf_path,"Catchments01_CT.shp"))

extract_lc(ag_grids,poly,"ag")

