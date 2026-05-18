// =====================================================
// CELL 4: AD AzureDiagnostics / AzureActivity// CELL 4: ADLS/STORAGE + LOGIC APPS + AZURE ACTIVITY LOG
// =====================================================
let start = ago(30d);

// ----------------------
// A) STORAGE / ADLS GEN2
// ----------------------

// A1) Discover storage categories being ingested
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.STORAGE"
| summarize cnt=count() by Category
| order by cnt desc

// A2) Sample storage logs (inspect available columns like StatusCode/CallerIpAddress)
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.STORAGE"
| take 20

// A3) Storage daily volume by category
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.STORAGE"
| summarize Events=count() by Category, bin(TimeGenerated, 1d)
| order by TimeGenerated asc

// A4) Storage failures (4xx/5xx) — tries common status fields
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.STORAGE"
| extend Status = coalesce(tostring(StatusCode), tostring(statusCode_s), tostring(HttpStatusCode), tostring(httpStatusCode_s))
| where Status startswith "4" or Status startswith "5"
| summarize Failures=count() by Category, Status
| order by Failures desc

// A5) Top caller IPs (adjust if your storage logs use a different field)
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.STORAGE"
| extend IP = coalesce(tostring(CallerIpAddress), tostring(callerIpAddress_s), tostring(clientIp_s), tostring(ClientIp))
| summarize Events=count() by IP
| order by Events desc
| take 50

// --------------
// B) LOGIC APPS
// --------------

// B1) Discover Logic Apps categories being ingested
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.LOGIC"
| summarize cnt=count() by Category
| order by cnt desc

// B2) Sample Logic App logs (inspect workflow name/status columns)
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.LOGIC"
| take 20

// B3) Logic App failures trend (generic)
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.LOGIC"
| extend Result = coalesce(tostring(Status), tostring(status_s), tostring(ResultType), tostring(result_s))
| where Result has_any ("Failed","Failure","TimedOut","Canceled")
| summarize Failures=count() by bin(TimeGenerated, 1d)
| order by TimeGenerated asc

// B4) Top failing workflows (generic; uses common workflow name fields)
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.LOGIC"
| extend Workflow = coalesce(tostring(WorkflowName), tostring(workflowName_s), tostring(resource_workflowName_s), tostring(Resource))
| extend Result = coalesce(tostring(Status), tostring(status_s), tostring(ResultType), tostring(result_s))
| where Result has_any ("Failed","Failure","TimedOut","Canceled")
| summarize Failures=count() by Workflow
| order by Failures desc
| take 50

// ---------------------
// C) AZURE ACTIVITY LOG
// ---------------------

// C1) Who changed what (control-plane governance)
AzureActivity
| where TimeGenerated >= start
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup, ResourceId
| order by TimeGenerated desc
| take 2000

// C2) ResourceGroup-specific (adjust RG name)
AzureActivity
| where TimeGenerated >= start
| where ResourceGroup == "seplatedw"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceId
| order by TimeGenerated desc

