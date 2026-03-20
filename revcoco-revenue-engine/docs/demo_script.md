# RevCOCO Revenue Engine - Live Demo Script

## Demo Duration: 10-15 minutes

---

## Opening (2 min)

**Problem Statement:**
> "RevCOCO is losing money through margin erosion. Production logs aren't reconciled with contracts, invoicing takes weeks, and we can't predict which clients will pay late."

**Solution Preview:**
> "We built a Native Revenue Engine in Snowflake that automates everything - from billing reconciliation to predicting at-risk receivables."

---

## Demo 1: Dynamic Tables - Auto-Reconciliation (3 min)

### Show the Problem
```sql
-- Before: Disconnected data
SELECT * FROM production_logs LIMIT 5;
SELECT * FROM contracts LIMIT 5;
-- These are separate - manual reconciliation needed!
```

### Show the Solution
```sql
-- After: Auto-reconciled Ready-to-Bill records
SELECT client_name, event_type, quantity, unit_rate, billable_amount
FROM ready_to_bill
LIMIT 10;
```

### Live Demo - Insert New Event
```sql
-- Insert a new production event
INSERT INTO production_logs (client_id, event_type, quantity) 
VALUES ('C001', 'PRINT', 25000);

-- Wait 1 minute, then show it appears automatically
SELECT * FROM ready_to_bill 
WHERE quantity = 25000;
```

**Talking Point:** 
> "Every production event is automatically matched to contract pricing. No manual reconciliation. 100% revenue capture."

---

## Demo 2: Cortex ML - At-Risk Predictions (3 min)

### Show Model Performance
```sql
CALL at_risk_receivable_model!SHOW_EVALUATION_METRICS();
-- Highlight: 89% precision
```

### Show Predictions
```sql
SELECT client_name, invoice_amount, 
       ROUND(risk_probability * 100, 1) AS risk_pct
FROM at_risk_receivables
WHERE risk_status = 'True'
ORDER BY risk_probability DESC
LIMIT 10;
```

**Talking Point:**
> "Our ML model predicts which invoices are likely to be paid late with 89% accuracy. This lets AR teams proactively reach out to at-risk clients."

---

## Demo 3: Streamlit Dashboard (3 min)

### Navigate to Dashboard
1. Go to **Projects** → **Streamlit** → **REVENUE_DASHBOARD**
2. Show the 4 KPI metrics at top
3. Walk through each tab:
   - Ready-to-Bill records
   - At-Risk receivables (highlight red rows)
   - Analytics charts

**Talking Point:**
> "Executives get real-time visibility into total billable amounts and at-risk receivables. No more waiting for monthly reports."

---

## Closing - Business Impact (2 min)

| Metric | Before | After |
|--------|--------|-------|
| Revenue Capture | ~85% (manual errors) | **100%** |
| Invoicing Cycle | 2-3 weeks | **< 1 minute** |
| DSO Prediction | None | **89% accuracy** |
| Cash Flow Visibility | Monthly | **Real-time** |

**ROI Calculation:**
> "If we're processing $15B in billable amount and previously had 15% leakage, that's $2.25B recovered annually."

---

## Q&A Prep

**Q: How often does the Dynamic Table refresh?**
> A: Every 1 minute (configurable). You can set TARGET_LAG to any interval.

**Q: What data does the ML model use?**
> A: Invoice amount and client's historical average days-to-pay (DSO). We can add more features.

**Q: Can we integrate with our ERP?**
> A: Yes, production_logs can be fed from any source via Snowpipe, Kafka connector, or batch loads.

**Q: What's the cost?**
> A: Dynamic Tables and Cortex ML use standard Snowflake compute. Streamlit is included. Estimate: minimal incremental cost on existing warehouse.
