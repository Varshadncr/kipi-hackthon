-- ============================================================
-- STEP 4: STREAMLIT DASHBOARD DEPLOYMENT
-- Ensemble Model Dashboard with Comparison View
-- ============================================================

USE DATABASE KIPI_REVCOCO_V2;
USE SCHEMA MVP;

-- Create Stage for Streamlit App
CREATE OR REPLACE STAGE streamlit_stage
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Create Streamlit App
CREATE OR REPLACE STREAMLIT revenue_dashboard_v2
    ROOT_LOCATION = '@streamlit_stage'
    MAIN_FILE = '/revenue_dashboard_ensemble.py'
    QUERY_WAREHOUSE = COMPUTE_WH
    TITLE = 'RevCOCO Revenue Engine V2 - Ensemble'
    COMMENT = 'Order-to-Cash Automation with Ensemble ML Hard Voting';

-- Verify Streamlit App
SHOW STREAMLITS IN SCHEMA MVP;
