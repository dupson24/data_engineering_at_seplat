-- ============================================================
-- TABLE 1 — EKKN_PO_Account_Assignments (STAGING + TARGET)
-- Schema: offshore_sunsystems
-- ============================================================

-- 0) Ensure schemas exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'zzSTG_offshore_sunsystems')
    EXEC ('CREATE SCHEMA [zzSTG_offshore_sunsystems];');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'offshore_sunsystems')
    EXEC ('CREATE SCHEMA [offshore_sunsystems];');
GO

-- ============================================================
-- STAGING TABLE — zzSTG_offshore_sunsystems.EKKN_PO_Account_Assignments
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments];

CREATE TABLE [zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments]
(
    [Purchase_Order_Number]         NVARCHAR(20)     NULL,
    [Purchase_Order_Item_Number]    NVARCHAR(10)     NULL,
    [Account_Assignment_Seq]        NVARCHAR(10)     NULL,
    [Account_Assignment_Category]   NVARCHAR(10)     NULL,
    [Cost_Centre]                   NVARCHAR(20)     NULL,
    [Internal_Order]                NVARCHAR(20)     NULL,
    [WBS_Internal_Id]               NVARCHAR(50)     NULL,
    [GL_Account]                    NVARCHAR(20)     NULL,
    [Quantity]                      DECIMAL(13,3)    NULL,
    [Allocation_Percent]            FLOAT            NULL,   -- (double) in Spark -> FLOAT in Synapse
    [Allocation_Method]             NVARCHAR(50)     NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);
GO

-- ============================================================
-- TARGET TABLE — offshore_sunsystems.EKKN_PO_Account_Assignments
-- ============================================================
IF OBJECT_ID('[offshore_sunsystems].[EKKN_PO_Account_Assignments]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[EKKN_PO_Account_Assignments];

CREATE TABLE [offshore_sunsystems].[EKKN_PO_Account_Assignments]
(
    [Purchase_Order_Number]         NVARCHAR(20)     NOT NULL,
    [Purchase_Order_Item_Number]    NVARCHAR(10)     NOT NULL,
    [Account_Assignment_Seq]        NVARCHAR(10)     NOT NULL,

    [Account_Assignment_Category]   NVARCHAR(10)     NULL,
    [Cost_Centre]                   NVARCHAR(20)     NULL,
    [Internal_Order]                NVARCHAR(20)     NULL,
    [WBS_Internal_Id]               NVARCHAR(50)     NULL,
    [GL_Account]                    NVARCHAR(20)     NULL,
    [Quantity]                      DECIMAL(13,3)    NULL,
    [Allocation_Percent]            FLOAT            NULL,
    [Allocation_Method]             NVARCHAR(50)     NULL,

    [load_id]                       NVARCHAR(100)    NULL,
    [pipeline_run_id]               NVARCHAR(100)    NULL,
    [source_path]                   NVARCHAR(500)    NULL,
    [loaded_at]                     DATETIME2        NULL,
    [updated_at]                    DATETIME2        NULL
)
WITH
(
    DISTRIBUTION = HASH([Purchase_Order_Number]),
    CLUSTERED COLUMNSTORE INDEX
);
GO


-- ============================================================
-- STORED PROCEDURE — usp_offshore_sunsystems_EKKN_PO_Account_Assignments
-- ============================================================
IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_EKKN_PO_Account_Assignments]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_EKKN_PO_Account_Assignments];
GO

CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_EKKN_PO_Account_Assignments]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Delete matching keys from target based on staging keys
    DELETE tgt
    FROM [offshore_sunsystems].[EKKN_PO_Account_Assignments] tgt
    INNER JOIN [zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments] stg
        ON  tgt.[Purchase_Order_Number]      = stg.[Purchase_Order_Number]
        AND tgt.[Purchase_Order_Item_Number] = stg.[Purchase_Order_Item_Number]
        AND tgt.[Account_Assignment_Seq]     = stg.[Account_Assignment_Seq]
    WHERE stg.[Purchase_Order_Number] IS NOT NULL
      AND stg.[Purchase_Order_Item_Number] IS NOT NULL
      AND stg.[Account_Assignment_Seq] IS NOT NULL;

    -- Insert new rows
    INSERT INTO [offshore_sunsystems].[EKKN_PO_Account_Assignments]
    (
        [Purchase_Order_Number],
        [Purchase_Order_Item_Number],
        [Account_Assignment_Seq],
        [Account_Assignment_Category],
        [Cost_Centre],
        [Internal_Order],
        [WBS_Internal_Id],
        [GL_Account],
        [Quantity],
        [Allocation_Percent],
        [Allocation_Method],
        [load_id],
        [pipeline_run_id],
        [source_path],
        [loaded_at],
        [updated_at]
    )
    SELECT
        stg.[Purchase_Order_Number],
        stg.[Purchase_Order_Item_Number],
        stg.[Account_Assignment_Seq],
        stg.[Account_Assignment_Category],
        stg.[Cost_Centre],
        stg.[Internal_Order],
        stg.[WBS_Internal_Id],
        stg.[GL_Account],
        stg.[Quantity],
        stg.[Allocation_Percent],
        stg.[Allocation_Method],
        @load_id,
        @pipeline_run_id,
        @source_path,
        GETDATE(),
        GETDATE()
    FROM [zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments] stg
    WHERE stg.[Purchase_Order_Number] IS NOT NULL
      AND stg.[Purchase_Order_Item_Number] IS NOT NULL
      AND stg.[Account_Assignment_Seq] IS NOT NULL;

    -- Clear staging
    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[EKKN_PO_Account_Assignments];
END;
GO


-- ============================================================
-- WATERMARK — seed EKKN_PO_Account_Assignments
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

-- Optional: avoid duplicate seed inserts
IF NOT EXISTS
(
    SELECT 1
    FROM [offshore_eam].[watermark]
    WHERE [table_name]  = 'EKKN_PO_Account_Assignments'
      AND [schema_name] = 'offshore_sunsystems'
)
BEGIN
    INSERT INTO [offshore_eam].[watermark]
        ([table_name],[schema_name],[source_system],[stored_procedure],
         [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
    VALUES
    (
        'EKKN_PO_Account_Assignments',
        'offshore_sunsystems',
        'SAP_ECC_EKKN',
        '[dbo].[usp_offshore_sunsystems_EKKN_PO_Account_Assignments]',
        '1900-01-01',
        'initial',
        0,
        NULL,
        @now
    );
END;
GO