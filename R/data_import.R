# =============================================================================
# data_import.R
# Purpose : Access TÜİK Motor Land Vehicles data using the tuikr package
#           and prepare the time series for forecasting.
# Author  : Eren EROĞLU
# =============================================================================

# Install tuikr if not already installed
if (!requireNamespace("tuikr", quietly = TRUE)) {
  if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
  devtools::install_github("emraher/tuikr")
}

library(tuikr)
library(httr)
library(dplyr)
library(lubridate)

# ---------------------------------------------------------------------------
# Step 1: Retrieve the table URL for dataflow ID 138721033
#         (Motor Land Vehicles Statistics – Transportation Statistics)
# ---------------------------------------------------------------------------
tables <- tuikr::statistical_tables()

# Filter for our table
target_table <- tables %>%
  filter(id == "138721033")

table_url <- target_table$url[1]
cat("Table URL:", table_url, "\n")

# ---------------------------------------------------------------------------
# Step 2: Fetch the raw data via httr::GET using the table URL
# ---------------------------------------------------------------------------
response <- httr::GET(table_url)
raw_content <- httr::content(response, as = "text", encoding = "UTF-8")

# ---------------------------------------------------------------------------
# Step 3: Parse and structure the data
# ---------------------------------------------------------------------------
# The raw content is tab-delimited; read it accordingly
con <- textConnection(raw_content)
raw_df <- read.delim(con, header = TRUE, sep = "\t",
                     stringsAsFactors = FALSE, check.names = FALSE)
close(con)

# ---------------------------------------------------------------------------
# Step 4: Select "Number of Registered Vehicles" (Tescil Edilen Araç Sayısı)
#         and the date/period column; keep only monthly observations
# ---------------------------------------------------------------------------
# Identify the period/date column (first column)
period_col <- names(raw_df)[1]

# Select relevant variable column (registered vehicles – total)
# Column names may contain Turkish characters; grep for the key term
reg_col <- grep("Tescil|Registered|REGISTERED", names(raw_df),
                value = TRUE, ignore.case = TRUE)[1]

if (is.na(reg_col)) {
  # Fallback: inspect column names
  cat("Available columns:\n")
  print(names(raw_df))
  stop("Could not identify the 'Number of Registered Vehicles' column automatically.")
}

vehicles_raw <- raw_df %>%
  select(period = all_of(period_col),
         registered_vehicles = all_of(reg_col)) %>%
  filter(!is.na(registered_vehicles),
         registered_vehicles != "",
         !is.na(period))

# ---------------------------------------------------------------------------
# Step 5: Parse the period column into a proper date (YYYY-MM-DD)
#         TÜİK typically uses "YYYY-MM" or "Month YYYY" formats
# ---------------------------------------------------------------------------
vehicles_raw <- vehicles_raw %>%
  mutate(
    period_clean = as.character(period),
    # Try YYYY-MM format first
    date = suppressWarnings(
      parse_date_time(period_clean, orders = c("Ym", "Y-m", "mY", "d/m/Y"))
    )
  ) %>%
  filter(!is.na(date)) %>%
  mutate(
    date = as.Date(date),
    registered_vehicles = as.numeric(
      gsub(",", "", gsub("\\.", "", registered_vehicles))
    )
  ) %>%
  filter(!is.na(registered_vehicles)) %>%
  arrange(date)

cat("\nData dimensions:", nrow(vehicles_raw), "rows\n")
cat("Period covered:", format(min(vehicles_raw$date), "%Y-%m"),
    "to", format(max(vehicles_raw$date), "%Y-%m"), "\n")
cat("Latest observation:", format(max(vehicles_raw$date), "%Y-%m"), "\n")
cat("Forecast target  : ",
    format(max(vehicles_raw$date) %m+% months(1), "%Y-%m"), "\n")
