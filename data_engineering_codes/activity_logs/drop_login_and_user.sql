/* ========= HARD REVOKE: Drop user + drop login ========= */

-- 1) Disable login immediately (optional but recommended)
ALTER LOGIN [autodb_user] DISABLE;
GO

-- 2) Fix schema ownership & drop user in the database
USE [YourDatabaseName];
GO

-- Transfer schema ownership if needed
IF EXISTS (
    SELECT 1
    FROM sys.schemas s
    JOIN sys.database_principals dp ON s.principal_id = dp.principal_id
    WHERE s.name = 'Auto' AND dp.name = 'autodb_user'
)
BEGIN
    ALTER AUTHORIZATION ON SCHEMA::[Auto] TO [dbo];
END
GO

-- Drop database user if exists
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'autodb_user')
BEGIN
    DROP USER [autodb_user];
END
GO

-- 3) Drop login (server level)
DROP LOGIN [autodb_user];
GO

-- Check if user owns the Auto schema
SELECT s.name AS schema_name, dp.name AS owner
FROM sys.schemas s
JOIN sys.database_principals dp ON s.principal_id = dp.principal_id
WHERE s.name = 'Auto';

-- Check objects inside schema Auto
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE s.name = 'Auto'
ORDER BY o.type_desc, o.name;
