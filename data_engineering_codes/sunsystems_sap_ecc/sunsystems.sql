-- ============================================================
-- SunSystems Conformed Layer — Full DDL
-- Schema: offshore_sunsystems
-- Staging + Target + Stored Procedures + Watermark
-- 20 tables: Analysis_Code_Extensions → Suppliers
-- ============================================================

-- ============================================================
-- Analysis_Code_Extensions
-- Rows: 5,048  |  26 data cols + 5 metadata = 31 target cols
-- Source: SAP_ECC_CSKS
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Analysis_Code_Extensions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Analysis_Code_Extensions];

CREATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Code_Extensions]
(
    [Analysis_Code]                                 NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Extension_Fixed_1]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_2]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_3]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_4]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_5]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_6]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_7]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_8]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_9]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_10]                            NVARCHAR(255)             NULL,
    [Extension_Text_6]                              NVARCHAR(255)             NULL,
    [Extension_Text_7]                              NVARCHAR(255)             NULL,
    [Extension_Text_8]                              NVARCHAR(255)             NULL,
    [Extension_Text_9]                              NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Analysis_Code_Extensions]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Analysis_Code_Extensions];

CREATE TABLE [offshore_sunsystems].[Analysis_Code_Extensions]
(
    [Analysis_Code]                                 NVARCHAR(255)             NOT NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Extension_Fixed_1]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_2]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_3]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_4]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_5]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_6]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_7]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_8]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_9]                             NVARCHAR(255)             NULL,
    [Extension_Fixed_10]                            NVARCHAR(255)             NULL,
    [Extension_Text_6]                              NVARCHAR(255)             NULL,
    [Extension_Text_7]                              NVARCHAR(255)             NULL,
    [Extension_Text_8]                              NVARCHAR(255)             NULL,
    [Extension_Text_9]                              NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Analysis_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Analysis_Code_Extensions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Code_Extensions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Code_Extensions]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Analysis_Code_Extensions]
    WHERE [Analysis_Code] IN (
        SELECT [Analysis_Code] FROM [zzSTG_offshore_sunsystems].[Analysis_Code_Extensions]
        WHERE  [Analysis_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Analysis_Code_Extensions]
    (
        [Analysis_Code],
        [Business_Unit],
        [Analysis_Dimension_Id],
        [DateTime_Last_Updated],
        [User_Id_Last_Updated],
        [Extension_Fixed_1],
        [Extension_Fixed_2],
        [Extension_Fixed_3],
        [Extension_Fixed_4],
        [Extension_Fixed_5],
        [Extension_Fixed_6],
        [Extension_Fixed_7],
        [Extension_Fixed_8],
        [Extension_Fixed_9],
        [Extension_Fixed_10],
        [Extension_Text_6],
        [Extension_Text_7],
        [Extension_Text_8],
        [Extension_Text_9],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Analysis_Code],
        [Business_Unit],
        [Analysis_Dimension_Id],
        [DateTime_Last_Updated],
        [User_Id_Last_Updated],
        [Extension_Fixed_1],
        [Extension_Fixed_2],
        [Extension_Fixed_3],
        [Extension_Fixed_4],
        [Extension_Fixed_5],
        [Extension_Fixed_6],
        [Extension_Fixed_7],
        [Extension_Fixed_8],
        [Extension_Fixed_9],
        [Extension_Fixed_10],
        [Extension_Text_6],
        [Extension_Text_7],
        [Extension_Text_8],
        [Extension_Text_9],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Analysis_Code_Extensions]
    WHERE [Analysis_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Code_Extensions];
END;
GO

-- ============================================================
-- Analysis_Codes
-- Rows: 1,360,946  |  27 data cols + 5 metadata = 32 target cols
-- Source: SAP_ECC_CSKS_AUFK_PRPS
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Analysis_Codes]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Analysis_Codes];

CREATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Codes]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Code]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Budget_Checking_Code]                          NVARCHAR(255)             NULL,
    [Budget_Checking_Description]                   NVARCHAR(255)             NULL,
    [Budget_Navigation_Method_Code]                 NVARCHAR(255)             NULL,
    [Budget_Navigation_Method_Description]          NVARCHAR(255)             NULL,
    [Budget_Stop_Code]                              NVARCHAR(255)             NULL,
    [Budget_Stop_Description]                       NVARCHAR(255)             NULL,
    [Combined_Budget_Check_Code]                    NVARCHAR(255)             NULL,
    [Combined_Budget_Check_Description]             NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Name]                                          NVARCHAR(255)             NULL,
    [Prohibit_Posting_Code]                         NVARCHAR(255)             NULL,
    [Prohibit_Posting_Description]                  NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [_source_table]                                 NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Analysis_Codes]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Analysis_Codes];

CREATE TABLE [offshore_sunsystems].[Analysis_Codes]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Code]                                 NVARCHAR(255)             NOT NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Budget_Checking_Code]                          NVARCHAR(255)             NULL,
    [Budget_Checking_Description]                   NVARCHAR(255)             NULL,
    [Budget_Navigation_Method_Code]                 NVARCHAR(255)             NULL,
    [Budget_Navigation_Method_Description]          NVARCHAR(255)             NULL,
    [Budget_Stop_Code]                              NVARCHAR(255)             NULL,
    [Budget_Stop_Description]                       NVARCHAR(255)             NULL,
    [Combined_Budget_Check_Code]                    NVARCHAR(255)             NULL,
    [Combined_Budget_Check_Description]             NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Name]                                          NVARCHAR(255)             NULL,
    [Prohibit_Posting_Code]                         NVARCHAR(255)             NULL,
    [Prohibit_Posting_Description]                  NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [_source_table]                                 NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Analysis_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Analysis_Codes]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Codes];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Codes]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Analysis_Codes]
    WHERE [Analysis_Code] IN (
        SELECT [Analysis_Code] FROM [zzSTG_offshore_sunsystems].[Analysis_Codes]
        WHERE  [Analysis_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Analysis_Codes]
    (
        [Business_Unit],
        [Analysis_Code],
        [Analysis_Dimension_Id],
        [Budget_Checking_Code],
        [Budget_Checking_Description],
        [Budget_Navigation_Method_Code],
        [Budget_Navigation_Method_Description],
        [Budget_Stop_Code],
        [Budget_Stop_Description],
        [Combined_Budget_Check_Code],
        [Combined_Budget_Check_Description],
        [DateTime_Last_Updated],
        [Lookup_Code],
        [Name],
        [Prohibit_Posting_Code],
        [Prohibit_Posting_Description],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [_source_table],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Analysis_Code],
        [Analysis_Dimension_Id],
        [Budget_Checking_Code],
        [Budget_Checking_Description],
        [Budget_Navigation_Method_Code],
        [Budget_Navigation_Method_Description],
        [Budget_Stop_Code],
        [Budget_Stop_Description],
        [Combined_Budget_Check_Code],
        [Combined_Budget_Check_Description],
        [DateTime_Last_Updated],
        [Lookup_Code],
        [Name],
        [Prohibit_Posting_Code],
        [Prohibit_Posting_Description],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [_source_table],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Analysis_Codes]
    WHERE [Analysis_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Codes];
END;
GO

-- ============================================================
-- Analysis_Dimension_Names
-- Rows: 38  |  23 data cols + 5 metadata = 28 target cols
-- Source: SAP_ECC_TKA01_CSKA
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Analysis_Dimension_Names]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Analysis_Dimension_Names];

CREATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Dimension_Names]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Amend_In_Account_Allocation_Code]              NVARCHAR(255)             NULL,
    [Amend_In_Account_Allocation_Description]       NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Length]                                        INT                       NULL,
    [Linked_Code]                                   NVARCHAR(255)             NULL,
    [Linked_Description]                            NVARCHAR(255)             NULL,
    [Look_Up_Code]                                  NVARCHAR(255)             NULL,
    [shortHeading]                                  NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Validation_Method_Code]                        NVARCHAR(255)             NULL,
    [Validation_Method_Description]                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Analysis_Dimension_Names]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Analysis_Dimension_Names];

CREATE TABLE [offshore_sunsystems].[Analysis_Dimension_Names]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NOT NULL,
    [Amend_In_Account_Allocation_Code]              NVARCHAR(255)             NULL,
    [Amend_In_Account_Allocation_Description]       NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Length]                                        INT                       NULL,
    [Linked_Code]                                   NVARCHAR(255)             NULL,
    [Linked_Description]                            NVARCHAR(255)             NULL,
    [Look_Up_Code]                                  NVARCHAR(255)             NULL,
    [shortHeading]                                  NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Validation_Method_Code]                        NVARCHAR(255)             NULL,
    [Validation_Method_Description]                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Analysis_Dimension_Names]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Dimension_Names];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Dimension_Names]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Analysis_Dimension_Names]
    WHERE [Analysis_Dimension_Id] IN (
        SELECT [Analysis_Dimension_Id] FROM [zzSTG_offshore_sunsystems].[Analysis_Dimension_Names]
        WHERE  [Analysis_Dimension_Id] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Analysis_Dimension_Names]
    (
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Amend_In_Account_Allocation_Code],
        [Amend_In_Account_Allocation_Description],
        [Description],
        [DateTime_Last_Updated],
        [Length],
        [Linked_Code],
        [Linked_Description],
        [Look_Up_Code],
        [shortHeading],
        [Status_Code],
        [Status_Description],
        [Validation_Method_Code],
        [Validation_Method_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Amend_In_Account_Allocation_Code],
        [Amend_In_Account_Allocation_Description],
        [Description],
        [DateTime_Last_Updated],
        [Length],
        [Linked_Code],
        [Linked_Description],
        [Look_Up_Code],
        [shortHeading],
        [Status_Code],
        [Status_Description],
        [Validation_Method_Code],
        [Validation_Method_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Analysis_Dimension_Names]
    WHERE [Analysis_Dimension_Id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Dimension_Names];
END;
GO

-- ============================================================
-- Analysis_Structures
-- Rows: 98,215  |  16 data cols + 5 metadata = 21 target cols
-- Source: SAP_ECC_SETHEADER_CSKT
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Analysis_Structures]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Analysis_Structures];

CREATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Structures]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Analysis_Entity_Id]                            NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Entry_Number]                                  INT                       NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Code]                                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Analysis_Structures]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Analysis_Structures];

CREATE TABLE [offshore_sunsystems].[Analysis_Structures]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Analysis_Entity_Id]                            NVARCHAR(255)             NOT NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Entry_Number]                                  INT                       NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Code]                                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Analysis_Entity_Id]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Analysis_Structures]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Structures];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Structures]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Analysis_Structures]
    WHERE [Analysis_Entity_Id] IN (
        SELECT [Analysis_Entity_Id] FROM [zzSTG_offshore_sunsystems].[Analysis_Structures]
        WHERE  [Analysis_Entity_Id] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Analysis_Structures]
    (
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Analysis_Entity_Id],
        [DateTime_Last_Updated],
        [Entry_Number],
        [Short_Heading],
        [User_Id_Last_Updated],
        [Code],
        [Description],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Analysis_Entity_Id],
        [DateTime_Last_Updated],
        [Entry_Number],
        [Short_Heading],
        [User_Id_Last_Updated],
        [Code],
        [Description],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Analysis_Structures]
    WHERE [Analysis_Entity_Id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Structures];
END;
GO

-- ============================================================
-- Analysis_Sub_Dimensions
-- Rows: 61,447  |  17 data cols + 5 metadata = 22 target cols
-- Source: SAP_ECC_CSKA
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions];

CREATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Analysis_Subdimension_Code]                    NVARCHAR(255)             NULL,
    [DateTimeLast_Updated]                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Mask]                                          NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [UserId_Last_Updated]                           NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Analysis_Sub_Dimensions]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Analysis_Sub_Dimensions];

CREATE TABLE [offshore_sunsystems].[Analysis_Sub_Dimensions]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Analysis_Dimension_Id]                         NVARCHAR(255)             NULL,
    [Analysis_Subdimension_Code]                    NVARCHAR(255)             NOT NULL,
    [DateTimeLast_Updated]                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Mask]                                          NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [UserId_Last_Updated]                           NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Analysis_Subdimension_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Analysis_Sub_Dimensions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Sub_Dimensions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Analysis_Sub_Dimensions]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Analysis_Sub_Dimensions]
    WHERE [Analysis_Subdimension_Code] IN (
        SELECT [Analysis_Subdimension_Code] FROM [zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions]
        WHERE  [Analysis_Subdimension_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Analysis_Sub_Dimensions]
    (
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Analysis_Subdimension_Code],
        [DateTimeLast_Updated],
        [Description],
        [Mask],
        [Short_Heading],
        [Status_Code],
        [Status_Description],
        [UserId_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Analysis_Dimension_Id],
        [Analysis_Subdimension_Code],
        [DateTimeLast_Updated],
        [Description],
        [Mask],
        [Short_Heading],
        [Status_Code],
        [Status_Description],
        [UserId_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions]
    WHERE [Analysis_Subdimension_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Analysis_Sub_Dimensions];
END;
GO

-- ============================================================
-- Budget_Definitions
-- Rows: 40  |  18 data cols + 5 metadata = 23 target cols
-- Source: SAP_ECC_BPGE_BPJA_OKOB_CSKS
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Budget_Definitions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Budget_Definitions];

CREATE TABLE [zzSTG_offshore_sunsystems].[Budget_Definitions]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Budget_Code]                                   NVARCHAR(255)             NULL,
    [Budget_Code_Description]                       NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Provisional_Posting_Code]                      NVARCHAR(255)             NULL,
    [Provisional_Posting_Description]               NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Budget_Definitions]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Budget_Definitions];

CREATE TABLE [offshore_sunsystems].[Budget_Definitions]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Budget_Code]                                   NVARCHAR(255)             NOT NULL,
    [Budget_Code_Description]                       NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Provisional_Posting_Code]                      NVARCHAR(255)             NULL,
    [Provisional_Posting_Description]               NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Budget_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Budget_Definitions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Budget_Definitions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Budget_Definitions]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Budget_Definitions]
    WHERE [Budget_Code] IN (
        SELECT [Budget_Code] FROM [zzSTG_offshore_sunsystems].[Budget_Definitions]
        WHERE  [Budget_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Budget_Definitions]
    (
        [Business_Unit],
        [Budget_Code],
        [Budget_Code_Description],
        [DateTime_Last_Updated],
        [Description],
        [Lookup_Code],
        [Provisional_Posting_Code],
        [Provisional_Posting_Description],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Budget_Code],
        [Budget_Code_Description],
        [DateTime_Last_Updated],
        [Description],
        [Lookup_Code],
        [Provisional_Posting_Code],
        [Provisional_Posting_Description],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Budget_Definitions]
    WHERE [Budget_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Budget_Definitions];
END;
GO

-- ============================================================
-- Business_Unit_Addresses
-- Rows: 2  |  32 data cols + 5 metadata = 37 target cols
-- Source: SAP_ECC_T001_ADRC
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Business_Unit_Addresses]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Addresses];

CREATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Addresses]
(
    [Address_Code]                                  NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Invoice_Address_Code]                          NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Business_Unit_Address_Short_Heading]           NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_1]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_2]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_3]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Town_City]               NVARCHAR(255)             NULL,
    [Business_Unit_Address_State]                   NVARCHAR(255)             NULL,
    [Business_Unit_Address_Country]                 NVARCHAR(255)             NULL,
    [Business_Unit_Address_Telex_Fax_Number]        NVARCHAR(255)             NULL,
    [Business_Unit_Address_Language_Code]           NVARCHAR(255)             NULL,
    [Business_Unit_Address_Comment]                 NVARCHAR(255)             NULL,
    [Business_Unit_Address_Date_Time_Last_Updated]  DATE                      NULL,
    [Valid_From]                                    DATE                      NULL,
    [Business_Unit_Address_Lookup_Code]             NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Business_Unit_Address_Status_Code]             NVARCHAR(255)             NULL,
    [Business_Unit_Address_Status_Description]      NVARCHAR(255)             NULL,
    [Business_Unit_Address_Temporary_Address_Code]  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Temporary_Address_Description] NVARCHAR(255)             NULL,
    [Business_Unit_Address_Update_Count]            NVARCHAR(255)             NULL,
    [Business_Unit_Address_User_Id_Last_Updated]    NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Business_Unit_Addresses]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Business_Unit_Addresses];

CREATE TABLE [offshore_sunsystems].[Business_Unit_Addresses]
(
    [Address_Code]                                  NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NOT NULL,
    [Invoice_Address_Code]                          NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Business_Unit_Address_Short_Heading]           NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_1]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_2]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Line_3]                  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Town_City]               NVARCHAR(255)             NULL,
    [Business_Unit_Address_State]                   NVARCHAR(255)             NULL,
    [Business_Unit_Address_Country]                 NVARCHAR(255)             NULL,
    [Business_Unit_Address_Telex_Fax_Number]        NVARCHAR(255)             NULL,
    [Business_Unit_Address_Language_Code]           NVARCHAR(255)             NULL,
    [Business_Unit_Address_Comment]                 NVARCHAR(255)             NULL,
    [Business_Unit_Address_Date_Time_Last_Updated]  DATE                      NULL,
    [Valid_From]                                    DATE                      NULL,
    [Business_Unit_Address_Lookup_Code]             NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Business_Unit_Address_Status_Code]             NVARCHAR(255)             NULL,
    [Business_Unit_Address_Status_Description]      NVARCHAR(255)             NULL,
    [Business_Unit_Address_Temporary_Address_Code]  NVARCHAR(255)             NULL,
    [Business_Unit_Address_Temporary_Address_Description] NVARCHAR(255)             NULL,
    [Business_Unit_Address_Update_Count]            NVARCHAR(255)             NULL,
    [Business_Unit_Address_User_Id_Last_Updated]    NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Business_Unit_Addresses]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Unit_Addresses];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Unit_Addresses]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Business_Unit_Addresses]
    WHERE [Business_Unit] IN (
        SELECT [Business_Unit] FROM [zzSTG_offshore_sunsystems].[Business_Unit_Addresses]
        WHERE  [Business_Unit] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Business_Unit_Addresses]
    (
        [Address_Code],
        [Business_Unit],
        [Invoice_Address_Code],
        [Own_Company_Code],
        [Business_Unit_Address_Short_Heading],
        [Business_Unit_Address_Line_1],
        [Business_Unit_Address_Line_2],
        [Business_Unit_Address_Line_3],
        [Business_Unit_Address_Town_City],
        [Business_Unit_Address_State],
        [Business_Unit_Address_Country],
        [Business_Unit_Address_Telex_Fax_Number],
        [Business_Unit_Address_Language_Code],
        [Business_Unit_Address_Comment],
        [Business_Unit_Address_Date_Time_Last_Updated],
        [Valid_From],
        [Business_Unit_Address_Lookup_Code],
        [Created_By],
        [Business_Unit_Address_Status_Code],
        [Business_Unit_Address_Status_Description],
        [Business_Unit_Address_Temporary_Address_Code],
        [Business_Unit_Address_Temporary_Address_Description],
        [Business_Unit_Address_Update_Count],
        [Business_Unit_Address_User_Id_Last_Updated],
        [Date_Time_Last_Updated],
        [Update_Count],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_Until],
        [Created],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Address_Code],
        [Business_Unit],
        [Invoice_Address_Code],
        [Own_Company_Code],
        [Business_Unit_Address_Short_Heading],
        [Business_Unit_Address_Line_1],
        [Business_Unit_Address_Line_2],
        [Business_Unit_Address_Line_3],
        [Business_Unit_Address_Town_City],
        [Business_Unit_Address_State],
        [Business_Unit_Address_Country],
        [Business_Unit_Address_Telex_Fax_Number],
        [Business_Unit_Address_Language_Code],
        [Business_Unit_Address_Comment],
        [Business_Unit_Address_Date_Time_Last_Updated],
        [Valid_From],
        [Business_Unit_Address_Lookup_Code],
        [Created_By],
        [Business_Unit_Address_Status_Code],
        [Business_Unit_Address_Status_Description],
        [Business_Unit_Address_Temporary_Address_Code],
        [Business_Unit_Address_Temporary_Address_Description],
        [Business_Unit_Address_Update_Count],
        [Business_Unit_Address_User_Id_Last_Updated],
        [Date_Time_Last_Updated],
        [Update_Count],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_Until],
        [Created],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Business_Unit_Addresses]
    WHERE [Business_Unit] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Addresses];
END;
GO

-- ============================================================
-- Business_Unit_Details
-- Rows: 2  |  53 data cols + 5 metadata = 58 target cols
-- Source: SAP_ECC_T001_ADRC_T052
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Business_Unit_Details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Details];

CREATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Details]
(
    [Invoice_Address_Code]                          NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Name]                                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Invoice_Short_Heading]                         NVARCHAR(255)             NULL,
    [Invoice_Language_Code]                         NVARCHAR(255)             NULL,
    [Invoice_Country]                               NVARCHAR(255)             NULL,
    [Invoice_Town_City]                             NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Payment_Receipt_Method_Code]                   NVARCHAR(255)             NULL,
    [Payment_Terms_Lookup_Code]                     NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Invoice_Address_Line1]                         NVARCHAR(255)             NULL,
    [Invoice_Address_Line2]                         NVARCHAR(255)             NULL,
    [Invoice_Address_Line3]                         NVARCHAR(255)             NULL,
    [Invoice_Comment]                               NVARCHAR(255)             NULL,
    [Invoice_State]                                 NVARCHAR(255)             NULL,
    [Invoice_Telephone_Number]                      NVARCHAR(255)             NULL,
    [InvoiceTelexFaxNumber]                         NVARCHAR(255)             NULL,
    [Invoice_Lookup_Code]                           NVARCHAR(255)             NULL,
    [Invoice_Date_Time_Last_Updated]                DATE                      NULL,
    [Valid_From]                                    DATE                      NULL,
    [Payment_Terms_Group_Code_def]                  NVARCHAR(255)             NULL,
    [Payment_Terms_Description]                     NVARCHAR(255)             NULL,
    [Preferred_Payment_Method_Code]                 NVARCHAR(255)             NULL,
    [Payment_Terms_Document1_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Document2_Description]           NVARCHAR(255)             NULL,
    [Invoice_Status_Code]                           NVARCHAR(255)             NULL,
    [Invoice_Status_Description]                    NVARCHAR(255)             NULL,
    [Email_Address]                                 NVARCHAR(255)             NULL,
    [Invoice_Temporary_Address_Code]                NVARCHAR(255)             NULL,
    [Invoice_Temporary_Address_Description]         NVARCHAR(255)             NULL,
    [Invoice_Update_Count]                          NVARCHAR(255)             NULL,
    [Invoice_User_Id_Last_Updated]                  NVARCHAR(255)             NULL,
    [Payment_Receipt_Method_Description]            NVARCHAR(255)             NULL,
    [Payment_Terms_Date_Time_Last_Updated]          NVARCHAR(255)             NULL,
    [Payment_Terms_Document3_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Document4_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Short_Heading]                   NVARCHAR(255)             NULL,
    [Payment_Terms_Update_Count]                    NVARCHAR(255)             NULL,
    [Payment_Terms_User_Id_Last_Updated]            NVARCHAR(255)             NULL,
    [Preferred_Payment_Method_Description]          NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Web_Page_Address]                              NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Business_Unit_Details]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Business_Unit_Details];

CREATE TABLE [offshore_sunsystems].[Business_Unit_Details]
(
    [Invoice_Address_Code]                          NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NOT NULL,
    [Name]                                          NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Invoice_Short_Heading]                         NVARCHAR(255)             NULL,
    [Invoice_Language_Code]                         NVARCHAR(255)             NULL,
    [Invoice_Country]                               NVARCHAR(255)             NULL,
    [Invoice_Town_City]                             NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Payment_Receipt_Method_Code]                   NVARCHAR(255)             NULL,
    [Payment_Terms_Lookup_Code]                     NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Invoice_Address_Line1]                         NVARCHAR(255)             NULL,
    [Invoice_Address_Line2]                         NVARCHAR(255)             NULL,
    [Invoice_Address_Line3]                         NVARCHAR(255)             NULL,
    [Invoice_Comment]                               NVARCHAR(255)             NULL,
    [Invoice_State]                                 NVARCHAR(255)             NULL,
    [Invoice_Telephone_Number]                      NVARCHAR(255)             NULL,
    [InvoiceTelexFaxNumber]                         NVARCHAR(255)             NULL,
    [Invoice_Lookup_Code]                           NVARCHAR(255)             NULL,
    [Invoice_Date_Time_Last_Updated]                DATE                      NULL,
    [Valid_From]                                    DATE                      NULL,
    [Payment_Terms_Group_Code_def]                  NVARCHAR(255)             NULL,
    [Payment_Terms_Description]                     NVARCHAR(255)             NULL,
    [Preferred_Payment_Method_Code]                 NVARCHAR(255)             NULL,
    [Payment_Terms_Document1_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Document2_Description]           NVARCHAR(255)             NULL,
    [Invoice_Status_Code]                           NVARCHAR(255)             NULL,
    [Invoice_Status_Description]                    NVARCHAR(255)             NULL,
    [Email_Address]                                 NVARCHAR(255)             NULL,
    [Invoice_Temporary_Address_Code]                NVARCHAR(255)             NULL,
    [Invoice_Temporary_Address_Description]         NVARCHAR(255)             NULL,
    [Invoice_Update_Count]                          NVARCHAR(255)             NULL,
    [Invoice_User_Id_Last_Updated]                  NVARCHAR(255)             NULL,
    [Payment_Receipt_Method_Description]            NVARCHAR(255)             NULL,
    [Payment_Terms_Date_Time_Last_Updated]          NVARCHAR(255)             NULL,
    [Payment_Terms_Document3_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Document4_Description]           NVARCHAR(255)             NULL,
    [Payment_Terms_Short_Heading]                   NVARCHAR(255)             NULL,
    [Payment_Terms_Update_Count]                    NVARCHAR(255)             NULL,
    [Payment_Terms_User_Id_Last_Updated]            NVARCHAR(255)             NULL,
    [Preferred_Payment_Method_Description]          NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Web_Page_Address]                              NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Business_Unit_Details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Unit_Details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Unit_Details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Business_Unit_Details]
    WHERE [Business_Unit] IN (
        SELECT [Business_Unit] FROM [zzSTG_offshore_sunsystems].[Business_Unit_Details]
        WHERE  [Business_Unit] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Business_Unit_Details]
    (
        [Invoice_Address_Code],
        [Business_Unit],
        [Name],
        [Description],
        [Short_Heading],
        [Own_Company_Code],
        [Invoice_Short_Heading],
        [Invoice_Language_Code],
        [Invoice_Country],
        [Invoice_Town_City],
        [Lookup_Code],
        [Payment_Receipt_Method_Code],
        [Payment_Terms_Lookup_Code],
        [Date_Time_Last_Updated],
        [Invoice_Address_Line1],
        [Invoice_Address_Line2],
        [Invoice_Address_Line3],
        [Invoice_Comment],
        [Invoice_State],
        [Invoice_Telephone_Number],
        [InvoiceTelexFaxNumber],
        [Invoice_Lookup_Code],
        [Invoice_Date_Time_Last_Updated],
        [Valid_From],
        [Payment_Terms_Group_Code_def],
        [Payment_Terms_Description],
        [Preferred_Payment_Method_Code],
        [Payment_Terms_Document1_Description],
        [Payment_Terms_Document2_Description],
        [Invoice_Status_Code],
        [Invoice_Status_Description],
        [Email_Address],
        [Invoice_Temporary_Address_Code],
        [Invoice_Temporary_Address_Description],
        [Invoice_Update_Count],
        [Invoice_User_Id_Last_Updated],
        [Payment_Receipt_Method_Description],
        [Payment_Terms_Date_Time_Last_Updated],
        [Payment_Terms_Document3_Description],
        [Payment_Terms_Document4_Description],
        [Payment_Terms_Short_Heading],
        [Payment_Terms_Update_Count],
        [Payment_Terms_User_Id_Last_Updated],
        [Preferred_Payment_Method_Description],
        [Update_Count],
        [User_Id_Last_Updated],
        [Web_Page_Address],
        [User_Defined_Fields],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Invoice_Address_Code],
        [Business_Unit],
        [Name],
        [Description],
        [Short_Heading],
        [Own_Company_Code],
        [Invoice_Short_Heading],
        [Invoice_Language_Code],
        [Invoice_Country],
        [Invoice_Town_City],
        [Lookup_Code],
        [Payment_Receipt_Method_Code],
        [Payment_Terms_Lookup_Code],
        [Date_Time_Last_Updated],
        [Invoice_Address_Line1],
        [Invoice_Address_Line2],
        [Invoice_Address_Line3],
        [Invoice_Comment],
        [Invoice_State],
        [Invoice_Telephone_Number],
        [InvoiceTelexFaxNumber],
        [Invoice_Lookup_Code],
        [Invoice_Date_Time_Last_Updated],
        [Valid_From],
        [Payment_Terms_Group_Code_def],
        [Payment_Terms_Description],
        [Preferred_Payment_Method_Code],
        [Payment_Terms_Document1_Description],
        [Payment_Terms_Document2_Description],
        [Invoice_Status_Code],
        [Invoice_Status_Description],
        [Email_Address],
        [Invoice_Temporary_Address_Code],
        [Invoice_Temporary_Address_Description],
        [Invoice_Update_Count],
        [Invoice_User_Id_Last_Updated],
        [Payment_Receipt_Method_Description],
        [Payment_Terms_Date_Time_Last_Updated],
        [Payment_Terms_Document3_Description],
        [Payment_Terms_Document4_Description],
        [Payment_Terms_Short_Heading],
        [Payment_Terms_Update_Count],
        [Payment_Terms_User_Id_Last_Updated],
        [Preferred_Payment_Method_Description],
        [Update_Count],
        [User_Id_Last_Updated],
        [Web_Page_Address],
        [User_Defined_Fields],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Business_Unit_Details]
    WHERE [Business_Unit] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Details];
END;
GO

-- ============================================================
-- Business_Units
-- Rows: 6  |  27 data cols + 5 metadata = 32 target cols
-- Source: SAP_ECC_T001_TKA01_T005_TCURR
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Business_Units]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Business_Units];

CREATE TABLE [zzSTG_offshore_sunsystems].[Business_Units]
(
    [Base_Currency]                                 NVARCHAR(255)             NULL,
    [Zone_Data_Code]                                NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Business_Unit_Code]                            NVARCHAR(255)             NULL,
    [Business_Unit_Description]                     NVARCHAR(255)             NULL,
    [Date_Format_Code]                              NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Primary_Budget_Ledger_Code]                    NVARCHAR(255)             NULL,
    [Purchase_Commitment_Ledger_Code]               NVARCHAR(255)             NULL,
    [Business_Unit_Locked_Code]                     NVARCHAR(255)             NULL,
    [Business_Unit_Locked_Description]              NVARCHAR(255)             NULL,
    [Maximum_Number_Of_Periods]                     INT                       NULL,
    [Financials_Only_Code]                          NVARCHAR(255)             NULL,
    [Financials_Only_Description]                   NVARCHAR(255)             NULL,
    [Base_Currency_Description]                     NVARCHAR(255)             NULL,
    [Value3_Currency_Code]                          NVARCHAR(255)             NULL,
    [Base_Currency_Name]                            NVARCHAR(255)             NULL,
    [Base_Currency_Iso_Currency_Code]               NVARCHAR(255)             NULL,
    [Value3_Currency_Type_Code]                     NVARCHAR(255)             NULL,
    [Date_Separator]                                NVARCHAR(255)             NULL,
    [Base_Currency_Currency_Unit_Name]              NVARCHAR(255)             NULL,
    [Base_Currency_Short_Heading]                   NVARCHAR(255)             NULL,
    [Decimal_Separator]                             NVARCHAR(255)             NULL,
    [Source_Business_Unit_Code]                     NVARCHAR(255)             NULL,
    [Base_Currency_Gain_Account_Realized]           DECIMAL(18,6)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Base_Currency_Post_Rule_Code]                  NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Business_Units]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Business_Units];

CREATE TABLE [offshore_sunsystems].[Business_Units]
(
    [Base_Currency]                                 NVARCHAR(255)             NULL,
    [Zone_Data_Code]                                NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NOT NULL,
    [Business_Unit_Code]                            NVARCHAR(255)             NULL,
    [Business_Unit_Description]                     NVARCHAR(255)             NULL,
    [Date_Format_Code]                              NVARCHAR(255)             NULL,
    [Own_Company_Code]                              NVARCHAR(255)             NULL,
    [Primary_Budget_Ledger_Code]                    NVARCHAR(255)             NULL,
    [Purchase_Commitment_Ledger_Code]               NVARCHAR(255)             NULL,
    [Business_Unit_Locked_Code]                     NVARCHAR(255)             NULL,
    [Business_Unit_Locked_Description]              NVARCHAR(255)             NULL,
    [Maximum_Number_Of_Periods]                     INT                       NULL,
    [Financials_Only_Code]                          NVARCHAR(255)             NULL,
    [Financials_Only_Description]                   NVARCHAR(255)             NULL,
    [Base_Currency_Description]                     NVARCHAR(255)             NULL,
    [Value3_Currency_Code]                          NVARCHAR(255)             NULL,
    [Base_Currency_Name]                            NVARCHAR(255)             NULL,
    [Base_Currency_Iso_Currency_Code]               NVARCHAR(255)             NULL,
    [Value3_Currency_Type_Code]                     NVARCHAR(255)             NULL,
    [Date_Separator]                                NVARCHAR(255)             NULL,
    [Base_Currency_Currency_Unit_Name]              NVARCHAR(255)             NULL,
    [Base_Currency_Short_Heading]                   NVARCHAR(255)             NULL,
    [Decimal_Separator]                             NVARCHAR(255)             NULL,
    [Source_Business_Unit_Code]                     NVARCHAR(255)             NULL,
    [Base_Currency_Gain_Account_Realized]           DECIMAL(18,6)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Base_Currency_Post_Rule_Code]                  NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Business_Units]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Units];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Business_Units]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Business_Units]
    WHERE [Business_Unit] IN (
        SELECT [Business_Unit] FROM [zzSTG_offshore_sunsystems].[Business_Units]
        WHERE  [Business_Unit] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Business_Units]
    (
        [Base_Currency],
        [Zone_Data_Code],
        [Business_Unit],
        [Business_Unit_Code],
        [Business_Unit_Description],
        [Date_Format_Code],
        [Own_Company_Code],
        [Primary_Budget_Ledger_Code],
        [Purchase_Commitment_Ledger_Code],
        [Business_Unit_Locked_Code],
        [Business_Unit_Locked_Description],
        [Maximum_Number_Of_Periods],
        [Financials_Only_Code],
        [Financials_Only_Description],
        [Base_Currency_Description],
        [Value3_Currency_Code],
        [Base_Currency_Name],
        [Base_Currency_Iso_Currency_Code],
        [Value3_Currency_Type_Code],
        [Date_Separator],
        [Base_Currency_Currency_Unit_Name],
        [Base_Currency_Short_Heading],
        [Decimal_Separator],
        [Source_Business_Unit_Code],
        [Base_Currency_Gain_Account_Realized],
        [Date_Time_Last_Updated],
        [Base_Currency_Post_Rule_Code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Base_Currency],
        [Zone_Data_Code],
        [Business_Unit],
        [Business_Unit_Code],
        [Business_Unit_Description],
        [Date_Format_Code],
        [Own_Company_Code],
        [Primary_Budget_Ledger_Code],
        [Purchase_Commitment_Ledger_Code],
        [Business_Unit_Locked_Code],
        [Business_Unit_Locked_Description],
        [Maximum_Number_Of_Periods],
        [Financials_Only_Code],
        [Financials_Only_Description],
        [Base_Currency_Description],
        [Value3_Currency_Code],
        [Base_Currency_Name],
        [Base_Currency_Iso_Currency_Code],
        [Value3_Currency_Type_Code],
        [Date_Separator],
        [Base_Currency_Currency_Unit_Name],
        [Base_Currency_Short_Heading],
        [Decimal_Separator],
        [Source_Business_Unit_Code],
        [Base_Currency_Gain_Account_Realized],
        [Date_Time_Last_Updated],
        [Base_Currency_Post_Rule_Code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Business_Units]
    WHERE [Business_Unit] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Business_Units];
END;
GO

-- ============================================================
-- Chart_Of_Accounts
-- Rows: 53,556  |  37 data cols + 5 metadata = 42 target cols
-- Source: SAP_ECC_SKA1_SKB1_SKAT
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Chart_Of_Accounts]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Chart_Of_Accounts];

CREATE TABLE [zzSTG_offshore_sunsystems].[Chart_Of_Accounts]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Account_Code]                                  NVARCHAR(255)             NULL,
    [Account_Type_Code]                             NVARCHAR(255)             NULL,
    [Account_Type_Description]                      NVARCHAR(255)             NULL,
    [Accounting_Links_Allowed_Code]                 NVARCHAR(255)             NULL,
    [Accounting_Links_Allowed_Description]          NVARCHAR(255)             NULL,
    [Allocation_In_Progress_Code]                   NVARCHAR(255)             NULL,
    [Allocation_In_Progress_Description]            NVARCHAR(255)             NULL,
    [Balance_Type_Code]                             NVARCHAR(255)             NULL,
    [Balance_Type_Description]                      NVARCHAR(255)             NULL,
    [Banking_Currencies_Required_Code]              NVARCHAR(255)             NULL,
    [Banking_Currencies_Required_Description]       NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Suppress_Revaluation_Code]                     NVARCHAR(255)             NULL,
    [Suppress_Revaluation_Description]              NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Link_Account_Code]                             NVARCHAR(255)             NULL,
    [Report_Group]                                  NVARCHAR(255)             NULL,
    [aa08]                                          NVARCHAR(255)             NULL,
    [managementAcc]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Long_Description]                              NVARCHAR(255)             NULL,
    [Debit_Or_Credit_Code]                          NVARCHAR(255)             NULL,
    [Base_Currency]                                 NVARCHAR(255)             NULL,
    [Withholding_Tax_AC_Tax_Class_Code]             NVARCHAR(255)             NULL,
    [cashflow]                                      NVARCHAR(255)             NULL,
    [coaLevel1]                                     NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Chart_Of_Accounts]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Chart_Of_Accounts];

CREATE TABLE [offshore_sunsystems].[Chart_Of_Accounts]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Account_Code]                                  NVARCHAR(255)             NOT NULL,
    [Account_Type_Code]                             NVARCHAR(255)             NULL,
    [Account_Type_Description]                      NVARCHAR(255)             NULL,
    [Accounting_Links_Allowed_Code]                 NVARCHAR(255)             NULL,
    [Accounting_Links_Allowed_Description]          NVARCHAR(255)             NULL,
    [Allocation_In_Progress_Code]                   NVARCHAR(255)             NULL,
    [Allocation_In_Progress_Description]            NVARCHAR(255)             NULL,
    [Balance_Type_Code]                             NVARCHAR(255)             NULL,
    [Balance_Type_Description]                      NVARCHAR(255)             NULL,
    [Banking_Currencies_Required_Code]              NVARCHAR(255)             NULL,
    [Banking_Currencies_Required_Description]       NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Suppress_Revaluation_Code]                     NVARCHAR(255)             NULL,
    [Suppress_Revaluation_Description]              NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Link_Account_Code]                             NVARCHAR(255)             NULL,
    [Report_Group]                                  NVARCHAR(255)             NULL,
    [aa08]                                          NVARCHAR(255)             NULL,
    [managementAcc]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Long_Description]                              NVARCHAR(255)             NULL,
    [Debit_Or_Credit_Code]                          NVARCHAR(255)             NULL,
    [Base_Currency]                                 NVARCHAR(255)             NULL,
    [Withholding_Tax_AC_Tax_Class_Code]             NVARCHAR(255)             NULL,
    [cashflow]                                      NVARCHAR(255)             NULL,
    [coaLevel1]                                     NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Account_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Chart_Of_Accounts]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Chart_Of_Accounts];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Chart_Of_Accounts]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Chart_Of_Accounts]
    WHERE [Account_Code] IN (
        SELECT [Account_Code] FROM [zzSTG_offshore_sunsystems].[Chart_Of_Accounts]
        WHERE  [Account_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Chart_Of_Accounts]
    (
        [Business_Unit],
        [Account_Code],
        [Account_Type_Code],
        [Account_Type_Description],
        [Accounting_Links_Allowed_Code],
        [Accounting_Links_Allowed_Description],
        [Allocation_In_Progress_Code],
        [Allocation_In_Progress_Description],
        [Balance_Type_Code],
        [Balance_Type_Description],
        [Banking_Currencies_Required_Code],
        [Banking_Currencies_Required_Description],
        [DateTime_Last_Updated],
        [Suppress_Revaluation_Code],
        [Suppress_Revaluation_Description],
        [Status_Code],
        [Status_Description],
        [Link_Account_Code],
        [Report_Group],
        [aa08],
        [managementAcc],
        [User_Id_Last_Updated],
        [Valid_From],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Lookup_Code],
        [Short_Heading],
        [Description],
        [Long_Description],
        [Debit_Or_Credit_Code],
        [Base_Currency],
        [Withholding_Tax_AC_Tax_Class_Code],
        [cashflow],
        [coaLevel1],
        [Valid_Until],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Account_Code],
        [Account_Type_Code],
        [Account_Type_Description],
        [Accounting_Links_Allowed_Code],
        [Accounting_Links_Allowed_Description],
        [Allocation_In_Progress_Code],
        [Allocation_In_Progress_Description],
        [Balance_Type_Code],
        [Balance_Type_Description],
        [Banking_Currencies_Required_Code],
        [Banking_Currencies_Required_Description],
        [DateTime_Last_Updated],
        [Suppress_Revaluation_Code],
        [Suppress_Revaluation_Description],
        [Status_Code],
        [Status_Description],
        [Link_Account_Code],
        [Report_Group],
        [aa08],
        [managementAcc],
        [User_Id_Last_Updated],
        [Valid_From],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Lookup_Code],
        [Short_Heading],
        [Description],
        [Long_Description],
        [Debit_Or_Credit_Code],
        [Base_Currency],
        [Withholding_Tax_AC_Tax_Class_Code],
        [cashflow],
        [coaLevel1],
        [Valid_Until],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Chart_Of_Accounts]
    WHERE [Account_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Chart_Of_Accounts];
END;
GO

-- ============================================================
-- Currencies
-- Rows: 192  |  34 data cols + 5 metadata = 39 target cols
-- Source: SAP_ECC_TCURC_TCURT_TCURX
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Currencies]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Currencies];

CREATE TABLE [zzSTG_offshore_sunsystems].[Currencies]
(
    [Currency_Code]                                 NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Banking_Currency_code]                         NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Use_Daily_Conversion_Rates_Code]               NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Banking_Currency_Description]                  NVARCHAR(255)             NULL,
    [Currency_Gender_code]                          NVARCHAR(255)             NULL,
    [Currency_Gender_description]                   NVARCHAR(255)             NULL,
    [Currency_Name]                                 NVARCHAR(255)             NULL,
    [Currency_Unit_Name]                            NVARCHAR(255)             NULL,
    [Decimals_Allowed_code]                         NVARCHAR(255)             NULL,
    [Decimals_Allowed_Description]                  NVARCHAR(255)             NULL,
    [First_Decimal_Name]                            NVARCHAR(255)             NULL,
    [Gain_Account_Realized]                         NVARCHAR(255)             NULL,
    [Gain_Account_Unrealized]                       NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Net_Loss_Account_Realized]                     NVARCHAR(255)             NULL,
    [Net_Loss_Account_Unrealized]                   NVARCHAR(255)             NULL,
    [Second_Decimal_Name]                           NVARCHAR(255)             NULL,
    [Third_Decimal_Name]                            NVARCHAR(255)             NULL,
    [Split_Decimal_Naming_Code]                     NVARCHAR(255)             NULL,
    [Split_Decimal_Naming_Description]              NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Use_Daily_Conversion_Rates_Description]        NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Currencies]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Currencies];

CREATE TABLE [offshore_sunsystems].[Currencies]
(
    [Currency_Code]                                 NVARCHAR(255)             NOT NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Banking_Currency_code]                         NVARCHAR(255)             NULL,
    [DateTime_Last_Updated]                         NVARCHAR(255)             NULL,
    [Use_Daily_Conversion_Rates_Code]               NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Banking_Currency_Description]                  NVARCHAR(255)             NULL,
    [Currency_Gender_code]                          NVARCHAR(255)             NULL,
    [Currency_Gender_description]                   NVARCHAR(255)             NULL,
    [Currency_Name]                                 NVARCHAR(255)             NULL,
    [Currency_Unit_Name]                            NVARCHAR(255)             NULL,
    [Decimals_Allowed_code]                         NVARCHAR(255)             NULL,
    [Decimals_Allowed_Description]                  NVARCHAR(255)             NULL,
    [First_Decimal_Name]                            NVARCHAR(255)             NULL,
    [Gain_Account_Realized]                         NVARCHAR(255)             NULL,
    [Gain_Account_Unrealized]                       NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Net_Loss_Account_Realized]                     NVARCHAR(255)             NULL,
    [Net_Loss_Account_Unrealized]                   NVARCHAR(255)             NULL,
    [Second_Decimal_Name]                           NVARCHAR(255)             NULL,
    [Third_Decimal_Name]                            NVARCHAR(255)             NULL,
    [Split_Decimal_Naming_Code]                     NVARCHAR(255)             NULL,
    [Split_Decimal_Naming_Description]              NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Use_Daily_Conversion_Rates_Description]        NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Currencies]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Currencies];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Currencies]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Currencies]
    WHERE [Currency_Code] IN (
        SELECT [Currency_Code] FROM [zzSTG_offshore_sunsystems].[Currencies]
        WHERE  [Currency_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Currencies]
    (
        [Currency_Code],
        [Short_Heading],
        [Banking_Currency_code],
        [DateTime_Last_Updated],
        [Use_Daily_Conversion_Rates_Code],
        [Business_Unit],
        [Banking_Currency_Description],
        [Currency_Gender_code],
        [Currency_Gender_description],
        [Currency_Name],
        [Currency_Unit_Name],
        [Decimals_Allowed_code],
        [Decimals_Allowed_Description],
        [First_Decimal_Name],
        [Gain_Account_Realized],
        [Gain_Account_Unrealized],
        [Lookup_Code],
        [Net_Loss_Account_Realized],
        [Net_Loss_Account_Unrealized],
        [Second_Decimal_Name],
        [Third_Decimal_Name],
        [Split_Decimal_Naming_Code],
        [Split_Decimal_Naming_Description],
        [Status_Code],
        [Status_Description],
        [Use_Daily_Conversion_Rates_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Currency_Code],
        [Short_Heading],
        [Banking_Currency_code],
        [DateTime_Last_Updated],
        [Use_Daily_Conversion_Rates_Code],
        [Business_Unit],
        [Banking_Currency_Description],
        [Currency_Gender_code],
        [Currency_Gender_description],
        [Currency_Name],
        [Currency_Unit_Name],
        [Decimals_Allowed_code],
        [Decimals_Allowed_Description],
        [First_Decimal_Name],
        [Gain_Account_Realized],
        [Gain_Account_Unrealized],
        [Lookup_Code],
        [Net_Loss_Account_Realized],
        [Net_Loss_Account_Unrealized],
        [Second_Decimal_Name],
        [Third_Decimal_Name],
        [Split_Decimal_Naming_Code],
        [Split_Decimal_Naming_Description],
        [Status_Code],
        [Status_Description],
        [Use_Daily_Conversion_Rates_Description],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Currencies]
    WHERE [Currency_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Currencies];
END;
GO

-- ============================================================
-- Currency_Rate_Types
-- Rows: 48  |  18 data cols + 5 metadata = 23 target cols
-- Source: SAP_ECC_TCURV
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Currency_Rate_Types]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Currency_Rate_Types];

CREATE TABLE [zzSTG_offshore_sunsystems].[Currency_Rate_Types]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Currency_Rate_Type]                            NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [_inverted_rate_flag]                           NVARCHAR(255)             NULL,
    [_fixed_rate_flag]                              NVARCHAR(255)             NULL,
    [_euro_rate_flag]                               NVARCHAR(255)             NULL,
    [_valuation_flag]                               NVARCHAR(255)             NULL,
    [_reference_currency]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Currency_Rate_Types]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Currency_Rate_Types];

CREATE TABLE [offshore_sunsystems].[Currency_Rate_Types]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Currency_Rate_Type]                            NVARCHAR(255)             NOT NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [_inverted_rate_flag]                           NVARCHAR(255)             NULL,
    [_fixed_rate_flag]                              NVARCHAR(255)             NULL,
    [_euro_rate_flag]                               NVARCHAR(255)             NULL,
    [_valuation_flag]                               NVARCHAR(255)             NULL,
    [_reference_currency]                           NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Currency_Rate_Types]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Currency_Rate_Types];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Currency_Rate_Types]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Currency_Rate_Types]
    WHERE [Currency_Rate_Type] IN (
        SELECT [Currency_Rate_Type] FROM [zzSTG_offshore_sunsystems].[Currency_Rate_Types]
        WHERE  [Currency_Rate_Type] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Currency_Rate_Types]
    (
        [Business_Unit],
        [Currency_Rate_Type],
        [Date_Time_Last_Updated],
        [Description],
        [Lookup_Code],
        [Short_Heading],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [_inverted_rate_flag],
        [_fixed_rate_flag],
        [_euro_rate_flag],
        [_valuation_flag],
        [_reference_currency],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Currency_Rate_Type],
        [Date_Time_Last_Updated],
        [Description],
        [Lookup_Code],
        [Short_Heading],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [_inverted_rate_flag],
        [_fixed_rate_flag],
        [_euro_rate_flag],
        [_valuation_flag],
        [_reference_currency],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Currency_Rate_Types]
    WHERE [Currency_Rate_Type] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Currency_Rate_Types];
END;
GO

-- ============================================================
-- DateDimension
-- Rows: 11,323  |  28 data cols + 5 metadata = 33 target cols
-- Source: SAP_TFACS_GENERATED
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[DateDimension]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[DateDimension];

CREATE TABLE [zzSTG_offshore_sunsystems].[DateDimension]
(
    [Date]                                          DATE                      NULL,
    [Day]                                           SMALLINT                  NULL,
    [DaySuffix]                                     NVARCHAR(5)               NULL,
    [Weekday]                                       SMALLINT                  NULL,
    [WeekDayName]                                   NVARCHAR(15)              NULL,
    [IsWeekend]                                     BIT                       NULL,
    [IsHoliday]                                     BIT                       NULL,
    [HolidayText]                                   NVARCHAR(255)             NULL,
    [DOWInMonth]                                    SMALLINT                  NULL,
    [DayOfYear]                                     SMALLINT                  NULL,
    [WeekOfMonth]                                   SMALLINT                  NULL,
    [WeekOfYear]                                    SMALLINT                  NULL,
    [ISOWeekOfYear]                                 SMALLINT                  NULL,
    [Month]                                         SMALLINT                  NULL,
    [MonthName]                                     NVARCHAR(15)              NULL,
    [Quarter]                                       SMALLINT                  NULL,
    [QuarterName]                                   NVARCHAR(10)              NULL,
    [Year]                                          INT                       NULL,
    [MMYYYY]                                        NVARCHAR(10)              NULL,
    [MonthYear]                                     NVARCHAR(10)              NULL,
    [FirstDayOfMonth]                               DATE                      NULL,
    [LastDayOfMonth]                                DATE                      NULL,
    [FirstDayOfQuarter]                             DATE                      NULL,
    [LastDayOfQuarter]                              DATE                      NULL,
    [FirstDayOfYear]                                DATE                      NULL,
    [LastDayOfYear]                                 DATE                      NULL,
    [FirstDayOfNextMonth]                           DATE                      NULL,
    [FirstDayOfNextYear]                            DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[DateDimension]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[DateDimension];

CREATE TABLE [offshore_sunsystems].[DateDimension]
(
    [Date]                                          DATE                      NOT NULL,
    [Day]                                           SMALLINT                  NULL,
    [DaySuffix]                                     NVARCHAR(5)               NULL,
    [Weekday]                                       SMALLINT                  NULL,
    [WeekDayName]                                   NVARCHAR(15)              NULL,
    [IsWeekend]                                     BIT                       NULL,
    [IsHoliday]                                     BIT                       NULL,
    [HolidayText]                                   NVARCHAR(255)             NULL,
    [DOWInMonth]                                    SMALLINT                  NULL,
    [DayOfYear]                                     SMALLINT                  NULL,
    [WeekOfMonth]                                   SMALLINT                  NULL,
    [WeekOfYear]                                    SMALLINT                  NULL,
    [ISOWeekOfYear]                                 SMALLINT                  NULL,
    [Month]                                         SMALLINT                  NULL,
    [MonthName]                                     NVARCHAR(15)              NULL,
    [Quarter]                                       SMALLINT                  NULL,
    [QuarterName]                                   NVARCHAR(10)              NULL,
    [Year]                                          INT                       NULL,
    [MMYYYY]                                        NVARCHAR(10)              NULL,
    [MonthYear]                                     NVARCHAR(10)              NULL,
    [FirstDayOfMonth]                               DATE                      NULL,
    [LastDayOfMonth]                                DATE                      NULL,
    [FirstDayOfQuarter]                             DATE                      NULL,
    [LastDayOfQuarter]                              DATE                      NULL,
    [FirstDayOfYear]                                DATE                      NULL,
    [LastDayOfYear]                                 DATE                      NULL,
    [FirstDayOfNextMonth]                           DATE                      NULL,
    [FirstDayOfNextYear]                            DATE                      NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_DateDimension]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_DateDimension];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_DateDimension]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[DateDimension]
    WHERE [Date] IN (
        SELECT [Date] FROM [zzSTG_offshore_sunsystems].[DateDimension]
        WHERE  [Date] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[DateDimension]
    (
        [Date],
        [Day],
        [DaySuffix],
        [Weekday],
        [WeekDayName],
        [IsWeekend],
        [IsHoliday],
        [HolidayText],
        [DOWInMonth],
        [DayOfYear],
        [WeekOfMonth],
        [WeekOfYear],
        [ISOWeekOfYear],
        [Month],
        [MonthName],
        [Quarter],
        [QuarterName],
        [Year],
        [MMYYYY],
        [MonthYear],
        [FirstDayOfMonth],
        [LastDayOfMonth],
        [FirstDayOfQuarter],
        [LastDayOfQuarter],
        [FirstDayOfYear],
        [LastDayOfYear],
        [FirstDayOfNextMonth],
        [FirstDayOfNextYear],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Date],
        [Day],
        [DaySuffix],
        [Weekday],
        [WeekDayName],
        [IsWeekend],
        [IsHoliday],
        [HolidayText],
        [DOWInMonth],
        [DayOfYear],
        [WeekOfMonth],
        [WeekOfYear],
        [ISOWeekOfYear],
        [Month],
        [MonthName],
        [Quarter],
        [QuarterName],
        [Year],
        [MMYYYY],
        [MonthYear],
        [FirstDayOfMonth],
        [LastDayOfMonth],
        [FirstDayOfQuarter],
        [LastDayOfQuarter],
        [FirstDayOfYear],
        [LastDayOfYear],
        [FirstDayOfNextMonth],
        [FirstDayOfNextYear],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[DateDimension]
    WHERE [Date] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[DateDimension];
END;
GO

-- ============================================================
-- Employee_Roles
-- Rows: 1,857,519  |  14 data cols + 5 metadata = 19 target cols
-- Source: SAP_ECC_HRP1001_AGR_USERS_PA0001
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Employee_Roles]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Employee_Roles];

CREATE TABLE [zzSTG_offshore_sunsystems].[Employee_Roles]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Active_Employee_Role_Code]                     NVARCHAR(255)             NULL,
    [Active_Employee_Role_Description]              NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Employee_Code]                                 NVARCHAR(255)             NULL,
    [Role_Code]                                     NVARCHAR(255)             NULL,
    [Role_Description]                              NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    DATE                      NULL,
    [Valid_Until]                                   DATE                      NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Employee_Roles]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Employee_Roles];

CREATE TABLE [offshore_sunsystems].[Employee_Roles]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Active_Employee_Role_Code]                     NVARCHAR(255)             NULL,
    [Active_Employee_Role_Description]              NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Employee_Code]                                 NVARCHAR(255)             NOT NULL,
    [Role_Code]                                     NVARCHAR(255)             NULL,
    [Role_Description]                              NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    DATE                      NULL,
    [Valid_Until]                                   DATE                      NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Employee_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Employee_Roles]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Employee_Roles];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Employee_Roles]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Employee_Roles]
    WHERE [Employee_Code] IN (
        SELECT [Employee_Code] FROM [zzSTG_offshore_sunsystems].[Employee_Roles]
        WHERE  [Employee_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Employee_Roles]
    (
        [Business_Unit],
        [Active_Employee_Role_Code],
        [Active_Employee_Role_Description],
        [Date_Time_Last_Updated],
        [Employee_Code],
        [Role_Code],
        [Role_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Active_Employee_Role_Code],
        [Active_Employee_Role_Description],
        [Date_Time_Last_Updated],
        [Employee_Code],
        [Role_Code],
        [Role_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Employee_Roles]
    WHERE [Employee_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Employee_Roles];
END;
GO

-- ============================================================
-- Fixed_Assets
-- Rows: 125,404  |  55 data cols + 5 metadata = 60 target cols
-- Source: SAP_ECC_ANLA_ANLB_ANLC_ANLZ
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Fixed_Assets]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Fixed_Assets];

CREATE TABLE [zzSTG_offshore_sunsystems].[Fixed_Assets]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Asset_Code]                                    NVARCHAR(255)             NULL,
    [Asset_Class_Code]                              NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Asset_Currency_Code]                           NVARCHAR(255)             NULL,
    [Asset_Quantity]                                DECIMAL(18,4)             NULL,
    [Asset_Status_Code]                             NVARCHAR(255)             NULL,
    [Asset_Status_Description]                      NVARCHAR(255)             NULL,
    [Balance_Sheet]                                 INT                       NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Disposed_Code]                                 NVARCHAR(255)             NULL,
    [Disposed_Description]                          NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Base_Depreciation_Method_Code]                 NVARCHAR(255)             NULL,
    [Base_Depreciation_Method_Description]          NVARCHAR(255)             NULL,
    [Base_Percentage]                               DECIMAL(18,4)             NULL,
    [Base_Posting_Final_Value]                      DECIMAL(18,4)             NULL,
    [Start_Period]                                  NVARCHAR(255)             NULL,
    [Last_Period]                                   NVARCHAR(255)             NULL,
    [Reporting_Depreciation_Method_Code]            NVARCHAR(255)             NULL,
    [Base_Net_Value]                                DECIMAL(18,4)             NULL,
    [Base_Gross_Value]                              DECIMAL(18,4)             NULL,
    [Base_Depreciation_Value]                       DECIMAL(18,4)             NULL,
    [Base_Anticipated_Depreciation]                 DECIMAL(18,4)             NULL,
    [Report_Net_Value]                              DECIMAL(18,4)             NULL,
    [Report_Gross_Value]                            DECIMAL(18,4)             NULL,
    [Report_Depreciation_Value]                     DECIMAL(18,4)             NULL,
    [locations]                                     NVARCHAR(255)             NULL,
    [Part_Disposed_Code]                            NVARCHAR(255)             NULL,
    [Part_Disposed_Description]                     NVARCHAR(255)             NULL,
    [Profit_And_Loss]                               NVARCHAR(255)             NULL,
    [Reporting_Depreciation_Method_Description]     NVARCHAR(255)             NULL,
    [Fa05]                                          NVARCHAR(255)             NULL,
    [Fa06]                                          NVARCHAR(255)             NULL,
    [Fa07]                                          NVARCHAR(255)             NULL,
    [Fa08]                                          NVARCHAR(255)             NULL,
    [Fa09]                                          NVARCHAR(255)             NULL,
    [Fa10]                                          NVARCHAR(255)             NULL,
    [Asset_Maintain]                                NVARCHAR(255)             NULL,
    [Asset_Location]                                NVARCHAR(255)             NULL,
    [Asset_Class_1]                                 NVARCHAR(255)             NULL,
    [afe]                                           NVARCHAR(255)             NULL,
    [legacyAssetCo]                                 NVARCHAR(255)             NULL,
    [legacySupplier]                                NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Fixed_Assets]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Fixed_Assets];

CREATE TABLE [offshore_sunsystems].[Fixed_Assets]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Asset_Code]                                    NVARCHAR(255)             NOT NULL,
    [Asset_Class_Code]                              NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [Asset_Currency_Code]                           NVARCHAR(255)             NULL,
    [Asset_Quantity]                                DECIMAL(18,4)             NULL,
    [Asset_Status_Code]                             NVARCHAR(255)             NULL,
    [Asset_Status_Description]                      NVARCHAR(255)             NULL,
    [Balance_Sheet]                                 INT                       NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Disposed_Code]                                 NVARCHAR(255)             NULL,
    [Disposed_Description]                          NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Base_Depreciation_Method_Code]                 NVARCHAR(255)             NULL,
    [Base_Depreciation_Method_Description]          NVARCHAR(255)             NULL,
    [Base_Percentage]                               DECIMAL(18,4)             NULL,
    [Base_Posting_Final_Value]                      DECIMAL(18,4)             NULL,
    [Start_Period]                                  NVARCHAR(255)             NULL,
    [Last_Period]                                   NVARCHAR(255)             NULL,
    [Reporting_Depreciation_Method_Code]            NVARCHAR(255)             NULL,
    [Base_Net_Value]                                DECIMAL(18,4)             NULL,
    [Base_Gross_Value]                              DECIMAL(18,4)             NULL,
    [Base_Depreciation_Value]                       DECIMAL(18,4)             NULL,
    [Base_Anticipated_Depreciation]                 DECIMAL(18,4)             NULL,
    [Report_Net_Value]                              DECIMAL(18,4)             NULL,
    [Report_Gross_Value]                            DECIMAL(18,4)             NULL,
    [Report_Depreciation_Value]                     DECIMAL(18,4)             NULL,
    [locations]                                     NVARCHAR(255)             NULL,
    [Part_Disposed_Code]                            NVARCHAR(255)             NULL,
    [Part_Disposed_Description]                     NVARCHAR(255)             NULL,
    [Profit_And_Loss]                               NVARCHAR(255)             NULL,
    [Reporting_Depreciation_Method_Description]     NVARCHAR(255)             NULL,
    [Fa05]                                          NVARCHAR(255)             NULL,
    [Fa06]                                          NVARCHAR(255)             NULL,
    [Fa07]                                          NVARCHAR(255)             NULL,
    [Fa08]                                          NVARCHAR(255)             NULL,
    [Fa09]                                          NVARCHAR(255)             NULL,
    [Fa10]                                          NVARCHAR(255)             NULL,
    [Asset_Maintain]                                NVARCHAR(255)             NULL,
    [Asset_Location]                                NVARCHAR(255)             NULL,
    [Asset_Class_1]                                 NVARCHAR(255)             NULL,
    [afe]                                           NVARCHAR(255)             NULL,
    [legacyAssetCo]                                 NVARCHAR(255)             NULL,
    [legacySupplier]                                NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Asset_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Fixed_Assets]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Fixed_Assets];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Fixed_Assets]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Fixed_Assets]
    WHERE [Asset_Code] IN (
        SELECT [Asset_Code] FROM [zzSTG_offshore_sunsystems].[Fixed_Assets]
        WHERE  [Asset_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Fixed_Assets]
    (
        [Business_Unit],
        [Asset_Code],
        [Asset_Class_Code],
        [Lookup_Code],
        [Asset_Currency_Code],
        [Asset_Quantity],
        [Asset_Status_Code],
        [Asset_Status_Description],
        [Balance_Sheet],
        [Date_Time_Last_Updated],
        [Description],
        [Disposed_Code],
        [Disposed_Description],
        [Short_Heading],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Base_Depreciation_Method_Code],
        [Base_Depreciation_Method_Description],
        [Base_Percentage],
        [Base_Posting_Final_Value],
        [Start_Period],
        [Last_Period],
        [Reporting_Depreciation_Method_Code],
        [Base_Net_Value],
        [Base_Gross_Value],
        [Base_Depreciation_Value],
        [Base_Anticipated_Depreciation],
        [Report_Net_Value],
        [Report_Gross_Value],
        [Report_Depreciation_Value],
        [locations],
        [Part_Disposed_Code],
        [Part_Disposed_Description],
        [Profit_And_Loss],
        [Reporting_Depreciation_Method_Description],
        [Fa05],
        [Fa06],
        [Fa07],
        [Fa08],
        [Fa09],
        [Fa10],
        [Asset_Maintain],
        [Asset_Location],
        [Asset_Class_1],
        [afe],
        [legacyAssetCo],
        [legacySupplier],
        [User_Defined_Fields],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Asset_Code],
        [Asset_Class_Code],
        [Lookup_Code],
        [Asset_Currency_Code],
        [Asset_Quantity],
        [Asset_Status_Code],
        [Asset_Status_Description],
        [Balance_Sheet],
        [Date_Time_Last_Updated],
        [Description],
        [Disposed_Code],
        [Disposed_Description],
        [Short_Heading],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Base_Depreciation_Method_Code],
        [Base_Depreciation_Method_Description],
        [Base_Percentage],
        [Base_Posting_Final_Value],
        [Start_Period],
        [Last_Period],
        [Reporting_Depreciation_Method_Code],
        [Base_Net_Value],
        [Base_Gross_Value],
        [Base_Depreciation_Value],
        [Base_Anticipated_Depreciation],
        [Report_Net_Value],
        [Report_Gross_Value],
        [Report_Depreciation_Value],
        [locations],
        [Part_Disposed_Code],
        [Part_Disposed_Description],
        [Profit_And_Loss],
        [Reporting_Depreciation_Method_Description],
        [Fa05],
        [Fa06],
        [Fa07],
        [Fa08],
        [Fa09],
        [Fa10],
        [Asset_Maintain],
        [Asset_Location],
        [Asset_Class_1],
        [afe],
        [legacyAssetCo],
        [legacySupplier],
        [User_Defined_Fields],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Fixed_Assets]
    WHERE [Asset_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Fixed_Assets];
END;
GO

-- ============================================================
-- Journal_Definitions
-- Rows: 160  |  32 data cols + 5 metadata = 37 target cols
-- Source: SAP_ECC_T003_T003T
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Journal_Definitions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Journal_Definitions];

CREATE TABLE [zzSTG_offshore_sunsystems].[Journal_Definitions]
(
    [Journal_Type]                                  NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Journal_Name]                                  NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Allocation_Marker_Code]                        NVARCHAR(255)             NULL,
    [Allocation_Marker_Description]                 NVARCHAR(255)             NULL,
    [Allow_Scheduled_Payments_Code]                 NVARCHAR(255)             NULL,
    [Allow_Scheduled_Payments_Description]          NVARCHAR(255)             NULL,
    [Asset_Depreciation_Type_Code]                  NVARCHAR(255)             NULL,
    [Asset_Sale_Code]                               NVARCHAR(255)             NULL,
    [Authorization_Required_Code]                   NVARCHAR(255)             NULL,
    [Authorization_Required_Description]            NVARCHAR(255)             NULL,
    [Journal_Preset_Code]                           NVARCHAR(255)             NULL,
    [Rate_Type]                                     NVARCHAR(255)             NULL,
    [Sequence_Number_Code]                          NVARCHAR(255)             NULL,
    [Posting_Journal_Type_Code]                     NVARCHAR(255)             NULL,
    [Reverse_Next_Period_Code]                      NVARCHAR(255)             NULL,
    [Transaction_Post_Rule_Override_Code]           NVARCHAR(255)             NULL,
    [True_Rated_Code]                               NVARCHAR(255)             NULL,
    [Record_Status_Code]                            NVARCHAR(255)             NULL,
    [Record_Status_Description]                     NVARCHAR(255)             NULL,
    [Discount_Tolerance_Days]                       DECIMAL(18,4)             NULL,
    [Discount_Tolerance_Percentage]                 DECIMAL(18,4)             NULL,
    [Discount_Tolerance_Value]                      DECIMAL(18,4)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Journal_Definitions]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Journal_Definitions];

CREATE TABLE [offshore_sunsystems].[Journal_Definitions]
(
    [Journal_Type]                                  NVARCHAR(255)             NOT NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Journal_Name]                                  NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Allocation_Marker_Code]                        NVARCHAR(255)             NULL,
    [Allocation_Marker_Description]                 NVARCHAR(255)             NULL,
    [Allow_Scheduled_Payments_Code]                 NVARCHAR(255)             NULL,
    [Allow_Scheduled_Payments_Description]          NVARCHAR(255)             NULL,
    [Asset_Depreciation_Type_Code]                  NVARCHAR(255)             NULL,
    [Asset_Sale_Code]                               NVARCHAR(255)             NULL,
    [Authorization_Required_Code]                   NVARCHAR(255)             NULL,
    [Authorization_Required_Description]            NVARCHAR(255)             NULL,
    [Journal_Preset_Code]                           NVARCHAR(255)             NULL,
    [Rate_Type]                                     NVARCHAR(255)             NULL,
    [Sequence_Number_Code]                          NVARCHAR(255)             NULL,
    [Posting_Journal_Type_Code]                     NVARCHAR(255)             NULL,
    [Reverse_Next_Period_Code]                      NVARCHAR(255)             NULL,
    [Transaction_Post_Rule_Override_Code]           NVARCHAR(255)             NULL,
    [True_Rated_Code]                               NVARCHAR(255)             NULL,
    [Record_Status_Code]                            NVARCHAR(255)             NULL,
    [Record_Status_Description]                     NVARCHAR(255)             NULL,
    [Discount_Tolerance_Days]                       DECIMAL(18,4)             NULL,
    [Discount_Tolerance_Percentage]                 DECIMAL(18,4)             NULL,
    [Discount_Tolerance_Value]                      DECIMAL(18,4)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Journal_Definitions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Journal_Definitions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Journal_Definitions]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Journal_Definitions]
    WHERE [Journal_Type] IN (
        SELECT [Journal_Type] FROM [zzSTG_offshore_sunsystems].[Journal_Definitions]
        WHERE  [Journal_Type] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Journal_Definitions]
    (
        [Journal_Type],
        [Business_Unit],
        [Journal_Name],
        [Date_Time_Last_Updated],
        [Allocation_Marker_Code],
        [Allocation_Marker_Description],
        [Allow_Scheduled_Payments_Code],
        [Allow_Scheduled_Payments_Description],
        [Asset_Depreciation_Type_Code],
        [Asset_Sale_Code],
        [Authorization_Required_Code],
        [Authorization_Required_Description],
        [Journal_Preset_Code],
        [Rate_Type],
        [Sequence_Number_Code],
        [Posting_Journal_Type_Code],
        [Reverse_Next_Period_Code],
        [Transaction_Post_Rule_Override_Code],
        [True_Rated_Code],
        [Record_Status_Code],
        [Record_Status_Description],
        [Discount_Tolerance_Days],
        [Discount_Tolerance_Percentage],
        [Discount_Tolerance_Value],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Journal_Type],
        [Business_Unit],
        [Journal_Name],
        [Date_Time_Last_Updated],
        [Allocation_Marker_Code],
        [Allocation_Marker_Description],
        [Allow_Scheduled_Payments_Code],
        [Allow_Scheduled_Payments_Description],
        [Asset_Depreciation_Type_Code],
        [Asset_Sale_Code],
        [Authorization_Required_Code],
        [Authorization_Required_Description],
        [Journal_Preset_Code],
        [Rate_Type],
        [Sequence_Number_Code],
        [Posting_Journal_Type_Code],
        [Reverse_Next_Period_Code],
        [Transaction_Post_Rule_Override_Code],
        [True_Rated_Code],
        [Record_Status_Code],
        [Record_Status_Description],
        [Discount_Tolerance_Days],
        [Discount_Tolerance_Percentage],
        [Discount_Tolerance_Value],
        [User_Id_Last_Updated],
        [User_Defined_Fields],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Journal_Definitions]
    WHERE [Journal_Type] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Journal_Definitions];
END;
GO

-- ============================================================
-- Ledger_Lines
-- Rows: 182,068,966  |  61 data cols + 5 metadata = 66 target cols
-- Source: SAP_ECC_BKPF_BSEG_BSIS_BSAS
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Ledger_Lines]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Ledger_Lines];

CREATE TABLE [zzSTG_offshore_sunsystems].[Ledger_Lines]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Journal_Number]                                NVARCHAR(255)             NULL,
    [Journal_Line_Number]                           INT                       NULL,
    [Account_Code]                                  NVARCHAR(255)             NULL,
    [Debit_Credit_Code]                             NVARCHAR(255)             NULL,
    [Base_Amount_Amount]                            DECIMAL(18,4)             NULL,
    [Transaction_Amount]                            DECIMAL(18,4)             NULL,
    [Base2_Reporting_Amount]                        DECIMAL(18,4)             NULL,
    [Base_Debit_Amount]                             DECIMAL(18,4)             NULL,
    [Base_Credit_Amount]                            DECIMAL(18,4)             NULL,
    [Transaction_Debit_Amount]                      DECIMAL(18,4)             NULL,
    [Transaction_Credit_Amount]                     DECIMAL(18,4)             NULL,
    [Reporting_Debit_Amount]                        DECIMAL(18,4)             NULL,
    [Reporting_Credit_Amount]                       DECIMAL(18,4)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Allocation_Reference]                          NVARCHAR(255)             NULL,
    [Supplier]                                      NVARCHAR(255)             NULL,
    [Locations]                                     NVARCHAR(255)             NULL,
    [Afe]                                           NVARCHAR(255)             NULL,
    [Wbs]                                           NVARCHAR(255)             NULL,
    [Due_Date]                                      DATE                      NULL,
    [Tax]                                           NVARCHAR(255)             NULL,
    [Contract]                                      NVARCHAR(255)             NULL,
    [Billing]                                       NVARCHAR(255)             NULL,
    [Project]                                       NVARCHAR(255)             NULL,
    [Employee]                                      NVARCHAR(255)             NULL,
    [Journal_Type]                                  NVARCHAR(255)             NULL,
    [Transaction_Reference]                         NVARCHAR(255)             NULL,
    [Currency_Code]                                 NVARCHAR(255)             NULL,
    [Currency_Rate]                                 DECIMAL(18,4)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Journal_Source]                                NVARCHAR(255)             NULL,
    [Accounting_Period]                             NVARCHAR(255)             NULL,
    [Entry_Date]                                    DATE                      NULL,
    [Ledger_Code]                                   NVARCHAR(255)             NULL,
    [Narration]                                     NVARCHAR(255)             NULL,
    [Allocation_Marker_Code]                        NVARCHAR(255)             NULL,
    [Department]                                    NVARCHAR(255)             NULL,
    [Managementacc]                                 NVARCHAR(255)             NULL,
    [Whtstate]                                      NVARCHAR(255)             NULL,
    [Uap]                                           NVARCHAR(255)             NULL,
    [Coalevel1]                                     NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Permanent_Posting_Date]                        DATE                      NULL,
    [Transaction_Date]                              DATE                      NULL,
    [Entityjv]                                      NVARCHAR(255)             NULL,
    [Jvbilling]                                     NVARCHAR(255)             NULL,
    [Lifecycle]                                     NVARCHAR(255)             NULL,
    [Summarycoa]                                    NVARCHAR(255)             NULL,
    [Workingcapital]                                NVARCHAR(255)             NULL,
    [Cashflow]                                      NVARCHAR(255)             NULL,
    [Financialacc]                                  NVARCHAR(255)             NULL,
    [Coalevel2]                                     NVARCHAR(255)             NULL,
    [Cutback]                                       NVARCHAR(255)             NULL,
    [Costallocation]                                NVARCHAR(255)             NULL,
    [Paidgovernment]                                NVARCHAR(255)             NULL,
    [Legacyassetco]                                 NVARCHAR(255)             NULL,
    [Legacysupplier]                                NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Ledger_Lines]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Ledger_Lines];

CREATE TABLE [offshore_sunsystems].[Ledger_Lines]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Journal_Number]                                NVARCHAR(255)             NOT NULL,
    [Journal_Line_Number]                           INT                       NULL,
    [Account_Code]                                  NVARCHAR(255)             NULL,
    [Debit_Credit_Code]                             NVARCHAR(255)             NULL,
    [Base_Amount_Amount]                            DECIMAL(18,4)             NULL,
    [Transaction_Amount]                            DECIMAL(18,4)             NULL,
    [Base2_Reporting_Amount]                        DECIMAL(18,4)             NULL,
    [Base_Debit_Amount]                             DECIMAL(18,4)             NULL,
    [Base_Credit_Amount]                            DECIMAL(18,4)             NULL,
    [Transaction_Debit_Amount]                      DECIMAL(18,4)             NULL,
    [Transaction_Credit_Amount]                     DECIMAL(18,4)             NULL,
    [Reporting_Debit_Amount]                        DECIMAL(18,4)             NULL,
    [Reporting_Credit_Amount]                       DECIMAL(18,4)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Allocation_Reference]                          NVARCHAR(255)             NULL,
    [Supplier]                                      NVARCHAR(255)             NULL,
    [Locations]                                     NVARCHAR(255)             NULL,
    [Afe]                                           NVARCHAR(255)             NULL,
    [Wbs]                                           NVARCHAR(255)             NULL,
    [Due_Date]                                      DATE                      NULL,
    [Tax]                                           NVARCHAR(255)             NULL,
    [Contract]                                      NVARCHAR(255)             NULL,
    [Billing]                                       NVARCHAR(255)             NULL,
    [Project]                                       NVARCHAR(255)             NULL,
    [Employee]                                      NVARCHAR(255)             NULL,
    [Journal_Type]                                  NVARCHAR(255)             NULL,
    [Transaction_Reference]                         NVARCHAR(255)             NULL,
    [Currency_Code]                                 NVARCHAR(255)             NULL,
    [Currency_Rate]                                 DECIMAL(18,4)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Journal_Source]                                NVARCHAR(255)             NULL,
    [Accounting_Period]                             NVARCHAR(255)             NULL,
    [Entry_Date]                                    DATE                      NULL,
    [Ledger_Code]                                   NVARCHAR(255)             NULL,
    [Narration]                                     NVARCHAR(255)             NULL,
    [Allocation_Marker_Code]                        NVARCHAR(255)             NULL,
    [Department]                                    NVARCHAR(255)             NULL,
    [Managementacc]                                 NVARCHAR(255)             NULL,
    [Whtstate]                                      NVARCHAR(255)             NULL,
    [Uap]                                           NVARCHAR(255)             NULL,
    [Coalevel1]                                     NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Permanent_Posting_Date]                        DATE                      NULL,
    [Transaction_Date]                              DATE                      NULL,
    [Entityjv]                                      NVARCHAR(255)             NULL,
    [Jvbilling]                                     NVARCHAR(255)             NULL,
    [Lifecycle]                                     NVARCHAR(255)             NULL,
    [Summarycoa]                                    NVARCHAR(255)             NULL,
    [Workingcapital]                                NVARCHAR(255)             NULL,
    [Cashflow]                                      NVARCHAR(255)             NULL,
    [Financialacc]                                  NVARCHAR(255)             NULL,
    [Coalevel2]                                     NVARCHAR(255)             NULL,
    [Cutback]                                       NVARCHAR(255)             NULL,
    [Costallocation]                                NVARCHAR(255)             NULL,
    [Paidgovernment]                                NVARCHAR(255)             NULL,
    [Legacyassetco]                                 NVARCHAR(255)             NULL,
    [Legacysupplier]                                NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Journal_Number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Ledger_Lines]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Ledger_Lines];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Ledger_Lines]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Ledger_Lines]
    WHERE [Journal_Number] IN (
        SELECT [Journal_Number] FROM [zzSTG_offshore_sunsystems].[Ledger_Lines]
        WHERE  [Journal_Number] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Ledger_Lines]
    (
        [Business_Unit],
        [Journal_Number],
        [Journal_Line_Number],
        [Account_Code],
        [Debit_Credit_Code],
        [Base_Amount_Amount],
        [Transaction_Amount],
        [Base2_Reporting_Amount],
        [Base_Debit_Amount],
        [Base_Credit_Amount],
        [Transaction_Debit_Amount],
        [Transaction_Credit_Amount],
        [Reporting_Debit_Amount],
        [Reporting_Credit_Amount],
        [Description],
        [Allocation_Reference],
        [Supplier],
        [Locations],
        [Afe],
        [Wbs],
        [Due_Date],
        [Tax],
        [Contract],
        [Billing],
        [Project],
        [Employee],
        [Journal_Type],
        [Transaction_Reference],
        [Currency_Code],
        [Currency_Rate],
        [Created_By],
        [Last_Updated],
        [Journal_Source],
        [Accounting_Period],
        [Entry_Date],
        [Ledger_Code],
        [Narration],
        [Allocation_Marker_Code],
        [Department],
        [Managementacc],
        [Whtstate],
        [Uap],
        [Coalevel1],
        [Created],
        [Last_Updated_By],
        [Permanent_Posting_Date],
        [Transaction_Date],
        [Entityjv],
        [Jvbilling],
        [Lifecycle],
        [Summarycoa],
        [Workingcapital],
        [Cashflow],
        [Financialacc],
        [Coalevel2],
        [Cutback],
        [Costallocation],
        [Paidgovernment],
        [Legacyassetco],
        [Legacysupplier],
        [User_Defined_Fields],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Journal_Number],
        [Journal_Line_Number],
        [Account_Code],
        [Debit_Credit_Code],
        [Base_Amount_Amount],
        [Transaction_Amount],
        [Base2_Reporting_Amount],
        [Base_Debit_Amount],
        [Base_Credit_Amount],
        [Transaction_Debit_Amount],
        [Transaction_Credit_Amount],
        [Reporting_Debit_Amount],
        [Reporting_Credit_Amount],
        [Description],
        [Allocation_Reference],
        [Supplier],
        [Locations],
        [Afe],
        [Wbs],
        [Due_Date],
        [Tax],
        [Contract],
        [Billing],
        [Project],
        [Employee],
        [Journal_Type],
        [Transaction_Reference],
        [Currency_Code],
        [Currency_Rate],
        [Created_By],
        [Last_Updated],
        [Journal_Source],
        [Accounting_Period],
        [Entry_Date],
        [Ledger_Code],
        [Narration],
        [Allocation_Marker_Code],
        [Department],
        [Managementacc],
        [Whtstate],
        [Uap],
        [Coalevel1],
        [Created],
        [Last_Updated_By],
        [Permanent_Posting_Date],
        [Transaction_Date],
        [Entityjv],
        [Jvbilling],
        [Lifecycle],
        [Summarycoa],
        [Workingcapital],
        [Cashflow],
        [Financialacc],
        [Coalevel2],
        [Cutback],
        [Costallocation],
        [Paidgovernment],
        [Legacyassetco],
        [Legacysupplier],
        [User_Defined_Fields],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Ledger_Lines]
    WHERE [Journal_Number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Ledger_Lines];
END;
GO

-- ============================================================
-- Ledger_Setups
-- Rows: 16  |  32 data cols + 5 metadata = 37 target cols
-- Source: SAP_ECC_T011_T093_T093B
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Ledger_Setups]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Ledger_Setups];

CREATE TABLE [zzSTG_offshore_sunsystems].[Ledger_Setups]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Ledger_Definition_Id]                          NVARCHAR(255)             NULL,
    [Currency_For_Payment_Code]                     NVARCHAR(255)             NULL,
    [Currency_Dealing_Description]                  NVARCHAR(255)             NULL,
    [Tax_Anl_Dimension_Code]                        NVARCHAR(255)             NULL,
    [Revaluation_Method_Code]                       NVARCHAR(255)             NULL,
    [Revaluation_Method_Description]                NVARCHAR(255)             NULL,
    [Voucher_Numbering_Code]                        NVARCHAR(255)             NULL,
    [Voucher_Numbering_Description]                 NVARCHAR(255)             NULL,
    [Current_Period]                                NVARCHAR(255)             NULL,
    [Days_Rec_Mnger_Tables_Retained]                NVARCHAR(255)             NULL,
    [Open_Period_From]                              NVARCHAR(255)             NULL,
    [Open_Period_To]                                NVARCHAR(255)             NULL,
    [Open_Date_From]                                DATE                      NULL,
    [Open_Date_To]                                  DATE                      NULL,
    [Posting_Stage_Code]                            NVARCHAR(255)             NULL,
    [Posting_Stage_Description]                     NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Apply_Sequence_Numbers_Code]                   NVARCHAR(255)             NULL,
    [Apply_Advanced_Depreciation_Code]              NVARCHAR(255)             NULL,
    [Transaction_Matching]                          NVARCHAR(255)             NULL,
    [Balance_By_Code]                               NVARCHAR(255)             NULL,
    [Balance_By_Override_Code]                      NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Ledger_Setups]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Ledger_Setups];

CREATE TABLE [offshore_sunsystems].[Ledger_Setups]
(
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Ledger_Definition_Id]                          NVARCHAR(255)             NOT NULL,
    [Currency_For_Payment_Code]                     NVARCHAR(255)             NULL,
    [Currency_Dealing_Description]                  NVARCHAR(255)             NULL,
    [Tax_Anl_Dimension_Code]                        NVARCHAR(255)             NULL,
    [Revaluation_Method_Code]                       NVARCHAR(255)             NULL,
    [Revaluation_Method_Description]                NVARCHAR(255)             NULL,
    [Voucher_Numbering_Code]                        NVARCHAR(255)             NULL,
    [Voucher_Numbering_Description]                 NVARCHAR(255)             NULL,
    [Current_Period]                                NVARCHAR(255)             NULL,
    [Days_Rec_Mnger_Tables_Retained]                NVARCHAR(255)             NULL,
    [Open_Period_From]                              NVARCHAR(255)             NULL,
    [Open_Period_To]                                NVARCHAR(255)             NULL,
    [Open_Date_From]                                DATE                      NULL,
    [Open_Date_To]                                  DATE                      NULL,
    [Posting_Stage_Code]                            NVARCHAR(255)             NULL,
    [Posting_Stage_Description]                     NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Apply_Sequence_Numbers_Code]                   NVARCHAR(255)             NULL,
    [Apply_Advanced_Depreciation_Code]              NVARCHAR(255)             NULL,
    [Transaction_Matching]                          NVARCHAR(255)             NULL,
    [Balance_By_Code]                               NVARCHAR(255)             NULL,
    [Balance_By_Override_Code]                      NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Ledger_Setups]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Ledger_Setups];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Ledger_Setups]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Ledger_Setups]
    WHERE [Ledger_Definition_Id] IN (
        SELECT [Ledger_Definition_Id] FROM [zzSTG_offshore_sunsystems].[Ledger_Setups]
        WHERE  [Ledger_Definition_Id] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Ledger_Setups]
    (
        [Business_Unit],
        [Ledger_Definition_Id],
        [Currency_For_Payment_Code],
        [Currency_Dealing_Description],
        [Tax_Anl_Dimension_Code],
        [Revaluation_Method_Code],
        [Revaluation_Method_Description],
        [Voucher_Numbering_Code],
        [Voucher_Numbering_Description],
        [Current_Period],
        [Days_Rec_Mnger_Tables_Retained],
        [Open_Period_From],
        [Open_Period_To],
        [Open_Date_From],
        [Open_Date_To],
        [Posting_Stage_Code],
        [Posting_Stage_Description],
        [Date_Time_Last_Updated],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Apply_Sequence_Numbers_Code],
        [Apply_Advanced_Depreciation_Code],
        [Transaction_Matching],
        [Balance_By_Code],
        [Balance_By_Override_Code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Business_Unit],
        [Ledger_Definition_Id],
        [Currency_For_Payment_Code],
        [Currency_Dealing_Description],
        [Tax_Anl_Dimension_Code],
        [Revaluation_Method_Code],
        [Revaluation_Method_Description],
        [Voucher_Numbering_Code],
        [Voucher_Numbering_Description],
        [Current_Period],
        [Days_Rec_Mnger_Tables_Retained],
        [Open_Period_From],
        [Open_Period_To],
        [Open_Date_From],
        [Open_Date_To],
        [Posting_Stage_Code],
        [Posting_Stage_Description],
        [Date_Time_Last_Updated],
        [Status_Code],
        [Status_Description],
        [User_Id_Last_Updated],
        [Valid_From],
        [Valid_Until],
        [Created],
        [Created_By],
        [Last_Updated],
        [Last_Updated_By],
        [Apply_Sequence_Numbers_Code],
        [Apply_Advanced_Depreciation_Code],
        [Transaction_Matching],
        [Balance_By_Code],
        [Balance_By_Override_Code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Ledger_Setups]
    WHERE [Ledger_Definition_Id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Ledger_Setups];
END;
GO

-- ============================================================
-- Supplier_Region
-- Rows: 939  |  3 data cols + 5 metadata = 8 target cols
-- Source: SAP_ECC_T005U_LFA1
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Supplier_Region]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Supplier_Region];

CREATE TABLE [zzSTG_offshore_sunsystems].[Supplier_Region]
(
    [Region]                                        NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Country]                                       NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Supplier_Region]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Supplier_Region];

CREATE TABLE [offshore_sunsystems].[Supplier_Region]
(
    [Region]                                        NVARCHAR(255)             NOT NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Country]                                       NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Supplier_Region]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Supplier_Region];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Supplier_Region]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Supplier_Region]
    WHERE [Region] IN (
        SELECT [Region] FROM [zzSTG_offshore_sunsystems].[Supplier_Region]
        WHERE  [Region] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Supplier_Region]
    (
        [Region],
        [Description],
        [Country],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Region],
        [Description],
        [Country],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Supplier_Region]
    WHERE [Region] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Supplier_Region];
END;
GO

-- ============================================================
-- Suppliers
-- Rows: 15,839  |  55 data cols + 5 metadata = 60 target cols
-- Source: SAP_ECC_LFA1_LFB1_LFM1_LFBK
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Suppliers]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Suppliers];

CREATE TABLE [zzSTG_offshore_sunsystems].[Suppliers]
(
    [Supplier_Code]                                 NVARCHAR(255)             NULL,
    [Account_Code]                                  NVARCHAR(255)             NULL,
    [Supplier_Name]                                 NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Company_Address_Code]                          NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [whtState]                                      NVARCHAR(255)             NULL,
    [narration]                                     NVARCHAR(255)             NULL,
    [Comment]                                       NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Payment_Terms_Group_Code]                      NVARCHAR(255)             NULL,
    [Payment_Method_Code]                           NVARCHAR(255)             NULL,
    [Direct_Debit_Code]                             NVARCHAR(255)             NULL,
    [Direct_Debit_Description]                      NVARCHAR(255)             NULL,
    [Reconciliation_Account]                        NVARCHAR(255)             NULL,
    [Carrier_Code]                                  NVARCHAR(255)             NULL,
    [Imminent_Settlement_Code]                      NVARCHAR(255)             NULL,
    [Maintain_Statistics_Code]                      NVARCHAR(255)             NULL,
    [Default_Currency_Code]                         NVARCHAR(255)             NULL,
    [Currency]                                      NVARCHAR(255)             NULL,
    [Distribution_Format_Code]                      NVARCHAR(255)             NULL,
    [Distribution_Method_Code]                      NVARCHAR(255)             NULL,
    [Carrier_Description]                           NVARCHAR(255)             NULL,
    [Credit_Check_Warning_Limit]                    NVARCHAR(255)             NULL,
    [sa05]                                          NVARCHAR(255)             NULL,
    [sa06]                                          NVARCHAR(255)             NULL,
    [sa07]                                          NVARCHAR(255)             NULL,
    [sa08]                                          NVARCHAR(255)             NULL,
    [sa09]                                          NVARCHAR(255)             NULL,
    [Days_Tolerance_Override_Code]                  NVARCHAR(255)             NULL,
    [Days_Tolerance_Override_Description]           NVARCHAR(255)             NULL,
    [Earliest_Latest_Cost_Code]                     NVARCHAR(255)             NULL,
    [Earliest_Latest_Cost_Description]              NVARCHAR(255)             NULL,
    [Imminent_Settlement_Description]               NVARCHAR(255)             NULL,
    [Maintain_Statistics_Description]               NVARCHAR(255)             NULL,
    [Payment_Method_Description]                    NVARCHAR(255)             NULL,
    [Price_List]                                    NVARCHAR(255)             NULL,
    [Distribution_Format_Description]               NVARCHAR(255)             NULL,
    [Distribution_Method_Description]               NVARCHAR(255)             NULL,
    [sa10]                                          NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [london_office]                                 NVARCHAR(255)             NULL,
    [paidGoverment]                                 NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_sunsystems].[Suppliers]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Suppliers];

CREATE TABLE [offshore_sunsystems].[Suppliers]
(
    [Supplier_Code]                                 NVARCHAR(255)             NOT NULL,
    [Account_Code]                                  NVARCHAR(255)             NULL,
    [Supplier_Name]                                 NVARCHAR(255)             NULL,
    [Description]                                   NVARCHAR(255)             NULL,
    [Short_Heading]                                 NVARCHAR(255)             NULL,
    [Company_Address_Code]                          NVARCHAR(255)             NULL,
    [Lookup_Code]                                   NVARCHAR(255)             NULL,
    [whtState]                                      NVARCHAR(255)             NULL,
    [narration]                                     NVARCHAR(255)             NULL,
    [Comment]                                       NVARCHAR(255)             NULL,
    [Status_Code]                                   NVARCHAR(255)             NULL,
    [Status_Description]                            NVARCHAR(255)             NULL,
    [Created]                                       NVARCHAR(255)             NULL,
    [Created_By]                                    NVARCHAR(255)             NULL,
    [Date_Time_Last_Updated]                        NVARCHAR(255)             NULL,
    [User_Id_Last_Updated]                          NVARCHAR(255)             NULL,
    [Valid_From]                                    NVARCHAR(255)             NULL,
    [Last_Updated]                                  NVARCHAR(255)             NULL,
    [Last_Updated_By]                               NVARCHAR(255)             NULL,
    [Business_Unit]                                 NVARCHAR(255)             NULL,
    [Payment_Terms_Group_Code]                      NVARCHAR(255)             NULL,
    [Payment_Method_Code]                           NVARCHAR(255)             NULL,
    [Direct_Debit_Code]                             NVARCHAR(255)             NULL,
    [Direct_Debit_Description]                      NVARCHAR(255)             NULL,
    [Reconciliation_Account]                        NVARCHAR(255)             NULL,
    [Carrier_Code]                                  NVARCHAR(255)             NULL,
    [Imminent_Settlement_Code]                      NVARCHAR(255)             NULL,
    [Maintain_Statistics_Code]                      NVARCHAR(255)             NULL,
    [Default_Currency_Code]                         NVARCHAR(255)             NULL,
    [Currency]                                      NVARCHAR(255)             NULL,
    [Distribution_Format_Code]                      NVARCHAR(255)             NULL,
    [Distribution_Method_Code]                      NVARCHAR(255)             NULL,
    [Carrier_Description]                           NVARCHAR(255)             NULL,
    [Credit_Check_Warning_Limit]                    NVARCHAR(255)             NULL,
    [sa05]                                          NVARCHAR(255)             NULL,
    [sa06]                                          NVARCHAR(255)             NULL,
    [sa07]                                          NVARCHAR(255)             NULL,
    [sa08]                                          NVARCHAR(255)             NULL,
    [sa09]                                          NVARCHAR(255)             NULL,
    [Days_Tolerance_Override_Code]                  NVARCHAR(255)             NULL,
    [Days_Tolerance_Override_Description]           NVARCHAR(255)             NULL,
    [Earliest_Latest_Cost_Code]                     NVARCHAR(255)             NULL,
    [Earliest_Latest_Cost_Description]              NVARCHAR(255)             NULL,
    [Imminent_Settlement_Description]               NVARCHAR(255)             NULL,
    [Maintain_Statistics_Description]               NVARCHAR(255)             NULL,
    [Payment_Method_Description]                    NVARCHAR(255)             NULL,
    [Price_List]                                    NVARCHAR(255)             NULL,
    [Distribution_Format_Description]               NVARCHAR(255)             NULL,
    [Distribution_Method_Description]               NVARCHAR(255)             NULL,
    [sa10]                                          NVARCHAR(255)             NULL,
    [Update_Count]                                  NVARCHAR(255)             NULL,
    [Valid_Until]                                   NVARCHAR(255)             NULL,
    [User_Defined_Fields]                           NVARCHAR(255)             NULL,
    [london_office]                                 NVARCHAR(255)             NULL,
    [paidGoverment]                                 NVARCHAR(255)             NULL,
    [load_id]                                       NVARCHAR(100)             NULL,
    [pipeline_run_id]                               NVARCHAR(100)             NULL,
    [source_path]                                   NVARCHAR(500)             NULL,
    [loaded_at]                                     DATETIME2                 NULL,
    [updated_at]                                    DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([Supplier_Code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_sunsystems_Suppliers]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_sunsystems_Suppliers];
GO
CREATE PROCEDURE [dbo].[usp_offshore_sunsystems_Suppliers]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_sunsystems].[Suppliers]
    WHERE [Supplier_Code] IN (
        SELECT [Supplier_Code] FROM [zzSTG_offshore_sunsystems].[Suppliers]
        WHERE  [Supplier_Code] IS NOT NULL);

    INSERT INTO [offshore_sunsystems].[Suppliers]
    (
        [Supplier_Code],
        [Account_Code],
        [Supplier_Name],
        [Description],
        [Short_Heading],
        [Company_Address_Code],
        [Lookup_Code],
        [whtState],
        [narration],
        [Comment],
        [Status_Code],
        [Status_Description],
        [Created],
        [Created_By],
        [Date_Time_Last_Updated],
        [User_Id_Last_Updated],
        [Valid_From],
        [Last_Updated],
        [Last_Updated_By],
        [Business_Unit],
        [Payment_Terms_Group_Code],
        [Payment_Method_Code],
        [Direct_Debit_Code],
        [Direct_Debit_Description],
        [Reconciliation_Account],
        [Carrier_Code],
        [Imminent_Settlement_Code],
        [Maintain_Statistics_Code],
        [Default_Currency_Code],
        [Currency],
        [Distribution_Format_Code],
        [Distribution_Method_Code],
        [Carrier_Description],
        [Credit_Check_Warning_Limit],
        [sa05],
        [sa06],
        [sa07],
        [sa08],
        [sa09],
        [Days_Tolerance_Override_Code],
        [Days_Tolerance_Override_Description],
        [Earliest_Latest_Cost_Code],
        [Earliest_Latest_Cost_Description],
        [Imminent_Settlement_Description],
        [Maintain_Statistics_Description],
        [Payment_Method_Description],
        [Price_List],
        [Distribution_Format_Description],
        [Distribution_Method_Description],
        [sa10],
        [Update_Count],
        [Valid_Until],
        [User_Defined_Fields],
        [london_office],
        [paidGoverment],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [Supplier_Code],
        [Account_Code],
        [Supplier_Name],
        [Description],
        [Short_Heading],
        [Company_Address_Code],
        [Lookup_Code],
        [whtState],
        [narration],
        [Comment],
        [Status_Code],
        [Status_Description],
        [Created],
        [Created_By],
        [Date_Time_Last_Updated],
        [User_Id_Last_Updated],
        [Valid_From],
        [Last_Updated],
        [Last_Updated_By],
        [Business_Unit],
        [Payment_Terms_Group_Code],
        [Payment_Method_Code],
        [Direct_Debit_Code],
        [Direct_Debit_Description],
        [Reconciliation_Account],
        [Carrier_Code],
        [Imminent_Settlement_Code],
        [Maintain_Statistics_Code],
        [Default_Currency_Code],
        [Currency],
        [Distribution_Format_Code],
        [Distribution_Method_Code],
        [Carrier_Description],
        [Credit_Check_Warning_Limit],
        [sa05],
        [sa06],
        [sa07],
        [sa08],
        [sa09],
        [Days_Tolerance_Override_Code],
        [Days_Tolerance_Override_Description],
        [Earliest_Latest_Cost_Code],
        [Earliest_Latest_Cost_Description],
        [Imminent_Settlement_Description],
        [Maintain_Statistics_Description],
        [Payment_Method_Description],
        [Price_List],
        [Distribution_Format_Description],
        [Distribution_Method_Description],
        [sa10],
        [Update_Count],
        [Valid_Until],
        [User_Defined_Fields],
        [london_office],
        [paidGoverment],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_sunsystems].[Suppliers]
    WHERE [Supplier_Code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_sunsystems].[Suppliers];
END;
GO

-- ============================================================
-- WATERMARK — all 20 SunSystems tables → offshore_eam.watermark
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Analysis_Code_Extensions','offshore_sunsystems','SAP_ECC_CSKS','[dbo].[usp_offshore_sunsystems_Analysis_Code_Extensions]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Analysis_Codes','offshore_sunsystems','SAP_ECC_CSKS_AUFK_PRPS','[dbo].[usp_offshore_sunsystems_Analysis_Codes]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Analysis_Dimension_Names','offshore_sunsystems','SAP_ECC_TKA01_CSKA','[dbo].[usp_offshore_sunsystems_Analysis_Dimension_Names]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Analysis_Structures','offshore_sunsystems','SAP_ECC_SETHEADER_CSKT','[dbo].[usp_offshore_sunsystems_Analysis_Structures]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Analysis_Sub_Dimensions','offshore_sunsystems','SAP_ECC_CSKA','[dbo].[usp_offshore_sunsystems_Analysis_Sub_Dimensions]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Budget_Definitions','offshore_sunsystems','SAP_ECC_BPGE_BPJA_OKOB_CSKS','[dbo].[usp_offshore_sunsystems_Budget_Definitions]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Business_Unit_Addresses','offshore_sunsystems','SAP_ECC_T001_ADRC','[dbo].[usp_offshore_sunsystems_Business_Unit_Addresses]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Business_Unit_Details','offshore_sunsystems','SAP_ECC_T001_ADRC_T052','[dbo].[usp_offshore_sunsystems_Business_Unit_Details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Business_Units','offshore_sunsystems','SAP_ECC_T001_TKA01_T005_TCURR','[dbo].[usp_offshore_sunsystems_Business_Units]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Chart_Of_Accounts','offshore_sunsystems','SAP_ECC_SKA1_SKB1_SKAT','[dbo].[usp_offshore_sunsystems_Chart_Of_Accounts]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Currencies','offshore_sunsystems','SAP_ECC_TCURC_TCURT_TCURX','[dbo].[usp_offshore_sunsystems_Currencies]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Currency_Rate_Types','offshore_sunsystems','SAP_ECC_TCURV','[dbo].[usp_offshore_sunsystems_Currency_Rate_Types]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('DateDimension','offshore_sunsystems','SAP_TFACS_GENERATED','[dbo].[usp_offshore_sunsystems_DateDimension]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Employee_Roles','offshore_sunsystems','SAP_ECC_HRP1001_AGR_USERS_PA0001','[dbo].[usp_offshore_sunsystems_Employee_Roles]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Fixed_Assets','offshore_sunsystems','SAP_ECC_ANLA_ANLB_ANLC_ANLZ','[dbo].[usp_offshore_sunsystems_Fixed_Assets]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Journal_Definitions','offshore_sunsystems','SAP_ECC_T003_T003T','[dbo].[usp_offshore_sunsystems_Journal_Definitions]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Ledger_Lines','offshore_sunsystems','SAP_ECC_BKPF_BSEG_BSIS_BSAS','[dbo].[usp_offshore_sunsystems_Ledger_Lines]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Ledger_Setups','offshore_sunsystems','SAP_ECC_T011_T093_T093B','[dbo].[usp_offshore_sunsystems_Ledger_Setups]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Supplier_Region','offshore_sunsystems','SAP_ECC_T005U_LFA1','[dbo].[usp_offshore_sunsystems_Supplier_Region]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('Suppliers','offshore_sunsystems','SAP_ECC_LFA1_LFB1_LFM1_LFBK','[dbo].[usp_offshore_sunsystems_Suppliers]','1900-01-01','initial',0,NULL,@now);


-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT COUNT(*) AS [Analysis_Code_Extensions] FROM [offshore_sunsystems].[Analysis_Code_Extensions];
-- SELECT COUNT(*) AS [Analysis_Codes] FROM [offshore_sunsystems].[Analysis_Codes];
-- SELECT COUNT(*) AS [Analysis_Dimension_Names] FROM [offshore_sunsystems].[Analysis_Dimension_Names];
-- SELECT COUNT(*) AS [Analysis_Structures] FROM [offshore_sunsystems].[Analysis_Structures];
-- SELECT COUNT(*) AS [Analysis_Sub_Dimensions] FROM [offshore_sunsystems].[Analysis_Sub_Dimensions];
-- SELECT COUNT(*) AS [Budget_Definitions] FROM [offshore_sunsystems].[Budget_Definitions];
-- SELECT COUNT(*) AS [Business_Unit_Addresses] FROM [offshore_sunsystems].[Business_Unit_Addresses];
-- SELECT COUNT(*) AS [Business_Unit_Details] FROM [offshore_sunsystems].[Business_Unit_Details];
-- SELECT COUNT(*) AS [Business_Units] FROM [offshore_sunsystems].[Business_Units];
-- SELECT COUNT(*) AS [Chart_Of_Accounts] FROM [offshore_sunsystems].[Chart_Of_Accounts];
-- SELECT COUNT(*) AS [Currencies] FROM [offshore_sunsystems].[Currencies];
-- SELECT COUNT(*) AS [Currency_Rate_Types] FROM [offshore_sunsystems].[Currency_Rate_Types];
-- SELECT COUNT(*) AS [DateDimension] FROM [offshore_sunsystems].[DateDimension];
-- SELECT COUNT(*) AS [Employee_Roles] FROM [offshore_sunsystems].[Employee_Roles];
-- SELECT COUNT(*) AS [Fixed_Assets] FROM [offshore_sunsystems].[Fixed_Assets];
-- SELECT COUNT(*) AS [Journal_Definitions] FROM [offshore_sunsystems].[Journal_Definitions];
-- SELECT COUNT(*) AS [Ledger_Lines] FROM [offshore_sunsystems].[Ledger_Lines];
-- SELECT COUNT(*) AS [Ledger_Setups] FROM [offshore_sunsystems].[Ledger_Setups];
-- SELECT COUNT(*) AS [Supplier_Region] FROM [offshore_sunsystems].[Supplier_Region];
-- SELECT COUNT(*) AS [Suppliers] FROM [offshore_sunsystems].[Suppliers];