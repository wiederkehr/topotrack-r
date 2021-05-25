# Install packages
install.packages("XML")
install.packages("plyr")
install.packages("https://cran.r-project.org/src/contrib/Archive/elevatr/elevatr_0.2.0.tar.gz", repos=NULL, type="source")
install.packages("sf")
install.packages("sp")
install.packages("raster")
install.packages("rayshader")

# Import libraries
library(XML)
library(plyr)
library(elevatr)
library(sf)
library(sp)
library(rayshader)
library(raster)

# Set working directory
setwd("~/Development/trackmap-experiment-0.2")

# Load GPX file and parse XML data
filename <- "track.gpx"
gpx.raw <- XML::xmlTreeParse(filename, useInternalNodes = TRUE)
rootNode <- XML::xmlRoot(gpx.raw)
gpx.metadata <- XML::xmlToList(rootNode)$metadata
gpx.trackdata <- XML::xmlToList(rootNode)$trk
gpx.time <- gpx.metadata[["time"]]
gpx.name <- gpx.trackdata[["name"]]

# Import GPX data into data frame
gpx.track <- unlist(gpx.trackdata[names(gpx.trackdata) == "trkseg"], recursive = FALSE)
gpx <- do.call(plyr::rbind.fill, lapply(gpx.track, function(x) as.data.frame(t(unlist(x)), stringsAsFactors=F)))
names(gpx) <- c("ele","time", "hr", "cad", "lat", "lon")

# Convert GPX values to numeric format
gpx[3:6] <- data.matrix(gpx[3:6])
sapply(gpx[3:6], class)
gpx[3:6] = as.numeric(unlist(gpx[3:6]))
gpx$ele <- as.numeric(gpx$ele)

# Convert GPX time to date format
gpx$time <- sub("T", " ", gpx$time)
gpx$time <- sub("\\+00:00","",gpx$time)
gpx$time  <- as.POSIXlt(gpx$time)

# Sort order of attributes
gpx <- gpx[,c("time","hr","cad","lon","lat","ele")]

# Calculate longitude and latitude extent
lat_min <- min(gpx$lat)
lat_max <- max(gpx$lat)
long_min <- min(gpx$lon)
long_max <- max(gpx$lon)

# Create data frame with longitude and latitude extent
gpx.extent <- data.frame(
  longitude = c(long_min, long_max), 
  latitude = c(lat_min, lat_max)
)

# Convert data frame with extent to Simple Feature collection
gpx.extent.sf <- sf::st_as_sf(
  x = gpx.extent, 
  coords = c("longitude", "latitude"),
  crs = 4326
)

# Get elevation raster image from AWS with Elevatr package
elev_img <- elevatr::get_elev_raster(gpx.extent.sf, z = 14, clip = "bbox")

# Convert elevation raster image into elevation matrix
elev_matrix <- matrix(
  raster::extract(elev_img, raster::extent(elev_img)), 
  nrow = ncol(elev_img), ncol = nrow(elev_img)
)

# Get extents and dimensions from elevation raster image
extent <- extent(elev_img)
dimemsion <- dim(elev_img)
resolution <- res(elev_img)

# Create vectors for x and y coordinates
xmin_vec <- rep(extent@xmin, length(gpx$lon))
ymin_vec <- rep(extent@ymin, length(gpx$lat))

# Set up lists of x, y, z coordinate
x <- (gpx$lon - xmin_vec) / resolution[1]
y <- (gpx$lat - ymin_vec) / resolution[2]
z <- extract(elev_img, gpx[,c(4,5)])

# Calculate Rayshader layers
ambmat <- rayshader::ambient_shade(elev_matrix)
raymat <- rayshader::ray_shade(elev_matrix)
watermap <- rayshader::detect_water(elev_matrix)

# Clear RGL window
rgl::clear3d()

# Display shaded map with Rayshader
elev_matrix %>% 
  rayshader::sphere_shade(texture = "bw") %>% 
  rayshader::add_water(watermap, color = "bw") %>%
  rayshader::add_shadow(raymat, max_darken = 0.8) %>%
  rayshader::add_shadow(ambmat, max_darken = 0.8) %>%
  #rayshader::create_texture("#fff673","#55967a","#8fb28a","#55967a","#cfe0a9") %>%
  rayshader::plot_3d(
    elev_matrix, 
    theta = 135, 
    phi = 45, 
    solidcolor = "#222222", 
    solidlinecolor = "#333333",
    shadowcolor = "#bbbbbb",
    )

# Plot the route in 3D
rgl::lines3d(
  x - dimemsion[2] / 2,
  z + 2,
  -y + dimemsion[1] / 2,
  color = "red",
)

# Export static preview image from RGL window
rayshader::render_snapshot("preview.png")
