library(sf)
library(ggplot2)
library(leaflet)

# read in data
raw_f <- read.csv("analysis/data/raw/fish_bcg_030522.csv",header = TRUE)
raw_b <- read.csv("analysis/data/raw/bug_bcg_030522.csv", header = TRUE)
sites <- read.csv("analysis/data/raw/stations_030522.csv", header = TRUE)
hydro <- read.csv("analysis/data/raw/stations_hydroID_030522.csv", header = TRUE)
flow  <- st_read(dsn = "analysis/data/raw_spatial/vector/flowline_ct.shp",
                 layer = "flowline_ct")
catch <- st_read(dsn = "analysis/data/raw_spatial/vector/catchments_ct.shp",
                 layer = "catchments_ct")

# get geometry summary for spatial data
st_geometry(catch)
st_geometry(flow)

# transform projection as needed
catch_sf <- st_transform(catch, 4326)
flow_sf  <- st_transform(flow, 4326)

# number of sites & samples in the dataset
dim(raw_f)[1] #number of fish samples
dim(raw_b)[1] #number of bug samples
length(unique(raw_f$staSeq)) # number of fish sites
length(unique(raw_b$staSeq)) # number of bug sites

# number of samples in each bcg tier
aggregate(staSeq ~ lev1Name, data = raw_f, FUN = "length")
aggregate(staSeq ~ lev1Name, data = raw_b, FUN = "length")

ggplot(raw_f, aes(lev1Name)) +
  geom_bar()+
  xlab('BCG') +
  ylab('Count of Samples') +
  ggtitle('Count of Fish Samples in each BCG Tier')+
  theme(panel.background = element_rect(fill = '#252525', colour = '#969696'),
        plot.background = element_rect(fill = '#252525'),
        panel.grid = element_blank(),
        axis.text = element_text(colour = '#cccccc',size=rel(1.1)),
        axis.title = element_text(color = '#cccccc',size=rel(1.1)),
        title = element_text(color = '#cccccc',size=rel(1.5)),
        legend.position = 'none')

ggplot(raw_b, aes(lev1Name)) +
  geom_bar()+
  xlab('BCG') +
  ylab('Count of Samples') +
  ggtitle('Count of Bug Samples in each BCG Tier')+
  theme(panel.background = element_rect(fill = '#252525', colour = '#969696'),
        plot.background = element_rect(fill = '#252525'),
        panel.grid = element_blank(),
        axis.text = element_text(colour = '#cccccc',size=rel(1.1)),
        axis.title = element_text(color = '#cccccc',size=rel(1.1)),
        title = element_text(color = '#cccccc',size=rel(1.5)),
       legend.position = 'none')  

# combine fish and bug bcg data
raw_f$taxa <- "fish"
raw_b$taxa <- "bug"
raw <- rbind(raw_f[,c(1,2,5:11)], raw_b[,c(1,2,5,9:14)])
raw$hq <- ifelse(raw$levPropNum < 2.5, 1, 0)
raw <- merge(raw, hydro[,1:2], by = "staSeq")
# write.csv(raw, "analysis/data/raw/bug_fish_bcg_030522.csv", row.names = FALSE)

# high quality sites
hq_fish <- unique(raw_f[raw_f$levPropNum < 2.5, 1])
hq_bugs <- unique(raw_b[raw_b$levPropNum < 2.5, 1])
length(hq_fish)
length(hq_bugs)

hq_sites <- data.frame(staSeq = unique(raw[raw$levPropNum < 2.5,1]))
hq_sites <- data.frame(staSeq = unique(hq_sites))
hq_sites$fish <- ifelse(hq_sites$staSeq %in% hq_fish, 1, 0)
hq_sites$bugs  <- ifelse(hq_sites$staSeq %in% hq_bugs, 1, 0)
hq_sites <- merge(hq_sites, sites[,c(1:2,5:6)], by = "staSeq")
hq_catch <- merge(hq_sites, hydro[,c(1:2)])
hq_catch <- aggregate(staSeq ~ hydroID, hq_catch, FUN = "length")
colnames(hq_catch)[1] <- "HydroID"


# high quality samples and catchments
hq_sf <- sf::st_as_sf(hq_sites, 
                      coords = c("xlong","ylat"),
                      crs = 4326) # csv to sf
catch_hq <- merge(catch_sf,hq_catch, by.x = c("HydroID"))
m <- leaflet() %>% setView(lng = -72.6999, lat = 41.5999, zoom = 8)
m %>% 
  addProviderTiles(providers$CartoDB.Voyager) %>%
  addPolygons(data = catch_hq, color = "#444444", fillColor = '#045a8d', 
              weight=2, fillOpacity = 0.5) %>%
  addCircleMarkers(data = hq_sf, color = "#444444", radius = 4, 
                   stroke = FALSE, fillOpacity = 0.7,label = ~locationName) 

# sf::st_write(hq_sf, dsn = "analysis/data/processed_spatial/hq_sites.geojson", 
#              layer = "hq_sites.geojson")
# 
# sf::st_write(catch_hq, 
#              dsn = "analysis/data/processed_spatial/hq_catchments.geojson", 
#              layer = "hq_catchments.geojson")

# minimum BCG level observed at a site

min_bcg   <- aggregate(lev1Name ~ staSeq, data = raw, FUN = "min")
min_bcg   <- merge(min_bcg, sites, by = "staSeq")
min_bcg   <- merge(min_bcg, hydro, by = "staSeq")
bcg_sites <- sf::st_as_sf(min_bcg, 
                          coords = c("xlong","ylat"),
                          crs = 4326) # csv to sf
# sf::st_write(bcg_sites,
#              dsn = "analysis/data/processed_spatial/min_bcg.geojson",
#              layer = "min_bcg.geojson",
#              append = FALSE)


           




