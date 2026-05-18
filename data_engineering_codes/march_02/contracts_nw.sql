-- ============================================================
-- Edw_Eam.Rates_vw  - Complete history (2012 to present)
-- Source: EnterpriseAssetManagement only
--
-- UNION ALL across every table that carries an exchange rate + date:
--   1. Invoice_Voucher_Details         (Invoice_Voucher_date       - most accurate)
--   2. Invoice_Voucher_Line_Details     (Created                    - line-level rates)
--   3. Purchase_Order_Details           (Purchase_Order_Created     - committed spend)
--   4. Purchase_Order_Parts_Details     (Purchase_Order_Parts_Due   - parts line rates)
--   5. Purchase_Order_Services_Details  (Purchase_Order_Services_Due- svc line rates)
--   6. Requisitions_Parts_Details       (Requisitions_Parts_due     - earliest demand)
--   7. Requisitions_Services_Details    (Requisitions_Services_due  - earliest demand)
--   8. Quotation_Requests_Parts_Details (Quotation_Requests_Parts_Created - RFQ rates)
--   9. Quotation_Requests_Services_Details
--
-- Final output: one row per Base_Currency + Exchange_Rate value
--   Base_Currency  = Org_Curr from Organisation_Details
--   Start_Date     = MIN date that rate first appears across all sources
--   End_Date       = MAX date that rate last  appears across all sources
--   Exchange_Rate  = DECIMAL(18,9) - no float scientific notation
-- ============================================================

USE [EnterpriseAssetManagement];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Edw_Eam')
    EXEC('CREATE SCHEMA [Edw_Eam]');
GO

IF OBJECT_ID('[Edw_Eam].[Rates_vw]', 'V') IS NOT NULL
    DROP VIEW [Edw_Eam].[Rates_vw];
GO

CREATE VIEW [Edw_Eam].[Rates_vw]
AS

WITH All_Rates AS (

    -- 1. Invoice Vouchers - primary source, real transaction dates
    SELECT
        iv.[Invoice_Voucher_org]                                AS Org_Code,
        iv.[Invoice_Voucher_curr]                               AS Transaction_Currency,
        CAST(iv.[Invoice_Voucher_exch] AS DECIMAL(18,9))        AS Exchange_Rate,
        iv.[Invoice_Voucher_date]                               AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
    WHERE iv.[Latest_Indicator]       = 1
      AND iv.[Invoice_Voucher_exch]   IS NOT NULL
      AND iv.[Invoice_Voucher_exch]   <> 0
      AND iv.[Invoice_Voucher_curr]   IS NOT NULL
      AND iv.[Invoice_Voucher_date]   IS NOT NULL

    UNION ALL

    -- 2. Invoice Voucher Lines - catches line-level overrides
    SELECT
        ivl.[Invoice_Voucher_Line_invoice_org]                          AS Org_Code,
        ivl.[Invoice_Voucher_Line_curr]                                 AS Transaction_Currency,
        CAST(ivl.[Invoice_Voucher_Line_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(ivl.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]     AS ivl
    WHERE ivl.[Latest_Indicator]            = 1
      AND ivl.[Invoice_Voucher_Line_exch]   IS NOT NULL
      AND ivl.[Invoice_Voucher_Line_exch]   <> 0
      AND ivl.[Invoice_Voucher_Line_curr]   IS NOT NULL
      AND ivl.[Created]                     IS NOT NULL

    UNION ALL

    -- 3. Purchase Orders - covers committed spend, oldest records
    SELECT
        po.[Purchase_Order_Organization_Code]                           AS Org_Code,
        po.[Purchase_Order_Currency]                                    AS Transaction_Currency,
        CAST(po.[Purchase_Order_Exchange] AS DECIMAL(18,9))             AS Exchange_Rate,
        po.[Purchase_Order_Created]                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
    WHERE po.[Latest_Indicator]             = 1
      AND po.[Purchase_Order_Exchange]      IS NOT NULL
      AND po.[Purchase_Order_Exchange]      <> 0
      AND po.[Purchase_Order_Currency]      IS NOT NULL
      AND po.[Purchase_Order_Created]       IS NOT NULL

    UNION ALL

    -- 4. PO Parts Lines - line-level exchange, dated by due date
    SELECT
        pop.[Purchase_Order_Parts_Order_Organization]                   AS Org_Code,
        pop.[Purchase_Order_Parts_Currency]                             AS Transaction_Currency,
        CAST(pop.[Purchase_Order_Parts_Exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(pop.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
    WHERE pop.[Latest_Indicator]                = 1
      AND pop.[Purchase_Order_Parts_Exch]       IS NOT NULL
      AND pop.[Purchase_Order_Parts_Exch]       <> 0
      AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
      AND pop.[Created]                         IS NOT NULL

    UNION ALL

    -- 5. PO Services Lines
    SELECT
        pos.[Purchase_Order_Services_Order_Organization]                AS Org_Code,
        pos.[Purchase_Order_Services_Currency]                          AS Transaction_Currency,
        CAST(pos.[Purchase_Order_Services_Exch] AS DECIMAL(18,9))       AS Exchange_Rate,
        CAST(pos.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]  AS pos
    WHERE pos.[Latest_Indicator]                    = 1
      AND pos.[Purchase_Order_Services_Exch]        IS NOT NULL
      AND pos.[Purchase_Order_Services_Exch]        <> 0
      AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
      AND pos.[Created]                             IS NOT NULL

    UNION ALL

    -- 6. Requisitions Parts - earliest demand records, go back furthest
    SELECT
        rp.[Requisitions_Parts_Organization]                            AS Org_Code,
        rp.[Requisitions_Parts_curr]                                    AS Transaction_Currency,
        CAST(rp.[Requisitions_Parts_exch] AS DECIMAL(18,9))             AS Exchange_Rate,
        CAST(rp.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
    WHERE rp.[Latest_Indicator]             = 1
      AND rp.[Requisitions_Parts_exch]      IS NOT NULL
      AND rp.[Requisitions_Parts_exch]      <> 0
      AND rp.[Requisitions_Parts_curr]      IS NOT NULL
      AND rp.[Created]                      IS NOT NULL

    UNION ALL

    -- 7. Requisitions Services
    SELECT
        rs.[Requisitions_Services_Organization]                         AS Org_Code,
        rs.[Requisitions_Services_curr]                                 AS Transaction_Currency,
        CAST(rs.[Requisitions_Services_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(rs.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]    AS rs
    WHERE rs.[Latest_Indicator]                 = 1
      AND rs.[Requisitions_Services_exch]       IS NOT NULL
      AND rs.[Requisitions_Services_exch]       <> 0
      AND rs.[Requisitions_Services_curr]       IS NOT NULL
      AND rs.[Created]                          IS NOT NULL

    UNION ALL

    -- 8. Quotation Request Parts - RFQ stage, pre-PO, oldest pipeline
    SELECT
        qrp.[Quotation_Requests_Parts_Rfq_Organization]                 AS Org_Code,
        qrp.[Quotation_Requests_Parts_Curr]                             AS Transaction_Currency,
        CAST(qrp.[Quotation_Requests_Parts_Exch] AS DECIMAL(18,9))      AS Exchange_Rate,
        qrp.[Quotation_Requests_Parts_Created]                          AS Rate_Date
    FROM [EnterpriseAssetManagement].[Quotation_Requests_Parts_Details] AS qrp
    WHERE qrp.[Latest_Indicator]                    = 1
      AND qrp.[Quotation_Requests_Parts_Exch]       IS NOT NULL
      AND qrp.[Quotation_Requests_Parts_Exch]       <> 0
      AND qrp.[Quotation_Requests_Parts_Curr]       IS NOT NULL
      AND qrp.[Quotation_Requests_Parts_Created]    IS NOT NULL

    UNION ALL

    -- 9. Quotation Request Services
    SELECT
        qrs.[Quotation_Requests_Services_Rfq_Org]                           AS Org_Code,
        qrs.[Quotation_Requests_Services_Curr]                              AS Transaction_Currency,
        CAST(qrs.[Quotation_Requests_Services_Exch] AS DECIMAL(18,9))       AS Exchange_Rate,
        qrs.[Quotation_Requests_Services_Created]                           AS Rate_Date
    FROM [EnterpriseAssetManagement].[Quotation_Requests_Services_Details]  AS qrs
    WHERE qrs.[Latest_Indicator]                        = 1
      AND qrs.[Quotation_Requests_Services_Exch]        IS NOT NULL
      AND qrs.[Quotation_Requests_Services_Exch]        <> 0
      AND qrs.[Quotation_Requests_Services_Curr]        IS NOT NULL
      AND qrs.[Quotation_Requests_Services_Created]     IS NOT NULL

),

-- Join org to get Base_Currency, then collapse to one row per rate value
Rates_With_Base AS (
    SELECT
        org.[Org_Curr]          AS Base_Currency,
        ar.[Exchange_Rate],
        ar.[Rate_Date]
    FROM All_Rates              AS ar
    INNER JOIN [EnterpriseAssetManagement].[Organisation_Details] AS org
            ON ar.[Org_Code]        = org.[Org_Code]
           AND org.[Latest_Indicator] = 1
    WHERE org.[Org_Curr] IS NOT NULL
)

SELECT
    [Base_Currency],
    MIN([Rate_Date])            AS Start_Date,
    MAX([Rate_Date])            AS End_Date,
    [Exchange_Rate]
FROM Rates_With_Base
GROUP BY
    [Base_Currency],
    [Exchange_Rate];
GO


-- ============================================================
-- Validation - check date range covers 2012+
-- ============================================================
-- SELECT [Base_Currency], MIN([Start_Date]) AS Earliest, MAX([End_Date]) AS Latest, COUNT(*) AS Rate_Count
-- FROM [Edw_Eam].[Rates_vw]
-- GROUP BY [Base_Currency]
-- ORDER BY Earliest;

-- SELECT TOP 100 [Base_Currency],[Start_Date],[End_Date],[Exchange_Rate]
-- FROM [Edw_Eam].[Rates_vw]
-- ORDER BY [Start_Date] ASC;
-- ============================================================