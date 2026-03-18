# GeoStatBR News

## GeoStatBR 0.1.0 (2026-03-18)

### Initial release

- **Choropleth Map**: visualize any numeric variable across Brazilian states or
  Paraná municipalities using an interactive color palette and classification
  scheme selector (equal intervals, quantile, natural breaks, standard deviation).
- **Global Moran's I**: compute the global spatial autocorrelation statistic with
  a permutation-based significance test; outputs the Moran's I coefficient, expected
  value, variance, z-score, and p-value.
- **Local Moran's I (LISA)**: identify spatial clusters and outliers (High-High,
  Low-Low, High-Low, Low-High) for each geographic unit; outputs a LISA cluster
  map with the standard Anselin color scheme and a Moran scatter plot.
- Built-in shapefiles for all 27 Brazilian states and all 399 Paraná municipalities
  (no internet connection required).
- Spatial weights matrix built automatically from the selected geographic level
  using queen contiguity; island regions handled by k-nearest neighbours fallback.
