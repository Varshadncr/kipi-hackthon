-- ============================================================
-- REVCOCO REVENUE ENGINE - VALIDATION TEST SUITE
-- Run these tests to verify the engine is working correctly
-- ============================================================

USE DATABASE KIPI_REVCOCO;
USE SCHEMA MVP;

-- ============================================================
-- TEST 1: DATA INTEGRITY - Check for duplicate contracts
-- Expected: No duplicates (0 rows)
-- ============================================================
SELECT 'TEST 1: Duplicate Contracts' AS test_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' duplicates found' END AS result
FROM (
    SELECT client_id, COUNT(*) as cnt 
    FROM contracts 
    GROUP BY client_id 
    HAVING COUNT(*) > 1
);

-- ============================================================
-- TEST 2: RECONCILIATION - All production logs have matching contracts
-- Expected: 0 unmatched records
-- ============================================================
SELECT 'TEST 2: Unmatched Production Logs' AS test_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' logs without contracts' END AS result
FROM production_logs p
LEFT JOIN contracts c ON p.client_id = c.client_id
WHERE c.client_id IS NULL;

-- ============================================================
-- TEST 3: BILLABLE CALCULATION - Verify math is correct
-- Expected: All calculations match
-- ============================================================
SELECT 'TEST 3: Billable Amount Calculation' AS test_name,
       CASE 
           WHEN SUM(CASE WHEN is_correct = FALSE THEN 1 ELSE 0 END) = 0 THEN 'PASS'
           ELSE 'FAIL - ' || SUM(CASE WHEN is_correct = FALSE THEN 1 ELSE 0 END) || ' incorrect calculations'
       END AS result
FROM (
    SELECT 
        r.billable_amount,
        r.quantity * r.unit_rate AS expected,
        ABS(r.billable_amount - (r.quantity * r.unit_rate)) < 0.01 AS is_correct
    FROM ready_to_bill r
);

-- ============================================================
-- TEST 4: RATE MATCHING - Correct rate applied per event type
-- Sample validation (spot check 100 records)
-- ============================================================
SELECT 'TEST 4: Rate Matching (Sample)' AS test_name,
       CASE 
           WHEN wrong_rates = 0 THEN 'PASS'
           ELSE 'FAIL - ' || wrong_rates || ' records with wrong rates'
       END AS result
FROM (
    SELECT COUNT(*) AS wrong_rates
    FROM (
        SELECT r.*, c.print_rate, c.digital_rate
        FROM ready_to_bill r
        JOIN (SELECT client_id, MIN(print_rate) as print_rate, MIN(digital_rate) as digital_rate 
              FROM contracts GROUP BY client_id) c 
        ON r.client_id = c.client_id
        WHERE (r.event_type = 'PRINT' AND r.unit_rate != c.print_rate)
           OR (r.event_type = 'DIGITAL' AND r.unit_rate != c.digital_rate)
        LIMIT 100
    )
);

-- ============================================================
-- TEST 5: ML MODEL - Predictions are being generated
-- Expected: All records have predictions
-- ============================================================
SELECT 'TEST 5: ML Predictions Generated' AS test_name,
       CASE 
           WHEN null_predictions = 0 THEN 'PASS'
           ELSE 'FAIL - ' || null_predictions || ' records missing predictions'
       END AS result
FROM (
    SELECT COUNT(*) AS null_predictions
    FROM at_risk_receivables
    WHERE risk_status IS NULL
);

-- ============================================================
-- TEST 6: ML MODEL - Risk scores are valid (0-1 range)
-- Expected: All probabilities between 0 and 1
-- ============================================================
SELECT 'TEST 6: Risk Score Validity' AS test_name,
       CASE 
           WHEN invalid_scores = 0 THEN 'PASS'
           ELSE 'FAIL - ' || invalid_scores || ' invalid risk scores'
       END AS result
FROM (
    SELECT COUNT(*) AS invalid_scores
    FROM at_risk_receivables
    WHERE risk_probability < 0 OR risk_probability > 1 OR risk_probability IS NULL
);

-- ============================================================
-- TEST 7: DYNAMIC TABLE FRESHNESS - Check last refresh
-- Expected: Refreshed within last 5 minutes
-- ============================================================
SELECT 'TEST 7: Dynamic Table Freshness' AS test_name,
       CASE 
           WHEN TIMESTAMPDIFF('minute', refresh_action_start_time, CURRENT_TIMESTAMP()) <= 5 THEN 'PASS'
           ELSE 'WARNING - Last refresh was ' || TIMESTAMPDIFF('minute', refresh_action_start_time, CURRENT_TIMESTAMP()) || ' minutes ago'
       END AS result
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(NAME => 'KIPI_REVCOCO.MVP.READY_TO_BILL'))
ORDER BY refresh_action_start_time DESC
LIMIT 1;

-- ============================================================
-- TEST 8: RECORD COUNTS - Sanity check
-- ============================================================
SELECT 'TEST 8: Record Counts' AS test_name,
       'INFO - ' || 
       'Contracts: ' || (SELECT COUNT(*) FROM contracts) || ', ' ||
       'Production Logs: ' || (SELECT COUNT(*) FROM production_logs) || ', ' ||
       'Ready-to-Bill: ' || (SELECT COUNT(*) FROM ready_to_bill) || ', ' ||
       'At-Risk: ' || (SELECT COUNT(*) FROM at_risk_receivables) AS result;

-- ============================================================
-- SUMMARY: Run all tests and get overall status
-- ============================================================
SELECT '========================================' AS test_summary UNION ALL
SELECT 'VALIDATION COMPLETE - Review results above' UNION ALL
SELECT '========================================';
