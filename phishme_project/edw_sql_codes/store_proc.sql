-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Azure Synapse Analytics — CDC Stored Procedures (ALL 10)
-- Schema : dbo (procedures)
-- Fixed  : RETURN → IF/ELSE | CAST(GETDATE()) → @today/@now vars
-- Author : Data Engineering
-- Date   : 2026-03-13
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

    -- STEP 1: Tag CDC
    UPDATE zzSTG_phishme_security.dim_date
    SET stg_cdc_action =
        CASE
            WHEN tgt.date_key IS NULL                  THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.dim_date stg
    LEFT JOIN phishme_security.dim_date tgt
        ON stg.date_key = tgt.date_key
    LEFT JOIN (
        SELECT date_key,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(year        AS NVARCHAR),''),'|',
                    ISNULL(CAST(month       AS NVARCHAR),''),'|',
                    ISNULL(month_name,      ''),'|',
                    ISNULL(month_short,     ''),'|',
                    ISNULL(CAST(quarter     AS NVARCHAR),''),'|',
                    ISNULL(quarter_label,   ''),'|',
                    ISNULL(CAST(week        AS NVARCHAR),''),'|',
                    ISNULL(CAST(day         AS NVARCHAR),''),'|',
                    ISNULL(CAST(day_of_week AS NVARCHAR),''),'|',
                    ISNULL(day_name,        ''),'|',
                    ISNULL(CAST(is_weekend  AS NVARCHAR),''),'|',
                    ISNULL(yyyymm,          '')
                )
            ), 2) AS row_hash
        FROM phishme_security.dim_date
    ) tgt_hash ON stg.date_key = tgt_hash.date_key;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.dim_date
        (date_key,year,month,month_name,month_short,quarter,quarter_label,
         week,day,day_of_week,day_name,is_weekend,yyyymm)
        SELECT
            date_key,year,month,month_name,month_short,quarter,quarter_label,
            week,day,day_of_week,day_name,is_weekend,yyyymm
        FROM zzSTG_phishme_security.dim_date
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.dim_date
        SET
            year          = stg.year,
            month         = stg.month,
            month_name    = stg.month_name,
            month_short   = stg.month_short,
            quarter       = stg.quarter,
            quarter_label = stg.quarter_label,
            week          = stg.week,
            day           = stg.day,
            day_of_week   = stg.day_of_week,
            day_name      = stg.day_name,
            is_weekend    = stg.is_weekend,
            yyyymm        = stg.yyyymm
        FROM phishme_security.dim_date tgt
        INNER JOIN zzSTG_phishme_security.dim_date stg
            ON tgt.date_key = stg.date_key
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC
    UPDATE zzSTG_phishme_security.dim_user
    SET stg_cdc_action =
        CASE
            WHEN tgt.email IS NULL                     THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.dim_user stg
    LEFT JOIN phishme_security.dim_user tgt
        ON stg.email = tgt.email
    LEFT JOIN (
        SELECT email,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(name,            ''),'|',
                    ISNULL(job_title,       ''),'|',
                    ISNULL(department,      ''),'|',
                    ISNULL(location,        ''),'|',
                    ISNULL(manager,         ''),'|',
                    ISNULL(employee_number, ''),'|',
                    ISNULL(user_type,       ''),'|',
                    ISNULL(country,         ''),'|',
                    ISNULL(division,        ''),'|',
                    ISNULL(CAST(is_active           AS NVARCHAR),''),'|',
                    ISNULL(risk_band,       ''),'|',
                    ISNULL(proficiency_band,''),'|',
                    ISNULL(CAST(proficiency_score       AS NVARCHAR),''),'|',
                    ISNULL(CAST(susceptibility_percent  AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.dim_user
    ) tgt_hash ON stg.email = tgt_hash.email;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.dim_user
        (email,name,job_title,phone,time_zone,roles,is_active,deactivated_at,
         first_name,last_name,department,location,manager,employee_number,
         user_type,country,division,display_name,time_zone_rc,proficiency_score,
         susceptibility_percent,reporting_percent,risk_band,proficiency_band,
         scenarios_received,full_name,is_third_party,ingested_date,ingested_at)
        SELECT
            email,name,job_title,phone,time_zone,roles,is_active,deactivated_at,
            first_name,last_name,department,location,manager,employee_number,
            user_type,country,division,display_name,time_zone_rc,proficiency_score,
            susceptibility_percent,reporting_percent,risk_band,proficiency_band,
            scenarios_received,full_name,is_third_party,ingested_date,ingested_at
        FROM zzSTG_phishme_security.dim_user
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.dim_user
        SET
            name                   = stg.name,
            job_title              = stg.job_title,
            phone                  = stg.phone,
            time_zone              = stg.time_zone,
            roles                  = stg.roles,
            is_active              = stg.is_active,
            deactivated_at         = stg.deactivated_at,
            first_name             = stg.first_name,
            last_name              = stg.last_name,
            department             = stg.department,
            location               = stg.location,
            manager                = stg.manager,
            employee_number        = stg.employee_number,
            user_type              = stg.user_type,
            country                = stg.country,
            division               = stg.division,
            display_name           = stg.display_name,
            time_zone_rc           = stg.time_zone_rc,
            proficiency_score      = stg.proficiency_score,
            susceptibility_percent = stg.susceptibility_percent,
            reporting_percent      = stg.reporting_percent,
            risk_band              = stg.risk_band,
            proficiency_band       = stg.proficiency_band,
            scenarios_received     = stg.scenarios_received,
            full_name              = stg.full_name,
            is_third_party         = stg.is_third_party,
            ingested_date          = stg.ingested_date,
            ingested_at            = stg.ingested_at
        FROM phishme_security.dim_user tgt
        INNER JOIN zzSTG_phishme_security.dim_user stg
            ON tgt.email = stg.email
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC
    UPDATE zzSTG_phishme_security.dim_scenario
    SET stg_cdc_action =
        CASE
            WHEN tgt.scenario_id IS NULL               THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.dim_scenario stg
    LEFT JOIN phishme_security.dim_scenario tgt
        ON stg.scenario_id = tgt.scenario_id
    LEFT JOIN (
        SELECT scenario_id,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(scenario_name,   ''),'|',
                    ISNULL(status,          ''),'|',
                    ISNULL(scenario_type,   ''),'|',
                    ISNULL(CAST(emails_sent      AS NVARCHAR),''),'|',
                    ISNULL(CAST(emails_clicked   AS NVARCHAR),''),'|',
                    ISNULL(CAST(emails_reported  AS NVARCHAR),''),'|',
                    ISNULL(CAST(is_active        AS NVARCHAR),''),'|',
                    ISNULL(CAST(click_rate_pct   AS NVARCHAR),''),'|',
                    ISNULL(CAST(report_rate_pct  AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.dim_scenario
    ) tgt_hash ON stg.scenario_id = tgt_hash.scenario_id;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.dim_scenario
        (scenario_id,scenario_name,status,scenario_type,starts_at,ends_at,
         duration_days,total_recipients,emails_sent,emails_reported,emails_clicked,
         emails_opened,attachments_opened,data_entered,scenario_group_id,
         scenario_group_name,is_active,click_rate_pct,report_rate_pct,
         open_rate_pct,ingested_date,ingested_at)
        SELECT
            scenario_id,scenario_name,status,scenario_type,starts_at,ends_at,
            duration_days,total_recipients,emails_sent,emails_reported,emails_clicked,
            emails_opened,attachments_opened,data_entered,scenario_group_id,
            scenario_group_name,is_active,click_rate_pct,report_rate_pct,
            open_rate_pct,ingested_date,ingested_at
        FROM zzSTG_phishme_security.dim_scenario
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.dim_scenario
        SET
            scenario_name       = stg.scenario_name,
            status              = stg.status,
            scenario_type       = stg.scenario_type,
            starts_at           = stg.starts_at,
            ends_at             = stg.ends_at,
            duration_days       = stg.duration_days,
            total_recipients    = stg.total_recipients,
            emails_sent         = stg.emails_sent,
            emails_reported     = stg.emails_reported,
            emails_clicked      = stg.emails_clicked,
            emails_opened       = stg.emails_opened,
            attachments_opened  = stg.attachments_opened,
            data_entered        = stg.data_entered,
            scenario_group_id   = stg.scenario_group_id,
            scenario_group_name = stg.scenario_group_name,
            is_active           = stg.is_active,
            click_rate_pct      = stg.click_rate_pct,
            report_rate_pct     = stg.report_rate_pct,
            open_rate_pct       = stg.open_rate_pct,
            ingested_date       = stg.ingested_date,
            ingested_at         = stg.ingested_at
        FROM phishme_security.dim_scenario tgt
        INNER JOIN zzSTG_phishme_security.dim_scenario stg
            ON tgt.scenario_id = stg.scenario_id
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (composite key: email + scenario_id)
    UPDATE zzSTG_phishme_security.fact_phishing_responses
    SET stg_cdc_action =
        CASE
            WHEN tgt.email IS NULL                     THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.fact_phishing_responses stg
    LEFT JOIN phishme_security.fact_phishing_responses tgt
        ON stg.email = tgt.email AND stg.scenario_id = tgt.scenario_id
    LEFT JOIN (
        SELECT email, scenario_id,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(opened_email         AS NVARCHAR),''),'|',
                    ISNULL(CAST(reported_phish        AS NVARCHAR),''),'|',
                    ISNULL(CAST(viewed_education      AS NVARCHAR),''),'|',
                    ISNULL(response_category,         ''),'|',
                    ISNULL(CAST(clicked_not_reported  AS NVARCHAR),''),'|',
                    ISNULL(CAST(time_to_report_mins   AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.fact_phishing_responses
    ) tgt_hash
        ON stg.email = tgt_hash.email AND stg.scenario_id = tgt_hash.scenario_id;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.fact_phishing_responses
        (email,scenario_id,recipient_name,recipient_group,department,location,
         opened_email,opened_email_at,viewed_education,viewed_education_at,
         reported_phish,reporter_type,reported_phish_at,time_to_report_secs,
         remote_ip,geo_country,geo_city,geo_isp,last_email_status,is_mobile,
         browser,ingested_date,clicked_not_reported,educated_after_click,
         time_to_report_mins,response_category,ingested_at)
        SELECT
            email,scenario_id,recipient_name,recipient_group,department,location,
            opened_email,opened_email_at,viewed_education,viewed_education_at,
            reported_phish,reporter_type,reported_phish_at,time_to_report_secs,
            remote_ip,geo_country,geo_city,geo_isp,last_email_status,is_mobile,
            browser,ingested_date,clicked_not_reported,educated_after_click,
            time_to_report_mins,response_category,ingested_at
        FROM zzSTG_phishme_security.fact_phishing_responses
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.fact_phishing_responses
        SET
            recipient_name       = stg.recipient_name,
            recipient_group      = stg.recipient_group,
            department           = stg.department,
            location             = stg.location,
            opened_email         = stg.opened_email,
            opened_email_at      = stg.opened_email_at,
            viewed_education     = stg.viewed_education,
            viewed_education_at  = stg.viewed_education_at,
            reported_phish       = stg.reported_phish,
            reporter_type        = stg.reporter_type,
            reported_phish_at    = stg.reported_phish_at,
            time_to_report_secs  = stg.time_to_report_secs,
            remote_ip            = stg.remote_ip,
            geo_country          = stg.geo_country,
            geo_city             = stg.geo_city,
            geo_isp              = stg.geo_isp,
            last_email_status    = stg.last_email_status,
            is_mobile            = stg.is_mobile,
            browser              = stg.browser,
            clicked_not_reported = stg.clicked_not_reported,
            educated_after_click = stg.educated_after_click,
            time_to_report_mins  = stg.time_to_report_mins,
            response_category    = stg.response_category,
            ingested_date        = stg.ingested_date,
            ingested_at          = stg.ingested_at
        FROM phishme_security.fact_phishing_responses tgt
        INNER JOIN zzSTG_phishme_security.fact_phishing_responses stg
            ON tgt.email = stg.email AND tgt.scenario_id = stg.scenario_id
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (key: tracking_id)
    UPDATE zzSTG_phishme_security.fact_activity_timeline
    SET stg_cdc_action =
        CASE
            WHEN tgt.tracking_id IS NULL               THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.fact_activity_timeline stg
    LEFT JOIN phishme_security.fact_activity_timeline tgt
        ON stg.tracking_id = tgt.tracking_id
    LEFT JOIN (
        SELECT tracking_id,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(action,          ''),'|',
                    ISNULL(action_category, ''),'|',
                    ISNULL(CAST(is_suspicious AS NVARCHAR),''),'|',
                    ISNULL(country,         ''),'|',
                    ISNULL(CAST(is_mobile   AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.fact_activity_timeline
    ) tgt_hash ON stg.tracking_id = tgt_hash.tracking_id;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.fact_activity_timeline
        (email,scenario_id,tracking_id,event_timestamp,event_date,action,
         recipient_group,remote_ip,country,city,isp,browser,user_agent,
         is_mobile,is_email_client,in_ua_charts,ingested_date,action_category,
         is_suspicious,ingested_at)
        SELECT
            email,scenario_id,tracking_id,event_timestamp,event_date,action,
            recipient_group,remote_ip,country,city,isp,browser,user_agent,
            is_mobile,is_email_client,in_ua_charts,ingested_date,action_category,
            is_suspicious,ingested_at
        FROM zzSTG_phishme_security.fact_activity_timeline
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.fact_activity_timeline
        SET
            action          = stg.action,
            action_category = stg.action_category,
            is_suspicious   = stg.is_suspicious,
            country         = stg.country,
            city            = stg.city,
            is_mobile       = stg.is_mobile,
            ingested_date   = stg.ingested_date,
            ingested_at     = stg.ingested_at
        FROM phishme_security.fact_activity_timeline tgt
        INNER JOIN zzSTG_phishme_security.fact_activity_timeline stg
            ON tgt.tracking_id = stg.tracking_id
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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
-- (append-only — no UPDATE, logs are immutable)
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

    -- STEP 1: Tag CDC (key: user + event_timestamp + activity_name)
    UPDATE zzSTG_phishme_security.fact_activity_logs
    SET stg_cdc_action =
        CASE
            WHEN tgt.[user] IS NULL THEN 'INSERT'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.fact_activity_logs stg
    LEFT JOIN phishme_security.fact_activity_logs tgt
        ON  stg.[user]           = tgt.[user]
        AND stg.event_timestamp  = tgt.event_timestamp
        AND stg.activity_name    = tgt.activity_name;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT only (no updates on audit logs)
        INSERT INTO phishme_security.fact_activity_logs
        ([user],activity_name,event_timestamp,event_date,
         ip_address,ingested_date,action_type,ingested_at)
        SELECT
            [user],activity_name,event_timestamp,event_date,
            ip_address,ingested_date,action_type,ingested_at
        FROM zzSTG_phishme_security.fact_activity_logs
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (key: email)
    UPDATE zzSTG_phishme_security.agg_user_risk
    SET stg_cdc_action =
        CASE
            WHEN tgt.email IS NULL                     THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.agg_user_risk stg
    LEFT JOIN phishme_security.agg_user_risk tgt
        ON stg.email = tgt.email
    LEFT JOIN (
        SELECT email,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(total_clicks      AS NVARCHAR),''),'|',
                    ISNULL(CAST(total_reports     AS NVARCHAR),''),'|',
                    ISNULL(CAST(user_risk_score   AS NVARCHAR),''),'|',
                    ISNULL(user_risk_label,       ''),'|',
                    ISNULL(risk_band,             ''),'|',
                    ISNULL(proficiency_band,      ''),'|',
                    ISNULL(CAST(click_rate_pct    AS NVARCHAR),''),'|',
                    ISNULL(CAST(report_rate_pct   AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.agg_user_risk
    ) tgt_hash ON stg.email = tgt_hash.email;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.agg_user_risk
        (email,total_scenarios,total_emails_received,total_clicks,total_reports,
         total_educated,clicks_not_reported,avg_time_to_report_mins,first_click_at,
         last_click_at,click_rate_pct,report_rate_pct,education_rate_pct,
         user_risk_score,user_risk_label,full_name,department,location,job_title,
         manager,country,division,is_active,is_third_party,risk_band,
         proficiency_band,proficiency_score,ingested_date,ingested_at)
        SELECT
            email,total_scenarios,total_emails_received,total_clicks,total_reports,
            total_educated,clicks_not_reported,avg_time_to_report_mins,first_click_at,
            last_click_at,click_rate_pct,report_rate_pct,education_rate_pct,
            user_risk_score,user_risk_label,full_name,department,location,job_title,
            manager,country,division,is_active,is_third_party,risk_band,
            proficiency_band,proficiency_score,ingested_date,ingested_at
        FROM zzSTG_phishme_security.agg_user_risk
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.agg_user_risk
        SET
            total_scenarios         = stg.total_scenarios,
            total_emails_received   = stg.total_emails_received,
            total_clicks            = stg.total_clicks,
            total_reports           = stg.total_reports,
            total_educated          = stg.total_educated,
            clicks_not_reported     = stg.clicks_not_reported,
            avg_time_to_report_mins = stg.avg_time_to_report_mins,
            first_click_at          = stg.first_click_at,
            last_click_at           = stg.last_click_at,
            click_rate_pct          = stg.click_rate_pct,
            report_rate_pct         = stg.report_rate_pct,
            education_rate_pct      = stg.education_rate_pct,
            user_risk_score         = stg.user_risk_score,
            user_risk_label         = stg.user_risk_label,
            full_name               = stg.full_name,
            department              = stg.department,
            location                = stg.location,
            job_title               = stg.job_title,
            manager                 = stg.manager,
            country                 = stg.country,
            division                = stg.division,
            is_active               = stg.is_active,
            is_third_party          = stg.is_third_party,
            risk_band               = stg.risk_band,
            proficiency_band        = stg.proficiency_band,
            proficiency_score       = stg.proficiency_score,
            ingested_date           = stg.ingested_date,
            ingested_at             = stg.ingested_at
        FROM phishme_security.agg_user_risk tgt
        INNER JOIN zzSTG_phishme_security.agg_user_risk stg
            ON tgt.email = stg.email
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (key: scenario_id)
    UPDATE zzSTG_phishme_security.agg_scenario_performance
    SET stg_cdc_action =
        CASE
            WHEN tgt.scenario_id IS NULL               THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.agg_scenario_performance stg
    LEFT JOIN phishme_security.agg_scenario_performance tgt
        ON stg.scenario_id = tgt.scenario_id
    LEFT JOIN (
        SELECT scenario_id,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(total_clicks      AS NVARCHAR),''),'|',
                    ISNULL(CAST(total_reports     AS NVARCHAR),''),'|',
                    ISNULL(CAST(resilience_score  AS NVARCHAR),''),'|',
                    ISNULL(CAST(click_rate_pct    AS NVARCHAR),''),'|',
                    ISNULL(CAST(report_rate_pct   AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.agg_scenario_performance
    ) tgt_hash ON stg.scenario_id = tgt_hash.scenario_id;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.agg_scenario_performance
        (scenario_id,unique_recipients,total_clicks,total_reports,total_educated,
         clicked_not_reported,avg_time_to_report_mins,no_action_count,click_rate_pct,
         report_rate_pct,education_rate_pct,resilience_score,scenario_name,
         scenario_type,starts_at,ends_at,duration_days,status,ingested_date,ingested_at)
        SELECT
            scenario_id,unique_recipients,total_clicks,total_reports,total_educated,
            clicked_not_reported,avg_time_to_report_mins,no_action_count,click_rate_pct,
            report_rate_pct,education_rate_pct,resilience_score,scenario_name,
            scenario_type,starts_at,ends_at,duration_days,status,ingested_date,ingested_at
        FROM zzSTG_phishme_security.agg_scenario_performance
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.agg_scenario_performance
        SET
            unique_recipients       = stg.unique_recipients,
            total_clicks            = stg.total_clicks,
            total_reports           = stg.total_reports,
            total_educated          = stg.total_educated,
            clicked_not_reported    = stg.clicked_not_reported,
            avg_time_to_report_mins = stg.avg_time_to_report_mins,
            no_action_count         = stg.no_action_count,
            click_rate_pct          = stg.click_rate_pct,
            report_rate_pct         = stg.report_rate_pct,
            education_rate_pct      = stg.education_rate_pct,
            resilience_score        = stg.resilience_score,
            scenario_name           = stg.scenario_name,
            scenario_type           = stg.scenario_type,
            starts_at               = stg.starts_at,
            ends_at                 = stg.ends_at,
            duration_days           = stg.duration_days,
            status                  = stg.status,
            ingested_date           = stg.ingested_date,
            ingested_at             = stg.ingested_at
        FROM phishme_security.agg_scenario_performance tgt
        INNER JOIN zzSTG_phishme_security.agg_scenario_performance stg
            ON tgt.scenario_id = stg.scenario_id
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (key: department)
    UPDATE zzSTG_phishme_security.agg_department_risk
    SET stg_cdc_action =
        CASE
            WHEN tgt.department IS NULL                THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.agg_department_risk stg
    LEFT JOIN phishme_security.agg_department_risk tgt
        ON stg.department = tgt.department
    LEFT JOIN (
        SELECT department,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(avg_click_rate_pct AS NVARCHAR),''),'|',
                    ISNULL(CAST(avg_risk_score     AS NVARCHAR),''),'|',
                    ISNULL(CAST(critical_users     AS NVARCHAR),''),'|',
                    ISNULL(CAST(high_risk_users    AS NVARCHAR),''),'|',
                    ISNULL(dept_risk_label,        '')
                )
            ), 2) AS row_hash
        FROM phishme_security.agg_department_risk
    ) tgt_hash ON stg.department = tgt_hash.department;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.agg_department_risk
        (department,total_users,avg_click_rate_pct,avg_report_rate_pct,
         avg_education_rate_pct,avg_risk_score,critical_users,high_risk_users,
         medium_risk_users,low_risk_users,dept_risk_label,ingested_date,ingested_at)
        SELECT
            department,total_users,avg_click_rate_pct,avg_report_rate_pct,
            avg_education_rate_pct,avg_risk_score,critical_users,high_risk_users,
            medium_risk_users,low_risk_users,dept_risk_label,ingested_date,ingested_at
        FROM zzSTG_phishme_security.agg_department_risk
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.agg_department_risk
        SET
            total_users            = stg.total_users,
            avg_click_rate_pct     = stg.avg_click_rate_pct,
            avg_report_rate_pct    = stg.avg_report_rate_pct,
            avg_education_rate_pct = stg.avg_education_rate_pct,
            avg_risk_score         = stg.avg_risk_score,
            critical_users         = stg.critical_users,
            high_risk_users        = stg.high_risk_users,
            medium_risk_users      = stg.medium_risk_users,
            low_risk_users         = stg.low_risk_users,
            dept_risk_label        = stg.dept_risk_label,
            ingested_date          = stg.ingested_date,
            ingested_at            = stg.ingested_at
        FROM phishme_security.agg_department_risk tgt
        INNER JOIN zzSTG_phishme_security.agg_department_risk stg
            ON tgt.department = stg.department
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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

    -- STEP 1: Tag CDC (composite key: yyyymm + scenario_id)
    UPDATE zzSTG_phishme_security.agg_monthly_trend
    SET stg_cdc_action =
        CASE
            WHEN tgt.yyyymm IS NULL                    THEN 'INSERT'
            WHEN stg.stg_row_hash <> tgt_hash.row_hash THEN 'UPDATE'
            ELSE 'NOCHANGE'
        END
    FROM zzSTG_phishme_security.agg_monthly_trend stg
    LEFT JOIN phishme_security.agg_monthly_trend tgt
        ON stg.yyyymm = tgt.yyyymm AND stg.scenario_id = tgt.scenario_id
    LEFT JOIN (
        SELECT yyyymm, scenario_id,
            CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(CAST(clicks               AS NVARCHAR),''),'|',
                    ISNULL(CAST(reports              AS NVARCHAR),''),'|',
                    ISNULL(CAST(suspicious_events    AS NVARCHAR),''),'|',
                    ISNULL(CAST(click_to_report_ratio AS NVARCHAR),''),'|',
                    ISNULL(CAST(unique_users         AS NVARCHAR),''),'|',
                    ISNULL(CAST(total_events         AS NVARCHAR),'')
                )
            ), 2) AS row_hash
        FROM phishme_security.agg_monthly_trend
    ) tgt_hash
        ON stg.yyyymm = tgt_hash.yyyymm AND stg.scenario_id = tgt_hash.scenario_id;

    -- STEP 2: Data quality
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
        -- STEP 3: INSERT
        INSERT INTO phishme_security.agg_monthly_trend
        (yyyymm,year,month,scenario_id,unique_users,total_events,clicks,reports,
         educations,data_entries,suspicious_events,click_to_report_ratio,
         ingested_date,ingested_at)
        SELECT
            yyyymm,year,month,scenario_id,unique_users,total_events,clicks,reports,
            educations,data_entries,suspicious_events,click_to_report_ratio,
            ingested_date,ingested_at
        FROM zzSTG_phishme_security.agg_monthly_trend
        WHERE stg_cdc_action = 'INSERT';

        -- STEP 4: UPDATE
        UPDATE phishme_security.agg_monthly_trend
        SET
            unique_users          = stg.unique_users,
            total_events          = stg.total_events,
            clicks                = stg.clicks,
            reports               = stg.reports,
            educations            = stg.educations,
            data_entries          = stg.data_entries,
            suspicious_events     = stg.suspicious_events,
            click_to_report_ratio = stg.click_to_report_ratio,
            ingested_date         = stg.ingested_date,
            ingested_at           = stg.ingested_at
        FROM phishme_security.agg_monthly_trend tgt
        INNER JOIN zzSTG_phishme_security.agg_monthly_trend stg
            ON tgt.yyyymm = stg.yyyymm AND tgt.scenario_id = stg.scenario_id
        WHERE stg.stg_cdc_action = 'UPDATE';

        -- STEP 5: Watermark SUCCESS
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