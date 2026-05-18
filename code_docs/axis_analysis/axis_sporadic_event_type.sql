/* ============================================================
   AXIS — t_sporadic_event_type UPDATE / FRESHNESS CHECK
   Table: [Axis].[t_sporadic_event_type]
   Freshness column: mod_dtime
   ============================================================ */

---------------------------------------------------------------
-- 1) Latest 100 rows (visual confirmation)
---------------------------------------------------------------
SELECT TOP (100)
       [id],
       [description],
       [object_type],
       [approval_set_id],
       [axis_1_meas_id],
       [axis_2_meas_id],
       [mod_user],
       [mod_dtime],
       [product_id],
       [date_type_ind],
       [always_trigger_approval_process],
       [parent_frequency],
       [details_url_pattern],
       [list_url_pattern],
       [new_url_pattern]
FROM [Axis].[t_sporadic_event_type]
ORDER BY TRY_CONVERT(datetime2, [mod_dtime]) DESC;


---------------------------------------------------------------
-- 2) Freshness / staleness summary (main “up-to-date” test)
---------------------------------------------------------------
;WITH x AS (
    SELECT TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_event_type]
)
SELECT
    MAX(mod_dt)                                          AS max_mod_dtime,
    MIN(mod_dt)                                          AS min_mod_dtime,
    COUNT(1)                                             AS total_rows,
    SUM(CASE WHEN mod_dt IS NULL THEN 1 ELSE 0 END)       AS null_mod_dtime_rows,
    DATEDIFF(day,  MAX(mod_dt), GETDATE())               AS staleness_days,
    DATEDIFF(hour, MAX(mod_dt), GETDATE())               AS staleness_hours
FROM x;


---------------------------------------------------------------
-- 3) Modification trend (last 30 days) by mod_dtime
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [mod_dtime]) AS date) AS mod_day
    FROM [Axis].[t_sporadic_event_type]
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
-- 4) Latest activity by mod_user (who last touched it?)
---------------------------------------------------------------
;WITH u AS (
    SELECT
        [mod_user],
        TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_event_type]
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
-- 5) Distribution checks (helps spot partial loads / filtering)
---------------------------------------------------------------
-- 5a) By object_type
SELECT
    [object_type],
    COUNT(1) AS cnt
FROM [Axis].[t_sporadic_event_type]
GROUP BY [object_type]
ORDER BY cnt DESC;

-- 5b) By product_id (if multi-product environment)
SELECT
    [product_id],
    COUNT(1) AS cnt
FROM [Axis].[t_sporadic_event_type]
GROUP BY [product_id]
ORDER BY cnt DESC;


---------------------------------------------------------------
-- 6) URL pattern completeness (optional quality check)
---------------------------------------------------------------
SELECT
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([details_url_pattern])), '') IS NULL THEN 1 ELSE 0 END) AS null_or_blank_details_url,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([list_url_pattern])), '')    IS NULL THEN 1 ELSE 0 END) AS null_or_blank_list_url,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([new_url_pattern])), '')     IS NULL THEN 1 ELSE 0 END) AS null_or_blank_new_url
FROM [Axis].[t_sporadic_event_type];


---------------------------------------------------------------
-- 7) Gap detection: last 60 days calendar with zero modifications
-- NOTE: master..spt_values might be blocked in some Synapse setups.
-- If it fails, tell me and I’ll replace with a dedicated SQL-safe CTE.
---------------------------------------------------------------
;WITH days AS (
    SELECT CAST(DATEADD(day, -v.number, CAST(GETDATE() AS date)) AS date) AS d
    FROM master..spt_values v
    WHERE v.type = 'P' AND v.number BETWEEN 0 AND 59
),
facts AS (
    SELECT
        CAST(TRY_CONVERT(date, [mod_dtime]) AS date) AS d,
        COUNT(1) AS cnt
    FROM [Axis].[t_sporadic_event_type]
    WHERE TRY_CONVERT(datetime2, [mod_dtime]) >= DATEADD(day, -60, GETDATE())
    GROUP BY CAST(TRY_CONVERT(date, [mod_dtime]) AS date)
)
SELECT
    days.d AS calendar_day,
    ISNULL(facts.cnt, 0) AS rows_modified
FROM days
LEFT JOIN facts ON facts.d = days.d
ORDER BY calendar_day DESC;


---------------------------------------------------------------
-- 8) Basic ID sanity check (helps infer insert growth)
---------------------------------------------------------------
SELECT
    COUNT(1)  AS total_rows,
    MIN([id]) AS min_id,
    MAX([id]) AS max_id
FROM [Axis].[t_sporadic_event_type];