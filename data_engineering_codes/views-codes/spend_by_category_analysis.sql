/* =====================================================================================
   DATA QUALITY + ANALYSIS PACK
   Object:  proc_vw.spend_by_category
   Grain:   1 row = 1 category / period combination
   Filter:  All active POs (purchase_order_status='Active' AND item_status='Active')
   Purpose: Validate uniqueness, completeness, spend sanity, supplier competition metrics,
            and reporting readiness.
   ===================================================================================== */

SET NOCOUNT ON;

PRINT '=============================================================';
PRINT 'DQ PACK START: proc_vw.spend_by_category';
PRINT '=============================================================';

----------------------------------------------------------------------------------------
-- 0) Quick row count
----------------------------------------------------------------------------------------
PRINT '0) Row count';
SELECT COUNT(*) AS total_rows
FROM proc_vw.spend_by_category;


----------------------------------------------------------------------------------------
-- 1) Grain validation: ensure 1 row per category/period
-- Choose the exact grain columns used by the view:
-- period = (calendar_year, calendar_month) and category = (purchasing_group, material_group_code)
-- If you prefer mmyyyy, use that instead of year/month.
-- Expect: 0 rows returned
----------------------------------------------------------------------------------------
PRINT '1) Grain validation (duplicates): expect 0 rows';
SELECT
    calendar_year,
    calendar_month,
    purchasing_group,
    material_group_code,
    COUNT(*) AS row_count
FROM proc_vw.spend_by_category
GROUP BY
    calendar_year, calendar_month, purchasing_group, material_group_code
HAVING COUNT(*) > 1;


----------------------------------------------------------------------------------------
-- 2) Completeness checks: key dimensions should not be NULL for analytics usability
----------------------------------------------------------------------------------------
PRINT '2) Completeness checks (null counts)';
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN calendar_year  IS NULL THEN 1 ELSE 0 END) AS missing_calendar_year,
    SUM(CASE WHEN calendar_month IS NULL THEN 1 ELSE 0 END) AS missing_calendar_month,
    SUM(CASE WHEN mmyyyy         IS NULL THEN 1 ELSE 0 END) AS missing_mmyyyy,

    SUM(CASE WHEN purchasing_group IS NULL OR LTRIM(RTRIM(purchasing_group)) = '' THEN 1 ELSE 0 END) AS missing_purchasing_group,
    SUM(CASE WHEN material_group_code IS NULL OR LTRIM(RTRIM(material_group_code)) = '' THEN 1 ELSE 0 END) AS missing_material_group_code,

    SUM(CASE WHEN material_group_description IS NULL OR LTRIM(RTRIM(material_group_description)) = '' THEN 1 ELSE 0 END) AS missing_material_group_description,
    SUM(CASE WHEN purchasing_group_description IS NULL OR LTRIM(RTRIM(purchasing_group_description)) = '' THEN 1 ELSE 0 END) AS missing_purchasing_group_description,

    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS missing_category_id
FROM proc_vw.spend_by_category;


----------------------------------------------------------------------------------------
-- 3) Spend sanity: totals should not be negative; counts should not be negative/zero weirdness
----------------------------------------------------------------------------------------
PRINT '3) Spend sanity (negative or suspicious rows): expect 0 rows';
SELECT TOP (100)
    *
FROM proc_vw.spend_by_category
WHERE
    total_spend < 0
    OR supplier_count < 0
    OR po_line_count < 0
ORDER BY total_spend ASC;


----------------------------------------------------------------------------------------
-- 4) Competition metric logic validation:
-- competition_type must match supplier_count (1 => Single-source, >1 => Competitive)
-- Expect: 0 rows returned
----------------------------------------------------------------------------------------
PRINT '4) Competition type vs supplier_count consistency: expect 0 rows';
SELECT TOP (100)
    calendar_year,
    calendar_month,
    purchasing_group,
    material_group_code,
    supplier_count,
    competition_type,
    total_spend,
    top_supplier_spend,
    top_supplier_share
FROM proc_vw.spend_by_category
WHERE
    (supplier_count = 1 AND competition_type <> 'Single-source')
 OR (supplier_count > 1 AND competition_type <> 'Competitive')
 OR (supplier_count IS NULL AND competition_type <> 'Unknown');


----------------------------------------------------------------------------------------
-- 5) Top supplier share sanity:
-- Should be between 0 and 1 when total_spend > 0
-- Expect: 0 rows returned
----------------------------------------------------------------------------------------
PRINT '5) Top supplier share bounds check: expect 0 rows';
SELECT TOP (100)
    calendar_year,
    calendar_month,
    purchasing_group,
    material_group_code,
    total_spend,
    top_supplier_spend,
    top_supplier_share
FROM proc_vw.spend_by_category
WHERE
    total_spend > 0
    AND (top_supplier_share < 0 OR top_supplier_share > 1)
ORDER BY top_supplier_share DESC;


----------------------------------------------------------------------------------------
-- 6) Category mapping quality (if category_id is frequently NULL, mapping table needs enrichment)
----------------------------------------------------------------------------------------
PRINT '6) Category mapping coverage (NULL category_id rate)';
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS unmapped_rows,
    CAST(100.0 * SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(5,2)) AS unmapped_pct
FROM proc_vw.spend_by_category;

PRINT '6b) Largest spend buckets with NULL category_id (Top 50)';
SELECT TOP (50)
    calendar_year,
    calendar_month,
    purchasing_group,
    material_group_code,
    material_group_description,
    CAST(total_spend AS decimal(18,2)) AS total_spend,
    supplier_count,
    po_line_count
FROM proc_vw.spend_by_category
WHERE category_id IS NULL
ORDER BY total_spend DESC;


----------------------------------------------------------------------------------------
-- 7) (Optional but recommended) Supplier ID coverage impact check:
-- If vendor_code is missing in source, supplier_count could undercount.
-- This check uses the BASE tables to measure NULL vendor match rate.
----------------------------------------------------------------------------------------
PRINT '7) Supplier identifier coverage check (base-table cross-check)';
SELECT
    COUNT(*) AS active_line_rows,
    SUM(CASE WHEN v.vendor_code IS NULL THEN 1 ELSE 0 END) AS missing_vendor_match_rows,
    CAST(100.0 * SUM(CASE WHEN v.vendor_code IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(5,2)) AS missing_vendor_match_pct
FROM offshore_srm.purchase_order_items i
JOIN offshore_srm.purchase_order_headers h
  ON h.purchase_order_number = i.purchase_order_number
LEFT JOIN offshore_srm.vendors v
  ON v.vendor_code = COALESCE(NULLIF(i.supplier_code,''), NULLIF(h.supplier_code,''))
WHERE
    h.purchase_order_status = 'Active'
    AND i.item_status = 'Active';


----------------------------------------------------------------------------------------
-- 8) Reporting outputs (confirm view answers the business questions)
----------------------------------------------------------------------------------------
PRINT '8a) Spend by category (Top 30)';
SELECT TOP (30)
    calendar_year,
    calendar_month,
    purchasing_group,
    material_group_code,
    material_group_description,
    CAST(total_spend AS decimal(18,2)) AS total_spend,
    supplier_count,
    competition_type,
    CAST(top_supplier_share AS decimal(18,4)) AS top_supplier_share
FROM proc_vw.spend_by_category
ORDER BY total_spend DESC;

PRINT '8b) Trend by period (year/month)';
SELECT
    calendar_year,
    calendar_month,
    month_name,
    CAST(SUM(total_spend) AS decimal(18,2)) AS total_spend,
    SUM(po_line_count) AS po_line_count
FROM proc_vw.spend_by_category
GROUP BY calendar_year, calendar_month, month_name
ORDER BY calendar_year, calendar_month;

PRINT '8c) Single-source vs Competitive spend (period summary)';
SELECT
    calendar_year,
    calendar_month,
    month_name,
    CAST(SUM(single_source_spend) AS decimal(18,2)) AS single_source_spend,
    CAST(SUM(competitive_spend)   AS decimal(18,2)) AS competitive_spend,
    CAST(SUM(total_spend)         AS decimal(18,2)) AS total_spend
FROM proc_vw.spend_by_category
GROUP BY calendar_year, calendar_month, month_name
ORDER BY calendar_year, calendar_month;

PRINT '=============================================================';
PRINT 'DQ PACK END: proc_vw.spend_by_category';
PRINT '=============================================================';
