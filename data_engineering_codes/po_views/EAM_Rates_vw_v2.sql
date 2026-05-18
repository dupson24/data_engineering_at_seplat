-- ============================================================
-- Edw_Eam.Rates_vw  -  Complete: Base Currency + NGN (Dual)
-- Source: EnterpriseAssetManagement only
--
-- EAM dual currency explanation:
--   _exch        = rate between Transaction Currency and Base Currency
--   _exchfromdual= rate FROM the dual currency (NGN) to base
--   _exchtodual  = rate TO the dual currency (NGN) from transaction
--
-- Three rate legs captured per source table:
--   Leg 1: Transaction currency vs Org base  (_exch)
--   Leg 2: Dual (NGN) to base               (_exchfromdual)
--   Leg 3: Transaction to dual (NGN)         (_exchtodual)
--
-- Sources (all carry dual columns + dates):
--   1. Invoice_Voucher_Details
--   2. Invoice_Voucher_Line_Details
--   3. Purchase_Order_Details
--   4. Purchase_Order_Parts_Details
--   5. Purchase_Order_Services_Details
--   6. Requisitions_Parts_Details
--   7. Requisitions_Services_Details
--
-- Output: Base_Currency | Transaction_Currency | Start_Date | End_Date | Exchange_Rate
--         Start_Date = End_Date = the transaction's effective date
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

    -- =========================================================
    -- 1. INVOICE VOUCHER HEADERS
    -- =========================================================

    -- Leg 1: Transaction currency vs Base
    SELECT
        COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])       AS Base_Currency,
        iv.[Invoice_Voucher_curr]                               AS Transaction_Currency,
        CAST(iv.[Invoice_Voucher_exch] AS DECIMAL(18,9))        AS Exchange_Rate,
        iv.[Invoice_Voucher_date]                               AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o
           ON iv.[Invoice_Voucher_org] = o.[Org_Code]
          AND o.[Latest_Indicator]     = 1
    WHERE iv.[Latest_Indicator]        = 1
      AND iv.[Invoice_Voucher_exch]    IS NOT NULL
      AND iv.[Invoice_Voucher_exch]    <> 0
      AND iv.[Invoice_Voucher_curr]    IS NOT NULL
      AND iv.[Invoice_Voucher_date]    IS NOT NULL

    UNION ALL

    -- Leg 2: Dual (NGN) from-dual rate vs Base
    SELECT
        COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])       AS Base_Currency,
        'NGN'                                                   AS Transaction_Currency,
        CAST(iv.[Invoice_Voucher_exchfromdual] AS DECIMAL(18,9)) AS Exchange_Rate,
        iv.[Invoice_Voucher_date]                               AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o
           ON iv.[Invoice_Voucher_org] = o.[Org_Code]
          AND o.[Latest_Indicator]     = 1
    WHERE iv.[Latest_Indicator]             = 1
      AND iv.[Invoice_Voucher_exchfromdual] IS NOT NULL
      AND iv.[Invoice_Voucher_exchfromdual] <> 0
      AND iv.[Invoice_Voucher_date]         IS NOT NULL

    UNION ALL

    -- Leg 3: Transaction to Dual (NGN) rate
    SELECT
        iv.[Invoice_Voucher_curr]                               AS Base_Currency,
        'NGN'                                                   AS Transaction_Currency,
        CAST(iv.[Invoice_Voucher_exchtodual] AS DECIMAL(18,9))  AS Exchange_Rate,
        iv.[Invoice_Voucher_date]                               AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
    WHERE iv.[Latest_Indicator]             = 1
      AND iv.[Invoice_Voucher_exchtodual]   IS NOT NULL
      AND iv.[Invoice_Voucher_exchtodual]   <> 0
      AND iv.[Invoice_Voucher_curr]         IS NOT NULL
      AND iv.[Invoice_Voucher_date]         IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 2. INVOICE VOUCHER LINES
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])         AS Base_Currency,
        ivl.[Invoice_Voucher_Line_curr]                                 AS Transaction_Currency,
        CAST(ivl.[Invoice_Voucher_Line_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(ivl.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]     AS ivl
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON ivl.[Invoice_Voucher_Line_invoice_org] = o.[Org_Code]
          AND o.[Latest_Indicator]                   = 1
    WHERE ivl.[Latest_Indicator]              = 1
      AND ivl.[Invoice_Voucher_Line_exch]     IS NOT NULL
      AND ivl.[Invoice_Voucher_Line_exch]     <> 0
      AND ivl.[Invoice_Voucher_Line_curr]     IS NOT NULL
      AND ivl.[Created]                       IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])             AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(ivl.[Invoice_Voucher_Line_exchfromdual] AS DECIMAL(18,9))      AS Exchange_Rate,
        CAST(ivl.[Created] AS DATE)                                         AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]         AS ivl
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
           ON ivl.[Invoice_Voucher_Line_invoice_org] = o.[Org_Code]
          AND o.[Latest_Indicator]                   = 1
    WHERE ivl.[Latest_Indicator]                        = 1
      AND ivl.[Invoice_Voucher_Line_exchfromdual]       IS NOT NULL
      AND ivl.[Invoice_Voucher_Line_exchfromdual]       <> 0
      AND ivl.[Created]                                 IS NOT NULL

    UNION ALL

    SELECT
        ivl.[Invoice_Voucher_Line_curr]                                     AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(ivl.[Invoice_Voucher_Line_exchtodual] AS DECIMAL(18,9))        AS Exchange_Rate,
        CAST(ivl.[Created] AS DATE)                                         AS Rate_Date
    FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]         AS ivl
    WHERE ivl.[Latest_Indicator]                    = 1
      AND ivl.[Invoice_Voucher_Line_exchtodual]     IS NOT NULL
      AND ivl.[Invoice_Voucher_Line_exchtodual]     <> 0
      AND ivl.[Invoice_Voucher_Line_curr]           IS NOT NULL
      AND ivl.[Created]                             IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 3. PURCHASE ORDER HEADERS
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])            AS Base_Currency,
        po.[Purchase_Order_Currency]                                    AS Transaction_Currency,
        CAST(po.[Purchase_Order_Exchange] AS DECIMAL(18,9))             AS Exchange_Rate,
        po.[Purchase_Order_Created]                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON po.[Purchase_Order_Organization_Code] = o.[Org_Code]
          AND o.[Latest_Indicator]                  = 1
    WHERE po.[Latest_Indicator]             = 1
      AND po.[Purchase_Order_Exchange]      IS NOT NULL
      AND po.[Purchase_Order_Exchange]      <> 0
      AND po.[Purchase_Order_Currency]      IS NOT NULL
      AND po.[Purchase_Order_Created]       IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])            AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(po.[Purchase_Order_Exch_From_Dual] AS DECIMAL(18,9))       AS Exchange_Rate,
        po.[Purchase_Order_Created]                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON po.[Purchase_Order_Organization_Code] = o.[Org_Code]
          AND o.[Latest_Indicator]                  = 1
    WHERE po.[Latest_Indicator]                 = 1
      AND po.[Purchase_Order_Exch_From_Dual]    IS NOT NULL
      AND po.[Purchase_Order_Exch_From_Dual]    <> 0
      AND po.[Purchase_Order_Created]           IS NOT NULL

    UNION ALL

    SELECT
        po.[Purchase_Order_Currency]                                    AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(po.[Purchase_Order_Exch_To_Dual] AS DECIMAL(18,9))         AS Exchange_Rate,
        po.[Purchase_Order_Created]                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
    WHERE po.[Latest_Indicator]                 = 1
      AND po.[Purchase_Order_Exch_To_Dual]      IS NOT NULL
      AND po.[Purchase_Order_Exch_To_Dual]      <> 0
      AND po.[Purchase_Order_Currency]          IS NOT NULL
      AND po.[Purchase_Order_Created]           IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 4. PURCHASE ORDER PARTS LINES
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])     AS Base_Currency,
        pop.[Purchase_Order_Parts_Currency]                             AS Transaction_Currency,
        CAST(pop.[Purchase_Order_Parts_Exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(pop.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON pop.[Purchase_Order_Parts_Order_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                          = 1
    WHERE pop.[Latest_Indicator]                = 1
      AND pop.[Purchase_Order_Parts_Exch]       IS NOT NULL
      AND pop.[Purchase_Order_Parts_Exch]       <> 0
      AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
      AND pop.[Created]                         IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])     AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(pop.[Purchase_Order_Parts_Exchfromdual] AS DECIMAL(18,9))  AS Exchange_Rate,
        CAST(pop.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON pop.[Purchase_Order_Parts_Order_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                          = 1
    WHERE pop.[Latest_Indicator]                    = 1
      AND pop.[Purchase_Order_Parts_Exchfromdual]   IS NOT NULL
      AND pop.[Purchase_Order_Parts_Exchfromdual]   <> 0
      AND pop.[Created]                             IS NOT NULL

    UNION ALL

    SELECT
        pop.[Purchase_Order_Parts_Currency]                             AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(pop.[Purchase_Order_Parts_Exchtodual] AS DECIMAL(18,9))    AS Exchange_Rate,
        CAST(pop.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
    WHERE pop.[Latest_Indicator]                = 1
      AND pop.[Purchase_Order_Parts_Exchtodual] IS NOT NULL
      AND pop.[Purchase_Order_Parts_Exchtodual] <> 0
      AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
      AND pop.[Created]                         IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 5. PURCHASE ORDER SERVICES LINES
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])  AS Base_Currency,
        pos.[Purchase_Order_Services_Currency]                          AS Transaction_Currency,
        CAST(pos.[Purchase_Order_Services_Exch] AS DECIMAL(18,9))       AS Exchange_Rate,
        CAST(pos.[Created] AS DATE)                                     AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]  AS pos
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON pos.[Purchase_Order_Services_Order_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                             = 1
    WHERE pos.[Latest_Indicator]                    = 1
      AND pos.[Purchase_Order_Services_Exch]        IS NOT NULL
      AND pos.[Purchase_Order_Services_Exch]        <> 0
      AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
      AND pos.[Created]                             IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])      AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(pos.[Purchase_Order_Services_Exchfromdual] AS DECIMAL(18,9))   AS Exchange_Rate,
        CAST(pos.[Created] AS DATE)                                         AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]      AS pos
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
           ON pos.[Purchase_Order_Services_Order_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                             = 1
    WHERE pos.[Latest_Indicator]                        = 1
      AND pos.[Purchase_Order_Services_Exchfromdual]    IS NOT NULL
      AND pos.[Purchase_Order_Services_Exchfromdual]    <> 0
      AND pos.[Created]                                 IS NOT NULL

    UNION ALL

    SELECT
        pos.[Purchase_Order_Services_Currency]                              AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(pos.[Purchase_Order_Services_Exchtodual] AS DECIMAL(18,9))     AS Exchange_Rate,
        CAST(pos.[Created] AS DATE)                                         AS Rate_Date
    FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]      AS pos
    WHERE pos.[Latest_Indicator]                    = 1
      AND pos.[Purchase_Order_Services_Exchtodual]  IS NOT NULL
      AND pos.[Purchase_Order_Services_Exchtodual]  <> 0
      AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
      AND pos.[Created]                             IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 6. REQUISITIONS PARTS  (oldest records - reaches 2012)
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])            AS Base_Currency,
        rp.[Requisitions_Parts_curr]                                    AS Transaction_Currency,
        CAST(rp.[Requisitions_Parts_exch] AS DECIMAL(18,9))             AS Exchange_Rate,
        CAST(rp.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON rp.[Requisitions_Parts_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                 = 1
    WHERE rp.[Latest_Indicator]             = 1
      AND rp.[Requisitions_Parts_exch]      IS NOT NULL
      AND rp.[Requisitions_Parts_exch]      <> 0
      AND rp.[Requisitions_Parts_curr]      IS NOT NULL
      AND rp.[Created]                      IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])            AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(rp.[Requisitions_Parts_exchfromdual] AS DECIMAL(18,9))     AS Exchange_Rate,
        CAST(rp.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON rp.[Requisitions_Parts_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                 = 1
    WHERE rp.[Latest_Indicator]                     = 1
      AND rp.[Requisitions_Parts_exchfromdual]      IS NOT NULL
      AND rp.[Requisitions_Parts_exchfromdual]      <> 0
      AND rp.[Created]                              IS NOT NULL

    UNION ALL

    SELECT
        rp.[Requisitions_Parts_curr]                                    AS Base_Currency,
        'NGN'                                                           AS Transaction_Currency,
        CAST(rp.[Requisitions_Parts_exchtodual] AS DECIMAL(18,9))       AS Exchange_Rate,
        CAST(rp.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
    WHERE rp.[Latest_Indicator]                 = 1
      AND rp.[Requisitions_Parts_exchtodual]    IS NOT NULL
      AND rp.[Requisitions_Parts_exchtodual]    <> 0
      AND rp.[Requisitions_Parts_curr]          IS NOT NULL
      AND rp.[Created]                          IS NOT NULL

    UNION ALL

    -- =========================================================
    -- 7. REQUISITIONS SERVICES  (oldest records - reaches 2012)
    -- =========================================================

    SELECT
        COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])         AS Base_Currency,
        rs.[Requisitions_Services_curr]                                 AS Transaction_Currency,
        CAST(rs.[Requisitions_Services_exch] AS DECIMAL(18,9))          AS Exchange_Rate,
        CAST(rs.[Created] AS DATE)                                      AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]    AS rs
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
           ON rs.[Requisitions_Services_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                    = 1
    WHERE rs.[Latest_Indicator]                 = 1
      AND rs.[Requisitions_Services_exch]       IS NOT NULL
      AND rs.[Requisitions_Services_exch]       <> 0
      AND rs.[Requisitions_Services_curr]       IS NOT NULL
      AND rs.[Created]                          IS NOT NULL

    UNION ALL

    SELECT
        COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])             AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(rs.[Requisitions_Services_exchfromdual] AS DECIMAL(18,9))      AS Exchange_Rate,
        CAST(rs.[Created] AS DATE)                                          AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]        AS rs
    LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
           ON rs.[Requisitions_Services_Organization] = o.[Org_Code]
          AND o.[Latest_Indicator]                    = 1
    WHERE rs.[Latest_Indicator]                         = 1
      AND rs.[Requisitions_Services_exchfromdual]       IS NOT NULL
      AND rs.[Requisitions_Services_exchfromdual]       <> 0
      AND rs.[Created]                                  IS NOT NULL

    UNION ALL

    SELECT
        rs.[Requisitions_Services_curr]                                     AS Base_Currency,
        'NGN'                                                               AS Transaction_Currency,
        CAST(rs.[Requisitions_Services_exchtodual] AS DECIMAL(18,9))        AS Exchange_Rate,
        CAST(rs.[Created] AS DATE)                                          AS Rate_Date
    FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]        AS rs
    WHERE rs.[Latest_Indicator]                     = 1
      AND rs.[Requisitions_Services_exchtodual]     IS NOT NULL
      AND rs.[Requisitions_Services_exchtodual]     <> 0
      AND rs.[Requisitions_Services_curr]           IS NOT NULL
      AND rs.[Created]                              IS NOT NULL

)

-- ============================================================
-- Final output: one distinct row per Base_Currency +
--   Transaction_Currency + Rate_Date + Exchange_Rate.
-- Start_Date = End_Date = the rate's own effective date,
-- matching the EAM screen which shows the same date in both
-- columns (e.g. 31-12-2026 / 31-12-2026).
-- ============================================================
SELECT DISTINCT
    [Base_Currency],
    [Transaction_Currency],
    [Rate_Date]             AS Start_Date,
    [Rate_Date]             AS End_Date,
    [Exchange_Rate]
FROM All_Rates
WHERE [Base_Currency]   IS NOT NULL
  AND [Exchange_Rate]   IS NOT NULL
  AND [Exchange_Rate]   <> 0;
GO


-- ============================================================
-- Validation
-- ============================================================
-- All currencies including NGN:
-- SELECT DISTINCT [Base_Currency] FROM [Edw_Eam].[Rates_vw] ORDER BY 1;

-- Date range check - should show 2012 through present:
-- SELECT [Base_Currency], MIN([Start_Date]) Earliest, MAX([End_Date]) Latest, COUNT(*) Rates
-- FROM [Edw_Eam].[Rates_vw]
-- GROUP BY [Base_Currency] ORDER BY Earliest;

-- NGN specific check:
-- SELECT [Base_Currency],[Start_Date],[End_Date],[Exchange_Rate]
-- FROM [Edw_Eam].[Rates_vw]
-- WHERE [Base_Currency] = 'NGN' OR [Base_Currency] = 'USD'
-- ORDER BY [Start_Date];
-- ============================================================
