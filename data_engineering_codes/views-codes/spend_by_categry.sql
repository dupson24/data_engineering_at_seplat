/* ======================================================================================
   View:        proc_vw.spend_by_category
   Grain:       1 row = 1 category / period combination
   Filters:     All active POs
                - purchase_order_status = 'Active'
                - item_status = 'Active'   (exclude 'Deleted')
   ====================================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'proc_vw')
BEGIN
    EXEC ('CREATE SCHEMA proc_vw');
END;
GO

CREATE OR ALTER VIEW proc_vw.spend_by_category
AS
WITH line_base AS
(
    SELECT
        -- Period bucket
        h.purchase_order_date,
        d.[Year]      AS calendar_year,
        d.[Month]     AS calendar_month,
        d.MonthName   AS month_name,
        d.Quarter     AS calendar_quarter,
        d.MonthYear   AS month_year,
        d.MMYYYY      AS mmyyyy,

        -- Category dimensions (material group + purchasing group)
        h.purchasing_group,
        sc.purchasing_group_description,
        i.material_group,
        sc.material_group_code,
        sc.material_group_description,
        sc.category_id,

        -- Supplier (for supplier count / competition metrics)
        supplier_code = COALESCE(NULLIF(i.supplier_code, ''), NULLIF(h.supplier_code, '')),
        v.vendor_code,
        vendor_name = COALESCE(NULLIF(v.company_name, ''), NULLIF(v.business_name, '')),

        -- Line spend
        line_spend =
            CAST(COALESCE(i.order_quantity, 0) AS decimal(18,4))
          * CAST(COALESCE(i.net_price, 0)     AS decimal(18,4)),

        -- Helpful counts
        h.purchase_order_number,
        i.purchase_order_item_number

    FROM offshore_srm.purchase_order_items i
    INNER JOIN offshore_srm.purchase_order_headers h
        ON h.purchase_order_number = i.purchase_order_number

    LEFT JOIN offshore_srm.supplier_category sc
        ON sc.material_group_code   = i.material_group
       AND sc.purchasing_group_code = h.purchasing_group

    LEFT JOIN offshore_srm.vendors v
        ON v.vendor_code = COALESCE(NULLIF(i.supplier_code, ''), NULLIF(h.supplier_code, ''))

    LEFT JOIN offshore_eam.date_dimension d
        ON d.[Date] = h.purchase_order_date

    -- ✅ 100% accurate "All active POs" filter based on your confirmed values
    WHERE
        h.purchase_order_status = 'Active'
        AND i.item_status = 'Active'
),
supplier_rollup AS
(
    -- Spend by supplier within each category/period bucket
    SELECT
        calendar_year,
        calendar_month,
        month_name,
        calendar_quarter,
        month_year,
        mmyyyy,

        purchasing_group,
        purchasing_group_description,
        material_group,
        material_group_code,
        material_group_description,
        category_id,

        vendor_code,
        vendor_name,

        COUNT(*) AS po_line_count,
        CAST(SUM(line_spend) AS decimal(18,2)) AS supplier_spend
    FROM line_base
    GROUP BY
        calendar_year, calendar_month, month_name, calendar_quarter, month_year, mmyyyy,
        purchasing_group, purchasing_group_description,
        material_group, material_group_code, material_group_description, category_id,
        vendor_code, vendor_name
),
category_period AS
(
    -- Collapse to 1 row per category/period with supplier count + competition metrics
    SELECT
        calendar_year,
        calendar_month,
        month_name,
        calendar_quarter,
        month_year,
        mmyyyy,

        purchasing_group,
        purchasing_group_description,
        material_group,
        material_group_code,
        material_group_description,
        category_id,

        CAST(SUM(supplier_spend) AS decimal(18,2)) AS total_spend,
        SUM(po_line_count) AS po_line_count,

        COUNT(DISTINCT vendor_code) AS supplier_count,
        CAST(MAX(supplier_spend) AS decimal(18,2)) AS top_supplier_spend
    FROM supplier_rollup
    GROUP BY
        calendar_year, calendar_month, month_name, calendar_quarter, month_year, mmyyyy,
        purchasing_group, purchasing_group_description,
        material_group, material_group_code, material_group_description, category_id
)
SELECT
    -- Grain
    calendar_year,
    calendar_month,
    month_name,
    calendar_quarter,
    month_year,
    mmyyyy,

    purchasing_group,
    purchasing_group_description,

    material_group,
    material_group_code,
    material_group_description,
    category_id,

    -- KPIs / Measures
    total_spend,
    supplier_count,
    po_line_count,

    -- Competition metrics
    competition_type =
        CASE
            WHEN supplier_count = 1 THEN 'Single-source'
            WHEN supplier_count > 1 THEN 'Competitive'
            ELSE 'Unknown'
        END,

    single_source_spend =
        CASE
            WHEN supplier_count = 1 THEN total_spend
            ELSE CAST(0 AS decimal(18,2))
        END,

    competitive_spend =
        CASE
            WHEN supplier_count > 1 THEN total_spend
            ELSE CAST(0 AS decimal(18,2))
        END,

    top_supplier_spend,

    top_supplier_share =
        CASE
            WHEN total_spend > 0 THEN CAST(top_supplier_spend / total_spend AS decimal(18,4))
            ELSE CAST(NULL AS decimal(18,4))
        END
FROM category_period;
GO