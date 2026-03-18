# utils.R — shared helpers for the geostat jamovi module
# Do NOT auto-generate — this file is hand-written.

#' Load the appropriate built-in shapefile
#'
#' @param level Character. One of "states", "mun_pr", or "mun_<abbrev>" for
#'   any Brazilian state abbreviation (e.g., "mun_sp", "mun_mg").
#' @return An sf object with IBGE region codes in the appropriate column.
.load_builtin_shapefile <- function(level) {
    if (level == "states") {
        shp <- geostatbr::brazil_states
        attr(shp, "id_col")   <- "code_state"
        attr(shp, "name_col") <- "name_state"
    } else if (level == "mun_pr") {
        # kept for backward compatibility
        shp <- geostatbr::brazil_municipalities_pr
        attr(shp, "id_col")   <- "code_muni"
        attr(shp, "name_col") <- "name_muni"
    } else if (startsWith(level, "mun_")) {
        state_abbrev <- toupper(substr(level, 5, nchar(level)))
        all_mun      <- geostatbr::brazil_municipalities_all
        shp          <- all_mun[all_mun$abbrev_state == state_abbrev, ]
        if (nrow(shp) == 0)
            stop("No municipalities found for state: ", state_abbrev)
        attr(shp, "id_col")   <- "code_muni"
        attr(shp, "name_col") <- "name_muni"
    } else {
        stop("Unknown geographic level: ", level)
    }
    shp
}

#' Join user data to a shapefile
#'
#' Performs a left join of user-supplied data to the shapefile by matching
#' the user's join column to the shapefile's region-id column.
#'
#' @param shp     An sf object (from .load_builtin_shapefile).
#' @param data    A data frame supplied by the user.
#' @param join_col Character. Name of the column in `data` with region codes.
#' @return An sf object with user data columns appended.
.join_data_to_shape <- function(shp, data, join_col) {
    id_col <- attr(shp, "id_col")

    # Validate the join column exists in user data
    if (!join_col %in% names(data)) {
        avail <- paste(names(data), collapse = ", ")
        stop(
            "Column '", join_col, "' not found in your data. ",
            "Available columns are: ", avail, "."
        )
    }

    # Coerce both join keys to character for safe matching
    shp[[id_col]]  <- as.character(shp[[id_col]])
    data[[join_col]] <- as.character(data[[join_col]])

    # Handle IBGE code length mismatch (6-digit vs 7-digit municipality codes).
    # The 7th digit is a check digit that some datasets omit. If the user's
    # codes are consistently shorter, truncate the shapefile codes to match.
    shp_len  <- nchar(shp[[id_col]][1])
    data_len <- stats::median(nchar(data[[join_col]]), na.rm = TRUE)
    if (shp_len > data_len) {
        chars_to_keep <- as.integer(data_len)
        shp[[id_col]] <- substr(shp[[id_col]], 1, chars_to_keep)
    }

    # Check for matches
    shp_codes  <- unique(shp[[id_col]])
    data_codes <- unique(data[[join_col]])
    matched    <- intersect(shp_codes, data_codes)

    if (length(matched) == 0) {
        stop(
            "No matching region codes found between your data column '",
            join_col, "' and the shapefile.\n",
            "Your data codes (first 5): ",
            paste(head(data_codes, 5), collapse = ", "), ".\n",
            "Shapefile codes (first 5): ",
            paste(head(shp_codes, 5), collapse = ", "), "."
        )
    }

    n_unmatched <- length(setdiff(shp_codes, data_codes))
    if (n_unmatched > 0) {
        warning(
            n_unmatched, " region(s) in the shapefile have no match in your ",
            "data and will appear as missing (NA) on the map."
        )
    }

    # Merge: keep all shapefile rows (left join).
    # Detach geometry first so base merge() cannot drop the sf class,
    # then reattach it explicitly.
    shp_geom  <- sf::st_geometry(shp)
    shp_df    <- sf::st_drop_geometry(shp)
    data_df   <- as.data.frame(data)

    # Deduplicate data by join column: duplicate codes would produce extra rows
    # after merge(), making nrow(merged_df) > length(shp_geom) and crashing
    # sf::st_set_geometry().
    dup_mask <- duplicated(data_df[[join_col]])
    if (any(dup_mask)) {
        n_dup <- sum(dup_mask)
        warning(
            n_dup, " duplicate region code(s) found in column '", join_col,
            "'. Only the first occurrence of each code will be used."
        )
        data_df <- data_df[!dup_mask, , drop = FALSE]
    }

    merged_df <- merge(shp_df, data_df, by.x = id_col, by.y = join_col, all.x = TRUE, sort = FALSE)

    # Restore original shapefile row order: merge() may reorder rows, which
    # would misalign geometries even when row counts match.
    row_order <- match(shp_df[[id_col]], merged_df[[id_col]])
    merged_df <- merged_df[row_order, , drop = FALSE]
    rownames(merged_df) <- NULL

    merged    <- sf::st_set_geometry(merged_df, shp_geom)
    merged
}

#' Validate a numeric variable
#'
#' Warns if more than 30% of values are NA and errors if all values are NA.
#'
#' @param x       Numeric vector.
#' @param varname Character. Variable name for display in messages.
#' @return Invisibly returns x.
.validate_numeric_var <- function(x, varname) {
    if (all(is.na(x))) {
        stop("Variable '", varname, "' contains only missing values (NA).")
    }
    pct_na <- mean(is.na(x)) * 100
    if (pct_na > 30) {
        warning(
            sprintf(
                "Variable '%s' has %.0f%% missing values. Results may be ",
                varname, pct_na
            ),
            "unreliable."
        )
    }
    invisible(x)
}

#' Build spatial weights
#'
#' Creates a neighbours list and a spatial weights list object.
#' Detects zero-neighbor (island) regions and warns the student with a
#' clear message instead of letting nb2listw() crash.
#'
#' @param shp          An sf object.
#' @param weights_type Character. One of "queen", "rook", "knn".
#' @param k            Integer. Number of neighbors (used only for knn).
#' @return A listw object (spdep).
.build_spatial_weights <- function(shp, weights_type, k = 4) {
    if (weights_type == "queen") {
        nb <- spdep::poly2nb(shp, queen = TRUE)
    } else if (weights_type == "rook") {
        nb <- spdep::poly2nb(shp, queen = FALSE)
    } else if (weights_type == "knn") {
        coords <- sf::st_centroid(sf::st_geometry(shp))
        nb     <- spdep::knn2nb(spdep::knearneigh(coords, k = k))
    } else {
        stop("Unknown weights type: ", weights_type)
    }

    # Detect island regions (zero neighbours)
    island_idx <- which(spdep::card(nb) == 0)
    if (length(island_idx) > 0) {
        name_col <- attr(shp, "name_col")
        if (!is.null(name_col) && name_col %in% names(shp)) {
            island_names <- shp[[name_col]][island_idx]
        } else {
            island_names <- as.character(island_idx)
        }
        warning(
            "The following region(s) have no spatial neighbors and will be ",
            "excluded from the spatial weights matrix: ",
            paste(island_names, collapse = ", "), ". ",
            "This is common for islands or isolated territories. ",
            "Consider using K Nearest Neighbors weights instead."
        )
    }

    listw <- spdep::nb2listw(nb, style = "W", zero.policy = TRUE)
    listw
}

#' Build an HTML error message for a result slot
#'
#' @param message Character. The error message to display.
#' @return Character HTML string.
.render_error_html <- function(message) {
    paste0(
        '<div style="color:#cc0000;padding:10px;border:1px solid #cc0000;',
        'border-radius:4px;background:#fff5f5;">',
        '<strong>Error:</strong> ', htmltools::htmlEscape(message),
        '</div>'
    )
}

#' Build the spatial lag data frame for Moran scatter plot
#'
#' @param x     Numeric vector (the variable of interest).
#' @param listw A listw object.
#' @return A data frame with columns `z` (standardized x) and `lag_z` (spatial lag of z).
.moran_scatter_data <- function(x, listw) {
    z     <- scale(x)[, 1]
    lag_z <- spdep::lag.listw(listw, z, zero.policy = TRUE)
    data.frame(z = z, lag_z = lag_z)
}

#' Map significance level option name to numeric value
#'
#' @param sig_opt Character. One of "p05", "p01", "p001".
#' @return Numeric p-value threshold.
.sig_level_value <- function(sig_opt) {
    switch(sig_opt,
        p05  = 0.05,
        p01  = 0.01,
        p001 = 0.001,
        0.05
    )
}

#' Map permutations option name to numeric value
#'
#' @param perm_opt Character. One of "perm99", "perm499", "perm999".
#' @return Integer number of permutations.
.nperm_value <- function(perm_opt) {
    switch(perm_opt,
        perm99  = 99L,
        perm499 = 499L,
        perm999 = 999L,
        499L
    )
}

#' Classify LISA results into cluster categories
#'
#' @param z        Numeric vector. Standardized values.
#' @param lag_z    Numeric vector. Spatial lag of standardized values.
#' @param pvalue   Numeric vector. LISA p-values.
#' @param sig      Numeric. Significance threshold.
#' @return Character vector of cluster labels.
.classify_lisa <- function(z, lag_z, pvalue, sig) {
    category <- rep("Not Significant", length(z))
    sig_idx  <- pvalue < sig
    category[sig_idx & z > 0 & lag_z > 0] <- "High-High"
    category[sig_idx & z < 0 & lag_z < 0] <- "Low-Low"
    category[sig_idx & z > 0 & lag_z < 0] <- "High-Low"
    category[sig_idx & z < 0 & lag_z > 0] <- "Low-High"
    category
}

#' Hardcoded LISA cluster colors
.lisa_colors <- c(
    "High-High"       = "#d7191c",   # red
    "Low-Low"         = "#2c7bb6",   # blue
    "High-Low"        = "#fdae61",   # orange
    "Low-High"        = "#abd9e9",   # light blue
    "Not Significant" = "#cccccc"    # grey
)
