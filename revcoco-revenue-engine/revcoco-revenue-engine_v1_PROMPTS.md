# RevCOCO Revenue Engine V1 — Prompts

## Phase 0: Source Data Setup

### Prompt 1 — Base Tables & Sample Data
> Create a database called KIPI_REVCOCO with a schema MVP. Create 3 tables: (1) contracts table with client_id, client_name, print_rate, digital_rate, contract_start_date — insert 3 sample clients (Acme Corp, Global Tech, Local Bank). (2) production_logs table with event_id (UUID default), client_id, event_type (PRINT/DIGITAL), quantity, event_timestamp — insert 4 sample records. (3) receivables_history table with invoice_id, client_id, invoice_amount, days_to_pay, past_dso_avg, is_late (boolean) — insert 6 synthetic training rows where C003 is often late and higher amounts tend to be later.

### Prompt 2 — Scale Contracts to 50 Clients
> Expand the contracts table to 50 clients using GENERATOR with random company names (Pinnacle Solutions, Bright Media, Sterling Logistics, Nexus Retail, Summit Finance), random print rates (0.10-0.20), digital rates (0.03-0.08), and contract start dates spread across the last 2 years.

### Prompt 3 — Generate 1M Production Logs
> Generate 1,000,000 rows for production_logs — 40% of volume goes to top 10 clients, PRINT is ~60% / DIGITAL is ~40%, PRINT lower quantity (1k-50k), DIGITAL higher (10k-500k), events spread across last 2 years.

### Prompt 4 — Generate 1M Receivables History
> Generate 1,000,000 rows for receivables_history — 20% "risky" clients (C030-C050 band), 80% normal (C001-C029). Invoice amounts skewed (70% small $500-$5000, 30% large $5000-$50000). Risky clients have past_dso_avg 35-55, normal 10-30. days_to_pay anchored around past_dso_avg with variance, large invoices add 0-15 extra days. is_late = days_to_pay > 30.

### Prompt 5 — Data Quality Checks & Constraints
> Check for NULLs across all 3 tables, delete any NULL rows from contracts, add NOT NULL constraints on all contracts columns. Verify data quality — check row counts, is_late rate (~30-40%), event distribution.

---

## Phase 1: V1 — Dynamic Tables + Cortex ML + Streamlit

### Prompt 6 — Dynamic Table (Order-to-Cash Reconciliation)
> Create a Dynamic Table called ready_to_bill with TARGET_LAG = 1 minute that auto-joins production_logs with contracts on client_id. Calculate unit_rate and billable_amount based on event_type (PRINT uses print_rate, DIGITAL uses digital_rate). Add billing_status = 'READY_TO_BILL' and processed_at timestamp.

### Prompt 7 — Cortex ML Classification Model
> Create a Cortex ML Classification model to predict at-risk receivables. Create a training view with invoice_amount and past_dso_avg as features and is_late as the target. Train the model using SNOWFLAKE.ML.CLASSIFICATION. Show evaluation metrics, confusion matrix, and feature importance.

### Prompt 8 — Prediction Views
> Create a current_receivables view that joins ready_to_bill with historical DSO averages per client from receivables_history (default 25 if no history). Then create an at_risk_receivables view that uses the trained model's PREDICT function to get risk_status and risk_probability for each current receivable.

### Prompt 9 — Streamlit Dashboard
> Create a Streamlit dashboard for the Revenue Engine. Show 4 KPI metrics at the top (Ready-to-Bill count, Total Billable Amount, At-Risk Invoices, At-Risk Amount). Add 3 tabs: Ready-to-Bill records table, At-Risk Receivables with risk highlighting (red for at-risk), and Analytics with Revenue by Client bar chart and Revenue by Event Type bar chart.

### Prompt 10 — Deploy Streamlit App
> Deploy the Streamlit app — create a stage called streamlit_stage, create the Streamlit app object pointing to revenue_dashboard.py.

---

## V1 Iteration & Quality

### Prompt 11 — Validation Test Suite
> Create a validation test suite — test for duplicate contracts, unmatched production logs, billable amount calculation correctness, rate matching, ML predictions being generated, risk scores in valid 0-1 range, dynamic table freshness, and record count sanity checks.

### Prompt 12 — Data Quality Fixes
> Fix data quality issues — deduplicate contracts (keep earliest contract_start_date), add default contracts for orphaned client_ids (print_rate 0.15, digital_rate 0.05), refresh the dynamic table after fixes.

### Prompt 13 — Advanced Analytics Queries
> Create advanced analytics queries — daily revenue pulse, week-over-week growth, client tier segmentation (Platinum/Gold/Silver/Bronze), client health score, print vs digital deep dive, revenue by rate tier, hourly/day-of-week patterns, risk heatmap, expected collection timeline, Pareto analysis (80/20), anomaly detection (3 std dev), monthly revenue spike detection, 7-day moving average, billing efficiency metrics, and executive scorecard.

### Prompt 14 — Enhanced Streamlit Dashboard
> Enhance the Streamlit dashboard with 5 tabs: Ready-to-Bill, At-Risk, Revenue Analytics (monthly trend, revenue by type, top 10 clients, rate tiers, day-of-week pattern, revenue concentration), Risk Analytics (risk distribution low/medium/high, collection timeline, risk histogram, highest risk clients, risk summary metrics), and Client Intelligence (client tiers, client health score, client detail view with selectbox and per-client monthly trend).
