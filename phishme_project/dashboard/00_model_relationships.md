# ============================================================
# SEPLAT ENERGY — PhishMe Security Analytics
# Power BI DAX Measures, KPIs & Report Page Specifications
# ============================================================
# Data Source  : Delta tables at /mnt/PhishMe/gold/
# Refreshed    : Daily 02:30 UTC (after gold layer build)
# Audience     : IT Security Analysts, CISO, Department Heads
# ============================================================

# ============================================================
# TABLE RELATIONSHIPS (set in Power BI Model View)
# ============================================================
# fact_phishing_responses[email]       → dim_user[email]           (Many:1)
# fact_phishing_responses[scenario_id] → dim_scenario[scenario_id] (Many:1)
# fact_phishing_responses[ingested_date] → dim_date[date_key]      (Many:1)
# fact_activity_timeline[email]        → dim_user[email]           (Many:1)
# fact_activity_timeline[scenario_id]  → dim_scenario[scenario_id] (Many:1)
# fact_activity_timeline[event_date]   → dim_date[date_key]        (Many:1)
# agg_user_risk[email]                 → dim_user[email]           (1:1)
# agg_scenario_performance[scenario_id]→ dim_scenario[scenario_id] (1:1)
# agg_department_risk[department]      → dim_user[department]      (Many:1)
# agg_monthly_trend[scenario_id]       → dim_scenario[scenario_id] (Many:1)
