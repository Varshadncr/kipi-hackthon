-- ============================================================
-- STEP 3: CORTEX ML ENSEMBLE - AT-RISK RECEIVABLES PREDICTION
-- Uses 3 models with different feature engineering + Hard Voting
-- ============================================================

USE DATABASE KIPI_REVCOCO_V2;
USE SCHEMA MVP;

-- ============================================================
-- MODEL 1: BASE FEATURES (Same as V1 for baseline)
-- Features: invoice_amount, past_dso_avg
-- ============================================================

CREATE OR REPLACE VIEW training_view_model1 AS
SELECT 
    invoice_amount,
    past_dso_avg,
    is_late
FROM receivables_history;

CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION at_risk_model_1(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'KIPI_REVCOCO_V2.MVP.training_view_model1'),
    TARGET_COLNAME => 'IS_LATE'
);

-- ============================================================
-- MODEL 2: ENGINEERED CATEGORICAL FEATURES
-- Features: amount buckets, DSO risk category, interaction terms
-- ============================================================

CREATE OR REPLACE VIEW training_view_model2 AS
SELECT 
    invoice_amount,
    past_dso_avg,
    CASE 
        WHEN invoice_amount < 5000 THEN 'LOW'
        WHEN invoice_amount < 20000 THEN 'MEDIUM'
        WHEN invoice_amount < 35000 THEN 'HIGH'
        ELSE 'VERY_HIGH'
    END AS amount_bucket,
    CASE 
        WHEN past_dso_avg < 20 THEN 'FAST_PAYER'
        WHEN past_dso_avg < 35 THEN 'AVERAGE_PAYER'
        ELSE 'SLOW_PAYER'
    END AS payer_category,
    CASE 
        WHEN invoice_amount > 25000 AND past_dso_avg > 35 THEN 1 
        ELSE 0 
    END AS high_risk_combo,
    is_late
FROM receivables_history;

CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION at_risk_model_2(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'KIPI_REVCOCO_V2.MVP.training_view_model2'),
    TARGET_COLNAME => 'IS_LATE'
);

-- ============================================================
-- MODEL 3: MATHEMATICAL TRANSFORMATIONS
-- Features: log transform, ratios, normalized values
-- ============================================================

CREATE OR REPLACE VIEW training_view_model3 AS
SELECT 
    LN(1 + invoice_amount) AS log_amount,
    past_dso_avg,
    invoice_amount / NULLIF(past_dso_avg, 0) AS amount_per_dso_day,
    POWER(past_dso_avg, 2) / 1000.0 AS dso_squared_scaled,
    (invoice_amount - 15000) / 15000.0 AS amount_normalized,
    is_late
FROM receivables_history;

CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION at_risk_model_3(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'KIPI_REVCOCO_V2.MVP.training_view_model3'),
    TARGET_COLNAME => 'IS_LATE'
);

-- ============================================================
-- CHECK INDIVIDUAL MODEL METRICS
-- ============================================================

CALL at_risk_model_1!SHOW_EVALUATION_METRICS();
CALL at_risk_model_2!SHOW_EVALUATION_METRICS();
CALL at_risk_model_3!SHOW_EVALUATION_METRICS();

-- ============================================================
-- CURRENT RECEIVABLES VIEW (Base for Predictions)
-- ============================================================

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

-- ============================================================
-- ENSEMBLE VIEW WITH HARD VOTING
-- Combines predictions from all 3 models
-- ============================================================

CREATE OR REPLACE VIEW at_risk_ensemble AS
WITH base_features AS (
    SELECT 
        invoice_id,
        client_id,
        client_name,
        invoice_amount,
        past_dso_avg,
        CASE 
            WHEN invoice_amount < 5000 THEN 'LOW'
            WHEN invoice_amount < 20000 THEN 'MEDIUM'
            WHEN invoice_amount < 35000 THEN 'HIGH'
            ELSE 'VERY_HIGH'
        END AS amount_bucket,
        CASE 
            WHEN past_dso_avg < 20 THEN 'FAST_PAYER'
            WHEN past_dso_avg < 35 THEN 'AVERAGE_PAYER'
            ELSE 'SLOW_PAYER'
        END AS payer_category,
        CASE WHEN invoice_amount > 25000 AND past_dso_avg > 35 THEN 1 ELSE 0 END AS high_risk_combo,
        LN(1 + invoice_amount) AS log_amount,
        invoice_amount / NULLIF(past_dso_avg, 0) AS amount_per_dso_day,
        POWER(past_dso_avg, 2) / 1000.0 AS dso_squared_scaled,
        (invoice_amount - 15000) / 15000.0 AS amount_normalized
    FROM current_receivables
),
predictions AS (
    SELECT 
        bf.*,
        at_risk_model_1!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT('INVOICE_AMOUNT', invoice_amount, 'PAST_DSO_AVG', past_dso_avg)
        ) AS pred1,
        at_risk_model_2!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT(
                'INVOICE_AMOUNT', invoice_amount, 
                'PAST_DSO_AVG', past_dso_avg,
                'AMOUNT_BUCKET', amount_bucket,
                'PAYER_CATEGORY', payer_category,
                'HIGH_RISK_COMBO', high_risk_combo
            )
        ) AS pred2,
        at_risk_model_3!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT(
                'LOG_AMOUNT', log_amount, 
                'PAST_DSO_AVG', past_dso_avg,
                'AMOUNT_PER_DSO_DAY', amount_per_dso_day,
                'DSO_SQUARED_SCALED', dso_squared_scaled,
                'AMOUNT_NORMALIZED', amount_normalized
            )
        ) AS pred3
    FROM base_features bf
)
SELECT 
    invoice_id,
    client_id,
    client_name,
    invoice_amount,
    past_dso_avg,
    pred1:class::STRING AS model1_prediction,
    pred1:probability:true::FLOAT AS model1_prob,
    pred2:class::STRING AS model2_prediction,
    pred2:probability:true::FLOAT AS model2_prob,
    pred3:class::STRING AS model3_prediction,
    pred3:probability:true::FLOAT AS model3_prob,
    (IFF(pred1:class::STRING = 'true', 1, 0) + 
     IFF(pred2:class::STRING = 'true', 1, 0) + 
     IFF(pred3:class::STRING = 'true', 1, 0)) AS votes_for_late,
    CASE 
        WHEN (IFF(pred1:class::STRING = 'true', 1, 0) + 
              IFF(pred2:class::STRING = 'true', 1, 0) + 
              IFF(pred3:class::STRING = 'true', 1, 0)) >= 2 
        THEN 'true' 
        ELSE 'false' 
    END AS ensemble_prediction,
    (pred1:probability:true::FLOAT + pred2:probability:true::FLOAT + pred3:probability:true::FLOAT) / 3 AS ensemble_avg_probability
FROM predictions;

-- ============================================================
-- BACKWARD COMPATIBLE VIEW (same interface as V1)
-- ============================================================

CREATE OR REPLACE VIEW at_risk_receivables AS
SELECT 
    invoice_id,
    client_id,
    client_name,
    invoice_amount,
    past_dso_avg,
    ensemble_prediction AS risk_status,
    ensemble_avg_probability AS risk_probability
FROM at_risk_ensemble;

-- ============================================================
-- VALIDATION: Compare Ensemble vs Individual Models
-- ============================================================

CREATE OR REPLACE VIEW ensemble_validation AS
WITH test_data AS (
    SELECT 
        invoice_amount,
        past_dso_avg,
        is_late,
        CASE 
            WHEN invoice_amount < 5000 THEN 'LOW'
            WHEN invoice_amount < 20000 THEN 'MEDIUM'
            WHEN invoice_amount < 35000 THEN 'HIGH'
            ELSE 'VERY_HIGH'
        END AS amount_bucket,
        CASE 
            WHEN past_dso_avg < 20 THEN 'FAST_PAYER'
            WHEN past_dso_avg < 35 THEN 'AVERAGE_PAYER'
            ELSE 'SLOW_PAYER'
        END AS payer_category,
        CASE WHEN invoice_amount > 25000 AND past_dso_avg > 35 THEN 1 ELSE 0 END AS high_risk_combo,
        LN(1 + invoice_amount) AS log_amount,
        invoice_amount / NULLIF(past_dso_avg, 0) AS amount_per_dso_day,
        POWER(past_dso_avg, 2) / 1000.0 AS dso_squared_scaled,
        (invoice_amount - 15000) / 15000.0 AS amount_normalized
    FROM receivables_history
    SAMPLE (10000 ROWS)
),
predictions AS (
    SELECT 
        is_late,
        at_risk_model_1!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT('INVOICE_AMOUNT', invoice_amount, 'PAST_DSO_AVG', past_dso_avg)
        ):class::STRING AS pred1,
        at_risk_model_2!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT(
                'INVOICE_AMOUNT', invoice_amount, 
                'PAST_DSO_AVG', past_dso_avg,
                'AMOUNT_BUCKET', amount_bucket,
                'PAYER_CATEGORY', payer_category,
                'HIGH_RISK_COMBO', high_risk_combo
            )
        ):class::STRING AS pred2,
        at_risk_model_3!PREDICT(
            INPUT_DATA => OBJECT_CONSTRUCT(
                'LOG_AMOUNT', log_amount, 
                'PAST_DSO_AVG', past_dso_avg,
                'AMOUNT_PER_DSO_DAY', amount_per_dso_day,
                'DSO_SQUARED_SCALED', dso_squared_scaled,
                'AMOUNT_NORMALIZED', amount_normalized
            )
        ):class::STRING AS pred3
    FROM test_data
)
SELECT 
    COUNT(*) AS total_samples,
    SUM(CASE WHEN pred1 = IFF(is_late, 'true', 'false') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS model1_accuracy,
    SUM(CASE WHEN pred2 = IFF(is_late, 'true', 'false') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS model2_accuracy,
    SUM(CASE WHEN pred3 = IFF(is_late, 'true', 'false') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS model3_accuracy,
    SUM(CASE WHEN 
        CASE WHEN (IFF(pred1 = 'true', 1, 0) + IFF(pred2 = 'true', 1, 0) + IFF(pred3 = 'true', 1, 0)) >= 2 
             THEN 'true' ELSE 'false' END = IFF(is_late, 'true', 'false') 
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ensemble_accuracy
FROM predictions;

-- Run validation
SELECT * FROM ensemble_validation;
