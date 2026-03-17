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
                .join_data_to_shape(shp, data, join_name),
                error = function(e) stop(e$message),
                warning = function(w) {
                    message(w$message)
                    .join_data_to_shape(shp, data, join_name)
                }
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
            classes <- as.integer(cut(vals, breaks = breaks, include.lowest = TRUE))

            region_names <- if (name_col %in% names(shp_joined)) {
                as.character(shp_joined[[name_col]])
            } else {
                as.character(seq_len(nrow(shp_joined)))
            }

            table <- self$results$summary
            table$deleteRows()
            for (i in seq_along(region_names)) {
                table$addRow(
                    rowKey = i,
                    values = list(
                        region = region_names[i],
                        value  = if (is.na(vals[i])) NA_real_ else vals[i],
                        class  = if (is.na(classes[i])) NA_integer_ else classes[i]
                    )
                )
            }
        },

        .renderMap = function(image, ggtheme, theme, ...) {
            if (is.null(private$.shp_data))
                return(FALSE)

            var_name <- self$options$var
            shp      <- private$.shp_data

            if (!var_name %in% names(shp))
                return(FALSE)

            pal_name   <- self$options$palette
            n_classes  <- self$options$nClasses
            cls_method <- self$options$classMethod
            map_title  <- self$options$mapTitle

            if (nchar(trimws(map_title)) == 0)
                map_title <- var_name

            # tmap v3 API (pinned < 4.0)
            tmap::tmap_mode("plot")

            # Build palette
            if (pal_name == "viridis") {
                pal <- viridis::viridis(n_classes)
            } else {
                pal <- RColorBrewer::brewer.pal(max(3, n_classes), pal_name)
            }

            map <- tmap::tm_shape(shp) +
                tmap::tm_polygons(
                    col      = var_name,
                    palette  = pal,
                    n        = n_classes,
                    style    = cls_method,
                    title    = var_name,
                    border.col = "white",
                    border.alpha = 0.5
                ) +
                tmap::tm_layout(
                    title          = map_title,
                    title.position = c("center", "top"),
                    legend.outside = TRUE,
                    frame          = FALSE
                ) +
                tmap::tm_compass(type = "arrow", position = c("right", "bottom")) +
                tmap::tm_scale_bar(position = c("left", "bottom"))

            print(map)
            TRUE
        }
    )
)
