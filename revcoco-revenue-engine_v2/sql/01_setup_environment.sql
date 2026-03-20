-- ============================================================
-- STEP 1: SETUP ENVIRONMENT FOR ENSEMBLE MODEL
-- RevCOCO Native Revenue Engine V2 - Ensemble Methods
-- ============================================================

-- 1. Create Database and Schema (separate from V1)
CREATE DATABASE IF NOT EXISTS KIPI_REVCOCO_V2;
USE DATABASE KIPI_REVCOCO_V2;
CREATE SCHEMA IF NOT EXISTS MVP;
USE SCHEMA MVP;

-- 2. Create Contracts Table (The Pricing Source of Truth)
CREATE OR REPLACE TABLE contracts (
    client_id VARCHAR,
    client_name VARCHAR,
    print_rate FLOAT,
    digital_rate FLOAT,
    contract_start_date DATE
);

INSERT INTO contracts VALUES 
    ('C001', 'Acme Corp', 0.15, 0.05, '2025-01-01'),
    ('C002', 'Global Tech', 0.12, 0.04, '2025-02-01'),
    ('C003', 'Local Bank', 0.18, 0.06, '2024-06-01');

-- 3. Create Production Logs (The Disconnected Events)
CREATE OR REPLACE TABLE production_logs (
    event_id VARCHAR DEFAULT UUID_STRING(),
    client_id VARCHAR,
    event_type VARCHAR,
    quantity INT,
    event_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO production_logs (client_id, event_type, quantity, event_timestamp) VALUES 
    ('C001', 'PRINT', 10000, DATEADD(day, -2, CURRENT_TIMESTAMP())),
    ('C001', 'DIGITAL', 50000, DATEADD(day, -1, CURRENT_TIMESTAMP())),
    ('C002', 'PRINT', 5000, CURRENT_TIMESTAMP()),
    ('C003', 'DIGITAL', 100000, CURRENT_TIMESTAMP());

-- 4. Create Historical Receivables with EXTENDED FEATURES for Ensemble
CREATE OR REPLACE TABLE receivables_history (
    invoice_id VARCHAR,
    client_id VARCHAR,
    invoice_amount FLOAT,
    days_to_pay INT,
    past_dso_avg INT,
    is_late BOOLEAN
);

-- Copy training data from V1 for fair comparison
INSERT INTO receivables_history
SELECT * FROM KIPI_REVCOCO.MVP.receivables_history;

-- Verify setup
SELECT 'contracts' as table_name, COUNT(*) as row_count FROM contracts
UNION ALL SELECT 'production_logs', COUNT(*) FROM production_logs
UNION ALL SELECT 'receivables_history', COUNT(*) FROM receivables_history;
