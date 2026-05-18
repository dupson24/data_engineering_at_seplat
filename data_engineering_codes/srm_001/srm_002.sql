-- ============================================================
-- ASA: SRM Extended Tables — Staging + Target + SPs + Watermark
-- Schema: offshore_srm | zzSTG_offshore_srm
-- 24 tables
-- ============================================================

-- ============================================================
-- actdetails
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[actdetails]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[actdetails];

CREATE TABLE [zzSTG_offshore_srm].[actdetails]
(
    [confirmation_number]                     NVARCHAR(255)             NULL,
    [confirmation_counter]                    NVARCHAR(255)             NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [operation_number]                        NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [work_centre_id]                          NVARCHAR(255)             NULL,
    [actual_start_date]                       NVARCHAR(255)             NULL,
    [actual_end_date]                         NVARCHAR(255)             NULL,
    [confirmed_yield_quantity]                DECIMAL(18,3)             NULL,
    [confirmed_work_quantity]                 DECIMAL(18,3)             NULL,
    [confirmed_scrap_quantity]                DECIMAL(18,3)             NULL,
    [posting_date]                            NVARCHAR(255)             NULL,
    [confirmed_by]                            NVARCHAR(255)             NULL,
    [reversal_indicator]                      NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[actdetails]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[actdetails];

CREATE TABLE [offshore_srm].[actdetails]
(
    [confirmation_number]                     NVARCHAR(255)             NOT NULL,
    [confirmation_counter]                    NVARCHAR(255)             NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [operation_number]                        NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [work_centre_id]                          NVARCHAR(255)             NULL,
    [actual_start_date]                       NVARCHAR(255)             NULL,
    [actual_end_date]                         NVARCHAR(255)             NULL,
    [confirmed_yield_quantity]                DECIMAL(18,3)             NULL,
    [confirmed_work_quantity]                 DECIMAL(18,3)             NULL,
    [confirmed_scrap_quantity]                DECIMAL(18,3)             NULL,
    [posting_date]                            NVARCHAR(255)             NULL,
    [confirmed_by]                            NVARCHAR(255)             NULL,
    [reversal_indicator]                      NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([confirmation_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_actdetails]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_actdetails];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_actdetails]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[actdetails]
    WHERE [confirmation_number] IN (
        SELECT [confirmation_number] FROM [zzSTG_offshore_srm].[actdetails]
        WHERE [confirmation_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[actdetails]
    (
        [confirmation_number],
        [confirmation_counter],
        [work_order_number],
        [operation_number],
        [plant],
        [work_centre_id],
        [actual_start_date],
        [actual_end_date],
        [confirmed_yield_quantity],
        [confirmed_work_quantity],
        [confirmed_scrap_quantity],
        [posting_date],
        [confirmed_by],
        [reversal_indicator],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [confirmation_number],
        [confirmation_counter],
        [work_order_number],
        [operation_number],
        [plant],
        [work_centre_id],
        [actual_start_date],
        [actual_end_date],
        [confirmed_yield_quantity],
        [confirmed_work_quantity],
        [confirmed_scrap_quantity],
        [posting_date],
        [confirmed_by],
        [reversal_indicator],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[actdetails]
    WHERE [confirmation_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[actdetails];
END;
GO

-- ============================================================
-- actlog
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[actlog]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[actlog];

CREATE TABLE [zzSTG_offshore_srm].[actlog]
(
    [confirmation_number]                     NVARCHAR(255)             NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [operation_number]                        NVARCHAR(255)             NULL,
    [activity_date]                           NVARCHAR(255)             NULL,
    [posting_date]                            NVARCHAR(255)             NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [reversal_indicator]                      NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [activity_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[actlog]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[actlog];

CREATE TABLE [offshore_srm].[actlog]
(
    [confirmation_number]                     NVARCHAR(255)             NOT NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [operation_number]                        NVARCHAR(255)             NULL,
    [activity_date]                           NVARCHAR(255)             NULL,
    [posting_date]                            NVARCHAR(255)             NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [reversal_indicator]                      NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [activity_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([confirmation_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_actlog]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_actlog];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_actlog]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[actlog]
    WHERE [confirmation_number] IN (
        SELECT [confirmation_number] FROM [zzSTG_offshore_srm].[actlog]
        WHERE [confirmation_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[actlog]
    (
        [confirmation_number],
        [work_order_number],
        [operation_number],
        [activity_date],
        [posting_date],
        [created_by],
        [reversal_indicator],
        [plant],
        [activity_quantity],
        [unit_of_measure],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [confirmation_number],
        [work_order_number],
        [operation_number],
        [activity_date],
        [posting_date],
        [created_by],
        [reversal_indicator],
        [plant],
        [activity_quantity],
        [unit_of_measure],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[actlog]
    WHERE [confirmation_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[actlog];
END;
GO

-- ============================================================
-- clients
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[clients]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[clients];

CREATE TABLE [zzSTG_offshore_srm].[clients]
(
    [person_number]                           NVARCHAR(255)             NULL,
    [client_code]                             NVARCHAR(255)             NULL,
    [client_name]                             NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [block_indicator]                         NVARCHAR(255)             NULL,
    [contact_first_name]                      NVARCHAR(255)             NULL,
    [contact_last_name]                       NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[clients]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[clients];

CREATE TABLE [offshore_srm].[clients]
(
    [person_number]                           NVARCHAR(255)             NULL,
    [client_code]                             NVARCHAR(255)             NOT NULL,
    [client_name]                             NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [block_indicator]                         NVARCHAR(255)             NULL,
    [contact_first_name]                      NVARCHAR(255)             NULL,
    [contact_last_name]                       NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([client_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_clients]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_clients];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_clients]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[clients]
    WHERE [client_code] IN (
        SELECT [client_code] FROM [zzSTG_offshore_srm].[clients]
        WHERE [client_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[clients]
    (
        [person_number],
        [client_code],
        [client_name],
        [account_group],
        [country],
        [city],
        [street_address],
        [phone],
        [block_indicator],
        [contact_first_name],
        [contact_last_name],
        [gender],
        [language],
        [nationality],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [person_number],
        [client_code],
        [client_name],
        [account_group],
        [country],
        [city],
        [street_address],
        [phone],
        [block_indicator],
        [contact_first_name],
        [contact_last_name],
        [gender],
        [language],
        [nationality],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[clients]
    WHERE [client_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[clients];
END;
GO

-- ============================================================
-- docsup
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[docsup]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[docsup];

CREATE TABLE [zzSTG_offshore_srm].[docsup]
(
    [supplier_code]                           NVARCHAR(255)             NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [address_number]                          NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[docsup]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[docsup];

CREATE TABLE [offshore_srm].[docsup]
(
    [supplier_code]                           NVARCHAR(255)             NOT NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [address_number]                          NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([supplier_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_docsup]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_docsup];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_docsup]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[docsup]
    WHERE [supplier_code] IN (
        SELECT [supplier_code] FROM [zzSTG_offshore_srm].[docsup]
        WHERE [supplier_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[docsup]
    (
        [supplier_code],
        [supplier_name],
        [country],
        [street_address],
        [city],
        [phone],
        [address_number],
        [account_group],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [supplier_code],
        [supplier_name],
        [country],
        [street_address],
        [city],
        [phone],
        [address_number],
        [account_group],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[docsup]
    WHERE [supplier_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[docsup];
END;
GO

-- ============================================================
-- itemcat
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[itemcat]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[itemcat];

CREATE TABLE [zzSTG_offshore_srm].[itemcat]
(
    [material_group_code]                     NVARCHAR(255)             NULL,
    [material_group_description]              NVARCHAR(255)             NULL,
    [material_group_description_long]         NVARCHAR(255)             NULL,
    [material_type]                           NVARCHAR(255)             NULL,
    [base_unit_of_measure]                    NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[itemcat]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[itemcat];

CREATE TABLE [offshore_srm].[itemcat]
(
    [material_group_code]                     NVARCHAR(255)             NOT NULL,
    [material_group_description]              NVARCHAR(255)             NULL,
    [material_group_description_long]         NVARCHAR(255)             NULL,
    [material_type]                           NVARCHAR(255)             NULL,
    [base_unit_of_measure]                    NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_itemcat]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_itemcat];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_itemcat]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[itemcat]
    WHERE [material_group_code] IN (
        SELECT [material_group_code] FROM [zzSTG_offshore_srm].[itemcat]
        WHERE [material_group_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[itemcat]
    (
        [material_group_code],
        [material_group_description],
        [material_group_description_long],
        [material_type],
        [base_unit_of_measure],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_group_code],
        [material_group_description],
        [material_group_description_long],
        [material_type],
        [base_unit_of_measure],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[itemcat]
    WHERE [material_group_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[itemcat];
END;
GO

-- ============================================================
-- items
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[items]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[items];

CREATE TABLE [zzSTG_offshore_srm].[items]
(
    [material_code]                           NVARCHAR(255)             NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [material_type]                           NVARCHAR(255)             NULL,
    [base_unit_of_measure]                    NVARCHAR(255)             NULL,
    [industry_sector]                         NVARCHAR(255)             NULL,
    [gross_weight]                            DECIMAL(18,3)             NULL,
    [weight_unit]                             NVARCHAR(255)             NULL,
    [created_date]                            DATE                      NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [purchasing_group]                        NVARCHAR(255)             NULL,
    [reorder_point]                           DECIMAL(18,3)             NULL,
    [safety_stock]                            DECIMAL(18,3)             NULL,
    [maximum_stock]                           DECIMAL(18,3)             NULL,
    [valuation_area]                          NVARCHAR(255)             NULL,
    [moving_average_price]                    DECIMAL(18,4)             NULL,
    [standard_price]                          DECIMAL(18,4)             NULL,
    [total_stock_quantity]                    DECIMAL(18,3)             NULL,
    [total_stock_value]                       DECIMAL(18,2)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[items]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[items];

CREATE TABLE [offshore_srm].[items]
(
    [material_code]                           NVARCHAR(255)             NOT NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [material_type]                           NVARCHAR(255)             NULL,
    [base_unit_of_measure]                    NVARCHAR(255)             NULL,
    [industry_sector]                         NVARCHAR(255)             NULL,
    [gross_weight]                            DECIMAL(18,3)             NULL,
    [weight_unit]                             NVARCHAR(255)             NULL,
    [created_date]                            DATE                      NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [purchasing_group]                        NVARCHAR(255)             NULL,
    [reorder_point]                           DECIMAL(18,3)             NULL,
    [safety_stock]                            DECIMAL(18,3)             NULL,
    [maximum_stock]                           DECIMAL(18,3)             NULL,
    [valuation_area]                          NVARCHAR(255)             NULL,
    [moving_average_price]                    DECIMAL(18,4)             NULL,
    [standard_price]                          DECIMAL(18,4)             NULL,
    [total_stock_quantity]                    DECIMAL(18,3)             NULL,
    [total_stock_value]                       DECIMAL(18,2)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([material_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_items]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_items];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_items]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[items]
    WHERE [material_code] IN (
        SELECT [material_code] FROM [zzSTG_offshore_srm].[items]
        WHERE [material_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[items]
    (
        [material_code],
        [material_group],
        [material_type],
        [base_unit_of_measure],
        [industry_sector],
        [gross_weight],
        [weight_unit],
        [created_date],
        [plant],
        [purchasing_group],
        [reorder_point],
        [safety_stock],
        [maximum_stock],
        [valuation_area],
        [moving_average_price],
        [standard_price],
        [total_stock_quantity],
        [total_stock_value],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_code],
        [material_group],
        [material_type],
        [base_unit_of_measure],
        [industry_sector],
        [gross_weight],
        [weight_unit],
        [created_date],
        [plant],
        [purchasing_group],
        [reorder_point],
        [safety_stock],
        [maximum_stock],
        [valuation_area],
        [moving_average_price],
        [standard_price],
        [total_stock_quantity],
        [total_stock_value],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[items]
    WHERE [material_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[items];
END;
GO

-- ============================================================
-- locations
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[locations]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[locations];

CREATE TABLE [zzSTG_offshore_srm].[locations]
(
    [location_code]                           NVARCHAR(255)             NULL,
    [location_name]                           NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [company_code]                            NVARCHAR(255)             NULL,
    [functional_location]                     NVARCHAR(255)             NULL,
    [location_description]                    NVARCHAR(255)             NULL,
    [business_area]                           NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[locations]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[locations];

CREATE TABLE [offshore_srm].[locations]
(
    [location_code]                           NVARCHAR(255)             NOT NULL,
    [location_name]                           NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [company_code]                            NVARCHAR(255)             NULL,
    [functional_location]                     NVARCHAR(255)             NULL,
    [location_description]                    NVARCHAR(255)             NULL,
    [business_area]                           NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_locations]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_locations];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_locations]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[locations]
    WHERE [location_code] IN (
        SELECT [location_code] FROM [zzSTG_offshore_srm].[locations]
        WHERE [location_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[locations]
    (
        [location_code],
        [location_name],
        [street_address],
        [city],
        [country],
        [company_code],
        [functional_location],
        [location_description],
        [business_area],
        [cost_centre],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [location_code],
        [location_name],
        [street_address],
        [city],
        [country],
        [company_code],
        [functional_location],
        [location_description],
        [business_area],
        [cost_centre],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[locations]
    WHERE [location_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[locations];
END;
GO

-- ============================================================
-- nations
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[nations]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[nations];

CREATE TABLE [zzSTG_offshore_srm].[nations]
(
    [country_code]                            NVARCHAR(255)             NULL,
    [eu_member_flag]                          NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [country_name]                            NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[nations]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[nations];

CREATE TABLE [offshore_srm].[nations]
(
    [country_code]                            NVARCHAR(255)             NOT NULL,
    [eu_member_flag]                          NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [country_name]                            NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_nations]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_nations];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_nations]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[nations]
    WHERE [country_code] IN (
        SELECT [country_code] FROM [zzSTG_offshore_srm].[nations]
        WHERE [country_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[nations]
    (
        [country_code],
        [eu_member_flag],
        [currency],
        [country_name],
        [nationality],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [country_code],
        [eu_member_flag],
        [currency],
        [country_name],
        [nationality],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[nations]
    WHERE [country_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[nations];
END;
GO

-- ============================================================
-- newdepts
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[newdepts]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[newdepts];

CREATE TABLE [zzSTG_offshore_srm].[newdepts]
(
    [org_unit_id]                             NVARCHAR(255)             NULL,
    [org_unit_short_name]                     NVARCHAR(255)             NULL,
    [org_unit_description]                    NVARCHAR(255)             NULL,
    [valid_from]                              NVARCHAR(255)             NULL,
    [valid_to]                                NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[newdepts]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[newdepts];

CREATE TABLE [offshore_srm].[newdepts]
(
    [org_unit_id]                             NVARCHAR(255)             NOT NULL,
    [org_unit_short_name]                     NVARCHAR(255)             NULL,
    [org_unit_description]                    NVARCHAR(255)             NULL,
    [valid_from]                              NVARCHAR(255)             NULL,
    [valid_to]                                NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([org_unit_id]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_newdepts]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_newdepts];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_newdepts]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[newdepts]
    WHERE [org_unit_id] IN (
        SELECT [org_unit_id] FROM [zzSTG_offshore_srm].[newdepts]
        WHERE [org_unit_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[newdepts]
    (
        [org_unit_id],
        [org_unit_short_name],
        [org_unit_description],
        [valid_from],
        [valid_to],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [org_unit_id],
        [org_unit_short_name],
        [org_unit_description],
        [valid_from],
        [valid_to],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[newdepts]
    WHERE [org_unit_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[newdepts];
END;
GO

-- ============================================================
-- newstock
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[newstock]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[newstock];

CREATE TABLE [zzSTG_offshore_srm].[newstock]
(
    [material_document_number]                NVARCHAR(255)             NULL,
    [material_document_year]                  NVARCHAR(255)             NULL,
    [document_item]                           NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [storage_location]                        NVARCHAR(255)             NULL,
    [movement_type]                           NVARCHAR(255)             NULL,
    [quantity]                                DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [amount_local_currency]                   DECIMAL(18,2)             NULL,
    [purchase_order_number]                   NVARCHAR(255)             NULL,
    [supplier_code]                           NVARCHAR(255)             NULL,
    [posting_date]                            DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[newstock]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[newstock];

CREATE TABLE [offshore_srm].[newstock]
(
    [material_document_number]                NVARCHAR(255)             NOT NULL,
    [material_document_year]                  NVARCHAR(255)             NULL,
    [document_item]                           NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [storage_location]                        NVARCHAR(255)             NULL,
    [movement_type]                           NVARCHAR(255)             NULL,
    [quantity]                                DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [amount_local_currency]                   DECIMAL(18,2)             NULL,
    [purchase_order_number]                   NVARCHAR(255)             NULL,
    [supplier_code]                           NVARCHAR(255)             NULL,
    [posting_date]                            DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([material_document_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_newstock]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_newstock];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_newstock]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[newstock]
    WHERE [material_document_number] IN (
        SELECT [material_document_number] FROM [zzSTG_offshore_srm].[newstock]
        WHERE [material_document_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[newstock]
    (
        [material_document_number],
        [material_document_year],
        [document_item],
        [material_code],
        [plant],
        [storage_location],
        [movement_type],
        [quantity],
        [unit_of_measure],
        [amount_local_currency],
        [purchase_order_number],
        [supplier_code],
        [posting_date],
        [created_by],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [material_document_number],
        [material_document_year],
        [document_item],
        [material_code],
        [plant],
        [storage_location],
        [movement_type],
        [quantity],
        [unit_of_measure],
        [amount_local_currency],
        [purchase_order_number],
        [supplier_code],
        [posting_date],
        [created_by],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[newstock]
    WHERE [material_document_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[newstock];
END;
GO

-- ============================================================
-- pendingpos
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[pendingpos]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[pendingpos];

CREATE TABLE [zzSTG_offshore_srm].[pendingpos]
(
    [purchase_order_number]                   NVARCHAR(255)             NULL,
    [po_item]                                 NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [order_quantity]                          DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [net_price]                               DECIMAL(18,2)             NULL,
    [net_value]                               DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [delivery_date]                           DATE                      NULL,
    [supplier_code]                           NVARCHAR(255)             NULL,
    [purchasing_org]                          NVARCHAR(255)             NULL,
    [purchasing_group]                        NVARCHAR(255)             NULL,
    [po_type]                                 NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [po_date]                                 DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[pendingpos]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[pendingpos];

CREATE TABLE [offshore_srm].[pendingpos]
(
    [purchase_order_number]                   NVARCHAR(255)             NOT NULL,
    [po_item]                                 NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [order_quantity]                          DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [net_price]                               DECIMAL(18,2)             NULL,
    [net_value]                               DECIMAL(18,2)             NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [delivery_date]                           DATE                      NULL,
    [supplier_code]                           NVARCHAR(255)             NULL,
    [purchasing_org]                          NVARCHAR(255)             NULL,
    [purchasing_group]                        NVARCHAR(255)             NULL,
    [po_type]                                 NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [po_date]                                 DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([purchase_order_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_pendingpos]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_pendingpos];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_pendingpos]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[pendingpos]
    WHERE [purchase_order_number] IN (
        SELECT [purchase_order_number] FROM [zzSTG_offshore_srm].[pendingpos]
        WHERE [purchase_order_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[pendingpos]
    (
        [purchase_order_number],
        [po_item],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [supplier_code],
        [purchasing_org],
        [purchasing_group],
        [po_type],
        [currency],
        [po_date],
        [created_by],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [purchase_order_number],
        [po_item],
        [material_code],
        [item_description],
        [order_quantity],
        [unit_of_measure],
        [net_price],
        [net_value],
        [material_group],
        [plant],
        [delivery_date],
        [supplier_code],
        [purchasing_org],
        [purchasing_group],
        [po_type],
        [currency],
        [po_date],
        [created_by],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[pendingpos]
    WHERE [purchase_order_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[pendingpos];
END;
GO

-- ============================================================
-- pendingrequests
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[pendingrequests]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[pendingrequests];

CREATE TABLE [zzSTG_offshore_srm].[pendingrequests]
(
    [requisition_number]                      NVARCHAR(255)             NULL,
    [pr_item]                                 NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(255)             NULL,
    [release_status]                          NVARCHAR(255)             NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [purchase_order_reference]                NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[pendingrequests]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[pendingrequests];

CREATE TABLE [offshore_srm].[pendingrequests]
(
    [requisition_number]                      NVARCHAR(255)             NOT NULL,
    [pr_item]                                 NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [requested_quantity]                      DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [estimated_price]                         DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [requisition_date]                        DATE                      NULL,
    [requested_by]                            NVARCHAR(255)             NULL,
    [release_status]                          NVARCHAR(255)             NULL,
    [material_group]                          NVARCHAR(255)             NULL,
    [purchase_order_reference]                NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([requisition_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_pendingrequests]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_pendingrequests];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_pendingrequests]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[pendingrequests]
    WHERE [requisition_number] IN (
        SELECT [requisition_number] FROM [zzSTG_offshore_srm].[pendingrequests]
        WHERE [requisition_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[pendingrequests]
    (
        [requisition_number],
        [pr_item],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [plant],
        [cost_centre],
        [requisition_date],
        [requested_by],
        [release_status],
        [material_group],
        [purchase_order_reference],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [requisition_number],
        [pr_item],
        [material_code],
        [item_description],
        [requested_quantity],
        [unit_of_measure],
        [estimated_price],
        [plant],
        [cost_centre],
        [requisition_date],
        [requested_by],
        [release_status],
        [material_group],
        [purchase_order_reference],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[pendingrequests]
    WHERE [requisition_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[pendingrequests];
END;
GO

-- ============================================================
-- settings
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[settings]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[settings];

CREATE TABLE [zzSTG_offshore_srm].[settings]
(
    [company_code]                            NVARCHAR(255)             NULL,
    [company_name]                            NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL,
    [fiscal_year_variant]                     NVARCHAR(255)             NULL,
    [chart_of_accounts]                       NVARCHAR(255)             NULL,
    [controlling_area]                        NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[settings]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[settings];

CREATE TABLE [offshore_srm].[settings]
(
    [company_code]                            NVARCHAR(255)             NOT NULL,
    [company_name]                            NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL,
    [fiscal_year_variant]                     NVARCHAR(255)             NULL,
    [chart_of_accounts]                       NVARCHAR(255)             NULL,
    [controlling_area]                        NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_settings]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_settings];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_settings]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[settings]
    WHERE [company_code] IN (
        SELECT [company_code] FROM [zzSTG_offshore_srm].[settings]
        WHERE [company_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[settings]
    (
        [company_code],
        [company_name],
        [currency],
        [country],
        [language],
        [fiscal_year_variant],
        [chart_of_accounts],
        [controlling_area],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [company_code],
        [company_name],
        [currency],
        [country],
        [language],
        [fiscal_year_variant],
        [chart_of_accounts],
        [controlling_area],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[settings]
    WHERE [company_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[settings];
END;
GO

-- ============================================================
-- stowners
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[stowners]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[stowners];

CREATE TABLE [zzSTG_offshore_srm].[stowners]
(
    [employee_code]                           NVARCHAR(255)             NULL,
    [full_name]                               NVARCHAR(255)             NULL,
    [job_title]                               NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [org_unit]                                NVARCHAR(255)             NULL,
    [location]                                NVARCHAR(255)             NULL,
    [hire_date]                               DATE                      NULL,
    [birth_date]                              DATE                      NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [status]                                  NVARCHAR(255)             NULL,
    [username]                                NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[stowners]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[stowners];

CREATE TABLE [offshore_srm].[stowners]
(
    [employee_code]                           NVARCHAR(255)             NOT NULL,
    [full_name]                               NVARCHAR(255)             NULL,
    [job_title]                               NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [org_unit]                                NVARCHAR(255)             NULL,
    [location]                                NVARCHAR(255)             NULL,
    [hire_date]                               DATE                      NULL,
    [birth_date]                              DATE                      NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [status]                                  NVARCHAR(255)             NULL,
    [username]                                NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([employee_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_stowners]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_stowners];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_stowners]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[stowners]
    WHERE [employee_code] IN (
        SELECT [employee_code] FROM [zzSTG_offshore_srm].[stowners]
        WHERE [employee_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[stowners]
    (
        [employee_code],
        [full_name],
        [job_title],
        [cost_centre],
        [org_unit],
        [location],
        [hire_date],
        [birth_date],
        [country],
        [gender],
        [status],
        [username],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [employee_code],
        [full_name],
        [job_title],
        [cost_centre],
        [org_unit],
        [location],
        [hire_date],
        [birth_date],
        [country],
        [gender],
        [status],
        [username],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[stowners]
    WHERE [employee_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[stowners];
END;
GO

-- ============================================================
-- stowner2
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[stowner2]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[stowner2];

CREATE TABLE [zzSTG_offshore_srm].[stowner2]
(
    [employee_code]                           NVARCHAR(255)             NULL,
    [first_name]                              NVARCHAR(255)             NULL,
    [last_name]                               NVARCHAR(255)             NULL,
    [birth_date]                              DATE                      NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [position]                                NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [org_unit]                                NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [hire_date]                               DATE                      NULL,
    [employment_status]                       NVARCHAR(255)             NULL,
    [sap_user_id]                             NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [address_country]                         NVARCHAR(255)             NULL,
    [postal_code]                             NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[stowner2]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[stowner2];

CREATE TABLE [offshore_srm].[stowner2]
(
    [employee_code]                           NVARCHAR(255)             NOT NULL,
    [first_name]                              NVARCHAR(255)             NULL,
    [last_name]                               NVARCHAR(255)             NULL,
    [birth_date]                              DATE                      NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [position]                                NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [org_unit]                                NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [hire_date]                               DATE                      NULL,
    [employment_status]                       NVARCHAR(255)             NULL,
    [sap_user_id]                             NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [address_country]                         NVARCHAR(255)             NULL,
    [postal_code]                             NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([employee_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_stowner2]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_stowner2];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_stowner2]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[stowner2]
    WHERE [employee_code] IN (
        SELECT [employee_code] FROM [zzSTG_offshore_srm].[stowner2]
        WHERE [employee_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[stowner2]
    (
        [employee_code],
        [first_name],
        [last_name],
        [birth_date],
        [country],
        [gender],
        [position],
        [cost_centre],
        [org_unit],
        [plant],
        [hire_date],
        [employment_status],
        [sap_user_id],
        [street_address],
        [city],
        [address_country],
        [postal_code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [employee_code],
        [first_name],
        [last_name],
        [birth_date],
        [country],
        [gender],
        [position],
        [cost_centre],
        [org_unit],
        [plant],
        [hire_date],
        [employment_status],
        [sap_user_id],
        [street_address],
        [city],
        [address_country],
        [postal_code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[stowner2]
    WHERE [employee_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[stowner2];
END;
GO

-- ============================================================
-- vendacct
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendacct]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendacct];

CREATE TABLE [zzSTG_offshore_srm].[vendacct]
(
    [vendor_code]                             NVARCHAR(255)             NULL,
    [company_code]                            NVARCHAR(255)             NULL,
    [reconciliation_account]                  NVARCHAR(255)             NULL,
    [payment_terms]                           NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [payment_methods]                         NVARCHAR(255)             NULL,
    [block_payment_flag]                      NVARCHAR(255)             NULL,
    [bank_sort_code]                          NVARCHAR(255)             NULL,
    [bank_account_number]                     NVARCHAR(255)             NULL,
    [bank_account_type]                       NVARCHAR(255)             NULL,
    [bank_country]                            NVARCHAR(255)             NULL,
    [partner_bank_type]                       NVARCHAR(255)             NULL,
    [account_holder_name]                     NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendacct]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendacct];

CREATE TABLE [offshore_srm].[vendacct]
(
    [vendor_code]                             NVARCHAR(255)             NOT NULL,
    [company_code]                            NVARCHAR(255)             NULL,
    [reconciliation_account]                  NVARCHAR(255)             NULL,
    [payment_terms]                           NVARCHAR(255)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [payment_methods]                         NVARCHAR(255)             NULL,
    [block_payment_flag]                      NVARCHAR(255)             NULL,
    [bank_sort_code]                          NVARCHAR(255)             NULL,
    [bank_account_number]                     NVARCHAR(255)             NULL,
    [bank_account_type]                       NVARCHAR(255)             NULL,
    [bank_country]                            NVARCHAR(255)             NULL,
    [partner_bank_type]                       NVARCHAR(255)             NULL,
    [account_holder_name]                     NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([vendor_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendacct]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendacct];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendacct]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendacct]
    WHERE [vendor_code] IN (
        SELECT [vendor_code] FROM [zzSTG_offshore_srm].[vendacct]
        WHERE [vendor_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendacct]
    (
        [vendor_code],
        [company_code],
        [reconciliation_account],
        [payment_terms],
        [currency],
        [payment_methods],
        [block_payment_flag],
        [bank_sort_code],
        [bank_account_number],
        [bank_account_type],
        [bank_country],
        [partner_bank_type],
        [account_holder_name],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [vendor_code],
        [company_code],
        [reconciliation_account],
        [payment_terms],
        [currency],
        [payment_methods],
        [block_payment_flag],
        [bank_sort_code],
        [bank_account_number],
        [bank_account_type],
        [bank_country],
        [partner_bank_type],
        [account_holder_name],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendacct]
    WHERE [vendor_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendacct];
END;
GO

-- ============================================================
-- vendapps
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendapps]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendapps];

CREATE TABLE [zzSTG_offshore_srm].[vendapps]
(
    [workflow_id]                             NVARCHAR(255)             NULL,
    [WI_TYPE]                                 NVARCHAR(255)             NULL,
    [WI_CREATOR]                              NVARCHAR(255)             NULL,
    [WI_TEXT]                                 NVARCHAR(255)             NULL,
    [WI_STAT]                                 NVARCHAR(255)             NULL,
    [WI_CD]                                   NVARCHAR(255)             NULL,
    [WI_CT]                                   NVARCHAR(255)             NULL,
    [WI_AED]                                  NVARCHAR(255)             NULL,
    [WI_AAGENT]                               NVARCHAR(255)             NULL,
    [WI_CRUSER]                               NVARCHAR(255)             NULL,
    [WI_RH_TASK]                              NVARCHAR(255)             NULL,
    [WI_PRIO]                                 NVARCHAR(255)             NULL,
    [TOP_WI_ID]                               NVARCHAR(255)             NULL,
    [WF_TYPE]                                 NVARCHAR(255)             NULL,
    [PROCCAT]                                 NVARCHAR(255)             NULL,
    [CREA_TMP]                                DECIMAL(21,7)             NULL,
    [EXEC_TIME]                               INT                       NULL,
    [NOTE_COUNT]                              INT                       NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendapps]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendapps];

CREATE TABLE [offshore_srm].[vendapps]
(
    [workflow_id]                             NVARCHAR(255)             NOT NULL,
    [WI_TYPE]                                 NVARCHAR(255)             NULL,
    [WI_CREATOR]                              NVARCHAR(255)             NULL,
    [WI_TEXT]                                 NVARCHAR(255)             NULL,
    [WI_STAT]                                 NVARCHAR(255)             NULL,
    [WI_CD]                                   NVARCHAR(255)             NULL,
    [WI_CT]                                   NVARCHAR(255)             NULL,
    [WI_AED]                                  NVARCHAR(255)             NULL,
    [WI_AAGENT]                               NVARCHAR(255)             NULL,
    [WI_CRUSER]                               NVARCHAR(255)             NULL,
    [WI_RH_TASK]                              NVARCHAR(255)             NULL,
    [WI_PRIO]                                 NVARCHAR(255)             NULL,
    [TOP_WI_ID]                               NVARCHAR(255)             NULL,
    [WF_TYPE]                                 NVARCHAR(255)             NULL,
    [PROCCAT]                                 NVARCHAR(255)             NULL,
    [CREA_TMP]                                DECIMAL(21,7)             NULL,
    [EXEC_TIME]                               INT                       NULL,
    [NOTE_COUNT]                              INT                       NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([workflow_id]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendapps]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendapps];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendapps]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendapps]
    WHERE [workflow_id] IN (
        SELECT [workflow_id] FROM [zzSTG_offshore_srm].[vendapps]
        WHERE [workflow_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendapps]
    (
        [workflow_id],
        [WI_TYPE],
        [WI_CREATOR],
        [WI_TEXT],
        [WI_STAT],
        [WI_CD],
        [WI_CT],
        [WI_AED],
        [WI_AAGENT],
        [WI_CRUSER],
        [WI_RH_TASK],
        [WI_PRIO],
        [TOP_WI_ID],
        [WF_TYPE],
        [PROCCAT],
        [CREA_TMP],
        [EXEC_TIME],
        [NOTE_COUNT],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [workflow_id],
        [WI_TYPE],
        [WI_CREATOR],
        [WI_TEXT],
        [WI_STAT],
        [WI_CD],
        [WI_CT],
        [WI_AED],
        [WI_AAGENT],
        [WI_CRUSER],
        [WI_RH_TASK],
        [WI_PRIO],
        [TOP_WI_ID],
        [WF_TYPE],
        [PROCCAT],
        [CREA_TMP],
        [EXEC_TIME],
        [NOTE_COUNT],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendapps]
    WHERE [workflow_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendapps];
END;
GO

-- ============================================================
-- vendcat
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendcat]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendcat];

CREATE TABLE [zzSTG_offshore_srm].[vendcat]
(
    [vendor_category_code]                    NVARCHAR(255)             NULL,
    [FAUSA]                                   NVARCHAR(255)             NULL,
    [FAUSF]                                   NVARCHAR(255)             NULL,
    [FAUSM]                                   NVARCHAR(255)             NULL,
    [NUMKR]                                   NVARCHAR(255)             NULL,
    [XCPDS]                                   NVARCHAR(255)             NULL,
    [FAUS1]                                   NVARCHAR(255)             NULL,
    [FAUSW]                                   NVARCHAR(255)             NULL,
    [FAUST]                                   NVARCHAR(255)             NULL,
    [LTSNA]                                   NVARCHAR(255)             NULL,
    [WERKR]                                   NVARCHAR(255)             NULL,
    [PARGE]                                   NVARCHAR(255)             NULL,
    [PARGT]                                   NVARCHAR(255)             NULL,
    [PARGW]                                   NVARCHAR(255)             NULL,
    [DURAS]                                   NVARCHAR(255)             NULL,
    [KTOKD]                                   NVARCHAR(255)             NULL,
    [FAUSG]                                   NVARCHAR(255)             NULL,
    [FAUSN]                                   NVARCHAR(255)             NULL,
    [FAUSX]                                   NVARCHAR(255)             NULL,
    [FAUSU]                                   NVARCHAR(255)             NULL,
    [FAUS2]                                   NVARCHAR(255)             NULL,
    [FAUS3]                                   NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendcat]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendcat];

CREATE TABLE [offshore_srm].[vendcat]
(
    [vendor_category_code]                    NVARCHAR(255)             NOT NULL,
    [FAUSA]                                   NVARCHAR(255)             NULL,
    [FAUSF]                                   NVARCHAR(255)             NULL,
    [FAUSM]                                   NVARCHAR(255)             NULL,
    [NUMKR]                                   NVARCHAR(255)             NULL,
    [XCPDS]                                   NVARCHAR(255)             NULL,
    [FAUS1]                                   NVARCHAR(255)             NULL,
    [FAUSW]                                   NVARCHAR(255)             NULL,
    [FAUST]                                   NVARCHAR(255)             NULL,
    [LTSNA]                                   NVARCHAR(255)             NULL,
    [WERKR]                                   NVARCHAR(255)             NULL,
    [PARGE]                                   NVARCHAR(255)             NULL,
    [PARGT]                                   NVARCHAR(255)             NULL,
    [PARGW]                                   NVARCHAR(255)             NULL,
    [DURAS]                                   NVARCHAR(255)             NULL,
    [KTOKD]                                   NVARCHAR(255)             NULL,
    [FAUSG]                                   NVARCHAR(255)             NULL,
    [FAUSN]                                   NVARCHAR(255)             NULL,
    [FAUSX]                                   NVARCHAR(255)             NULL,
    [FAUSU]                                   NVARCHAR(255)             NULL,
    [FAUS2]                                   NVARCHAR(255)             NULL,
    [FAUS3]                                   NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = REPLICATE, CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendcat]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendcat];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendcat]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendcat]
    WHERE [vendor_category_code] IN (
        SELECT [vendor_category_code] FROM [zzSTG_offshore_srm].[vendcat]
        WHERE [vendor_category_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendcat]
    (
        [vendor_category_code],
        [FAUSA],
        [FAUSF],
        [FAUSM],
        [NUMKR],
        [XCPDS],
        [FAUS1],
        [FAUSW],
        [FAUST],
        [LTSNA],
        [WERKR],
        [PARGE],
        [PARGT],
        [PARGW],
        [DURAS],
        [KTOKD],
        [FAUSG],
        [FAUSN],
        [FAUSX],
        [FAUSU],
        [FAUS2],
        [FAUS3],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [vendor_category_code],
        [FAUSA],
        [FAUSF],
        [FAUSM],
        [NUMKR],
        [XCPDS],
        [FAUS1],
        [FAUSW],
        [FAUST],
        [LTSNA],
        [WERKR],
        [PARGE],
        [PARGT],
        [PARGW],
        [DURAS],
        [KTOKD],
        [FAUSG],
        [FAUSN],
        [FAUSX],
        [FAUSU],
        [FAUS2],
        [FAUS3],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendcat]
    WHERE [vendor_category_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendcat];
END;
GO

-- ============================================================
-- vendconts
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendconts]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendconts];

CREATE TABLE [zzSTG_offshore_srm].[vendconts]
(
    [person_number]                           NVARCHAR(255)             NULL,
    [vendor_code]                             NVARCHAR(255)             NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [fax]                                     NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [contact_person]                          NVARCHAR(255)             NULL,
    [contact_first_name]                      NVARCHAR(255)             NULL,
    [contact_last_name]                       NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendconts]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendconts];

CREATE TABLE [offshore_srm].[vendconts]
(
    [person_number]                           NVARCHAR(255)             NULL,
    [vendor_code]                             NVARCHAR(255)             NOT NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [fax]                                     NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [contact_person]                          NVARCHAR(255)             NULL,
    [contact_first_name]                      NVARCHAR(255)             NULL,
    [contact_last_name]                       NVARCHAR(255)             NULL,
    [gender]                                  NVARCHAR(255)             NULL,
    [nationality]                             NVARCHAR(255)             NULL,
    [language]                                NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([vendor_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendconts]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendconts];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendconts]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendconts]
    WHERE [vendor_code] IN (
        SELECT [vendor_code] FROM [zzSTG_offshore_srm].[vendconts]
        WHERE [vendor_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendconts]
    (
        [person_number],
        [vendor_code],
        [supplier_name],
        [phone],
        [fax],
        [country],
        [street_address],
        [city],
        [contact_person],
        [contact_first_name],
        [contact_last_name],
        [gender],
        [nationality],
        [language],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [person_number],
        [vendor_code],
        [supplier_name],
        [phone],
        [fax],
        [country],
        [street_address],
        [city],
        [contact_person],
        [contact_first_name],
        [contact_last_name],
        [gender],
        [nationality],
        [language],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendconts]
    WHERE [vendor_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendconts];
END;
GO

-- ============================================================
-- vendfin
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendfin]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendfin];

CREATE TABLE [zzSTG_offshore_srm].[vendfin]
(
    [vendor_code]                             NVARCHAR(255)             NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [tax_number]                              NVARCHAR(255)             NULL,
    [vat_number]                              NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendfin]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendfin];

CREATE TABLE [offshore_srm].[vendfin]
(
    [vendor_code]                             NVARCHAR(255)             NOT NULL,
    [supplier_name]                           NVARCHAR(255)             NULL,
    [tax_number]                              NVARCHAR(255)             NULL,
    [vat_number]                              NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([vendor_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendfin]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendfin];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendfin]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendfin]
    WHERE [vendor_code] IN (
        SELECT [vendor_code] FROM [zzSTG_offshore_srm].[vendfin]
        WHERE [vendor_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendfin]
    (
        [vendor_code],
        [supplier_name],
        [tax_number],
        [vat_number],
        [country],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [vendor_code],
        [supplier_name],
        [tax_number],
        [vat_number],
        [country],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendfin]
    WHERE [vendor_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendfin];
END;
GO

-- ============================================================
-- vendreq
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[vendreq]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[vendreq];

CREATE TABLE [zzSTG_offshore_srm].[vendreq]
(
    [vendor_code]                             NVARCHAR(255)             NULL,
    [vendor_name]                             NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [tax_number]                              NVARCHAR(255)             NULL,
    [status]                                  NVARCHAR(255)             NULL,
    [created_date]                            DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[vendreq]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[vendreq];

CREATE TABLE [offshore_srm].[vendreq]
(
    [vendor_code]                             NVARCHAR(255)             NOT NULL,
    [vendor_name]                             NVARCHAR(255)             NULL,
    [account_group]                           NVARCHAR(255)             NULL,
    [country]                                 NVARCHAR(255)             NULL,
    [street_address]                          NVARCHAR(255)             NULL,
    [city]                                    NVARCHAR(255)             NULL,
    [phone]                                   NVARCHAR(255)             NULL,
    [tax_number]                              NVARCHAR(255)             NULL,
    [status]                                  NVARCHAR(255)             NULL,
    [created_date]                            DATE                      NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([vendor_code]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_vendreq]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_vendreq];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_vendreq]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[vendreq]
    WHERE [vendor_code] IN (
        SELECT [vendor_code] FROM [zzSTG_offshore_srm].[vendreq]
        WHERE [vendor_code] IS NOT NULL);

    INSERT INTO [offshore_srm].[vendreq]
    (
        [vendor_code],
        [vendor_name],
        [account_group],
        [country],
        [street_address],
        [city],
        [phone],
        [tax_number],
        [status],
        [created_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [vendor_code],
        [vendor_name],
        [account_group],
        [country],
        [street_address],
        [city],
        [phone],
        [tax_number],
        [status],
        [created_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[vendreq]
    WHERE [vendor_code] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[vendreq];
END;
GO

-- ============================================================
-- woitems
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[woitems]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[woitems];

CREATE TABLE [zzSTG_offshore_srm].[woitems]
(
    [reservation_number]                      NVARCHAR(255)             NULL,
    [reservation_item]                        NVARCHAR(255)             NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [material_description]                    NVARCHAR(255)             NULL,
    [required_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [storage_location]                        NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [final_issue_indicator]                   NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [requirement_date]                        DATE                      NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[woitems]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[woitems];

CREATE TABLE [offshore_srm].[woitems]
(
    [reservation_number]                      NVARCHAR(255)             NOT NULL,
    [reservation_item]                        NVARCHAR(255)             NULL,
    [work_order_number]                       NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [material_description]                    NVARCHAR(255)             NULL,
    [required_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [storage_location]                        NVARCHAR(255)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [final_issue_indicator]                   NVARCHAR(255)             NULL,
    [cost_centre]                             NVARCHAR(255)             NULL,
    [requirement_date]                        DATE                      NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([reservation_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_woitems]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_woitems];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_woitems]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[woitems]
    WHERE [reservation_number] IN (
        SELECT [reservation_number] FROM [zzSTG_offshore_srm].[woitems]
        WHERE [reservation_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[woitems]
    (
        [reservation_number],
        [reservation_item],
        [work_order_number],
        [material_code],
        [material_description],
        [required_quantity],
        [unit_of_measure],
        [storage_location],
        [plant],
        [final_issue_indicator],
        [cost_centre],
        [requirement_date],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [reservation_number],
        [reservation_item],
        [work_order_number],
        [material_code],
        [material_description],
        [required_quantity],
        [unit_of_measure],
        [storage_location],
        [plant],
        [final_issue_indicator],
        [cost_centre],
        [requirement_date],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[woitems]
    WHERE [reservation_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[woitems];
END;
GO

-- ============================================================
-- transacts
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[transacts]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[transacts];

CREATE TABLE [zzSTG_offshore_srm].[transacts]
(
    [transaction_id]                          NVARCHAR(255)             NULL,
    [billing_type]                            NVARCHAR(255)             NULL,
    [billing_date]                            DATE                      NULL,
    [sold_to_party]                           NVARCHAR(255)             NULL,
    [net_value]                               DECIMAL(18,2)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [sales_org]                               NVARCHAR(255)             NULL,
    [payment_status]                          NVARCHAR(255)             NULL,
    [billing_item]                            NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [billed_quantity]                         DECIMAL(18,3)             NULL,
    [line_net_value]                          DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [sales_order_number]                      NVARCHAR(255)             NULL,
    [sales_order_type]                        NVARCHAR(255)             NULL,
    [customer_code]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[transacts]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[transacts];

CREATE TABLE [offshore_srm].[transacts]
(
    [transaction_id]                          NVARCHAR(255)             NOT NULL,
    [billing_type]                            NVARCHAR(255)             NULL,
    [billing_date]                            DATE                      NULL,
    [sold_to_party]                           NVARCHAR(255)             NULL,
    [net_value]                               DECIMAL(18,2)             NULL,
    [currency]                                NVARCHAR(255)             NULL,
    [sales_org]                               NVARCHAR(255)             NULL,
    [payment_status]                          NVARCHAR(255)             NULL,
    [billing_item]                            NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [item_description]                        NVARCHAR(255)             NULL,
    [billed_quantity]                         DECIMAL(18,3)             NULL,
    [line_net_value]                          DECIMAL(18,2)             NULL,
    [plant]                                   NVARCHAR(255)             NULL,
    [sales_order_number]                      NVARCHAR(255)             NULL,
    [sales_order_type]                        NVARCHAR(255)             NULL,
    [customer_code]                           NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
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
        WHERE [transaction_id] IS NOT NULL);

    INSERT INTO [offshore_srm].[transacts]
    (
        [transaction_id],
        [billing_type],
        [billing_date],
        [sold_to_party],
        [net_value],
        [currency],
        [sales_org],
        [payment_status],
        [billing_item],
        [material_code],
        [item_description],
        [billed_quantity],
        [line_net_value],
        [plant],
        [sales_order_number],
        [sales_order_type],
        [customer_code],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [transaction_id],
        [billing_type],
        [billing_date],
        [sold_to_party],
        [net_value],
        [currency],
        [sales_org],
        [payment_status],
        [billing_item],
        [material_code],
        [item_description],
        [billed_quantity],
        [line_net_value],
        [plant],
        [sales_order_number],
        [sales_order_type],
        [customer_code],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[transacts]
    WHERE [transaction_id] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[transacts];
END;
GO

-- ============================================================
-- transfers
-- ============================================================
IF OBJECT_ID('[zzSTG_offshore_srm].[transfers]','U') IS NOT NULL
    DROP TABLE [zzSTG_offshore_srm].[transfers];

CREATE TABLE [zzSTG_offshore_srm].[transfers]
(
    [transfer_document_number]                NVARCHAR(255)             NULL,
    [document_year]                           NVARCHAR(255)             NULL,
    [document_item]                           NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [from_plant]                              NVARCHAR(255)             NULL,
    [from_storage_location]                   NVARCHAR(255)             NULL,
    [to_plant]                                NVARCHAR(255)             NULL,
    [to_storage_location]                     NVARCHAR(255)             NULL,
    [movement_type]                           NVARCHAR(255)             NULL,
    [transfer_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [transfer_value]                          DECIMAL(18,2)             NULL,
    [posting_date]                            DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [document_type]                           NVARCHAR(255)             NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);

IF OBJECT_ID('[offshore_srm].[transfers]','U') IS NOT NULL
    DROP TABLE [offshore_srm].[transfers];

CREATE TABLE [offshore_srm].[transfers]
(
    [transfer_document_number]                NVARCHAR(255)             NOT NULL,
    [document_year]                           NVARCHAR(255)             NULL,
    [document_item]                           NVARCHAR(255)             NULL,
    [material_code]                           NVARCHAR(255)             NULL,
    [from_plant]                              NVARCHAR(255)             NULL,
    [from_storage_location]                   NVARCHAR(255)             NULL,
    [to_plant]                                NVARCHAR(255)             NULL,
    [to_storage_location]                     NVARCHAR(255)             NULL,
    [movement_type]                           NVARCHAR(255)             NULL,
    [transfer_quantity]                       DECIMAL(18,3)             NULL,
    [unit_of_measure]                         NVARCHAR(255)             NULL,
    [transfer_value]                          DECIMAL(18,2)             NULL,
    [posting_date]                            DATE                      NULL,
    [created_by]                              NVARCHAR(255)             NULL,
    [document_type]                           NVARCHAR(255)             NULL,
    [load_id]                                 NVARCHAR(100)             NULL,
    [pipeline_run_id]                         NVARCHAR(100)             NULL,
    [source_path]                             NVARCHAR(500)             NULL,
    [loaded_at]                               DATETIME2                 NULL,
    [updated_at]                              DATETIME2                 NULL
)
WITH (DISTRIBUTION = HASH([transfer_document_number]), CLUSTERED COLUMNSTORE INDEX);

IF OBJECT_ID('[dbo].[usp_offshore_srm_transfers]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_offshore_srm_transfers];
GO
CREATE PROCEDURE [dbo].[usp_offshore_srm_transfers]
    @load_id            NVARCHAR(100),
    @pipeline_run_id    NVARCHAR(100),
    @source_path        NVARCHAR(500)
AS
BEGIN
    DELETE [offshore_srm].[transfers]
    WHERE [transfer_document_number] IN (
        SELECT [transfer_document_number] FROM [zzSTG_offshore_srm].[transfers]
        WHERE [transfer_document_number] IS NOT NULL);

    INSERT INTO [offshore_srm].[transfers]
    (
        [transfer_document_number],
        [document_year],
        [document_item],
        [material_code],
        [from_plant],
        [from_storage_location],
        [to_plant],
        [to_storage_location],
        [movement_type],
        [transfer_quantity],
        [unit_of_measure],
        [transfer_value],
        [posting_date],
        [created_by],
        [document_type],
        [load_id],[pipeline_run_id],[source_path],[loaded_at],[updated_at]
    )
    SELECT
        [transfer_document_number],
        [document_year],
        [document_item],
        [material_code],
        [from_plant],
        [from_storage_location],
        [to_plant],
        [to_storage_location],
        [movement_type],
        [transfer_quantity],
        [unit_of_measure],
        [transfer_value],
        [posting_date],
        [created_by],
        [document_type],
        @load_id,@pipeline_run_id,@source_path,GETDATE(),GETDATE()
    FROM [zzSTG_offshore_srm].[transfers]
    WHERE [transfer_document_number] IS NOT NULL;

    TRUNCATE TABLE [zzSTG_offshore_srm].[transfers];
END;
GO

-- ============================================================
-- WATERMARK — one INSERT per table (ASA limitation)
-- ============================================================
DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('actdetails','offshore_srm','SAP_ECC_AFRU','[dbo].[usp_offshore_srm_actdetails]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('actlog','offshore_srm','SAP_ECC_AFRU','[dbo].[usp_offshore_srm_actlog]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('clients','offshore_srm','SAP_ECC_KNA1_ADRP','[dbo].[usp_offshore_srm_clients]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('docsup','offshore_srm','SAP_ECC_LFA1_CVP_SD_ADRNR','[dbo].[usp_offshore_srm_docsup]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('itemcat','offshore_srm','SAP_ECC_T023_MARA','[dbo].[usp_offshore_srm_itemcat]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('items','offshore_srm','SAP_ECC_MARA_MARC_MBEW','[dbo].[usp_offshore_srm_items]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('locations','offshore_srm','SAP_ECC_T001W_ILOA','[dbo].[usp_offshore_srm_locations]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('nations','offshore_srm','SAP_ECC_T005_T005T','[dbo].[usp_offshore_srm_nations]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('newdepts','offshore_srm','SAP_ECC_HRP1000_CSKS','[dbo].[usp_offshore_srm_newdepts]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('newstock','offshore_srm','SAP_ECC_MKPF_MSEG','[dbo].[usp_offshore_srm_newstock]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('pendingpos','offshore_srm','SAP_ECC_EKKO_EKPO','[dbo].[usp_offshore_srm_pendingpos]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('pendingrequests','offshore_srm','SAP_ECC_EBAN','[dbo].[usp_offshore_srm_pendingrequests]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('settings','offshore_srm','SAP_ECC_T001','[dbo].[usp_offshore_srm_settings]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('stowners','offshore_srm','SAP_ECC_PA0001_PA0002','[dbo].[usp_offshore_srm_stowners]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('stowner2','offshore_srm','SAP_ECC_PA0001_PA0002_PA0006','[dbo].[usp_offshore_srm_stowner2]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendacct','offshore_srm','SAP_ECC_LFB1_LFBK','[dbo].[usp_offshore_srm_vendacct]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendapps','offshore_srm','SAP_ECC_SWWWIHEAD','[dbo].[usp_offshore_srm_vendapps]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendcat','offshore_srm','SAP_ECC_CRMKTOKK_T077K','[dbo].[usp_offshore_srm_vendcat]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendconts','offshore_srm','SAP_ECC_LFA1_ADRP','[dbo].[usp_offshore_srm_vendconts]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendfin','offshore_srm','SAP_ECC_LFA1_BSAK','[dbo].[usp_offshore_srm_vendfin]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('vendreq','offshore_srm','SAP_ECC_LFA1','[dbo].[usp_offshore_srm_vendreq]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('woitems','offshore_srm','SAP_ECC_RESB','[dbo].[usp_offshore_srm_woitems]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('transacts','offshore_srm','SAP_ECC_VBRK_VBRP_VBAK','[dbo].[usp_offshore_srm_transacts]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_srm].[watermark]
    ([table_name],[schema_name],[source_system],[stored_procedure],
     [last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('transfers','offshore_srm','SAP_ECC_MKPF_MSEG','[dbo].[usp_offshore_srm_transfers]','1900-01-01','initial',0,NULL,@now);

-- ============================================================
-- VALIDATION
-- ============================================================
-- SELECT COUNT(*) AS [actdetails] FROM [offshore_srm].[actdetails];
-- SELECT COUNT(*) AS [actlog] FROM [offshore_srm].[actlog];
-- SELECT COUNT(*) AS [clients] FROM [offshore_srm].[clients];
-- SELECT COUNT(*) AS [docsup] FROM [offshore_srm].[docsup];
-- SELECT COUNT(*) AS [itemcat] FROM [offshore_srm].[itemcat];
-- SELECT COUNT(*) AS [items] FROM [offshore_srm].[items];
-- SELECT COUNT(*) AS [locations] FROM [offshore_srm].[locations];
-- SELECT COUNT(*) AS [nations] FROM [offshore_srm].[nations];
-- SELECT COUNT(*) AS [newdepts] FROM [offshore_srm].[newdepts];
-- SELECT COUNT(*) AS [newstock] FROM [offshore_srm].[newstock];
-- SELECT COUNT(*) AS [pendingpos] FROM [offshore_srm].[pendingpos];
-- SELECT COUNT(*) AS [pendingrequests] FROM [offshore_srm].[pendingrequests];
-- SELECT COUNT(*) AS [settings] FROM [offshore_srm].[settings];
-- SELECT COUNT(*) AS [stowners] FROM [offshore_srm].[stowners];
-- SELECT COUNT(*) AS [stowner2] FROM [offshore_srm].[stowner2];
-- SELECT COUNT(*) AS [vendacct] FROM [offshore_srm].[vendacct];
-- SELECT COUNT(*) AS [vendapps] FROM [offshore_srm].[vendapps];
-- SELECT COUNT(*) AS [vendcat] FROM [offshore_srm].[vendcat];
-- SELECT COUNT(*) AS [vendconts] FROM [offshore_srm].[vendconts];
-- SELECT COUNT(*) AS [vendfin] FROM [offshore_srm].[vendfin];
-- SELECT COUNT(*) AS [vendreq] FROM [offshore_srm].[vendreq];
-- SELECT COUNT(*) AS [woitems] FROM [offshore_srm].[woitems];
-- SELECT COUNT(*) AS [transacts] FROM [offshore_srm].[transacts];
-- SELECT COUNT(*) AS [transfers] FROM [offshore_srm].[transfers];
-- SELECT * FROM [offshore_srm].[watermark] WHERE schema_name = 'offshore_srm' ORDER BY table_name;