-- ============================================================
-- Edw_Eam.Rates_vw  - All base currencies, full history 2012+
--
-- FIX: Previous version used INNER JOIN on a single Org_Code column
--      causing most rows to be dropped -> only one Base_Currency showing.
--
-- Solution:
--   1. LEFT JOIN Organisation_Details on EVERY org column per table
--   2. COALESCE across all org joins to get Base_Currency
--   3. Fall back to Transaction_Currency when no org resolves
--      (self-rates where transaction IS the base)
--   4. UNION ALL across all 9 rate-bearing tables
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

    -- 1. Invoice Voucher Headers
    --    Org columns: Invoice_Voucher_org, Invoice_Voucher_order_org
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], iv.[Invoice_Voucher_curr])
                                                                AS Base_Currency,
        iv.[Invoice_Voucher_curr]                               AS Transaction_Currency,
        CAST(iv.[Invoice_Voucher_exch] AS DECIMAL(18,9))        AS Exchange_Rate,
        iv.[Invoice_Voucher_date]                               AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o1
           ON iv.[Invoice_Voucher_org]       = o1.[Org_Code]
          AND o1.[Latest_Indicator]          = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o2
           ON iv.[Invoice_Voucher_order_org] = o2.[Org_Code]
          AND o2.[Latest_Indicator]          = 1
    WHERE iv.[Latest_Indicator]             = 1
      AND iv.[Invoice_Voucher_exch]         IS NOT NULL
      AND iv.[Invoice_Voucher_exch]         <> 0
      AND iv.[Invoice_Voucher_curr]         IS NOT NULL
      AND iv.[Invoice_Voucher_date]         IS NOT NULL

    UNION ALL

    -- 2. Invoice Voucher Lines
    --    Org columns: Invoice_Voucher_Line_invoice_org, Invoice_Voucher_Line_order_org
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])
                                                                        AS Base_Currency,
        ivl.[Invoice_Voucher_Line_curr]                                 AS Transaction_Currency,
        CAST(ivl.[Invoice_Voucher_Line_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(ivl.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]     AS ivl
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON ivl.[Invoice_Voucher_Line_invoice_org] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                  = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON ivl.[Invoice_Voucher_Line_order_org]   = o2.[Org_Code]
          AND o2.[Latest_Indicator]                  = 1
    WHERE ivl.[Latest_Indicator]                = 1
      AND ivl.[Invoice_Voucher_Line_exch]       IS NOT NULL
      AND ivl.[Invoice_Voucher_Line_exch]       <> 0
      AND ivl.[Invoice_Voucher_Line_curr]       IS NOT NULL
      AND ivl.[Created]                         IS NOT NULL

    UNION ALL

    -- 3. Purchase Order Headers
    --    Org columns: Purchase_Order_Organization_Code, Purchase_Order_Supplier_Organization_Code
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], po.[Purchase_Order_Currency])
                                                                        AS Base_Currency,
        po.[Purchase_Order_Currency]                                    AS Transaction_Currency,
        CAST(po.[Purchase_Order_Exchange] AS DECIMAL(18,9))             AS Exchange_Rate,
        po.[Purchase_Order_Created]                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON po.[Purchase_Order_Organization_Code]          = o1.[Org_Code]
          AND o1.[Latest_Indicator]                          = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON po.[Purchase_Order_Supplier_Organization_Code] = o2.[Org_Code]
          AND o2.[Latest_Indicator]                          = 1
    WHERE po.[Latest_Indicator]             = 1
      AND po.[Purchase_Order_Exchange]      IS NOT NULL
      AND po.[Purchase_Order_Exchange]      <> 0
      AND po.[Purchase_Order_Currency]      IS NOT NULL
      AND po.[Purchase_Order_Created]       IS NOT NULL

    UNION ALL

    -- 4. Purchase Order Parts Lines
    --    Org columns: Purchase_Order_Parts_Order_Organization, Purchase_Order_Parts_Part_Organization
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], pop.[Purchase_Order_Parts_Currency])
                                                                        AS Base_Currency,
        pop.[Purchase_Order_Parts_Currency]                             AS Transaction_Currency,
        CAST(pop.[Purchase_Order_Parts_Exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(pop.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON pop.[Purchase_Order_Parts_Order_Organization] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                         = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON pop.[Purchase_Order_Parts_Part_Organization]  = o2.[Org_Code]
          AND o2.[Latest_Indicator]                         = 1
    WHERE pop.[Latest_Indicator]                = 1
      AND pop.[Purchase_Order_Parts_Exch]       IS NOT NULL
      AND pop.[Purchase_Order_Parts_Exch]       <> 0
      AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
      AND pop.[Created]                         IS NOT NULL

    UNION ALL

    -- 5. Purchase Order Services Lines
    --    Org columns: Purchase_Order_Services_Order_Organization, Purchase_Order_Services_Part_Organization
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], pos.[Purchase_Order_Services_Currency])
                                                                        AS Base_Currency,
        pos.[Purchase_Order_Services_Currency]                          AS Transaction_Currency,
        CAST(pos.[Purchase_Order_Services_Exch] AS DECIMAL(18,9))       AS Exchange_Rate,
        CAST(pos.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]  AS pos
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON pos.[Purchase_Order_Services_Order_Organization] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                            = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON pos.[Purchase_Order_Services_Part_Organization]  = o2.[Org_Code]
          AND o2.[Latest_Indicator]                            = 1
    WHERE pos.[Latest_Indicator]                    = 1
      AND pos.[Purchase_Order_Services_Exch]        IS NOT NULL
      AND pos.[Purchase_Order_Services_Exch]        <> 0
      AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
      AND pos.[Created]                             IS NOT NULL

    UNION ALL

    -- 6. Requisitions Parts  (oldest demand records - reaches back to 2012)
    --    Org columns: Requisitions_Parts_Organization, Requisitions_Parts_part_org
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], rp.[Requisitions_Parts_curr])
                                                                        AS Base_Currency,
        rp.[Requisitions_Parts_curr]                                    AS Transaction_Currency,
        CAST(rp.[Requisitions_Parts_exch] AS DECIMAL(18,9))             AS Exchange_Rate,
        CAST(rp.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON rp.[Requisitions_Parts_Organization] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON rp.[Requisitions_Parts_part_org]     = o2.[Org_Code]
          AND o2.[Latest_Indicator]                = 1
    WHERE rp.[Latest_Indicator]             = 1
      AND rp.[Requisitions_Parts_exch]      IS NOT NULL
      AND rp.[Requisitions_Parts_exch]      <> 0
      AND rp.[Requisitions_Parts_curr]      IS NOT NULL
      AND rp.[Created]                      IS NOT NULL

    UNION ALL

    -- 7. Requisitions Services  (oldest demand records)
    --    Org columns: Requisitions_Services_Organization, Requisitions_Services_part_org
    SELECT
        COALESCE(o1.[Org_Curr], o2.[Org_Curr], rs.[Requisitions_Services_curr])
                                                                        AS Base_Currency,
        rs.[Requisitions_Services_curr]                                 AS Transaction_Currency,
        CAST(rs.[Requisitions_Services_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(rs.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]    AS rs
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON rs.[Requisitions_Services_Organization] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                   = 1
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o2
           ON rs.[Requisitions_Services_part_org]     = o2.[Org_Code]
          AND o2.[Latest_Indicator]                   = 1
    WHERE rs.[Latest_Indicator]                 = 1
      AND rs.[Requisitions_Services_exch]       IS NOT NULL
      AND rs.[Requisitions_Services_exch]       <> 0
      AND rs.[Requisitions_Services_curr]       IS NOT NULL
      AND rs.[Created]                          IS NOT NULL

    UNION ALL

    -- 8. Quotation Request Parts  (RFQ stage, pre-PO pipeline)
    --    Org column: Quotation_Requests_Parts_Rfq_Organization
    SELECT
        COALESCE(o1.[Org_Curr], qrp.[Quotation_Requests_Parts_Curr])    AS Base_Currency,
        qrp.[Quotation_Requests_Parts_Curr]                             AS Transaction_Currency,
        CAST(qrp.[Quotation_Requests_Parts_Exch] AS DECIMAL(18,9))      AS Exchange_Rate,
        qrp.[Quotation_Requests_Parts_Created]                          AS Rate_Date
    FROM [EnterpriseAssetManagement].[Quotation_Requests_Parts_Details] AS qrp
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o1
           ON qrp.[Quotation_Requests_Parts_Rfq_Organization] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                           = 1
    WHERE qrp.[Latest_Indicator]                    = 1
      AND qrp.[Quotation_Requests_Parts_Exch]       IS NOT NULL
      AND qrp.[Quotation_Requests_Parts_Exch]       <> 0
      AND qrp.[Quotation_Requests_Parts_Curr]       IS NOT NULL
      AND qrp.[Quotation_Requests_Parts_Created]    IS NOT NULL

    UNION ALL

    -- 9. Quotation Request Services
    --    Org column: Quotation_Requests_Services_Rfq_Org
    SELECT
        COALESCE(o1.[Org_Curr], qrs.[Quotation_Requests_Services_Curr]) AS Base_Currency,
        qrs.[Quotation_Requests_Services_Curr]                          AS Transaction_Currency,
        CAST(qrs.[Quotation_Requests_Services_Exch] AS DECIMAL(18,9))   AS Exchange_Rate,
        qrs.[Quotation_Requests_Services_Created]                       AS Rate_Date
    FROM [EnterpriseAssetManagement].[Quotation_Requests_Services_Details] AS qrs
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]           AS o1
           ON qrs.[Quotation_Requests_Services_Rfq_Org] = o1.[Org_Code]
          AND o1.[Latest_Indicator]                     = 1
    WHERE qrs.[Latest_Indicator]                        = 1
      AND qrs.[Quotation_Requests_Services_Exch]        IS NOT NULL
      AND qrs.[Quotation_Requests_Services_Exch]        <> 0
      AND qrs.[Quotation_Requests_Services_Curr]        IS NOT NULL
      AND qrs.[Quotation_Requests_Services_Created]     IS NOT NULL

)

-- Final output: collapse to one row per Base_Currency + Exchange_Rate
-- Start_Date = earliest date this rate appears, End_Date = latest
SELECT
    [Base_Currency],
    MIN([Rate_Date])    AS Start_Date,
    MAX([Rate_Date])    AS End_Date,
    [Exchange_Rate]
FROM All_Rates
WHERE [Base_Currency]   IS NOT NULL
  AND [Exchange_Rate]   IS NOT NULL
GROUP BY
    [Base_Currency],
    [Exchange_Rate];
GO


-- ============================================================
-- Validation
-- ============================================================
-- Check all base currencies present:
-- SELECT DISTINCT [Base_Currency] FROM [Edw_Eam].[Rates_vw] ORDER BY 1;

-- Check full date range per currency:
-- SELECT [Base_Currency], MIN([Start_Date]) AS Earliest, MAX([End_Date]) AS Latest, COUNT(*) AS Rates
-- FROM [Edw_Eam].[Rates_vw]
-- GROUP BY [Base_Currency] ORDER BY Earliest;

-- Spot check USD rates:
-- SELECT * FROM [Edw_Eam].[Rates_vw] WHERE [Base_Currency] = 'USD' ORDER BY [Start_Date];
-- ============================================================