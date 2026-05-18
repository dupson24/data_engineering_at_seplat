-- ============================================================
-- FIX 1 — Ledger_Lines staging: add missing Entry_Period col
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Ledger_Lines]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Ledger_Lines];

CREATE TABLE [zzSTG_offshore_sunsystems].[Ledger_Lines]
(
    [Business_Unit]                               NVARCHAR(255)   NULL,
    [Journal_Number]                              NVARCHAR(255)   NULL,
    [Journal_Line_Number]                         INT             NULL,
    [Account_Code]                                NVARCHAR(255)   NULL,
    [Debit_Credit_Code]                           NVARCHAR(255)   NULL,
    [Base_Amount_Amount]                          DECIMAL(18,4)   NULL,
    [Transaction_Amount]                          DECIMAL(18,4)   NULL,
    [Base2_Reporting_Amount]                      DECIMAL(18,4)   NULL,
    [Base_Debit_Amount]                           DECIMAL(18,4)   NULL,
    [Base_Credit_Amount]                          DECIMAL(18,4)   NULL,
    [Transaction_Debit_Amount]                    DECIMAL(18,4)   NULL,
    [Transaction_Credit_Amount]                   DECIMAL(18,4)   NULL,
    [Reporting_Debit_Amount]                      DECIMAL(18,4)   NULL,
    [Reporting_Credit_Amount]                     DECIMAL(18,4)   NULL,
    [Description]                                 NVARCHAR(255)   NULL,
    [Allocation_Reference]                        NVARCHAR(255)   NULL,
    [Supplier]                                    NVARCHAR(255)   NULL,
    [Locations]                                   NVARCHAR(255)   NULL,
    [Afe]                                         NVARCHAR(255)   NULL,
    [Wbs]                                         NVARCHAR(255)   NULL,
    [Due_Date]                                    NVARCHAR(255)   NULL,    -- DATE → NVARCHAR (SAP date safety)
    [Tax]                                         NVARCHAR(255)   NULL,
    [Contract]                                    NVARCHAR(255)   NULL,
    [Billing]                                     NVARCHAR(255)   NULL,
    [Project]                                     NVARCHAR(255)   NULL,
    [Employee]                                    NVARCHAR(255)   NULL,
    [Journal_Type]                                NVARCHAR(255)   NULL,
    [Transaction_Reference]                       NVARCHAR(255)   NULL,
    [Currency_Code]                               NVARCHAR(255)   NULL,
    [Currency_Rate]                               DECIMAL(18,4)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Journal_Source]                              NVARCHAR(255)   NULL,
    [Accounting_Period]                           NVARCHAR(255)   NULL,
    [Entry_Date]                                  NVARCHAR(255)   NULL,    -- DATE → NVARCHAR
    [Entry_Period]                                NVARCHAR(255)   NULL,    -- ← ADDED (was missing)
    [Ledger_Code]                                 NVARCHAR(255)   NULL,
    [Narration]                                   NVARCHAR(255)   NULL,
    [Allocation_Marker_Code]                      NVARCHAR(255)   NULL,
    [Department]                                  NVARCHAR(255)   NULL,
    [Managementacc]                               NVARCHAR(255)   NULL,
    [Whtstate]                                    NVARCHAR(255)   NULL,
    [Uap]                                         NVARCHAR(255)   NULL,
    [Coalevel1]                                   NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL,
    [Permanent_Posting_Date]                      NVARCHAR(255)   NULL,    -- DATE → NVARCHAR
    [Transaction_Date]                            NVARCHAR(255)   NULL,    -- DATE → NVARCHAR
    [Entityjv]                                    NVARCHAR(255)   NULL,
    [Jvbilling]                                   NVARCHAR(255)   NULL,
    [Lifecycle]                                   NVARCHAR(255)   NULL,
    [Summarycoa]                                  NVARCHAR(255)   NULL,
    [Workingcapital]                              NVARCHAR(255)   NULL,
    [Cashflow]                                    NVARCHAR(255)   NULL,
    [Financialacc]                                NVARCHAR(255)   NULL,
    [Coalevel2]                                   NVARCHAR(255)   NULL,
    [Cutback]                                     NVARCHAR(255)   NULL,
    [Costallocation]                              NVARCHAR(255)   NULL,
    [Paidgovernment]                              NVARCHAR(255)   NULL,
    [Legacyassetco]                               NVARCHAR(255)   NULL,
    [Legacysupplier]                              NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);


-- ============================================================
-- FIX 2 — Business_Unit_Addresses: DATE cols → NVARCHAR
-- Root cause: SAP 00000000 dates produce negative ticks
-- Fix: store all date cols as NVARCHAR, cast in SP
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Business_Unit_Addresses]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Addresses];

CREATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Addresses]
(
    [Address_Code]                                NVARCHAR(255)   NULL,
    [Business_Unit]                               NVARCHAR(255)   NULL,
    [Invoice_Address_Code]                        NVARCHAR(255)   NULL,
    [Own_Company_Code]                            NVARCHAR(255)   NULL,
    [Business_Unit_Address_Short_Heading]         NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_1]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_2]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_3]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Town_City]             NVARCHAR(255)   NULL,
    [Business_Unit_Address_State]                 NVARCHAR(255)   NULL,
    [Business_Unit_Address_Country]               NVARCHAR(255)   NULL,
    [Business_Unit_Address_Telex_Fax_Number]      NVARCHAR(255)   NULL,
    [Business_Unit_Address_Language_Code]         NVARCHAR(255)   NULL,
    [Business_Unit_Address_Comment]               NVARCHAR(255)   NULL,
    [Business_Unit_Address_Date_Time_Last_Updated] NVARCHAR(255)  NULL,    -- was DATE
    [Valid_From]                                  NVARCHAR(255)   NULL,    -- was DATE
    [Business_Unit_Address_Lookup_Code]           NVARCHAR(255)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Business_Unit_Address_Status_Code]           NVARCHAR(255)   NULL,
    [Business_Unit_Address_Status_Description]    NVARCHAR(255)   NULL,
    [Business_Unit_Address_Temporary_Address_Code] NVARCHAR(255)  NULL,
    [Business_Unit_Address_Temporary_Address_Description] NVARCHAR(255) NULL,
    [Business_Unit_Address_Update_Count]          NVARCHAR(255)   NULL,
    [Business_Unit_Address_User_Id_Last_Updated]  NVARCHAR(255)   NULL,
    [Date_Time_Last_Updated]                      NVARCHAR(255)   NULL,
    [Update_Count]                                NVARCHAR(255)   NULL,
    [User_Id_Last_Updated]                        NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL,
    [Valid_Until]                                 NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);


-- ============================================================
-- FIX 3 — Business_Unit_Details: DATE cols → NVARCHAR
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_sunsystems].[Business_Unit_Details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Details];

CREATE TABLE [zzSTG_offshore_sunsystems].[Business_Unit_Details]
(
    [Invoice_Address_Code]                        NVARCHAR(255)   NULL,
    [Business_Unit]                               NVARCHAR(255)   NULL,
    [Name]                                        NVARCHAR(255)   NULL,
    [Description]                                 NVARCHAR(255)   NULL,
    [Short_Heading]                               NVARCHAR(255)   NULL,
    [Own_Company_Code]                            NVARCHAR(255)   NULL,
    [Invoice_Short_Heading]                       NVARCHAR(255)   NULL,
    [Invoice_Language_Code]                       NVARCHAR(255)   NULL,
    [Invoice_Country]                             NVARCHAR(255)   NULL,
    [Invoice_Town_City]                           NVARCHAR(255)   NULL,
    [Lookup_Code]                                 NVARCHAR(255)   NULL,
    [Payment_Receipt_Method_Code]                 NVARCHAR(255)   NULL,
    [Payment_Terms_Lookup_Code]                   NVARCHAR(255)   NULL,
    [Date_Time_Last_Updated]                      NVARCHAR(255)   NULL,
    [Invoice_Address_Line1]                       NVARCHAR(255)   NULL,
    [Invoice_Address_Line2]                       NVARCHAR(255)   NULL,
    [Invoice_Address_Line3]                       NVARCHAR(255)   NULL,
    [Invoice_Comment]                             NVARCHAR(255)   NULL,
    [Invoice_State]                               NVARCHAR(255)   NULL,
    [Invoice_Telephone_Number]                    NVARCHAR(255)   NULL,
    [InvoiceTelexFaxNumber]                       NVARCHAR(255)   NULL,
    [Invoice_Lookup_Code]                         NVARCHAR(255)   NULL,
    [Invoice_Date_Time_Last_Updated]              NVARCHAR(255)   NULL,    -- was DATE
    [Valid_From]                                  NVARCHAR(255)   NULL,    -- was DATE
    [Payment_Terms_Group_Code_def]                NVARCHAR(255)   NULL,
    [Payment_Terms_Description]                   NVARCHAR(255)   NULL,
    [Preferred_Payment_Method_Code]               NVARCHAR(255)   NULL,
    [Payment_Terms_Document1_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Document2_Description]         NVARCHAR(255)   NULL,
    [Invoice_Status_Code]                         NVARCHAR(255)   NULL,
    [Invoice_Status_Description]                  NVARCHAR(255)   NULL,
    [Email_Address]                               NVARCHAR(255)   NULL,
    [Invoice_Temporary_Address_Code]              NVARCHAR(255)   NULL,
    [Invoice_Temporary_Address_Description]       NVARCHAR(255)   NULL,
    [Invoice_Update_Count]                        NVARCHAR(255)   NULL,
    [Invoice_User_Id_Last_Updated]                NVARCHAR(255)   NULL,
    [Payment_Receipt_Method_Description]          NVARCHAR(255)   NULL,
    [Payment_Terms_Date_Time_Last_Updated]        NVARCHAR(255)   NULL,
    [Payment_Terms_Document3_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Document4_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Short_Heading]                 NVARCHAR(255)   NULL,
    [Payment_Terms_Update_Count]                  NVARCHAR(255)   NULL,
    [Payment_Terms_User_Id_Last_Updated]          NVARCHAR(255)   NULL,
    [Preferred_Payment_Method_Description]        NVARCHAR(255)   NULL,
    [Update_Count]                                NVARCHAR(255)   NULL,
    [User_Id_Last_Updated]                        NVARCHAR(255)   NULL,
    [Web_Page_Address]                            NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL,
    [Valid_Until]                                 NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);


-- ============================================================
-- Also fix target tables to match (drop + recreate)
-- ============================================================

-- Ledger_Lines target — add Entry_Period + all dates as NVARCHAR
IF OBJECT_ID('[offshore_sunsystems].[Ledger_Lines]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Ledger_Lines];

CREATE TABLE [offshore_sunsystems].[Ledger_Lines]
(
    [Business_Unit]                               NVARCHAR(255)   NOT NULL,
    [Journal_Number]                              NVARCHAR(255)   NOT NULL,
    [Journal_Line_Number]                         INT             NULL,
    [Account_Code]                                NVARCHAR(255)   NULL,
    [Debit_Credit_Code]                           NVARCHAR(255)   NULL,
    [Base_Amount_Amount]                          DECIMAL(18,4)   NULL,
    [Transaction_Amount]                          DECIMAL(18,4)   NULL,
    [Base2_Reporting_Amount]                      DECIMAL(18,4)   NULL,
    [Base_Debit_Amount]                           DECIMAL(18,4)   NULL,
    [Base_Credit_Amount]                          DECIMAL(18,4)   NULL,
    [Transaction_Debit_Amount]                    DECIMAL(18,4)   NULL,
    [Transaction_Credit_Amount]                   DECIMAL(18,4)   NULL,
    [Reporting_Debit_Amount]                      DECIMAL(18,4)   NULL,
    [Reporting_Credit_Amount]                     DECIMAL(18,4)   NULL,
    [Description]                                 NVARCHAR(255)   NULL,
    [Allocation_Reference]                        NVARCHAR(255)   NULL,
    [Supplier]                                    NVARCHAR(255)   NULL,
    [Locations]                                   NVARCHAR(255)   NULL,
    [Afe]                                         NVARCHAR(255)   NULL,
    [Wbs]                                         NVARCHAR(255)   NULL,
    [Due_Date]                                    NVARCHAR(255)   NULL,
    [Tax]                                         NVARCHAR(255)   NULL,
    [Contract]                                    NVARCHAR(255)   NULL,
    [Billing]                                     NVARCHAR(255)   NULL,
    [Project]                                     NVARCHAR(255)   NULL,
    [Employee]                                    NVARCHAR(255)   NULL,
    [Journal_Type]                                NVARCHAR(255)   NULL,
    [Transaction_Reference]                       NVARCHAR(255)   NULL,
    [Currency_Code]                               NVARCHAR(255)   NULL,
    [Currency_Rate]                               DECIMAL(18,4)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Journal_Source]                              NVARCHAR(255)   NULL,
    [Accounting_Period]                           NVARCHAR(255)   NULL,
    [Entry_Date]                                  NVARCHAR(255)   NULL,
    [Entry_Period]                                NVARCHAR(255)   NULL,
    [Ledger_Code]                                 NVARCHAR(255)   NULL,
    [Narration]                                   NVARCHAR(255)   NULL,
    [Allocation_Marker_Code]                      NVARCHAR(255)   NULL,
    [Department]                                  NVARCHAR(255)   NULL,
    [Managementacc]                               NVARCHAR(255)   NULL,
    [Whtstate]                                    NVARCHAR(255)   NULL,
    [Uap]                                         NVARCHAR(255)   NULL,
    [Coalevel1]                                   NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL,
    [Permanent_Posting_Date]                      NVARCHAR(255)   NULL,
    [Transaction_Date]                            NVARCHAR(255)   NULL,
    [Entityjv]                                    NVARCHAR(255)   NULL,
    [Jvbilling]                                   NVARCHAR(255)   NULL,
    [Lifecycle]                                   NVARCHAR(255)   NULL,
    [Summarycoa]                                  NVARCHAR(255)   NULL,
    [Workingcapital]                              NVARCHAR(255)   NULL,
    [Cashflow]                                    NVARCHAR(255)   NULL,
    [Financialacc]                                NVARCHAR(255)   NULL,
    [Coalevel2]                                   NVARCHAR(255)   NULL,
    [Cutback]                                     NVARCHAR(255)   NULL,
    [Costallocation]                              NVARCHAR(255)   NULL,
    [Paidgovernment]                              NVARCHAR(255)   NULL,
    [Legacyassetco]                               NVARCHAR(255)   NULL,
    [Legacysupplier]                              NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL,
    [load_id]                                     NVARCHAR(100)   NULL,
    [pipeline_run_id]                             NVARCHAR(100)   NULL,
    [source_path]                                 NVARCHAR(500)   NULL,
    [loaded_at]                                   DATETIME2       NULL,
    [updated_at]                                  DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([Journal_Number]), CLUSTERED COLUMNSTORE INDEX);


-- Business_Unit_Addresses target
IF OBJECT_ID('[offshore_sunsystems].[Business_Unit_Addresses]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Business_Unit_Addresses];

CREATE TABLE [offshore_sunsystems].[Business_Unit_Addresses]
(
    [Address_Code]                                NVARCHAR(255)   NULL,
    [Business_Unit]                               NVARCHAR(255)   NOT NULL,
    [Invoice_Address_Code]                        NVARCHAR(255)   NULL,
    [Own_Company_Code]                            NVARCHAR(255)   NULL,
    [Business_Unit_Address_Short_Heading]         NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_1]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_2]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Line_3]                NVARCHAR(255)   NULL,
    [Business_Unit_Address_Town_City]             NVARCHAR(255)   NULL,
    [Business_Unit_Address_State]                 NVARCHAR(255)   NULL,
    [Business_Unit_Address_Country]               NVARCHAR(255)   NULL,
    [Business_Unit_Address_Telex_Fax_Number]      NVARCHAR(255)   NULL,
    [Business_Unit_Address_Language_Code]         NVARCHAR(255)   NULL,
    [Business_Unit_Address_Comment]               NVARCHAR(255)   NULL,
    [Business_Unit_Address_Date_Time_Last_Updated] NVARCHAR(255)  NULL,
    [Valid_From]                                  NVARCHAR(255)   NULL,
    [Business_Unit_Address_Lookup_Code]           NVARCHAR(255)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Business_Unit_Address_Status_Code]           NVARCHAR(255)   NULL,
    [Business_Unit_Address_Status_Description]    NVARCHAR(255)   NULL,
    [Business_Unit_Address_Temporary_Address_Code] NVARCHAR(255)  NULL,
    [Business_Unit_Address_Temporary_Address_Description] NVARCHAR(255) NULL,
    [Business_Unit_Address_Update_Count]          NVARCHAR(255)   NULL,
    [Business_Unit_Address_User_Id_Last_Updated]  NVARCHAR(255)   NULL,
    [Date_Time_Last_Updated]                      NVARCHAR(255)   NULL,
    [Update_Count]                                NVARCHAR(255)   NULL,
    [User_Id_Last_Updated]                        NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL,
    [Valid_Until]                                 NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL,
    [load_id]                                     NVARCHAR(100)   NULL,
    [pipeline_run_id]                             NVARCHAR(100)   NULL,
    [source_path]                                 NVARCHAR(500)   NULL,
    [loaded_at]                                   DATETIME2       NULL,
    [updated_at]                                  DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);


-- Business_Unit_Details target
IF OBJECT_ID('[offshore_sunsystems].[Business_Unit_Details]','U') IS NOT NULL
    DROP TABLE [offshore_sunsystems].[Business_Unit_Details];

CREATE TABLE [offshore_sunsystems].[Business_Unit_Details]
(
    [Invoice_Address_Code]                        NVARCHAR(255)   NULL,
    [Business_Unit]                               NVARCHAR(255)   NOT NULL,
    [Name]                                        NVARCHAR(255)   NULL,
    [Description]                                 NVARCHAR(255)   NULL,
    [Short_Heading]                               NVARCHAR(255)   NULL,
    [Own_Company_Code]                            NVARCHAR(255)   NULL,
    [Invoice_Short_Heading]                       NVARCHAR(255)   NULL,
    [Invoice_Language_Code]                       NVARCHAR(255)   NULL,
    [Invoice_Country]                             NVARCHAR(255)   NULL,
    [Invoice_Town_City]                           NVARCHAR(255)   NULL,
    [Lookup_Code]                                 NVARCHAR(255)   NULL,
    [Payment_Receipt_Method_Code]                 NVARCHAR(255)   NULL,
    [Payment_Terms_Lookup_Code]                   NVARCHAR(255)   NULL,
    [Date_Time_Last_Updated]                      NVARCHAR(255)   NULL,
    [Invoice_Address_Line1]                       NVARCHAR(255)   NULL,
    [Invoice_Address_Line2]                       NVARCHAR(255)   NULL,
    [Invoice_Address_Line3]                       NVARCHAR(255)   NULL,
    [Invoice_Comment]                             NVARCHAR(255)   NULL,
    [Invoice_State]                               NVARCHAR(255)   NULL,
    [Invoice_Telephone_Number]                    NVARCHAR(255)   NULL,
    [InvoiceTelexFaxNumber]                       NVARCHAR(255)   NULL,
    [Invoice_Lookup_Code]                         NVARCHAR(255)   NULL,
    [Invoice_Date_Time_Last_Updated]              NVARCHAR(255)   NULL,
    [Valid_From]                                  NVARCHAR(255)   NULL,
    [Payment_Terms_Group_Code_def]                NVARCHAR(255)   NULL,
    [Payment_Terms_Description]                   NVARCHAR(255)   NULL,
    [Preferred_Payment_Method_Code]               NVARCHAR(255)   NULL,
    [Payment_Terms_Document1_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Document2_Description]         NVARCHAR(255)   NULL,
    [Invoice_Status_Code]                         NVARCHAR(255)   NULL,
    [Invoice_Status_Description]                  NVARCHAR(255)   NULL,
    [Email_Address]                               NVARCHAR(255)   NULL,
    [Invoice_Temporary_Address_Code]              NVARCHAR(255)   NULL,
    [Invoice_Temporary_Address_Description]       NVARCHAR(255)   NULL,
    [Invoice_Update_Count]                        NVARCHAR(255)   NULL,
    [Invoice_User_Id_Last_Updated]                NVARCHAR(255)   NULL,
    [Payment_Receipt_Method_Description]          NVARCHAR(255)   NULL,
    [Payment_Terms_Date_Time_Last_Updated]        NVARCHAR(255)   NULL,
    [Payment_Terms_Document3_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Document4_Description]         NVARCHAR(255)   NULL,
    [Payment_Terms_Short_Heading]                 NVARCHAR(255)   NULL,
    [Payment_Terms_Update_Count]                  NVARCHAR(255)   NULL,
    [Payment_Terms_User_Id_Last_Updated]          NVARCHAR(255)   NULL,
    [Preferred_Payment_Method_Description]        NVARCHAR(255)   NULL,
    [Update_Count]                                NVARCHAR(255)   NULL,
    [User_Id_Last_Updated]                        NVARCHAR(255)   NULL,
    [Web_Page_Address]                            NVARCHAR(255)   NULL,
    [User_Defined_Fields]                         NVARCHAR(255)   NULL,
    [Valid_Until]                                 NVARCHAR(255)   NULL,
    [Created]                                     NVARCHAR(255)   NULL,
    [Created_By]                                  NVARCHAR(255)   NULL,
    [Last_Updated]                                NVARCHAR(255)   NULL,
    [Last_Updated_By]                             NVARCHAR(255)   NULL,
    [load_id]                                     NVARCHAR(100)   NULL,
    [pipeline_run_id]                             NVARCHAR(100)   NULL,
    [source_path]                                 NVARCHAR(500)   NULL,\
    [loaded_at]                                   DATETIME2       NULL,
    [updated_at]                                  DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- Validation
-- ============================================================
-- SELECT COUNT(*) FROM [zzSTG_offshore_sunsystems].[Ledger_Lines];
-- SELECT COUNT(*) FROM [zzSTG_offshore_sunsystems].[Business_Unit_Addresses];
-- SELECT COUNT(*) FROM [zzSTG_offshore_sunsystems].[Business_Unit_Details];
-- SELECT COUNT(*) FROM [offshore_sunsystems].[Ledger_Lines];
-- SELECT COUNT(*) FROM [offshore_sunsystems].[Business_Unit_Addresses];
-- SELECT COUNT(*) FROM [offshore_sunsystems].[Business_Unit_Details];