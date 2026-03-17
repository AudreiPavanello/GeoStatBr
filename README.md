# Geospatial Analysis Module for jamovi

A jamovi add-on providing point-and-click geospatial analysis for students with no coding experience. Designed for a Biostatistics course using Brazilian geographic data.

## Phase 1 Analyses

| Analysis | Description |
|---|---|
| **Choropleth Map** | Color-shade Brazilian states or Paraná municipalities by any numeric variable |
| **Global Moran's I** | Test for global spatial autocorrelation; includes Moran scatter plot |
| **Local Moran's I (LISA)** | Identify spatial clusters (HH/LL) and outliers (HL/LH); cluster and significance maps |

## Built-in Datasets

| Dataset | Contents |
|---|---|
| `brazil_states` | sf object — 27 Brazilian states (IBGE 2020) |
| `brazil_municipalities_pr` | sf object — 399 Paraná municipalities (IBGE 2020) |
| `brazil_health_states` | Simulated health indicators (dengue incidence, infant mortality, HDI, hospital beds) by state |
| `brazil_health_pr` | Same indicators for Paraná municipalities |

## Development Setup

```r
# Install prerequisites
install.packages(c("jmvtools", "geobr", "sf", "spdep", "tmap", "ggplot2",
                   "dplyr", "RColorBrewer", "viridis"))

# tmap MUST be pinned to v3 (v4 broke the API)
install.packages("tmap", repos = "https://cran.r-project.org")
packageVersion("tmap")  # must be >= 3.3 and < 4.0

# Clone repo and enter package directory
setwd("geostat/")

# 1. Generate built-in datasets (requires geobr internet access — run once)
source("data-raw/prepare_data.R")

# 2. Generate .h.R boilerplate from YAML schemas
jmvtools::prepare()

# 3. Install into running jamovi for live testing
jmvtools::install()

# 4. Build .jmo for distribution
jmvtools::build()
```

## Development Workflow

```
Edit .r.yaml / .u.yaml  →  jmvtools::prepare()  →  Edit .b.R  →  jmvtools::install()  →  Test in jamovi
```

The `.h.R` files are auto-generated — never edit them directly.

## Key Decisions

- **tmap pinned `>= 3.3, < 4.0`** — v4 broke the v3 API substantially
- **LISA cluster colors are hardcoded** — HH=red, LL=blue, HL=orange, LH=lightblue, NS=grey
- **Island detection** — zero-neighbor regions trigger a student-friendly warning (not a cryptic crash)
- **Shapefile upload deferred to Phase 2** — Phase 1 uses only built-in shapefiles

## Roadmap

- **Phase 2**: Point Pattern Analysis (KDE + Ripley's K), Spatial Regression
- **Phase 3**: Kriging, Getis-Ord G*, User shapefile upload
