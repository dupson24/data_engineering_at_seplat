SELECT
    s.name        AS schema_name,
    t.name        AS table_name,
    c.column_id   AS column_position,
    c.name        AS column_name,
    ty.name       AS data_type,
    CASE 
        WHEN ty.name IN ('varchar','nvarchar','char','nchar')
             THEN c.max_length
        ELSE NULL
    END           AS max_length,
    CASE c.is_nullable
        WHEN 1 THEN 'YES'
        ELSE 'NO'
    END           AS is_nullable
FROM sys.schemas s
JOIN sys.tables t
    ON s.schema_id = t.schema_id
JOIN sys.columns c
    ON t.object_id = c.object_id
JOIN sys.types ty
    ON c.user_type_id = ty.user_type_id
WHERE s.name IN ('offshore_srm', 'offshore_eam', 'offshore_sunsystems')
ORDER BY
    s.name,
    t.name,
    c.column_id;
