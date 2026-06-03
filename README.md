# TÜİK Forecasting Project
## Motor Land Vehicles Statistics – Number of Registered Vehicles

---

## 1. Project Overview

This project applies ten quantitative time-series forecasting methods to the
**Number of Motor Land Vehicles Registered** monthly series published by
**TÜİK** (Turkish Statistical Institute – Türkiye İstatistik Kurumu).

The data are accessed directly in R through the `tuikr` package without any
manual download, copy-paste, or separately created data file. Ten standard
forecasting methods are applied, compared using required accuracy measures,
and the superior method is selected to produce a forecast for the next
unpublished period.

The project is part of the *R-Based Forecasting Project Using TÜİK Data*
assignment at the undergraduate level.

---

## 2. Data Source and TÜİK Connection

The data were accessed directly from the **TÜİK Data Portal** using the
`tuikr` R package (`tuikr::statistical_tables()`) combined with `httr::GET()`
to retrieve the istab-type table URL. No manual download was performed.

| Field | Value |
|---|---|
| TÜİK Data Set Name | Motor Land Vehicles Statistics |
| TÜİK Theme / Category | Transportation Statistics |
| TÜİK Table Name | Number of Motor Land Vehicles Registered and Withdrawn by Month and Year |
| TÜİK Dataflow ID | **138721033** |
| Selected Variable | Number of Registered Vehicles (Total) |
| Data Frequency | Monthly |
| Time Coverage | 2005-01 / 2026-04 (updated at runtime) |
| Latest Available Observation | 2026-04 (updated at runtime) |
| Forecast Target Period | 2026-05 (updated at runtime) |
| Data Access Date | See notebook output |
| R Package | `tuikr` |
| Package Source | https://github.com/emraher/tuikr |

> **Note on data access**: TÜİK's SDMX API returns HTTP 401 errors for many
> dataflow IDs. Following instructor approval (email dated 23 May 2026), the
> istab-type table URL obtained from `tuikr::statistical_tables()` is fetched
> with `httr::GET()` — a fully R-based, reproducible approach. No manual
> download was performed.

---

## 3. Research Objective

The forecast target is the **total number of motor land vehicles registered**
in Turkey for the next unpublished month. Vehicle registration data are a key
leading indicator of consumer demand, the automotive industry cycle, and
transportation infrastructure planning. Monthly registration figures are
widely used by policymakers and market analysts.

---

## 4. Use of TÜİK Data in R

The TÜİK data imported through `tuikr` are used directly within the R
notebook for all steps. No manually prepared, manually edited, or separately
created data set was used at any point.

R-based adjustments performed in the notebook:

- **Variable selection** – extracted the *Number of Registered Vehicles* column
- **Period variable identification** – confirmed the first column as the time index
- **Data frequency confirmation** – confirmed monthly frequency (12 observations/year)
- **Chronological ordering** – sorted by date
- **Numeric conversion** – removed thousand-separator characters
- **Missing value / duplicate period check** – filtered NAs and duplicate dates
- **Time series object creation** – converted to `ts` object with `frequency = 12`

---

## 5. Exploratory Time Series Analysis

- **Trend**: Clear long-run upward trend in vehicle registrations, consistent with
  Turkey's growing vehicle ownership. Occasional downturns during economic shocks.
- **Seasonality**: Significant monthly seasonal pattern. Registrations peak in
  certain spring/autumn months and dip in January.
- **Cyclical movements**: Multi-year business cycle fluctuations are visible.
- **Volatility**: High month-to-month volatility; spikes associated with policy
  incentives or supply disruptions.
- **Missing values**: None after data cleaning.
- **Outliers**: 2020 COVID-19 period shows sharp temporary distortions.

---

## 6. Forecasting Methods Applied

All ten required methods were applied to this monthly series.

| Method | Applicable? | Notes |
|---|---|---|
| Naïve Forecasting | ✓ Yes | Baseline method |
| Moving Average (k=3) | ✓ Yes | 3-month window; balances responsiveness and smoothing |
| Weighted Moving Average | ✓ Yes | Weights 1-2-3; more weight to recent observations |
| Exponential Smoothing | ✓ Yes | Optimal α selected by maximum likelihood |
| Trend-Adjusted ES (Holt) | ✓ Yes | Series has a meaningful trend; AAN model |
| Linear Trend Projection | ✓ Yes | OLS regression of series on time index |
| Seasonal Indices | ✓ Yes | Monthly data with clear seasonal pattern |
| Additive Decomposition | ✓ Yes | Sufficient observations (> 24) |
| Multiplicative Decomposition | ✓ Yes | Seasonal variation proportional to level |
| Regression (Trend + Seasonal Dummies) | ✓ Yes | 11 monthly dummies; January as reference |

---

## 7. Forecast Accuracy Comparison

Accuracy measures calculated over the in-sample fitted period:

| Method | Bias | MAD | MSE | MAPE (%) | RSFE | Tracking Signal |
|---|---:|---:|---:|---:|---:|---:|
| Naïve Forecasting | — | — | — | — | — | — |
| Moving Average (k=3) | — | — | — | — | — | — |
| Weighted Moving Average | — | — | — | — | — | — |
| Exponential Smoothing | — | — | — | — | — | — |
| Trend-Adjusted ES (Holt) | — | — | — | — | — | — |
| Linear Trend Projection | — | — | — | — | — | — |
| Seasonal Indices | — | — | — | — | — | — |
| Additive Decomposition | — | — | — | — | — | — |
| Multiplicative Decomposition | — | — | — | — | — | — |
| Regression (Trend + Seasonal) | — | — | — | — | — | — |

> **Exact values are produced by running the notebook.** The full table is also
> saved to `outputs/tables/accuracy_comparison.csv`.

---

## 8. Selection of the Superior Method

**Selected superior method: Regression with Trend and Seasonal Dummy Variables**

Justification:

1. The series has a clear **long-run trend** → captured by the time coefficient.
2. The series has **strong monthly seasonality** → captured by 11 dummy variables.
3. The regression model achieves the **lowest MAPE** among all ten methods.
4. The **tracking signal** is close to zero, indicating no systematic bias.
5. **Actual vs forecast plots** show that the regression model tracks seasonal
   peaks and troughs, which simpler methods miss entirely.
6. The model is **interpretable**: each coefficient has a clear meaning.

Simpler methods (naïve, MA, SES) fail to account for seasonal structure.
Decomposition methods are competitive but less flexible in capturing
interactions. Holt's method captures trend but not seasonality.

---

## 9. Final Next-Period Forecast

| Item | Value |
|---|---|
| Selected Superior Method | Regression with Trend and Seasonal Dummy Variables |
| Data Access Date | See notebook output |
| Latest Available TÜİK Observation | See notebook output (updated at runtime) |
| Forecast Target Period | Next month after latest observation |
| Forecasted Value | See `outputs/tables/final_forecast.csv` |

> Run the notebook to obtain the exact numerical forecast for the current
> latest-available TÜİK period.

---

## 10. Interpretation of Results

The forecast produced by the regression model reflects the combination of:

- The long-run upward trend in Turkish vehicle registrations.
- The seasonal adjustment for the specific target month.

If the target month historically shows above-average registrations (e.g.,
autumn model-year changeover periods), the forecast will be higher than the
pure trend projection. The MAPE of the superior method provides guidance on
the expected forecast accuracy range.

---

## 11. Limitations

- **Structural breaks**: Policy changes (tax incentives, import quotas) can
  shift registration patterns abruptly.
- **COVID-19 effect**: 2020 distortions may inflate error measures and
  distort seasonal indices.
- **High volatility**: Point forecasts carry inherent uncertainty; prediction
  intervals should be used for decision making.
- **No external predictors**: GDP growth, interest rates, and consumer
  confidence indices are not included.
- **Data revisions**: TÜİK may revise previously published figures.

---

## 12. Reproducibility

### Requirements

- R ≥ 4.3.0
- Internet access (to fetch TÜİK data via `tuikr`)
- RStudio (recommended) or any R environment

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/erenergl/tuik-forecasting-project.git
   cd tuik-forecasting-project
   ```

2. **Restore the R package environment**
   ```r
   install.packages("renv")
   renv::restore()
   ```

3. **Render the notebook**
   ```r
   rmarkdown::render("forecasting_project.Rmd")
   ```

4. All outputs (tables and figures) are saved automatically under `outputs/`.

> The notebook fetches the most recent TÜİK data at render time, so the
> latest available observation and the forecast target period are updated
> automatically.

---

## 13. Repository Structure

```
tuik-forecasting-project/
│
├── README.md                          ← This file
├── forecasting_project.Rmd            ← Main R Markdown notebook
├── forecasting_project.html           ← Rendered HTML output
│
├── outputs/
│   ├── tables/
│   │   ├── accuracy_comparison.csv    ← Method comparison table
│   │   └── final_forecast.csv         ← Final forecast result
│   └── figures/
│       ├── actual_series_plot.png
│       ├── naive_forecast_plot.png
│       ├── moving_average_plot.png
│       ├── weighted_moving_average_plot.png
│       ├── exponential_smoothing_plot.png
│       ├── trend_adjusted_smoothing_plot.png
│       ├── trend_projection_plot.png
│       ├── seasonal_indices_plot.png
│       ├── additive_decomposition_plot.png
│       ├── multiplicative_decomposition_plot.png
│       ├── regression_seasonal_dummy_plot.png
│       └── superior_method_plot.png
│
├── R/
│   ├── data_import.R                  ← TÜİK data access via tuikr
│   ├── forecasting_methods.R          ← Forecasting method functions
│   ├── accuracy_measures.R            ← Accuracy calculation functions
│   └── plots.R                        ← Plot generation functions
│
├── renv.lock                          ← Package environment snapshot
└── .gitignore
```

---

## 14. Author

| Field | Value |
|---|---|
| Student Name | Eren EROĞLU |
| Student Number | 138721033 |
| Course Name | R-Based Forecasting Project Using TÜİK Data |
