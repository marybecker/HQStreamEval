library(httr)
library(sf)
library(tmap)
library(terra)

#### IMPORT FROM ESRI REST FEATURE SERVICES - VECTOR ###########################
url <- 'https://services1.arcgis.com/FjPcSmEFuDYlIdKC/arcgis/rest/services/'
lyr <- 'Road/FeatureServer/0/query?'
qry <- 'where=1%3D1&outFields=*&outSR=4326&f=json'
request <- paste0(url,lyr,qry)

ct_roads <- st_read(request)
flow  <- st_read(dsn = "analysis/data/raw_spatial/vector/flowline_ct.shp",
                 layer = "flowline_ct")
flow_sf  <- st_transform(flow, 4326)

x <- st_intersection(flow_sf,ct_roads)

tmap_mode(mode = "view")
tm_shape(ct_roads)+tm_lines(lwd = 5)



#### IMPORT FROM ESRI REST IMAGE SERVICES - RASTER #############################

url <- 'http://cteco.uconn.edu/ctraster/rest/services/'
lyr <- 'elevation/Statewide2016/ImageServer/exportImage?'
bbx <- 'bbox=-8208572.6952%2C5008472.305471067%2C-7990329.972314554%2C5169936.770799998'
bbs <- '&102100'
fmt <- '&format=tiff'
pxl <- '&pixelType=F32'
nod <- '&noDataInterpretation=esriNoDataMatchAny'
itp <- '&interpolation=+RSP_BilinearInterpolation'
fim <- '&f=image'
qry <- paste0(bbx,fmt,pxl,nod,itp,fim)
req <- paste0(url,lyr,qry)

elev <- rast(req)
elev <- project(elev, "+proj=lcc +lat_1=48 +lat_2=33 +lon_0=-100 +datum=WGS84")
plot(elev)

bfs <- st_read('C:/Users/deepuser/Documents/Projects/GISPrjs/2022/hq_stream_eval/data/bug_fish_bcg_flow_in_lc_bounds_buffer.shp')
bfs <- st_transform(bfs,4326)
bfs_elev_min <- extract(bfs, elev, fun=min, na.rm=TRUE)


## Points in polygons #########################################################

catch_sf <- st_read("analysis/data/raw_spatial/vector/catchments_ct.shp")
road_cr_sf <- st_read("C:/Users/deepuser/Documents/Projects/GISPrjs/StatewideData/stream_road_crossings/ct_detailed_flow_conte_road_crossings_2234.shp")

catch_sf$pt_ctn <- lengths(st_intersects(catch_sf,road_cr_sf))