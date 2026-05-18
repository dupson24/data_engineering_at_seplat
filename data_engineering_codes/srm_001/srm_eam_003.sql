-- ============================================================
-- RFQ + Transacts — Staging + Target + Stored Procs + Watermark
-- Tables: quotation_requests_parts_details,
--         quotation_requests_services_details,
--         quotation_requests_details (offshore_eam)
--         transacts (offshore_srm)
-- ============================================================

-- ============================================================
-- quotation_requests_parts_details
-- Schema: offshore_eam  |  17 data cols + 5 metadata = 22 target cols
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_parts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details]
(
    [rfq_number]                                NVARCHAR(255)             NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL,
    [item_category]                             NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_parts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_parts_details];

CREATE TABLE [offshore_eam].[quotation_requests_parts_details]
(
    [rfq_number]                                NVARCHAR(255)             NOT NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL,
    [item_category]                             NVARCHAR(255)             NULL,
    [load_id]                                   NVARCHAR(100)             NULL,
    [pipeline_run_id]                           NVARCHAR(100)             NULL,
    [source_path]                               NVARCHAR(500)             NULL,
    [loaded_at]                                 DATETIME2                 NULL,
    [updated_at]                                DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([rfq_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_quotation_requests_parts_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_parts_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_parts_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[quotation_requests_parts_details]
    WHERE [rfq_number] IN (
        SELECT [rfq_number] FROM [zzSTG_offshore_eam].[quotation_requests_parts_details]
        WHERE  [rfq_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_parts_details]
    (
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        [item_category],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        [item_category],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_parts_details]
    WHERE [rfq_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details];
END;
GO

-- ============================================================
-- quotation_requests_services_details
-- Schema: offshore_eam  |  21 data cols + 5 metadata = 26 target cols
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_services_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_services_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_services_details]
(
    [rfq_purchase_order_number]                 NVARCHAR(255)             NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [service_description]                       NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [net_value]                                 DECIMAL(18,2)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [item_category]                             NVARCHAR(255)             NULL,
    [deletion_indicator]                        NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_services_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_services_details];

CREATE TABLE [offshore_eam].[quotation_requests_services_details]
(
    [rfq_purchase_order_number]                 NVARCHAR(255)             NOT NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [service_description]                       NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [net_value]                                 DECIMAL(18,2)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [item_category]                             NVARCHAR(255)             NULL,
    [deletion_indicator]                        NVARCHAR(255)             NULL,
    [load_id]                                   NVARCHAR(100)             NULL,
    [pipeline_run_id]                           NVARCHAR(100)             NULL,
    [source_path]                               NVARCHAR(500)             NULL,
    [loaded_at]                                 DATETIME2                 NULL,
    [updated_at]                                DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([rfq_purchase_order_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_quotation_requests_services_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_services_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_quotation_requests_services_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[quotation_requests_services_details]
    WHERE [rfq_purchase_order_number] IN (
        SELECT [rfq_purchase_order_number] FROM [zzSTG_offshore_eam].[quotation_requests_services_details]
        WHERE  [rfq_purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_services_details]
    (
        [rfq_purchase_order_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [created_by],
        [created_date],
        [rfq_item_number],
        [service_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [plant],
        [material_group],
        [item_category],
        [deletion_indicator],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_purchase_order_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [created_by],
        [created_date],
        [rfq_item_number],
        [service_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [plant],
        [material_group],
        [item_category],
        [deletion_indicator],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_services_details]
    WHERE [rfq_purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_services_details];
END;
GO

-- ============================================================
-- quotation_requests_details
-- Schema: offshore_eam  |  21 data cols + 5 metadata = 26 target cols
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_details]
(
    [rfq_number]                                NVARCHAR(255)             NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [our_reference]                             NVARCHAR(255)             NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_details];

CREATE TABLE [offshore_eam].[quotation_requests_details]
(
    [rfq_number]                                NVARCHAR(255)             NOT NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [rfq_type]                                  NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [rfq_date]                                  DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [our_reference]                             NVARCHAR(255)             NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [rfq_item_number]                           NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [rfq_quantity]                              DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL,
    [load_id]                                   NVARCHAR(100)             NULL,
    [pipeline_run_id]                           NVARCHAR(100)             NULL,
    [source_path]                               NVARCHAR(500)             NULL,
    [loaded_at]                                 DATETIME2                 NULL,
    [updated_at]                                DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([rfq_number]), CLUSTERED COLUMNSTORE INDEX);

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
        WHERE  [rfq_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_details]
    (
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        [created_by],
        [created_date],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_number],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [rfq_type],
        [currency],
        [rfq_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        [created_by],
        [created_date],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_details]
    WHERE [rfq_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_details];
END;
GO

-- ============================================================
-- transacts
-- Schema: offshore_srm  |  29 data cols + 5 metadata = 34 target cols
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[transacts]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[transacts];

CREATE TABLE [zzSTG_offshore_srm].[transacts]
(
    [transaction_id]                            NVARCHAR(255)             NULL,
    [document_type]                             NVARCHAR(255)             NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [document_date]                             DATE                      NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [our_reference]                             NVARCHAR(255)             NULL,
    [deletion_indicator]                        NVARCHAR(255)             NULL,
    [release_status]                            NVARCHAR(255)             NULL,
    [transaction_item_number]                   NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [order_quantity]                            DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [net_value]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL,
    [item_category]                             NVARCHAR(255)             NULL,
    [item_deletion_indicator]                   NVARCHAR(255)             NULL,
    [delivery_completed_indicator]              NVARCHAR(255)             NULL,
    [cost_centre]                               NVARCHAR(255)             NULL,
    [order_number]                              NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[transacts]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[transacts];

CREATE TABLE [offshore_srm].[transacts]
(
    [transaction_id]                            NVARCHAR(255)             NOT NULL,
    [document_type]                             NVARCHAR(255)             NULL,
    [supplier_code]                             NVARCHAR(255)             NULL,
    [purchasing_organisation]                   NVARCHAR(255)             NULL,
    [purchasing_group]                          NVARCHAR(255)             NULL,
    [currency]                                  NVARCHAR(255)             NULL,
    [document_date]                             DATE                      NULL,
    [created_by]                                NVARCHAR(255)             NULL,
    [created_date]                              DATE                      NULL,
    [quotation_deadline_date]                   DATE                      NULL,
    [binding_period_end_date]                   DATE                      NULL,
    [our_reference]                             NVARCHAR(255)             NULL,
    [deletion_indicator]                        NVARCHAR(255)             NULL,
    [release_status]                            NVARCHAR(255)             NULL,
    [transaction_item_number]                   NVARCHAR(255)             NULL,
    [material_code]                             NVARCHAR(255)             NULL,
    [item_description]                          NVARCHAR(255)             NULL,
    [order_quantity]                            DECIMAL(18,3)             NULL,
    [unit_of_measure]                           NVARCHAR(255)             NULL,
    [net_price]                                 DECIMAL(18,2)             NULL,
    [net_value]                                 DECIMAL(18,2)             NULL,
    [material_group]                            NVARCHAR(255)             NULL,
    [plant]                                     NVARCHAR(255)             NULL,
    [delivery_date]                             DATE                      NULL,
    [item_category]                             NVARCHAR(255)             NULL,
    [item_deletion_indicator]                   NVARCHAR(255)             NULL,
    [delivery_completed_indicator]              NVARCHAR(255)             NULL,
    [cost_centre]                               NVARCHAR(255)             NULL,
    [order_number]                              NVARCHAR(255)             NULL,
    [load_id]                                   NVARCHAR(100)             NULL,
    [pipeline_run_id]                           NVARCHAR(100)             NULL,
    [source_path]                               NVARCHAR(500)             NULL,
    [loaded_at]                                 DATETIME2                 NULL,
    [updated_at]                                DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([transaction_id]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_transacts]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_transacts];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_transacts]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[transacts]
    WHERE [transaction_id] IN (
        SELECT [transaction_id] FROM [zzSTG_offshore_srm].[transacts]
        WHERE  [transaction_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[transacts]
    (
        [transaction_id],
        [document_type],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [currency],
        [document_date],
        [created_by],
        [created_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        [deletion_indicator],
        [release_status],
        [transaction_item_number],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [item_category],
        [item_deletion_indicator],
        [delivery_completed_indicator],
        [cost_centre],
        [order_number],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [transaction_id],
        [document_type],
        [supplier_code],
        [purchasing_organisation],
        [purchasing_group],
        [currency],
        [document_date],
        [created_by],
        [created_date],
        [quotation_deadline_date],
        [binding_period_end_date],
        [our_reference],
        [deletion_indicator],
        [release_status],
        [transaction_item_number],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [item_category],
        [item_deletion_indicator],
        [delivery_completed_indicator],
        [cost_centre],
        [order_number],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[transacts]
    WHERE [transaction_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[transacts];
END;
GO

-- ============================================================
-- WATERMARK — individual INSERT per table
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_parts_details','offshore_eam','SAP_ECC_EKKO_EKPO','[dbo].[usp_offshore_eam_quotation_requests_parts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_services_details','offshore_eam','SAP_ECC_EKKO_EKPO','[dbo].[usp_offshore_eam_quotation_requests_services_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_details','offshore_eam','SAP_ECC_EKKO_EKPO','[dbo].[usp_offshore_eam_quotation_requests_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('transacts','offshore_srm','SAP_ECC_EKKO_EKPO','[dbo].[usp_offshore_srm_transacts]','1900-01-01','initial',0,NULL,@now);

-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT COUNT(*) AS stg_quotation_requests_p FROM [zzSTG_offshore_eam].[quotation_requests_parts_details];
-- SELECT COUNT(*) AS tgt_quotation_requests_p FROM [offshore_eam].[quotation_requests_parts_details];
-- SELECT COUNT(*) AS stg_quotation_requests_s FROM [zzSTG_offshore_eam].[quotation_requests_services_details];
-- SELECT COUNT(*) AS tgt_quotation_requests_s FROM [offshore_eam].[quotation_requests_services_details];
-- SELECT COUNT(*) AS stg_quotation_requests_d FROM [zzSTG_offshore_eam].[quotation_requests_details];
-- SELECT COUNT(*) AS tgt_quotation_requests_d FROM [offshore_eam].[quotation_requests_details];
-- SELECT COUNT(*) AS stg_transacts FROM [zzSTG_offshore_srm].[transacts];
-- SELECT COUNT(*) AS tgt_transacts FROM [offshore_srm].[transacts];
-- SELECT * FROM [offshore_eam].[watermark] WHERE table_name IN ('quotation_requests_parts_details','quotation_requests_services_details','quotation_requests_details','transacts');