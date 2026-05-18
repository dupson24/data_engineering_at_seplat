-- ============================================================
-- srm.tenders  -  Reconstructed from source tables
--
-- tenders table is empty; columns sourced as follows:
--
--   posid    -> srm.poss.posid
--                (purchase order summary - the originating PO)
--   tendid   -> ROW_NUMBER() OVER (ORDER BY p.posid, w.worid)
--                (no source equivalent; generated as surrogate key)
--   vendid   -> srm.poss.vendid
--                (vendor assigned to the PO)
--   wodesc   -> srm.worders.justify
--                (work order description / justification text)
--   docreq   -> NULL
--                (document requirements - no equivalent in source)
--   stid     -> srm.worders.stid
--                (store/site ID from the work order)
--   postdate -> srm.poss.postdate
--                (date the PO was posted)
--   opdate   -> CAST(srm.worders.opdate AS DATE)
--                (operations approval date)
--   optime   -> CAST(srm.worders.opdate AS TIME)
--                (operations approval time, extracted from datetime)
--   clodate  -> CAST(srm.worders.authdate AS DATE)
--                (closing date = works order authorisation date)
--   clotime  -> CAST(srm.worders.authdate AS TIME)
--                (closing time, extracted from authdate datetime)
--
-- JOIN path:  poss -> porders (posid) -> worders (via woid on poss)
-- ============================================================

IF OBJECT_ID('[srm].[tenders_vw]', 'V') IS NOT NULL
    DROP VIEW [srm].[tenders_vw];
GO

CREATE VIEW [srm].[tenders_vw]
AS
SELECT
    p.[posid]                                           AS posid,

    -- Generated surrogate key: tenders has no source tendid
    ROW_NUMBER() OVER (
        ORDER BY p.[posid], w.[worid]
    )                                                   AS tendid,

    p.[vendid]                                          AS vendid,

    -- Work order justification is closest match to tender description
    w.[justify]                                         AS wodesc,

    -- No source column maps to docreq; NULL placeholder
    CAST(NULL AS VARCHAR(255))                          AS docreq,

    w.[stid]                                            AS stid,

    p.[postdate]                                        AS postdate,

    -- opdate / optime split from worders.opdate (datetime)
    CAST(w.[opdate] AS DATE)                            AS opdate,
    CAST(w.[opdate] AS TIME)                            AS optime,

    -- clodate / clotime split from worders.authdate (datetime)
    CAST(w.[authdate] AS DATE)                          AS clodate,
    CAST(w.[authdate] AS TIME)                          AS clotime

FROM [srm].[poss]       AS p
INNER JOIN [srm].[worders] AS w
        ON p.[woid] = w.[worid]
WHERE p.[vendid]    IS NOT NULL
  AND w.[opdate]    IS NOT NULL
  AND w.[authdate]  IS NOT NULL;
GO


-- ============================================================
-- Optional: populate tenders from generated data
-- ============================================================
-- INSERT INTO [srm].[tenders]
--     (posid, tendid, vendid, wodesc, docreq, stid,
--      postdate, opdate, optime, clodate, clotime)
-- SELECT
--     p.[posid],
--     ROW_NUMBER() OVER (ORDER BY p.[posid], w.[worid]),
--     p.[vendid],
--     w.[justify],
--     NULL,
--     w.[stid],
--     p.[postdate],
--     CAST(w.[opdate]   AS DATE),
--     CAST(w.[opdate]   AS TIME),
--     CAST(w.[authdate] AS DATE),
--     CAST(w.[authdate] AS TIME)
-- FROM [srm].[poss]       AS p
-- INNER JOIN [srm].[worders] AS w
--         ON p.[woid] = w.[worid]
-- WHERE p.[vendid]   IS NOT NULL
--   AND w.[opdate]   IS NOT NULL
--   AND w.[authdate] IS NOT NULL;


-- ============================================================
-- Validation
-- ============================================================
-- Row count
-- SELECT COUNT(*) AS Generated_Rows FROM ( <above query> ) x;

-- Check for NULL opdate/clodate after generation
-- SELECT
--     SUM(CASE WHEN opdate  IS NULL THEN 1 ELSE 0 END) AS Null_opdate,
--     SUM(CASE WHEN clodate IS NULL THEN 1 ELSE 0 END) AS Null_clodate
-- FROM [srm].[tenders];

-- Verify opdate always <= clodate
-- SELECT COUNT(*) AS Bad_Date_Order
-- FROM [srm].[tenders]
-- WHERE opdate > clodate;
