# =============================================================================
# accuracy_measures.R
# Purpose : Calculate all required forecast accuracy measures.
# Author  : Eren EROĞLU
# =============================================================================

# ---------------------------------------------------------------------------
# Core accuracy function
# Returns: Bias, MAD, MSE, MAPE, RSFE, Tracking Signal
# ---------------------------------------------------------------------------
calc_accuracy <- function(actual, fitted) {
  # Remove NA pairs
  valid  <- !is.na(actual) & !is.na(fitted)
  actual <- actual[valid]
  fitted <- fitted[valid]
  n      <- length(actual)
  if (n == 0) return(rep(NA, 7))

  errors  <- actual - fitted
  bias    <- mean(errors)                           # Mean Error / Bias
  mad     <- mean(abs(errors))                      # MAD
  mse     <- mean(errors^2)                         # MSE
  mape    <- mean(abs(errors / actual)) * 100       # MAPE (%)
  rsfe    <- sum(errors)                            # RSFE
  ts_val  <- rsfe / mad                             # Tracking Signal

  c(Bias = bias, MAD = mad, MSE = mse,
    MAPE = mape, RSFE = rsfe, TS = ts_val, N = n)
}

# ---------------------------------------------------------------------------
# Build comparison table across all methods
# ---------------------------------------------------------------------------
build_comparison_table <- function(actual_vec, methods_list) {
  results <- lapply(names(methods_list), function(nm) {
    fitted_vec <- methods_list[[nm]]$fitted
    fc_next    <- methods_list[[nm]]$fc_next

    if (is.null(fitted_vec) || all(is.na(fitted_vec))) {
      row <- data.frame(
        Method        = nm,
        Bias          = NA, MAD = NA, MSE = NA,
        MAPE          = NA, RSFE = NA, TS  = NA,
        N             = NA,
        Next_Forecast = if (!is.null(fc_next)) round(fc_next, 0) else NA,
        stringsAsFactors = FALSE
      )
    } else {
      acc <- calc_accuracy(actual_vec, fitted_vec)
      row <- data.frame(
        Method        = nm,
        Bias          = round(acc["Bias"], 2),
        MAD           = round(acc["MAD"],  2),
        MSE           = round(acc["MSE"],  2),
        MAPE          = round(acc["MAPE"], 4),
        RSFE          = round(acc["RSFE"], 2),
        TS            = round(acc["TS"],   4),
        N             = acc["N"],
        Next_Forecast = if (!is.null(fc_next)) round(fc_next, 0) else NA,
        stringsAsFactors = FALSE
      )
    }
    row
  })
  do.call(rbind, results)
}
