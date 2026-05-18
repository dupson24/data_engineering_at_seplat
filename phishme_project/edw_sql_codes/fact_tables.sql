-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Fact Target Tables only — NVARCHAR(4000) for columnstore
-- Staging tables unchanged (NVARCHAR(MAX) ok on HEAP)
-- ingested_date removed from all tables
-- Database : seplat_edw
-- Date     : 2026-03-13
-- ============================================================

USE seplat_edw;
GO


-- ============================================================
-- 1. fact_phishing_responses — TARGET ONLY
-- ============================================================
IF OBJECT_ID('phishme_security.fact_phishing_responses','U') IS NOT NULL
    DROP TABLE phishme_security.fact_phishing_responses;
GO
CREATE TABLE phishme_security.fact_phishing_responses
(
    email                   NVARCHAR(256)   NOT NULL,
    scenario_id             NVARCHAR(256)   NOT NULL,
    recipient_name          NVARCHAR(4000)  NULL,
    recipient_group         NVARCHAR(4000)  NULL,
    department              NVARCHAR(4000)  NULL,
    location                NVARCHAR(4000)  NULL,
    opened_email            BIT             NULL,
    opened_email_at         DATETIME2       NULL,
    viewed_education        BIT             NULL,
    viewed_education_at     DATETIME2       NULL,
    reported_phish          BIT             NULL,
    reporter_type           NVARCHAR(4000)  NULL,
    reported_phish_at       DATETIME2       NULL,
    time_to_report_secs     BIGINT          NULL,
    remote_ip               NVARCHAR(4000)  NULL,
    geo_country             NVARCHAR(4000)  NULL,
    geo_city                NVARCHAR(4000)  NULL,
    geo_isp                 NVARCHAR(4000)  NULL,
    last_email_status       NVARCHAR(4000)  NULL,
    is_mobile               BIT             NULL,
    browser                 NVARCHAR(4000)  NULL,
    clicked_not_reported    BIT             NULL,
    educated_after_click    BIT             NULL,
    time_to_report_mins     FLOAT           NULL,
    response_category       NVARCHAR(4000)  NULL,
    ingested_at             DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(email), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 2. fact_activity_timeline — TARGET ONLY
-- ============================================================
IF OBJECT_ID('phishme_security.fact_activity_timeline','U') IS NOT NULL
    DROP TABLE phishme_security.fact_activity_timeline;
GO
CREATE TABLE phishme_security.fact_activity_timeline
(
    email               NVARCHAR(256)   NOT NULL,
    scenario_id         NVARCHAR(256)   NULL,
    tracking_id         NVARCHAR(256)   NOT NULL,
    event_timestamp     DATETIME2       NOT NULL,
    event_date          DATE            NULL,
    action              NVARCHAR(4000)  NULL,
    recipient_group     NVARCHAR(4000)  NULL,
    remote_ip           NVARCHAR(4000)  NULL,
    country             NVARCHAR(4000)  NULL,
    city                NVARCHAR(4000)  NULL,
    isp                 NVARCHAR(4000)  NULL,
    browser             NVARCHAR(4000)  NULL,
    user_agent          NVARCHAR(4000)  NULL,
    is_mobile           BIT             NULL,
    is_email_client     BIT             NULL,
    in_ua_charts        BIT             NULL,
    action_category     NVARCHAR(4000)  NULL,
    is_suspicious       BIT             NULL,
    ingested_at         DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH(tracking_id), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- 3. fact_activity_logs — TARGET ONLY
-- ============================================================
IF OBJECT_ID('phishme_security.fact_activity_logs','U') IS NOT NULL
    DROP TABLE phishme_security.fact_activity_logs;
GO
CREATE TABLE phishme_security.fact_activity_logs
(
    [user]              NVARCHAR(256)   NOT NULL,
    activity_name       NVARCHAR(4000)  NULL,
    event_timestamp     DATETIME2       NOT NULL,
    event_date          DATE            NULL,
    ip_address          NVARCHAR(4000)  NULL,
    action_type         NVARCHAR(4000)  NULL,
    ingested_at         DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([user]), CLUSTERED COLUMNSTORE INDEX);
GO


-- ============================================================
-- VERIFY
-- ============================================================
SELECT TABLE_SCHEMA, TABLE_NAME, COUNT(*) AS col_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'phishme_security'
AND TABLE_NAME IN ('fact_phishing_responses','fact_activity_timeline','fact_activity_logs')
GROUP BY TABLE_SCHEMA, TABLE_NAME
ORDER BY TABLE_NAME;
GO

PRINT 'Done — 3 fact target tables recreated with NVARCHAR(4000)';
GO