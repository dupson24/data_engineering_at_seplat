/* ============================================================
   ONE-STATEMENT Supplier Master Analysis (2023–2026)
   Returns ONE result set (Metric, Dim1, Dim2, Value)

   Date filter: Registration_Date >= '2023-01-01'
                AND Registration_Date <  '2027-01-01'
   ============================================================ */

WITH base AS
(
    SELECT
        Supplier_Code,
        Supplier_Name,
        Supplier_Status,
        Email_Address,
        Phone_Number,
        Vendor_Account_Group,
        Payment_Terms,
        Pay_By_Method,
        Currency,
        Supplier_Cost_Center,
        Supplier_Account_Code,
        Supplier_Group_Purchasing_Org_1,
        Supplier_Group_Purchasing_Org_2,
        Registration_Number,
        Tax_Identification_Number,
        VAT_Registration_Number,
        Registration_Date,
        Bank_Sort_Code,
        Bank_Account_Number,
        Bank_Account_Type,
        Registered_Address,
        City,
        State_Region,
        Country
    FROM [Edw_Eam].[vw_supplier_master_unified]
    WHERE Registration_Date >= '2023-01-01'
      AND Registration_Date <  '2027-01-01'
)
SELECT *
FROM
(
    /* 1) Total suppliers registered (2023–2026) */
    SELECT
        'TotalSuppliers_2023_2026' AS Metric,
        CAST(NULL AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint)    AS Value
    FROM base

    UNION ALL

    /* 2) Suppliers by year */
    SELECT
        'SuppliersByYear' AS Metric,
        CAST(YEAR(Registration_Date) AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY YEAR(Registration_Date)

    UNION ALL

    /* 3) Suppliers by year-month (yyyy-MM) */
    SELECT
        'SuppliersByYearMonth' AS Metric,
        CONVERT(varchar(7), Registration_Date, 126) AS Dim1,  -- yyyy-MM
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY CONVERT(varchar(7), Registration_Date, 126)

    UNION ALL

    /* 4) Supplier status distribution */
    SELECT
        'SupplierStatus' AS Metric,
        CAST(Supplier_Status AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY Supplier_Status

    UNION ALL

    /* 5) Supplier status by year */
    SELECT
        'SupplierStatusByYear' AS Metric,
        CAST(YEAR(Registration_Date) AS varchar(200)) AS Dim1,
        CAST(Supplier_Status AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY YEAR(Registration_Date), Supplier_Status

    UNION ALL

    /* 6) Top 20 Vendor Account Groups */
    SELECT
        'TopVendorAccountGroup' AS Metric,
        CAST(Vendor_Account_Group AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(Cnt AS bigint) AS Value
    FROM
    (
        SELECT
            Vendor_Account_Group,
            COUNT(*) AS Cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM base
        GROUP BY Vendor_Account_Group
    ) x
    WHERE rn <= 20

    UNION ALL

    /* 7) Purchasing org group coverage (PO1/PO2) */
    SELECT
        'PurchasingOrgCoverage' AS Metric,
        CAST(CASE WHEN Supplier_Group_Purchasing_Org_1 IS NULL OR LTRIM(RTRIM(Supplier_Group_Purchasing_Org_1)) = '' THEN 'Missing' ELSE 'Present' END AS varchar(200)) AS Dim1,
        CAST(CASE WHEN Supplier_Group_Purchasing_Org_2 IS NULL OR LTRIM(RTRIM(Supplier_Group_Purchasing_Org_2)) = '' THEN 'Missing' ELSE 'Present' END AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY
        CASE WHEN Supplier_Group_Purchasing_Org_1 IS NULL OR LTRIM(RTRIM(Supplier_Group_Purchasing_Org_1)) = '' THEN 'Missing' ELSE 'Present' END,
        CASE WHEN Supplier_Group_Purchasing_Org_2 IS NULL OR LTRIM(RTRIM(Supplier_Group_Purchasing_Org_2)) = '' THEN 'Missing' ELSE 'Present' END

    UNION ALL

    /* 8) Completeness (key fields) */
    SELECT 'Missing_Supplier_Code', NULL, NULL, CAST(SUM(CASE WHEN Supplier_Code IS NULL OR LTRIM(RTRIM(Supplier_Code)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Supplier_Name', NULL, NULL, CAST(SUM(CASE WHEN Supplier_Name IS NULL OR LTRIM(RTRIM(Supplier_Name)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Email', NULL, NULL, CAST(SUM(CASE WHEN Email_Address IS NULL OR LTRIM(RTRIM(Email_Address)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Phone', NULL, NULL, CAST(SUM(CASE WHEN Phone_Number IS NULL OR LTRIM(RTRIM(Phone_Number)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Country', NULL, NULL, CAST(SUM(CASE WHEN Country IS NULL OR LTRIM(RTRIM(Country)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_City', NULL, NULL, CAST(SUM(CASE WHEN City IS NULL OR LTRIM(RTRIM(City)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Payment_Terms', NULL, NULL, CAST(SUM(CASE WHEN Payment_Terms IS NULL OR LTRIM(RTRIM(Payment_Terms)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_Currency', NULL, NULL, CAST(SUM(CASE WHEN Currency IS NULL OR LTRIM(RTRIM(Currency)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base

    UNION ALL

    /* 9) Duplicate Supplier_Code */
    SELECT
        'Duplicate_Supplier_Code' AS Metric,
        CAST(Supplier_Code AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY Supplier_Code
    HAVING COUNT(*) > 1

    UNION ALL

    /* 10) Duplicate Supplier_Name */
    SELECT
        'Duplicate_Supplier_Name' AS Metric,
        CAST(Supplier_Name AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY Supplier_Name
    HAVING COUNT(*) > 1

    UNION ALL

    /* 11) Duplicate Tax IDs */
    SELECT
        'Duplicate_Tax_Identification_Number' AS Metric,
        CAST(Tax_Identification_Number AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    WHERE Tax_Identification_Number IS NOT NULL
      AND LTRIM(RTRIM(Tax_Identification_Number)) <> ''
    GROUP BY Tax_Identification_Number
    HAVING COUNT(*) > 1

    UNION ALL

    /* 12) Duplicate Bank Account Numbers */
    SELECT
        'Duplicate_Bank_Account_Number' AS Metric,
        CAST(Bank_Account_Number AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    WHERE Bank_Account_Number IS NOT NULL
      AND LTRIM(RTRIM(Bank_Account_Number)) <> ''
    GROUP BY Bank_Account_Number
    HAVING COUNT(*) > 1

    UNION ALL

    /* 13) Suspect Emails */
    SELECT
        'SuspectEmails' AS Metric,
        CAST(NULL AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    WHERE Email_Address IS NOT NULL
      AND LTRIM(RTRIM(Email_Address)) <> ''
      AND (Email_Address NOT LIKE '%@%.%' OR Email_Address LIKE '% %')

    UNION ALL

    /* 14) Invalid currency formats (LEN != 3) */
    SELECT
        'InvalidCurrencyLength' AS Metric,
        CAST(Currency AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    WHERE Currency IS NOT NULL
    GROUP BY Currency
    HAVING LEN(LTRIM(RTRIM(Currency))) <> 3

    UNION ALL

    /* 15) Payment terms distribution (Top 20) */
    SELECT
        'TopPaymentTerms' AS Metric,
        CAST(Payment_Terms AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(Cnt AS bigint) AS Value
    FROM
    (
        SELECT
            Payment_Terms,
            COUNT(*) AS Cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM base
        GROUP BY Payment_Terms
    ) pt
    WHERE rn <= 20

    UNION ALL

    /* 16) Pay-by method distribution (Top 20) */
    SELECT
        'TopPayByMethod' AS Metric,
        CAST(Pay_By_Method AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(Cnt AS bigint) AS Value
    FROM
    (
        SELECT
            Pay_By_Method,
            COUNT(*) AS Cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM base
        GROUP BY Pay_By_Method
    ) pm
    WHERE rn <= 20

    UNION ALL

    /* 17) Currency distribution */
    SELECT
        'CurrencyDistribution' AS Metric,
        CAST(Currency AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    GROUP BY Currency

    UNION ALL

    /* 18) Suppliers by country (Top 30) */
    SELECT
        'TopCountry' AS Metric,
        CAST(Country AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(Cnt AS bigint) AS Value
    FROM
    (
        SELECT
            Country,
            COUNT(*) AS Cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM base
        GROUP BY Country
    ) c
    WHERE rn <= 30

    UNION ALL

    /* 19) Country + State combos (Top 30) */
    SELECT
        'TopCountryState' AS Metric,
        CAST(Country AS varchar(200)) AS Dim1,
        CAST(State_Region AS varchar(200)) AS Dim2,
        CAST(Cnt AS bigint) AS Value
    FROM
    (
        SELECT
            Country,
            State_Region,
            COUNT(*) AS Cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM base
        GROUP BY Country, State_Region
    ) cs
    WHERE rn <= 30

    UNION ALL

    /* 20) Missing address components */
    SELECT 'Missing_Address', NULL, NULL, CAST(SUM(CASE WHEN Registered_Address IS NULL OR LTRIM(RTRIM(Registered_Address)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base
    UNION ALL
    SELECT 'Missing_State', NULL, NULL, CAST(SUM(CASE WHEN State_Region IS NULL OR LTRIM(RTRIM(State_Region)) = '' THEN 1 ELSE 0 END) AS bigint) FROM base

    UNION ALL

    /* 21) Future dates inside base (should be 0) */
    SELECT
        'FutureRegistrationDate_InRange' AS Metric,
        CAST(NULL AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM base
    WHERE Registration_Date > GETDATE()

    UNION ALL

    /* 22) Null Registration_Date (full view) */
    SELECT
        'NullRegistrationDate_FullView' AS Metric,
        CAST(NULL AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM [Edw_Eam].[vw_supplier_master_unified]
    WHERE Registration_Date IS NULL

    UNION ALL

    /* 23) Date buckets outside range (full view) */
    SELECT
        'DateBucket_FullView' AS Metric,
        CAST(
            CASE
                WHEN Registration_Date IS NULL THEN 'NULL'
                WHEN Registration_Date <  '2023-01-01' THEN 'Before 2023'
                WHEN Registration_Date >= '2027-01-01' THEN 'After 2026'
                ELSE 'Within 2023-2026'
            END
        AS varchar(200)) AS Dim1,
        CAST(NULL AS varchar(200)) AS Dim2,
        CAST(COUNT(*) AS bigint) AS Value
    FROM [Edw_Eam].[vw_supplier_master_unified]
    GROUP BY
        CASE
            WHEN Registration_Date IS NULL THEN 'NULL'
            WHEN Registration_Date <  '2023-01-01' THEN 'Before 2023'
            WHEN Registration_Date >= '2027-01-01' THEN 'After 2026'
            ELSE 'Within 2023-2026'
        END
) z
ORDER BY
    Metric,
    Value DESC,
    Dim1,
    Dim2;