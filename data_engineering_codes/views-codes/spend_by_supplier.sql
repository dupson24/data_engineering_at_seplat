IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'proc_vw')
    EXEC ('CREATE SCHEMA proc_vw');
GO

CREATE VIEW proc_vw.spend_by_supplier
AS\
WITH base AS
(
    SELECT
        h.purchase_order_number,
        i.purchase_order_item_number,

        supplier_code = COALESCE(NULLIF(i.supplier_code, ''), NULLIF(h.supplier_code, '')),

        v.vendor_code,
        vendor_name = COALESCE(NULLIF(v.company_name, ''), NULLIF(v.business_name, '')),
        v.vendor_account_group,
        v.vendor_status,

        h.purchasing_organisation,
        h.purchasing_group,
        plant = COALESCE(NULLIF(i.plant, ''), NULLIF(h.plant, '')),

        sc.category_id,
        sc.purchasing_group_description,
        sc.material_group_code,
        sc.material_group_description,

        i.material_code,
        i.item_description,
        i.material_group,
        i.item_category,
        i.unit_of_measure,
        i.order_quantity,
        i.net_price,

        h.purchase_order_date,
        i.delivery_date,

        d.[Year]      AS calendar_year,
        d.[Month]     AS calendar_month,
        d.MonthName   AS month_name,
        d.Quarter     AS calendar_quarter,
        d.MonthYear   AS month_year,
        d.MMYYYY      AS mmyyyy,

        h.currency,
        h.purchase_order_type,
        h.purchase_order_status,
        i.item_status,

        line_spend =
            CAST(COALESCE(i.order_quantity, 0) AS decimal(18,4))
          * CAST(COALESCE(i.net_price, 0)     AS decimal(18,4))
    FROM offshore_srm.purchase_order_headers h
    INNER JOIN offshore_srm.purchase_order_items i
        ON i.purchase_order_number = h.purchase_order_number
    LEFT JOIN offshore_srm.vendors v
        ON v.vendor_code = COALESCE(NULLIF(i.supplier_code, ''), NULLIF(h.supplier_code, ''))
    LEFT JOIN offshore_srm.supplier_category sc
        ON sc.material_group_code   = i.material_group
       AND sc.purchasing_group_code = h.purchasing_group
    LEFT JOIN offshore_eam.date_dimension d
        ON d.[Date] = h.purchase_order_date
    WHERE
        ISNULL(NULLIF(LTRIM(RTRIM(h.purchase_order_status)), ''), 'ACTIVE') NOT IN ('L','CANCELLED','CANCELED','DELETED')
        AND ISNULL(NULLIF(LTRIM(RTRIM(i.item_status)), ''), 'ACTIVE')       NOT IN ('L','CANCELLED','CANCELED','DELETED')
)
SELECT
    purchase_order_number,
    purchase_order_item_number,

    supplier_code,
    vendor_code,
    vendor_name,
    vendor_account_group,
    vendor_status,

    purchasing_organisation,
    purchasing_group,
    plant,

    category_id,
    purchasing_group_description,
    material_group_code,
    material_group_description,

    material_code,
    item_description,
    material_group,
    item_category,
    unit_of_measure,
    order_quantity,
    net_price,

    purchase_order_date,
    delivery_date,
    calendar_year,
    calendar_month,
    month_name,
    calendar_quarter,
    month_year,
    mmyyyy,

    currency,
    purchase_order_type,
    purchase_order_status,
    item_status,

    committed_spend = line_spend,
    actual_spend    = line_spend,  -- until invoice/GR tables are available
    line_spend,

    po_total_value = SUM(line_spend) OVER (PARTITION BY purchase_order_number),
    po_line_count  = COUNT(1)      OVER (PARTITION BY purchase_order_number)
FROM base;
GO