CREATE VIEW Edw_Eam.Rates_vw
AS
SELECT
    ll.Currency_Code      AS Base_Currency,
    ll.Valid_From         AS Start_Date,
    ll.Valid_Until        AS End_Date,
    ll.Currency_Rate      AS Exchange_Rate
FROM SunSystemsCloud.Ledger_Lines ll
WHERE ll.Latest_Indicator = 1
  AND ll.Currency_Rate IS NOT NULL;

SELECT TOP 20 *
FROM Edw_Eam.Rates_vw
ORDER BY Start_Date DESC;