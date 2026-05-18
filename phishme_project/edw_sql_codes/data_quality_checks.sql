-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Data Quality & Duplicate Check — All 10 Target Tables
-- Database : seplat_edw
-- ============================================================

-- ============================================================
-- 1. dim_date (key: date_key)
-- ============================================================
SELECT 'dim_date' AS table_name, 'row_count' AS check_type, COUNT(*) AS result
FROM phishme_security.dim_date
UNION ALL
SELECT 'dim_date', 'duplicates', COUNT(*) FROM (
    SELECT date_key, COUNT(*) AS cnt FROM phishme_security.dim_date
    GROUP BY date_key HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'dim_date', 'null_key', COUNT(*) FROM phishme_security.dim_date
WHERE date_key IS NULL

UNION ALL

-- ============================================================
-- 2. dim_user (key: email)
-- ============================================================
SELECT 'dim_user', 'row_count', COUNT(*) FROM phishme_security.dim_user
UNION ALL
SELECT 'dim_user', 'duplicates', COUNT(*) FROM (
    SELECT email, COUNT(*) AS cnt FROM phishme_security.dim_user
    GROUP BY email HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'dim_user', 'null_key', COUNT(*) FROM phishme_security.dim_user
WHERE email IS NULL

UNION ALL

-- ============================================================
-- 3. dim_scenario (key: scenario_id)
-- ============================================================
SELECT 'dim_scenario', 'row_count', COUNT(*) FROM phishme_security.dim_scenario
UNION ALL
SELECT 'dim_scenario', 'duplicates', COUNT(*) FROM (
    SELECT scenario_id, COUNT(*) AS cnt FROM phishme_security.dim_scenario
    GROUP BY scenario_id HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'dim_scenario', 'null_key', COUNT(*) FROM phishme_security.dim_scenario
WHERE scenario_id IS NULL

UNION ALL

-- ============================================================
-- 4. fact_phishing_responses (key: email + scenario_id)
-- ============================================================
SELECT 'fact_phishing_responses', 'row_count', COUNT(*) FROM phishme_security.fact_phishing_responses
UNION ALL
SELECT 'fact_phishing_responses', 'duplicates', COUNT(*) FROM (
    SELECT email, scenario_id, COUNT(*) AS cnt FROM phishme_security.fact_phishing_responses
    GROUP BY email, scenario_id HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'fact_phishing_responses', 'null_key', COUNT(*) FROM phishme_security.fact_phishing_responses
WHERE email IS NULL OR scenario_id IS NULL

UNION ALL

-- ============================================================
-- 5. fact_activity_timeline (key: tracking_id)
-- ============================================================
SELECT 'fact_activity_timeline', 'row_count', COUNT(*) FROM phishme_security.fact_activity_timeline
UNION ALL
SELECT 'fact_activity_timeline', 'duplicates', COUNT(*) FROM (
    SELECT tracking_id, COUNT(*) AS cnt FROM phishme_security.fact_activity_timeline
    GROUP BY tracking_id HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'fact_activity_timeline', 'null_key', COUNT(*) FROM phishme_security.fact_activity_timeline
WHERE tracking_id IS NULL OR email IS NULL OR event_timestamp IS NULL

UNION ALL

-- ============================================================
-- 6. fact_activity_logs (key: user + event_timestamp + activity_name)
-- ============================================================
SELECT 'fact_activity_logs', 'row_count', COUNT(*) FROM phishme_security.fact_activity_logs
UNION ALL
SELECT 'fact_activity_logs', 'duplicates', COUNT(*) FROM (
    SELECT [user], event_timestamp, activity_name, COUNT(*) AS cnt
    FROM phishme_security.fact_activity_logs
    GROUP BY [user], event_timestamp, activity_name HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'fact_activity_logs', 'null_key', COUNT(*) FROM phishme_security.fact_activity_logs
WHERE [user] IS NULL OR event_timestamp IS NULL

UNION ALL

-- ============================================================
-- 7. agg_user_risk (key: email)
-- ============================================================
SELECT 'agg_user_risk', 'row_count', COUNT(*) FROM phishme_security.agg_user_risk
UNION ALL
SELECT 'agg_user_risk', 'duplicates', COUNT(*) FROM (
    SELECT email, COUNT(*) AS cnt FROM phishme_security.agg_user_risk
    GROUP BY email HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'agg_user_risk', 'null_key', COUNT(*) FROM phishme_security.agg_user_risk
WHERE email IS NULL

UNION ALL

-- ============================================================
-- 8. agg_scenario_performance (key: scenario_id)
-- ============================================================
SELECT 'agg_scenario_performance', 'row_count', COUNT(*) FROM phishme_security.agg_scenario_performance
UNION ALL
SELECT 'agg_scenario_performance', 'duplicates', COUNT(*) FROM (
    SELECT scenario_id, COUNT(*) AS cnt FROM phishme_security.agg_scenario_performance
    GROUP BY scenario_id HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'agg_scenario_performance', 'null_key', COUNT(*) FROM phishme_security.agg_scenario_performance
WHERE scenario_id IS NULL

UNION ALL

-- ============================================================
-- 9. agg_department_risk (key: department)
-- ============================================================
SELECT 'agg_department_risk', 'row_count', COUNT(*) FROM phishme_security.agg_department_risk
UNION ALL
SELECT 'agg_department_risk', 'duplicates', COUNT(*) FROM (
    SELECT department, COUNT(*) AS cnt FROM phishme_security.agg_department_risk
    GROUP BY department HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'agg_department_risk', 'null_key', COUNT(*) FROM phishme_security.agg_department_risk
WHERE department IS NULL

UNION ALL

-- ============================================================
-- 10. agg_monthly_trend (key: yyyymm + scenario_id)
-- ============================================================
SELECT 'agg_monthly_trend', 'row_count', COUNT(*) FROM phishme_security.agg_monthly_trend
UNION ALL
SELECT 'agg_monthly_trend', 'duplicates', COUNT(*) FROM (
    SELECT yyyymm, scenario_id, COUNT(*) AS cnt FROM phishme_security.agg_monthly_trend
    GROUP BY yyyymm, scenario_id HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'agg_monthly_trend', 'null_key', COUNT(*) FROM phishme_security.agg_monthly_trend
WHERE yyyymm IS NULL OR scenario_id IS NULL

ORDER BY table_name, check_type;