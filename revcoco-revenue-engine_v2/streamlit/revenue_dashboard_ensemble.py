import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="RevCOCO Revenue Engine V2", page_icon="📊", layout="wide")

session = get_active_session()

st.title("📊 RevCOCO Revenue Engine V2")
st.subheader("Ensemble ML with Hard Voting")

tab1, tab2, tab3, tab4 = st.tabs(["📈 Dashboard", "🤖 Ensemble Analysis", "📊 Model Comparison", "🔍 Predictions"])

with tab1:
    col1, col2, col3, col4 = st.columns(4)
    
    total_billable = session.sql("SELECT SUM(billable_amount) FROM ready_to_bill").collect()[0][0]
    total_records = session.sql("SELECT COUNT(*) FROM ready_to_bill").collect()[0][0]
    
    with col1:
        st.metric("💰 Total Billable", f"${total_billable:,.2f}" if total_billable else "$0")
    with col2:
        st.metric("📋 Ready to Bill", f"{total_records:,}" if total_records else "0")
    
    try:
        at_risk_data = session.sql("""
            SELECT COUNT(*) as cnt, SUM(invoice_amount) as amt 
            FROM at_risk_receivables WHERE risk_status = 'true'
        """).collect()[0]
        with col3:
            st.metric("⚠️ At-Risk Invoices", f"{at_risk_data[0]:,}")
        with col4:
            st.metric("💸 At-Risk Amount", f"${at_risk_data[1]:,.2f}" if at_risk_data[1] else "$0")
    except:
        with col3:
            st.metric("⚠️ At-Risk Invoices", "N/A")
        with col4:
            st.metric("💸 At-Risk Amount", "N/A")
    
    st.subheader("Ready-to-Bill Summary")
    billing_df = session.sql("""
        SELECT client_name, event_type, quantity, billable_amount, billing_status
        FROM ready_to_bill ORDER BY billable_amount DESC
    """).to_pandas()
    st.dataframe(billing_df, use_container_width=True)

with tab2:
    st.subheader("🗳️ Ensemble Hard Voting Analysis")
    
    st.markdown("""
    **How Hard Voting Works:**
    - 3 models vote independently on each invoice
    - Majority wins (2+ votes = at-risk)
    - Reduces individual model bias
    """)
    
    try:
        ensemble_df = session.sql("""
            SELECT 
                client_name,
                invoice_amount,
                past_dso_avg,
                model1_prediction AS "Model 1",
                model2_prediction AS "Model 2", 
                model3_prediction AS "Model 3",
                votes_for_late AS "Votes for Late",
                ensemble_prediction AS "Final Prediction",
                ROUND(ensemble_avg_probability * 100, 1) AS "Risk %"
            FROM at_risk_ensemble
            ORDER BY ensemble_avg_probability DESC
        """).to_pandas()
        
        st.dataframe(ensemble_df, use_container_width=True)
        
        col1, col2 = st.columns(2)
        with col1:
            st.subheader("Vote Distribution")
            vote_dist = session.sql("""
                SELECT votes_for_late, COUNT(*) as count
                FROM at_risk_ensemble GROUP BY votes_for_late ORDER BY votes_for_late
            """).to_pandas()
            st.bar_chart(vote_dist.set_index('VOTES_FOR_LATE'))
        
        with col2:
            st.subheader("Model Agreement")
            agreement = session.sql("""
                SELECT 
                    CASE WHEN model1_prediction = model2_prediction 
                              AND model2_prediction = model3_prediction 
                         THEN 'All Agree' ELSE 'Disagreement' END as status,
                    COUNT(*) as count
                FROM at_risk_ensemble GROUP BY 1
            """).to_pandas()
            st.bar_chart(agreement.set_index('STATUS'))
    except Exception as e:
        st.warning(f"Ensemble data not available: {e}")

with tab3:
    st.subheader("📊 Model Accuracy Comparison")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("### V1 (Single Model)")
        try:
            v1_metrics = session.sql("""
                CALL KIPI_REVCOCO.MVP.at_risk_receivable_model!SHOW_EVALUATION_METRICS()
            """).to_pandas()
            
            v1_confusion = session.sql("""
                CALL KIPI_REVCOCO.MVP.at_risk_receivable_model!SHOW_CONFUSION_MATRIX()
            """).to_pandas()
            
            tp = v1_confusion[v1_confusion['ACTUAL_CLASS'] == 'true'][v1_confusion['PREDICTED_CLASS'] == 'true']['COUNT'].values
            tn = v1_confusion[v1_confusion['ACTUAL_CLASS'] == 'false'][v1_confusion['PREDICTED_CLASS'] == 'false']['COUNT'].values
            total = v1_confusion['COUNT'].sum()
            
            tp_val = tp[0] if len(tp) > 0 else 0
            tn_val = tn[0] if len(tn) > 0 else 0
            v1_accuracy = (tp_val + tn_val) / total * 100
            
            st.metric("Accuracy", f"{v1_accuracy:.2f}%")
            st.dataframe(v1_metrics[['CLASS', 'ERROR_METRIC', 'METRIC_VALUE']], use_container_width=True)
        except Exception as e:
            st.warning(f"V1 metrics unavailable: {e}")
    
    with col2:
        st.markdown("### V2 (Ensemble - Hard Voting)")
        try:
            validation = session.sql("SELECT * FROM ensemble_validation").to_pandas()
            
            st.metric("Model 1 Accuracy", f"{validation['MODEL1_ACCURACY'].values[0]:.2f}%")
            st.metric("Model 2 Accuracy", f"{validation['MODEL2_ACCURACY'].values[0]:.2f}%")
            st.metric("Model 3 Accuracy", f"{validation['MODEL3_ACCURACY'].values[0]:.2f}%")
            st.metric("🏆 Ensemble Accuracy", f"{validation['ENSEMBLE_ACCURACY'].values[0]:.2f}%", 
                     delta=f"+{validation['ENSEMBLE_ACCURACY'].values[0] - v1_accuracy:.2f}%" if 'v1_accuracy' in dir() else None)
        except Exception as e:
            st.warning(f"V2 metrics unavailable: {e}")
    
    st.markdown("---")
    st.subheader("Individual Model Metrics (V2)")
    
    model_tabs = st.tabs(["Model 1 (Base)", "Model 2 (Categorical)", "Model 3 (Transforms)"])
    
    models = ['at_risk_model_1', 'at_risk_model_2', 'at_risk_model_3']
    for i, mtab in enumerate(model_tabs):
        with mtab:
            try:
                metrics = session.sql(f"CALL {models[i]}!SHOW_EVALUATION_METRICS()").to_pandas()
                st.dataframe(metrics, use_container_width=True)
            except Exception as e:
                st.warning(f"Metrics unavailable: {e}")

with tab4:
    st.subheader("🔍 Detailed Predictions")
    
    try:
        predictions_df = session.sql("""
            SELECT 
                invoice_id,
                client_name,
                invoice_amount,
                past_dso_avg,
                model1_prediction,
                ROUND(model1_prob * 100, 1) AS model1_pct,
                model2_prediction,
                ROUND(model2_prob * 100, 1) AS model2_pct,
                model3_prediction,
                ROUND(model3_prob * 100, 1) AS model3_pct,
                ensemble_prediction,
                ROUND(ensemble_avg_probability * 100, 1) AS ensemble_pct
            FROM at_risk_ensemble
            ORDER BY ensemble_avg_probability DESC
        """).to_pandas()
        
        st.dataframe(predictions_df, use_container_width=True)
    except Exception as e:
        st.warning(f"Predictions unavailable: {e}")

st.sidebar.markdown("---")
st.sidebar.markdown("### About V2")
st.sidebar.markdown("""
**Ensemble Methods:**
- Model 1: Base features
- Model 2: Categorical buckets
- Model 3: Math transforms

**Hard Voting:** 2+ votes = at-risk
""")

if st.sidebar.button("🔄 Refresh Data"):
    st.rerun()
