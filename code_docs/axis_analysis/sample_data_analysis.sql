/* ============================================================
   AXIS SAMPLE ANALYSIS — FULL UPDATE / FRESHNESS CHECK
   Table: [Axis].[Axis_Sample_AnalaysisData]
   ============================================================ */

---------------------------------------------------------------
-- 1) Latest 100 records (to visually confirm recency)
---------------------------------------------------------------
SELECT TOP (100)
       [event_id],
       [object_id],
       [event_date],
       [fields],
       [status],
       [Analysed],
       [BSW],
       [Sand Cut],
       [Samp Bean Size],
       [API],
       [SG],
       [Viscosity],
       [WaxAppTemp],
       [Comment],
       [SeiveNumber]
FROM [Axis].[Axis_Sample_AnalaysisData]
ORDER BY TRY_CONVERT(datetime2, [event_date]) DESC;


---------------------------------------------------------------
-- 2) Freshness / staleness summary
---------------------------------------------------------------
;WITH x AS (
    SELECT TRY_CONVERT(datetime2, [event_date]) AS event_dt
    FROM [Axis].[Axis_Sample_AnalaysisData]
)
SELECT
    MAX(event_dt)                                   AS max_event_date,
    MIN(event_dt)                                   AS min_event_date,
    COUNT(1)                                        AS total_rows,
    SUM(CASE WHEN event_dt IS NULL THEN 1 ELSE 0 END) AS null_event_date_rows,
    DATEDIFF(day, MAX(event_dt), GETDATE())         AS staleness_days,
    DATEDIFF(hour, MAX(event_dt), GETDATE())        AS staleness_hours
FROM x;


---------------------------------------------------------------
-- 3) Daily arrival trend (last 30 days)
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [event_date]) AS date) AS event_day
    FROM [Axis].[Axis_Sample_AnalaysisData]
    WHERE TRY_CONVERT(datetime2, [event_date]) >= DATEADD(day, -30, GETDATE())
)
SELECT
    event_day,
    COUNT(1) AS rows_per_day
FROM d
WHERE event_day IS NOT NULL
GROUP BY event_day
ORDER BY event_day DESC;


---------------------------------------------------------------
-- 4) Latest record per object_id (who stopped updating)
---------------------------------------------------------------
;WITH s AS (
    SELECT
        [object_id],
        TRY_CONVERT(datetime2, [event_date]) AS event_dt
    FROM [Axis].[Axis_Sample_AnalaysisData]
    WHERE [object_id] IS NOT NULL
)
SELECT TOP 200
    object_id,
    MAX(event_dt) AS last_event_date,
    DATEDIFF(day, MAX(event_dt), GETDATE()) AS staleness_days
FROM s
WHERE event_dt IS NOT NULL
GROUP BY object_id
ORDER BY staleness_days DESC, object_id;


---------------------------------------------------------------
-- 5) Status / Analysed distribution (are new rows stuck?)
---------------------------------------------------------------
SELECT
    [status],
    [Analysed],
    COUNT(1) AS cnt
FROM [Axis].[Axis_Sample_AnalaysisData]
GROUP BY [status], [Analysed]
ORDER BY cnt DESC;


---------------------------------------------------------------
-- 6) Gap detection: show last 60 days, including days with zero rows
-- (Uses master..spt_values; if blocked in Synapse, tell me and I'll
--  switch to a numbers CTE that works in Dedicated SQL Pool)
---------------------------------------------------------------
;WITH days AS (
    SELECT CAST(DATEADD(day, -v.number, CAST(GETDATE() AS date)) AS date) AS d
    FROM master..spt_values v
    WHERE v.type = 'P' AND v.number BETWEEN 0 AND 59
),
facts AS (
    SELECT
        CAST(TRY_CONVERT(date, [event_date]) AS date) AS d,
        COUNT(1) AS cnt
    FROM [Axis].[Axis_Sample_AnalaysisData]
    WHERE TRY_CONVERT(datetime2, [event_date]) >= DATEADD(day, -60, GETDATE())
    GROUP BY CAST(TRY_CONVERT(date, [event_date]) AS date)
)
SELECT
    days.d AS calendar_day,
    ISNULL(facts.cnt, 0) AS rows_count
FROM days
LEFT JOIN facts ON facts.d = days.d
ORDER BY calendar_day DESC;
``