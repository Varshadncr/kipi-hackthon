import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="RevCOCO Revenue Engine", layout="wide")
session = get_active_session()

st.title("🚀 RevCOCO Native Revenue Engine")
st.markdown("**Real-time Order-to-Cash Automation & AR Risk Intelligence**")

col1, col2, col3, col4 = st.columns(4)

rtb_df = session.sql("""
    SELECT COUNT(*) as cnt, SUM(billable_amount) as total 
    FROM KIPI_REVCOCO.MVP.ready_to_bill
""").to_pandas()
col1.metric("📋 Ready-to-Bill Records", f"{int(rtb_df['CNT'][0]):,}")
col2.metric("💰 Total Billable Amount", f"${rtb_df['TOTAL'][0]:,.2f}")

risk_df = session.sql("""
    SELECT COUNT(*) as cnt, COALESCE(SUM(invoice_amount), 0) as total 
    FROM KIPI_REVCOCO.MVP.at_risk_receivables 
    WHERE risk_status = 'True'
""").to_pandas()
col3.metric("⚠️ At-Risk Invoices", f"{int(risk_df['CNT'][0]):,}", delta="Needs Attention", delta_color="inverse")
col4.metric("🔴 At-Risk Amount", f"${risk_df['TOTAL'][0]:,.2f}")

st.divider()

tab1, tab2, tab3 = st.tabs(["📊 Ready-to-Bill", "⚠️ At-Risk Receivables", "📈 Analytics"])

with tab1:
    st.subheader("Ready-to-Bill Records (Auto-Reconciled)")
    rtb_data = session.sql("""
        SELECT client_name, event_type, quantity, unit_rate, billable_amount, event_timestamp
        FROM KIPI_REVCOCO.MVP.ready_to_bill
        ORDER BY event_timestamp DESC
        LIMIT 100
    """).to_pandas()
    st.dataframe(rtb_data, use_container_width=True, height=400)

with tab2:
    st.subheader("At-Risk Receivables (ML Predictions)")
    at_risk_data = session.sql("""
        SELECT client_name, invoice_amount, past_dso_avg, risk_status,
               ROUND(risk_probability * 100, 1) as risk_pct
        FROM KIPI_REVCOCO.MVP.at_risk_receivables
        ORDER BY risk_probability DESC
        LIMIT 100
    """).to_pandas()
    
    def highlight_risk(row):
        if row['RISK_STATUS'] == 'True':
            return ['background-color: #ffcccc'] * len(row)
        return [''] * len(row)
    
    st.dataframe(at_risk_data.style.apply(highlight_risk, axis=1), use_container_width=True, height=400)

with tab3:
    col_a, col_b = st.columns(2)
    
    with col_a:
        st.subheader("Revenue by Client")
        chart_data = session.sql("""
            SELECT client_name, SUM(billable_amount) as revenue
            FROM KIPI_REVCOCO.MVP.ready_to_bill
            GROUP BY client_name
            ORDER BY revenue DESC
            LIMIT 10
        """).to_pandas()
        st.bar_chart(chart_data.set_index('CLIENT_NAME'))
    
    with col_b:
        st.subheader("Revenue by Event Type")
        type_data = session.sql("""
            SELECT event_type, SUM(billable_amount) as revenue
            FROM KIPI_REVCOCO.MVP.ready_to_bill
            GROUP BY event_type
        """).to_pandas()
        st.bar_chart(type_data.set_index('EVENT_TYPE'))

st.divider()
st.caption("Powered by Snowflake Dynamic Tables & Cortex ML | Real-time data refresh every 1 minute")
