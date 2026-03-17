# choropleth.b.R — Choropleth Map implementation
# This file is hand-written. Do NOT overwrite with jmvtools::prepare().

choroplethClass <- R6::R6Class(
    "choropleth",
    inherit = choroplethBase,
    private = list(

        # .shp_data caches the joined sf object so .run() and .renderMap()
        # share the same data without re-joining.
        .shp_data = NULL,

        .init = function() {
            self$results$map$setSize(600, 450)
        },

        .run = function() {
            var_name  <- self$options$var
            join_name <- self$options$joinVar

            # Early exit if required options not set
            if (is.null(var_name) || is.null(join_name))
                return()

            data <- self$data

            # Validate numeric variable
            tryCatch(
                .validate_numeric_var(data[[var_name]], var_name),
                error   = function(e) stop(e$message),
                warning = function(w) {
                    message(w$message)
                }
            )

            # Load shapefile and join data
            shp <- tryCatch(
                .load_builtin_shapefile(self$options$geoLevel),
                error = function(e) stop(e$message)
            )

            shp_joined <- tryCatch(
                withCallingHandlers(
                    .join_data_to_shape(shp, data, join_name),
                    warning = function(w) {
                        message(w$message)
                        invokeRestart("muffleWarning")
                    }
                ),
                error = function(e) stop(e$message)
            )

            # Cache for render function
            private$.shp_data <- shp_joined

            # Populate summary table
            name_col <- attr(shp, "name_col")
            vals     <- shp_joined[[var_name]]

            # Classify values
            n_classes   <- self$options$nClasses
            class_method <- self$options$classMethod

            breaks <- switch(class_method,
                quantile = stats::quantile(vals, probs = seq(0, 1, length.out = n_classes + 1), na.rm = TRUE),
                equal    = seq(min(vals, na.rm = TRUE), max(vals, na.rm = TRUE), length.out = n_classes + 1),
                sd       = {
                    m <- mean(vals, na.rm = TRUE)
                    s <- stats::sd(vals, na.rm = TRUE)
                    if (is.na(s) || s == 0)
                        stop("Standard deviation classification requires non-constant values.")
                    seq(m - 3 * s, m + 3 * s, length.out = n_classes + 1)
                },
                jenks    = {
                    # Use classInt for Jenks if available; fall back to quantile
                    if (requireNamespace("classInt", quietly = TRUE)) {
                        ci <- classInt::classIntervals(vals[!is.na(vals)], n_classes, style = "jenks")
                        ci$brks
                    } else {
                        stats::quantile(vals, probs = seq(0, 1, length.out = n_classes + 1), na.rm = TRUE)
                    }
                }
            )
            breaks <- unique(breaks)
            if (length(breaks) < 2)
                stop("Not enough distinct values to create ", n_classes, " classes. Try fewer classes or a different classification method.")
            classes <- as.integer(cut(vals, breaks = breaks, include.lowest = TRUE))

            region_names <- if (name_col %in% names(shp_joined)) {
                as.character(shp_joined[[name_col]])
            } else {
                as.character(seq_len(nrow(shp_joined)))
            }

            data_idx       <- !is.na(vals)
            region_names_d <- region_names[data_idx]
            vals_d         <- vals[data_idx]
            classes_d      <- classes[data_idx]

            table <- self$results$summary
            table$deleteRows()
            for (i in seq_along(region_names_d)) {
                table$addRow(
                    rowKey = i,
                    values = list(
                        region = region_names_d[i],
                        value  = vals_d[i],
                        class  = if (is.na(classes_d[i])) NA_integer_ else classes_d[i]
                    )
                )
            }
        },

        .renderMap = function(image, ggtheme, theme, ...) {
            if (is.null(private$.shp_data))
                return(FALSE)

            var_name   <- self$options$var
            shp        <- private$.shp_data

            if (!var_name %in% names(shp))
                return(FALSE)

            pal_name   <- "YlOrRd"
            n_classes  <- self$options$nClasses
            cls_method <- self$options$classMethod
            map_title  <- self$options$mapTitle

            if (nchar(trimws(map_title)) == 0)
                map_title <- var_name

            vals <- shp[[var_name]]

            # Compute class breaks
            breaks <- switch(cls_method,
                quantile = stats::quantile(vals, probs = seq(0, 1, length.out = n_classes + 1), na.rm = TRUE),
                equal    = seq(min(vals, na.rm = TRUE), max(vals, na.rm = TRUE), length.out = n_classes + 1),
                sd       = {
                    m <- mean(vals, na.rm = TRUE)
                    s <- stats::sd(vals, na.rm = TRUE)
                    if (is.na(s) || s == 0) return(FALSE)
                    seq(m - 3 * s, m + 3 * s, length.out = n_classes + 1)
                },
                jenks    = {
                    if (requireNamespace("classInt", quietly = TRUE)) {
                        ci <- classInt::classIntervals(vals[!is.na(vals)], n_classes, style = "jenks")
                        ci$brks
                    } else {
                        stats::quantile(vals, probs = seq(0, 1, length.out = n_classes + 1), na.rm = TRUE)
                    }
                }
            )
            breaks <- unique(breaks)
            if (length(breaks) < 2) return(FALSE)
            shp[["map_class"]] <- cut(vals, breaks = breaks, include.lowest = TRUE)

            # Build colour palette (no tmap/viridis dependency)
            if (pal_name == "viridis") {
                pal <- grDevices::hcl.colors(n_classes, palette = "viridis")
            } else {
                max_col <- RColorBrewer::brewer.pal.info[pal_name, "maxcolors"]
                pal     <- RColorBrewer::brewer.pal(min(max_col, max(3, n_classes)), pal_name)
                if (n_classes > length(pal))
                    pal <- grDevices::colorRampPalette(pal)(n_classes)
            }

            p <- ggplot2::ggplot(shp) +
                ggplot2::geom_sf(ggplot2::aes(fill = map_class),
                                 color = "white", linewidth = 0.15) +
                ggplot2::scale_fill_manual(values   = pal,
                                           name     = var_name,
                                           na.value = "#cccccc",
                                           drop     = FALSE) +
                ggplot2::labs(title = map_title) +
                ggplot2::theme_void() +
                ggplot2::theme(
                    plot.title      = ggplot2::element_text(hjust = 0.5, size = 12),
                    legend.position = "right"
                )

            print(p)
            TRUE
        }
    )
)
