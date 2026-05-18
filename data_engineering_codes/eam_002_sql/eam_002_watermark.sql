DECLARE @now DATETIME2 = GETDATE();

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('date_dimension','offshore_eam','SAP_ECC_SCAL_TT_DATE','[dbo].[usp_offshore_eam_date_dimension]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('invoice_voucher_details','offshore_eam','SAP_ECC_BKPF_BSIK_RBKPB','[dbo].[usp_offshore_eam_invoice_voucher_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('invoice_voucher_line_details','offshore_eam','SAP_ECC_BSEG_RSEG','[dbo].[usp_offshore_eam_invoice_voucher_line_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('organisation_details','offshore_eam','SAP_ECC_T001_TKA01_TBUKRS','[dbo].[usp_offshore_eam_organisation_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('parts_details','offshore_eam','SAP_ECC_MARA_MAKT_MARC_MARM','[dbo].[usp_offshore_eam_parts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('parts_stock_details','offshore_eam','SAP_ECC_MARD_MCHB_MSEG','[dbo].[usp_offshore_eam_parts_stock_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('parts_store_details','offshore_eam','SAP_ECC_MARC_MARA_MBEW','[dbo].[usp_offshore_eam_parts_store_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_details','offshore_eam','SAP_ECC_EKKO','[dbo].[usp_offshore_eam_purchase_order_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_parts_details','offshore_eam','SAP_ECC_EKPO','[dbo].[usp_offshore_eam_purchase_order_parts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_receipt_details','offshore_eam','SAP_ECC_MKPF','[dbo].[usp_offshore_eam_purchase_order_receipt_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_receipt_packingslip_active_lines_details','offshore_eam','SAP_ECC_MSEG','[dbo].[usp_offshore_eam_purchase_order_receipt_packingslip_active_lines_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_receipts_packingslip_details','offshore_eam','SAP_ECC_MSEG_LIKP_LIPS','[dbo].[usp_offshore_eam_purchase_order_receipts_packingslip_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_service_receipts_details','offshore_eam','SAP_ECC_ESLH_ESLL','[dbo].[usp_offshore_eam_purchase_order_service_receipts_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('purchase_order_services_details','offshore_eam','SAP_ECC_EKPO_EKPV','[dbo].[usp_offshore_eam_purchase_order_services_details]','1900-01-01','initial',0,NULL,@now);

INSERT INTO [offshore_eam].[watermark] ([table_name],[schema_name],[source_system],[stored_procedure],[last_load_date],[last_load_type],[last_row_count],[last_pipeline_run],[updated_at])
VALUES ('quotation_requests_details','offshore_eam','SAP_ECC_EKAN','[dbo].[usp_offshore_eam_quotation_requests_details]','1900-01-01','initial',0,NULL,@now);