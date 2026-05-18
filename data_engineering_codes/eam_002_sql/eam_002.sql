-- ============================================================
-- ASA: EAM Part 3 — Staging + Target + Stored Procs + Watermark
-- Schema: offshore_eam | zzSTG_offshore_eam
-- ============================================================

-- ============================================================
-- quotation_requests_parts_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_parts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details]
(
    [rfq_number]                              NVARCHAR(20)              NULL,
    [rfq_item_number]                         NVARCHAR(10)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [rfq_quantity]                            DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [net_price]                               DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [delivery_date]                           DATE                      NULL,
    [purchasing_organisation]                 NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_parts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_parts_details];

CREATE TABLE [offshore_eam].[quotation_requests_parts_details]
(
    [rfq_number]                              NVARCHAR(20)              NOT NULL,
    [rfq_item_number]                         NVARCHAR(10)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [rfq_quantity]                            DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [net_price]                               DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [delivery_date]                           DATE                      NULL,
    [purchasing_organisation]                 NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
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
        WHERE [rfq_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_parts_details]
    (
        [rfq_number],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        [purchasing_organisation],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_number],
        [rfq_item_number],
        [material_code],
        [item_description],
        [rfq_quantity],
        [unit_of_measure],
        [net_price],
        [material_group],
        [plant],
        [delivery_date],
        [purchasing_organisation],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_parts_details]
    WHERE [rfq_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_parts_details];
END;
GO

-- ============================================================
-- quotation_requests_services_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[quotation_requests_services_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[quotation_requests_services_details];

CREATE TABLE [zzSTG_offshore_eam].[quotation_requests_services_details]
(
    [rfq_purchase_order_number]               NVARCHAR(20)              NULL,
    [rfq_item_number]                         NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[quotation_requests_services_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[quotation_requests_services_details];

CREATE TABLE [offshore_eam].[quotation_requests_services_details]
(
    [rfq_purchase_order_number]               NVARCHAR(20)              NOT NULL,
    [rfq_item_number]                         NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
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
        WHERE [rfq_purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[quotation_requests_services_details]
    (
        [rfq_purchase_order_number],
        [rfq_item_number],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [rfq_purchase_order_number],
        [rfq_item_number],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[quotation_requests_services_details]
    WHERE [rfq_purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[quotation_requests_services_details];
END;
GO

-- ============================================================
-- r5objects_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[r5objects_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[r5objects_details];

CREATE TABLE [zzSTG_offshore_eam].[r5objects_details]
(
    [equipment_number]                        NVARCHAR(20)              NULL,
    [equipment_category]                      NVARCHAR(10)              NULL,
    [asset_number]                            NVARCHAR(20)              NULL,
    [maintenance_plant]                       NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [installation_date]                       NVARCHAR(20)              NULL,
    [manufacturer]                            NVARCHAR(100)             NULL,
    [serial_number]                           NVARCHAR(50)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [system_status]                           NVARCHAR(10)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [equipment_description]                   NVARCHAR(255)             NULL,
    [functional_location]                     NVARCHAR(50)              NULL,
    [responsible_plant]                       NVARCHAR(10)              NULL,
    [location]                                NVARCHAR(50)              NULL,
    [business_area]                           NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[r5objects_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[r5objects_details];

CREATE TABLE [offshore_eam].[r5objects_details]
(
    [equipment_number]                        NVARCHAR(20)              NOT NULL,
    [equipment_category]                      NVARCHAR(10)              NULL,
    [asset_number]                            NVARCHAR(20)              NULL,
    [maintenance_plant]                       NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [installation_date]                       NVARCHAR(20)              NULL,
    [manufacturer]                            NVARCHAR(100)             NULL,
    [serial_number]                           NVARCHAR(50)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [system_status]                           NVARCHAR(10)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [equipment_description]                   NVARCHAR(255)             NULL,
    [functional_location]                     NVARCHAR(50)              NULL,
    [responsible_plant]                       NVARCHAR(10)              NULL,
    [location]                                NVARCHAR(50)              NULL,
    [business_area]                           NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([equipment_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_r5objects_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_r5objects_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_r5objects_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[r5objects_details]
    WHERE [equipment_number] IN (
        SELECT [equipment_number] FROM [zzSTG_offshore_eam].[r5objects_details]
        WHERE [equipment_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[r5objects_details]
    (
        [equipment_number],
        [equipment_category],
        [asset_number],
        [maintenance_plant],
        [cost_centre],
        [installation_date],
        [manufacturer],
        [serial_number],
        [material_code],
        [system_status],
        [plant],
        [equipment_description],
        [functional_location],
        [responsible_plant],
        [location],
        [business_area],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [equipment_number],
        [equipment_category],
        [asset_number],
        [maintenance_plant],
        [cost_centre],
        [installation_date],
        [manufacturer],
        [serial_number],
        [material_code],
        [system_status],
        [plant],
        [equipment_description],
        [functional_location],
        [responsible_plant],
        [location],
        [business_area],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[r5objects_details]
    WHERE [equipment_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[r5objects_details];
END;
GO

-- ============================================================
-- r5schedgroups_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[r5schedgroups_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[r5schedgroups_details];

CREATE TABLE [zzSTG_offshore_eam].[r5schedgroups_details]
(
    [work_centre_id]                          NVARCHAR(20)              NULL,
    [work_centre_code]                        NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [usage]                                   NVARCHAR(10)              NULL,
    [work_centre_description]                 NVARCHAR(255)             NULL,
    [responsible_person]                      NVARCHAR(100)             NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [activity_type]                           NVARCHAR(20)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[r5schedgroups_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[r5schedgroups_details];

CREATE TABLE [offshore_eam].[r5schedgroups_details]
(
    [work_centre_id]                          NVARCHAR(20)              NOT NULL,
    [work_centre_code]                        NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [usage]                                   NVARCHAR(10)              NULL,
    [work_centre_description]                 NVARCHAR(255)             NULL,
    [responsible_person]                      NVARCHAR(100)             NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [activity_type]                           NVARCHAR(20)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([work_centre_id]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_r5schedgroups_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_r5schedgroups_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_r5schedgroups_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[r5schedgroups_details]
    WHERE [work_centre_id] IN (
        SELECT [work_centre_id] FROM [zzSTG_offshore_eam].[r5schedgroups_details]
        WHERE [work_centre_id] IS NOT NULL);

    INSERT INTO [offshore_eam].[r5schedgroups_details]
    (
        [work_centre_id],
        [work_centre_code],
        [plant],
        [usage],
        [work_centre_description],
        [responsible_person],
        [cost_centre],
        [activity_type],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [work_centre_id],
        [work_centre_code],
        [plant],
        [usage],
        [work_centre_description],
        [responsible_person],
        [cost_centre],
        [activity_type],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[r5schedgroups_details]
    WHERE [work_centre_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[r5schedgroups_details];
END;
GO

-- ============================================================
-- r5events_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[r5events_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[r5events_details];

CREATE TABLE [zzSTG_offshore_eam].[r5events_details]
(
    [work_order_number]                       NVARCHAR(20)              NULL,
    [notification_number]                     NVARCHAR(20)              NULL,
    [order_type]                              NVARCHAR(10)              NULL,
    [order_description]                       NVARCHAR(255)             NULL,
    [maintenance_plant]                       NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [equipment_number]                        NVARCHAR(20)              NULL,
    [created_by]                              NVARCHAR(100)             NULL,
    [creation_date]                           DATE                      NULL,
    [planned_start_date]                      DATE                      NULL,
    [planned_finish_date]                     DATE                      NULL,
    [order_status]                            NVARCHAR(10)              NULL,
    [priority]                                NVARCHAR(10)              NULL,
    [functional_location]                     NVARCHAR(50)              NULL,
    [asset_number]                            NVARCHAR(20)              NULL,
    [pm_order_number]                         NVARCHAR(20)              NULL,
    [notification_type]                       NVARCHAR(10)              NULL,
    [notification_description]                NVARCHAR(255)             NULL,
    [notification_priority]                   NVARCHAR(10)              NULL,
    [required_start_date]                     DATE                      NULL,
    [required_end_date]                       DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[r5events_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[r5events_details];

CREATE TABLE [offshore_eam].[r5events_details]
(
    [work_order_number]                       NVARCHAR(20)              NOT NULL,
    [notification_number]                     NVARCHAR(20)              NULL,
    [order_type]                              NVARCHAR(10)              NULL,
    [order_description]                       NVARCHAR(255)             NULL,
    [maintenance_plant]                       NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [equipment_number]                        NVARCHAR(20)              NULL,
    [created_by]                              NVARCHAR(100)             NULL,
    [creation_date]                           DATE                      NULL,
    [planned_start_date]                      DATE                      NULL,
    [planned_finish_date]                     DATE                      NULL,
    [order_status]                            NVARCHAR(10)              NULL,
    [priority]                                NVARCHAR(10)              NULL,
    [functional_location]                     NVARCHAR(50)              NULL,
    [asset_number]                            NVARCHAR(20)              NULL,
    [pm_order_number]                         NVARCHAR(20)              NULL,
    [notification_type]                       NVARCHAR(10)              NULL,
    [notification_description]                NVARCHAR(255)             NULL,
    [notification_priority]                   NVARCHAR(10)              NULL,
    [required_start_date]                     DATE                      NULL,
    [required_end_date]                       DATE                      NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([work_order_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_r5events_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_r5events_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_r5events_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[r5events_details]
    WHERE [work_order_number] IN (
        SELECT [work_order_number] FROM [zzSTG_offshore_eam].[r5events_details]
        WHERE [work_order_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[r5events_details]
    (
        [work_order_number],
        [notification_number],
        [order_type],
        [order_description],
        [maintenance_plant],
        [cost_centre],
        [equipment_number],
        [created_by],
        [creation_date],
        [planned_start_date],
        [planned_finish_date],
        [order_status],
        [priority],
        [functional_location],
        [asset_number],
        [pm_order_number],
        [notification_type],
        [notification_description],
        [notification_priority],
        [required_start_date],
        [required_end_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [work_order_number],
        [notification_number],
        [order_type],
        [order_description],
        [maintenance_plant],
        [cost_centre],
        [equipment_number],
        [created_by],
        [creation_date],
        [planned_start_date],
        [planned_finish_date],
        [order_status],
        [priority],
        [functional_location],
        [asset_number],
        [pm_order_number],
        [notification_type],
        [notification_description],
        [notification_priority],
        [required_start_date],
        [required_end_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[r5events_details]
    WHERE [work_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[r5events_details];
END;
GO

-- ============================================================
-- requisition_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[requisition_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[requisition_details];

CREATE TABLE [zzSTG_offshore_eam].[requisition_details]
(
    [requisition_number]                      NVARCHAR(20)              NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(100)             NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [release_status]                          NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [purchase_order_reference]                NVARCHAR(20)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[requisition_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[requisition_details];

CREATE TABLE [offshore_eam].[requisition_details]
(
    [requisition_number]                      NVARCHAR(20)              NOT NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(100)             NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [release_status]                          NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [purchase_order_reference]                NVARCHAR(20)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([requisition_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_requisition_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_requisition_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_requisition_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[requisition_details]
    WHERE [requisition_number] IN (
        SELECT [requisition_number] FROM [zzSTG_offshore_eam].[requisition_details]
        WHERE [requisition_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[requisition_details]
    (
        [requisition_number],
        [requisition_item_number],
        [requisition_date],
        [requested_by],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [plant],
        [cost_centre],
        [release_status],
        [estimated_price],
        [purchase_order_reference],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [requisition_number],
        [requisition_item_number],
        [requisition_date],
        [requested_by],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [plant],
        [cost_centre],
        [release_status],
        [estimated_price],
        [purchase_order_reference],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[requisition_details]
    WHERE [requisition_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[requisition_details];
END;
GO

-- ============================================================
-- requisitions_parts_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[requisitions_parts_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[requisitions_parts_details];

CREATE TABLE [zzSTG_offshore_eam].[requisitions_parts_details]
(
    [requisition_number]                      NVARCHAR(20)              NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [requisition_date]                        DATE                      NULL,
    [release_status]                          NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[requisitions_parts_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[requisitions_parts_details];

CREATE TABLE [offshore_eam].[requisitions_parts_details]
(
    [requisition_number]                      NVARCHAR(20)              NOT NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [material_code]                           NVARCHAR(50)              NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [requisition_date]                        DATE                      NULL,
    [release_status]                          NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([requisition_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_requisitions_parts_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_requisitions_parts_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_requisitions_parts_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[requisitions_parts_details]
    WHERE [requisition_number] IN (
        SELECT [requisition_number] FROM [zzSTG_offshore_eam].[requisitions_parts_details]
        WHERE [requisition_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[requisitions_parts_details]
    (
        [requisition_number],
        [requisition_item_number],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [material_group],
        [plant],
        [requisition_date],
        [release_status],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [requisition_number],
        [requisition_item_number],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [material_group],
        [plant],
        [requisition_date],
        [release_status],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[requisitions_parts_details]
    WHERE [requisition_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[requisitions_parts_details];
END;
GO

-- ============================================================
-- requisitions_services_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[requisitions_services_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[requisitions_services_details];

CREATE TABLE [zzSTG_offshore_eam].[requisitions_services_details]
(
    [requisition_number]                      NVARCHAR(20)              NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [service_description]                     NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(100)             NULL,
    [release_status]                          NVARCHAR(10)              NULL,
    [item_category]                           NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[requisitions_services_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[requisitions_services_details];

CREATE TABLE [offshore_eam].[requisitions_services_details]
(
    [requisition_number]                      NVARCHAR(20)              NOT NULL,
    [requisition_item_number]                 NVARCHAR(10)              NULL,
    [service_description]                     NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(10)              NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(100)             NULL,
    [release_status]                          NVARCHAR(10)              NULL,
    [item_category]                           NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([requisition_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_requisitions_services_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_requisitions_services_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_requisitions_services_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[requisitions_services_details]
    WHERE [requisition_number] IN (
        SELECT [requisition_number] FROM [zzSTG_offshore_eam].[requisitions_services_details]
        WHERE [requisition_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[requisitions_services_details]
    (
        [requisition_number],
        [requisition_item_number],
        [service_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [plant],
        [cost_centre],
        [requisition_date],
        [requested_by],
        [release_status],
        [item_category],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [requisition_number],
        [requisition_item_number],
        [service_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [plant],
        [cost_centre],
        [requisition_date],
        [requested_by],
        [release_status],
        [item_category],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[requisitions_services_details]
    WHERE [requisition_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[requisitions_services_details];
END;
GO

-- ============================================================
-- status_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[status_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[status_details];

CREATE TABLE [zzSTG_offshore_eam].[status_details]
(
    [status_code]                             NVARCHAR(20)              NULL,
    [status_profile]                          NVARCHAR(20)              NULL,
    [status_description_short]                NVARCHAR(20)              NULL,
    [status_description]                      NVARCHAR(255)             NULL,
    [status_type]                             NVARCHAR(20)              NULL,
    [source_table]                            NVARCHAR(50)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[status_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[status_details];

CREATE TABLE [offshore_eam].[status_details]
(
    [status_code]                             NVARCHAR(20)              NOT NULL,
    [status_profile]                          NVARCHAR(20)              NULL,
    [status_description_short]                NVARCHAR(20)              NULL,
    [status_description]                      NVARCHAR(255)             NULL,
    [status_type]                             NVARCHAR(20)              NULL,
    [source_table]                            NVARCHAR(50)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_status_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_status_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_status_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[status_details]
    WHERE [status_code] IN (
        SELECT [status_code] FROM [zzSTG_offshore_eam].[status_details]
        WHERE [status_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[status_details]
    (
        [status_code],
        [status_profile],
        [status_description_short],
        [status_description],
        [status_type],
        [source_table],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [status_code],
        [status_profile],
        [status_description_short],
        [status_description],
        [status_type],
        [source_table],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[status_details]
    WHERE [status_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[status_details];
END;
GO

-- ============================================================
-- store_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[store_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[store_details];

CREATE TABLE [zzSTG_offshore_eam].[store_details]
(
    [plant_code]                              NVARCHAR(10)              NULL,
    [storage_location_code]                   NVARCHAR(10)              NULL,
    [storage_location_description]            NVARCHAR(255)             NULL,
    [plant_name]                              NVARCHAR(255)             NULL,
    [plant_address]                           NVARCHAR(255)             NULL,
    [plant_city]                              NVARCHAR(100)             NULL,
    [plant_country]                           NVARCHAR(10)              NULL,
    [company_code]                            NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[store_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[store_details];

CREATE TABLE [offshore_eam].[store_details]
(
    [plant_code]                              NVARCHAR(10)              NULL,
    [storage_location_code]                   NVARCHAR(10)              NOT NULL,
    [storage_location_description]            NVARCHAR(255)             NULL,
    [plant_name]                              NVARCHAR(255)             NULL,
    [plant_address]                           NVARCHAR(255)             NULL,
    [plant_city]                              NVARCHAR(100)             NULL,
    [plant_country]                           NVARCHAR(10)              NULL,
    [company_code]                            NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_store_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_store_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_store_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[store_details]
    WHERE [storage_location_code] IN (
        SELECT [storage_location_code] FROM [zzSTG_offshore_eam].[store_details]
        WHERE [storage_location_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[store_details]
    (
        [plant_code],
        [storage_location_code],
        [storage_location_description],
        [plant_name],
        [plant_address],
        [plant_city],
        [plant_country],
        [company_code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [plant_code],
        [storage_location_code],
        [storage_location_description],
        [plant_name],
        [plant_address],
        [plant_city],
        [plant_country],
        [company_code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[store_details]
    WHERE [storage_location_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[store_details];
END;
GO

-- ============================================================
-- task_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[task_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[task_details];

CREATE TABLE [zzSTG_offshore_eam].[task_details]
(
    [task_list_number]                        NVARCHAR(20)              NULL,
    [operation_node]                          NVARCHAR(20)              NULL,
    [operation_number]                        NVARCHAR(10)              NULL,
    [operation_description]                   NVARCHAR(255)             NULL,
    [work_centre_id]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [normal_duration_hours]                   DECIMAL(18,3)             NULL,
    [duration_unit]                           NVARCHAR(10)              NULL,
    [status]                                  NVARCHAR(10)              NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[task_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[task_details];

CREATE TABLE [offshore_eam].[task_details]
(
    [task_list_number]                        NVARCHAR(20)              NOT NULL,
    [operation_node]                          NVARCHAR(20)              NULL,
    [operation_number]                        NVARCHAR(10)              NULL,
    [operation_description]                   NVARCHAR(255)             NULL,
    [work_centre_id]                          NVARCHAR(20)              NULL,
    [plant]                                   NVARCHAR(10)              NULL,
    [normal_duration_hours]                   DECIMAL(18,3)             NULL,
    [duration_unit]                           NVARCHAR(10)              NULL,
    [status]                                  NVARCHAR(10)              NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([task_list_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_task_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_task_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_task_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[task_details]
    WHERE [task_list_number] IN (
        SELECT [task_list_number] FROM [zzSTG_offshore_eam].[task_details]
        WHERE [task_list_number] IS NOT NULL);

    INSERT INTO [offshore_eam].[task_details]
    (
        [task_list_number],
        [operation_node],
        [operation_number],
        [operation_description],
        [work_centre_id],
        [plant],
        [normal_duration_hours],
        [duration_unit],
        [status],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [task_list_number],
        [operation_node],
        [operation_number],
        [operation_description],
        [work_centre_id],
        [plant],
        [normal_duration_hours],
        [duration_unit],
        [status],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[task_details]
    WHERE [task_list_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[task_details];
END;
GO

-- ============================================================
-- tax_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[tax_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[tax_details];

CREATE TABLE [zzSTG_offshore_eam].[tax_details]
(
    [tax_code]                                NVARCHAR(10)              NULL,
    [tax_procedure]                           NVARCHAR(20)              NULL,
    [tax_type]                                NVARCHAR(10)              NULL,
    [inactive_flag]                           NVARCHAR(5)               NULL,
    [tax_category]                            NVARCHAR(10)              NULL,
    [tax_description]                         NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[tax_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[tax_details];

CREATE TABLE [offshore_eam].[tax_details]
(
    [tax_code]                                NVARCHAR(10)              NOT NULL,
    [tax_procedure]                           NVARCHAR(20)              NULL,
    [tax_type]                                NVARCHAR(10)              NULL,
    [inactive_flag]                           NVARCHAR(5)               NULL,
    [tax_category]                            NVARCHAR(10)              NULL,
    [tax_description]                         NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_tax_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_tax_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_tax_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[tax_details]
    WHERE [tax_code] IN (
        SELECT [tax_code] FROM [zzSTG_offshore_eam].[tax_details]
        WHERE [tax_code] IS NOT NULL);

    INSERT INTO [offshore_eam].[tax_details]
    (
        [tax_code],
        [tax_procedure],
        [tax_type],
        [inactive_flag],
        [tax_category],
        [tax_description],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [tax_code],
        [tax_procedure],
        [tax_type],
        [inactive_flag],
        [tax_category],
        [tax_description],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[tax_details]
    WHERE [tax_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[tax_details];
END;
GO

-- ============================================================
-- user_details
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_eam].[user_details]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_eam].[user_details];

CREATE TABLE [zzSTG_offshore_eam].[user_details]
(
    [username]                                NVARCHAR(100)             NULL,
    [user_type]                               NVARCHAR(10)              NULL,
    [user_class]                              NVARCHAR(10)              NULL,
    [valid_from]                              DATE                      NULL,
    [valid_to]                                DATE                      NULL,
    [last_login_date]                         NVARCHAR(20)              NULL,
    [user_status]                             NVARCHAR(20)              NULL,
    [person_number]                           NVARCHAR(20)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [role_name]                               NVARCHAR(100)             NULL,
    [role_from_date]                          DATE                      NULL,
    [role_to_date]                            DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_eam].[user_details]','U') IS NOT NULL
    DROP TABLE [offshore_eam].[user_details];

CREATE TABLE [offshore_eam].[user_details]
(
    [username]                                NVARCHAR(100)             NOT NULL,
    [user_type]                               NVARCHAR(10)              NULL,
    [user_class]                              NVARCHAR(10)              NULL,
    [valid_from]                              DATE                      NULL,
    [valid_to]                                DATE                      NULL,
    [last_login_date]                         NVARCHAR(20)              NULL,
    [user_status]                             NVARCHAR(20)              NULL,
    [person_number]                           NVARCHAR(20)              NULL,
    [cost_centre]                             NVARCHAR(20)              NULL,
    [role_name]                               NVARCHAR(100)             NULL,
    [role_from_date]                          DATE                      NULL,
    [role_to_date]                            DATE                      NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([username]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_eam_user_details]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_eam_user_details];
GO
CREATE PROCEDURE [dbo].[usp_offshore_eam_user_details]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_eam].[user_details]
    WHERE [username] IN (
        SELECT [username] FROM [zzSTG_offshore_eam].[user_details]
        WHERE [username] IS NOT NULL);

    INSERT INTO [offshore_eam].[user_details]
    (
        [username],
        [user_type],
        [user_class],
        [valid_from],
        [valid_to],
        [last_login_date],
        [user_status],
        [person_number],
        [cost_centre],
        [role_name],
        [role_from_date],
        [role_to_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [username],
        [user_type],
        [user_class],
        [valid_from],
        [valid_to],
        [last_login_date],
        [user_status],
        [person_number],
        [cost_centre],
        [role_name],
        [role_from_date],
        [role_to_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_eam].[user_details]
    WHERE [username] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_eam].[user_details];
END;
GO

-- ============================================================
-- WATERMARK — individual INSERT per table (ASA limitation)
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_parts_details','offshore_eam','SAP_ECC_EKAP','[dbo].[usp_offshore_eam_quotation_requests_parts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_services_details','offshore_eam','SAP_ECC_EKPV','[dbo].[usp_offshore_eam_quotation_requests_services_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('r5objects_details','offshore_eam','SAP_ECC_EQUI+EQKT+ILOA','[dbo].[usp_offshore_eam_r5objects_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('r5schedgroups_details','offshore_eam','SAP_ECC_CRHD+CRCO','[dbo].[usp_offshore_eam_r5schedgroups_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('r5events_details','offshore_eam','SAP_ECC_AUFK+AFIH+QMEL','[dbo].[usp_offshore_eam_r5events_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('requisition_details','offshore_eam','SAP_ECC_EBAN','[dbo].[usp_offshore_eam_requisition_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('requisitions_parts_details','offshore_eam','SAP_ECC_EBAN+EIPO','[dbo].[usp_offshore_eam_requisitions_parts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('requisitions_services_details','offshore_eam','SAP_ECC_EBAN','[dbo].[usp_offshore_eam_requisitions_services_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('status_details','offshore_eam','SAP_ECC_TJ02T','[dbo].[usp_offshore_eam_status_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('store_details','offshore_eam','SAP_ECC_T001L+T001W','[dbo].[usp_offshore_eam_store_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('task_details','offshore_eam','SAP_ECC_PLPO+PLPH+MAPL','[dbo].[usp_offshore_eam_task_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('tax_details','offshore_eam','SAP_ECC_T007A+T007S','[dbo].[usp_offshore_eam_tax_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('user_details','offshore_eam','SAP_ECC_USR02+USR21+AGR_USERS','[dbo].[usp_offshore_eam_user_details]','1900-01-01','initial',0,NULL,@now);

-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT COUNT(*) AS [quotation_requests_parts_details] FROM [offshore_eam].[quotation_requests_parts_details];
-- SELECT COUNT(*) AS [quotation_requests_services_details] FROM [offshore_eam].[quotation_requests_services_details];
-- SELECT COUNT(*) AS [r5objects_details] FROM [offshore_eam].[r5objects_details];
-- SELECT COUNT(*) AS [r5schedgroups_details] FROM [offshore_eam].[r5schedgroups_details];
-- SELECT COUNT(*) AS [r5events_details] FROM [offshore_eam].[r5events_details];
-- SELECT COUNT(*) AS [requisition_details] FROM [offshore_eam].[requisition_details];
-- SELECT COUNT(*) AS [requisitions_parts_details] FROM [offshore_eam].[requisitions_parts_details];
-- SELECT COUNT(*) AS [requisitions_services_details] FROM [offshore_eam].[requisitions_services_details];
-- SELECT COUNT(*) AS [status_details] FROM [offshore_eam].[status_details];
-- SELECT COUNT(*) AS [store_details] FROM [offshore_eam].[store_details];
-- SELECT COUNT(*) AS [task_details] FROM [offshore_eam].[task_details];
-- SELECT COUNT(*) AS [tax_details] FROM [offshore_eam].[tax_details];
-- SELECT COUNT(*) AS [user_details] FROM [offshore_eam].[user_details];
-- SELECT * FROM [offshore_eam].[watermark] WHERE schema_name = 'offshore_eam' ORDER BY table_name;