/* ============================================================
   AXIS — Axis_WellTestData UPDATE / FRESHNESS CHECK
   Table: [Axis].[Axis_WellTestData]
   Freshness column: event_date (and optionally [Test Date (Datetime)])
   ============================================================ */

---------------------------------------------------------------
-- 1) Latest 100 records (visual confirmation of most recent load)
---------------------------------------------------------------
SELECT TOP (100)
       [event_id],
       [object_id],
       [event_date],
       [units],
       [fields],
       [status],
       [Test Date (Datetime)],
       [Bean Size (64ths)],
       [Raw Liq (bbls/d)],
       [BSW (Vol%)],
       [Raw Oil (bbls/d)],
       [Raw Wat (bbls/d)],
       [Sand Cut (pptb)],
       [Gas Rate (mmscf/d)],
       [Oil Rate (bbls/d)],
       [Wat Rate (bbls/d)],
       [Total Gas (mmscf/d)],
       [FGOR (scf/bbl)],
       [FTHP (psig)],
       [Sep Press (psig)],
       [Sep Temp (DegF)],
       [DP (inH2O)],
       [Orifice Diam (Inch)],
       [Raw Gas (mmscf/d)],
       [FLP (psig)],
       [MLP (psig)],
       [CHP (psig)],
       [GL THP (psig)],
       [GL CHP (psig)],
       [Source (Text)],
       [Test Type (Text)],
       [Test Sep (Text)],
       [Duration (hour)],
       [Conn Sep (Text)],
       [Choke Press (psig)],
       [Meas Lift Gas (mmscf/d)],
       [Cal Lift Gas (mmscf/d)],
       [C10 (Mol%)],
       [GL Line Size (Inch)],
       [GL Inj Opening (percent)],
       [GL Orifice Plate Size (Inch)],
       [Comment (Text)],
       [ROW_HASH]
FROM [Axis].[Axis_WellTestData]
ORDER BY TRY_CONVERT(datetime2, [event_date]) DESC;


---------------------------------------------------------------
-- 2) Freshness / staleness summary (event_date)
---------------------------------------------------------------
;WITH x AS (
    SELECT
        TRY_CONVERT(datetime2, [event_date]) AS event_dt,
        TRY_CONVERT(datetime2, [Test Date (Datetime)]) AS test_dt
    FROM [Axis].[Axis_WellTestData]
)
SELECT
    MAX(event_dt)                                        AS max_event_date,
    MIN(event_dt)                                        AS min_event_date,
    MAX(test_dt)                                         AS max_test_date,
    MIN(test_dt)                                         AS min_test_date,
    COUNT(1)                                             AS total_rows,
    SUM(CASE WHEN event_dt IS NULL THEN 1 ELSE 0 END)     AS null_event_date_rows,
    SUM(CASE WHEN test_dt  IS NULL THEN 1 ELSE 0 END)     AS null_test_date_rows,
    DATEDIFF(day,  MAX(event_dt), GETDATE())             AS event_staleness_days,
    DATEDIFF(hour, MAX(event_dt), GETDATE())             AS event_staleness_hours
FROM x;


---------------------------------------------------------------
-- 3) Daily arrival trend (last 30 days) by event_date
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [event_date]) AS date) AS event_day
    FROM [Axis].[Axis_WellTestData]
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
-- 4) Latest record per object_id (which wells/objects are stale)
---------------------------------------------------------------
;WITH s AS (
    SELECT
        [object_id],
        TRY_CONVERT(datetime2, [event_date]) AS event_dt
    FROM [Axis].[Axis_WellTestData]
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
-- 5) Status distribution (are events stuck in a status?)
---------------------------------------------------------------
SELECT
    [status],
    COUNT(1) AS cnt
FROM [Axis].[Axis_WellTestData]
GROUP BY [status]
ORDER BY cnt DESC;


---------------------------------------------------------------
-- 6) Gap detection: last 60 days calendar with zero-count days
-- NOTE: master..spt_values might be blocked in Synapse setups.
-- If it fails, tell me and I’ll give you a Dedicated SQL-safe version.
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
    FROM [Axis].[Axis_WellTestData]
    WHERE TRY_CONVERT(datetime2, [event_date]) >= DATEADD(day, -60, GETDATE())
    GROUP BY CAST(TRY_CONVERT(date, [event_date]) AS date)
)
SELECT
    days.d AS calendar_day,
    ISNULL(facts.cnt, 0) AS rows_count
FROM days
LEFT JOIN facts ON facts.d = days.d
ORDER BY calendar_day DESC;


---------------------------------------------------------------
-- 7) Optional quality checks
-- 7a) Detect duplicate ROW_HASH (could indicate replay/dup loads)
---------------------------------------------------------------
SELECT TOP 50
    [ROW_HASH],
    COUNT(1) AS cnt
FROM [Axis].[Axis_WellTestData]
WHERE [ROW_HASH] IS NOT NULL
GROUP BY [ROW_HASH]
HAVING COUNT(1) > 1
ORDER BY cnt DESC;


---------------------------------------------------------------
-- 7b) Key field null checks (quick health indicator)
---------------------------------------------------------------
SELECT
    SUM(CASE WHEN [event_id]  IS NULL THEN 1 ELSE 0 END) AS null_event_id,
    SUM(CASE WHEN [object_id] IS NULL THEN 1 ELSE 0 END) AS null_object_id,
    SUM(CASE WHEN TRY_CONVERT(datetime2,[event_date]) IS NULL THEN 1 ELSE 0 END) AS bad_event_date,
    SUM(CASE WHEN [fields] IS NULL OR LTRIM(RTRIM(CAST([fields] AS varchar(max)))) = '' THEN 1 ELSE 0 END) AS blank_fields,
    SUM(CASE WHEN [status] IS NULL OR LTRIM(RTRIM(CAST([status] AS varchar(100)))) = '' THEN 1 ELSE 0 END) AS blank_status
FROM [Axis].[Axis_WellTestData];
``