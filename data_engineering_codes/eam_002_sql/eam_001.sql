-- ============================================================
-- ASA: EAM Full DDL — Staging + Target + Stored Procs + Watermark
-- Schema  : offshore_eam (target) | zzSTG_offshore_eam (staging)
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'offshore_eam')
    EXEC('CREATE SCHEMA [offshore_eam]');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'zzSTG_offshore_eam')
    EXEC('CREATE SCHEMA [zzSTG_offshore_eam]');

-- ============================================================
-- date_dimension
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[date_dimension]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[date_dimension];

CREATE TABLE [zzSTG_offshore_eam].[date_dimension]
(
    [date]                                    DATE                 NULL,
    [day_of_week]                             INT                  NULL,
    [month]                                   INT                  NULL,
    [year]                                    INT                  NULL,
    [fiscal_period]                           NVARCHAR(10)         NULL,
    [week_of_year]                            INT                  NULL,
    [week_of_month]                           INT                  NULL,
    [quarter]                                 INT                  NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[date_dimension]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[date_dimension];

CREATE TABLE [offshore_eam].[date_dimension]
(
    [date]                                    DATE                 NOT NULL,
    [day_of_week]                             INT                  NULL,
    [month]                                   INT                  NULL,
    [year]                                    INT                  NULL,
    [fiscal_period]                           NVARCHAR(10)         NULL,
    [week_of_year]                            INT                  NULL,
    [week_of_month]                           INT                  NULL,
    [quarter]                                 INT                  NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- invoice_voucher_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[invoice_voucher_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[invoice_voucher_details];

CREATE TABLE [zzSTG_offshore_eam].[invoice_voucher_details]
(
    [invoice_voucher_code]                    NVARCHAR(20)         NULL,
    [company_code]                            NVARCHAR(10)         NULL,
    [fiscal_year]                             NVARCHAR(4)          NULL,
    [document_type]                           NVARCHAR(10)         NULL,
    [document_date]                           DATE                 NULL,
    [posting_date]                            DATE                 NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [document_status]                         NVARCHAR(10)         NULL,
    [reference_number]                        NVARCHAR(50)         NULL,
    [document_header_text]                    NVARCHAR(255)        NULL,
    [created_by]                              NVARCHAR(100)        NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [payment_due_date]                        DATE                 NULL,
    [total_amount]                            DECIMAL(18,2)        NULL,
    [payment_method]                          NVARCHAR(10)         NULL,
    [cleared_date]                            DATE                 NULL,
    [liv_supplier_code]                       NVARCHAR(20)         NULL,
    [gross_invoice_amount]                    DECIMAL(18,2)        NULL,
    [invoice_status]                          NVARCHAR(10)         NULL,
    [external_invoice_number]                 NVARCHAR(50)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[invoice_voucher_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[invoice_voucher_details];

CREATE TABLE [offshore_eam].[invoice_voucher_details]
(
    [invoice_voucher_code]                    NVARCHAR(20)         NOT NULL,
    [company_code]                            NVARCHAR(10)         NULL,
    [fiscal_year]                             NVARCHAR(4)          NULL,
    [document_type]                           NVARCHAR(10)         NULL,
    [document_date]                           DATE                 NULL,
    [posting_date]                            DATE                 NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [document_status]                         NVARCHAR(10)         NULL,
    [reference_number]                        NVARCHAR(50)         NULL,
    [document_header_text]                    NVARCHAR(255)        NULL,
    [created_by]                              NVARCHAR(100)        NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [payment_due_date]                        DATE                 NULL,
    [total_amount]                            DECIMAL(18,2)        NULL,
    [payment_method]                          NVARCHAR(10)         NULL,
    [cleared_date]                            DATE                 NULL,
    [liv_supplier_code]                       NVARCHAR(20)         NULL,
    [gross_invoice_amount]                    DECIMAL(18,2)        NULL,
    [invoice_status]                          NVARCHAR(10)         NULL,
    [external_invoice_number]                 NVARCHAR(50)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([invoice_voucher_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- invoice_voucher_line_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[invoice_voucher_line_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[invoice_voucher_line_details];

CREATE TABLE [zzSTG_offshore_eam].[invoice_voucher_line_details]
(
    [invoice_voucher_code]                    NVARCHAR(20)         NULL,
    [company_code]                            NVARCHAR(10)         NULL,
    [fiscal_year]                             NVARCHAR(4)          NULL,
    [line_item_number]                        NVARCHAR(10)         NULL,
    [gl_account]                              NVARCHAR(20)         NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [transaction_amount]                      DECIMAL(18,2)        NULL,
    [local_currency_amount]                   DECIMAL(18,2)        NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [debit_credit_indicator]                  NVARCHAR(5)          NULL,
    [line_item_text]                          NVARCHAR(255)        NULL,
    [cost_centre]                             NVARCHAR(20)         NULL,
    [order_number]                            NVARCHAR(20)         NULL,
    [tax_amount]                              DECIMAL(18,2)        NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [invoice_quantity]                        DECIMAL(18,3)        NULL,
    [invoice_amount]                          DECIMAL(18,2)        NULL,
    [material_code]                           NVARCHAR(50)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[invoice_voucher_line_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[invoice_voucher_line_details];

CREATE TABLE [offshore_eam].[invoice_voucher_line_details]
(
    [invoice_voucher_code]                    NVARCHAR(20)         NOT NULL,
    [company_code]                            NVARCHAR(10)         NULL,
    [fiscal_year]                             NVARCHAR(4)          NULL,
    [line_item_number]                        NVARCHAR(10)         NULL,
    [gl_account]                              NVARCHAR(20)         NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [transaction_amount]                      DECIMAL(18,2)        NULL,
    [local_currency_amount]                   DECIMAL(18,2)        NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [debit_credit_indicator]                  NVARCHAR(5)          NULL,
    [line_item_text]                          NVARCHAR(255)        NULL,
    [cost_centre]                             NVARCHAR(20)         NULL,
    [order_number]                            NVARCHAR(20)         NULL,
    [tax_amount]                              DECIMAL(18,2)        NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [invoice_quantity]                        DECIMAL(18,3)        NULL,
    [invoice_amount]                          DECIMAL(18,2)        NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([invoice_voucher_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- organisation_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[organisation_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[organisation_details];

CREATE TABLE [zzSTG_offshore_eam].[organisation_details]
(
    [organisation_code]                       NVARCHAR(10)         NULL,
    [organisation_description]                NVARCHAR(255)        NULL,
    [organisation_currency]                   NVARCHAR(10)         NULL,
    [country]                                 NVARCHAR(10)         NULL,
    [language]                                NVARCHAR(10)         NULL,
    [address_number]                          NVARCHAR(20)         NULL,
    [fiscal_year_variant]                     NVARCHAR(10)         NULL,
    [chart_of_accounts]                       NVARCHAR(10)         NULL,
    [controlling_area]                        NVARCHAR(10)         NULL,
    [controlling_area_description]            NVARCHAR(255)        NULL,
    [controlling_area_currency]               NVARCHAR(10)         NULL,
    [company_code_description]                NVARCHAR(255)        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[organisation_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[organisation_details];

CREATE TABLE [offshore_eam].[organisation_details]
(
    [organisation_code]                       NVARCHAR(10)         NOT NULL,
    [organisation_description]                NVARCHAR(255)        NULL,
    [organisation_currency]                   NVARCHAR(10)         NULL,
    [country]                                 NVARCHAR(10)         NULL,
    [language]                                NVARCHAR(10)         NULL,
    [address_number]                          NVARCHAR(20)         NULL,
    [fiscal_year_variant]                     NVARCHAR(10)         NULL,
    [chart_of_accounts]                       NVARCHAR(10)         NULL,
    [controlling_area]                        NVARCHAR(10)         NULL,
    [controlling_area_description]            NVARCHAR(255)        NULL,
    [controlling_area_currency]               NVARCHAR(10)         NULL,
    [company_code_description]                NVARCHAR(255)        NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- parts_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[parts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[parts_details];

CREATE TABLE [zzSTG_offshore_eam].[parts_details]
(
    [material_code]                           NVARCHAR(50)         NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [material_type]                           NVARCHAR(10)         NULL,
    [base_unit_of_measure]                    NVARCHAR(10)         NULL,
    [industry_standard_description]           NVARCHAR(255)        NULL,
    [gross_weight]                            DECIMAL(18,3)        NULL,
    [net_weight]                              DECIMAL(18,3)        NULL,
    [weight_unit]                             NVARCHAR(10)         NULL,
    [created_date]                            DATE                 NULL,
    [material_description]                    NVARCHAR(255)        NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [checking_rule]                           NVARCHAR(10)         NULL,
    [reorder_point]                           DECIMAL(18,3)        NULL,
    [safety_stock]                            DECIMAL(18,3)        NULL,
    [alternative_uom]                         NVARCHAR(10)         NULL,
    [conversion_numerator]                    DECIMAL(18,3)        NULL,
    [conversion_denominator]                  DECIMAL(18,3)        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[parts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[parts_details];

CREATE TABLE [offshore_eam].[parts_details]
(
    [material_code]                           NVARCHAR(50)         NOT NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [material_type]                           NVARCHAR(10)         NULL,
    [base_unit_of_measure]                    NVARCHAR(10)         NULL,
    [industry_standard_description]           NVARCHAR(255)        NULL,
    [gross_weight]                            DECIMAL(18,3)        NULL,
    [net_weight]                              DECIMAL(18,3)        NULL,
    [weight_unit]                             NVARCHAR(10)         NULL,
    [created_date]                            DATE                 NULL,
    [material_description]                    NVARCHAR(255)        NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [checking_rule]                           NVARCHAR(10)         NULL,
    [reorder_point]                           DECIMAL(18,3)        NULL,
    [safety_stock]                            DECIMAL(18,3)        NULL,
    [alternative_uom]                         NVARCHAR(10)         NULL,
    [conversion_numerator]                    DECIMAL(18,3)        NULL,
    [conversion_denominator]                  DECIMAL(18,3)        NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([material_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- parts_stock_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[parts_stock_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[parts_stock_details];

CREATE TABLE [zzSTG_offshore_eam].[parts_stock_details]
(
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [unrestricted_stock_quantity]             DECIMAL(18,3)        NULL,
    [quality_inspection_stock]                DECIMAL(18,3)        NULL,
    [restricted_use_stock]                    DECIMAL(18,3)        NULL,
    [blocked_stock]                           DECIMAL(18,3)        NULL,
    [batch_number]                            NVARCHAR(20)         NULL,
    [batch_unrestricted_stock]                DECIMAL(18,3)        NULL,
    [last_material_document_number]           NVARCHAR(20)         NULL,
    [last_movement_type]                      NVARCHAR(10)         NULL,
    [last_movement_quantity]                  DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [last_posting_date]                       DATE                 NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[parts_stock_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[parts_stock_details];

CREATE TABLE [offshore_eam].[parts_stock_details]
(
    [material_code]                           NVARCHAR(50)         NOT NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [unrestricted_stock_quantity]             DECIMAL(18,3)        NULL,
    [quality_inspection_stock]                DECIMAL(18,3)        NULL,
    [restricted_use_stock]                    DECIMAL(18,3)        NULL,
    [blocked_stock]                           DECIMAL(18,3)        NULL,
    [batch_number]                            NVARCHAR(20)         NULL,
    [batch_unrestricted_stock]                DECIMAL(18,3)        NULL,
    [last_material_document_number]           NVARCHAR(20)         NULL,
    [last_movement_type]                      NVARCHAR(10)         NULL,
    [last_movement_quantity]                  DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [last_posting_date]                       DATE                 NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([material_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- parts_store_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[parts_store_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[parts_store_details];

CREATE TABLE [zzSTG_offshore_eam].[parts_store_details]
(
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_bin]                             NVARCHAR(20)         NULL,
    [minimum_stock_level]                     DECIMAL(18,3)        NULL,
    [maximum_stock_level]                     DECIMAL(18,3)        NULL,
    [safety_stock_level]                      DECIMAL(18,3)        NULL,
    [reorder_point_method]                    NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [base_unit_of_measure]                    NVARCHAR(10)         NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [valuation_area]                          NVARCHAR(10)         NULL,
    [moving_average_price]                    DECIMAL(18,4)        NULL,
    [standard_price]                          DECIMAL(18,4)        NULL,
    [price_unit]                              INT                  NULL,
    [valuation_class]                         NVARCHAR(10)         NULL,
    [total_valuated_stock]                    DECIMAL(18,3)        NULL,
    [total_stock_value]                       DECIMAL(18,2)        NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[parts_store_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[parts_store_details];

CREATE TABLE [offshore_eam].[parts_store_details]
(
    [material_code]                           NVARCHAR(50)         NOT NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_bin]                             NVARCHAR(20)         NULL,
    [minimum_stock_level]                     DECIMAL(18,3)        NULL,
    [maximum_stock_level]                     DECIMAL(18,3)        NULL,
    [safety_stock_level]                      DECIMAL(18,3)        NULL,
    [reorder_point_method]                    NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [base_unit_of_measure]                    NVARCHAR(10)         NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [valuation_area]                          NVARCHAR(10)         NULL,
    [moving_average_price]                    DECIMAL(18,4)        NULL,
    [standard_price]                          DECIMAL(18,4)        NULL,
    [price_unit]                              INT                  NULL,
    [valuation_class]                         NVARCHAR(10)         NULL,
    [total_valuated_stock]                    DECIMAL(18,3)        NULL,
    [total_stock_value]                       DECIMAL(18,2)        NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([material_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [purchasing_organisation]                 NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [purchase_order_type]                     NVARCHAR(10)         NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [purchase_order_date]                     DATE                 NULL,
    [purchase_order_status]                   NVARCHAR(20)         NULL,
    [created_by]                              NVARCHAR(100)        NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [approval_date]                           DATE                 NULL,
    [validity_start_date]                     DATE                 NULL,
    [validity_end_date]                       DATE                 NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_details];

CREATE TABLE [offshore_eam].[purchase_order_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NOT NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [purchasing_organisation]                 NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [purchase_order_type]                     NVARCHAR(10)         NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [purchase_order_date]                     DATE                 NULL,
    [purchase_order_status]                   NVARCHAR(20)         NULL,
    [created_by]                              NVARCHAR(100)        NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [approval_date]                           DATE                 NULL,
    [validity_start_date]                     DATE                 NULL,
    [validity_end_date]                       DATE                 NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_parts_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_parts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_parts_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_parts_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [item_description]                        NVARCHAR(255)        NULL,
    [order_quantity]                          DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [net_price]                               DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [delivery_date]                           DATE                 NULL,
    [item_status]                             NVARCHAR(20)         NULL,
    [delivery_completion_status]              NVARCHAR(20)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_parts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_parts_details];

CREATE TABLE [offshore_eam].[purchase_order_parts_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NOT NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [item_description]                        NVARCHAR(255)        NULL,
    [order_quantity]                          DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [net_price]                               DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [delivery_date]                           DATE                 NULL,
    [item_status]                             NVARCHAR(20)         NULL,
    [delivery_completion_status]              NVARCHAR(20)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_receipt_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_receipt_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_receipt_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_receipt_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [posting_date]                            DATE                 NULL,
    [document_date]                           DATE                 NULL,
    [received_by]                             NVARCHAR(100)        NULL,
    [document_header_text]                    NVARCHAR(255)        NULL,
    [document_type]                           NVARCHAR(10)         NULL,
    [plant]                                   NVARCHAR(10)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_receipt_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_receipt_details];

CREATE TABLE [offshore_eam].[purchase_order_receipt_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NOT NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [posting_date]                            DATE                 NULL,
    [document_date]                           DATE                 NULL,
    [received_by]                             NVARCHAR(100)        NULL,
    [document_header_text]                    NVARCHAR(255)        NULL,
    [document_type]                           NVARCHAR(10)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([goods_receipt_document_number]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_receipt_packingslip_active_lines_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [document_line_item]                      NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [goods_receipt_quantity]                  DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [movement_type]                           NVARCHAR(10)         NULL,
    [posting_date]                            DATE                 NULL,
    [debit_credit_indicator]                  NVARCHAR(5)          NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_receipt_packingslip_active_lines_details];

CREATE TABLE [offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NOT NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [document_line_item]                      NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [goods_receipt_quantity]                  DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [movement_type]                           NVARCHAR(10)         NULL,
    [posting_date]                            DATE                 NULL,
    [debit_credit_indicator]                  NVARCHAR(5)          NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([goods_receipt_document_number]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_receipts_packingslip_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [document_line_item]                      NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [delivered_quantity]                      DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [delivery_document_number]                NVARCHAR(20)         NULL,
    [delivery_item]                           NVARCHAR(10)         NULL,
    [delivery_quantity]                       DECIMAL(18,3)        NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [planned_goods_issue_date]                DATE                 NULL,
    [ship_to_customer]                        NVARCHAR(20)         NULL,
    [delivery_type]                           NVARCHAR(10)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_receipts_packingslip_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_receipts_packingslip_details];

CREATE TABLE [offshore_eam].[purchase_order_receipts_packingslip_details]
(
    [goods_receipt_document_number]           NVARCHAR(20)         NOT NULL,
    [material_document_year]                  NVARCHAR(4)          NULL,
    [document_line_item]                      NVARCHAR(10)         NULL,
    [material_code]                           NVARCHAR(50)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [delivered_quantity]                      DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [delivery_document_number]                NVARCHAR(20)         NULL,
    [delivery_item]                           NVARCHAR(10)         NULL,
    [delivery_quantity]                       DECIMAL(18,3)        NULL,
    [storage_location]                        NVARCHAR(10)         NULL,
    [planned_goods_issue_date]                DATE                 NULL,
    [ship_to_customer]                        NVARCHAR(20)         NULL,
    [delivery_type]                           NVARCHAR(10)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([goods_receipt_document_number]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_service_receipts_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_service_receipts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_service_receipts_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_service_receipts_details]
(
    [service_entry_sheet_number]              NVARCHAR(20)         NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [total_net_value]                         DECIMAL(18,2)        NULL,
    [condition_record_number]                 NVARCHAR(20)         NULL,
    [internal_row_number]                     NVARCHAR(10)         NULL,
    [service_number]                          NVARCHAR(20)         NULL,
    [service_description]                     NVARCHAR(255)        NULL,
    [service_quantity]                        DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [total_value]                             DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [posting_date]                            DATE                 NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_service_receipts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_service_receipts_details];

CREATE TABLE [offshore_eam].[purchase_order_service_receipts_details]
(
    [service_entry_sheet_number]              NVARCHAR(20)         NOT NULL,
    [purchase_order_number]                   NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [currency]                                NVARCHAR(10)         NULL,
    [total_net_value]                         DECIMAL(18,2)        NULL,
    [condition_record_number]                 NVARCHAR(20)         NULL,
    [internal_row_number]                     NVARCHAR(10)         NULL,
    [service_number]                          NVARCHAR(20)         NULL,
    [service_description]                     NVARCHAR(255)        NULL,
    [service_quantity]                        DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [total_value]                             DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [material_group]                          NVARCHAR(20)         NULL,
    [posting_date]                            DATE                 NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([service_entry_sheet_number]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- purchase_order_services_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[purchase_order_services_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[purchase_order_services_details];

CREATE TABLE [zzSTG_offshore_eam].[purchase_order_services_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [service_description]                     NVARCHAR(255)        NULL,
    [net_price]                               DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [quantity]                                DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [deletion_indicator]                      NVARCHAR(5)          NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[purchase_order_services_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[purchase_order_services_details];

CREATE TABLE [offshore_eam].[purchase_order_services_details]
(
    [purchase_order_code]                     NVARCHAR(20)         NOT NULL,
    [purchase_order_item]                     NVARCHAR(10)         NULL,
    [service_description]                     NVARCHAR(255)        NULL,
    [net_price]                               DECIMAL(18,2)        NULL,
    [net_value]                               DECIMAL(18,2)        NULL,
    [quantity]                                DECIMAL(18,3)        NULL,
    [unit_of_measure]                         NVARCHAR(10)         NULL,
    [plant]                                   NVARCHAR(10)         NULL,
    [deletion_indicator]                      NVARCHAR(5)          NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_code]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- quotation_requests_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_details]
(
    [rfq_number]                              NVARCHAR(20)         NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [purchasing_organisation]                 NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [created_date]                            DATE                 NULL,
    [language]                                NVARCHAR(5)          NULL,
    [rfq_type]                                NVARCHAR(10)         NULL,
    [quotation_deadline_date]                 DATE                 NULL,
    [binding_period_end_date]                 DATE                 NULL,
    [our_reference]                           NVARCHAR(50)         NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_details];

CREATE TABLE [offshore_eam].[quotation_requests_details]
(
    [rfq_number]                              NVARCHAR(20)         NOT NULL,
    [supplier_code]                           NVARCHAR(20)         NULL,
    [purchasing_organisation]                 NVARCHAR(10)         NULL,
    [purchasing_group]                        NVARCHAR(10)         NULL,
    [created_date]                            DATE                 NULL,
    [language]                                NVARCHAR(5)          NULL,
    [rfq_type]                                NVARCHAR(10)         NULL,
    [quotation_deadline_date]                 DATE                 NULL,
    [binding_period_end_date]                 DATE                 NULL,
    [our_reference]                           NVARCHAR(50)         NULL,
    [load_id]                                 NVARCHAR(100)        NULL,
    [pipeline_run_id]                         NVARCHAR(100)        NULL,
    [source_path]                             NVARCHAR(500)        NULL,
    [loaded_at]                               DATETIME2            NULL,
    [updated_at]                              DATETIME2            NULL
)
WITH (DISTRIBUTION = HASH([rfq_number]), CLUSTERED COLUMNSTORE INDEX);

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

IF OBJECT_ID('[dbo].[usp_offshore_eam_date_dimension]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_date_dimension];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_date_dimension]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[date_dimension]
    WHERE [date] IN (
        SELECT [date] FROM [zzSTG_offshore_eam].[date_dimension]
        WHERE [date] IS NOT NULL);

    INSERT INTO [offshore_eam].[date_dimension]
    (
        [date],
        [day_of_week],
        [month],
        [year],
        [fiscal_period],
        [week_of_year],
        [week_of_month],
        [quarter],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [date],
        [day_of_week],
        [month],
        [year],
        [fiscal_period],
        [week_of_year],
        [week_of_month],
        [quarter],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[date_dimension]
    WHERE [date] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[date_dimension];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_invoice_voucher_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_invoice_voucher_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_invoice_voucher_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[invoice_voucher_details]
    WHERE [invoice_voucher_code] IN (
        SELECT [invoice_voucher_code] FROM [zzSTG_offshore_eam].[invoice_voucher_details]
        WHERE [invoice_voucher_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[invoice_voucher_details]
    (
        [invoice_voucher_code],
        [company_code],
        [fiscal_year],
        [document_type],
        [document_date],
        [posting_date],
        [currency],
        [document_status],
        [reference_number],
        [document_header_text],
        [created_by],
        [supplier_code],
        [payment_due_date],
        [total_amount],
        [payment_method],
        [cleared_date],
        [liv_supplier_code],
        [gross_invoice_amount],
        [invoice_status],
        [external_invoice_number],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [invoice_voucher_code],
        [company_code],
        [fiscal_year],
        [document_type],
        [document_date],
        [posting_date],
        [currency],
        [document_status],
        [reference_number],
        [document_header_text],
        [created_by],
        [supplier_code],
        [payment_due_date],
        [total_amount],
        [payment_method],
        [cleared_date],
        [liv_supplier_code],
        [gross_invoice_amount],
        [invoice_status],
        [external_invoice_number],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[invoice_voucher_details]
    WHERE [invoice_voucher_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[invoice_voucher_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_invoice_voucher_line_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_invoice_voucher_line_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_invoice_voucher_line_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[invoice_voucher_line_details]
    WHERE [invoice_voucher_code] IN (
        SELECT [invoice_voucher_code] FROM [zzSTG_offshore_eam].[invoice_voucher_line_details]
        WHERE [invoice_voucher_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[invoice_voucher_line_details]
    (
        [invoice_voucher_code],
        [company_code],
        [fiscal_year],
        [line_item_number],
        [gl_account],
        [supplier_code],
        [transaction_amount],
        [local_currency_amount],
        [currency],
        [debit_credit_indicator],
        [line_item_text],
        [cost_centre],
        [order_number],
        [tax_amount],
        [purchase_order_number],
        [purchase_order_item],
        [invoice_quantity],
        [invoice_amount],
        [material_code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [invoice_voucher_code],
        [company_code],
        [fiscal_year],
        [line_item_number],
        [gl_account],
        [supplier_code],
        [transaction_amount],
        [local_currency_amount],
        [currency],
        [debit_credit_indicator],
        [line_item_text],
        [cost_centre],
        [order_number],
        [tax_amount],
        [purchase_order_number],
        [purchase_order_item],
        [invoice_quantity],
        [invoice_amount],
        [material_code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[invoice_voucher_line_details]
    WHERE [invoice_voucher_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[invoice_voucher_line_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_organisation_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_organisation_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_organisation_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[organisation_details]
    WHERE [organisation_code] IN (
        SELECT [organisation_code] FROM [zzSTG_offshore_eam].[organisation_details]
        WHERE [organisation_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[organisation_details]
    (
        [organisation_code],
        [organisation_description],
        [organisation_currency],
        [country],
        [language],
        [address_number],
        [fiscal_year_variant],
        [chart_of_accounts],
        [controlling_area],
        [controlling_area_description],
        [controlling_area_currency],
        [company_code_description],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [organisation_code],
        [organisation_description],
        [organisation_currency],
        [country],
        [language],
        [address_number],
        [fiscal_year_variant],
        [chart_of_accounts],
        [controlling_area],
        [controlling_area_description],
        [controlling_area_currency],
        [company_code_description],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[organisation_details]
    WHERE [organisation_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[organisation_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_parts_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_parts_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_parts_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[parts_details]
    WHERE [material_code] IN (
        SELECT [material_code] FROM [zzSTG_offshore_eam].[parts_details]
        WHERE [material_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[parts_details]
    (
        [material_code],
        [material_group],
        [material_type],
        [base_unit_of_measure],
        [industry_standard_description],
        [gross_weight],
        [net_weight],
        [weight_unit],
        [created_date],
        [material_description],
        [plant],
        [purchasing_group],
        [checking_rule],
        [reorder_point],
        [safety_stock],
        [alternative_uom],
        [conversion_numerator],
        [conversion_denominator],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_code],
        [material_group],
        [material_type],
        [base_unit_of_measure],
        [industry_standard_description],
        [gross_weight],
        [net_weight],
        [weight_unit],
        [created_date],
        [material_description],
        [plant],
        [purchasing_group],
        [checking_rule],
        [reorder_point],
        [safety_stock],
        [alternative_uom],
        [conversion_numerator],
        [conversion_denominator],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[parts_details]
    WHERE [material_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[parts_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_parts_stock_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_parts_stock_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_parts_stock_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[parts_stock_details]
    WHERE [material_code] IN (
        SELECT [material_code] FROM [zzSTG_offshore_eam].[parts_stock_details]
        WHERE [material_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[parts_stock_details]
    (
        [material_code],
        [plant],
        [storage_location],
        [unrestricted_stock_quantity],
        [quality_inspection_stock],
        [restricted_use_stock],
        [blocked_stock],
        [batch_number],
        [batch_unrestricted_stock],
        [last_material_document_number],
        [last_movement_type],
        [last_movement_quantity],
        [unit_of_measure],
        [last_posting_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_code],
        [plant],
        [storage_location],
        [unrestricted_stock_quantity],
        [quality_inspection_stock],
        [restricted_use_stock],
        [blocked_stock],
        [batch_number],
        [batch_unrestricted_stock],
        [last_material_document_number],
        [last_movement_type],
        [last_movement_quantity],
        [unit_of_measure],
        [last_posting_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[parts_stock_details]
    WHERE [material_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[parts_stock_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_parts_store_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_parts_store_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_parts_store_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[parts_store_details]
    WHERE [material_code] IN (
        SELECT [material_code] FROM [zzSTG_offshore_eam].[parts_store_details]
        WHERE [material_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[parts_store_details]
    (
        [material_code],
        [plant],
        [storage_bin],
        [minimum_stock_level],
        [maximum_stock_level],
        [safety_stock_level],
        [reorder_point_method],
        [purchasing_group],
        [base_unit_of_measure],
        [material_group],
        [valuation_area],
        [moving_average_price],
        [standard_price],
        [price_unit],
        [valuation_class],
        [total_valuated_stock],
        [total_stock_value],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_code],
        [plant],
        [storage_bin],
        [minimum_stock_level],
        [maximum_stock_level],
        [safety_stock_level],
        [reorder_point_method],
        [purchasing_group],
        [base_unit_of_measure],
        [material_group],
        [valuation_area],
        [moving_average_price],
        [standard_price],
        [price_unit],
        [valuation_class],
        [total_valuated_stock],
        [total_stock_value],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[parts_store_details]
    WHERE [material_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[parts_store_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_details]
    WHERE [purchase_order_code] IN (
        SELECT [purchase_order_code] FROM [zzSTG_offshore_eam].[purchase_order_details]
        WHERE [purchase_order_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_details]
    (
        [purchase_order_code],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [purchase_order_type],
        [currency],
        [purchase_order_date],
        [purchase_order_status],
        [created_by],
        [plant],
        [approval_date],
        [validity_start_date],
        [validity_end_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [purchase_order_code],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [purchase_order_type],
        [currency],
        [purchase_order_date],
        [purchase_order_status],
        [created_by],
        [plant],
        [approval_date],
        [validity_start_date],
        [validity_end_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_details]
    WHERE [purchase_order_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_parts_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_parts_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_parts_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_parts_details]
    WHERE [purchase_order_code] IN (
        SELECT [purchase_order_code] FROM [zzSTG_offshore_eam].[purchase_order_parts_details]
        WHERE [purchase_order_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_parts_details]
    (
        [purchase_order_code],
        [purchase_order_item],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [item_status],
        [delivery_completion_status],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [purchase_order_code],
        [purchase_order_item],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [item_status],
        [delivery_completion_status],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_parts_details]
    WHERE [purchase_order_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_parts_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_receipt_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipt_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipt_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_receipt_details]
    WHERE [goods_receipt_document_number] IN (
        SELECT [goods_receipt_document_number] FROM [zzSTG_offshore_eam].[purchase_order_receipt_details]
        WHERE [goods_receipt_document_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_receipt_details]
    (
        [goods_receipt_document_number],
        [material_document_year],
        [posting_date],
        [document_date],
        [received_by],
        [document_header_text],
        [document_type],
        [plant],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [goods_receipt_document_number],
        [material_document_year],
        [posting_date],
        [document_date],
        [received_by],
        [document_header_text],
        [document_type],
        [plant],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_receipt_details]
    WHERE [goods_receipt_document_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_receipt_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_receipt_packingslip_active_lines_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipt_packingslip_active_lines_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipt_packingslip_active_lines_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
    WHERE [goods_receipt_document_number] IN (
        SELECT [goods_receipt_document_number] FROM [zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
        WHERE [goods_receipt_document_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
    (
        [goods_receipt_document_number],
        [material_document_year],
        [document_line_item],
        [material_code],
        [plant],
        [storage_location],
        [goods_receipt_quantity],
        [unit_of_measure],
        [purchase_order_number],
        [purchase_order_item],
        [movement_type],
        [posting_date],
        [debit_credit_indicator],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [goods_receipt_document_number],
        [material_document_year],
        [document_line_item],
        [material_code],
        [plant],
        [storage_location],
        [goods_receipt_quantity],
        [unit_of_measure],
        [purchase_order_number],
        [purchase_order_item],
        [movement_type],
        [posting_date],
        [debit_credit_indicator],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details]
    WHERE [goods_receipt_document_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_receipt_packingslip_active_lines_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_receipts_packingslip_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipts_packingslip_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_receipts_packingslip_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_receipts_packingslip_details]
    WHERE [goods_receipt_document_number] IN (
        SELECT [goods_receipt_document_number] FROM [zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details]
        WHERE [goods_receipt_document_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_receipts_packingslip_details]
    (
        [goods_receipt_document_number],
        [material_document_year],
        [document_line_item],
        [material_code],
        [plant],
        [delivered_quantity],
        [unit_of_measure],
        [purchase_order_number],
        [delivery_document_number],
        [delivery_item],
        [delivery_quantity],
        [storage_location],
        [planned_goods_issue_date],
        [ship_to_customer],
        [delivery_type],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [goods_receipt_document_number],
        [material_document_year],
        [document_line_item],
        [material_code],
        [plant],
        [delivered_quantity],
        [unit_of_measure],
        [purchase_order_number],
        [delivery_document_number],
        [delivery_item],
        [delivery_quantity],
        [storage_location],
        [planned_goods_issue_date],
        [ship_to_customer],
        [delivery_type],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details]
    WHERE [goods_receipt_document_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_receipts_packingslip_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_service_receipts_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_service_receipts_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_service_receipts_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_service_receipts_details]
    WHERE [service_entry_sheet_number] IN (
        SELECT [service_entry_sheet_number] FROM [zzSTG_offshore_eam].[purchase_order_service_receipts_details]
        WHERE [service_entry_sheet_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_service_receipts_details]
    (
        [service_entry_sheet_number],
        [purchase_order_number],
        [purchase_order_item],
        [currency],
        [total_net_value],
        [condition_record_number],
        [internal_row_number],
        [service_number],
        [service_description],
        [service_quantity],
        [unit_of_measure],
        [total_value],
        [net_value],
        [material_group],
        [posting_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [service_entry_sheet_number],
        [purchase_order_number],
        [purchase_order_item],
        [currency],
        [total_net_value],
        [condition_record_number],
        [internal_row_number],
        [service_number],
        [service_description],
        [service_quantity],
        [unit_of_measure],
        [total_value],
        [net_value],
        [material_group],
        [posting_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_service_receipts_details]
    WHERE [service_entry_sheet_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_service_receipts_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_purchase_order_services_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_purchase_order_services_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_purchase_order_services_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[purchase_order_services_details]
    WHERE [purchase_order_code] IN (
        SELECT [purchase_order_code] FROM [zzSTG_offshore_eam].[purchase_order_services_details]
        WHERE [purchase_order_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[purchase_order_services_details]
    (
        [purchase_order_code],
        [purchase_order_item],
        [service_description],
        [net_price],
        [net_value],
        [quantity],
        [unit_of_measure],
        [plant],
        [deletion_indicator],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [purchase_order_code],
        [purchase_order_item],
        [service_description],
        [net_price],
        [net_value],
        [quantity],
        [unit_of_measure],
        [plant],
        [deletion_indicator],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[purchase_order_services_details]
    WHERE [purchase_order_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[purchase_order_services_details];
END;
GO

IF OBJECT_ID('[dbo].[usp_offshore_eam_quotation_requests_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[quotation_requests_details]
    WHERE [rfq_number] IN (
        SELECT [rfq_number] FROM [zzSTG_offshore_eam].[quotation_requests_details]
        WHERE [rfq_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_details]
    (
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [created_date],
        [language],
        [rfq_type],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [created_date],
        [language],
        [rfq_type],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_details]
    WHERE [rfq_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_details];
END;
GO

-- ============================================================
-- WATERMARK — seed all EAM tables
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES
('date_dimension','offshore_eam','SAP_ECC_SCAL_TT_DATE','[dbo].[usp_offshore_eam_date_dimension]','1900-01-01','initial',0,NULL,@now),
('invoice_voucher_details','offshore_eam','SAP_ECC_BKPF+BSIK+RBKPB','[dbo].[usp_offshore_eam_invoice_voucher_details]','1900-01-01','initial',0,NULL,@now),
('invoice_voucher_line_details','offshore_eam','SAP_ECC_BSEG+RSEG','[dbo].[usp_offshore_eam_invoice_voucher_line_details]','1900-01-01','initial',0,NULL,@now),
('organisation_details','offshore_eam','SAP_ECC_T001+TKA01+TBUKRS','[dbo].[usp_offshore_eam_organisation_details]','1900-01-01','initial',0,NULL,@now),
('parts_details','offshore_eam','SAP_ECC_MARA+MAKT+MARC+MARM','[dbo].[usp_offshore_eam_parts_details]','1900-01-01','initial',0,NULL,@now),
('parts_stock_details','offshore_eam','SAP_ECC_MARD+MCHB+MSEG','[dbo].[usp_offshore_eam_parts_stock_details]','1900-01-01','initial',0,NULL,@now),
('parts_store_details','offshore_eam','SAP_ECC_MARC+MARA+MBEW','[dbo].[usp_offshore_eam_parts_store_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_details','offshore_eam','SAP_ECC_EKKO','[dbo].[usp_offshore_eam_purchase_order_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_parts_details','offshore_eam','SAP_ECC_EKPO','[dbo].[usp_offshore_eam_purchase_order_parts_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_receipt_details','offshore_eam','SAP_ECC_MKPF','[dbo].[usp_offshore_eam_purchase_order_receipt_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_receipt_packingslip_active_lines_details','offshore_eam','SAP_ECC_MSEG','[dbo].[usp_offshore_eam_purchase_order_receipt_packingslip_active_lines_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_receipts_packingslip_details','offshore_eam','SAP_ECC_MSEG+LIKP+LIPS','[dbo].[usp_offshore_eam_purchase_order_receipts_packingslip_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_service_receipts_details','offshore_eam','SAP_ECC_ESLH+ESLL','[dbo].[usp_offshore_eam_purchase_order_service_receipts_details]','1900-01-01','initial',0,NULL,@now),
('purchase_order_services_details','offshore_eam','SAP_ECC_EKPO+EKPV','[dbo].[usp_offshore_eam_purchase_order_services_details]','1900-01-01','initial',0,NULL,@now),
('quotation_requests_details','offshore_eam','SAP_ECC_EKAN','[dbo].[usp_offshore_eam_quotation_requests_details]','1900-01-01','initial',0,NULL,@now);

-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT COUNT(*) AS [date_dimension] FROM [offshore_eam].[date_dimension];
-- SELECT COUNT(*) AS [invoice_voucher_details] FROM [offshore_eam].[invoice_voucher_details];
-- SELECT COUNT(*) AS [invoice_voucher_line_details] FROM [offshore_eam].[invoice_voucher_line_details];
-- SELECT COUNT(*) AS [organisation_details] FROM [offshore_eam].[organisation_details];
-- SELECT COUNT(*) AS [parts_details] FROM [offshore_eam].[parts_details];
-- SELECT COUNT(*) AS [parts_stock_details] FROM [offshore_eam].[parts_stock_details];
-- SELECT COUNT(*) AS [parts_store_details] FROM [offshore_eam].[parts_store_details];
-- SELECT COUNT(*) AS [purchase_order_details] FROM [offshore_eam].[purchase_order_details];
-- SELECT COUNT(*) AS [purchase_order_parts_details] FROM [offshore_eam].[purchase_order_parts_details];
-- SELECT COUNT(*) AS [purchase_order_receipt_details] FROM [offshore_eam].[purchase_order_receipt_details];
-- SELECT COUNT(*) AS [purchase_order_receipt_packingslip_active_lines_details] FROM [offshore_eam].[purchase_order_receipt_packingslip_active_lines_details];
-- SELECT COUNT(*) AS [purchase_order_receipts_packingslip_details] FROM [offshore_eam].[purchase_order_receipts_packingslip_details];
-- SELECT COUNT(*) AS [purchase_order_service_receipts_details] FROM [offshore_eam].[purchase_order_service_receipts_details];
-- SELECT COUNT(*) AS [purchase_order_services_details] FROM [offshore_eam].[purchase_order_services_details];
-- SELECT COUNT(*) AS [quotation_requests_details] FROM [offshore_eam].[quotation_requests_details];
-- SELECT * FROM [offshore_eam].[watermark] WHERE schema_name = 'offshore_eam';