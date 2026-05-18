SELECT
    s.name        AS schema_name,
    v.name        AS view_name,
    c.column_id   AS column_position,
    c.name        AS column_name,
    ty.name       AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.schemas s
JOIN sys.views v
    ON s.schema_id = v.schema_id
JOIN sys.columns c
    ON v.object_id = c.object_id
JOIN sys.types ty
    ON c.user_type_id = ty.user_type_id
WHERE s.name IN ('offshore_srm', 'offshore_eam')
ORDER BY
    s.name,
    v.name,
    c.column_id;