-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Azure Synapse Analytics — Staging Tables + CDC Procedures
-- Staging Schema  : zzSTG_phishme_security
-- Tables Schema   : phishme_security
-- Procedures      : dbo
-- Author          : Data Engineering
-- Created         : 2026-03-13
-- ============================================================

USE seplat_edw;
GO

-- ============================================================
-- 1. CREATE STAGING SCHEMA
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.schemas WHERE name = 'zzSTG_phishme_security'
)
    EXEC('CREATE SCHEMA zzSTG_phishme_security AUTHORIZATION dbo');
GO

-- ============================================================
-- 2. STAGING TABLES
-- ============================================================

-- ------------------------------------------------------------
-- STG: dim_date
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.dim_date', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.dim_date;
GO
CREATE TABLE zzSTG_phishme_security.dim_date
(
    date_key            DATE            NOT NULL,
    year                INT             NOT NULL,
    month               INT             NOT NULL,
    month_name          NVARCHAR(20)    NOT NULL,
    month_short         NVARCHAR(10)    NOT NULL,
    quarter             INT             NOT NULL,
    quarter_label       NVARCHAR(20)    NOT NULL,
    week                INT             NOT NULL,
    day                 INT             NOT NULL,
    day_of_week         INT             NOT NULL,
    day_name            NVARCHAR(20)    NOT NULL,
    is_weekend          BIT             NOT NULL,
    yyyymm              NVARCHAR(10)    NOT NULL,
    -- CDC columns
    stg_load_id         INT             NOT NULL,
    stg_loaded_at       DATETIME        NOT NULL,
    stg_source_path     NVARCHAR(500)   NOT NULL,
    stg_row_hash        NVARCHAR(64)    NOT NULL,
    stg_cdc_action      NVARCHAR(10)    NOT NULL  -- INSERT / UPDATE / DELETE / NOCHANGE
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: dim_user
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.dim_user', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.dim_user;
GO
CREATE TABLE zzSTG_phishme_security.dim_user
(
    email                   NVARCHAR(256)   NOT NULL,
    name                    NVARCHAR(256)   NULL,
    job_title               NVARCHAR(256)   NULL,
    phone                   NVARCHAR(50)    NULL,
    time_zone               NVARCHAR(100)   NULL,
    roles                   NVARCHAR(500)   NULL,
    is_active               BIT             NOT NULL,
    deactivated_at          NVARCHAR(50)    NULL,
    first_name              NVARCHAR(128)   NULL,
    last_name               NVARCHAR(128)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    manager                 NVARCHAR(256)   NULL,
    employee_number         NVARCHAR(50)    NULL,
    user_type               NVARCHAR(50)    NULL,
    country                 NVARCHAR(100)   NULL,
    division                NVARCHAR(256)   NULL,
    display_name            NVARCHAR(256)   NULL,
    time_zone_rc            NVARCHAR(100)   NULL,
    proficiency_score       FLOAT           NULL,
    susceptibility_percent  FLOAT           NULL,
    reporting_percent       FLOAT           NULL,
    risk_band               NVARCHAR(20)    NULL,
    proficiency_band        NVARCHAR(20)    NULL,
    scenarios_received      INT             NULL,
    full_name               NVARCHAR(256)   NULL,
    is_third_party          BIT             NOT NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: dim_scenario
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.dim_scenario', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.dim_scenario;
GO
CREATE TABLE zzSTG_phishme_security.dim_scenario
(
    scenario_id             NVARCHAR(64)    NOT NULL,
    scenario_name           NVARCHAR(500)   NULL,
    status                  NVARCHAR(50)    NULL,
    scenario_type           NVARCHAR(50)    NULL,
    starts_at               DATETIME        NULL,
    ends_at                 DATETIME        NULL,
    duration_days           INT             NULL,
    total_recipients        INT             NULL,
    emails_sent             INT             NULL,
    emails_reported         INT             NULL,
    emails_clicked          INT             NULL,
    emails_opened           INT             NULL,
    attachments_opened      INT             NULL,
    data_entered            INT             NULL,
    scenario_group_id       NVARCHAR(64)    NULL,
    scenario_group_name     NVARCHAR(256)   NULL,
    is_active               BIT             NOT NULL,
    click_rate_pct          FLOAT           NULL,
    report_rate_pct         FLOAT           NULL,
    open_rate_pct           FLOAT           NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: fact_phishing_responses
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.fact_phishing_responses', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.fact_phishing_responses;
GO
CREATE TABLE zzSTG_phishme_security.fact_phishing_responses
(
    email                   NVARCHAR(256)   NOT NULL,
    scenario_id             NVARCHAR(64)    NOT NULL,
    recipient_name          NVARCHAR(256)   NULL,
    recipient_group         NVARCHAR(256)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    opened_email            BIT             NOT NULL,
    opened_email_at         DATETIME        NULL,
    viewed_education        BIT             NOT NULL,
    viewed_education_at     DATETIME        NULL,
    reported_phish          BIT             NOT NULL,
    reporter_type           NVARCHAR(50)    NULL,
    reported_phish_at       DATETIME        NULL,
    time_to_report_secs     BIGINT          NULL,
    remote_ip               NVARCHAR(50)    NULL,
    geo_country             NVARCHAR(100)   NULL,
    geo_city                NVARCHAR(100)   NULL,
    geo_isp                 NVARCHAR(256)   NULL,
    last_email_status       NVARCHAR(50)    NULL,
    is_mobile               BIT             NOT NULL,
    browser                 NVARCHAR(256)   NULL,
    ingested_date           DATE            NOT NULL,
    clicked_not_reported    BIT             NOT NULL,
    educated_after_click    BIT             NOT NULL,
    time_to_report_mins     FLOAT           NULL,
    response_category       NVARCHAR(50)    NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

-- ------------------------------------------------------------
-- STG: fact_activity_timeline
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.fact_activity_timeline', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.fact_activity_timeline;
GO
CREATE TABLE zzSTG_phishme_security.fact_activity_timeline
(
    email                   NVARCHAR(256)   NOT NULL,
    scenario_id             NVARCHAR(64)    NOT NULL,
    tracking_id             NVARCHAR(64)    NOT NULL,
    event_timestamp         DATETIME        NOT NULL,
    event_date              DATE            NOT NULL,
    action                  NVARCHAR(256)   NULL,
    recipient_group         NVARCHAR(256)   NULL,
    remote_ip               NVARCHAR(50)    NULL,
    country                 NVARCHAR(100)   NULL,
    city                    NVARCHAR(100)   NULL,
    isp                     NVARCHAR(256)   NULL,
    browser                 NVARCHAR(256)   NULL,
    user_agent              NVARCHAR(500)   NULL,
    is_mobile               BIT             NOT NULL,
    is_email_client         BIT             NOT NULL,
    in_ua_charts            BIT             NOT NULL,
    ingested_date           DATE            NOT NULL,
    action_category         NVARCHAR(50)    NULL,
    is_suspicious           BIT             NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

-- ------------------------------------------------------------
-- STG: fact_activity_logs
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.fact_activity_logs', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.fact_activity_logs;
GO
CREATE TABLE zzSTG_phishme_security.fact_activity_logs
(
    [user]                  NVARCHAR(256)   NOT NULL,
    activity_name           NVARCHAR(256)   NULL,
    event_timestamp         DATETIME        NOT NULL,
    event_date              DATE            NOT NULL,
    ip_address              NVARCHAR(50)    NULL,
    ingested_date           DATE            NOT NULL,
    action_type             NVARCHAR(50)    NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

-- ------------------------------------------------------------
-- STG: agg_user_risk
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.agg_user_risk', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.agg_user_risk;
GO
CREATE TABLE zzSTG_phishme_security.agg_user_risk
(
    email                   NVARCHAR(256)   NOT NULL,
    total_scenarios         BIGINT          NULL,
    total_emails_received   BIGINT          NULL,
    total_clicks            BIGINT          NULL,
    total_reports           BIGINT          NULL,
    total_educated          BIGINT          NULL,
    clicks_not_reported     BIGINT          NULL,
    avg_time_to_report_mins FLOAT           NULL,
    first_click_at          DATETIME        NULL,
    last_click_at           DATETIME        NULL,
    click_rate_pct          FLOAT           NULL,
    report_rate_pct         FLOAT           NULL,
    education_rate_pct      FLOAT           NULL,
    user_risk_score         FLOAT           NULL,
    user_risk_label         NVARCHAR(20)    NULL,
    full_name               NVARCHAR(256)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    job_title               NVARCHAR(256)   NULL,
    manager                 NVARCHAR(256)   NULL,
    country                 NVARCHAR(100)   NULL,
    division                NVARCHAR(256)   NULL,
    is_active               BIT             NOT NULL,
    is_third_party          BIT             NOT NULL,
    risk_band               NVARCHAR(20)    NULL,
    proficiency_band        NVARCHAR(20)    NULL,
    proficiency_score       FLOAT           NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: agg_scenario_performance
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.agg_scenario_performance', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.agg_scenario_performance;
GO
CREATE TABLE zzSTG_phishme_security.agg_scenario_performance
(
    scenario_id             NVARCHAR(64)    NOT NULL,
    unique_recipients       BIGINT          NULL,
    total_clicks            BIGINT          NULL,
    total_reports           BIGINT          NULL,
    total_educated          BIGINT          NULL,
    clicked_not_reported    BIGINT          NULL,
    avg_time_to_report_mins FLOAT           NULL,
    no_action_count         BIGINT          NULL,
    click_rate_pct          FLOAT           NULL,
    report_rate_pct         FLOAT           NULL,
    education_rate_pct      FLOAT           NULL,
    resilience_score        FLOAT           NULL,
    scenario_name           NVARCHAR(500)   NULL,
    scenario_type           NVARCHAR(50)    NULL,
    starts_at               DATETIME        NULL,
    ends_at                 DATETIME        NULL,
    duration_days           INT             NULL,
    status                  NVARCHAR(50)    NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: agg_department_risk
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.agg_department_risk', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.agg_department_risk;
GO
CREATE TABLE zzSTG_phishme_security.agg_department_risk
(
    department              NVARCHAR(256)   NOT NULL,
    total_users             BIGINT          NULL,
    avg_click_rate_pct      FLOAT           NULL,
    avg_report_rate_pct     FLOAT           NULL,
    avg_education_rate_pct  FLOAT           NULL,
    avg_risk_score          FLOAT           NULL,
    critical_users          BIGINT          NULL,
    high_risk_users         BIGINT          NULL,
    medium_risk_users       BIGINT          NULL,
    low_risk_users          BIGINT          NULL,
    dept_risk_label         NVARCHAR(20)    NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = REPLICATE, HEAP);
GO

-- ------------------------------------------------------------
-- STG: agg_monthly_trend
-- ------------------------------------------------------------
IF OBJECT_ID('zzSTG_phishme_security.agg_monthly_trend', 'U') IS NOT NULL
    DROP TABLE zzSTG_phishme_security.agg_monthly_trend;
GO
CREATE TABLE zzSTG_phishme_security.agg_monthly_trend
(
    yyyymm                  NVARCHAR(10)    NOT NULL,
    year                    NVARCHAR(10)    NOT NULL,
    month                   NVARCHAR(10)    NOT NULL,
    scenario_id             NVARCHAR(64)    NOT NULL,
    unique_users            BIGINT          NULL,
    total_events            BIGINT          NULL,
    clicks                  BIGINT          NULL,
    reports                 BIGINT          NULL,
    educations              BIGINT          NULL,
    data_entries            BIGINT          NULL,
    suspicious_events       BIGINT          NULL,
    click_to_report_ratio   FLOAT           NULL,
    ingested_date           DATE            NOT NULL,
    ingested_at             DATETIME        NOT NULL,
    -- CDC columns
    stg_load_id             INT             NOT NULL,
    stg_loaded_at           DATETIME        NOT NULL,
    stg_source_path         NVARCHAR(500)   NOT NULL,
    stg_row_hash            NVARCHAR(64)    NOT NULL,
    stg_cdc_action          NVARCHAR(10)    NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO


