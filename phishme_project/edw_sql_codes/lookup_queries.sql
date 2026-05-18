-- ============================================================
-- ADF LOOKUP SCRIPTS — PhishMe Security CDC
-- Database : seplat_edw
-- Schema   : phishme_security
-- Usage    : Paste each query into the corresponding
--            ADF Lookup activity → sqlReaderQuery
-- ============================================================


-- ============================================================
-- 1. LKP_GetWatermark
-- ============================================================
-- LKP_GetWatermark  — ADF Lookup Activity (firstRowOnly = false)
-- Table: phishme_security.watermark
-- ============================================================
SELECT
    table_name,
    schema_name,
    last_load_date,
    last_load_timestamp,
    last_load_status,
    source_path,
    pipeline_name,
    pipeline_run_id,
    rows_extracted,
    rows_loaded,
    rows_rejected
FROM phishme_security.watermark
ORDER BY table_name;

-- ============================================================
-- 2. LKP_CheckStagingRowCount
--    Used by: Validation before stored proc — ensure staging
--             was populated after ADLS copy
--    ADF Activity Type: Lookup (firstRowOnly = false)
--    Bind: @item().table_name from ForEach
-- ============================================================
SELECT
    table_name,
    row_count
FROM (
    VALUES
        ('dim_date',                (SELECT COUNT(1) FROM zzSTG_phishme_security.dim_date)),
        ('dim_user',                (SELECT COUNT(1) FROM zzSTG_phishme_security.dim_user)),
        ('dim_scenario',            (SELECT COUNT(1) FROM zzSTG_phishme_security.dim_scenario)),
        ('fact_phishing_responses', (SELECT COUNT(1) FROM zzSTG_phishme_security.fact_phishing_responses)),
        ('fact_activity_timeline',  (SELECT COUNT(1) FROM zzSTG_phishme_security.fact_activity_timeline)),
        ('fact_activity_logs',      (SELECT COUNT(1) FROM zzSTG_phishme_security.fact_activity_logs)),
        ('agg_user_risk',           (SELECT COUNT(1) FROM zzSTG_phishme_security.agg_user_risk)),
        ('agg_scenario_performance',(SELECT COUNT(1) FROM zzSTG_phishme_security.agg_scenario_performance)),
        ('agg_department_risk',     (SELECT COUNT(1) FROM zzSTG_phishme_security.agg_department_risk)),
        ('agg_monthly_trend',       (SELECT COUNT(1) FROM zzSTG_phishme_security.agg_monthly_trend))
) AS staging_counts (table_name, row_count);


-- ============================================================
-- 3. LKP_GetLastSuccessfulLoad
--    Used by: Incremental/delta detection — returns last good
--             load date per table for downstream filtering
--    ADF Activity Type: Lookup (firstRowOnly = false)
-- ============================================================
SELECT
    w.table_name,
    w.last_load_date,
    w.last_load_datetime,
    ISNULL(w.last_load_date, '1900-01-01') AS watermark_from,
    CAST(GETDATE() AS DATE)                AS watermark_to
FROM phishme_security.watermark w
WHERE w.is_active       = 1
  AND w.last_load_status IN ('SUCCESS', 'INIT')
ORDER BY w.table_name;


-- ============================================================
-- 4. LKP_GetFailedTables
--    Used by: Alert / retry pipeline — identify tables that
--             failed in the last run
--    ADF Activity Type: Lookup (firstRowOnly = false)
-- ============================================================
SELECT
    table_name,
    last_load_date,
    last_load_status,
    last_pipeline_run_id,
    error_message,
    error_code,
    updated_at
FROM phishme_security.watermark
WHERE is_active       = 1
  AND last_load_status = 'FAILED'
ORDER BY updated_at DESC;


-- ============================================================
-- 5. LKP_GetSingleTableWatermark
--    Used by: Individual table pipeline runs
--    ADF Activity Type: Lookup (firstRowOnly = true)
--    Replace @{pipeline().parameters.table_name} with ADF param
-- ============================================================
SELECT TOP 1
    table_name,
    schema_name,
    last_load_date,
    last_load_datetime,
    last_load_status,
    last_pipeline_run_id,
    last_source_path
FROM phishme_security.watermark
WHERE table_name = '@{pipeline().parameters.table_name}'
  AND is_active  = 1;


-- ============================================================
-- 6. LKP_GetCDCSummary  (post-load audit)
--    Used by: End-of-pipeline summary notification
--    ADF Activity Type: Lookup (firstRowOnly = false)
--    Run AFTER ForEach completes
-- ============================================================
SELECT
    table_name,
    last_load_date,
    last_load_status,
    last_proc_name,
    last_pipeline_run_id,
    error_message,
    error_code,
    updated_at,
    CASE last_load_status
        WHEN 'SUCCESS' THEN 1
        WHEN 'FAILED'  THEN 0
        ELSE NULL
    END AS is_success
FROM phishme_security.watermark
WHERE is_active          = 1
  AND last_pipeline_run_id = '@{pipeline().RunId}'
ORDER BY table_name;