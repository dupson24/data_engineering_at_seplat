-- ============================================================
-- Edw_Eam.Contracts_vw  - corrected
--
-- Source screen: "Blanket Orders" dropdown -> Contract view
-- Contract column  = Purchase_Order_Code  (e.g. 502574, 502571)
-- Description      = Purchase_Order_Description
-- Organization     = Purchase_Order_Organization_Code
-- Supplier         = Purchase_Order_Supplier  (code e.g. 3007432)
-- Supplier Desc    = Purchase_Order_Supplier_Description
-- Status           = Purchase_Order_Status_Description
-- Store            = Purchase_Order_Store
-- Buyer            = Purchase_Order_Buyer
-- Maximum Value    = Part_Lines_Value + Service_Lines_Value
--                    (total ordered value on the blanket)
-- Currency         = Purchase_Order_Currency
-- Start Date       = Purchase_Order_Created
-- End Date         = Purchase_Order_Due_Date
-- Released Value   = Subtotal_Part_Value + Subtotal_Service_Value
--                    (what has been released/receipted so far)
-- Remaining Value  = Maximum_Value - Released_Value
--
-- All float -> DECIMAL(18,2) to fix 2.15288E+12 rendering
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

    -- Maximum Value = total value of all lines on the blanket order
    CAST(
        COALESCE([Purchase_Order_Part_Lines_Value],    0)
      + COALESCE([Purchase_Order_Service_Lines_Value], 0)
    AS DECIMAL(18,2))                                                   AS Maximum_Value,

    [Purchase_Order_Currency]                                           AS Currency,
    [Purchase_Order_Created]                                            AS Start_Date,
    [Purchase_Order_Due_Date]                                           AS End_Date,

    -- Released Value = subtotal receipted/released against the blanket
    CAST(
        COALESCE([Purchase_Order_Subtotal_Part_Value],    0)
      + COALESCE([Purchase_Order_Subtotal_Service_Value], 0)
    AS DECIMAL(18,2))                                                   AS Released_Value,

    -- Remaining Value = Maximum - Released
    CAST(
       (COALESCE([Purchase_Order_Part_Lines_Value],    0) + COALESCE([Purchase_Order_Service_Lines_Value], 0))
     - (COALESCE([Purchase_Order_Subtotal_Part_Value], 0) + COALESCE([Purchase_Order_Subtotal_Service_Value], 0))
    AS DECIMAL(18,2))                                                   AS Remaining_Value

FROM [EnterpriseAssetManagement].[Purchase_Order_Details]
WHERE [Latest_Indicator] = 1;
GO


-- ============================================================
-- Validation - should match screenshot rows exactly
-- ============================================================
-- SELECT TOP 100
--     [Contract],[Description],[Organization],
--     [Supplier],[Supplier_Description],[Status],
--     [Store],[Buyer],[Maximum_Value],[Currency],
--     [Start_Date],[End_Date],[Released_Value],[Remaining_Value]
-- FROM [Edw_Eam].[Contracts_vw]
-- ORDER BY [Contract] DESC;

-- Spot check against screenshot:
-- SELECT * FROM [Edw_Eam].[Contracts_vw]
-- WHERE [Contract] IN ('502574','502571','502570','502569','502568');
-- ============================================================