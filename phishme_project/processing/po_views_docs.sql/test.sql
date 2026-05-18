-- ============================================================
-- Edw_Eam.Contracts_vw  v4  -  Corrected dates & values

-- Source screen: Blanket Orders -> Contract view

-- COLUMN MAPPING (verified against EAM Data Dictionary):
--   Contract         = Purchase_Order_Code
--   Description      = Purchase_Order_Description
--   Organization     = Purchase_Order_Organization_Code
--   Supplier         = Purchase_Order_Supplier
--   Supplier Desc    = Purchase_Order_Supplier_Description
--   Status           = Purchase_Order_Status_Description
--   Store            = Purchase_Order_Store
--   Buyer            = Purchase_Order_Buyer
--   Maximum Value    = Purchase_Order_Part_Lines_Value
--                    + Purchase_Order_Service_Lines_Value
--                      (total value of all lines on the blanket)
--   Currency         = Purchase_Order_Currency
--   Start Date       = Purchase_Order_Approv
--                      (contract approval/effective date — NOT Created)
--   End Date         = Purchase_Order_Due_Date
--   Released Value   = Purchase_Order_Subtotal_Part_Value
--                    + Purchase_Order_Subtotal_Service_Value
--                      (cumulative receipted/invoiced value)
--   Remaining Value  = Maximum_Value - Released_Value

-- NOTE: Purchase_Order_Created is the PO creation date (earlier
--       than approval). The screen Start Date matches Approv.
--       Purchase_Order_Due_Date is the contract expiry date.



-- Edw_Eam.Rates_vw  -  Complete: Base Currency + NGN (Dual)
-- Source: EnterpriseAssetManagement only

-- EAM dual currency explanation:
--   _exch        = rate between Transaction Currency and Base Currency
--   _exchfromdual= rate FROM the dual currency (NGN) to base
--   _exchtodual  = rate TO the dual currency (NGN) from transaction

-- Three rate legs captured per source table:
--   Leg 1: Transaction currency vs Org base  (_exch)
--   Leg 2: Dual (NGN) to base               (_exchfromdual)
--   Leg 3: Transaction to dual (NGN)         (_exchtodual)

-- Sources (all carry dual columns + dates):
--   1. Invoice_Voucher_Details
--   2. Invoice_Voucher_Line_Details
--   3. Purchase_Order_Details
--   4. Purchase_Order_Parts_Details
--   5. Purchase_Order_Services_Details
--   6. Requisitions_Parts_Details
--   7. Requisitions_Services_Details

-- Output: Base_Currency | Transaction_Currency | Start_Date | End_Date | Exchange_Rate
--         Start_Date = End_Date = the transaction's effective date