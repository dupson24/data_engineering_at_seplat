/* =========================================================
   QUICK PROFILE
   ========================================================= */
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(Base_Currency,'|',Transaction_Currency)) AS distinct_pairs,
  MIN(Start_Date) AS min_start_date,
  MAX(End_Date) AS max_end_date,
  MIN(Exchange_Rate) AS min_rate,
  MAX(Exchange_Rate) AS max_rate
FROM [Edw_Eam].[Rates_vw];


/* =========================================================
   NULL / BLANK CHECKS
   ========================================================= */
SELECT
  SUM(CASE WHEN Base_Currency IS NULL OR LTRIM(RTRIM(Base_Currency)) = '' THEN 1 ELSE 0 END) AS null_base_currency,
  SUM(CASE WHEN Transaction_Currency IS NULL OR LTRIM(RTRIM(Transaction_Currency)) = '' THEN 1 ELSE 0 END) AS null_transaction_currency,
  SUM(CASE WHEN Start_Date IS NULL THEN 1 ELSE 0 END) AS null_start_date,
  SUM(CASE WHEN End_Date IS NULL THEN 1 ELSE 0 END) AS null_end_date,
  SUM(CASE WHEN Exchange_Rate IS NULL THEN 1 ELSE 0 END) AS null_exchange_rate
FROM [Edw_Eam].[Rates_vw];


/* =========================================================
   BUSINESS RULE VALIDATIONS
   ========================================================= */
-- Start_Date > End_Date
SELECT TOP 100 *
FROM [Edw_Eam].[Rates_vw]
WHERE Start_Date > End_Date;

-- Invalid exchange rates
SELECT TOP 100 *
FROM [Edw_Eam].[Rates_vw]
WHERE Exchange_Rate <= 0 OR Exchange_Rate IS NULL;


/* =========================================================
   DUPLICATE CHECKS
   ========================================================= */
-- Exact duplicates
SELECT
  Base_Currency,
  Transaction_Currency,
  Start_Date,
  End_Date,
  Exchange_Rate,
  COUNT(*) AS duplicate_count
FROM [Edw_Eam].[Rates_vw]
GROUP BY
  Base_Currency,
  Transaction_Currency,
  Start_Date,
  End_Date,
  Exchange_Rate
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Duplicate key (same pair + start date)
SELECT
  Base_Currency,
  Transaction_Currency,
  Start_Date,
  COUNT(*) AS duplicate_key_count
FROM [Edw_Eam].[Rates_vw]
GROUP BY
  Base_Currency,
  Transaction_Currency,
  Start_Date
HAVING COUNT(*) > 1
ORDER BY duplicate_key_count DESC;


/* =========================================================
   OVERLAPPING DATE RANGES
   ========================================================= */
WITH overlap_cte AS (
  SELECT
    Base_Currency,
    Transaction_Currency,
    Start_Date,
    End_Date,
    LEAD(Start_Date) OVER (
      PARTITION BY Base_Currency, Transaction_Currency
      ORDER BY Start_Date, End_Date
    ) AS next_start_date
  FROM [Edw_Eam].[Rates_vw]
)
SELECT TOP 200 *
FROM overlap_cte
WHERE next_start_date IS NOT NULL
  AND End_Date >= next_start_date;


/* =========================================================
   GAP CHECKS BETWEEN DATE RANGES
   ========================================================= */
WITH gap_cte AS (
  SELECT
    Base_Currency,
    Transaction_Currency,
    Start_Date,
    End_Date,
    LEAD(Start_Date) OVER (
      PARTITION BY Base_Currency, Transaction_Currency
      ORDER BY Start_Date, End_Date
    ) AS next_start_date
  FROM [Edw_Eam].[Rates_vw]
)
SELECT TOP 200
  Base_Currency,
  Transaction_Currency,
  Start_Date,
  End_Date,
  next_start_date,
  DATEDIFF(day, End_Date, next_start_date) AS gap_days
FROM gap_cte
WHERE next_start_date IS NOT NULL
  AND DATEDIFF(day, End_Date, next_start_date) > 1
ORDER BY gap_days DESC;


/* =========================================================
   CURRENCY FORMAT CHECKS
   ========================================================= */
SELECT TOP 200 *
FROM [Edw_Eam].[Rates_vw]
WHERE LEN(LTRIM(RTRIM(Base_Currency))) <> 3
   OR LEN(LTRIM(RTRIM(Transaction_Currency))) <> 3
   OR Base_Currency <> UPPER(Base_Currency)
   OR Transaction_Currency <> UPPER(Transaction_Currency);


/* =========================================================
   RATE CHANGE / SPIKE CHECK (>20%)
   ========================================================= */
WITH rate_change AS (
  SELECT
    Base_Currency,
    Transaction_Currency,
    Start_Date,
    End_Date,
    Exchange_Rate,
    LAG(Exchange_Rate) OVER (
      PARTITION BY Base_Currency, Transaction_Currency
      ORDER BY Start_Date, End_Date
    ) AS prev_rate
  FROM [Edw_Eam].[Rates_vw]
)
SELECT TOP 200 *,
       (Exchange_Rate - prev_rate) / NULLIF(prev_rate, 0) AS pct_change
FROM rate_change
WHERE prev_rate IS NOT NULL
  AND ABS((Exchange_Rate - prev_rate) / NULLIF(prev_rate, 0)) > 0.20
ORDER BY ABS((Exchange_Rate - prev_rate) / NULLIF(prev_rate, 0)) DESC;


/* =========================================================
   STATISTICAL OUTLIERS (Z-SCORE)
   ========================================================= */
WITH stats AS (
  SELECT
    Base_Currency,
    Transaction_Currency,
    AVG(CAST(Exchange_Rate AS FLOAT)) AS avg_rate,
    STDEV(CAST(Exchange_Rate AS FLOAT)) AS sd_rate
  FROM [Edw_Eam].[Rates_vw]
  WHERE Exchange_Rate IS NOT NULL
  GROUP BY Base_Currency, Transaction_Currency
),
z_scores AS (
  SELECT
    r.*,
    (CAST(r.Exchange_Rate AS FLOAT) - s.avg_rate) / NULLIF(s.sd_rate, 0) AS z_score
  FROM [Edw_Eam].[Rates_vw] r
  JOIN stats s
    ON r.Base_Currency = s.Base_Currency
   AND r.Transaction_Currency = s.Transaction_Currency
)
SELECT TOP 200 *
FROM z_scores
WHERE ABS(z_score) >= 3
ORDER BY ABS(z_score) DESC;


/* =========================================================
   MOST RECENT RATE PER CURRENCY PAIR
   ========================================================= */
WITH latest_rate AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY Base_Currency, Transaction_Currency
           ORDER BY End_Date DESC, Start_Date DESC
         ) AS rn
  FROM [Edw_Eam].[Rates_vw]
)
SELECT
  Base_Currency,
  Transaction_Currency,
  Start_Date,
  End_Date,
  Exchange_Rate
FROM latest_rate
WHERE rn = 1
ORDER BY Base_Currency, Transaction_Currency;


/* =========================================================
   MONTHLY COVERAGE SUMMARY
   ========================================================= */
SELECT
  Base_Currency,
  Transaction_Currency,
  DATEFROMPARTS(YEAR(Start_Date), MONTH(Start_Date), 1) AS start_month,
  COUNT(*) AS rows_in_month,
  MIN(Exchange_Rate) AS min_rate,
  MAX(Exchange_Rate) AS max_rate
FROM [Edw_Eam].[Rates_vw]
GROUP BY
  Base_Currency,
  Transaction_Currency,
  DATEFROMPARTS(YEAR(Start_Date), MONTH(Start_Date), 1)
ORDER BY start_month DESC, Base_Currency, Transaction_Currency;
``