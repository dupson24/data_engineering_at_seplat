// ==================================
// CELL 2: SQL GOVERNANCE AUDIT (30d)
// Tables: SQLSecurityAuditEvents
// Columns confirmed: Statement (string), Succeeded (bool), ClientIp (string), LogicalServerName etc.
// ==================================
let start = ago(30d);

// --- 1) EVIDENCE EXTRACT (detail, governance appendix) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| project
    TimeGenerated, EventTime,
    LogicalServerName, ResourceGroup, Category,
    ActionId, AuditSchemaVersion, SequenceNumber,
    ClientIp, Succeeded, Statement,
    _ResourceId, TenantId
| order by TimeGenerated desc
| take 1000

// --- 2) EXEC SUMMARY KPIs ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| summarize
    TotalEvents=count(),
    Success=countif(Succeeded==true),
    Failed=countif(Succeeded==false),
    SuccessRatePct=round(100.0*countif(Succeeded)/count(),2),
    UniqueIPs=dcount(ClientIp),
    DistinctStatements=dcount(Statement),
    FirstEvent=min(TimeGenerated),
    LastEvent=max(TimeGenerated)

// --- 3) DAILY TREND (Total vs Failed vs Unique IPs) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| summarize
    Total=count(),
    Failed=countif(Succeeded==false),
    UniqueIPs=dcount(ClientIp)
  by bin(TimeGenerated, 1d)
| order by TimeGenerated asc

// --- 4) ACTION BREAKDOWN + FAIL RATE ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| summarize
    Events=count(),
    Failed=countif(Succeeded==false),
    FailRatePct=round(100.0*countif(Succeeded==false)/count(),2)
  by ActionId
| order by Failed desc, Events desc

// --- 5) STATEMENT CLASSIFICATION (Read/Write/DDL/Security) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| extend stmt = trim_start(@" \t\r\n", tostring(Statement))
| extend s = tolower(stmt)
| extend StatementType = case(
    s startswith "select", "SELECT (Read)",
    s startswith "insert" or s startswith "update" or s startswith "delete" or s startswith "merge", "DML (Write)",
    s startswith "create" or s startswith "alter" or s startswith "drop", "DDL (Schema Change)",
    s startswith "grant" or s startswith "revoke" or s startswith "deny", "Security/Permissions",
    "Other/Unknown"
)
| summarize
    Events=count(),
    Failed=countif(Succeeded==false),
    UniqueIPs=dcount(ClientIp)
  by StatementType
| order by Events desc

// --- 6) HIGH-RISK: PERMISSIONS CHANGES (GRANT/REVOKE/DENY) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| extend s = tolower(tostring(Statement))
| where s startswith "grant" or s startswith "revoke" or s startswith "deny"
| project TimeGenerated, LogicalServerName, ClientIp, ActionId, Succeeded, Statement
| order by TimeGenerated desc
| take 500

// --- 7) HIGH-RISK: SCHEMA CHANGES (CREATE/ALTER/DROP) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start
| extend s = tolower(tostring(Statement))
| where s startswith "create" or s startswith "alter" or s startswith "drop"
| project TimeGenerated, LogicalServerName, ClientIp, ActionId, Succeeded, Statement
| order by TimeGenerated desc
| take 500

// --- 8) TOP FAILED IPs (security hotspot) ---
SQLSecurityAuditEvents
| where TimeGenerated >= start and Succeeded==false
| summarize Failures=count(), Actions=make_set(ActionId, 20) by ClientIp
| order by Failures desc
| take 50

// --- 9) NEW IPs (seen last 7d but not in prior 23d) ---
let baseline = 30d;
let recent = 7d;
let baselineIPs =
    SQLSecurityAuditEvents
    | where TimeGenerated between (ago(baseline) .. ago(recent))
    | summarize by ClientIp;
SQLSecurityAuditEvents
| where TimeGenerated >= ago(recent)
| join kind=leftanti baselineIPs on ClientIp
| summarize Events=count(), Failed=countif(Succeeded==false) by ClientIp
| order by Events desc
