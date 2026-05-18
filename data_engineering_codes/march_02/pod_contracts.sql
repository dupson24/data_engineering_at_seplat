CREATE VIEW Edw_Eam.Contracts_vw
AS
SELECT
    pod.Purchase_Order_Contract               AS Contract,
    pod.Purchase_Order_Description            AS [Description],
    pod.Purchase_Order_Organization_Code      AS Organization,
    pod.Purchase_Order_Supplier               AS Supplier,
    pod.Purchase_Order_Supplier_Description   AS Supplier_Description,
    pod.Purchase_Order_Status_Description     AS Status,
    pod.Purchase_Order_Store                  AS Store,
    pod.Purchase_Order_Buyer                  AS Buyer,

    /* Maximum Value = Parts + Services */
    ISNULL(pod.Purchase_Order_Part_Lines_Value, 0)
      + ISNULL(pod.Purchase_Order_Service_Lines_Value, 0)
                                              AS Maximum_Value,

    pod.Purchase_Order_Currency               AS Currency,

    pod.Purchase_Order_Created                AS Start_Date,
    pod.Purchase_Order_Due_Date               AS End_Date,

    /* Released value = received Parts + Services */
    ISNULL(parts.Released_Value, 0)
      + ISNULL(services.Released_Value, 0)
                                              AS Released_Value,

    /* Remaining value */
    (
        ISNULL(pod.Purchase_Order_Part_Lines_Value, 0)
      + ISNULL(pod.Purchase_Order_Service_Lines_Value, 0)
    )
    - (
        ISNULL(parts.Released_Value, 0)
      + ISNULL(services.Released_Value, 0)
      )
                                              AS Remaining_Value

FROM EnterpriseAssetManagement.Purchase_Order_Details pod

LEFT JOIN (
    SELECT
        Purchase_Order_Parts_Contract AS Contract,
        SUM(Purchase_Order_Parts_Recvvalue) AS Released_Value
    FROM EnterpriseAssetManagement.Purchase_Order_Parts_Details
    GROUP BY Purchase_Order_Parts_Contract
) parts
    ON pod.Purchase_Order_Contract = parts.Contract

LEFT JOIN (
    SELECT
        Purchase_Order_Services_Contract AS Contract,
        SUM(Purchase_Order_Services_Recvvalue) AS Released_Value
    FROM EnterpriseAssetManagement.Purchase_Order_Services_Details
    GROUP BY Purchase_Order_Services_Contract
) services
    ON pod.Purchase_Order_Contract = services.Contract

WHERE pod.Latest_Indicator = 1;
