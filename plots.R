# =============================================================================
# plots.R
# Purpose : Generate and save all required actual vs forecast plots.
# Author  : Eren EROĞLU
# =============================================================================

library(ggplot2)
library(dplyr)

FIGURES_DIR <- "outputs/figures"

# ---------------------------------------------------------------------------
# Helper: base plot of actual series
# ---------------------------------------------------------------------------
base_plot <- function(dates, actual,
                      title = "Actual Time Series",
                      ylab  = "Number of Registered Vehicles") {
  df <- data.frame(date = dates, value = actual, series = "Actual")
  ggplot(df, aes(x = date, y = value, colour = series)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c("Actual" = "#2C3E50")) +
    labs(title = title, x = "Date", y = ylab, colour = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
}

# ---------------------------------------------------------------------------
# Helper: actual vs fitted (+ next period forecast point)
# ---------------------------------------------------------------------------
av_plot <- function(dates, actual, fitted_vals,
                    fc_date, fc_val,
                    method_name,
                    ylab = "Number of Registered Vehicles") {
  df_actual <- data.frame(date = dates, value = actual,       series = "Actual")
  df_fitted <- data.frame(date = dates, value = fitted_vals,  series = "Fitted")
  df_fc     <- data.frame(date = fc_date, value = fc_val,     series = "Forecast")

  # Remove NA from fitted
  df_fitted <- df_fitted[!is.na(df_fitted$value), ]

  df_all <- bind_rows(df_actual, df_fitted, df_fc)

  ggplot(df_all, aes(x = date, y = value,
                     colour = series, linetype = series)) +
    geom_line(data = df_all[df_all$series != "Forecast", ],
              linewidth = 0.8) +
    geom_point(data = df_all[df_all$series == "Forecast", ],
               size = 3, shape = 17) +
    scale_colour_manual(
      values = c("Actual"   = "#2C3E50",
                 "Fitted"   = "#E74C3C",
                 "Forecast" = "#27AE60")
    ) +
    scale_linetype_manual(
      values = c("Actual"   = "solid",
                 "Fitted"   = "dashed",
                 "Forecast" = "blank")
    ) +
    labs(title   = paste("Actual vs", method_name),
         x = "Date", y = ylab, colour = NULL, linetype = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
}

# ---------------------------------------------------------------------------
# Save helper
# ---------------------------------------------------------------------------
save_plot <- function(p, filename, width = 10, height = 5) {
  path <- file.path(FIGURES_DIR, filename)
  ggsave(path, plot = p, width = width, height = height, dpi = 150)
  invisible(path)
}

# ---------------------------------------------------------------------------
# Plot actual series
# ---------------------------------------------------------------------------
plot_actual <- function(dates, actual) {
  p <- base_plot(dates, actual,
                 title = "Motor Land Vehicles – Number of Registered Vehicles (Monthly)")
  save_plot(p, "actual_series_plot.png")
  p
}

# ---------------------------------------------------------------------------
# Plot wrappers for each method
# ---------------------------------------------------------------------------
plot_method <- function(dates, actual, fitted_vals,
                        fc_date, fc_val,
                        method_name, filename) {
  p <- av_plot(dates, actual, fitted_vals,
               fc_date, fc_val, method_name)
  save_plot(p, filename)
  p
}

# ---------------------------------------------------------------------------
# Final superior method plot (with shaded forecast region)
# ---------------------------------------------------------------------------
plot_superior <- function(dates, actual, fitted_vals,
                          fc_date, fc_val,
                          method_name) {
  p <- av_plot(dates, actual, fitted_vals,
               fc_date, fc_val, method_name) +
    annotate("text",
             x     = fc_date,
             y     = fc_val * 1.05,
             label = paste0("Forecast: ", format(round(fc_val), big.mark = ",")),
             size  = 3.5, colour = "#27AE60", hjust = 0) +
    labs(title = paste("Superior Method:", method_name,
                       "– Next-Period Forecast"))
  save_plot(p, "superior_method_plot.png")
  p
}
