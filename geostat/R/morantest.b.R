# morantest.b.R — Global Moran's I implementation
# This file is hand-written. Do NOT overwrite with jmvtools::prepare().

morantestClass <- R6::R6Class(
    "morantest",
    inherit = morantestBase,
    private = list(

        # Cache for the scatter plot render function
        .scatter_data = NULL,

        .init = function() {
            self$results$scatterPlot$setSize(500, 450)
        },

        .run = function() {
            var_name  <- self$options$var
            join_name <- self$options$joinVar

            if (is.null(var_name) || is.null(join_name))
                return()

            data <- self$data

            tryCatch(
                .validate_numeric_var(data[[var_name]], var_name),
                error   = function(e) stop(e$message),
                warning = function(w) message(w$message)
            )

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

            vals <- shp_joined[[var_name]]

            # Remove NA rows for spatial weights
            complete_idx <- !is.na(vals)
            if (sum(complete_idx) < 3)
                stop("At least 3 non-missing values are required for Moran's I.")

            shp_complete <- shp_joined[complete_idx, ]
            vals_complete <- vals[complete_idx]

            # Build spatial weights
            listw <- tryCatch(
                withCallingHandlers(
                    .build_spatial_weights(
                        shp_complete,
                        self$options$weightsType,
                        self$options$kNeighbors
                    ),
                    warning = function(w) {
                        message(w$message)
                        invokeRestart("muffleWarning")
                    }
                ),
                error = function(e) stop(e$message)
            )

            # Run Moran's I test
            mtest <- spdep::moran.test(
                vals_complete,
                listw,
                alternative   = self$options$alternative,
                zero.policy   = TRUE
            )

            # Populate results table
            # mtest$statistic        = Z-score (standard deviate)
            # mtest$estimate names   = "Moran I statistic", "Expectation", "Variance"
            table <- self$results$testTable
            table$deleteRows()
            table$addRow(
                rowKey = 1,
                values = list(
                    statistic  = unname(mtest$estimate["Moran I statistic"]),
                    expected   = unname(mtest$estimate["Expectation"]),
                    variance   = unname(mtest$estimate["Variance"]),
                    stdDeviate = unname(mtest$statistic),
                    pvalue     = mtest$p.value
                )
            )

            # Build interpretation HTML
            i_val   <- unname(mtest$estimate["Moran I statistic"])
            p_val   <- mtest$p.value
            alt_lab <- switch(self$options$alternative,
                two.sided = "two-sided",
                greater   = "one-sided (greater)",
                less      = "one-sided (less)"
            )

            if (p_val < 0.05) {
                direction <- if (i_val > 0) "positive" else "negative"
                conclusion <- paste0(
                    "There is statistically significant <strong>", direction,
                    " spatial autocorrelation</strong> (p = ",
                    format(p_val, digits = 3, scientific = FALSE), ", ",
                    alt_lab, "). Similar values tend to cluster together in space."
                )
            } else {
                conclusion <- paste0(
                    "No statistically significant spatial autocorrelation was detected ",
                    "(p = ", format(p_val, digits = 3, scientific = FALSE), ", ",
                    alt_lab, "). Values appear to be distributed randomly in space."
                )
            }

            html <- paste0(
                '<div style="padding:10px;border-left:4px solid #3a86ff;background:#f0f6ff;">',
                '<p><strong>Moran\'s I = ', round(i_val, 4), '</strong></p>',
                '<p>', conclusion, '</p>',
                '<p style="font-size:0.85em;color:#555;">',
                'Spatial weights: ', self$options$weightsType,
                if (self$options$weightsType == "knn")
                    paste0(" (k=", self$options$kNeighbors, ")")
                else "",
                '</p>',
                '</div>'
            )
            self$results$interpretation$setContent(html)

            # Cache scatter data for render function
            private$.scatter_data <- list(
                df       = .moran_scatter_data(vals_complete, listw),
                i_val    = i_val,
                var_name = var_name
            )
        },

        .renderScatterPlot = function(image, ggtheme, theme, ...) {
            if (is.null(private$.scatter_data))
                return(FALSE)

            sd   <- private$.scatter_data
            df   <- sd$df
            i_v  <- sd$i_val
            vn   <- sd$var_name

            p <- ggplot2::ggplot(df, ggplot2::aes(x = z, y = lag_z)) +
                ggplot2::geom_point(alpha = 0.7, color = "#3a86ff", size = 2.5) +
                ggplot2::geom_smooth(method = "lm", se = FALSE,
                                     color = "#d62828", linewidth = 0.8) +
                ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "#888") +
                ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "#888") +
                ggplot2::labs(
                    title = paste0("Moran Scatter Plot — ", vn),
                    subtitle = paste0("Moran's I = ", round(i_v, 4)),
                    x = "Standardized Value (z)",
                    y = "Spatial Lag (Wz)"
                ) +
                ggtheme

            print(p)
            TRUE
        }
    )
)
