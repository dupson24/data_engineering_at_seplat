// =======================================
// CELL 3// =======================================// CELL 3: SYNAPSE SQL POOL REQUEST LOGS
let start = ago(30d);

// --- 1) HEALTH / AVAILABILITY (proves retention & ingestion) ---
SynapseSqlPoolSqlRequests
| summarize rows=count(), minTG=min(TimeGenerated), maxTG=max(TimeGenerated)

// --- 2) LATEST REQUESTS (detail) ---
SynapseSqlPoolSqlRequests
| where TimeGenerated >= start
| order by TimeGenerated desc
| take 500

// --- 3) STATUS / RESULT BREAKDOWN (adjust column if needed) ---
SynapseSqlPoolSqlRequests
| where TimeGenerated >= start
| summarize Requests=count() by Status
| order by Requests desc

// --- 4) DURATION TREND (daily) (assumes DurationMs exists) ---
SynapseSqlPoolSqlRequests
| where TimeGenerated >= start
| extend DurationSec = todouble(DurationMs)/1000.0
| summarize
    Requests=count(),
    AvgDurationSec=round(avg(DurationSec),2),
    P95DurationSec=round(percentile(DurationSec,95),2)
  by bin(TimeGenerated, 1d)
| order by TimeGenerated asc

// --- 5) TOP LONG-RUNNING REQUESTS (detail) ---
SynapseSqlPoolSqlRequests
| where TimeGenerated >= start
| extend DurationSec = todouble(DurationMs)/1000.0
| top 50 by DurationSec desc
``
// Table: SynapseSqlPoolSqlRequests
