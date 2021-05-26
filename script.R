# Install packages
install.packages("av")
install.packages("https://cran.r-project.org/src/contrib/Archive/elevatr/elevatr_0.2.0.tar.gz", repos = NULL, type = "source")
install.packages("plyr")
install.packages("raster")
install.packages("rayshader")
install.packages("sf")
install.packages("sp")
install.packages("XML")

# Import libraries
library(av)
library(elevatr)
library(plyr)
library(raster)
library(rayshader)
library(sf)
library(sp)
library(XML)

# Set working directory
setwd("~/Development/topotrack")

# Load GPX file and parse XML data
filename <- "track.gpx"
gpx_raw <- XML::xmlTreeParse(filename, useInternalNodes = TRUE)
gpx_root <- XML::xmlRoot(gpx_raw)
gpx_metadata <- XML::xmlToList(gpx_root)$metadata
gpx_trackdata <- XML::xmlToList(gpx_root)$trk
gpx_name <- gpx_trackdata[["name"]]
gpx_time <- gpx_metadata[["time"]]
gpx_time <- sub("T", " ", gpx_time)
gpx_time <- sub("\\+00:00", "", gpx_time)

# Import GPX data into data frame
gpx_track <- unlist(gpx_trackdata[names(gpx_trackdata) == "trkseg"], recursive = FALSE)
gpx <- do.call(plyr::rbind.fill, lapply(gpx_track, function(x) as.data.frame(t(unlist(x)), stringsAsFactors = F)))
names(gpx) <- c("ele", "time", "hr", "cad", "lat", "lon")

# Convert GPX values to numeric format
gpx[3:6] <- data.matrix(gpx[3:6])
sapply(gpx[3:6], class)
gpx[3:6] <- as.numeric(unlist(gpx[3:6]))
gpx$ele <- as.numeric(gpx$ele)

# Convert GPX time to date format
gpx$time <- sub("T", " ", gpx$time)
gpx$time <- sub("\\+00:00", "", gpx$time)
gpx$time <- as.POSIXlt(gpx$time)

# Sort order of attributes
gpx <- gpx[, c("time", "hr", "cad", "lon", "lat", "ele")]

# Calculate longitude and latitude extent
lat_min <- min(gpx$lat)
lat_max <- max(gpx$lat)
lon_min <- min(gpx$lon)
lon_max <- max(gpx$lon)
ele_min <- min(gpx$ele)
ele_max <- max(gpx$ele)

# Create data frame with longitude and latitude extent
gpx_extent <- data.frame(
  lon = c(lon_min, lon_max),
  lat = c(lat_min, lat_max)
)

# Convert data frame with extent to Simple Feature collection
gpx_sf <- sf::st_as_sf(
  x = gpx_extent,
  coords = c("lon", "lat"),
  crs = 4326
)

# Get elevation raster image from AWS with Elevatr package
ele_raster <- elevatr::get_elev_raster(
  gpx_sf,
  z = 14,
  clip = "bbox"
)

# Convert elevation raster image into elevation matrix
ele_matrix <- matrix(
  raster::extract(ele_raster, raster::extent(ele_raster)),
  nrow = ncol(ele_raster), ncol = nrow(ele_raster)
)

# Get extents and dimensions from elevation raster image
ele_raster_extent <- raster::extent(ele_raster)
ele_raster_dimemsion <- dim(ele_raster)
ele_raster_resolution <- raster::res(ele_raster)

# Create vectors for x and y coordinates
xmin_vec <- rep(ele_raster_extent@xmin, length(gpx$lon))
ymin_vec <- rep(ele_raster_extent@ymin, length(gpx$lat))

# Set up lists of x, y, z coordinate
x <- (gpx$lon - xmin_vec) / ele_raster_resolution[1]
y <- (gpx$lat - ymin_vec) / ele_raster_resolution[2]
z <- raster::extract(ele_raster, gpx[, c(4, 5)])

# Calculate Rayshader layers
ambient_layer <- rayshader::ambient_shade(ele_matrix)
ray_layer <- rayshader::ray_shade(ele_matrix)
water_layer <- rayshader::detect_water(ele_matrix)

# Clear RGL window
rgl::clear3d()

# Display shaded map with Rayshader
ele_matrix %>%
  rayshader::sphere_shade(texture = "bw") %>%
  rayshader::add_water(water_layer, color = "bw") %>%
  rayshader::add_shadow(ray_layer, max_darken = 0.2) %>%
  rayshader::add_shadow(ambient_layer, max_darken = 0.2) %>%
  rayshader::plot_3d(
    ele_matrix,
    theta = 135,
    phi = 45,
    solidcolor = "#eeeeee",
    solidlinecolor = "#eeeeee",
    soliddepth = ele_min - 100,
    shadowdepth = ele_min - 100,
    shadowcolor = "#bbbbbb",
  )

# Plot the route in 3D
rgl::lines3d(
  x - ele_raster_dimemsion[2] / 2,
  z + 3,
  -y + ele_raster_dimemsion[1] / 2,
  color = "#fc5200",
  lwd = 2.0,
)

# Export static preview image
rayshader::render_snapshot(
  filename = "preview",
  title_text = gpx_time,
  title_color = "#bbbbbb",
  title_size = "16",
  title_font = "mono",
  title_position = "southeast",
)

# Export animated preview movie
rayshader::render_movie(
  filename = "preview",
  title_text = gpx_time,
  title_color = "#bbbbbb",
  title_size = "16",
  title_font = "mono",
  title_position = "southeast",
)