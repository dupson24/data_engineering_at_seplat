INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 1,'phishme_security','dim_date','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_date','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 2,'phishme_security','dim_user','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_user','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 3,'phishme_security','dim_scenario','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/dim_scenario','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 4,'phishme_security','fact_phishing_responses','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_phishing_responses','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 5,'phishme_security','fact_activity_timeline','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_activity_timeline','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 6,'phishme_security','fact_activity_logs','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/fact_activity_logs','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 7,'phishme_security','agg_user_risk','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_user_risk','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 8,'phishme_security','agg_scenario_performance','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_scenario_performance','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 9,'phishme_security','agg_department_risk','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_department_risk','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();

INSERT INTO phishme_security.watermark (watermark_id,schema_name,table_name,last_load_date,last_load_timestamp,last_load_status,rows_extracted,rows_loaded,rows_rejected,source_path,pipeline_name,created_at,updated_at)
SELECT 10,'phishme_security','agg_monthly_trend','1900-01-01','1900-01-01 00:00:00','SKIPPED',0,0,0,'/mnt/PhishMe/curated/agg_monthly_trend','PL_PhishMe_Gold_Load',GETDATE(),GETDATE();
GO