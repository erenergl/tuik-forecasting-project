# =============================================================================
# forecasting_methods.R
# Purpose : All forecasting method functions used in the project.
# Author  : Eren EROĞLU
# =============================================================================

library(forecast)
library(dplyr)

# ---------------------------------------------------------------------------
# 1. Naïve Forecasting
# ---------------------------------------------------------------------------
naive_forecast <- function(ts_data) {
  fit <- naive(ts_data)
  list(
    model  = fit,
    fitted = as.numeric(fitted(fit)),
    fc_next = as.numeric(forecast(fit, h = 1)$mean)
  )
}

# ---------------------------------------------------------------------------
# 2. Moving Average (window = k)
# ---------------------------------------------------------------------------
moving_average_forecast <- function(ts_data, k = 3) {
  n      <- length(ts_data)
  fitted <- rep(NA, n)
  for (i in (k + 1):n) {
    fitted[i] <- mean(ts_data[(i - k):(i - 1)])
  }
  fc_next <- mean(ts_data[(n - k + 1):n])
  list(fitted = fitted, fc_next = fc_next, k = k)
}

# ---------------------------------------------------------------------------
# 3. Weighted Moving Average
# ---------------------------------------------------------------------------
wma_forecast <- function(ts_data, weights = c(1, 2, 3)) {
  # Normalise weights so they sum to 1
  w  <- weights / sum(weights)
  k  <- length(w)
  n  <- length(ts_data)
  fitted <- rep(NA, n)
  for (i in (k + 1):n) {
    fitted[i] <- sum(w * ts_data[(i - k):(i - 1)])
  }
  fc_next <- sum(w * ts_data[(n - k + 1):n])
  list(fitted = fitted, fc_next = fc_next, weights = w)
}

# ---------------------------------------------------------------------------
# 4. Simple Exponential Smoothing
# ---------------------------------------------------------------------------
ses_forecast <- function(ts_data, alpha = NULL) {
  fit <- if (is.null(alpha)) {
    ets(ts_data, model = "ANN")
  } else {
    ets(ts_data, model = "ANN", alpha = alpha)
  }
  list(
    model  = fit,
    alpha  = fit$par["alpha"],
    fitted = as.numeric(fitted(fit)),
    fc_next = as.numeric(forecast(fit, h = 1)$mean)
  )
}

# ---------------------------------------------------------------------------
# 5. Trend-Adjusted Exponential Smoothing (Holt's)
# ---------------------------------------------------------------------------
holt_forecast <- function(ts_data, alpha = NULL, beta = NULL) {
  fit <- if (is.null(alpha) && is.null(beta)) {
    ets(ts_data, model = "AAN")
  } else {
    ets(ts_data, model = "AAN",
        alpha = alpha, beta = beta)
  }
  list(
    model   = fit,
    alpha   = fit$par["alpha"],
    beta    = fit$par["beta"],
    fitted  = as.numeric(fitted(fit)),
    fc_next = as.numeric(forecast(fit, h = 1)$mean)
  )
}

# ---------------------------------------------------------------------------
# 6. Linear Trend Projection
# ---------------------------------------------------------------------------
trend_projection <- function(ts_data) {
  n  <- length(ts_data)
  t  <- 1:n
  df <- data.frame(y = as.numeric(ts_data), t = t)
  fit <- lm(y ~ t, data = df)
  fc_next <- predict(fit, newdata = data.frame(t = n + 1))
  list(
    model      = fit,
    fitted     = as.numeric(fitted(fit)),
    fc_next    = as.numeric(fc_next),
    intercept  = coef(fit)[1],
    slope      = coef(fit)[2]
  )
}

# ---------------------------------------------------------------------------
# 7. Seasonal Indices
# ---------------------------------------------------------------------------
seasonal_indices <- function(ts_data) {
  freq <- frequency(ts_data)
  if (freq == 1) {
    message("Annual data – seasonal indices not applicable.")
    return(NULL)
  }
  n   <- length(ts_data)
  t   <- 1:n
  # Centred moving average for trend
  cma <- stats::filter(as.numeric(ts_data),
                       rep(1 / freq, freq), sides = 2)
  ratio <- as.numeric(ts_data) / cma

  # Average ratio by season
  season <- cycle(ts_data)
  si <- tapply(ratio, season, mean, na.rm = TRUE)
  # Normalise so mean = 1
  si <- si / mean(si)

  # Deseasonalised series
  deseas <- as.numeric(ts_data) / si[season]

  # Trend on deseasonalised
  fit_trend <- lm(deseas ~ t)
  trend_vals <- as.numeric(fitted(fit_trend))
  fc_next_t  <- as.numeric(predict(fit_trend,
                                    newdata = data.frame(t = n + 1)))
  next_season <- (n %% freq) + 1
  fc_next     <- fc_next_t * si[next_season]

  list(
    si          = si,
    deseas      = deseas,
    trend_vals  = trend_vals,
    fitted      = trend_vals * si[season],
    fc_next     = fc_next,
    next_season = next_season
  )
}

# ---------------------------------------------------------------------------
# 8. Additive Decomposition forecast
# ---------------------------------------------------------------------------
additive_decomp_forecast <- function(ts_data) {
  freq <- frequency(ts_data)
  if (freq == 1 || length(ts_data) < 2 * freq) {
    message("Insufficient observations for additive decomposition.")
    return(NULL)
  }
  dec  <- decompose(ts_data, type = "additive")
  n    <- length(ts_data)
  t    <- 1:n

  # Fit trend line to the trend component (removing NAs)
  trend_vec <- as.numeric(dec$trend)
  valid     <- !is.na(trend_vec)
  fit_t     <- lm(trend_vec[valid] ~ t[valid])
  trend_all <- as.numeric(predict(fit_t,
                                   newdata = data.frame(`t[valid]` = t,
                                                        check.names = FALSE)))
  # Simpler: use coef directly
  b0 <- coef(fit_t)[1]; b1 <- coef(fit_t)[2]
  trend_all <- b0 + b1 * t
  fc_trend  <- b0 + b1 * (n + 1)

  season_vec <- as.numeric(dec$seasonal)
  next_s     <- season_vec[(n %% freq) + 1]
  fc_next    <- fc_trend + next_s

  fitted_vals <- trend_all + season_vec

  list(
    decomp  = dec,
    fitted  = fitted_vals,
    fc_next = fc_next
  )
}

# ---------------------------------------------------------------------------
# 9. Multiplicative Decomposition forecast
# ---------------------------------------------------------------------------
multiplicative_decomp_forecast <- function(ts_data) {
  freq <- frequency(ts_data)
  if (freq == 1 || length(ts_data) < 2 * freq) {
    message("Insufficient observations for multiplicative decomposition.")
    return(NULL)
  }
  dec <- decompose(ts_data, type = "multiplicative")
  n   <- length(ts_data)
  t   <- 1:n

  trend_vec <- as.numeric(dec$trend)
  valid     <- !is.na(trend_vec)
  fit_t     <- lm(trend_vec[valid] ~ t[valid])
  b0 <- coef(fit_t)[1]; b1 <- coef(fit_t)[2]
  trend_all <- b0 + b1 * t
  fc_trend  <- b0 + b1 * (n + 1)

  season_vec <- as.numeric(dec$seasonal)
  next_s     <- season_vec[(n %% freq) + 1]
  fc_next    <- fc_trend * next_s

  fitted_vals <- trend_all * season_vec

  list(
    decomp  = dec,
    fitted  = fitted_vals,
    fc_next = fc_next
  )
}

# ---------------------------------------------------------------------------
# 10. Regression with Trend + Seasonal Dummies
# ---------------------------------------------------------------------------
reg_seasonal_forecast <- function(ts_data) {
  freq <- frequency(ts_data)
  n    <- length(ts_data)
  t    <- 1:n
  s    <- cycle(ts_data)

  if (freq == 1) {
    message("Annual data – seasonal dummies not applicable.")
    # Trend-only regression
    df  <- data.frame(y = as.numeric(ts_data), t = t)
    fit <- lm(y ~ t, data = df)
    fc_next <- as.numeric(predict(fit,
                                   newdata = data.frame(t = n + 1)))
    return(list(model   = fit,
                fitted  = as.numeric(fitted(fit)),
                fc_next = fc_next,
                seasonal_dummies = FALSE))
  }

  # Create dummy variables (reference = season 1)
  season_factor <- factor(s, levels = 1:freq)
  df  <- data.frame(y = as.numeric(ts_data), t = t,
                    season = season_factor)
  fit <- lm(y ~ t + season, data = df)

  # Next period
  next_s  <- (n %% freq) + 1
  new_df  <- data.frame(t = n + 1,
                         season = factor(next_s, levels = 1:freq))
  fc_next <- as.numeric(predict(fit, newdata = new_df))

  list(
    model            = fit,
    fitted           = as.numeric(fitted(fit)),
    fc_next          = fc_next,
    seasonal_dummies = TRUE
  )
}
