-- ============================================================
-- STEP 4: STREAMLIT DASHBOARD DEPLOYMENT
-- Real-time Order-to-Cash & AR Risk Dashboard
-- ============================================================

USE DATABASE KIPI_REVCOCO;
USE SCHEMA MVP;

-- Create Stage for Streamlit App
CREATE OR REPLACE STAGE streamlit_stage
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Create Streamlit App
-- NOTE: After running this, upload revenue_dashboard.py to the stage
CREATE OR REPLACE STREAMLIT revenue_dashboard
    ROOT_LOCATION = '@streamlit_stage'
    MAIN_FILE = '/revenue_dashboard.py'
    QUERY_WAREHOUSE = COMPUTE_WH
    TITLE = 'RevCOCO Revenue Engine'
    COMMENT = 'Order-to-Cash Automation & AR Risk Intelligence Dashboard';

-- Grant access (if needed for other roles)
-- GRANT USAGE ON STREAMLIT revenue_dashboard TO ROLE <role_name>;

-- Verify Streamlit App
SHOW STREAMLITS IN SCHEMA MVP;

-- To upload the Python file via SQL (if using SnowSQL):
-- PUT file://streamlit/revenue_dashboard.py @streamlit_stage AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
