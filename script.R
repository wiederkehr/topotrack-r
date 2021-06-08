# Install packages
install.packages("av")
install.packages("https://cran.r-project.org/src/contrib/Archive/elevatr/elevatr_0.2.0.tar.gz", repos = NULL, type = "source")
# install.packages("elevatr")
install.packages("plyr")
install.packages("raster")
install.packages("rayshader")
install.packages("sf")
install.packages("sp")
install.packages("XML")

# Import libraries
library("av")
library("elevatr")
library("plyr")
library("raster")
library("rayshader")
library("sf")
library("sp")
library("XML")

# ----------------
# Helper functions
# ----------------

# Convert character representations to timestamp
parse_timestamp <- function(string) {
  timestamp <- sub("T", " ", string)
  timestamp <- sub("Z", "", timestamp)
  timestamp <- as.POSIXlt(timestamp)
  return(timestamp)
}

# Extract lat, lon, ele extent from GPX track
create_extent <- function(track) {
  extent <- list(
    lat_min = min(track$lat),
    lat_max = max(track$lat),
    lon_min = min(track$lon),
    lon_max = max(track$lon),
    ele_min = min(track$ele),
    ele_max = max(track$ele)
  )
  return(extent)
}

# Construct Simple Feature collection from GPX extent
create_features <- function(extent) {
  features <- sf::st_as_sf(
    x = data.frame(
      lon = c(extent$lon_min, extent$lon_max),
      lat = c(extent$lat_min, extent$lat_max)
    ),
    coords = c("lon", "lat"),
    crs = 4326
  )
  return(features)
}

# Load GPX file
load_gpx <- function(filename) {
  gpx_raw <- XML::xmlTreeParse(filename, useInternalNodes = TRUE)
  gpx_root <- XML::xmlRoot(gpx_raw)
  metadata <- XML::xmlToList(gpx_root)$metadata
  trackdata <- XML::xmlToList(gpx_root)$trk
  tracksegments <- unlist(
    trackdata[names(trackdata) == "trkseg"],
    recursive = FALSE
  )
  track <- do.call(
    plyr::rbind.fill,
    lapply(
      tracksegments,
      function(x) as.data.frame(t(unlist(x)), stringsAsFactors = F)
    )
  )
  names(track) <- c("ele", "time", "hr", "cad", "lat", "lon")
  track$time <- parse_timestamp(track$time)
  track$hr <- as.numeric(track$hr)
  track$cad <- as.numeric(track$cad)
  track$lon <- as.numeric(track$lon)
  track$lat <- as.numeric(track$lat)
  track$ele <- as.numeric(track$ele)

  extent <- create_extent(track)
  features <- create_features(extent)

  gpx <- list(
    name = trackdata$name,
    time = parse_timestamp(metadata$time),
    track = track,
    extent = extent,
    features = features
  )

  return(gpx)
}

# Construct elevation raster, matrics, and metrics from GPX
load_elevation <- function(gpx) {
  raster <- elevatr::get_elev_raster(
    gpx$features,
    z = 14,
    clip = "bbox"
  )
  matrix <- matrix(
    raster::extract(raster, raster::extent(raster)),
    nrow = ncol(raster), ncol = nrow(raster)
  )
  metrics <- list(
    extent = raster::extent(raster),
    dimemsion = dim(raster),
    resolution = raster::res(raster)
  )
  elevation <- list(
    raster = raster,
    matrix = matrix,
    metrics = metrics
  )
  return(elevation)
}

# Create vectors from elevation and GPX track
create_vectors <- function(gpx, elevation) {
  vector <- list(
    x_min = rep(elevation$metrics$extent@xmin, length(gpx$track$lon)),
    y_min = rep(elevation$metrics$extent@ymin, length(gpx$track$lat))
  )
  return(vector)
}

# Create coordinates from elevation and GPX track
create_coordinates <- function(gpx, elevation, vectors) {
  coordinates <- list(
    x = (gpx$track$lon - vectors$x_min) / elevation$metrics$resolution[1],
    y = (gpx$track$lat - vectors$y_min) / elevation$metrics$resolution[2],
    z = raster::extract(elevation$raster, gpx$track[, c(6, 5)])
  )
  return(coordinates)
}

# Create shading layers from elevation matrix
create_layers <- function(elevation) {
  layers <- list(
    ray = rayshader::ray_shade(elevation$matrix),
    ambient = rayshader::ambient_shade(elevation$matrix),
    water = rayshader::detect_water(elevation$matrix)
  )
  return(layers)
}

# Render scene in XQuartz window
render_scene <- function(elevation, coordinates) {
  # Clear RGL window
  rgl::clear3d()
  # Display shaded map with Rayshader
  elevation$matrix %>%
    rayshader::sphere_shade(texture = "bw") %>%
    # Commented out for better performance during development
    # rayshader::add_shadow(layers$ray, max_darken = 0.2) %>%
    # rayshader::add_shadow(layers$ambient, max_darken = 0.2) %>%
    # rayshader::add_water(layers$water, color = "bw") %>%

    rayshader::plot_3d(
      elevation$matrix,
      theta = 45,
      phi = 45,
      solidcolor = "#eeeeee",
      solidlinecolor = "#eeeeee",
      soliddepth = gpx$extent$ele_min - 100,
      shadowdepth = gpx$extent$ele_min - 100,
      shadowcolor = "#bbbbbb",
      windowsize = c(1200, 800),
    )

  # Display the GPX route in 3D
  rgl::lines3d(
    coordinates$x - elevation$metrics$dimemsion[2] / 2,
    coordinates$z + 3,
    -coordinates$y + elevation$metrics$dimemsion[1] / 2,
    color = "#fc5200",
    lwd = 2.0,
  )
}

# Export static preview image
render_picture <- function(name) {
  rayshader::render_snapshot(
    filename = name,
    title_text = name,
    title_color = "#bbbbbb",
    title_size = "16",
    title_font = "mono",
    title_position = "southeast",
  )
}
# Export animated preview movie
render_animation <- function(name) {
  rayshader::render_movie(
    filename = name,
    title_text = name,
    title_color = "#bbbbbb",
    title_size = "16",
    title_font = "mono",
    title_position = "southeast",
  )
}

# -------------------
# Execution functions
# -------------------

gpx <- load_gpx("track.gpx")
elevation <- load_elevation(gpx)
vectors <- create_vectors(gpx, elevation)
coordinates <- create_coordinates(gpx, elevation, vectors)
layers <- create_layers(elevation)

render_scene(elevation, coordinates)
render_picture(toString(gpx$time))
# render_animation(toString(gpx$time))