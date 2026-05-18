--Count number of columns per view

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COUNT(*) AS Column_Count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Edw_Eam'
  AND TABLE_NAME IN ('Contracts_vw', 'Rates_vw')
GROUP BY TABLE_SCHEMA, TABLE_NAME;

--List columns in order
SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Edw_Eam'
  AND TABLE_NAME IN ('Contracts_vw', 'Rates_vw')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

--Total rows
SELECT
    'Contracts_vw' AS View_Name,
    COUNT(*) AS Row_Count
FROM Edw_Eam.Contracts_vw

UNION ALL

SELECT
    'Rates_vw',
    COUNT(*)
FROM Edw_Eam.Rates_vw;

--Contracts – key business fields
SELECT
    SUM(CASE WHEN Contract IS NULL THEN 1 ELSE 0 END) AS Null_Contract,
    SUM(CASE WHEN Organization IS NULL THEN 1 ELSE 0 END) AS Null_Organization,
    SUM(CASE WHEN Supplier IS NULL THEN 1 ELSE 0 END) AS Null_Supplier,
    SUM(CASE WHEN Currency IS NULL THEN 1 ELSE 0 END) AS Null_Currency,
    SUM(CASE WHEN Start_Date IS NULL THEN 1 ELSE 0 END) AS Null_Start_Date,
    SUM(CASE WHEN End_Date IS NULL THEN 1 ELSE 0 END) AS Null_End_Date
FROM Edw_Eam.Contracts_vw;