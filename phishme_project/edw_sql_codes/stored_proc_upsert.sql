-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Azure Synapse Analytics — Upsert Stored Procedures (ALL 10)
-- Schema   : dbo (procedures)
-- Pattern  : MERGE staging → target (upsert, no CDC tagging)
--            fact_activity_logs : INSERT only (append)
-- Author   : Data Engineering
-- Date     : 2026-03-13
-- ============================================================

USE seplat_edw;
GO


-- ============================================================
-- 1. usp_phishme_security_dim_date
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_dim_date', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_dim_date;
GO
CREATE PROCEDURE dbo.usp_phishme_security_dim_date
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
        SELECT 1 FROM zzSTG_phishme_security.dim_date
        WHERE date_key IS NULL OR year IS NULL OR month IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'dim_date', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_dim_date', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL date_key or year or month', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert)
        MERGE phishme_security.dim_date AS tgt
        USING zzSTG_phishme_security.dim_date AS src
            ON tgt.date_key = src.date_key
        WHEN MATCHED THEN
            UPDATE SET
                year          = src.year,
                month         = src.month,
                month_name    = src.month_name,
                month_short   = src.month_short,
                quarter       = src.quarter,
                quarter_label = src.quarter_label,
                week          = src.week,
                day           = src.day,
                day_of_week   = src.day_of_week,
                day_name      = src.day_name,
                is_weekend    = src.is_weekend,
                yyyymm        = src.yyyymm
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (date_key,year,month,month_name,month_short,quarter,
                    quarter_label,week,day,day_of_week,day_name,is_weekend,yyyymm)
            VALUES (src.date_key,src.year,src.month,src.month_name,src.month_short,
                    src.quarter,src.quarter_label,src.week,src.day,src.day_of_week,
                    src.day_name,src.is_weekend,src.yyyymm);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'dim_date', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_dim_date', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 2. usp_phishme_security_dim_user
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_dim_user', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_dim_user;
GO
CREATE PROCEDURE dbo.usp_phishme_security_dim_user
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
        SELECT 1 FROM zzSTG_phishme_security.dim_user
        WHERE email IS NULL OR LEN(LTRIM(RTRIM(email))) = 0
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'dim_user', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_dim_user', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL or empty email in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert)
        MERGE phishme_security.dim_user AS tgt
        USING zzSTG_phishme_security.dim_user AS src
            ON tgt.email = src.email
        WHEN MATCHED THEN
            UPDATE SET
                name                   = src.name,
                job_title              = src.job_title,
                phone                  = src.phone,
                time_zone              = src.time_zone,
                roles                  = src.roles,
                is_active              = src.is_active,
                deactivated_at         = src.deactivated_at,
                first_name             = src.first_name,
                last_name              = src.last_name,
                department             = src.department,
                location               = src.location,
                manager                = src.manager,
                employee_number        = src.employee_number,
                user_type              = src.user_type,
                country                = src.country,
                division               = src.division,
                display_name           = src.display_name,
                time_zone_rc           = src.time_zone_rc,
                proficiency_score      = src.proficiency_score,
                susceptibility_percent = src.susceptibility_percent,
                reporting_percent      = src.reporting_percent,
                risk_band              = src.risk_band,
                proficiency_band       = src.proficiency_band,
                scenarios_received     = src.scenarios_received,
                full_name              = src.full_name,
                is_third_party         = src.is_third_party,
                ingested_date          = src.ingested_date,
                ingested_at            = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (email,name,job_title,phone,time_zone,roles,is_active,
                    deactivated_at,first_name,last_name,department,location,
                    manager,employee_number,user_type,country,division,display_name,
                    time_zone_rc,proficiency_score,susceptibility_percent,
                    reporting_percent,risk_band,proficiency_band,scenarios_received,
                    full_name,is_third_party,ingested_date,ingested_at)
            VALUES (src.email,src.name,src.job_title,src.phone,src.time_zone,
                    src.roles,src.is_active,src.deactivated_at,src.first_name,
                    src.last_name,src.department,src.location,src.manager,
                    src.employee_number,src.user_type,src.country,src.division,
                    src.display_name,src.time_zone_rc,src.proficiency_score,
                    src.susceptibility_percent,src.reporting_percent,src.risk_band,
                    src.proficiency_band,src.scenarios_received,src.full_name,
                    src.is_third_party,src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'dim_user', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_dim_user', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 3. usp_phishme_security_dim_scenario
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_dim_scenario', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_dim_scenario;
GO
CREATE PROCEDURE dbo.usp_phishme_security_dim_scenario
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
        SELECT 1 FROM zzSTG_phishme_security.dim_scenario
        WHERE scenario_id IS NULL OR LEN(LTRIM(RTRIM(scenario_id))) = 0
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'dim_scenario', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_dim_scenario', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL or empty scenario_id in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert)
        MERGE phishme_security.dim_scenario AS tgt
        USING zzSTG_phishme_security.dim_scenario AS src
            ON tgt.scenario_id = src.scenario_id
        WHEN MATCHED THEN
            UPDATE SET
                scenario_name       = src.scenario_name,
                status              = src.status,
                scenario_type       = src.scenario_type,
                starts_at           = src.starts_at,
                ends_at             = src.ends_at,
                duration_days       = src.duration_days,
                total_recipients    = src.total_recipients,
                emails_sent         = src.emails_sent,
                emails_reported     = src.emails_reported,
                emails_clicked      = src.emails_clicked,
                emails_opened       = src.emails_opened,
                attachments_opened  = src.attachments_opened,
                data_entered        = src.data_entered,
                scenario_group_id   = src.scenario_group_id,
                scenario_group_name = src.scenario_group_name,
                is_active           = src.is_active,
                click_rate_pct      = src.click_rate_pct,
                report_rate_pct     = src.report_rate_pct,
                open_rate_pct       = src.open_rate_pct,
                ingested_date       = src.ingested_date,
                ingested_at         = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (scenario_id,scenario_name,status,scenario_type,starts_at,
                    ends_at,duration_days,total_recipients,emails_sent,
                    emails_reported,emails_clicked,emails_opened,attachments_opened,
                    data_entered,scenario_group_id,scenario_group_name,is_active,
                    click_rate_pct,report_rate_pct,open_rate_pct,ingested_date,ingested_at)
            VALUES (src.scenario_id,src.scenario_name,src.status,src.scenario_type,
                    src.starts_at,src.ends_at,src.duration_days,src.total_recipients,
                    src.emails_sent,src.emails_reported,src.emails_clicked,
                    src.emails_opened,src.attachments_opened,src.data_entered,
                    src.scenario_group_id,src.scenario_group_name,src.is_active,
                    src.click_rate_pct,src.report_rate_pct,src.open_rate_pct,
                    src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'dim_scenario', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_dim_scenario', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 4. usp_phishme_security_fact_phishing_responses
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_fact_phishing_responses', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_fact_phishing_responses;
GO
CREATE PROCEDURE dbo.usp_phishme_security_fact_phishing_responses
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
        SELECT 1 FROM zzSTG_phishme_security.fact_phishing_responses
        WHERE email IS NULL OR scenario_id IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'fact_phishing_responses', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_fact_phishing_responses', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL email or scenario_id in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert — composite key: email + scenario_id)
        MERGE phishme_security.fact_phishing_responses AS tgt
        USING zzSTG_phishme_security.fact_phishing_responses AS src
            ON tgt.email = src.email AND tgt.scenario_id = src.scenario_id
        WHEN MATCHED THEN
            UPDATE SET
                recipient_name       = src.recipient_name,
                recipient_group      = src.recipient_group,
                department           = src.department,
                location             = src.location,
                opened_email         = src.opened_email,
                opened_email_at      = src.opened_email_at,
                viewed_education     = src.viewed_education,
                viewed_education_at  = src.viewed_education_at,
                reported_phish       = src.reported_phish,
                reporter_type        = src.reporter_type,
                reported_phish_at    = src.reported_phish_at,
                time_to_report_secs  = src.time_to_report_secs,
                remote_ip            = src.remote_ip,
                geo_country          = src.geo_country,
                geo_city             = src.geo_city,
                geo_isp              = src.geo_isp,
                last_email_status    = src.last_email_status,
                is_mobile            = src.is_mobile,
                browser              = src.browser,
                ingested_date        = src.ingested_date,
                clicked_not_reported = src.clicked_not_reported,
                educated_after_click = src.educated_after_click,
                time_to_report_mins  = src.time_to_report_mins,
                response_category    = src.response_category,
                ingested_at          = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (email,scenario_id,recipient_name,recipient_group,department,
                    location,opened_email,opened_email_at,viewed_education,
                    viewed_education_at,reported_phish,reporter_type,reported_phish_at,
                    time_to_report_secs,remote_ip,geo_country,geo_city,geo_isp,
                    last_email_status,is_mobile,browser,ingested_date,
                    clicked_not_reported,educated_after_click,time_to_report_mins,
                    response_category,ingested_at)
            VALUES (src.email,src.scenario_id,src.recipient_name,src.recipient_group,
                    src.department,src.location,src.opened_email,src.opened_email_at,
                    src.viewed_education,src.viewed_education_at,src.reported_phish,
                    src.reporter_type,src.reported_phish_at,src.time_to_report_secs,
                    src.remote_ip,src.geo_country,src.geo_city,src.geo_isp,
                    src.last_email_status,src.is_mobile,src.browser,src.ingested_date,
                    src.clicked_not_reported,src.educated_after_click,
                    src.time_to_report_mins,src.response_category,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'fact_phishing_responses', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_fact_phishing_responses', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 5. usp_phishme_security_fact_activity_timeline
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_fact_activity_timeline', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_fact_activity_timeline;
GO
CREATE PROCEDURE dbo.usp_phishme_security_fact_activity_timeline
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
        SELECT 1 FROM zzSTG_phishme_security.fact_activity_timeline
        WHERE tracking_id IS NULL OR email IS NULL OR event_timestamp IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'fact_activity_timeline', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_fact_activity_timeline', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL tracking_id or email or event_timestamp', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert — key: tracking_id)
        MERGE phishme_security.fact_activity_timeline AS tgt
        USING zzSTG_phishme_security.fact_activity_timeline AS src
            ON tgt.tracking_id = src.tracking_id
        WHEN MATCHED THEN
            UPDATE SET
                email           = src.email,
                scenario_id     = src.scenario_id,
                event_timestamp = src.event_timestamp,
                event_date      = src.event_date,
                action          = src.action,
                recipient_group = src.recipient_group,
                remote_ip       = src.remote_ip,
                country         = src.country,
                city            = src.city,
                isp             = src.isp,
                browser         = src.browser,
                user_agent      = src.user_agent,
                is_mobile       = src.is_mobile,
                is_email_client = src.is_email_client,
                in_ua_charts    = src.in_ua_charts,
                ingested_date   = src.ingested_date,
                action_category = src.action_category,
                is_suspicious   = src.is_suspicious,
                ingested_at     = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (email,scenario_id,tracking_id,event_timestamp,event_date,
                    action,recipient_group,remote_ip,country,city,isp,browser,
                    user_agent,is_mobile,is_email_client,in_ua_charts,ingested_date,
                    action_category,is_suspicious,ingested_at)
            VALUES (src.email,src.scenario_id,src.tracking_id,src.event_timestamp,
                    src.event_date,src.action,src.recipient_group,src.remote_ip,
                    src.country,src.city,src.isp,src.browser,src.user_agent,
                    src.is_mobile,src.is_email_client,src.in_ua_charts,
                    src.ingested_date,src.action_category,src.is_suspicious,
                    src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'fact_activity_timeline', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_fact_activity_timeline', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 6. usp_phishme_security_fact_activity_logs
-- (append-only — INSERT new rows only, no updates)
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_fact_activity_logs', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_fact_activity_logs;
GO
CREATE PROCEDURE dbo.usp_phishme_security_fact_activity_logs
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
        SELECT 1 FROM zzSTG_phishme_security.fact_activity_logs
        WHERE [user] IS NULL OR event_timestamp IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'fact_activity_logs', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_fact_activity_logs', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL user or event_timestamp in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: INSERT new rows only (dedup on composite key)
        INSERT INTO phishme_security.fact_activity_logs
        ([user],activity_name,event_timestamp,event_date,
         ip_address,ingested_date,action_type,ingested_at)
        SELECT
            src.[user],src.activity_name,src.event_timestamp,src.event_date,
            src.ip_address,src.ingested_date,src.action_type,src.ingested_at
        FROM zzSTG_phishme_security.fact_activity_logs src
        WHERE NOT EXISTS (
            SELECT 1
            FROM phishme_security.fact_activity_logs tgt
            WHERE tgt.[user]          = src.[user]
              AND tgt.event_timestamp = src.event_timestamp
              AND tgt.activity_name   = src.activity_name
        );

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'fact_activity_logs', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_fact_activity_logs', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 7. usp_phishme_security_agg_user_risk
-- ============================================================
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
        -- STEP 2: MERGE (upsert — key: email)
        MERGE phishme_security.agg_user_risk AS tgt
        USING zzSTG_phishme_security.agg_user_risk AS src
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


-- ============================================================
-- 8. usp_phishme_security_agg_scenario_performance
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_agg_scenario_performance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_agg_scenario_performance;
GO
CREATE PROCEDURE dbo.usp_phishme_security_agg_scenario_performance
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
        SELECT 1 FROM zzSTG_phishme_security.agg_scenario_performance
        WHERE scenario_id IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'agg_scenario_performance', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_agg_scenario_performance', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL scenario_id in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert — key: scenario_id)
        MERGE phishme_security.agg_scenario_performance AS tgt
        USING zzSTG_phishme_security.agg_scenario_performance AS src
            ON tgt.scenario_id = src.scenario_id
        WHEN MATCHED THEN
            UPDATE SET
                unique_recipients       = src.unique_recipients,
                total_clicks            = src.total_clicks,
                total_reports           = src.total_reports,
                total_educated          = src.total_educated,
                clicked_not_reported    = src.clicked_not_reported,
                avg_time_to_report_mins = src.avg_time_to_report_mins,
                no_action_count         = src.no_action_count,
                click_rate_pct          = src.click_rate_pct,
                report_rate_pct         = src.report_rate_pct,
                education_rate_pct      = src.education_rate_pct,
                resilience_score        = src.resilience_score,
                scenario_name           = src.scenario_name,
                scenario_type           = src.scenario_type,
                starts_at               = src.starts_at,
                ends_at                 = src.ends_at,
                duration_days           = src.duration_days,
                status                  = src.status,
                ingested_date           = src.ingested_date,
                ingested_at             = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (scenario_id,unique_recipients,total_clicks,total_reports,
                    total_educated,clicked_not_reported,avg_time_to_report_mins,
                    no_action_count,click_rate_pct,report_rate_pct,education_rate_pct,
                    resilience_score,scenario_name,scenario_type,starts_at,ends_at,
                    duration_days,status,ingested_date,ingested_at)
            VALUES (src.scenario_id,src.unique_recipients,src.total_clicks,
                    src.total_reports,src.total_educated,src.clicked_not_reported,
                    src.avg_time_to_report_mins,src.no_action_count,src.click_rate_pct,
                    src.report_rate_pct,src.education_rate_pct,src.resilience_score,
                    src.scenario_name,src.scenario_type,src.starts_at,src.ends_at,
                    src.duration_days,src.status,src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'agg_scenario_performance', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_agg_scenario_performance', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 9. usp_phishme_security_agg_department_risk
-- ============================================================
IF OBJECT_ID('dbo.usp_phishme_security_agg_department_risk', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_phishme_security_agg_department_risk;
GO
CREATE PROCEDURE dbo.usp_phishme_security_agg_department_risk
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
        SELECT 1 FROM zzSTG_phishme_security.agg_department_risk
        WHERE department IS NULL
    )
        SET @dq_failed = 1;

    IF @dq_failed = 1
    BEGIN
        EXEC phishme_security.usp_set_watermark
            'agg_department_risk', @today, @now, 'FAILED',
            0, 0, 0, @source_path, 0, 0,
            'usp_phishme_security_agg_department_risk', @pipeline_run_id,
            'pipeline', 'DQ FAIL: NULL department in staging', 'DQ001';
    END
    ELSE
    BEGIN
        -- STEP 2: MERGE (upsert — key: department)
        MERGE phishme_security.agg_department_risk AS tgt
        USING zzSTG_phishme_security.agg_department_risk AS src
            ON tgt.department = src.department
        WHEN MATCHED THEN
            UPDATE SET
                total_users            = src.total_users,
                avg_click_rate_pct     = src.avg_click_rate_pct,
                avg_report_rate_pct    = src.avg_report_rate_pct,
                avg_education_rate_pct = src.avg_education_rate_pct,
                avg_risk_score         = src.avg_risk_score,
                critical_users         = src.critical_users,
                high_risk_users        = src.high_risk_users,
                medium_risk_users      = src.medium_risk_users,
                low_risk_users         = src.low_risk_users,
                dept_risk_label        = src.dept_risk_label,
                ingested_date          = src.ingested_date,
                ingested_at            = src.ingested_at
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (department,total_users,avg_click_rate_pct,avg_report_rate_pct,
                    avg_education_rate_pct,avg_risk_score,critical_users,high_risk_users,
                    medium_risk_users,low_risk_users,dept_risk_label,ingested_date,ingested_at)
            VALUES (src.department,src.total_users,src.avg_click_rate_pct,
                    src.avg_report_rate_pct,src.avg_education_rate_pct,src.avg_risk_score,
                    src.critical_users,src.high_risk_users,src.medium_risk_users,
                    src.low_risk_users,src.dept_risk_label,src.ingested_date,src.ingested_at);

        -- STEP 3: Watermark SUCCESS
        EXEC phishme_security.usp_set_watermark
            'agg_department_risk', @today, @now, 'SUCCESS',
            0, 0, 0, @source_path, 1, 0,
            'usp_phishme_security_agg_department_risk', @pipeline_run_id,
            'pipeline', NULL, NULL;
    END
END;
GO


-- ============================================================
-- 10. usp_phishme_security_agg_monthly_trend
-- ============================================================
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
        -- STEP 2: MERGE (upsert — composite key: yyyymm + scenario_id)
        MERGE phishme_security.agg_monthly_trend AS tgt
        USING zzSTG_phishme_security.agg_monthly_trend AS src
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


-- ============================================================
-- VERIFY: confirm all 10 procedures exist
-- ============================================================
SELECT
    name            AS procedure_name,
    create_date,
    modify_date
FROM sys.procedures
WHERE name LIKE 'usp_phishme_security_%'
ORDER BY name;
GO
