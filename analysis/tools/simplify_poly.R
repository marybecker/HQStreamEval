library(sf)
library(ggplot2)
library(leaflet)


# read in data
catch <- st_read(dsn = "data/catchments.geojson",
                 layer = "catchments")

# get geometry summary for spatial data
st_geometry(catch)

catch_sm <- st_simplify(catch, dTolerance = 100)

plot(catch_sm[1])

sf::st_write(catch_sm, dsn = "data/catchments_sm.geojson",
             layer = "catchments_sm.geojson")

