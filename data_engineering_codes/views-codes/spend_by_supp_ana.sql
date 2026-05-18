/* =====================================================================================
   DATA QUALITY + ANALYSIS PACK
   Object:  proc_vw.spend_by_supplier
   Goal:    Validate grain, completeness, spend math, window metrics, and analytics readiness
   ===================================================================================== */

SET NOCOUNT ON;

PRINT '=============================================================';
PRINT 'DQ PACK START: proc_vw.spend_by_supplier';
PRINT '=============================================================';

----------------------------------------------------------------------------------------
-- 0) Quick row count
----------------------------------------------------------------------------------------
PRINT '0) Row count';
SELECT
    COUNT(*) AS total_rows
FROM proc_vw.spend_by_supplier;


----------------------------------------------------------------------------------------
-- 1) Grain validation: ensure 1 row = 1 PO line item
-- Expect: 0 rows returned
----------------------------------------------------------------------------------------
PRINT '1) Grain validation (duplicates check): expect 0 rows';
SELECT
    purchase_order_number,
    purchase_order_item_number,
    COUNT(*) AS row_count
FROM proc_vw.spend_by_supplier
GROUP BY purchase_order_number, purchase_order_item_number
HAVING COUNT(*) > 1;


----------------------------------------------------------------------------------------
-- 2) Completeness: key fields null / blanks (supplier, vendor, org, dates)
----------------------------------------------------------------------------------------
PRINT '2) Completeness checks (null counts)';
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN supplier_code IS NULL OR LTRIM(RTRIM(supplier_code)) = '' THEN 1 ELSE 0 END) AS missing_supplier_code,
    SUM(CASE WHEN vendor_code   IS NULL OR LTRIM(RTRIM(vendor_code))   = '' THEN 1 ELSE 0 END) AS missing_vendor_code,
    SUM(CASE WHEN vendor_name   IS NULL OR LTRIM(RTRIM(vendor_name))   = '' THEN 1 ELSE 0 END) AS missing_vendor_name,

    SUM(CASE WHEN purchasing_organisation IS NULL OR LTRIM(RTRIM(purchasing_organisation)) = '' THEN 1 ELSE 0 END) AS missing_purchasing_organisation,
    SUM(CASE WHEN purchasing_group        IS NULL OR LTRIM(RTRIM(purchasing_group))        = '' THEN 1 ELSE 0 END) AS missing_purchasing_group,
    SUM(CASE WHEN plant                   IS NULL OR LTRIM(RTRIM(plant))                   = '' THEN 1 ELSE 0 END) AS missing_plant,

    SUM(CASE WHEN purchase_order_date IS NULL THEN 1 ELSE 0 END) AS missing_purchase_order_date,
    SUM(CASE WHEN calendar_year       IS NULL THEN 1 ELSE 0 END) AS missing_calendar_year,
    SUM(CASE WHEN mmyyyy              IS NULL THEN 1 ELSE 0 END) AS missing_mmyyyy
FROM proc_vw.spend_by_supplier;


----------------------------------------------------------------------------------------
-- 3) Spend math validation: line_spend should equal order_quantity * net_price
-- Expect: 0 rows returned (or only rounding-level differences)
----------------------------------------------------------------------------------------
PRINT '3) Spend math validation (line_spend vs qty*price): expect 0 rows';
SELECT TOP (100)
    purchase_order_number,
    purchase_order_item_number,
    order_quantity,
    net_price,
    line_spend,
    CAST(order_quantity * net_price AS decimal(18,4)) AS recomputed_line_spend,
    CAST(line_spend - (order_quantity * net_price) AS decimal(18,4)) AS diff
FROM proc_vw.spend_by_supplier
WHERE ABS(COALESCE(line_spend,0) - COALESCE(order_quantity,0) * COALESCE(net_price,0)) > 0.01
ORDER BY ABS(COALESCE(line_spend,0) - COALESCE(order_quantity,0) * COALESCE(net_price,0)) DESC;


----------------------------------------------------------------------------------------
-- 4) PO total consistency: po_total_value should equal SUM(line_spend) per PO
-- Expect: 0 rows returned
----------------------------------------------------------------------------------------
PRINT '4) PO total consistency (sum lines vs po_total_value): expect 0 rows';
SELECT
    purchase_order_number,
    CAST(SUM(COALESCE(line_spend,0)) AS decimal(18,2)) AS sum_of_lines,
    CAST(MAX(COALESCE(po_total_value,0)) AS decimal(18,2)) AS po_total_value,
    CAST(SUM(COALESCE(line_spend,0)) - MAX(COALESCE(po_total_value,0)) AS decimal(18,2)) AS diff
FROM proc_vw.spend_by_supplier
GROUP BY purchase_order_number
HAVING ABS(SUM(COALESCE(line_spend,0)) - MAX(COALESCE(po_total_value,0))) > 0.01;


----------------------------------------------------------------------------------------
-- 5) Status review: list distinct statuses present (confirm cancelled not included)
----------------------------------------------------------------------------------------
PRINT '5) Status review (distinct values)';
SELECT DISTINCT
    purchase_order_status,
    item_status
FROM proc_vw.spend_by_supplier
ORDER BY purchase_order_status, item_status;


----------------------------------------------------------------------------------------
-- 6) Category mapping coverage (often a weak point)
----------------------------------------------------------------------------------------
PRINT '6) Category mapping coverage';
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS missing_category_id,
    CAST(100.0 * SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS decimal(5,2)) AS missing_category_pct
FROM proc_vw.spend_by_supplier;

PRINT '6b) Unmapped combinations (purchasing_group + material_group) - top 50';
SELECT TOP (50)
    purchasing_group,
    material_group,
    COUNT(*) AS row_count,
    CAST(SUM(line_spend) AS decimal(18,2)) AS spend_value
FROM proc_vw.spend_by_supplier
WHERE category_id IS NULL
GROUP BY purchasing_group, material_group
ORDER BY spend_value DESC;


----------------------------------------------------------------------------------------
-- 7) Date dimension alignment (purchase_order_date should map to date_dimension)
----------------------------------------------------------------------------------------
PRINT '7) Date dimension alignment (missing calendar attributes)';
SELECT TOP (100)
    purchase_order_number,
    purchase_order_item_number,
    purchase_order_date,
    calendar_year,
    calendar_month,
    month_name,
    mmyyyy
FROM proc_vw.spend_by_supplier
WHERE purchase_order_date IS NOT NULL
  AND (calendar_year IS NULL OR calendar_month IS NULL OR mmyyyy IS NULL)
ORDER BY purchase_order_date DESC;


----------------------------------------------------------------------------------------
-- 8) Core analytics outputs (confirm view supports your KPI reporting)
----------------------------------------------------------------------------------------

PRINT '8a) Top suppliers by spend (Top 20)';
SELECT TOP (20)
    vendor_name,
    vendor_code,
    CAST(SUM(line_spend) AS decimal(18,2)) AS total_spend,
    COUNT(*) AS line_count,
    CAST(AVG(po_total_value) AS decimal(18,2)) AS avg_po_value_proxy  -- proxy: repeated per line; use 8c for true avg PO
FROM proc_vw.spend_by_supplier
GROUP BY vendor_name, vendor_code
ORDER BY SUM(line_spend) DESC;

PRINT '8b) Spend trend by year/month';
SELECT
    calendar_year,
    calendar_month,
    month_name,
    COUNT(*) AS line_count,
    CAST(SUM(line_spend) AS decimal(18,2)) AS total_spend
FROM proc_vw.spend_by_supplier
GROUP BY calendar_year, calendar_month, month_name
ORDER BY calendar_year, calendar_month;

PRINT '8c) True Avg PO Value (de-duplicated by PO)';
SELECT
    CAST(AVG(po_total_value) AS decimal(18,2)) AS avg_po_value
FROM (
    SELECT DISTINCT purchase_order_number, po_total_value
    FROM proc_vw.spend_by_supplier
) x;

PRINT '8d) Spend by category (Top 30)';
SELECT TOP (30)
    material_group_description,
    material_group_code,
    CAST(SUM(line_spend) AS decimal(18,2)) AS total_spend,
    COUNT(*) AS line_count
FROM proc_vw.spend_by_supplier
GROUP BY material_group_description, material_group_code
ORDER BY SUM(line_spend) DESC;

PRINT '8e) Spend by plant (Top 30)';
SELECT TOP (30)
    plant,
    CAST(SUM(line_spend) AS decimal(18,2)) AS total_spend,
    COUNT(*) AS line_count
FROM proc_vw.spend_by_supplier
GROUP BY plant
ORDER BY SUM(line_spend) DESC;

PRINT '=============================================================';
PRINT 'DQ PACK END: proc_vw.spend_by_supplier';
PRINT '=============================================================';