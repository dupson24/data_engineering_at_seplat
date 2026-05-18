/* Supplier Master Unified - 30 Data Profiling / Quality Metrics (Single Result Set) */

WITH base AS (
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
        TRY_CONVERT(date, Registration_Date) AS Registration_Date,
        Bank_Sort_Code,
        Bank_Account_Number,
        Bank_Account_Type,
        Registered_Address,
        City,
        State_Region,
        Country
    FROM [Edw_Eam].[vw_supplier_master_unified]
),
stats AS (
    SELECT
        COUNT(1) AS total_rows,
        COUNT(DISTINCT Supplier_Code) AS distinct_supplier_code
    FROM base
),
mode_payment_terms AS (
    SELECT TOP 1 Payment_Terms
    FROM base
    WHERE NULLIF(LTRIM(RTRIM(Payment_Terms)), '') IS NOT NULL
    GROUP BY Payment_Terms
    ORDER BY COUNT(1) DESC, Payment_Terms
),
mode_currency AS (
    SELECT TOP 1 Currency
    FROM base
    WHERE NULLIF(LTRIM(RTRIM(Currency)), '') IS NOT NULL
    GROUP BY Currency
    ORDER BY COUNT(1) DESC, Currency
)
SELECT MetricName, MetricValue
FROM (
    /* 1 */ SELECT '01_TotalRows' AS MetricName, CAST(s.total_rows AS nvarchar(4000)) AS MetricValue FROM stats s
    UNION ALL
    /* 2 */ SELECT '02_DistinctSupplierCode', CAST(s.distinct_supplier_code AS nvarchar(4000)) FROM stats s
    UNION ALL
    /* 3 */ SELECT '03_DuplicateSupplierCodeCount', CAST(s.total_rows - s.distinct_supplier_code AS nvarchar(4000)) FROM stats s
    UNION ALL
    /* 4 */ SELECT '04_NullOrBlank_SupplierCode', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Code)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 5 */ SELECT '05_NullOrBlank_SupplierName', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Name)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 6 */ SELECT '06_NullOrBlank_SupplierStatus', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Status)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 7 */ SELECT '07_DistinctSupplierStatusCount', CAST(COUNT(DISTINCT Supplier_Status) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 8 */ SELECT '08_ActiveSupplierCount',
             CAST(SUM(CASE WHEN UPPER(LTRIM(RTRIM(Supplier_Status))) IN ('ACTIVE','ACT','A') THEN 1 ELSE 0 END) AS nvarchar(4000))
          FROM base
    UNION ALL
    /* 9 */ SELECT '09_UnknownSupplierStatusCount',
             CAST(SUM(CASE
                      WHEN NULLIF(LTRIM(RTRIM(Supplier_Status)), '') IS NULL THEN 0
                      WHEN UPPER(LTRIM(RTRIM(Supplier_Status))) NOT IN ('ACTIVE','ACT','A','INACTIVE','INACT','I','BLOCKED','BLK','SUSPENDED','SUSP')
                      THEN 1 ELSE 0 END) AS nvarchar(4000))
          FROM base
    UNION ALL
    /* 10 */ SELECT '10_NullOrBlank_EmailAddress', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Email_Address)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 11 */ SELECT '11_InvalidEmailFormatCount',
              CAST(SUM(CASE
                       WHEN NULLIF(LTRIM(RTRIM(Email_Address)), '') IS NULL THEN 0
                       WHEN Email_Address NOT LIKE '%_@_%._%' THEN 1
                       ELSE 0 END) AS nvarchar(4000))
           FROM base
    UNION ALL
    /* 12 */ SELECT '12_NullOrBlank_PhoneNumber', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Phone_Number)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 13 */ SELECT '13_InvalidPhoneCharsCount',
              CAST(SUM(CASE
                       WHEN NULLIF(LTRIM(RTRIM(Phone_Number)), '') IS NULL THEN 0
                       WHEN PATINDEX('%[^0-9+ ()-]%', Phone_Number) > 0 THEN 1
                       ELSE 0 END) AS nvarchar(4000))
           FROM base
    UNION ALL
    /* 14 */ SELECT '14_NullOrBlank_VendorAccountGroup', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Vendor_Account_Group)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 15 */ SELECT '15_DistinctVendorAccountGroupCount', CAST(COUNT(DISTINCT Vendor_Account_Group) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 16 */ SELECT '16_NullOrBlank_PaymentTerms', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Payment_Terms)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 17 */ SELECT '17_DistinctPaymentTermsCount', CAST(COUNT(DISTINCT Payment_Terms) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 18 */ SELECT '18_MostCommonPaymentTerms', COALESCE(CAST((SELECT Payment_Terms FROM mode_payment_terms) AS nvarchar(4000)), 'N/A')
    UNION ALL
    /* 19 */ SELECT '19_NullOrBlank_PayByMethod', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Pay_By_Method)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 20 */ SELECT '20_DistinctPayByMethodCount', CAST(COUNT(DISTINCT Pay_By_Method) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 21 */ SELECT '21_NullOrBlank_Currency', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Currency)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 22 */ SELECT '22_DistinctCurrencyCount', CAST(COUNT(DISTINCT Currency) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 23 */ SELECT '23_MostCommonCurrency', COALESCE(CAST((SELECT Currency FROM mode_currency) AS nvarchar(4000)), 'N/A')
    UNION ALL
    /* 24 */ SELECT '24_NullOrBlank_SupplierCostCenter', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Cost_Center)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 25 */ SELECT '25_NullOrBlank_SupplierAccountCode', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Account_Code)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 26 */ SELECT '26_NullOrBlank_PurchasingOrg1', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Group_Purchasing_Org_1)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 27 */ SELECT '27_NullOrBlank_PurchasingOrg2', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Supplier_Group_Purchasing_Org_2)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 28 */ SELECT '28_NullOrBlank_RegistrationNumber', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Registration_Number)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 29 */ SELECT '29_NullOrBlank_TaxIdentificationNumber', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Tax_Identification_Number)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 30 */ SELECT '30_NullOrBlank_VATRegistrationNumber', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(VAT_Registration_Number)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 31 (optional) */ SELECT '31_NullOrBlank_BankAccountNumber', CAST(SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Bank_Account_Number)), '') IS NULL THEN 1 ELSE 0 END) AS nvarchar(4000)) FROM base
    UNION ALL
    /* 32 (optional) */ SELECT '32_RegistrationDate_MinToMax',
           COALESCE(
             CONCAT(
               CONVERT(varchar(10), MIN(Registration_Date), 120),
               ' -> ',
               CONVERT(varchar(10), MAX(Registration_Date), 120)
             ),
             'N/A'
           )
    FROM base
) x
/* return only first 30 metrics (as requested) */
WHERE TRY_CONVERT(int, LEFT(MetricName, 2)) BETWEEN 1 AND 30
ORDER BY MetricName;