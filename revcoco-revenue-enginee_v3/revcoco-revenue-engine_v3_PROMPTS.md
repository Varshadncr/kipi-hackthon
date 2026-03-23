# RevCOCO Revenue Engine V3 — Prompts

## Phase 3: V3 — Python ML Model Comparison Notebook

### Prompt 19 — V3 SQL Setup
> Create a SQL setup that samples 100K rows from KIPI_REVCOCO.MVP.receivables_history into a training view for the notebook.

### Prompt 20 — ML Model Comparison Notebook
> Create a Snowflake Notebook (Python) that compares XGBoost, Logistic Regression, and kNN for at-risk receivables prediction. Pull data via SQL cell, then in Python: engineer 7 features (invoice_amount, past_dso_avg, log_amount, amount_per_dso_day, dso_squared_scaled, amount_normalized, high_risk_combo). Train XGBoost (100 estimators, max_depth 5), Logistic Regression (max_iter 1000), and kNN (k=7) — use StandardScaler for LR and kNN. Compare accuracy/precision/recall, show confusion matrices side by side, bar chart comparison, and XGBoost feature importance. Add a summary table of each algorithm's strengths.
