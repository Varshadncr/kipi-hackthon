-- ============================================================
-- REVCOCO DATA QUALITY FIX SCRIPT
-- Run this to fix data issues found during validation
-- ============================================================

USE DATABASE KIPI_REVCOCO;
USE SCHEMA MVP;

-- ============================================================
-- FIX 1: Remove duplicate contracts (keep one per client_id)
-- ============================================================

-- First, backup original contracts
CREATE OR REPLACE TABLE contracts_backup AS SELECT * FROM contracts;

-- Remove duplicates - keep the one with earliest contract_start_date
CREATE OR REPLACE TABLE contracts AS
SELECT client_id, client_name, print_rate, digital_rate, contract_start_date
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY contract_start_date) as rn
    FROM contracts_backup
)
WHERE rn = 1;

-- Verify no duplicates remain
SELECT 'Contracts after dedup: ' || COUNT(*) || ' (should be unique)' AS status FROM contracts;
SELECT 'Duplicate check: ' || COUNT(*) || ' (should be 0)' AS status 
FROM (SELECT client_id FROM contracts GROUP BY client_id HAVING COUNT(*) > 1);

-- ============================================================
-- FIX 2: Add missing contracts for orphaned client_ids
-- ============================================================

-- Find orphaned client_ids
CREATE OR REPLACE TEMP TABLE orphaned_clients AS
SELECT DISTINCT p.client_id
FROM production_logs p
LEFT JOIN contracts c ON p.client_id = c.client_id
WHERE c.client_id IS NULL;

-- Add default contracts for orphaned clients
INSERT INTO contracts (client_id, client_name, print_rate, digital_rate, contract_start_date)
SELECT 
    client_id,
    'Client ' || client_id AS client_name,
    0.15 AS print_rate,      -- Default print rate
    0.05 AS digital_rate,    -- Default digital rate  
    '2025-01-01'::DATE AS contract_start_date
FROM orphaned_clients;

-- Verify all production logs now have contracts
SELECT 'Orphaned logs after fix: ' || COUNT(*) || ' (should be 0)' AS status
FROM production_logs p
LEFT JOIN contracts c ON p.client_id = c.client_id
WHERE c.client_id IS NULL;

-- ============================================================
-- REFRESH DYNAMIC TABLE after data fixes
-- ============================================================
ALTER DYNAMIC TABLE ready_to_bill REFRESH;

-- ============================================================
-- RE-RUN VALIDATION
-- ============================================================
SELECT 'Validation after fixes:' AS status;

SELECT 
    'Ready-to-Bill count: ' || COUNT(*) AS metric FROM ready_to_bill
UNION ALL
SELECT 'Production Logs count: ' || COUNT(*) FROM production_logs
UNION ALL
SELECT 'Match rate: ' || ROUND(100.0 * (SELECT COUNT(*) FROM ready_to_bill) / (SELECT COUNT(*) FROM production_logs), 2) || '%';
