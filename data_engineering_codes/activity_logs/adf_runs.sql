// ==============================
// CELL 1: ADF / SYNAPSE PIPELINES
// ==============================
let start = ago(30d);

// --- 1) DISCOVERY: Do I have resource-specific ADF tables? ---
search "ADF"
| summarize Tables = make_set($table)

// --- 2) PIPELINE RUNS (resource-specific) ---
ADFPipelineRun
| where TimeGenerated >= start
| order by TimeGenerated desc
| take 200

// --- 3) PIPELINE KPI (resource-specific) ---
ADFPipelineRun
| where TimeGenerated >= start
| summarize
    Total=count(),
    Succeeded=countif(Status =~ "Succeeded"),
    Failed=countif(Status !~ "Succeeded"),
    SuccessRatePct=round(100.0*countif(Status =~ "Succeeded")/count(),2)

// --- 4) PIPELINE FAILURES by PipelineName (resource-specific) ---
ADFPipelineRun
| where TimeGenerated >= start and Status !~ "Succeeded"
| summarize Failures=count() by PipelineName
| order by Failures desc
| take 50

// --- 5) PIPELINE DURATION (avg/p95) (resource-specific) ---
ADFPipelineRun
| where TimeGenerated >= start
| summarize
    Runs=count(),
    AvgDurationSec=round(avg(DurationMs)/1000.0,2),
    P95DurationSec=round(percentile(DurationMs,95)/1000.0,2)
  by PipelineName
| order by P95DurationSec desc
| take 50

// --- 6) ACTIVITY FAILURES (resource-specific) ---
ADFActivityRun
| where TimeGenerated >= start and Status !~ "Succeeded"
| summarize Failures=count() by PipelineName, ActivityName, ActivityType
| order by Failures desc
| take 100

// --- 7) TRIGGER RUNS (resource-specific) ---
ADFTriggerRun
| where TimeGenerated >= start
| summarize Runs=count(), Failed=countif(Status !~ "Succeeded") by TriggerName
| order by Failed desc, Runs desc

// ==============================
// FALLBACK (if no ADF* tables): AzureDiagnostics route
// ==============================
// --- 8) ADF categories available via AzureDiagnostics ---
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.DATAFACTORY"
| summarize cnt=count() by Category
| order by cnt desc

// --- 9) SAMPLE ADF records via AzureDiagnostics (inspect columns) ---
AzureDiagnostics
| where TimeGenerated >= start
| where ResourceProvider =~ "MICROSOFT.DATAFACTORY"
| take 20