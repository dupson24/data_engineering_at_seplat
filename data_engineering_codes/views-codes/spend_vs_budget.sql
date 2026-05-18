/* ======================================================================================
   View:        proc_vw.spend_vs_budget
   Purpose:     Actual procurement commitment spend vs approved budget by cost centre & month
   Grain:       1 row = 1 cost centre / month  (includes business_unit for traceability)
   Sources:
       - offshore_sunsystems.Ledger_Lines      (amounts + dimensions)
       - offshore_sunsystems.Business_Units    (budget ledger + commitment ledger codes)
       - offshore_eam.organisation_details     (org context: fiscal year variant, COA code)
       - offshore_eam.date_dimension           (calendar attributes)
   Budget source:
       - Primary budget ledger entries in Ledger_Lines
   Spend source:
       - Purchase commitment ledger entries in Ledger_Lines
   Current fiscal year:
       - Implemented as Calendar Year = YEAR(GETDATE()) (adjust if FY differs)
   ====================================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'proc_vw')
BEGIN
    EXEC ('CREATE SCHEMA proc_vw');
END;
GO

CREATE OR ALTER VIEW proc_vw.spend_vs_budget
AS
WITH bu AS
(
    SELECT
        Business_Unit,
        Primary_Budget_Ledger_Code,
        Purchase_Commitment_Ledger_Code
    FROM offshore_sunsystems.Business_Units
),
ledger_enriched AS
(
    SELECT
        l.Business_Unit,
        cost_centre = NULLIF(LTRIM(RTRIM(l.Department)), ''),   -- ✅ cost centre assumption
        l.Ledger_Code,

        -- Use Base currency net (Debit - Credit) to avoid sign ambiguity
        net_amount =
            CAST(COALESCE(l.Base_Debit_Amount, 0)  AS decimal(18,4))
          - CAST(COALESCE(l.Base_Credit_Amount, 0) AS decimal(18,4)),

        -- Parse transaction date (Ledger_Lines stores as nvarchar)
        trans_date =
            COALESCE(
                TRY_CONVERT(date, l.Transaction_Date, 23),  -- yyyy-mm-dd
                TRY_CONVERT(date, l.Transaction_Date, 120), -- yyyy-mm-dd hh:mi:ss
                TRY_CONVERT(date, l.Transaction_Date, 103), -- dd/mm/yyyy
                TRY_CONVERT(date, l.Transaction_Date)       -- fallback
            )
    FROM offshore_sunsystems.Ledger_Lines l
),
ledger_tagged AS
(
    SELECT
        le.Business_Unit,
        le.cost_centre,
        le.net_amount,
        le.trans_date,

        is_budget =
            CASE WHEN le.Ledger_Code = b.Primary_Budget_Ledger_Code THEN 1 ELSE 0 END,

        is_commitment =
            CASE WHEN le.Ledger_Code = b.Purchase_Commitment_Ledger_Code THEN 1 ELSE 0 END
    FROM ledger_enriched le
    INNER JOIN bu b
        ON b.Business_Unit = le.Business_Unit
    WHERE le.trans_date IS NOT NULL
),
periodised AS
(
    SELECT
        d.[Year]    AS calendar_year,
        d.[Month]   AS calendar_month,
        d.MonthName AS month_name,
        d.MonthYear AS month_year,
        d.MMYYYY    AS mmyyyy,

        lt.Business_Unit,
        lt.cost_centre,

        budget_amount =
            CAST(SUM(CASE WHEN lt.is_budget = 1 THEN lt.net_amount ELSE 0 END) AS decimal(18,2)),

        actual_spend =
            CAST(SUM(CASE WHEN lt.is_commitment = 1 THEN lt.net_amount ELSE 0 END) AS decimal(18,2))
    FROM ledger_tagged lt
    INNER JOIN offshore_eam.date_dimension d
        ON d.[Date] = lt.trans_date
    WHERE
        d.[Year] = YEAR(GETDATE())  -- ✅ “Current fiscal year” (calendar-based). Adjust if FY differs.
        AND lt.cost_centre IS NOT NULL
    GROUP BY
        d.[Year], d.[Month], d.MonthName, d.MonthYear, d.MMYYYY,
        lt.Business_Unit, lt.cost_centre
)
SELECT
    p.calendar_year,
    p.calendar_month,
    p.month_name,
    p.month_year,
    p.mmyyyy,

    p.Business_Unit,
    p.cost_centre,

    -- Budget & Spend
    p.budget_amount,
    p.actual_spend,

    -- KPIs
    remaining_budget =
        CAST(COALESCE(p.budget_amount, 0) - COALESCE(p.actual_spend, 0) AS decimal(18,2)),

    overspend_flag =
        CASE WHEN COALESCE(p.actual_spend, 0) > COALESCE(p.budget_amount, 0) THEN 1 ELSE 0 END,

    budget_utilisation_pct =
        CASE
            WHEN COALESCE(p.budget_amount, 0) > 0
                THEN CAST(COALESCE(p.actual_spend, 0) / p.budget_amount AS decimal(18,4))
            ELSE NULL
        END,

    -- Org context (optional enrichment)
    od.organisation_description,
    od.fiscal_year_variant,
    od.chart_of_accounts
FROM periodised p
LEFT JOIN offshore_eam.organisation_details od
    ON od.organisation_code = p.Business_Unit;
GO