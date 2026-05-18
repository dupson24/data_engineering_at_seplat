-- ============================================================
-- ASA: EAM Employee Details — Full DDL + Stored Procedure
-- Schema  : offshore_eam  (target) | zzSTG_offshore_eam (staging)
-- ============================================================

-- ============================================================
-- STEP 1 — Create schemas
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'offshore_eam')
    EXEC('CREATE SCHEMA [offshore_eam]');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'zzSTG_offshore_eam')
    EXEC('CREATE SCHEMA [zzSTG_offshore_eam]');


-- ============================================================
-- STEP 2 — Staging table (ROUND_ROBIN HEAP)
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[employee_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[employee_details];

CREATE TABLE [zzSTG_offshore_eam].[employee_details]
(
    [Employee_Code]             NVARCHAR(50)    NULL,
    [Employee_Description]      NVARCHAR(255)   NULL,
    [Employee_Job_Title]        NVARCHAR(255)   NULL,
    [Employee_Costcode]         NVARCHAR(50)    NULL,
    [Employee_Organization_Code]NVARCHAR(50)    NULL,
    [Employee_Payroll_Number]   NVARCHAR(50)    NULL,
    [Employee_User]             NVARCHAR(100)   NULL,
    [Employee_Hire_Date]        DATE            NULL,
    [Employee_Birthdate]        DATE            NULL,
    [Employee_Email_Address]    NVARCHAR(255)   NULL,
    [Employee_Country]          NVARCHAR(10)    NULL,
    [Employee_Gender]           NVARCHAR(10)    NULL,
    [Employee_Nationality]      NVARCHAR(50)    NULL,
    [Employee_Terminated_Date]  NVARCHAR(50)    NULL,
    [load_id]                   NVARCHAR(100)   NULL,
    [pipeline_run_id]           NVARCHAR(100)   NULL,
    [source_path]               NVARCHAR(500)   NULL,
    [loaded_at]                 DATETIME2       NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
);


-- ============================================================
-- STEP 3 — Target table (HASH distributed + CLUSTERED COLUMNSTORE)
-- ============================================================
IF OBJECT_ID('[offshore_eam].[employee_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[employee_details];

CREATE TABLE [offshore_eam].[employee_details]
(
    [Employee_Code]             NVARCHAR(50)    NOT NULL,
    [Employee_Description]      NVARCHAR(255)   NULL,
    [Employee_Job_Title]        NVARCHAR(255)   NULL,
    [Employee_Costcode]         NVARCHAR(50)    NULL,
    [Employee_Organization_Code]NVARCHAR(50)    NULL,
    [Employee_Payroll_Number]   NVARCHAR(50)    NULL,
    [Employee_User]             NVARCHAR(100)   NULL,
    [Employee_Hire_Date]        DATE            NULL,
    [Employee_Birthdate]        DATE            NULL,
    [Employee_Email_Address]    NVARCHAR(255)   NULL,
    [Employee_Country]          NVARCHAR(10)    NULL,
    [Employee_Gender]           NVARCHAR(10)    NULL,
    [Employee_Nationality]      NVARCHAR(50)    NULL,
    [Employee_Terminated_Date]  NVARCHAR(50)    NULL,
    [load_id]                   NVARCHAR(100)   NULL,
    [pipeline_run_id]           NVARCHAR(100)   NULL,
    [source_path]               NVARCHAR(500)   NULL,
    [loaded_at]                 DATETIME2       NULL,
    [updated_at]                DATETIME2       NULL
)
WITH
(
    DISTRIBUTION = HASH([Employee_Code]),
    CLUSTERED COLUMNSTORE INDEX
);


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
    [last_load_type]    NVARCHAR(20)    NULL,  -- 'initial' | 'delta'
    [last_row_count]    BIGINT          NULL,
    [last_pipeline_run] NVARCHAR(100)   NULL,
    [updated_at]        DATETIME2       NULL
)
WITH
(
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- Seed watermark row for employee_details
INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[last_load_date],
     [last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES
    ('employee_details','offshore_eam','SAP_ECC_PA0002_PA0105',
     '1900-01-01 00:00:00','initial',0,NULL,GETDATE());


-- ============================================================
-- STEP 5 — Stored procedure: upsert staging → target
-- ============================================================
IF OBJECT_ID('[dbo].[usp_offshore_eam_employee_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_employee_details];
GO

CREATE PROCEDURE [dbo].[usp_offshore_eam_employee_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN

    -- Step A: delete matched rows from target
    DELETE [offshore_eam].[employee_details]
    WHERE [Employee_Code] IN
    (
        SELECT [Employee_Code]
        FROM   [zzSTG_offshore_eam].[employee_details]
        WHERE  [Employee_Code] IS NOT NULL
    );

    -- Step B: insert staging rows into target with metadata from parameters
    INSERT INTO [offshore_eam].[employee_details]
    (
        [Employee_Code],
        [Employee_Description],
        [Employee_Job_Title],
        [Employee_Costcode],
        [Employee_Organization_Code],
        [Employee_Payroll_Number],
        [Employee_User],
        [Employee_Hire_Date],
        [Employee_Birthdate],
        [Employee_Email_Address],
        [Employee_Country],
        [Employee_Gender],
        [Employee_Nationality],
        [Employee_Terminated_Date],
        [load_id],
        [pipeline_run_id],
        [source_path],
        [loaded_at],
        [updated_at]
    )
    SELECT
        [Employee_Code],
        [Employee_Description],
        [Employee_Job_Title],
        [Employee_Costcode],
        [Employee_Organization_Code],
        [Employee_Payroll_Number],
        [Employee_User],
        [Employee_Hire_Date],
        [Employee_Birthdate],
        [Employee_Email_Address],
        [Employee_Country],
        [Employee_Gender],
        [Employee_Nationality],
        [Employee_Terminated_Date],
        @load_id,
        @pipeline_run_id,
        @source_path,
        GETDATE(),
        GETDATE()
    FROM [zzSTG_offshore_eam].[employee_details]
    WHERE [Employee_Code] IS NOT NULL;

    -- Step C: truncate staging after successful load
    TRUNCATE TABLE [zzSTG_offshore_eam].[employee_details];

END;
GO


-- ============================================================
-- STEP 6 — ADF Watermark Lookup query
-- Use this as the query in ADF Lookup activity
-- before the Copy activity to get last load date
-- ============================================================

-- ADF Lookup source query (paste into ADF Lookup activity):
/*
SELECT
    [table_name],
    [last_load_date],
    [last_load_type],
    [last_pipeline_run]
FROM [offshore_eam].[watermark]
WHERE [table_name]  = 'employee_details'
  AND [schema_name] = 'offshore_eam'
*/


-- ============================================================
-- STEP 7 — ADF Watermark Update query
-- Use this in ADF Stored Procedure activity
-- after the Copy activity to update the watermark
-- ============================================================

-- ADF Stored Procedure activity settings:
/*
Stored procedure name : [dbo].[usp_offshore_eam_employee_details]
Parameters:
    @load_id          = @{pipeline().RunId}
    @pipeline_run_id  = @{pipeline().RunId}
    @source_path      = @{pipeline().parameters.source_path}
*/


-- ============================================================
-- STEP 8 — Validation queries
-- ============================================================

-- Row counts
-- SELECT COUNT(*) AS stg_rows  FROM [zzSTG_offshore_eam].[employee_details];
-- SELECT COUNT(*) AS tgt_rows  FROM [offshore_eam].[employee_details];

-- Watermark check
-- SELECT * FROM [offshore_eam].[watermark] WHERE table_name = 'employee_details';

-- Null key check
-- SELECT COUNT(*) AS null_keys
-- FROM [offshore_eam].[employee_details]
-- WHERE [Employee_Code] IS NULL;

-- Sample data
-- SELECT TOP 20 * FROM [offshore_eam].[employee_details]
-- ORDER BY [loaded_at] DESC;