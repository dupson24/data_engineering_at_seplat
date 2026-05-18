-- ============================================================
-- STEP 4 — Watermark table
-- ============================================================
IF OBJECT_ID('[offshore_eam].[watermark]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[watermark];

CREATE TABLE [offshore_eam].[watermark]
(
    [table_name]        NVARCHAR(200)   NOT NULL,
    [schema_name]       NVARCHAR(100)   NOT NULL,
    [source_system]     NVARCHAR(100)   NOT NULL,
    [last_load_date]    DATETIME2       NULL,
    [last_load_type]    NVARCHAR(20)    NULL,
    [last_row_count]    BIGINT          NULL,
    [last_pipeline_run] NVARCHAR(100)   NULL,
    [updated_at]        DATETIME2       NULL
)
WITH
(
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- Seed watermark row
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[last_load_date],
     [last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES
    ('employee_details','offshore_eam','SAP_ECC_PA0002_PA0105',
     '1900-01-01 00:00:00','initial',0,NULL,@now);


-- ============================================================
-- Stored Procedure: usp_offshore_eam_update_watermark
-- ============================================================
IF OBJECT_ID('[dbo].[usp_offshore_eam_update_watermark]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_update_watermark];
GO

CREATE PROCEDURE [dbo].[usp_offshore_eam_update_watermark]
    @table_name         NVARCHAR(200),
    @schema_name        NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @load_type          NVARCHAR(20)      -- pass 'initial' or 'delta' from ADF
AS
BEGIN

    DECLARE @now        DATETIME2 = GETDATE();
    DECLARE @row_count  BIGINT;

    SELECT @row_count = COUNT(*)
    FROM   [offshore_eam].[employee_details];

    UPDATE [offshore_eam].[watermark]
    SET
        [last_load_date]    = @now,
        [last_load_type]    = @load_type,
        [last_row_count]    = @row_count,
        [last_pipeline_run] = @pipeline_run_id,
        [updated_at]        = @now
    WHERE [table_name]  = @table_name
      AND [schema_name] = @schema_name;

END;
GO