-- ============================================================
-- STEP 2: AUTOMATED ORDER-TO-CASH (DYNAMIC TABLES)
-- Auto-reconciles production logs with contract pricing
-- ============================================================

USE DATABASE KIPI_REVCOCO;
USE SCHEMA MVP;

-- Create Ready-to-Bill Dynamic Table
-- Pairs every production event with client rates automatically
CREATE OR REPLACE DYNAMIC TABLE ready_to_bill
    TARGET_LAG = '1 minute'
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
    p.event_id,
    p.client_id,
    c.client_name,
    p.event_type,
    p.quantity,
    p.event_timestamp,
    CASE 
        WHEN p.event_type = 'PRINT' THEN c.print_rate
        WHEN p.event_type = 'DIGITAL' THEN c.digital_rate
    END AS unit_rate,
    CASE 
        WHEN p.event_type = 'PRINT' THEN p.quantity * c.print_rate
        WHEN p.event_type = 'DIGITAL' THEN p.quantity * c.digital_rate
    END AS billable_amount,
    'READY_TO_BILL' AS billing_status,
    CURRENT_TIMESTAMP() AS processed_at
FROM production_logs p
JOIN contracts c ON p.client_id = c.client_id;

-- Verify Dynamic Table
SELECT client_name, event_type, quantity, unit_rate, billable_amount, billing_status
FROM ready_to_bill
ORDER BY event_timestamp DESC
LIMIT 10;

-- Check Dynamic Table status
SHOW DYNAMIC TABLES LIKE 'ready_to_bill';
