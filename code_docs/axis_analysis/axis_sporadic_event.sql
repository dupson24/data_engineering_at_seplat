/* ============================================================
   AXIS — t_sporadic_event UPDATE / FRESHNESS CHECK
   Table: [Axis].[t_sporadic_event]
   Freshness columns: mod_dtime (change time), event_date (business time)
   ============================================================ */

---------------------------------------------------------------
-- 1) Latest 100 records (by mod_dtime)
---------------------------------------------------------------
SELECT TOP (100)
       [id],
       [event_type],
       [object_type],
       [object_id],
       [event_date],
       [status_id],
       [parent_event_id],
       [mod_user],
       [mod_dtime],
       [approval_set_id],
       [product_id],
       [event_date_local]
FROM [Axis].[t_sporadic_event]
ORDER BY TRY_CONVERT(datetime2, [mod_dtime]) DESC;


---------------------------------------------------------------
-- 2) Freshness / staleness summary using mod_dtime (last change)
---------------------------------------------------------------
;WITH x AS (
    SELECT TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_event]
)
SELECT
    MAX(mod_dt)                                          AS max_mod_dtime,
    MIN(mod_dt)                                          AS min_mod_dtime,
    COUNT(1)                                             AS total_rows,
    SUM(CASE WHEN mod_dt IS NULL THEN 1 ELSE 0 END)       AS null_mod_dtime_rows,
    DATEDIFF(day,  MAX(mod_dt), GETDATE())               AS mod_staleness_days,
    DATEDIFF(hour, MAX(mod_dt), GETDATE())               AS mod_staleness_hours
FROM x;


---------------------------------------------------------------
-- 3) Freshness / staleness summary using event_date (latest event)
-- (Sometimes source updates mod_dtime but event_date is what matters)
---------------------------------------------------------------
;WITH e AS (
    SELECT TRY_CONVERT(datetime2, [event_date]) AS event_dt
    FROM [Axis].[t_sporadic_event]
)
SELECT
    MAX(event_dt)                                        AS max_event_date,
    MIN(event_dt)                                        AS min_event_date,
    COUNT(1)                                             AS total_rows,
    SUM(CASE WHEN event_dt IS NULL THEN 1 ELSE 0 END)     AS null_event_date_rows,
    DATEDIFF(day,  MAX(event_dt), GETDATE())             AS event_staleness_days,
    DATEDIFF(hour, MAX(event_dt), GETDATE())             AS event_staleness_hours
FROM e;


---------------------------------------------------------------
-- 4) Modification trend (last 30 days) by mod_dtime
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [mod_dtime]) AS date) AS mod_day
    FROM [Axis].[t_sporadic_event]
    WHERE TRY_CONVERT(datetime2, [mod_dtime]) >= DATEADD(day, -30, GETDATE())
)
SELECT
    mod_day,
    COUNT(1) AS rows_modified
FROM d
WHERE mod_day IS NOT NULL
GROUP BY mod_day
ORDER BY mod_day DESC;


---------------------------------------------------------------
-- 5) Event arrival trend (last 30 days) by event_date
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [event_date]) AS date) AS event_day
    FROM [Axis].[t_sporadic_event]
    WHERE TRY_CONVERT(datetime2, [event_date]) >= DATEADD(day, -30, GETDATE())
)
SELECT
    event_day,
    COUNT(1) AS rows_by_event_day
FROM d
WHERE event_day IS NOT NULL
GROUP BY event_day
ORDER BY event_day DESC;


---------------------------------------------------------------
-- 6) Latest event per object_id (who is stale?)
---------------------------------------------------------------
;WITH s AS (
    SELECT
        [object_id],
        TRY_CONVERT(datetime2, [event_date]) AS event_dt
    FROM [Axis].[t_sporadic_event]
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
-- 7) Status distribution (are events stuck in a status?)
---------------------------------------------------------------
SELECT
    [status_id],
    COUNT(1) AS cnt
FROM [Axis].[t_sporadic_event]
GROUP BY [status_id]
ORDER BY cnt DESC;


---------------------------------------------------------------
-- 8) Latest activity by mod_user (who last touched it?)
---------------------------------------------------------------
;WITH u AS (
    SELECT
        [mod_user],
        TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_event]
)
SELECT TOP 50
    mod_user,
    COUNT(1) AS rows_touched,
    MAX(mod_dt) AS last_touch_time
FROM u
WHERE mod_dt IS NOT NULL
GROUP BY mod_user
ORDER BY last_touch_time DESC;


---------------------------------------------------------------
-- 9) Gap detection: last 60 days calendar with zero-count days
-- NOTE: master..spt_values might be blocked in some Synapse setups.
-- If it fails, tell me and I’ll switch to a compatible numbers CTE.
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
    FROM [Axis].[t_sporadic_event]
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
-- 10) Basic ID sanity check (helps infer insert growth)
---------------------------------------------------------------
SELECT
    COUNT(1)   AS total_rows,
    MIN([id])  AS min_id,
    MAX([id])  AS max_id
FROM [Axis].[t_sporadic_event];