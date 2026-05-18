-- ============================================================
-- DEPLOY PROC — creates proc_vw.maverick_spend safely (no invalid columns)
-- ============================================================

IF OBJECT_ID('[dbo].[usp_deploy_proc_vw_maverick_spend]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_deploy_proc_vw_maverick_spend];
GO

CREATE PROCEDURE [dbo].[usp_deploy_proc_vw_maverick_spend]
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Ensure schema exists
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'proc_vw')
        EXEC ('CREATE SCHEMA proc_vw');

    DECLARE
        @po_contract_col SYSNAME = NULL,
        @ct_contract_col SYSNAME = NULL,
        @ct_start_col    SYSNAME = NULL,
        @ct_end_col      SYSNAME = NULL;

    /* 2) Detect contract reference column in purchase_order_headers */
    ;WITH c AS (
        SELECT c.name
        FROM sys.columns c
        JOIN sys.objects o ON c.object_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'offshore_srm'
          AND o.name = 'purchase_order_headers'
          AND c.name IN ('contract_reference','contract_number','agreement_number','outline_agreement','contract_id','contract_ref')
    )
    SELECT TOP 1 @po_contract_col = name FROM c;

    /* 3) Detect contract reference column in srm_contracts */
    ;WITH c AS (
        SELECT c.name
        FROM sys.columns c
        JOIN sys.objects o ON c.object_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'offshore_srm'
          AND o.name = 'srm_contracts'
          AND c.name IN ('contract_reference','contract_number','agreement_number','outline_agreement','contract_id','contract_ref')
    )
    SELECT TOP 1 @ct_contract_col = name FROM c;

    /* 4) Detect optional contract validity date columns (if they exist) */
    ;WITH d AS (
        SELECT c.name
        FROM sys.columns c
        JOIN sys.objects o ON c.object_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'offshore_srm'
          AND o.name = 'srm_contracts'
          AND c.name IN ('validity_start_date','start_date','contract_start_date','valid_from')
    )
    SELECT TOP 1 @ct_start_col = name FROM d;

    ;WITH d AS (
        SELECT c.name
        FROM sys.columns c
        JOIN sys.objects o ON c.object_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'offshore_srm'
          AND o.name = 'srm_contracts'
          AND c.name IN ('validity_end_date','end_date','contract_end_date','valid_to')
    )
    SELECT TOP 1 @ct_end_col = name FROM d;

    /* 5) Build the view SQL dynamically so it ALWAYS compiles */
    DECLARE @sql NVARCHAR(MAX) = N'
CREATE OR ALTER VIEW proc_vw.maverick_spend
AS
WITH po_total AS
(
    SELECT
        i.purchase_order_number,
        po_total_value =
            CAST(SUM(
                CAST(COALESCE(i.order_quantity,0) AS decimal(18,4))
              * CAST(COALESCE(i.net_price,0)     AS decimal(18,4))
            ) AS decimal(18,2))
    FROM offshore_srm.purchase_order_items i
    GROUP BY i.purchase_order_number
),
base AS
(
    SELECT
        h.purchase_order_number,
        h.supplier_code,
        v.vendor_code,
        vendor_name = COALESCE(NULLIF(v.company_name, ''''), NULLIF(v.business_name, '''')),
        v.vendor_status,
        h.purchasing_organisation,
        h.purchasing_group,
        h.plant,
        h.currency,
        h.purchase_order_type,
        h.purchase_order_date,
        h.purchase_order_status,
        t.po_total_value,

        d.[Year]    AS calendar_year,
        d.[Month]   AS calendar_month,
        d.MonthName AS month_name,
        d.MonthYear AS month_year,
        d.MMYYYY    AS mmyyyy
        ' + CASE WHEN @po_contract_col IS NOT NULL THEN N',
        h.' + QUOTENAME(@po_contract_col) + N' AS contract_reference' ELSE N',
        CAST(NULL AS nvarchar(100)) AS contract_reference' END + N'
    FROM offshore_srm.purchase_order_headers h
    LEFT JOIN po_total t
        ON t.purchase_order_number = h.purchase_order_number
    LEFT JOIN offshore_srm.vendors v
        ON v.vendor_code = h.supplier_code
    LEFT JOIN offshore_eam.date_dimension d
        ON d.[Date] = h.purchase_order_date
    WHERE h.purchase_order_status = ''Active''
),
contract_match AS
(
    SELECT
        b.*,
        contract_match_flag =
            CASE
                WHEN b.contract_reference IS NULL OR LTRIM(RTRIM(b.contract_reference)) = '''' THEN 0
                ' + CASE
                      WHEN @ct_contract_col IS NOT NULL
                      THEN N'WHEN EXISTS (
                            SELECT 1
                            FROM offshore_srm.srm_contracts c
                            WHERE c.' + QUOTENAME(@ct_contract_col) + N' = b.contract_reference
                            ' + CASE
                                  WHEN @ct_start_col IS NOT NULL AND @ct_end_col IS NOT NULL
                                  THEN N'AND (TRY_CONVERT(date, c.' + QUOTENAME(@ct_start_col) + N') IS NULL OR TRY_CONVERT(date, c.' + QUOTENAME(@ct_start_col) + N') <= b.purchase_order_date)
                                       AND (TRY_CONVERT(date, c.' + QUOTENAME(@ct_end_col) + N') IS NULL OR TRY_CONVERT(date, c.' + QUOTENAME(@ct_end_col) + N') >= b.purchase_order_date)'
                                  ELSE N''
                              END + N'
                        ) THEN 1'
                      ELSE N'ELSE 0'  -- no contracts table key found
                  END + N'
                ELSE 0
            END
    FROM base b
),
classified AS
(
    SELECT
        c.*,

        is_off_contract =
            CASE WHEN c.contract_match_flag = 0 THEN 1 ELSE 0 END,

        is_unapproved_vendor =
            CASE
                WHEN c.vendor_code IS NULL THEN 1
                WHEN UPPER(LTRIM(RTRIM(COALESCE(c.vendor_status,'''')))) IN (''BLOCKED'',''INACTIVE'',''SUSPENDED'') THEN 1
                ELSE 0
            END,

        is_maverick =
            CASE
                WHEN c.contract_match_flag = 0 THEN 1
                WHEN c.vendor_code IS NULL THEN 1
                WHEN UPPER(LTRIM(RTRIM(COALESCE(c.vendor_status,'''')))) IN (''BLOCKED'',''INACTIVE'',''SUSPENDED'') THEN 1
                ELSE 0
            END
    FROM contract_match c
)
SELECT
    -- Grain: 1 row = 1 PO header
    purchase_order_number,
    supplier_code,
    vendor_code,
    vendor_name,
    vendor_status,
    purchasing_organisation,
    purchasing_group,
    plant,
    currency,
    purchase_order_type,
    purchase_order_date,
    calendar_year,
    calendar_month,
    month_name,
    month_year,
    mmyyyy,
    contract_reference,

    po_total_value,

    contract_match_flag,
    is_off_contract,
    is_unapproved_vendor,
    is_maverick,

    -- KPIs (monthly window metrics)
    maverick_spend_value_month =
        SUM(CASE WHEN is_maverick = 1 THEN COALESCE(po_total_value,0) ELSE 0 END)
        OVER (PARTITION BY calendar_year, calendar_month),

    total_spend_value_month =
        SUM(COALESCE(po_total_value,0))
        OVER (PARTITION BY calendar_year, calendar_month),

    maverick_spend_pct_month =
        CASE
            WHEN SUM(COALESCE(po_total_value,0)) OVER (PARTITION BY calendar_year, calendar_month) > 0
            THEN CAST(
                SUM(CASE WHEN is_maverick = 1 THEN COALESCE(po_total_value,0) ELSE 0 END)
                OVER (PARTITION BY calendar_year, calendar_month)
                /
                NULLIF(SUM(COALESCE(po_total_value,0)) OVER (PARTITION BY calendar_year, calendar_month), 0)
            AS decimal(18,4))
            ELSE NULL
        END,

    off_contract_po_count_month =
        SUM(CASE WHEN is_off_contract = 1 THEN 1 ELSE 0 END)
        OVER (PARTITION BY calendar_year, calendar_month)
FROM classified
WHERE is_off_contract = 1;';

    EXEC sp_executesql @sql;

    PRINT '✅ proc_vw.maverick_spend deployed successfully.';
    PRINT 'Detected columns:';
    PRINT ' - PO contract ref column: ' + COALESCE(@po_contract_col,'(none)');
    PRINT ' - Contracts key column  : ' + COALESCE(@ct_contract_col,'(none)');
END;
GO