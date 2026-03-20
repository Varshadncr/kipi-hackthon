-- ============================================================
-- STEP 3: CORTEX ML - AT-RISK RECEIVABLES PREDICTION
-- Predicts which invoices are likely to be paid late
-- ============================================================

USE DATABASE KIPI_REVCOCO;
USE SCHEMA MVP;

-- 3a. Create Training Data View
CREATE OR REPLACE VIEW receivables_training_view AS
SELECT 
    invoice_amount,
    past_dso_avg,
    is_late
FROM receivables_history;

-- 3b. Train Classification Model
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION at_risk_receivable_model(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'KIPI_REVCOCO.MVP.receivables_training_view'),
    TARGET_COLNAME => 'IS_LATE'
);

-- 3c. Check Model Evaluation Metrics
CALL at_risk_receivable_model!SHOW_EVALUATION_METRICS();
CALL at_risk_receivable_model!SHOW_CONFUSION_MATRIX();
CALL at_risk_receivable_model!SHOW_FEATURE_IMPORTANCE();

-- 3d. Create Current Receivables View (with client DSO history)
CREATE OR REPLACE VIEW current_receivables AS
SELECT
    r.event_id AS invoice_id,
    r.client_id,
    r.client_name,
    r.billable_amount AS invoice_amount,
    COALESCE(h.past_dso_avg, 25) AS past_dso_avg
FROM ready_to_bill r
LEFT JOIN (
    SELECT client_id, AVG(past_dso_avg) AS past_dso_avg 
    FROM receivables_history 
    GROUP BY client_id
) h ON r.client_id = h.client_id;

-- 3e. Create At-Risk Receivables View with ML Predictions
CREATE OR REPLACE VIEW at_risk_receivables AS
SELECT 
    invoice_id,
    client_id,
    client_name,
    invoice_amount,
    past_dso_avg,
    at_risk_receivable_model!PREDICT(
        INPUT_DATA => OBJECT_CONSTRUCT(
            'INVOICE_AMOUNT', invoice_amount,
            'PAST_DSO_AVG', past_dso_avg
        )
    ) AS prediction,
    prediction:class::STRING AS risk_status,
    prediction:probability:true::FLOAT AS risk_probability
FROM current_receivables;

-- Verify At-Risk Predictions
SELECT client_name, invoice_amount, past_dso_avg, risk_status, 
       ROUND(risk_probability * 100, 1) AS risk_pct
FROM at_risk_receivables
ORDER BY risk_probability DESC
LIMIT 10;
