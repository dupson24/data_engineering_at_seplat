-- ============================================================
-- ASA: EAM Supplier Details — Full DDL + Stored Procedure
-- Schema  : offshore_eam (target) | zzSTG_offshore_eam (staging)
-- ============================================================

-- ============================================================
-- STEP 1 — Staging table (ROUND_ROBIN HEAP)
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[supplier_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[supplier_details];

CREATE TABLE [zzSTG_offshore_eam].[supplier_details]
(
    [Supplier_Code]                 NVARCHAR(50)    NULL,
    [Supplier_Description]          NVARCHAR(255)   NULL,
    [Supplier_Phone]                NVARCHAR(50)    NULL,
    [Supplier_Fax]                  NVARCHAR(50)    NULL,
    [Supplier_Email]                NVARCHAR(255)   NULL,
    [Supplier_Contact]              NVARCHAR(100)   NULL,
    [Supplier_Address]              NVARCHAR(255)   NULL,
    [Supplier_City]                 NVARCHAR(100)   NULL,
    [Supplier_Country]              NVARCHAR(10)    NULL,
    [Supplier_Region]               NVARCHAR(50)    NULL,
    [Supplier_Status]               NVARCHAR(20)    NULL,
    [Supplier_Type_Account_Group]   NVARCHAR(20)    NULL,
    [Supplier_Tax_Number]           NVARCHAR(50)    NULL,
    [Supplier_VAT_Number]           NVARCHAR(50)    NULL,
    [Supplier_Purchase_Org]         NVARCHAR(20)    NULL,
    [Supplier_Currency]             NVARCHAR(10)    NULL,
    [Supplier_Payment_Terms]        NVARCHAR(20)    NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
);


-- ============================================================
-- STEP 2 — Target table (HASH + CLUSTERED COLUMNSTORE)
-- ============================================================
IF OBJECT_ID('[offshore_eam].[supplier_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[supplier_details];

CREATE TABLE [offshore_eam].[supplier_details]
(
    [Supplier_Code]                 NVARCHAR(50)    NOT NULL,
    [Supplier_Description]          NVARCHAR(255)   NULL,
    [Supplier_Phone]                NVARCHAR(50)    NULL,
    [Supplier_Fax]                  NVARCHAR(50)    NULL,
    [Supplier_Email]                NVARCHAR(255)   NULL,
    [Supplier_Contact]              NVARCHAR(100)   NULL,
    [Supplier_Address]              NVARCHAR(255)   NULL,
    [Supplier_City]                 NVARCHAR(100)   NULL,
    [Supplier_Country]              NVARCHAR(10)    NULL,
    [Supplier_Region]               NVARCHAR(50)    NULL,
    [Supplier_Status]               NVARCHAR(20)    NULL,
    [Supplier_Type_Account_Group]   NVARCHAR(20)    NULL,
    [Supplier_Tax_Number]           NVARCHAR(50)    NULL,
    [Supplier_VAT_Number]           NVARCHAR(50)    NULL,
    [Supplier_Purchase_Org]         NVARCHAR(20)    NULL,
    [Supplier_Currency]             NVARCHAR(10)    NULL,
    [Supplier_Payment_Terms]        NVARCHAR(20)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH
(
    DISTRIBUTION = HASH([Supplier_Code]),
    CLUSTERED COLUMNSTORE INDEX
);


-- ============================================================
-- STEP 3 — Stored procedure: upsert staging → target
-- ============================================================
IF OBJECT_ID('[dbo].[usp_offshore_eam_supplier_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_supplier_details];
GO

CREATE PROCEDURE [dbo].[usp_offshore_eam_supplier_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN

    -- Step A: delete matched rows from target
    DELETE [offshore_eam].[supplier_details]
    WHERE [Supplier_Code] IN
    (
        SELECT [Supplier_Code]
        FROM   [zzSTG_offshore_eam].[supplier_details]
        WHERE  [Supplier_Code] IS NOT NULL
    );

    -- Step B: insert staging rows into target with metadata
    INSERT INTO [offshore_eam].[supplier_details]
    (
        [Supplier_Code],
        [Supplier_Description],
        [Supplier_Phone],
        [Supplier_Fax],
        [Supplier_Email],
        [Supplier_Contact],
        [Supplier_Address],
        [Supplier_City],
        [Supplier_Country],
        [Supplier_Region],
        [Supplier_Status],
        [Supplier_Type_Account_Group],
        [Supplier_Tax_Number],
        [Supplier_VAT_Number],
        [Supplier_Purchase_Org],
        [Supplier_Currency],
        [Supplier_Payment_Terms],
        [load_id],
        [pipeline_run_id],
        [source_path],
        [loaded_at],
        [updated_at]
    )
    SELECT
        [Supplier_Code],
        [Supplier_Description],
        [Supplier_Phone],
        [Supplier_Fax],
        [Supplier_Email],
        [Supplier_Contact],
        [Supplier_Address],
        [Supplier_City],
        [Supplier_Country],
        [Supplier_Region],
        [Supplier_Status],
        [Supplier_Type_Account_Group],
        [Supplier_Tax_Number],
        [Supplier_VAT_Number],
        [Supplier_Purchase_Org],
        [Supplier_Currency],
        [Supplier_Payment_Terms],
        @load_id,
        @pipeline_run_id,
        @source_path,
        GETDATE(),
        GETDATE()
    FROM [zzSTG_offshore_eam].[supplier_details]
    WHERE [Supplier_Code] IS NOT NULL;

    -- Step C: truncate staging after successful load
    TRUNCATE TABLE [zzSTG_offshore_eam].[supplier_details];

END;
GO


-- ============================================================
-- STEP 4 — Add watermark row
-- ============================================================
DECLARE @now    DATETIME2    = GETDATE();
DECLARE @table  NVARCHAR(200)= 'supplier_details';
DECLARE @schema NVARCHAR(100)= 'offshore_eam';
DECLARE @sp     NVARCHAR(300)= CONCAT('[dbo].[usp_', @schema, '_', @table, ']');

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES
    (@table, @schema, 'SAP_ECC_LFA1_LFM1_LFM2', @sp,
     '1900-01-01 00:00:00', 'initial', 0, NULL, @now);


-- ============================================================
-- STEP 5 — Validation queries
-- ============================================================
-- SELECT COUNT(*) AS stg_rows FROM [zzSTG_offshore_eam].[supplier_details];
-- SELECT COUNT(*) AS tgt_rows FROM [offshore_eam].[supplier_details];
-- SELECT * FROM [offshore_eam].[watermark] WHERE table_name = 'supplier_details';
-- SELECT TOP 20 * FROM [offshore_eam].[supplier_details] ORDER BY loaded_at DESC;