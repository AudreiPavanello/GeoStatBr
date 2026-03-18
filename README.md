# GeoStatBR

**Geospatial analysis  module for Jamovi**

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/AudreiPavanello/geostatbr/releases)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![jamovi](https://img.shields.io/badge/jamovi-%E2%89%A5%202.3-orange.svg)](https://www.jamovi.org)

---

## Overview

**GeoStatBR** is a [jamovi](https://www.jamovi.org) module that executes spatial data visualization and spatial autocorrelation analysis. The module focuses on Brazilian geography, providing built-in shapefiles for all 27 states and all States municipalities.

---

## Features

- **Choropleth Map**: Visualize any numeric variable as a color-shaded map of Brazilian states or Paraná municipalities
- **Global Moran's I**: Test for global spatial autocorrelation with a Moran scatter plot and permutation-based significance test
- **Local Moran's I (LISA)**: Identify spatial clusters (High-High, Low-Low) and outliers (High-Low, Low-High) with cluster and significance maps

---

## Installation

[![Download](https://img.shields.io/badge/Download-.jmo-blue?style=for-the-badge)](https://github.com/AudreiPavanello/geostatbr/releases/latest)

1. Open **jamovi**.
2. Click the **Modules** button in the top-right corner.
3. Select **Install from file…** and choose the downloaded `.jmo` file.
4. The **GeoStatBR** menu will appear in the analysis ribbon.

---

## Analyses

### Choropleth Map

Produces a thematic map that color-shades geographic regions according to a numeric variable, making spatial patterns immediately visible.

---

### Global Moran's I

Tests whether values that are geographically close to each other tend to be more similar (positive autocorrelation) or more different (negative autocorrelation) than expected by chance.

---

### Local Moran's I (LISA)

Decomposes the global index to identify specific locations that drive spatial autocorrelation — high-value clusters, low-value clusters, and spatial outliers.

---

## Quick Start

1. Open **jamovi** and load your dataset (CSV or spreadsheet).
2. Click the **GeoStatBR** menu in the analysis ribbon.
3. Choose an analysis: **Choropleth Map**, **Global Moran's I**, or **Local Moran's I (LISA)**.
4. Select the **geographic level**.
5. Select the **join column**, the variable in your data that identifies each region (e.g., state name or IBGE municipality code).
6. Select the **variable** you want to map or test.
7. The map or results appear in the output panel.

---

## How to Cite

**APA:**

> Pavanello, A. (2026). *GeoStatBR: Geospatial Analysis for jamovi* (Version 0.1.0) [Computer software]. GitHub. https://github.com/AudreiPavanello/geostatbr

**BibTeX:**

```bibtex
@software{pavanello2026geostatbr,
  author    = {Pavanello, Audrei},
  title     = {{GeoStatBR}: Geospatial Analysis for jamovi},
  year      = {2026},
  version   = {0.1.0},
  note      = {Computer software},
  url       = {https://github.com/AudreiPavanello/geostatbr}
}
```

---

## License

GeoStatBR is free software distributed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).

---