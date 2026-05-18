-- ============================================================
-- Edw_Eam.Contracts_vw  v4  -  Corrected dates & values
--
-- Source screen: Blanket Orders -> Contract view
--
-- COLUMN MAPPING (verified against EAM Data Dictionary):
--   Contract         = Purchase_Order_Code
--   Description      = Purchase_Order_Description
--   Organization     = Purchase_Order_Organization_Code
--   Supplier         = Purchase_Order_Supplier
--   Supplier Desc    = Purchase_Order_Supplier_Description
--   Status           = Purchase_Order_Status_Description
--   Store            = Purchase_Order_Store
--   Buyer            = Purchase_Order_Buyer
--   Maximum Value    = Purchase_Order_Part_Lines_Value
--                    + Purchase_Order_Service_Lines_Value
--                      (total value of all lines on the blanket)
--   Currency         = Purchase_Order_Currency
--   Start Date       = Purchase_Order_Approv
--                      (contract approval/effective date — NOT Created)
--   End Date         = Purchase_Order_Due_Date
--   Released Value   = Purchase_Order_Subtotal_Part_Value
--                    + Purchase_Order_Subtotal_Service_Value
--                      (cumulative receipted/invoiced value)
--   Remaining Value  = Maximum_Value - Released_Value
--
-- NOTE: Purchase_Order_Created is the PO creation date (earlier
--       than approval). The screen Start Date matches Approv.
--       Purchase_Order_Due_Date is the contract expiry date.
-- ============================================================

USE [EnterpriseAssetManagement];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Edw_Eam')
    EXEC('CREATE SCHEMA [Edw_Eam]');
GO

IF OBJECT_ID('[Edw_Eam].[Contracts_vw]', 'V') IS NOT NULL
    DROP VIEW [Edw_Eam].[Contracts_vw];
GO

CREATE VIEW [Edw_Eam].[Contracts_vw]
AS
SELECT
    [Purchase_Order_Code]                                               AS Contract,
    [Purchase_Order_Description]                                        AS Description,
    [Purchase_Order_Organization_Code]                                  AS Organization,
    [Purchase_Order_Supplier]                                           AS Supplier,
    [Purchase_Order_Supplier_Description]                               AS Supplier_Description,
    [Purchase_Order_Status_Description]                                 AS Status,
    [Purchase_Order_Store]                                              AS Store,
    [Purchase_Order_Buyer]                                              AS Buyer,

    -- Maximum Value: total ordered value across all part and service lines
    CAST(
        COALESCE([Purchase_Order_Part_Lines_Value],    0)
      + COALESCE([Purchase_Order_Service_Lines_Value], 0)
    AS DECIMAL(18,2))                                                   AS Maximum_Value,

    [Purchase_Order_Currency]                                           AS Currency,

    -- Start Date: contract approval/effective date (not PO creation date)
    [Purchase_Order_Approv]                                             AS Start_Date,

    -- End Date: contract expiry / due date
    [Purchase_Order_Due_Date]                                           AS End_Date,

    -- Released Value: cumulative receipted/invoiced value to date
    CAST(
        COALESCE([Purchase_Order_Subtotal_Part_Value],    0)
      + COALESCE([Purchase_Order_Subtotal_Service_Value], 0)
    AS DECIMAL(18,2))                                                   AS Released_Value,

    -- Remaining Value: unspent contract balance
    CAST(
       (COALESCE([Purchase_Order_Part_Lines_Value],    0) + COALESCE([Purchase_Order_Service_Lines_Value], 0))
     - (COALESCE([Purchase_Order_Subtotal_Part_Value], 0) + COALESCE([Purchase_Order_Subtotal_Service_Value], 0))
    AS DECIMAL(18,2))                                                   AS Remaining_Value

FROM [EnterpriseAssetManagement].[Purchase_Order_Details]
WHERE [Latest_Indicator] = 1;
GO


-- ============================================================
-- Validation queries
-- ============================================================

-- Top 20 contracts sorted by Contract desc (matches screen order)
-- SELECT TOP 20
--     [Contract],[Description],[Organization],
--     [Supplier],[Supplier_Description],[Status],
--     [Store],[Buyer],[Maximum_Value],[Currency],
--     [Start_Date],[End_Date],[Released_Value],[Remaining_Value]
-- FROM [Edw_Eam].[Contracts_vw]
-- ORDER BY [Contract] DESC;

-- Spot check exact rows visible in screenshot:
-- SELECT *
-- FROM [Edw_Eam].[Contracts_vw]
-- WHERE [Contract] IN ('502574','502571','502570','502569','502568','502567','502566','502565','502563','502561')
-- ORDER BY [Contract] DESC;

-- Sanity check: confirm Start_Date <= End_Date for all rows
-- SELECT COUNT(*) AS Bad_Date_Order
-- FROM [Edw_Eam].[Contracts_vw]
-- WHERE [Start_Date] > [End_Date];

-- Check for NULLs in key date fields
-- SELECT
--     SUM(CASE WHEN [Start_Date] IS NULL THEN 1 ELSE 0 END) AS Null_Start,
--     SUM(CASE WHEN [End_Date]   IS NULL THEN 1 ELSE 0 END) AS Null_End
-- FROM [Edw_Eam].[Contracts_vw];