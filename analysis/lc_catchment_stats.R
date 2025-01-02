# import required libraries
library(terra)
library(stringr)

# raster references
# https://cran.rstudio.com/web/packages/terra/terra.pdf
# https://rspatial.org/terra/spatial/Spatialdata.pdf
# https://rspatial.org/terra/analysis/analysis.pdf
base = "C:/Users/deepuser/Documents/Projects/ProgramDev/HQStreamEval"

r_path <- paste0(base,"/analysis/data/raw_spatial/raster/")
sf_path <- paste0(base,"/analysis/data/raw_spatial/vector/")

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
    rc <- classify(lc, l_spec,include.lowest=FALSE) # reclassify
    writeRaster(rc,paste0(r_path,l_type,"_",lc_yr,".tif"),overwrite=TRUE)
  }
}

extract_lc <- function(r_file,poly,l_type){
  for (i in 1:(length(r_file))){
    lc_yr <- str_sub(r_file[i],-8,-5) #get year
    lc <- rast(paste0(r_path,r_file[i])) #read in raster file
    # calc total cnt of pixels
    l_ex <- extract(lc, poly, fun=function(x,...)length(na.omit(x)), raw=FALSE)
    # calc sum of (0,1) pixels
    ex <- extract(lc, poly, fun=sum, na.rm=TRUE, raw=FALSE)
    df <- data.frame(poly$HydroID,l_ex[,2],ex[,2])
    # df[,3] <- df[,3]-1
    df$pct <- df[,3]/df[,2] # calc proportion land cover
    colnames(df) <- c("HydroID","cnt",paste0(l_type,"_",lc_yr,"_sum"),
                      paste0(l_type,"_",lc_yr,"_pct"))
    write.csv(df,paste0(base,"/analysis/data/",l_type,"_",lc_yr,".csv"),
              row.names=FALSE)
  }
}


### reclassify #################################################################
### ct lc: https://clear.uconn.edu/projects/landscape/about/classes.htm#top ####
### ct ff: https://clear.uconn.edu/projects/landscape/CT/forestfrag.htm ########

# list files
landcover<- "turf"
# grids    <- list.files(r_path, pattern = "*.tif$")
lc_grids <- list.files(r_path, pattern = "landcover_*")

# specify the classes to be re-classed
#logical. If TRUE, the intervals are closed on the right (and open on the left). 
#If FALSE they are open at the right and closed at the left. "open" means that 
#the extreme value is *not* included in the interval. Thus, right-closed and 
#left open is (0,1] = {x | 0 < x <= 1}. You can also close both sides with 
#right=NA, that is only meaningful if you "from-to-becomes" classification 
#with integers. For example to classify 1-5 -> 1, 6-10 -> 2, 11-15 -> 3. 
#That may be easier to read and write than the equivalent 1-5 -> 1, 5-10 -> 2, 
#10-15 -> 3 with right=TRUE and include.lowest=TRUE

c_spec <- cbind(from = c(-Inf, 1, 2), to = c(1, 2, Inf), 
                becomes = c(0, 1, 0))

reclass_lc(lc_grids,c_spec,landcover)

### extract by poly ############################################################

# get only specified landcover grids
grids <- list.files(r_path, pattern = paste0(landcover,"_*"))

#read-in the polygon shapefile of river catchments
poly <- vect(paste0(sf_path,"catchments_ct.shp"))

extract_lc(grids,poly,landcover)

### combine all years to one csv  ##############################################

lc_csv <- list.files("analysis/data", pattern = paste0(landcover,"_*"))

lc_df <- read.csv(paste0("analysis/data/",lc_csv[1]), header = TRUE)
lc_df <- lc_df[,1:3]

for (i in 2:length(lc_csv)){
  lc_df_i <- read.csv(paste0("analysis/data/",lc_csv[i]), header = TRUE)
  lc_df <- merge(lc_df,lc_df_i[,c(1,3)], by = "HydroID")
}

write.csv(lc_df,paste0("analysis/data/",landcover,"_statewide_allyrs.csv"),
          row.names = FALSE)



