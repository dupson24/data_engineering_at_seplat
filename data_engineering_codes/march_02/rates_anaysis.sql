-- ============================================================
-- Individual leg validation queries
-- Run each block separately to verify data before UNION ALL
-- Check: Base_Currency variety, NGN presence, date range, row count
-- ============================================================


-- ============================================================
-- 1a. Invoice Voucher Headers - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY iv.[Invoice_Voucher_date];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])       AS Base_Currency,
    COUNT(*)                                                AS Row_Count,
    MIN(iv.[Invoice_Voucher_date])                          AS Earliest,
    MAX(iv.[Invoice_Voucher_date])                          AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o
       ON iv.[Invoice_Voucher_org] = o.[Org_Code]
      AND o.[Latest_Indicator]     = 1
WHERE iv.[Latest_Indicator]        = 1
  AND iv.[Invoice_Voucher_exch]    IS NOT NULL
  AND iv.[Invoice_Voucher_exch]    <> 0
  AND iv.[Invoice_Voucher_curr]    IS NOT NULL
  AND iv.[Invoice_Voucher_date]    IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])
ORDER BY 1;


-- ============================================================
-- 1b. Invoice Voucher Headers - NGN From-Dual
-- ============================================================
SELECT TOP 100
    COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])        AS Base_Currency,
    'NGN'                                                    AS Transaction_Currency,
    CAST(iv.[Invoice_Voucher_exchfromdual] AS DECIMAL(18,9)) AS Exchange_Rate,
    iv.[Invoice_Voucher_date]                                AS Rate_Date
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]   AS iv
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o
       ON iv.[Invoice_Voucher_org] = o.[Org_Code]
      AND o.[Latest_Indicator]     = 1
WHERE iv.[Latest_Indicator]             = 1
  AND iv.[Invoice_Voucher_exchfromdual] IS NOT NULL
  AND iv.[Invoice_Voucher_exchfromdual] <> 0
  AND iv.[Invoice_Voucher_date]         IS NOT NULL
ORDER BY iv.[Invoice_Voucher_date];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])        AS Base_Currency,
    COUNT(*)                                                 AS Row_Count,
    MIN(iv.[Invoice_Voucher_date])                           AS Earliest,
    MAX(iv.[Invoice_Voucher_date])                           AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]   AS iv
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details] AS o
       ON iv.[Invoice_Voucher_org] = o.[Org_Code]
      AND o.[Latest_Indicator]     = 1
WHERE iv.[Latest_Indicator]             = 1
  AND iv.[Invoice_Voucher_exchfromdual] IS NOT NULL
  AND iv.[Invoice_Voucher_exchfromdual] <> 0
  AND iv.[Invoice_Voucher_date]         IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], iv.[Invoice_Voucher_curr])
ORDER BY 1;


-- ============================================================
-- 1c. Invoice Voucher Headers - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY iv.[Invoice_Voucher_date];

-- Summary
SELECT
    iv.[Invoice_Voucher_curr]                               AS Base_Currency,
    COUNT(*)                                                AS Row_Count,
    MIN(iv.[Invoice_Voucher_date])                          AS Earliest,
    MAX(iv.[Invoice_Voucher_date])                          AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Details]  AS iv
WHERE iv.[Latest_Indicator]             = 1
  AND iv.[Invoice_Voucher_exchtodual]   IS NOT NULL
  AND iv.[Invoice_Voucher_exchtodual]   <> 0
  AND iv.[Invoice_Voucher_curr]         IS NOT NULL
  AND iv.[Invoice_Voucher_date]         IS NOT NULL
GROUP BY iv.[Invoice_Voucher_curr]
ORDER BY 1;


-- ============================================================
-- 2a. Invoice Voucher Lines - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY ivl.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])         AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(ivl.[Created] AS DATE))                                AS Earliest,
    MAX(CAST(ivl.[Created] AS DATE))                                AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]     AS ivl
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON ivl.[Invoice_Voucher_Line_invoice_org] = o.[Org_Code]
      AND o.[Latest_Indicator]                   = 1
WHERE ivl.[Latest_Indicator]              = 1
  AND ivl.[Invoice_Voucher_Line_exch]     IS NOT NULL
  AND ivl.[Invoice_Voucher_Line_exch]     <> 0
  AND ivl.[Invoice_Voucher_Line_curr]     IS NOT NULL
  AND ivl.[Created]                       IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])
ORDER BY 1;


-- ============================================================
-- 2b. Invoice Voucher Lines - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY ivl.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])             AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(ivl.[Created] AS DATE))                                    AS Earliest,
    MAX(CAST(ivl.[Created] AS DATE))                                    AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]         AS ivl
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
       ON ivl.[Invoice_Voucher_Line_invoice_org] = o.[Org_Code]
      AND o.[Latest_Indicator]                   = 1
WHERE ivl.[Latest_Indicator]                        = 1
  AND ivl.[Invoice_Voucher_Line_exchfromdual]       IS NOT NULL
  AND ivl.[Invoice_Voucher_Line_exchfromdual]       <> 0
  AND ivl.[Created]                                 IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], ivl.[Invoice_Voucher_Line_curr])
ORDER BY 1;


-- ============================================================
-- 2c. Invoice Voucher Lines - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY ivl.[Created];

-- Summary
SELECT
    ivl.[Invoice_Voucher_Line_curr]                                     AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(ivl.[Created] AS DATE))                                    AS Earliest,
    MAX(CAST(ivl.[Created] AS DATE))                                    AS Latest
FROM [EnterpriseAssetManagement].[Invoice_Voucher_Line_Details]         AS ivl
WHERE ivl.[Latest_Indicator]                    = 1
  AND ivl.[Invoice_Voucher_Line_exchtodual]     IS NOT NULL
  AND ivl.[Invoice_Voucher_Line_exchtodual]     <> 0
  AND ivl.[Invoice_Voucher_Line_curr]           IS NOT NULL
  AND ivl.[Created]                             IS NOT NULL
GROUP BY ivl.[Invoice_Voucher_Line_curr]
ORDER BY 1;


-- ============================================================
-- 3a. Purchase Order Headers - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY po.[Purchase_Order_Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])            AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(po.[Purchase_Order_Created])                                AS Earliest,
    MAX(po.[Purchase_Order_Created])                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON po.[Purchase_Order_Organization_Code] = o.[Org_Code]
      AND o.[Latest_Indicator]                  = 1
WHERE po.[Latest_Indicator]             = 1
  AND po.[Purchase_Order_Exchange]      IS NOT NULL
  AND po.[Purchase_Order_Exchange]      <> 0
  AND po.[Purchase_Order_Currency]      IS NOT NULL
  AND po.[Purchase_Order_Created]       IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])
ORDER BY 1;


-- ============================================================
-- 3b. Purchase Order Headers - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY po.[Purchase_Order_Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])            AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(po.[Purchase_Order_Created])                                AS Earliest,
    MAX(po.[Purchase_Order_Created])                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON po.[Purchase_Order_Organization_Code] = o.[Org_Code]
      AND o.[Latest_Indicator]                  = 1
WHERE po.[Latest_Indicator]                 = 1
  AND po.[Purchase_Order_Exch_From_Dual]    IS NOT NULL
  AND po.[Purchase_Order_Exch_From_Dual]    <> 0
  AND po.[Purchase_Order_Created]           IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], po.[Purchase_Order_Currency])
ORDER BY 1;


-- ============================================================
-- 3c. Purchase Order Headers - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY po.[Purchase_Order_Created];

-- Summary
SELECT
    po.[Purchase_Order_Currency]                                    AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(po.[Purchase_Order_Created])                                AS Earliest,
    MAX(po.[Purchase_Order_Created])                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Details]           AS po
WHERE po.[Latest_Indicator]                 = 1
  AND po.[Purchase_Order_Exch_To_Dual]      IS NOT NULL
  AND po.[Purchase_Order_Exch_To_Dual]      <> 0
  AND po.[Purchase_Order_Currency]          IS NOT NULL
  AND po.[Purchase_Order_Created]           IS NOT NULL
GROUP BY po.[Purchase_Order_Currency]
ORDER BY 1;


-- ============================================================
-- 4a. Purchase Order Parts Lines - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY pop.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])     AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(pop.[Created] AS DATE))                                AS Earliest,
    MAX(CAST(pop.[Created] AS DATE))                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON pop.[Purchase_Order_Parts_Order_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                          = 1
WHERE pop.[Latest_Indicator]                = 1
  AND pop.[Purchase_Order_Parts_Exch]       IS NOT NULL
  AND pop.[Purchase_Order_Parts_Exch]       <> 0
  AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
  AND pop.[Created]                         IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])
ORDER BY 1;


-- ============================================================
-- 4b. Purchase Order Parts Lines - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY pop.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])     AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(pop.[Created] AS DATE))                                AS Earliest,
    MAX(CAST(pop.[Created] AS DATE))                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON pop.[Purchase_Order_Parts_Order_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                          = 1
WHERE pop.[Latest_Indicator]                    = 1
  AND pop.[Purchase_Order_Parts_Exchfromdual]   IS NOT NULL
  AND pop.[Purchase_Order_Parts_Exchfromdual]   <> 0
  AND pop.[Created]                             IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], pop.[Purchase_Order_Parts_Currency])
ORDER BY 1;


-- ============================================================
-- 4c. Purchase Order Parts Lines - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY pop.[Created];

-- Summary
SELECT
    pop.[Purchase_Order_Parts_Currency]                             AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(pop.[Created] AS DATE))                                AS Earliest,
    MAX(CAST(pop.[Created] AS DATE))                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Parts_Details]     AS pop
WHERE pop.[Latest_Indicator]                = 1
  AND pop.[Purchase_Order_Parts_Exchtodual] IS NOT NULL
  AND pop.[Purchase_Order_Parts_Exchtodual] <> 0
  AND pop.[Purchase_Order_Parts_Currency]   IS NOT NULL
  AND pop.[Created]                         IS NOT NULL
GROUP BY pop.[Purchase_Order_Parts_Currency]
ORDER BY 1;


-- ============================================================
-- 5a. Purchase Order Services Lines - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY pos.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])  AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(pos.[Created] AS DATE))                                AS Earliest,
    MAX(CAST(pos.[Created] AS DATE))                                AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]  AS pos
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON pos.[Purchase_Order_Services_Order_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                             = 1
WHERE pos.[Latest_Indicator]                    = 1
  AND pos.[Purchase_Order_Services_Exch]        IS NOT NULL
  AND pos.[Purchase_Order_Services_Exch]        <> 0
  AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
  AND pos.[Created]                             IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])
ORDER BY 1;


-- ============================================================
-- 5b. Purchase Order Services Lines - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY pos.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])      AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(pos.[Created] AS DATE))                                    AS Earliest,
    MAX(CAST(pos.[Created] AS DATE))                                    AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]      AS pos
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
       ON pos.[Purchase_Order_Services_Order_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                             = 1
WHERE pos.[Latest_Indicator]                        = 1
  AND pos.[Purchase_Order_Services_Exchfromdual]    IS NOT NULL
  AND pos.[Purchase_Order_Services_Exchfromdual]    <> 0
  AND pos.[Created]                                 IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], pos.[Purchase_Order_Services_Currency])
ORDER BY 1;


-- ============================================================
-- 5c. Purchase Order Services Lines - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY pos.[Created];

-- Summary
SELECT
    pos.[Purchase_Order_Services_Currency]                              AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(pos.[Created] AS DATE))                                    AS Earliest,
    MAX(CAST(pos.[Created] AS DATE))                                    AS Latest
FROM [EnterpriseAssetManagement].[Purchase_Order_Services_Details]      AS pos
WHERE pos.[Latest_Indicator]                    = 1
  AND pos.[Purchase_Order_Services_Exchtodual]  IS NOT NULL
  AND pos.[Purchase_Order_Services_Exchtodual]  <> 0
  AND pos.[Purchase_Order_Services_Currency]    IS NOT NULL
  AND pos.[Created]                             IS NOT NULL
GROUP BY pos.[Purchase_Order_Services_Currency]
ORDER BY 1;


-- ============================================================
-- 6a. Requisitions Parts - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY rp.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])            AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(rp.[Created] AS DATE))                                 AS Earliest,
    MAX(CAST(rp.[Created] AS DATE))                                 AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON rp.[Requisitions_Parts_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                 = 1
WHERE rp.[Latest_Indicator]             = 1
  AND rp.[Requisitions_Parts_exch]      IS NOT NULL
  AND rp.[Requisitions_Parts_exch]      <> 0
  AND rp.[Requisitions_Parts_curr]      IS NOT NULL
  AND rp.[Created]                      IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])
ORDER BY 1;


-- ============================================================
-- 6b. Requisitions Parts - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY rp.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])            AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(rp.[Created] AS DATE))                                 AS Earliest,
    MAX(CAST(rp.[Created] AS DATE))                                 AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON rp.[Requisitions_Parts_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                 = 1
WHERE rp.[Latest_Indicator]                     = 1
  AND rp.[Requisitions_Parts_exchfromdual]      IS NOT NULL
  AND rp.[Requisitions_Parts_exchfromdual]      <> 0
  AND rp.[Created]                              IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], rp.[Requisitions_Parts_curr])
ORDER BY 1;


-- ============================================================
-- 6c. Requisitions Parts - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY rp.[Created];

-- Summary
SELECT
    rp.[Requisitions_Parts_curr]                                    AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(rp.[Created] AS DATE))                                 AS Earliest,
    MAX(CAST(rp.[Created] AS DATE))                                 AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Parts_Details]       AS rp
WHERE rp.[Latest_Indicator]                 = 1
  AND rp.[Requisitions_Parts_exchtodual]    IS NOT NULL
  AND rp.[Requisitions_Parts_exchtodual]    <> 0
  AND rp.[Requisitions_Parts_curr]          IS NOT NULL
  AND rp.[Created]                          IS NOT NULL
GROUP BY rp.[Requisitions_Parts_curr]
ORDER BY 1;


-- ============================================================
-- 7a. Requisitions Services - Transaction vs Base
-- ============================================================
SELECT TOP 100
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
ORDER BY rs.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])         AS Base_Currency,
    COUNT(*)                                                        AS Row_Count,
    MIN(CAST(rs.[Created] AS DATE))                                 AS Earliest,
    MAX(CAST(rs.[Created] AS DATE))                                 AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]    AS rs
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]        AS o
       ON rs.[Requisitions_Services_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                    = 1
WHERE rs.[Latest_Indicator]                 = 1
  AND rs.[Requisitions_Services_exch]       IS NOT NULL
  AND rs.[Requisitions_Services_exch]       <> 0
  AND rs.[Requisitions_Services_curr]       IS NOT NULL
  AND rs.[Created]                          IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])
ORDER BY 1;


-- ============================================================
-- 7b. Requisitions Services - NGN From-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY rs.[Created];

-- Summary
SELECT
    COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])             AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(rs.[Created] AS DATE))                                     AS Earliest,
    MAX(CAST(rs.[Created] AS DATE))                                     AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]        AS rs
LEFT JOIN [EnterpriseAssetManagement].[Organisation_Details]            AS o
       ON rs.[Requisitions_Services_Organization] = o.[Org_Code]
      AND o.[Latest_Indicator]                    = 1
WHERE rs.[Latest_Indicator]                         = 1
  AND rs.[Requisitions_Services_exchfromdual]       IS NOT NULL
  AND rs.[Requisitions_Services_exchfromdual]       <> 0
  AND rs.[Created]                                  IS NOT NULL
GROUP BY COALESCE(o.[Org_Curr], rs.[Requisitions_Services_curr])
ORDER BY 1;


-- ============================================================
-- 7c. Requisitions Services - NGN To-Dual
-- ============================================================
SELECT TOP 100
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
ORDER BY rs.[Created];

-- Summary
SELECT
    rs.[Requisitions_Services_curr]                                     AS Base_Currency,
    COUNT(*)                                                            AS Row_Count,
    MIN(CAST(rs.[Created] AS DATE))                                     AS Earliest,
    MAX(CAST(rs.[Created] AS DATE))                                     AS Latest
FROM [EnterpriseAssetManagement].[Requisitions_Services_Details]        AS rs
WHERE rs.[Latest_Indicator]                     = 1
  AND rs.[Requisitions_Services_exchtodual]     IS NOT NULL
  AND rs.[Requisitions_Services_exchtodual]     <> 0
  AND rs.[Requisitions_Services_curr]           IS NOT NULL
  AND rs.[Created]                              IS NOT NULL
GROUP BY rs.[Requisitions_Services_curr]
ORDER BY 1;