-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Staging Tables DDL — zzSTG_phishme_security
-- Target Tables DDL — phishme_security
-- Database : seplat_edw
-- Author   : Data Engineering
-- Date     : 2026-03-13
-- Notes    : ASA-compatible T-SQL (no IDENTITY on HEAP/REPLICATE)
--            Staging adds: stg_row_hash, stg_cdc_action, stg_loaded_at
-- ============================================================

USE seplat_edw;
GO

-- ============================================================
-- CREATE SCHEMAS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'zzSTG_phishme_security')
    EXEC('CREATE SCHEMA zzSTG_phishme_security AUTHORIZATION dbo');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'phishme_security')
    EXEC('CREATE SCHEMA phishme_security AUTHORIZATION dbo');
GO


-- ============================================================
-- 1. dim_date
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.dim_date','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.dim_date;
GO
CREATE TABLE zzSTG_phishme_security.dim_date
(
    date_key        DATE            NULL,
    year            INT             NULL,
    month           INT             NULL,
    month_name      NVARCHAR(50)    NULL,
    month_short     NVARCHAR(10)    NULL,
    quarter         INT             NULL,
    quarter_label   NVARCHAR(10)    NULL,
    week            INT             NULL,
    day             INT             NULL,
    day_of_week     INT             NULL,
    day_name        NVARCHAR(20)    NULL,
    is_weekend      BIT             NULL,
    yyyymm          NVARCHAR(10)    NULL,
    -- CDC control columns
    stg_row_hash    NVARCHAR(64)    NULL,
    stg_cdc_action  NVARCHAR(20)    NULL,
    stg_loaded_at   DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.dim_date','U') IS NOT NULL DROP TABLE phishme_security.dim_date;
GO
CREATE TABLE phishme_security.dim_date
(
    date_key        DATE            NOT NULL,
    year            INT             NOT NULL,
    month           INT             NOT NULL,
    month_name      NVARCHAR(50)    NULL,
    month_short     NVARCHAR(10)    NULL,
    quarter         INT             NULL,
    quarter_label   NVARCHAR(10)    NULL,
    week            INT             NULL,
    day             INT             NULL,
    day_of_week     INT             NULL,
    day_name        NVARCHAR(20)    NULL,
    is_weekend      BIT             NULL,
    yyyymm          NVARCHAR(10)    NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 2. dim_user
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.dim_user','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.dim_user;
GO
CREATE TABLE zzSTG_phishme_security.dim_user
(
    email                   NVARCHAR(256)   NULL,
    name                    NVARCHAR(256)   NULL,
    job_title               NVARCHAR(256)   NULL,
    phone                   NVARCHAR(50)    NULL,
    time_zone               NVARCHAR(100)   NULL,
    roles                   NVARCHAR(500)   NULL,
    is_active               BIT             NULL,
    deactivated_at          NVARCHAR(50)    NULL,
    first_name              NVARCHAR(128)   NULL,
    last_name               NVARCHAR(128)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    manager                 NVARCHAR(256)   NULL,
    employee_number         NVARCHAR(50)    NULL,
    user_type               NVARCHAR(100)   NULL,
    country                 NVARCHAR(100)   NULL,
    division                NVARCHAR(256)   NULL,
    display_name            NVARCHAR(256)   NULL,
    time_zone_rc            NVARCHAR(100)   NULL,
    proficiency_score       FLOAT           NULL,
    susceptibility_percent  FLOAT           NULL,
    reporting_percent       FLOAT           NULL,
    risk_band               NVARCHAR(50)    NULL,
    proficiency_band        NVARCHAR(50)    NULL,
    scenarios_received      INT             NULL,
    full_name               NVARCHAR(256)   NULL,
    is_third_party          BIT             NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash            NVARCHAR(64)    NULL,
    stg_cdc_action          NVARCHAR(20)    NULL,
    stg_loaded_at           DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.dim_user','U') IS NOT NULL DROP TABLE phishme_security.dim_user;
GO
CREATE TABLE phishme_security.dim_user
(
    email                   NVARCHAR(256)   NOT NULL,
    name                    NVARCHAR(256)   NULL,
    job_title               NVARCHAR(256)   NULL,
    phone                   NVARCHAR(50)    NULL,
    time_zone               NVARCHAR(100)   NULL,
    roles                   NVARCHAR(500)   NULL,
    is_active               BIT             NULL,
    deactivated_at          NVARCHAR(50)    NULL,
    first_name              NVARCHAR(128)   NULL,
    last_name               NVARCHAR(128)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    manager                 NVARCHAR(256)   NULL,
    employee_number         NVARCHAR(50)    NULL,
    user_type               NVARCHAR(100)   NULL,
    country                 NVARCHAR(100)   NULL,
    division                NVARCHAR(256)   NULL,
    display_name            NVARCHAR(256)   NULL,
    time_zone_rc            NVARCHAR(100)   NULL,
    proficiency_score       FLOAT           NULL,
    susceptibility_percent  FLOAT           NULL,
    reporting_percent       FLOAT           NULL,
    risk_band               NVARCHAR(50)    NULL,
    proficiency_band        NVARCHAR(50)    NULL,
    scenarios_received      INT             NULL,
    full_name               NVARCHAR(256)   NULL,
    is_third_party          BIT             NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 3. dim_scenario
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.dim_scenario','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.dim_scenario;
GO
CREATE TABLE zzSTG_phishme_security.dim_scenario
(
    scenario_id             NVARCHAR(256)   NULL,
    scenario_name           NVARCHAR(500)   NULL,
    status                  NVARCHAR(50)    NULL,
    scenario_type           NVARCHAR(100)   NULL,
    starts_at               DATETIME2       NULL,
    ends_at                 DATETIME2       NULL,
    duration_days           INT             NULL,
    total_recipients        INT             NULL,
    emails_sent             INT             NULL,
    emails_reported         INT             NULL,
    emails_clicked          INT             NULL,
    emails_opened           INT             NULL,
    attachments_opened      INT             NULL,
    data_entered            INT             NULL,
    scenario_group_id       NVARCHAR(256)   NULL,
    scenario_group_name     NVARCHAR(500)   NULL,
    is_active               BIT             NULL,
    click_rate_pct          FLOAT           NULL,
    report_rate_pct         FLOAT           NULL,
    open_rate_pct           FLOAT           NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash            NVARCHAR(64)    NULL,
    stg_cdc_action          NVARCHAR(20)    NULL,
    stg_loaded_at           DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.dim_scenario','U') IS NOT NULL DROP TABLE phishme_security.dim_scenario;
GO
CREATE TABLE phishme_security.dim_scenario
(
    scenario_id             NVARCHAR(256)   NOT NULL,
    scenario_name           NVARCHAR(500)   NULL,
    status                  NVARCHAR(50)    NULL,
    scenario_type           NVARCHAR(100)   NULL,
    starts_at               DATETIME2       NULL,
    ends_at                 DATETIME2       NULL,
    duration_days           INT             NULL,
    total_recipients        INT             NULL,
    emails_sent             INT             NULL,
    emails_reported         INT             NULL,
    emails_clicked          INT             NULL,
    emails_opened           INT             NULL,
    attachments_opened      INT             NULL,
    data_entered            INT             NULL,
    scenario_group_id       NVARCHAR(256)   NULL,
    scenario_group_name     NVARCHAR(500)   NULL,
    is_active               BIT             NULL,
    click_rate_pct          FLOAT           NULL,
    report_rate_pct         FLOAT           NULL,
    open_rate_pct           FLOAT           NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 4. fact_phishing_responses
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.fact_phishing_responses','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.fact_phishing_responses;
GO
CREATE TABLE zzSTG_phishme_security.fact_phishing_responses
(
    email                   NVARCHAR(256)   NULL,
    scenario_id             NVARCHAR(256)   NULL,
    recipient_name          NVARCHAR(256)   NULL,
    recipient_group         NVARCHAR(256)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    opened_email            BIT             NULL,
    opened_email_at         DATETIME2       NULL,
    viewed_education        BIT             NULL,
    viewed_education_at     DATETIME2       NULL,
    reported_phish          BIT             NULL,
    reporter_type           NVARCHAR(100)   NULL,
    reported_phish_at       DATETIME2       NULL,
    time_to_report_secs     BIGINT          NULL,
    remote_ip               NVARCHAR(50)    NULL,
    geo_country             NVARCHAR(100)   NULL,
    geo_city                NVARCHAR(100)   NULL,
    geo_isp                 NVARCHAR(256)   NULL,
    last_email_status       NVARCHAR(100)   NULL,
    is_mobile               BIT             NULL,
    browser                 NVARCHAR(256)   NULL,
    ingested_date           DATE            NULL,
    clicked_not_reported    BIT             NULL,
    educated_after_click    BIT             NULL,
    time_to_report_mins     FLOAT           NULL,
    response_category       NVARCHAR(100)   NULL,
    ingested_at             DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash            NVARCHAR(64)    NULL,
    stg_cdc_action          NVARCHAR(20)    NULL,
    stg_loaded_at           DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.fact_phishing_responses','U') IS NOT NULL DROP TABLE phishme_security.fact_phishing_responses;
GO
CREATE TABLE phishme_security.fact_phishing_responses
(
    email                   NVARCHAR(256)   NOT NULL,
    scenario_id             NVARCHAR(256)   NOT NULL,
    recipient_name          NVARCHAR(256)   NULL,
    recipient_group         NVARCHAR(256)   NULL,
    department              NVARCHAR(256)   NULL,
    location                NVARCHAR(256)   NULL,
    opened_email            BIT             NULL,
    opened_email_at         DATETIME2       NULL,
    viewed_education        BIT             NULL,
    viewed_education_at     DATETIME2       NULL,
    reported_phish          BIT             NULL,
    reporter_type           NVARCHAR(100)   NULL,
    reported_phish_at       DATETIME2       NULL,
    time_to_report_secs     BIGINT          NULL,
    remote_ip               NVARCHAR(50)    NULL,
    geo_country             NVARCHAR(100)   NULL,
    geo_city                NVARCHAR(100)   NULL,
    geo_isp                 NVARCHAR(256)   NULL,
    last_email_status       NVARCHAR(100)   NULL,
    is_mobile               BIT             NULL,
    browser                 NVARCHAR(256)   NULL,
    ingested_date           DATE            NULL,
    clicked_not_reported    BIT             NULL,
    educated_after_click    BIT             NULL,
    time_to_report_mins     FLOAT           NULL,
    response_category       NVARCHAR(100)   NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(email), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 5. fact_activity_timeline
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.fact_activity_timeline','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.fact_activity_timeline;
GO
CREATE TABLE zzSTG_phishme_security.fact_activity_timeline
(
    email               NVARCHAR(256)   NULL,
    scenario_id         NVARCHAR(256)   NULL,
    tracking_id         NVARCHAR(256)   NULL,
    event_timestamp     DATETIME2       NULL,
    event_date          DATE            NULL,
    action              NVARCHAR(256)   NULL,
    recipient_group     NVARCHAR(256)   NULL,
    remote_ip           NVARCHAR(50)    NULL,
    country             NVARCHAR(100)   NULL,
    city                NVARCHAR(100)   NULL,
    isp                 NVARCHAR(256)   NULL,
    browser             NVARCHAR(256)   NULL,
    user_agent          NVARCHAR(500)   NULL,
    is_mobile           BIT             NULL,
    is_email_client     BIT             NULL,
    in_ua_charts        BIT             NULL,
    ingested_date       DATE            NULL,
    action_category     NVARCHAR(100)   NULL,
    is_suspicious       BIT             NULL,
    ingested_at         DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash        NVARCHAR(64)    NULL,
    stg_cdc_action      NVARCHAR(20)    NULL,
    stg_loaded_at       DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.fact_activity_timeline','U') IS NOT NULL DROP TABLE phishme_security.fact_activity_timeline;
GO
CREATE TABLE phishme_security.fact_activity_timeline
(
    email               NVARCHAR(256)   NOT NULL,
    scenario_id         NVARCHAR(256)   NULL,
    tracking_id         NVARCHAR(256)   NOT NULL,
    event_timestamp     DATETIME2       NOT NULL,
    event_date          DATE            NULL,
    action              NVARCHAR(256)   NULL,
    recipient_group     NVARCHAR(256)   NULL,
    remote_ip           NVARCHAR(50)    NULL,
    country             NVARCHAR(100)   NULL,
    city                NVARCHAR(100)   NULL,
    isp                 NVARCHAR(256)   NULL,
    browser             NVARCHAR(256)   NULL,
    user_agent          NVARCHAR(500)   NULL,
    is_mobile           BIT             NULL,
    is_email_client     BIT             NULL,
    in_ua_charts        BIT             NULL,
    ingested_date       DATE            NULL,
    action_category     NVARCHAR(100)   NULL,
    is_suspicious       BIT             NULL,
    ingested_at         DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(tracking_id), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 6. fact_activity_logs  (append-only)
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.fact_activity_logs','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.fact_activity_logs;
GO
CREATE TABLE zzSTG_phishme_security.fact_activity_logs
(
    [user]              NVARCHAR(256)   NULL,
    activity_name       NVARCHAR(256)   NULL,
    event_timestamp     DATETIME2       NULL,
    event_date          DATE            NULL,
    ip_address          NVARCHAR(50)    NULL,
    ingested_date       DATE            NULL,
    action_type         NVARCHAR(100)   NULL,
    ingested_at         DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash        NVARCHAR(64)    NULL,
    stg_cdc_action      NVARCHAR(20)    NULL,
    stg_loaded_at       DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.fact_activity_logs','U') IS NOT NULL DROP TABLE phishme_security.fact_activity_logs;
GO
CREATE TABLE phishme_security.fact_activity_logs
(
    [user]              NVARCHAR(256)   NOT NULL,
    activity_name       NVARCHAR(256)   NULL,
    event_timestamp     DATETIME2       NOT NULL,
    event_date          DATE            NULL,
    ip_address          NVARCHAR(50)    NULL,
    ingested_date       DATE            NULL,
    action_type         NVARCHAR(100)   NULL,
    ingested_at         DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([user]), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 7. agg_user_risk
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.agg_user_risk','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.agg_user_risk;
GO
CREATE TABLE zzSTG_phishme_security.agg_user_risk
(
    email                       NVARCHAR(256)   NULL,
    total_scenarios             BIGINT          NULL,
    total_emails_received       BIGINT          NULL,
    total_clicks                BIGINT          NULL,
    total_reports               BIGINT          NULL,
    total_educated              BIGINT          NULL,
    clicks_not_reported         BIGINT          NULL,
    avg_time_to_report_mins     FLOAT           NULL,
    first_click_at              DATETIME2       NULL,
    last_click_at               DATETIME2       NULL,
    click_rate_pct              FLOAT           NULL,
    report_rate_pct             FLOAT           NULL,
    education_rate_pct          FLOAT           NULL,
    user_risk_score             FLOAT           NULL,
    user_risk_label             NVARCHAR(50)    NULL,
    full_name                   NVARCHAR(256)   NULL,
    department                  NVARCHAR(256)   NULL,
    location                    NVARCHAR(256)   NULL,
    job_title                   NVARCHAR(256)   NULL,
    manager                     NVARCHAR(256)   NULL,
    country                     NVARCHAR(100)   NULL,
    division                    NVARCHAR(256)   NULL,
    is_active                   BIT             NULL,
    is_third_party              BIT             NULL,
    risk_band                   NVARCHAR(50)    NULL,
    proficiency_band            NVARCHAR(50)    NULL,
    proficiency_score           FLOAT           NULL,
    ingested_date               DATE            NULL,
    ingested_at                 DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash                NVARCHAR(64)    NULL,
    stg_cdc_action              NVARCHAR(20)    NULL,
    stg_loaded_at               DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.agg_user_risk','U') IS NOT NULL DROP TABLE phishme_security.agg_user_risk;
GO
CREATE TABLE phishme_security.agg_user_risk
(
    email                       NVARCHAR(256)   NOT NULL,
    total_scenarios             BIGINT          NULL,
    total_emails_received       BIGINT          NULL,
    total_clicks                BIGINT          NULL,
    total_reports               BIGINT          NULL,
    total_educated              BIGINT          NULL,
    clicks_not_reported         BIGINT          NULL,
    avg_time_to_report_mins     FLOAT           NULL,
    first_click_at              DATETIME2       NULL,
    last_click_at               DATETIME2       NULL,
    click_rate_pct              FLOAT           NULL,
    report_rate_pct             FLOAT           NULL,
    education_rate_pct          FLOAT           NULL,
    user_risk_score             FLOAT           NULL,
    user_risk_label             NVARCHAR(50)    NULL,
    full_name                   NVARCHAR(256)   NULL,
    department                  NVARCHAR(256)   NULL,
    location                    NVARCHAR(256)   NULL,
    job_title                   NVARCHAR(256)   NULL,
    manager                     NVARCHAR(256)   NULL,
    country                     NVARCHAR(100)   NULL,
    division                    NVARCHAR(256)   NULL,
    is_active                   BIT             NULL,
    is_third_party              BIT             NULL,
    risk_band                   NVARCHAR(50)    NULL,
    proficiency_band            NVARCHAR(50)    NULL,
    proficiency_score           FLOAT           NULL,
    ingested_date               DATE            NULL,
    ingested_at                 DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(email), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 8. agg_scenario_performance
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.agg_scenario_performance','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.agg_scenario_performance;
GO
CREATE TABLE zzSTG_phishme_security.agg_scenario_performance
(
    scenario_id                 NVARCHAR(256)   NULL,
    unique_recipients           BIGINT          NULL,
    total_clicks                BIGINT          NULL,
    total_reports               BIGINT          NULL,
    total_educated              BIGINT          NULL,
    clicked_not_reported        BIGINT          NULL,
    avg_time_to_report_mins     FLOAT           NULL,
    no_action_count             BIGINT          NULL,
    click_rate_pct              FLOAT           NULL,
    report_rate_pct             FLOAT           NULL,
    education_rate_pct          FLOAT           NULL,
    resilience_score            FLOAT           NULL,
    scenario_name               NVARCHAR(500)   NULL,
    scenario_type               NVARCHAR(100)   NULL,
    starts_at                   DATETIME2       NULL,
    ends_at                     DATETIME2       NULL,
    duration_days               INT             NULL,
    status                      NVARCHAR(50)    NULL,
    ingested_date               DATE            NULL,
    ingested_at                 DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash                NVARCHAR(64)    NULL,
    stg_cdc_action              NVARCHAR(20)    NULL,
    stg_loaded_at               DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.agg_scenario_performance','U') IS NOT NULL DROP TABLE phishme_security.agg_scenario_performance;
GO
CREATE TABLE phishme_security.agg_scenario_performance
(
    scenario_id                 NVARCHAR(256)   NOT NULL,
    unique_recipients           BIGINT          NULL,
    total_clicks                BIGINT          NULL,
    total_reports               BIGINT          NULL,
    total_educated              BIGINT          NULL,
    clicked_not_reported        BIGINT          NULL,
    avg_time_to_report_mins     FLOAT           NULL,
    no_action_count             BIGINT          NULL,
    click_rate_pct              FLOAT           NULL,
    report_rate_pct             FLOAT           NULL,
    education_rate_pct          FLOAT           NULL,
    resilience_score            FLOAT           NULL,
    scenario_name               NVARCHAR(500)   NULL,
    scenario_type               NVARCHAR(100)   NULL,
    starts_at                   DATETIME2       NULL,
    ends_at                     DATETIME2       NULL,
    duration_days               INT             NULL,
    status                      NVARCHAR(50)    NULL,
    ingested_date               DATE            NULL,
    ingested_at                 DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 9. agg_department_risk
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.agg_department_risk','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.agg_department_risk;
GO
CREATE TABLE zzSTG_phishme_security.agg_department_risk
(
    department              NVARCHAR(256)   NULL,
    total_users             BIGINT          NULL,
    avg_click_rate_pct      FLOAT           NULL,
    avg_report_rate_pct     FLOAT           NULL,
    avg_education_rate_pct  FLOAT           NULL,
    avg_risk_score          FLOAT           NULL,
    critical_users          BIGINT          NULL,
    high_risk_users         BIGINT          NULL,
    medium_risk_users       BIGINT          NULL,
    low_risk_users          BIGINT          NULL,
    dept_risk_label         NVARCHAR(50)    NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash            NVARCHAR(64)    NULL,
    stg_cdc_action          NVARCHAR(20)    NULL,
    stg_loaded_at           DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.agg_department_risk','U') IS NOT NULL DROP TABLE phishme_security.agg_department_risk;
GO
CREATE TABLE phishme_security.agg_department_risk
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
    dept_risk_label         NVARCHAR(50)    NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 10. agg_monthly_trend
-- ============================================================
IF OBJECT_ID('zzSTG_phishme_security.agg_monthly_trend','U') IS NOT NULL DROP TABLE zzSTG_phishme_security.agg_monthly_trend;
GO
CREATE TABLE zzSTG_phishme_security.agg_monthly_trend
(
    yyyymm                  NVARCHAR(10)    NULL,
    year                    NVARCHAR(10)    NULL,
    month                   NVARCHAR(10)    NULL,
    scenario_id             NVARCHAR(256)   NULL,
    unique_users            BIGINT          NULL,
    total_events            BIGINT          NULL,
    clicks                  BIGINT          NULL,
    reports                 BIGINT          NULL,
    educations              BIGINT          NULL,
    data_entries            BIGINT          NULL,
    suspicious_events       BIGINT          NULL,
    click_to_report_ratio   FLOAT           NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL,
    -- CDC control columns
    stg_row_hash            NVARCHAR(64)    NULL,
    stg_cdc_action          NVARCHAR(20)    NULL,
    stg_loaded_at           DATETIME        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

IF OBJECT_ID('phishme_security.agg_monthly_trend','U') IS NOT NULL DROP TABLE phishme_security.agg_monthly_trend;
GO
CREATE TABLE phishme_security.agg_monthly_trend
(
    yyyymm                  NVARCHAR(10)    NOT NULL,
    year                    NVARCHAR(10)    NULL,
    month                   NVARCHAR(10)    NULL,
    scenario_id             NVARCHAR(256)   NOT NULL,
    unique_users            BIGINT          NULL,
    total_events            BIGINT          NULL,
    clicks                  BIGINT          NULL,
    reports                 BIGINT          NULL,
    educations              BIGINT          NULL,
    data_entries            BIGINT          NULL,
    suspicious_events       BIGINT          NULL,
    click_to_report_ratio   FLOAT           NULL,
    ingested_date           DATE            NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(scenario_id), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- VERIFY
-- ============================================================
SELECT
    s.name      AS schema_name,
    t.name      AS table_name,
    p.rows      AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE s.name IN ('zzSTG_phishme_security','phishme_security')
  AND t.name != 'watermark'
ORDER BY s.name, t.name;
GO

PRINT '=============================================='
PRINT 'DDL complete: 10 staging + 10 target tables'
PRINT 'Schemas: zzSTG_phishme_security, phishme_security'
PRINT '=============================================='
GO