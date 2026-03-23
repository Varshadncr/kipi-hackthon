<p align="center">
  <h1 align="center">RevCOCO Native Revenue Engine</h1>
  <p align="center">
    Automating Order-to-Cash with Snowflake — Dynamic Tables, Cortex ML & Streamlit
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Snowflake-100%25%20Native-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white" />
  <img src="https://img.shields.io/badge/ML-Cortex%20Classification-FF6F00?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Dashboard-Streamlit-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

---

## The Problem

RevCOCO faces **Margin Erosion** from a disconnected billing lifecycle:

| Pain Point | Business Impact |
|---|---|
| **Manual Reconciliation** | Production logs disconnected from contract pricing — ~15% revenue leakage |
| **Slow Invoicing** | 2–3 week cycle to generate invoices — delayed cash collection |
| **Unpredictable DSO** | No visibility into which clients will pay late — poor cash flow planning |
| **No Real-time Visibility** | Monthly reporting only — reactive decision-making |

**Estimated Annual Loss:** $2.25B+ on $15B billable volume

---

## The Solution

A unified, 100% Snowflake-native Order-to-Cash platform that eliminates manual processes and provides predictive AR intelligence.

```
Production Logs + Contracts
        │
        ▼
  Dynamic Table (1-min refresh)
  Auto-reconcile every event with contract pricing
        │
        ▼
  Cortex ML Classification
  Predict at-risk receivables before they become late
        │
        ▼
  Streamlit Dashboard
  Real-time KPIs, risk alerts, executive visibility
```

---

## Results

| Metric | Before | After | Improvement |
|---|---|---|---|
| **Revenue Capture** | ~85% | 100% | +15% recovered |
| **Invoicing Cycle** | 2–3 weeks | < 1 minute | 99.9% faster |
| **Late Payment Prediction** | None | 89% accuracy | Proactive AR |
| **Cash Flow Visibility** | Monthly | Real-time | Instant decisions |
| **Records Processed** | — | 1.1M+ | Fully automated |
| **Total Billable Tracked** | — | $15.4B | Complete visibility |

**ROI:** Recovering 15% revenue leakage on $15B = **$2.25B annual recovery**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         KIPI_REVCOCO.MVP                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │ CONTRACTS    │    │ PRODUCTION   │    │ RECEIVABLES_HISTORY  │  │
│  │ (Pricing)    │    │ LOGS         │    │ (ML Training Data)   │  │
│  └──────┬───────┘    └──────┬───────┘    └──────────┬───────────┘  │
│         │                   │                       │               │
│         └─────────┬─────────┘                       │               │
│                   ▼                                 ▼               │
│         ┌─────────────────┐              ┌─────────────────┐       │
│         │ DYNAMIC TABLE   │              │ CORTEX ML       │       │
│         │ ready_to_bill   │              │ Classification  │       │
│         │ (1-min refresh) │              │ (89% precision) │       │
│         └────────┬────────┘              └────────┬────────┘       │
│                  │                                │                 │
│                  └───────────┬────────────────────┘                 │
│                              ▼                                      │
│                    ┌─────────────────┐                              │
│                    │ at_risk_        │                              │
│                    │ receivables     │                              │
│                    │ (Predictions)   │                              │
│                    └────────┬────────┘                              │
│                             ▼                                       │
│                    ┌─────────────────┐                              │
│                    │ STREAMLIT       │                              │
│                    │ Dashboard       │                              │
│                    └─────────────────┘                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Data** | Snowflake Tables | Contracts, Production Logs, Receivables History |
| **Automation** | Dynamic Tables | 1-minute refresh, auto-reconciliation |
| **ML** | Snowflake Cortex Classification | Late payment prediction (no external tools) |
| **UI** | Streamlit in Snowflake | Native dashboard, zero infrastructure |
| **Security** | Snowflake RBAC | Role-based access, built-in governance |

**Key Advantage:** No external ETL, ML platforms, or BI tools required.

---

## Project Structure

This project evolved through 3 iterations, each adding sophistication:

```
.
├── revcoco-revenue-engine/              # V1 — Core MVP
│   ├── sql/
│   │   ├── 01_setup_environment.sql     # Database, schema, mock data
│   │   ├── 02_dynamic_tables.sql        # Ready-to-Bill automation
│   │   ├── 03_cortex_ml.sql             # Single XGBoost model
│   │   ├── 04_streamlit_deploy.sql      # Dashboard deployment
│   │   ├── 05_validation_tests.sql      # Automated test suite
│   │   ├── 06_data_quality_fix.sql      # Data quality remediation
│   │   └── 07_advanced_analytics.sql    # Extended analytics
│   ├── streamlit/
│   │   ├── revenue_dashboard.py         # Core dashboard
│   │   ├── revenue_dashboard_v2.py      # Enhanced dashboard
│   │   └── revenue_dashboard_v3.py      # Final dashboard
│   └── docs/
│       ├── PROJECT_SUMMARY.md
│       ├── PRESENTATION_DECK.md
│       ├── TESTING_GUIDE.md
│       └── demo_script.md
│
├── revcoco-revenue-engine_v2/           # V2 — Ensemble ML
│   ├── sql/
│   │   ├── 01_setup_environment.sql     # V2 database setup
│   │   ├── 02_dynamic_tables.sql        # Same automation layer
│   │   ├── 03_cortex_ml_ensemble.sql    # 3 models + hard voting
│   │   └── 04_streamlit_deploy.sql      # Ensemble dashboard deploy
│   └── streamlit/
│       └── revenue_dashboard_ensemble.py
│
├── revcoco-revenue-enginee_v3/          # V3 — Python ML Comparison
│   ├── ml_model_comparison.ipynb        # XGBoost vs LR vs kNN notebook
│   └── sql/
│       └── 01_setup_environment.sql     # Training view setup
│

```

---

## Version History

### V1 — Core MVP

Single Cortex ML Classification model with Dynamic Tables and Streamlit dashboard. Establishes the full Order-to-Cash pipeline.

### V2 — Ensemble ML (Hard Voting)

Three models with different feature engineering strategies, combined via majority vote:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   MODEL 1       │  │   MODEL 2       │  │   MODEL 3       │
│ Base Features   │  │ Categorical     │  │ Math Transforms │
│ invoice_amount  │  │ amount_bucket   │  │ log_amount      │
│ past_dso_avg    │  │ payer_category  │  │ amount_per_dso  │
│                 │  │ high_risk_combo │  │ dso_squared     │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         └──────────────┬─────────────────────────┘
                        ▼
              HARD VOTING (2/3 wins)
```

### V3 — Python ML Model Comparison

Snowflake Notebook comparing XGBoost, Logistic Regression, and kNN with 7 engineered features, confusion matrices, and feature importance analysis.

---

## Quick Start

### Prerequisites

- Snowflake account with ACCOUNTADMIN role (or equivalent)
- Warehouse (e.g., `COMPUTE_WH`)
- Cortex ML enabled
- Streamlit in Snowflake enabled

### 1. Setup Environment & Mock Data

```sql
-- Run in Snowflake
-- Creates KIPI_REVCOCO database, MVP schema, and loads mock data
@revcoco-revenue-engine/sql/01_setup_environment.sql
```

### 2. Create Dynamic Tables

```sql
-- Builds the ready_to_bill Dynamic Table with 1-minute refresh
@revcoco-revenue-engine/sql/02_dynamic_tables.sql
```

### 3. Train ML Model

```sql
-- Trains Cortex Classification model on receivables history
@revcoco-revenue-engine/sql/03_cortex_ml.sql
```

### 4. Deploy Dashboard

```sql
-- Creates Streamlit app in Snowflake
@revcoco-revenue-engine/sql/04_streamlit_deploy.sql
```

### 5. Validate

```sql
-- Run the full test suite
@revcoco-revenue-engine/sql/05_validation_tests.sql
```

---

## Testing

A comprehensive test suite covers:

| Test | What It Checks | Pass Criteria |
|---|---|---|
| Reconciliation | Every production log appears in ready_to_bill | Counts match |
| Billing Accuracy | `billable_amount = quantity * unit_rate` | No calculation errors |
| ML Predictions | All receivables have a prediction | No null risk scores |
| Risk Score Validity | Scores are between 0 and 1 | 100% valid |
| Dynamic Table Freshness | Data is current | < 5 minutes old |
| Data Integrity | No orphaned records or duplicate contracts | 0 issues |

```sql
-- Quick health check
SELECT
    (SELECT COUNT(*) FROM KIPI_REVCOCO.MVP.ready_to_bill) AS ready_to_bill_records,
    (SELECT COUNT(*) FROM KIPI_REVCOCO.MVP.production_logs) AS production_logs,
    (SELECT COUNT(*) FROM KIPI_REVCOCO.MVP.at_risk_receivables WHERE risk_status = 'True') AS at_risk_count,
    (SELECT SUM(billable_amount) FROM KIPI_REVCOCO.MVP.ready_to_bill) AS total_billable;
```

See [`docs/TESTING_GUIDE.md`](revcoco-revenue-engine/docs/TESTING_GUIDE.md) for the full testing guide.

---

## Demo

1. **Auto-Reconciliation** — Insert a new production log and watch it appear in `ready_to_bill` within 1 minute
2. **ML Predictions** — Query `at_risk_receivables` to see flagged invoices with risk probabilities
3. **Dashboard** — Open the Streamlit app in Snowsight for real-time KPIs

```sql
-- Insert a test event
INSERT INTO KIPI_REVCOCO.MVP.production_logs (client_id, event_type, quantity)
VALUES ('C001', 'PRINT', 25000);

-- Wait ~1 minute, then verify
SELECT * FROM KIPI_REVCOCO.MVP.ready_to_bill WHERE quantity = 25000;
```

---

## Roadmap

| Phase | Timeline | Deliverable |
|---|---|---|
| **MVP** | Week 1 | Dynamic Tables + ML + Dashboard |
| **Integration** | Week 2–3 | Connect production systems via Snowpipe/Kafka |
| **Enhanced ML** | Week 4–5 | Add features: client industry, payment terms, seasonality |
| **Alerts** | Week 6 | Email/Slack notifications for high-risk receivables |
| **ERP Sync** | Week 7–8 | Push Ready-to-Bill records to invoicing system |
| **Forecasting** | Week 9–10 | Cash flow forecasting with Cortex Time Series |

---

## Snowflake Objects

| Object | Type | Purpose |
|---|---|---|
| `KIPI_REVCOCO.MVP.contracts` | Table | Client pricing |
| `KIPI_REVCOCO.MVP.production_logs` | Table | Events to bill |
| `KIPI_REVCOCO.MVP.receivables_history` | Table | ML training data |
| `KIPI_REVCOCO.MVP.ready_to_bill` | Dynamic Table | Auto-reconciled records |
| `KIPI_REVCOCO.MVP.at_risk_receivable_model` | ML Model | Late payment prediction |
| `KIPI_REVCOCO.MVP.at_risk_receivables` | View | ML predictions |
| `REVENUE_DASHBOARD` | Streamlit App | Executive dashboard |

---

## License

MIT

---

<p align="center">
  Built with Snowflake — Dynamic Tables &bull; Cortex ML &bull; Streamlit
</p>
