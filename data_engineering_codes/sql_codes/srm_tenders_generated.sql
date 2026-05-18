-- ============================================================
-- srm.tenders_vw  -  Reconstructed from source tables
--
-- tenders table is empty; columns sourced as follows:
--
--   posid    -> srm.poss.posid
--   tendid   -> ROW_NUMBER() OVER (ORDER BY p.posid, wi.worid)
--   vendid   -> srm.poss.vendid
--   wodesc   -> srm.worders.justify
--   docreq   -> NULL  (no equivalent in schema)
--   stid     -> srm.worders.stid
--   postdate -> srm.poss.postdate
--   opdate   -> CAST(srm.worders.opdate AS DATE)
--   optime   -> CAST(srm.worders.opdate AS TIME)
--   clodate  -> CAST(srm.worders.authdate AS DATE)
--   clotime  -> CAST(srm.worders.authdate AS TIME)
--
-- JOIN PATH:
--   poss -> woitems (poss.woid = woitems.woid)
--        -> worders (woitems.worid = worders.worid)
--
-- NOTE: poss.woid -> worders.worid direct join was empty in data.
--       woitems is the correct bridge table between the two.
-- ============================================================

IF OBJECT_ID('[srm].[tenders_vw]', 'V') IS NOT NULL
    DROP VIEW [srm].[tenders_vw];
GO

CREATE VIEW [srm].[tenders_vw]
AS
SELECT
    p.[posid]                                           AS posid,

    ROW_NUMBER() OVER (
        ORDER BY p.[posid], wi.[worid]
    )                                                   AS tendid,

    p.[vendid]                                          AS vendid,

    w.[justify]                                         AS wodesc,

    CAST(NULL AS VARCHAR(255))                          AS docreq,

    w.[stid]                                            AS stid,

    p.[postdate]                                        AS postdate,

    CAST(w.[opdate]   AS DATE)                          AS opdate,
    CAST(w.[opdate]   AS TIME)                          AS optime,

    CAST(w.[authdate] AS DATE)                          AS clodate,
    CAST(w.[authdate] AS TIME)                          AS clotime

FROM      [srm].[poss]    AS p
INNER JOIN [srm].[woitems] AS wi ON p.[woid]   = wi.[woid]
INNER JOIN [srm].[worders] AS w  ON wi.[worid]  = w.[worid]

WHERE p.[vendid]    IS NOT NULL
  AND w.[opdate]    IS NOT NULL
  AND w.[authdate]  IS NOT NULL;
GO


-- ============================================================
-- Validation
-- ============================================================
-- SELECT TOP 100 * FROM [srm].[tenders_vw] ORDER BY posid;
-- SELECT COUNT(*) AS Total_Rows FROM [srm].[tenders_vw];
