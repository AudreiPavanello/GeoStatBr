# localmorantest.b.R — Local Moran's I (LISA) implementation
# This file is hand-written. Do NOT overwrite with jmvtools::prepare().

localmorantestClass <- R6::R6Class(
    "localmorantest",
    inherit = localmorantestBase,
    private = list(

        # Cached results shared between .run() and render functions
        .lisa_shp   = NULL,   # sf object with lisa results joined
        .lisa_df    = NULL,   # plain data frame with lisa columns
        .var_name   = NULL,

        .init = function() {
            self$results$clusterMap$setSize(600, 450)
            self$results$sigMap$setSize(600, 450)
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

            complete_idx <- !is.na(vals)
            if (sum(complete_idx) < 3)
                stop("At least 3 non-missing values are required for LISA.")

            shp_complete  <- shp_joined[complete_idx, ]
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

            nperm   <- .nperm_value(self$options$nperm)
            sig_thr <- .sig_level_value(self$options$sigLevel)

            # Compute local Moran's I with permutation-based p-values
            lisa <- spdep::localmoran_perm(
                vals_complete,
                listw,
                nsim        = nperm,
                zero.policy = TRUE,
                alternative = "two.sided"
            )

            z_std  <- scale(vals_complete)[, 1]
            lag_z  <- spdep::lag.listw(listw, z_std, zero.policy = TRUE)
            pvals  <- lisa[, "Pr(z != E(Ii))"]
            local_i <- lisa[, "Ii"]
            z_scores <- lisa[, "Z.Ii"]

            cluster_cat <- .classify_lisa(z_std, lag_z, pvals, sig_thr)

            # Name column for display
            name_col <- attr(shp, "name_col")
            region_names <- if (name_col %in% names(shp_complete)) {
                as.character(shp_complete[[name_col]])
            } else {
                as.character(seq_len(nrow(shp_complete)))
            }

            # Populate LISA table
            table <- self$results$lisaTable
            table$deleteRows()
            for (i in seq_along(region_names)) {
                table$addRow(
                    rowKey = i,
                    values = list(
                        region  = region_names[i],
                        localI  = local_i[i],
                        zScore  = z_scores[i],
                        pvalue  = pvals[i],
                        cluster = cluster_cat[i]
                    )
                )
            }

            # Build interpretation HTML
            counts <- table(cluster_cat)
            cluster_summary <- paste(
                names(counts), counts, sep = ": ", collapse = "; "
            )

            html <- paste0(
                '<div style="padding:10px;border-left:4px solid #3a86ff;background:#f0f6ff;">',
                '<p><strong>LISA Cluster Summary</strong> (significance level: p &lt; ',
                sig_thr, ', permutations: ', nperm, ')</p>',
                '<p>', cluster_summary, '</p>',
                '<ul>',
                '<li><span style="color:#d7191c;font-weight:bold;">High-High</span>: ',
                'High-value region surrounded by high-value neighbors (hot spot).</li>',
                '<li><span style="color:#2c7bb6;font-weight:bold;">Low-Low</span>: ',
                'Low-value region surrounded by low-value neighbors (cold spot).</li>',
                '<li><span style="color:#fdae61;font-weight:bold;">High-Low</span>: ',
                'High-value region surrounded by low-value neighbors (spatial outlier).</li>',
                '<li><span style="color:#abd9e9;font-weight:bold;">Low-High</span>: ',
                'Low-value region surrounded by high-value neighbors (spatial outlier).</li>',
                '<li><span style="color:#888;font-weight:bold;">Not Significant</span>: ',
                'No statistically significant local pattern detected.</li>',
                '</ul>',
                '</div>'
            )
            self$results$interpretation$setContent(html)

            # Cache for render functions — build full-length vectors first,
            # then assign via [[<- only (avoids [<-.sf row-subset shrinkage)
            n_full       <- nrow(shp_joined)
            li_full      <- rep(NA_real_, n_full)
            z_full       <- rep(NA_real_, n_full)
            pv_full      <- rep(NA_real_, n_full)
            cluster_full <- rep(NA_character_, n_full)

            li_full[complete_idx]      <- local_i
            z_full[complete_idx]       <- z_scores
            pv_full[complete_idx]      <- pvals
            cluster_full[complete_idx] <- cluster_cat

            shp_joined[["..lisa_local_i"]] <- li_full
            shp_joined[["..lisa_z"]]       <- z_full
            shp_joined[["..lisa_pvalue"]]  <- pv_full
            shp_joined[["..lisa_cluster"]] <- factor(
                cluster_full,
                levels = c("High-High", "Low-Low", "High-Low", "Low-High", "Not Significant")
            )

            private$.lisa_shp  <- shp_joined   # full Paraná; non-data municipalities are NA (grey)
            private$.lisa_df   <- data.frame(
                cluster = cluster_cat,
                pvalue  = pvals
            )
            private$.var_name  <- var_name
        },

        .renderClusterMap = function(image, ggtheme, theme, ...) {
            if (is.null(private$.lisa_shp))
                return(FALSE)

            shp      <- private$.lisa_shp
            var_name <- private$.var_name
            colors   <- .lisa_colors[levels(shp[["..lisa_cluster"]])]

            p <- ggplot2::ggplot(shp) +
                ggplot2::geom_sf(ggplot2::aes(fill = .data[["..lisa_cluster"]]),
                                 color = "white", linewidth = 0.15) +
                ggplot2::scale_fill_manual(values       = colors,
                                           name         = "Cluster Type",
                                           na.value     = "#cccccc",
                                           na.translate = FALSE,
                                           drop         = FALSE) +
                ggplot2::labs(title = paste0("LISA Cluster Map \u2014 ", var_name)) +
                ggplot2::theme_void() +
                ggplot2::theme(
                    plot.title      = ggplot2::element_text(hjust = 0.5, size = 12),
                    legend.position = "right"
                )

            print(p)
            TRUE
        },

        .renderSigMap = function(image, ggtheme, theme, ...) {
            if (is.null(private$.lisa_shp))
                return(FALSE)

            shp      <- private$.lisa_shp
            var_name <- private$.var_name

            pvals    <- shp[["..lisa_pvalue"]]
            sig_band <- cut(
                pvals,
                breaks = c(-Inf, 0.001, 0.01, 0.05, 1),
                labels = c("p < 0.001", "p < 0.01", "p < 0.05", "Not Significant"),
                right  = TRUE
            )
            shp[["sig_band"]] <- sig_band

            sig_colors <- c(
                "p < 0.001"       = "#08306b",
                "p < 0.01"        = "#2171b5",
                "p < 0.05"        = "#6baed6",
                "Not Significant" = "#cccccc"
            )
            colors <- sig_colors[levels(droplevels(sig_band))]

            p <- ggplot2::ggplot(shp) +
                ggplot2::geom_sf(ggplot2::aes(fill = sig_band),
                                 color = "white", linewidth = 0.15) +
                ggplot2::scale_fill_manual(values       = colors,
                                           name         = "Significance",
                                           na.value     = "#cccccc",
                                           na.translate = FALSE,
                                           drop         = TRUE) +
                ggplot2::labs(title = paste0("LISA Significance Map \u2014 ", var_name)) +
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
