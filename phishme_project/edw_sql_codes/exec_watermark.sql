EXEC phishme_security.usp_set_watermark
    'dim_user',
    '2026-03-13',
    '2026-03-13 02:30:00',
    'SUCCESS',
    2214,   -- rows_extracted
    2214,   -- rows_loaded
    0,      -- rows_rejected
    '/mnt/PhishMe/gold/dim_user',
    1,      -- source_file_count
    NULL,   -- source_size_bytes
    'PL_PhishMe_Gold_Load',
    NULL,   -- pipeline_run_id
    'scheduler',
    NULL,   -- error_message
    NULL;   -- error_code