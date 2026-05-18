-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Fix: agg_monthly_trend — dedup staging before MERGE
-- Key: yyyymm + scenario_id
-- Database : seplat_edw
-- Date     : 2026-03-13
-- ============================================================

USE seplat_edw;
GO

IF OBJECT_ID('dbo.usp_phishme_security_agg_monthly_trend', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_agg_monthly_trend;
GO
CREATE PROCEDURE dbo.usp_phishme_security_agg_monthly_trend
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
        SELECT 1 FROM zzSTG_phishme_security.agg_monthly_trend
        WHERE yyyymm IS NULL OR scenario_id IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'agg_monthly_trend', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_agg_monthly_trend', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL yyyymm or scenario_id in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE using deduped source (latest ingested_at per yyyymm + scenario_id)
        MERGE phishme_security.agg_monthly_trend AS tgt
        USING (
            SELECT *
            FROM (
                SELECT *,
                    ROW_NUMBER() OVER (
                        PARTITION BY yyyymm, scenario_id
                        ORDER BY ingested_at DESC
                    ) AS rn
                FROM zzSTG_phishme_security.agg_monthly_trend
            ) x
            WHERE rn = 1
        ) AS src
            ON tgt.yyyymm = src.yyyymm AND tgt.scenario_id = src.scenario_id
        WHEN MATCHED THEN
            UPDATE SET
                year                  = src.year,
                month                 = src.month,
                unique_users          = src.unique_users,
                total_events          = src.total_events,
                clicks                = src.clicks,
                reports               = src.reports,
                educations            = src.educations,
                data_entries          = src.data_entries,
                suspicious_events     = src.suspicious_events,
                click_to_report_ratio = src.click_to_report_ratio,
                ingested_date         = src.ingested_date,
                ingested_at           = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (yyyymm,year,month,scenario_id,unique_users,total_events,
                    clicks,reports,educations,data_entries,suspicious_events,
                    click_to_report_ratio,ingested_date,ingested_at)
            VALUES (src.yyyymm,src.year,src.month,src.scenario_id,src.unique_users,
                    src.total_events,src.clicks,src.reports,src.educations,
                    src.data_entries,src.suspicious_events,src.click_to_report_ratio,
                    src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'agg_monthly_trend', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_agg_monthly_trend', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO

PRINT 'Done — agg_monthly_trend proc updated with dedup';
GO
