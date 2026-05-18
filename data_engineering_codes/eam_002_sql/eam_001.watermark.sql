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

