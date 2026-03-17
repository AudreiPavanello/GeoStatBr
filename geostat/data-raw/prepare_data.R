# data-raw/prepare_data.R
#
# Downloads IBGE shapefiles via geobr and synthesizes health indicator
# datasets with realistic spatial autocorrelation patterns.
#
# Run this script once to regenerate all .rda files in data/.
# Source it from ANY working directory — paths are resolved relative to this
# script's own location.
#
# Requires: geobr, sf, dplyr, spdep

library(geobr)
library(sf)
library(dplyr)
library(spdep)

# Resolve the package root regardless of the caller's working directory.
# Works whether sourced interactively or via source("path/to/script").
.script_path <- tryCatch({
    # When sourced: sys.calls() contains the source() call with a file arg
    src_calls <- Filter(function(x) identical(as.character(x[[1]]), "source"), sys.calls())
    if (length(src_calls) > 0) {
        normalizePath(as.character(src_calls[[length(src_calls)]][[2]]))
    } else {
        stop("not sourced")
    }
}, error = function(e) {
    # Fallback: assume script is in data-raw/ inside the package
    file.path(getwd(), "data-raw", "prepare_data.R")
})
.pkg_root <- normalizePath(file.path(dirname(.script_path), ".."))
.data_dir <- file.path(.pkg_root, "data")
if (!dir.exists(.data_dir)) dir.create(.data_dir, recursive = TRUE)
message("Package root: ", .pkg_root)
message("Data directory: ", .data_dir)

set.seed(42)

# -----------------------------------------------------------------------------
# 1. Brazilian States shapefile
# -----------------------------------------------------------------------------
message("Downloading Brazilian states shapefile...")
brazil_states <- geobr::read_state(code_state = "all", year = 2020)
brazil_states <- sf::st_transform(brazil_states, crs = 4326)

# Keep only columns needed for joining and display
brazil_states <- brazil_states[, c("code_state", "abbrev_state", "name_state",
                                    "name_region", "geom")]

save(brazil_states, file = file.path(.data_dir, "brazil_states.rda"), compress = "xz")
message("  Saved data/brazil_states.rda (", nrow(brazil_states), " features)")

# -----------------------------------------------------------------------------
# 2. Paraná Municipalities shapefile
# -----------------------------------------------------------------------------
message("Downloading Paraná municipalities shapefile...")
brazil_municipalities_pr <- geobr::read_municipality(code_muni = "PR", year = 2020)
brazil_municipalities_pr <- sf::st_transform(brazil_municipalities_pr, crs = 4326)

brazil_municipalities_pr <- brazil_municipalities_pr[, c("code_muni", "name_muni",
                                                          "code_state", "geom")]

save(brazil_municipalities_pr,
     file = file.path(.data_dir, "brazil_municipalities_pr.rda"), compress = "xz")
message("  Saved data/brazil_municipalities_pr.rda (",
        nrow(brazil_municipalities_pr), " features)")

# -----------------------------------------------------------------------------
# 3. All Brazilian municipalities (all 27 states)
# -----------------------------------------------------------------------------
message("Downloading all Brazilian municipalities shapefile (this may take a minute)...")
brazil_municipalities_all <- geobr::read_municipality(code_muni = "all", year = 2020)
brazil_municipalities_all <- sf::st_transform(brazil_municipalities_all, crs = 4326)
brazil_municipalities_all <- brazil_municipalities_all[,
    c("code_muni", "name_muni", "code_state", "abbrev_state", "geom")]

save(brazil_municipalities_all,
     file = file.path(.data_dir, "brazil_municipalities_all.rda"), compress = "xz")
message("  Saved data/brazil_municipalities_all.rda (",
        nrow(brazil_municipalities_all), " features)")

# -----------------------------------------------------------------------------
# 5. Synthesize state-level health indicators with spatial autocorrelation
# -----------------------------------------------------------------------------
message("Synthesizing state-level health data...")

# Build spatial weights to generate autocorrelated data
nb_states <- spdep::poly2nb(brazil_states, queen = TRUE)
W_states  <- spdep::nb2mat(nb_states, style = "W", zero.policy = TRUE)

# Generate spatially autocorrelated variables using a simple CAR-like smoother
# We simulate X ~ Normal(0,1) then smooth it with the weight matrix
.spatial_smooth <- function(n, W, rho = 0.7, seed = NULL) {
    if (!is.null(seed)) set.seed(seed)
    x <- rnorm(n)
    # Apply two rounds of averaging to increase autocorrelation
    x_smooth <- (1 - rho) * x + rho * (W %*% x)
    x_smooth <- (1 - rho) * x_smooth + rho * (W %*% x_smooth)
    as.numeric(x_smooth)
}

n_states <- nrow(brazil_states)

# Dengue incidence rate (per 100,000 — higher in tropical/northeastern states)
dengue_raw       <- .spatial_smooth(n_states, W_states, rho = 0.75, seed = 101)
dengue_incidence <- round(pmax(0, 80 + 120 * dengue_raw), 1)

# Infant mortality rate (per 1,000 live births — gradient from North to South)
infant_raw       <- .spatial_smooth(n_states, W_states, rho = 0.70, seed = 202)
infant_mortality <- round(pmax(5, 18 + 8 * infant_raw), 1)

# HDI (Human Development Index — 0 to 1, higher in South/Southeast)
hdi_raw <- .spatial_smooth(n_states, W_states, rho = 0.80, seed = 303)
hdi     <- round(pmin(0.95, pmax(0.55, 0.74 + 0.07 * hdi_raw)), 3)

# Hospital beds per 1,000 inhabitants
beds_raw  <- .spatial_smooth(n_states, W_states, rho = 0.65, seed = 404)
hosp_beds <- round(pmax(1.0, 2.4 + 0.8 * beds_raw), 2)

brazil_health_states <- data.frame(
    code_state       = as.character(brazil_states$code_state),
    abbrev_state     = brazil_states$abbrev_state,
    name_state       = brazil_states$name_state,
    dengue_incidence = dengue_incidence,
    infant_mortality = infant_mortality,
    hdi              = hdi,
    hosp_beds        = hosp_beds
)

save(brazil_health_states,
     file = file.path(.data_dir, "brazil_health_states.rda"), compress = "xz")
message("  Saved data/brazil_health_states.rda (", nrow(brazil_health_states), " rows)")

# -----------------------------------------------------------------------------
# 6. Synthesize Paraná municipality health indicators
# -----------------------------------------------------------------------------
message("Synthesizing Paraná municipality health data...")

nb_pr <- spdep::poly2nb(brazil_municipalities_pr, queen = TRUE)
W_pr  <- spdep::nb2mat(nb_pr, style = "W", zero.policy = TRUE)

n_pr <- nrow(brazil_municipalities_pr)

dengue_pr   <- round(pmax(0, 60 + 100 * .spatial_smooth(n_pr, W_pr, rho = 0.72, seed = 505)), 1)
infant_pr   <- round(pmax(4,  15 + 7   * .spatial_smooth(n_pr, W_pr, rho = 0.68, seed = 606)), 1)
hdi_pr      <- round(pmin(0.95, pmax(0.55, 0.73 + 0.06 * .spatial_smooth(n_pr, W_pr, rho = 0.78, seed = 707))), 3)
beds_pr     <- round(pmax(0.5, 2.1 + 0.9 * .spatial_smooth(n_pr, W_pr, rho = 0.60, seed = 808)), 2)

brazil_health_pr <- data.frame(
    code_muni        = as.character(brazil_municipalities_pr$code_muni),
    name_muni        = brazil_municipalities_pr$name_muni,
    dengue_incidence = dengue_pr,
    infant_mortality = infant_pr,
    hdi              = hdi_pr,
    hosp_beds        = beds_pr
)

save(brazil_health_pr,
     file = file.path(.data_dir, "brazil_health_pr.rda"), compress = "xz")
message("  Saved data/brazil_health_pr.rda (", nrow(brazil_health_pr), " rows)")

message("\nAll datasets prepared successfully. Files are in: ", .data_dir)
message("Next: install jmvtools and run jmvtools::prepare() from geostat/")
