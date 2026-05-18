/* =====================================================================================
   DQ + ANALYSIS PACK
   Object:  proc_vw.spend_vs_budget
   Grain:   1 row = 1 cost centre / month (plus Business_Unit)
   ===================================================================================== */

SET NOCOUNT ON;

PRINT '=============================================================';
PRINT 'DQ PACK START: proc_vw.spend_vs_budget';
PRINT '=============================================================';

-- 0) Row count
PRINT '0) Row count';
SELECT COUNT(*) AS total_rows
FROM proc_vw.spend_vs_budget;

-- 1) Grain validation (duplicates) - expect 0 rows
PRINT '1) Grain validation (duplicates): expect 0 rows';
SELECT
    calendar_year, calendar_month, business_unit, cost_centre,
    COUNT(*) AS row_count
FROM proc_vw.spend_vs_budget
GROUP BY calendar_year, calendar_month, business_unit, cost_centre
HAVING COUNT(*) > 1;

-- 2) Completeness
PRINT '2) Completeness checks';
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN cost_centre IS NULL OR LTRIM(RTRIM(cost_centre))='' THEN 1 ELSE 0 END) AS missing_cost_centre,
    SUM(CASE WHEN budget_amount IS NULL THEN 1 ELSE 0 END) AS missing_budget_amount,
    SUM(CASE WHEN actual_spend IS NULL THEN 1 ELSE 0 END) AS missing_actual_spend
FROM proc_vw.spend_vs_budget;

-- 3) Sanity: negative or weird values (depends on your accounting sign rules)
PRINT '3) Sanity checks (negative values) - review if accounting uses negatives';
SELECT TOP (100) *
FROM proc_vw.spend_vs_budget
WHERE budget_amount < 0 OR actual_spend < 0
ORDER BY actual_spend ASC;

-- 4) Utilisation bounds (negative invalid; >1 allowed for overspend)
PRINT '4) Utilisation bounds (negative invalid): expect 0 rows';
SELECT TOP (100) *
FROM proc_vw.spend_vs_budget
WHERE budget_utilisation_pct < 0
ORDER BY budget_utilisation_pct ASC;

-- 5) Overspend flag logic
PRINT '5) Overspend flag consistency: expect 0 rows';
SELECT TOP (100) *
FROM proc_vw.spend_vs_budget
WHERE
    (overspend_flag = 1 AND actual_spend <= budget_amount)
 OR (overspend_flag = 0 AND actual_spend >  budget_amount);

-- 6) Business outputs
PRINT '6a) Top overspent cost centres (Top 20)';
SELECT TOP (20)
    business_unit,
    cost_centre,
    SUM(actual_spend) AS actual_spend,
    SUM(budget_amount) AS budget_amount,
    SUM(actual_spend - budget_amount) AS overspend_amount
FROM proc_vw.spend_vs_budget
GROUP BY business_unit, cost_centre
ORDER BY SUM(actual_spend - budget_amount) DESC;

PRINT '6b) Monthly utilisation trend';
SELECT
    calendar_year,
    calendar_month,
    month_name,
    SUM(actual_spend) AS actual_spend,
    SUM(budget_amount) AS budget_amount,
    CASE WHEN SUM(budget_amount) > 0
         THEN CAST(SUM(actual_spend) / SUM(budget_amount) AS decimal(18,4))
    END AS utilisation_pct
FROM proc_vw.spend_vs_budget
GROUP BY calendar_year, calendar_month, month_name
ORDER BY calendar_year, calendar_month;

PRINT '=============================================================';
PRINT 'DQ PACK END: proc_vw.spend_vs_budget';
PRINT '=============================================================';