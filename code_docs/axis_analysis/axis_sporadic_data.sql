/* ============================================================
   AXIS — t_sporadic_data_point UPDATE / FRESHNESS CHECK
   Table: [Axis].[t_sporadic_data_point]
   Key freshness column: mod_dtime
   ============================================================ */

---------------------------------------------------------------
-- 1) Latest 100 records (visual confirmation)
---------------------------------------------------------------
SELECT TOP (100)
       [id],
       [event_type],
       [measurement_id],
       [derived_ind],
       [display_order],
       [min_value],
       [max_value],
       [stored_precision],
       [required_ind],
       [mod_user],
       [mod_dtime],
       [product_id],
       [display_precision]
FROM [Axis].[t_sporadic_data_point]
ORDER BY TRY_CONVERT(datetime2, [mod_dtime]) DESC;


---------------------------------------------------------------
-- 2) Freshness / staleness summary (is it up-to-date?)
---------------------------------------------------------------
;WITH x AS (
    SELECT TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_data_point]
)
SELECT
    MAX(mod_dt)                                         AS max_mod_dtime,
    MIN(mod_dt)                                         AS min_mod_dtime,
    COUNT(1)                                            AS total_rows,
    SUM(CASE WHEN mod_dt IS NULL THEN 1 ELSE 0 END)      AS null_mod_dtime_rows,
    DATEDIFF(day,  MAX(mod_dt), GETDATE())              AS staleness_days,
    DATEDIFF(hour, MAX(mod_dt), GETDATE())              AS staleness_hours
FROM x;


---------------------------------------------------------------
-- 3) Modification trend (last 30 days)
---------------------------------------------------------------
;WITH d AS (
    SELECT CAST(TRY_CONVERT(date, [mod_dtime]) AS date) AS mod_day
    FROM [Axis].[t_sporadic_data_point]
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
-- 4) Activity by mod_user (who changed it most recently)
---------------------------------------------------------------
;WITH u AS (
    SELECT
        [mod_user],
        TRY_CONVERT(datetime2, [mod_dtime]) AS mod_dt
    FROM [Axis].[t_sporadic_data_point]
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
-- 5) ID range sanity check (helps infer insert growth)
---------------------------------------------------------------
SELECT
    COUNT(1)    AS total_rows,
    MIN([id])   AS min_id,
    MAX([id])   AS max_id
FROM [Axis].[t_sporadic_data_point];