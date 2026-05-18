# ============================================================
# SEPLAT ENERGY — PhishMe Power BI Report Specification
# Page-by-page build guide for Power BI Desktop
# ============================================================

## REPORT SETTINGS
- Canvas size     : 1440 × 900 (Widescreen 16:9)
- Theme           : Dark (custom JSON below)
- Font            : Segoe UI / Segoe UI Semibold
- Accent color    : #00C2FF
- Background      : #07090F
- Data source     : Azure Databricks — /mnt/PhishMe/gold/

---

## PAGE 1 — Executive Overview

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Security Health Index | Card | — | Security Health Index |
| Overall Click Rate | Card | — | Click Rate % |
| Report Rate | Card | — | Report Rate % |
| High/Critical Users | Card | — | High Risk Users |
| Repeat Clickers | Card | — | Repeat Clickers |
| Avg Time to Report | Card | — | Avg Time to Report (mins) |
| Click vs Report Trend | Line Chart | dim_date[yyyymm] X-axis | Click Rate % MTD, Report Rate % MTD |
| Response Distribution | Donut | fact_phishing_responses[response_category] | Count of email |
| Dept Click Rate | Bar Chart | dim_user[department] | Click Rate % |
| Scenario Summary | Table | dim_scenario[scenario_name, scenario_type] | Click Rate %, Report Rate %, Resilience Score |

### Slicers
- dim_date[year], dim_date[quarter_label]
- dim_scenario[scenario_type]
- dim_user[is_active]

### Conditional Formatting
- Click Rate % card: Red if >30%, Amber if 15–30%, Green if <15%
- Report Rate % card: Green if >30%, Amber if 15–30%, Red if <15%
- Security Health Index card: Green if >70, Amber if 40–70, Red if <40

---

## PAGE 2 — User Risk Analysis

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Critical Risk Users | Card | — | Critical Risk Users |
| High Risk Users | Card | — | High Risk Users |
| Repeat Clickers | Card | — | Repeat Clickers |
| Avg Proficiency Score | Card | — | Avg Proficiency Score |
| Risk Band Distribution | Stacked Bar | agg_user_risk[user_risk_label] | Count of email |
| Susceptibility Distribution | Donut | dim_user[risk_band] | Count of email |
| High Risk Users Table | Table | agg_user_risk[email, department, total_clicks, total_reports, user_risk_score, user_risk_label] | — |
| Proficiency vs Susceptibility | Scatter | X: susceptibility_percent, Y: proficiency_score, Size: total_clicks | — |
| Top 10 Repeat Clickers | Bar | agg_user_risk[email] | Total Clicks |

### Slicers
- agg_user_risk[user_risk_label]
- dim_user[department]
- dim_user[is_third_party]
- dim_user[is_active]

### Drill-through
- Right-click any user row → drill-through to user detail page
- Detail page shows: all scenarios received, click/report per scenario, timeline of events

### Conditional Formatting (table)
- user_risk_label: Red=Critical, Amber=High, Blue=Medium, Green=Low (using Risk Label Color measure)
- user_risk_score: Data bar, Red gradient

---

## PAGE 3 — Scenario Performance

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Most Clicked Scenario | Card (text) | — | Most Clicked Scenario |
| Best Reported Scenario | Card (text) | — | Best Reported Scenario |
| Avg Resilience Score | Card | — | Avg Scenario Resilience |
| Scenario Matrix | Table | dim_scenario[scenario_name, scenario_type, status] | Click Rate %, Report Rate %, Education Rate %, Resilience Score |
| Click Rate by Type | Bar | dim_scenario[scenario_type] | Click Rate % |
| Resilience by Scenario | Bar | dim_scenario[scenario_name] | Resilience Score |
| Recipient Heatmap | Matrix | Rows: dim_user[department], Cols: dim_scenario[scenario_name] | Click Rate % |
| Time to Report Distribution | Histogram | fact_phishing_responses[time_to_report_mins] | — |

### Slicers
- dim_scenario[scenario_type]
- dim_scenario[status]
- dim_date[year], dim_date[quarter_label]

### Conditional Formatting (Resilience Score bar)
- Positive values: Green (#00E5A0)
- Negative values: Red (#FF3B5C)
- Reference line at 0

---

## PAGE 4 — Department Analysis

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Highest Risk Dept | Card (text) | — | Highest Risk Department |
| Dept Scorecard | Table | agg_department_risk[department, total_users, avg_click_rate_pct, avg_report_rate_pct, critical_users, high_risk_users, dept_risk_label] | Dept vs Org Click Rate |
| Click vs Report by Dept | Clustered Bar | dim_user[department] | Click Rate %, Report Rate % |
| Dept Risk Treemap | Treemap | dim_user[department] | High Risk Users (size), Avg Org Risk Score (color) |
| Critical Users by Dept | Stacked Bar | dim_user[department] | Count by user_risk_label |

### Slicers
- dim_user[department]
- agg_department_risk[dept_risk_label]

### Conditional Formatting (scorecard table)
- avg_click_rate_pct: Red > 50%, Amber 25–50%, Green < 25%
- dept_risk_label: background color by risk (Critical=Red, High=Amber, Medium=Blue, Low=Green)

---

## PAGE 5 — Trend Analysis

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Click Rate MoM | Card | — | Click Rate % vs Prior Month |
| Report Rate MoM | Card | — | Report Rate % vs Prior Month |
| Health Index MoM | Card | — | Security Health Index vs Prior Month |
| Rolling 3M Click | Card | — | Rolling 3M Click Rate % |
| Monthly Metrics Table | Table | agg_monthly_trend[yyyymm] | Click Rate % MTD, Report Rate % MTD, Security Health Index, MoM Click Change Label |
| 6-Month Trend | Line+Clustered | dim_date[yyyymm] | Click Rate % MTD, Report Rate % MTD, Security Health Index |
| Click to Report Ratio | Line | agg_monthly_trend[yyyymm] | click_to_report_ratio |
| Suspicious Events Trend | Area | agg_monthly_trend[yyyymm] | suspicious_events |

### Reference Lines
- Click Rate % chart: constant line at 20% (target threshold)
- Report Rate % chart: constant line at 30% (target threshold)
- Security Health Index chart: constant line at 70 (target)

---

## PAGE 6 — Activity Logs

### Visuals
| Visual | Type | Fields | DAX Measure |
|--------|------|--------|-------------|
| Total Events | Card | — | Count of fact_activity_logs rows |
| Unique Admins | Card | — | CountDistinct fact_activity_logs[user] |
| Last Login | Card (text) | — | Max event_timestamp where action_type = Login |
| Events Table | Table | fact_activity_logs[event_timestamp, user, activity_name, action_type, ip_address] | — |
| Events by Day | Bar | fact_activity_logs[event_date] | Count of events |
| Login by IP | Bar | fact_activity_logs[ip_address] | Count where action_type = Login |

### Slicers
- fact_activity_logs[action_type]
- dim_date[date_key] (date range picker)
- fact_activity_logs[user]

---

## CUSTOM THEME JSON (paste into Power BI: View → Themes → Browse)

{
  "name": "Seplat PhishMe Dark",
  "dataColors": ["#00C2FF","#00E5A0","#FF3B5C","#FFB300","#A855F7","#FF6B6B","#0077FF","#4A5D7A"],
  "background": "#07090F",
  "foreground": "#E8EDF5",
  "tableAccent": "#00C2FF",
  "visualStyles": {
    "*": {
      "*": {
        "background": [{"color": {"solid": {"color": "#0D1117"}}}],
        "border": [{"color": {"solid": {"color": "#1E2D45"}}}],
        "fontFamily": [{"fontFamily": "Segoe UI"}]
      }
    },
    "card": {
      "*": {
        "calloutValue": [{"fontSize": 32, "fontBold": true, "color": {"solid": {"color": "#E8EDF5"}}}],
        "label": [{"fontSize": 10, "color": {"solid": {"color": "#8A9BB5"}}}]
      }
    }
  }
}

---

## POWER BI GATEWAY SETUP (Databricks connection)

1. Power BI Desktop → Get Data → Azure Databricks
2. Server hostname : <your-workspace>.azuredatabricks.net
3. HTTP path      : /sql/1.0/warehouses/<warehouse-id>
4. Auth           : Azure Active Directory (SSO) or Personal Access Token
5. Tables to import:
   - gold.dim_user
   - gold.dim_scenario
   - gold.dim_date
   - gold.fact_phishing_responses
   - gold.fact_activity_timeline
   - gold.fact_activity_logs
   - gold.agg_user_risk
   - gold.agg_scenario_performance
   - gold.agg_department_risk
   - gold.agg_monthly_trend
6. Import mode    : DirectQuery (recommended for live data)
7. Refresh schedule: Daily 03:00 UTC (1 hour after gold layer build)

---

## ROW LEVEL SECURITY (RLS)

Create these roles in Power BI Desktop (Modeling → Manage Roles):

Role: Department_Manager
  Table: dim_user
  Filter: [department] = USERPRINCIPALNAME()   ← map AD group to department

Role: CISO
  Table: dim_user
  Filter: (none — full access)

Role: Security_Analyst
  Table: dim_user
  Filter: (none — full access, read-only)

Role: Department_Head
  Table: dim_user
  Filter: [department] = LOOKUPVALUE(dept_mapping[department], dept_mapping[email], USERPRINCIPALNAME())
