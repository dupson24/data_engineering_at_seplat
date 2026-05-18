```sql
-- ============================================================
-- ASA: SRM Multi-Table DDL + Stored Procedures + Watermark
-- Schema  : offshore_srm (target) | zzSTG_offshore_srm (staging)
-- ============================================================

-- ============================================================
-- STEP 1 — Create schemas
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'offshore_srm')
    EXEC('CREATE SCHEMA [offshore_srm]');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'zzSTG_offshore_srm')
    EXEC('CREATE SCHEMA [zzSTG_offshore_srm]');


-- ============================================================
-- TABLE 1 — purchase_order_headers
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[purchase_order_headers]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[purchase_order_headers];

CREATE TABLE [zzSTG_offshore_srm].[purchase_order_headers]
(
    [purchase_order_number]         NVARCHAR(50)    NULL,
    [supplier_code]                 NVARCHAR(50)    NULL,
    [purchasing_organisation]       NVARCHAR(50)    NULL,
    [purchasing_group]              NVARCHAR(20)    NULL,
    [purchase_order_type]           NVARCHAR(20)    NULL,
    [currency]                      NVARCHAR(10)    NULL,
    [purchase_order_date]           DATE            NULL,
    [purchase_order_status]         NVARCHAR(20)    NULL,
    [created_by]                    NVARCHAR(100)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [approval_date]                 DATE            NULL,
    [validity_start_date]           DATE            NULL,
    [validity_end_date]             DATE            NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[purchase_order_headers]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[purchase_order_headers];

CREATE TABLE [offshore_srm].[purchase_order_headers]
(
    [purchase_order_number]         NVARCHAR(50)    NOT NULL,
    [supplier_code]                 NVARCHAR(50)    NULL,
    [purchasing_organisation]       NVARCHAR(50)    NULL,
    [purchasing_group]              NVARCHAR(20)    NULL,
    [purchase_order_type]           NVARCHAR(20)    NULL,
    [currency]                      NVARCHAR(10)    NULL,
    [purchase_order_date]           DATE            NULL,
    [purchase_order_status]         NVARCHAR(20)    NULL,
    [created_by]                    NVARCHAR(100)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [approval_date]                 DATE            NULL,
    [validity_start_date]           DATE            NULL,
    [validity_end_date]             DATE            NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_number]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 2 — purchase_order_items
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[purchase_order_items]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[purchase_order_items];

CREATE TABLE [zzSTG_offshore_srm].[purchase_order_items]
(
    [purchase_order_number]         NVARCHAR(50)    NULL,
    [purchase_order_item_number]    NVARCHAR(10)    NULL,
    [material_code]                 NVARCHAR(50)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [order_quantity]                DECIMAL(18,3)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [net_price]                     DECIMAL(18,2)   NULL,
    [material_group]                NVARCHAR(20)    NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [delivery_date]                 DATE            NULL,
    [item_status]                   NVARCHAR(20)    NULL,
    [delivery_status]               NVARCHAR(20)    NULL,
    [item_category]                 NVARCHAR(10)    NULL,
    [supplier_code]                 NVARCHAR(50)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[purchase_order_items]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[purchase_order_items];

CREATE TABLE [offshore_srm].[purchase_order_items]
(
    [purchase_order_number]         NVARCHAR(50)    NOT NULL,
    [purchase_order_item_number]    NVARCHAR(10)    NOT NULL,
    [material_code]                 NVARCHAR(50)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [order_quantity]                DECIMAL(18,3)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [net_price]                     DECIMAL(18,2)   NULL,
    [material_group]                NVARCHAR(20)    NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [delivery_date]                 DATE            NULL,
    [item_status]                   NVARCHAR(20)    NULL,
    [delivery_status]               NVARCHAR(20)    NULL,
    [item_category]                 NVARCHAR(10)    NULL,
    [supplier_code]                 NVARCHAR(50)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_number]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 3 — work_order_master
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[work_order_master]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[work_order_master];

CREATE TABLE [zzSTG_offshore_srm].[work_order_master]
(
    [work_order_number]             NVARCHAR(20)    NULL,
    [work_order_type]               NVARCHAR(20)    NULL,
    [work_order_description]        NVARCHAR(255)   NULL,
    [maintenance_plant]             NVARCHAR(20)    NULL,
    [cost_centre]                   NVARCHAR(20)    NULL,
    [equipment_number]              NVARCHAR(50)    NULL,
    [created_by]                    NVARCHAR(100)   NULL,
    [creation_date]                 DATE            NULL,
    [planned_start_date]            DATE            NULL,
    [planned_finish_date]           DATE            NULL,
    [work_order_status]             NVARCHAR(20)    NULL,
    [priority]                      NVARCHAR(10)    NULL,
    [routing_number]                NVARCHAR(20)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[work_order_master]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[work_order_master];

CREATE TABLE [offshore_srm].[work_order_master]
(
    [work_order_number]             NVARCHAR(20)    NOT NULL,
    [work_order_type]               NVARCHAR(20)    NULL,
    [work_order_description]        NVARCHAR(255)   NULL,
    [maintenance_plant]             NVARCHAR(20)    NULL,
    [cost_centre]                   NVARCHAR(20)    NULL,
    [equipment_number]              NVARCHAR(50)    NULL,
    [created_by]                    NVARCHAR(100)   NULL,
    [creation_date]                 DATE            NULL,
    [planned_start_date]            DATE            NULL,
    [planned_finish_date]           DATE            NULL,
    [work_order_status]             NVARCHAR(20)    NULL,
    [priority]                      NVARCHAR(10)    NULL,
    [routing_number]                NVARCHAR(20)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([work_order_number]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 4 — bank_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[bank_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[bank_details];

CREATE TABLE [zzSTG_offshore_srm].[bank_details]
(
    [bank_sort_code]                NVARCHAR(20)    NULL,
    [bank_name]                     NVARCHAR(255)   NULL,
    [bank_country]                  NVARCHAR(10)    NULL,
    [bank_branch]                   NVARCHAR(100)   NULL,
    [bank_street_address]           NVARCHAR(255)   NULL,
    [bank_city]                     NVARCHAR(100)   NULL,
    [swift_code]                    NVARCHAR(20)    NULL,
    [created_date]                  DATE            NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[bank_details]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[bank_details];

CREATE TABLE [offshore_srm].[bank_details]
(
    [bank_sort_code]                NVARCHAR(20)    NOT NULL,
    [bank_name]                     NVARCHAR(255)   NULL,
    [bank_country]                  NVARCHAR(10)    NULL,
    [bank_branch]                   NVARCHAR(100)   NULL,
    [bank_street_address]           NVARCHAR(255)   NULL,
    [bank_city]                     NVARCHAR(100)   NULL,
    [swift_code]                    NVARCHAR(20)    NULL,
    [created_date]                  DATE            NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 5 — requisitions
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[requisitions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[requisitions];

CREATE TABLE [zzSTG_offshore_srm].[requisitions]
(
    [requisition_number]            NVARCHAR(20)    NULL,
    [requisition_item_number]       NVARCHAR(10)    NULL,
    [material_group]                NVARCHAR(20)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [estimated_price]               DECIMAL(18,2)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [requested_quantity]            DECIMAL(18,3)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [cost_centre]                   NVARCHAR(20)    NULL,
    [requisition_date]              DATE            NULL,
    [requested_by]                  NVARCHAR(100)   NULL,
    [release_status]                NVARCHAR(10)    NULL,
    [purchase_order_reference]      NVARCHAR(50)    NULL,
    [item_category]                 NVARCHAR(10)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[requisitions]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[requisitions];

CREATE TABLE [offshore_srm].[requisitions]
(
    [requisition_number]            NVARCHAR(20)    NOT NULL,
    [requisition_item_number]       NVARCHAR(10)    NOT NULL,
    [material_group]                NVARCHAR(20)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [estimated_price]               DECIMAL(18,2)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [requested_quantity]            DECIMAL(18,3)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [cost_centre]                   NVARCHAR(20)    NULL,
    [requisition_date]              DATE            NULL,
    [requested_by]                  NVARCHAR(100)   NULL,
    [release_status]                NVARCHAR(10)    NULL,
    [purchase_order_reference]      NVARCHAR(50)    NULL,
    [item_category]                 NVARCHAR(10)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([requisition_number]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 6 — supplier_category
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[supplier_category]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[supplier_category];

CREATE TABLE [zzSTG_offshore_srm].[supplier_category]
(
    [category_id]                   INT             NULL,
    [purchasing_group_code]         NVARCHAR(20)    NULL,
    [purchasing_group_description]  NVARCHAR(100)   NULL,
    [material_group_code]           NVARCHAR(20)    NULL,
    [material_group_description]    NVARCHAR(100)   NULL,
    [created_date]                  DATE            NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[supplier_category]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[supplier_category];

CREATE TABLE [offshore_srm].[supplier_category]
(
    [category_id]                   INT             NOT NULL,
    [purchasing_group_code]         NVARCHAR(20)    NULL,
    [purchasing_group_description]  NVARCHAR(100)   NULL,
    [material_group_code]           NVARCHAR(20)    NULL,
    [material_group_description]    NVARCHAR(100)   NULL,
    [created_date]                  DATE            NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 7 — tenders
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[tenders]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[tenders];

CREATE TABLE [zzSTG_offshore_srm].[tenders]
(
    [purchase_order_number]         NVARCHAR(50)    NULL,
    [tender_item_number]            NVARCHAR(10)    NULL,
    [supplier_code]                 NVARCHAR(50)    NULL,
    [tender_description]            NVARCHAR(255)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [tender_posted_date]            DATE            NULL,
    [tender_open_date]              DATE            NULL,
    [tender_close_date]             DATE            NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[tenders]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[tenders];

CREATE TABLE [offshore_srm].[tenders]
(
    [purchase_order_number]         NVARCHAR(50)    NOT NULL,
    [tender_item_number]            NVARCHAR(10)    NOT NULL,
    [supplier_code]                 NVARCHAR(50)    NULL,
    [tender_description]            NVARCHAR(255)   NULL,
    [plant]                         NVARCHAR(20)    NULL,
    [tender_posted_date]            DATE            NULL,
    [tender_open_date]              DATE            NULL,
    [tender_close_date]             DATE            NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_number]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 8 — transactions
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[transactions]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[transactions];

CREATE TABLE [zzSTG_offshore_srm].[transactions]
(
    [transaction_id]                NVARCHAR(20)    NULL,
    [origin_document_number]        NVARCHAR(20)    NULL,
    [issue_type]                    NVARCHAR(20)    NULL,
    [sales_office]                  NVARCHAR(20)    NULL,
    [billing_date]                  DATE            NULL,
    [total_sales_value]             DECIMAL(18,2)   NULL,
    [discount_amount]               DECIMAL(18,2)   NULL,
    [from_location]                 NVARCHAR(20)    NULL,
    [to_location]                   NVARCHAR(20)    NULL,
    [issued_by_organisation]        NVARCHAR(20)    NULL,
    [customer_id]                   NVARCHAR(20)    NULL,
    [payment_type]                  NVARCHAR(20)    NULL,
    [payment_status]                NVARCHAR(20)    NULL,
    [invoice_number]                NVARCHAR(50)    NULL,
    [approved_by]                   NVARCHAR(100)   NULL,
    [confirmed_date]                NVARCHAR(20)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[transactions]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[transactions];

CREATE TABLE [offshore_srm].[transactions]
(
    [transaction_id]                NVARCHAR(20)    NOT NULL,
    [origin_document_number]        NVARCHAR(20)    NULL,
    [issue_type]                    NVARCHAR(20)    NULL,
    [sales_office]                  NVARCHAR(20)    NULL,
    [billing_date]                  DATE            NULL,
    [total_sales_value]             DECIMAL(18,2)   NULL,
    [discount_amount]               DECIMAL(18,2)   NULL,
    [from_location]                 NVARCHAR(20)    NULL,
    [to_location]                   NVARCHAR(20)    NULL,
    [issued_by_organisation]        NVARCHAR(20)    NULL,
    [customer_id]                   NVARCHAR(20)    NULL,
    [payment_type]                  NVARCHAR(20)    NULL,
    [payment_status]                NVARCHAR(20)    NULL,
    [invoice_number]                NVARCHAR(50)    NULL,
    [approved_by]                   NVARCHAR(100)   NULL,
    [confirmed_date]                NVARCHAR(20)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([transaction_id]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 9 — transfers
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[transfers]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[transfers];

CREATE TABLE [zzSTG_offshore_srm].[transfers]
(
    [transfer_line_item]            NVARCHAR(10)    NULL,
    [transaction_id]                NVARCHAR(20)    NULL,
    [origin_document_number]        NVARCHAR(20)    NULL,
    [material_code]                 NVARCHAR(50)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [billed_quantity]               DECIMAL(18,3)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [net_price]                     DECIMAL(18,2)   NULL,
    [special_price]                 DECIMAL(18,2)   NULL,
    [discount_percentage]           DECIMAL(18,2)   NULL,
    [from_plant]                    NVARCHAR(20)    NULL,
    [to_storage_location]           NVARCHAR(20)    NULL,
    [item_category]                 NVARCHAR(10)    NULL,
    [transfer_date]                 DATE            NULL,
    [issued_by]                     NVARCHAR(100)   NULL,
    [payment_status]                NVARCHAR(20)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[transfers]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[transfers];

CREATE TABLE [offshore_srm].[transfers]
(
    [transfer_line_item]            NVARCHAR(10)    NOT NULL,
    [transaction_id]                NVARCHAR(20)    NOT NULL,
    [origin_document_number]        NVARCHAR(20)    NULL,
    [material_code]                 NVARCHAR(50)    NULL,
    [item_description]              NVARCHAR(255)   NULL,
    [billed_quantity]               DECIMAL(18,3)   NULL,
    [unit_of_measure]               NVARCHAR(10)    NULL,
    [net_price]                     DECIMAL(18,2)   NULL,
    [special_price]                 DECIMAL(18,2)   NULL,
    [discount_percentage]           DECIMAL(18,2)   NULL,
    [from_plant]                    NVARCHAR(20)    NULL,
    [to_storage_location]           NVARCHAR(20)    NULL,
    [item_category]                 NVARCHAR(10)    NULL,
    [transfer_date]                 DATE            NULL,
    [issued_by]                     NVARCHAR(100)   NULL,
    [payment_status]                NVARCHAR(20)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([transaction_id]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- TABLE 10 — vendors
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendors]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendors];

CREATE TABLE [zzSTG_offshore_srm].[vendors]
(
    [vendor_code]                   NVARCHAR(20)    NULL,
    [vendor_account_group]          NVARCHAR(20)    NULL,
    [business_name]                 NVARCHAR(255)   NULL,
    [company_name]                  NVARCHAR(255)   NULL,
    [registration_number]           NVARCHAR(50)    NULL,
    [email_address]                 NVARCHAR(255)   NULL,
    [phone_number]                  NVARCHAR(50)    NULL,
    [registered_address]            NVARCHAR(255)   NULL,
    [city]                          NVARCHAR(100)   NULL,
    [state_region]                  NVARCHAR(50)    NULL,
    [country]                       NVARCHAR(10)    NULL,
    [vendor_status]                 NVARCHAR(20)    NULL,
    [tax_identification_number]     NVARCHAR(50)    NULL,
    [vat_registration_number]       NVARCHAR(50)    NULL,
    [registration_date]             DATE            NULL,
    [payment_terms]                 NVARCHAR(20)    NULL,
    [currency]                      NVARCHAR(10)    NULL,
    [reconciliation_account]        NVARCHAR(20)    NULL,
    [bank_sort_code]                NVARCHAR(20)    NULL,
    [bank_account_number]           NVARCHAR(50)    NULL,
    [bank_account_type]             NVARCHAR(10)    NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendors]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendors];

CREATE TABLE [offshore_srm].[vendors]
(
    [vendor_code]                   NVARCHAR(20)    NOT NULL,
    [vendor_account_group]          NVARCHAR(20)    NULL,
    [business_name]                 NVARCHAR(255)   NULL,
    [company_name]                  NVARCHAR(255)   NULL,
    [registration_number]           NVARCHAR(50)    NULL,
    [email_address]                 NVARCHAR(255)   NULL,
    [phone_number]                  NVARCHAR(50)    NULL,
    [registered_address]            NVARCHAR(255)   NULL,
    [city]                          NVARCHAR(100)   NULL,
    [state_region]                  NVARCHAR(50)    NULL,
    [country]                       NVARCHAR(10)    NULL,
    [vendor_status]                 NVARCHAR(20)    NULL,
    [tax_identification_number]     NVARCHAR(50)    NULL,
    [vat_registration_number]       NVARCHAR(50)    NULL,
    [registration_date]             DATE            NULL,
    [payment_terms]                 NVARCHAR(20)    NULL,
    [currency]                      NVARCHAR(10)    NULL,
    [reconciliation_account]        NVARCHAR(20)    NULL,
    [bank_sort_code]                NVARCHAR(20)    NULL,
    [bank_account_number]           NVARCHAR(50)    NULL,
    [bank_account_type]             NVARCHAR(10)    NULL,
    [load_id]                       NVARCHAR(100)   NULL,
    [pipeline_run_id]               NVARCHAR(100)   NULL,
    [source_path]                   NVARCHAR(500)   NULL,
    [loaded_at]                     DATETIME2       NULL,
    [updated_at]                    DATETIME2       NULL
)
WITH (DISTRIBUTION = HASH([vendor_code]), CLUSTERED COLUMNSTORE INDEX);


-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- SP 1 — purchase_order_headers
IF OBJECT_ID('[dbo].[usp_offshore_srm_purchase_order_headers]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_purchase_order_headers];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_purchase_order_headers]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[purchase_order_headers]
    WHERE [purchase_order_number] IN (
        SELECT [purchase_order_number] FROM [zzSTG_offshore_srm].[purchase_order_headers]
        WHERE [purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[purchase_order_headers]
    SELECT [purchase_order_number],[supplier_code],[purchasing_organisation],
           [purchasing_group],[purchase_order_type],[currency],
           [purchase_order_date],[purchase_order_status],[created_by],[plant],
           [approval_date],[validity_start_date],[validity_end_date],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[purchase_order_headers]
    WHERE [purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[purchase_order_headers];
END;
GO


-- SP 2 — purchase_order_items
IF OBJECT_ID('[dbo].[usp_offshore_srm_purchase_order_items]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_purchase_order_items];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_purchase_order_items]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[purchase_order_items]
    WHERE [purchase_order_number] IN (
        SELECT [purchase_order_number] FROM [zzSTG_offshore_srm].[purchase_order_items]
        WHERE [purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[purchase_order_items]
    SELECT [purchase_order_number],[purchase_order_item_number],[material_code],
           [item_description],[order_quantity],[unit_of_measure],[net_price],
           [material_group],[plant],[delivery_date],[item_status],
           [delivery_status],[item_category],[supplier_code],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[purchase_order_items]
    WHERE [purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[purchase_order_items];
END;
GO


-- SP 3 — work_order_master
IF OBJECT_ID('[dbo].[usp_offshore_srm_work_order_master]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_work_order_master];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_work_order_master]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[work_order_master]
    WHERE [work_order_number] IN (
        SELECT [work_order_number] FROM [zzSTG_offshore_srm].[work_order_master]
        WHERE [work_order_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[work_order_master]
    SELECT [work_order_number],[work_order_type],[work_order_description],
           [maintenance_plant],[cost_centre],[equipment_number],[created_by],
           [creation_date],[planned_start_date],[planned_finish_date],
           [work_order_status],[priority],[routing_number],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[work_order_master]
    WHERE [work_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[work_order_master];
END;
GO


-- SP 4 — bank_details
IF OBJECT_ID('[dbo].[usp_offshore_srm_bank_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_bank_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_bank_details]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[bank_details]
    WHERE [bank_sort_code] IN (
        SELECT [bank_sort_code] FROM [zzSTG_offshore_srm].[bank_details]
        WHERE [bank_sort_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[bank_details]
    SELECT [bank_sort_code],[bank_name],[bank_country],[bank_branch],
           [bank_street_address],[bank_city],[swift_code],[created_date],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[bank_details]
    WHERE [bank_sort_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[bank_details];
END;
GO


-- SP 5 — requisitions
IF OBJECT_ID('[dbo].[usp_offshore_srm_requisitions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_requisitions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_requisitions]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[requisitions]
    WHERE [requisition_number] IN (
        SELECT [requisition_number] FROM [zzSTG_offshore_srm].[requisitions]
        WHERE [requisition_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[requisitions]
    SELECT [requisition_number],[requisition_item_number],[material_group],
           [item_description],[estimated_price],[unit_of_measure],
           [requested_quantity],[plant],[cost_centre],[requisition_date],
           [requested_by],[release_status],[purchase_order_reference],
           [item_category],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[requisitions]
    WHERE [requisition_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[requisitions];
END;
GO


-- SP 6 — supplier_category
IF OBJECT_ID('[dbo].[usp_offshore_srm_supplier_category]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_supplier_category];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_supplier_category]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[supplier_category]
    WHERE [category_id] IN (
        SELECT [category_id] FROM [zzSTG_offshore_srm].[supplier_category]
        WHERE [category_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[supplier_category]
    SELECT [category_id],[purchasing_group_code],[purchasing_group_description],
           [material_group_code],[material_group_description],[created_date],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[supplier_category]
    WHERE [category_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[supplier_category];
END;
GO


-- SP 7 — tenders
IF OBJECT_ID('[dbo].[usp_offshore_srm_tenders]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_tenders];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_tenders]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[tenders]
    WHERE [purchase_order_number] IN (
        SELECT [purchase_order_number] FROM [zzSTG_offshore_srm].[tenders]
        WHERE [purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[tenders]
    SELECT [purchase_order_number],[tender_item_number],[supplier_code],
           [tender_description],[plant],[tender_posted_date],
           [tender_open_date],[tender_close_date],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[tenders]
    WHERE [purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[tenders];
END;
GO


-- SP 8 — transactions
IF OBJECT_ID('[dbo].[usp_offshore_srm_transactions]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_transactions];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_transactions]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[transactions]
    WHERE [transaction_id] IN (
        SELECT [transaction_id] FROM [zzSTG_offshore_srm].[transactions]
        WHERE [transaction_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[transactions]
    SELECT [transaction_id],[origin_document_number],[issue_type],
           [sales_office],[billing_date],[total_sales_value],[discount_amount],
           [from_location],[to_location],[issued_by_organisation],[customer_id],
           [payment_type],[payment_status],[invoice_number],[approved_by],
           [confirmed_date],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[transactions]
    WHERE [transaction_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[transactions];
END;
GO


-- SP 9 — transfers
IF OBJECT_ID('[dbo].[usp_offshore_srm_transfers]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_transfers];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_transfers]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[transfers]
    WHERE [transaction_id] IN (
        SELECT [transaction_id] FROM [zzSTG_offshore_srm].[transfers]
        WHERE [transaction_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[transfers]
    SELECT [transfer_line_item],[transaction_id],[origin_document_number],
           [material_code],[item_description],[billed_quantity],[unit_of_measure],
           [net_price],[special_price],[discount_percentage],[from_plant],
           [to_storage_location],[item_category],[transfer_date],[issued_by],
           [payment_status],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[transfers]
    WHERE [transaction_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[transfers];
END;
GO


-- SP 10 — vendors
IF OBJECT_ID('[dbo].[usp_offshore_srm_vendors]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendors];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendors]
    @load_id         NVARCHAR(100),
    @pipeline_run_id NVARCHAR(100),
    @source_path     NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendors]
    WHERE [vendor_code] IN (
        SELECT [vendor_code] FROM [zzSTG_offshore_srm].[vendors]
        WHERE [vendor_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendors]
    SELECT [vendor_code],[vendor_account_group],[business_name],[company_name],
           [registration_number],[email_address],[phone_number],
           [registered_address],[city],[state_region],[country],
           [vendor_status],[tax_identification_number],[vat_registration_number],
           [registration_date],[payment_terms],[currency],
           [reconciliation_account],[bank_sort_code],[bank_account_number],
           [bank_account_type],
           @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendors]
    WHERE [vendor_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendors];
END;
GO


-- ============================================================
-- WATERMARK — seed all 10 tables
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES
('purchase_order_headers','offshore_srm','SAP_ECC_EKKO',
 CONCAT('[dbo].[usp_offshore_srm_purchase_order_headers]'),
 '1900-01-01','initial',0,NULL,@now),

('purchase_order_items','offshore_srm','SAP_ECC_EKPO',
 CONCAT('[dbo].[usp_offshore_srm_purchase_order_items]'),
 '1900-01-01','initial',0,NULL,@now),

('work_order_master','offshore_srm','SAP_ECC_AUFK',
 CONCAT('[dbo].[usp_offshore_srm_work_order_master]'),
 '1900-01-01','initial',0,NULL,@now),

('bank_details','offshore_srm','SAP_ECC_BNKA',
 CONCAT('[dbo].[usp_offshore_srm_bank_details]'),
 '1900-01-01','initial',0,NULL,@now),

('requisitions','offshore_srm','SAP_ECC_EBAN_EIPO',
 CONCAT('[dbo].[usp_offshore_srm_requisitions]'),
 '1900-01-01','initial',0,NULL,@now),

('supplier_category','offshore_srm','SAP_ECC_T023_T024',
 CONCAT('[dbo].[usp_offshore_srm_supplier_category]'),
 '1900-01-01','initial',0,NULL,@now),

('tenders','offshore_srm','SAP_ECC_EKAB',
 CONCAT('[dbo].[usp_offshore_srm_tenders]'),
 '1900-01-01','initial',0,NULL,@now),

('transactions','offshore_srm','SAP_ECC_VBRK',
 CONCAT('[dbo].[usp_offshore_srm_transactions]'),
 '1900-01-01','initial',0,NULL,@now),

('transfers','offshore_srm','SAP_ECC_VBRP',
 CONCAT('[dbo].[usp_offshore_srm_transfers]'),
 '1900-01-01','initial',0,NULL,@now),

('vendors','offshore_srm','SAP_ECC_LFA1_LFB1_LFBK',
 CONCAT('[dbo].[usp_offshore_srm_vendors]'),
 '1900-01-01','initial',0,NULL,@now);


-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT * FROM [offshore_eam].[watermark] WHERE schema_name = 'offshore_srm';
-- SELECT COUNT(*) FROM [offshore_srm].[vendors];
-- SELECT COUNT(*) FROM [offshore_srm].[purchase_order_headers];
-- SELECT COUNT(*) FROM [offshore_srm].[transactions];
```