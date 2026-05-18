-- ============================================================
-- SEPLAT ENERGY — PhishMe Security Analytics
-- Azure Synapse Analytics — Schema & Watermark Table
-- Database : seplat_edw
-- Schema   : phishme_security
-- Author   : Data Engineering
-- Created  : 2026-03-13
-- ============================================================

USE seplat_edw;
GO

-- ============================================================
-- 1. CREATE SCHEMA
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.schemas WHERE name = 'phishme_security'
)
BEGIN
    EXEC('CREATE SCHEMA phishme_security AUTHORIZATION dbo')
    PRINT 'Schema [phishme_security] created successfully.'
END
ELSE
BEGIN
    PRINT 'Schema [phishme_security] already exists — skipped.'
END
GO

-- ============================================================
-- 2. WATERMARK TABLE
-- Note: Synapse DEFAULT only accepts literal constants.
--       created_at / updated_at are set explicitly in INSERT/UPDATE.
-- ============================================================
IF OBJECT_ID('phishme_security.watermark', 'U') IS NOT NULL
    DROP TABLE phishme_security.watermark;
GO

CREATE TABLE phishme_security.watermark
(
    watermark_id            INT             NOT NULL,
    schema_name             NVARCHAR(128)   NOT NULL,
    table_name              NVARCHAR(256)   NOT NULL,
    last_load_date          DATE            NOT NULL,
    last_load_timestamp     DATETIME        NOT NULL,
    last_load_status        NVARCHAR(20)    NOT NULL,
    rows_extracted          BIGINT          NULL,
    rows_loaded             BIGINT          NULL,
    rows_rejected           BIGINT          NULL,
    source_path             NVARCHAR(500)   NULL,
    source_file_count       INT             NULL,
    source_size_bytes       BIGINT          NULL,
    pipeline_name           NVARCHAR(256)   NULL,
    pipeline_run_id         NVARCHAR(128)   NULL,
    triggered_by            NVARCHAR(128)   NULL,
    error_message           NVARCHAR(400)   NULL,
    error_code              NVARCHAR(50)    NULL,
    created_at              DATETIME        NOT NULL,
    updated_at              DATETIME        NOT NULL
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO
-- ============================================================
-- 3. SEED WATERMARK — created_at / updated_at set explicitly
-- ============================================================
INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 1,'phishme_security','dim_date','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_date','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 2,'phishme_security','dim_user','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_user','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 3,'phishme_security','dim_scenario','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_scenario','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 4,'phishme_security','fact_phishing_responses','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_phishing_responses','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 5,'phishme_security','fact_activity_timeline','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_activity_timeline','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 6,'phishme_security','fact_activity_logs','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_activity_logs','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 7,'phishme_security','agg_user_risk','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_user_risk','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 8,'phishme_security','agg_scenario_performance','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_scenario_performance','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 9,'phishme_security','agg_department_risk','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_department_risk','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 10,'phishme_security','agg_monthly_trend','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_monthly_trend','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();
GO
-- ============================================================
-- 4. STORED PROCEDURES
-- ============================================================

-- 4a. Get watermark
IF OBJECT_ID('phishme_security.usp_get_watermark', 'P') IS NOT NULL
    DROP PROCEDURE phishme_security.usp_get_watermark;
GO

CREATE PROCEDURE phishme_security.usp_get_watermark
    @table_name NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        watermark_id,
        schema_name,
        table_name,
        schema_name + '.' + table_name AS full_table_name,
        last_load_date,
        last_load_timestamp,
        last_load_status,
        rows_loaded,
        source_path
    FROM phishme_security.watermark
    WHERE table_name  = @table_name
      AND schema_name = 'phishme_security';
END;
GO

-- 4b. Set watermark
IF OBJECT_ID('phishme_security.usp_set_watermark', 'P') IS NOT NULL
    DROP PROCEDURE phishme_security.usp_set_watermark;
GO

CREATE PROCEDURE phishme_security.usp_set_watermark
    @table_name         NVARCHAR(256),
    @load_date          DATE,
    @load_timestamp     DATETIME,
    @load_status        NVARCHAR(20),
    @rows_extracted     BIGINT,
    @rows_loaded        BIGINT,
    @rows_rejected      BIGINT,
    @source_path        NVARCHAR(500),
    @source_file_count  INT,
    @source_size_bytes  BIGINT,
    @pipeline_name      NVARCHAR(256),
    @pipeline_run_id    NVARCHAR(128),
    @triggered_by       NVARCHAR(128),
    @error_message      NVARCHAR(400),
    @error_code         NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE phishme_security.watermark
    SET
        last_load_date      = @load_date,
        last_load_timestamp = @load_timestamp,
        last_load_status    = @load_status,
        rows_extracted      = COALESCE(@rows_extracted,    rows_extracted),
        rows_loaded         = COALESCE(@rows_loaded,       rows_loaded),
        rows_rejected       = COALESCE(@rows_rejected,     rows_rejected),
        source_path         = COALESCE(@source_path,       source_path),
        source_file_count   = COALESCE(@source_file_count, source_file_count),
        source_size_bytes   = COALESCE(@source_size_bytes, source_size_bytes),
        pipeline_name       = COALESCE(@pipeline_name,     pipeline_name),
        pipeline_run_id     = @pipeline_run_id,
        triggered_by        = COALESCE(@triggered_by,      triggered_by),
        error_message       = @error_message,
        error_code          = @error_code,
        updated_at          = GETDATE()
    WHERE table_name  = @table_name
      AND schema_name = 'phishme_security';
END;
GO

-- ============================================================
-- 5. VERIFY
-- ============================================================
SELECT
    watermark_id,
    schema_name + '.' + table_name     AS full_table_name,
    last_load_date,
    last_load_status,
    source_path,
    created_at
FROM phishme_security.watermark
ORDER BY watermark_id;
GO

PRINT '=============================================='
PRINT 'Schema [phishme_security] setup complete.'
PRINT 'Watermark seeded with 10 tables.'
PRINT 'Procedures: usp_get_watermark, usp_set_watermark'
PRINT '=============================================='
GO