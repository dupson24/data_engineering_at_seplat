-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Fix: agg_user_risk — dedup staging before MERGE
-- Database : seplat_edw
-- Date     : 2026-03-13
-- ============================================================

USE seplat_edw;
GO

IF OBJECT_ID('dbo.usp_phishme_security_agg_user_risk', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_agg_user_risk;
GO
CREATE PROCEDURE dbo.usp_phishme_security_agg_user_risk
    @load_id         INT,
    @source_path     NVARCHAR(500),
    @pipeline_run_id NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today     DATE     = GETDATE();
    DECLARE @now       DATETIME = GETDATE();
    DECLARE @dq_failed INT      = 0;

    -- STEP 1: Data quality
    IF EXISTS (
        SELECT 1 FROM zzSTG_phishme_security.agg_user_risk
        WHERE email IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'agg_user_risk', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_agg_user_risk', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL email in agg_user_risk staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE using deduped source (latest ingested_at per email)
        MERGE phishme_security.agg_user_risk AS tgt
        USING (
            SELECT *
            FROM (
                SELECT *,
                    ROW_NUMBER() OVER (
                        PARTITION BY email
                        ORDER BY ingested_at DESC
                    ) AS rn
                FROM zzSTG_phishme_security.agg_user_risk
            ) x
            WHERE rn = 1
        ) AS src
            ON tgt.email = src.email
        WHEN MATCHED THEN
            UPDATE SET
                total_scenarios         = src.total_scenarios,
                total_emails_received   = src.total_emails_received,
                total_clicks            = src.total_clicks,
                total_reports           = src.total_reports,
                total_educated          = src.total_educated,
                clicks_not_reported     = src.clicks_not_reported,
                avg_time_to_report_mins = src.avg_time_to_report_mins,
                first_click_at          = src.first_click_at,
                last_click_at           = src.last_click_at,
                click_rate_pct          = src.click_rate_pct,
                report_rate_pct         = src.report_rate_pct,
                education_rate_pct      = src.education_rate_pct,
                user_risk_score         = src.user_risk_score,
                user_risk_label         = src.user_risk_label,
                full_name               = src.full_name,
                department              = src.department,
                location                = src.location,
                job_title               = src.job_title,
                manager                 = src.manager,
                country                 = src.country,
                division                = src.division,
                is_active               = src.is_active,
                is_third_party          = src.is_third_party,
                risk_band               = src.risk_band,
                proficiency_band        = src.proficiency_band,
                proficiency_score       = src.proficiency_score,
                ingested_date           = src.ingested_date,
                ingested_at             = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (email,total_scenarios,total_emails_received,total_clicks,
                    total_reports,total_educated,clicks_not_reported,
                    avg_time_to_report_mins,first_click_at,last_click_at,
                    click_rate_pct,report_rate_pct,education_rate_pct,
                    user_risk_score,user_risk_label,full_name,department,
                    location,job_title,manager,country,division,is_active,
                    is_third_party,risk_band,proficiency_band,proficiency_score,
                    ingested_date,ingested_at)
            VALUES (src.email,src.total_scenarios,src.total_emails_received,
                    src.total_clicks,src.total_reports,src.total_educated,
                    src.clicks_not_reported,src.avg_time_to_report_mins,
                    src.first_click_at,src.last_click_at,src.click_rate_pct,
                    src.report_rate_pct,src.education_rate_pct,src.user_risk_score,
                    src.user_risk_label,src.full_name,src.department,src.location,
                    src.job_title,src.manager,src.country,src.division,src.is_active,
                    src.is_third_party,src.risk_band,src.proficiency_band,
                    src.proficiency_score,src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'agg_user_risk', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_agg_user_risk', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO

PRINT 'Done — agg_user_risk proc updated with dedup';
GO
