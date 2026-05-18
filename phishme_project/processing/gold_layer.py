```python
# ============================================================
# Cell 1 — Imports & Config
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, lit, current_timestamp, to_timestamp, to_date,
    when, coalesce, upper, lower, trim, initcap,
    count, countDistinct, sum, avg, min, max,
    round as spark_round, datediff, months_between,
    row_number, dense_rank, lag
)
from pyspark.sql.types import *
from pyspark.sql.window import Window
from datetime import datetime, timezone

spark = SparkSession.builder.getOrCreate()

PROCESSED = "/mnt/PhishMe/processed"
GOLD      = "/mnt/PhishMe/gold"
RUN_DATE  = datetime.now(timezone.utc)
TODAY     = RUN_DATE.strftime("%Y-%m-%d")

def write_gold(df, name, partition_col=None):
    path = f"{GOLD}/{name}"
    w = (df.write.format("delta")
           .mode("overwrite")
           .option("overwriteSchema", "true"))
    if partition_col:
        w = w.partitionBy(partition_col)
    w.save(path)
    print(f"✅ {name} → {path}  ({df.count():,} rows)")
```

```python
# ============================================================
# Cell 2 — dim_date
# ============================================================
def build_dim_date():
    from pyspark.sql.functions import (
        explode, sequence, year, month, dayofmonth,
        dayofweek, weekofyear, quarter, date_format
    )
    dates = spark.createDataFrame([("2024-01-01", "2027-12-31")], ["start", "end"])
    df = (dates
        .select(explode(sequence(
            to_date(col("start")), to_date(col("end"))
        )).alias("date_key"))
        .withColumn("year",          year(col("date_key")))
        .withColumn("month",         month(col("date_key")))
        .withColumn("month_name",    date_format(col("date_key"), "MMMM"))
        .withColumn("month_short",   date_format(col("date_key"), "MMM"))
        .withColumn("quarter",       quarter(col("date_key")))
        .withColumn("quarter_label", date_format(col("date_key"), "'Q'Q yyyy"))
        .withColumn("week",          weekofyear(col("date_key")))
        .withColumn("day",           dayofmonth(col("date_key")))
        .withColumn("day_of_week",   dayofweek(col("date_key")))
        .withColumn("day_name",      date_format(col("date_key"), "EEEE"))
        .withColumn("is_weekend",    dayofweek(col("date_key")).isin(1, 7))
        .withColumn("yyyymm",        date_format(col("date_key"), "yyyyMM"))
    )
    write_gold(df, "dim_date")
    return df

dim_date = build_dim_date()
display(dim_date.limit(5))
```

```python
# ============================================================
# Cell 3 — dim_user  (master user record, SCIM enriched)
# ============================================================
def build_dim_user():
    users = spark.read.format("delta").load(f"{PROCESSED}/users")
    rc    = spark.read.format("delta").load(f"{PROCESSED}/repeat_clickers")
    eng   = spark.read.format("delta").load(f"{PROCESSED}/engagement_scores")

    # Base from users table
    base = (users
        .select(
            lower(trim(col("email"))).alias("email"),
            col("name"),
            col("title").alias("job_title"),
            col("phone"),
            col("time_zone"),
            col("roles"),
            col("is_active"),
            col("deactivated_at")
        )
    )

    # Enrich from repeat_clickers SCIM fields
    rc_enrich = (rc
        .select(
            lower(trim(col("email"))).alias("email"),
            col("first_name"),
            col("last_name"),
            col("department"),
            col("location"),
            col("manager"),
            col("employee_number"),
            col("user_type"),
            col("country"),
            col("division"),
            col("display_name"),
            col("time_zone").alias("time_zone_rc")
        )
    )

    # Enrich from engagement scores
    eng_enrich = (eng
        .select(
            lower(trim(col("email"))).alias("email"),
            col("proficiency_score"),
            col("susceptibility_percent"),
            col("reporting_percent"),
            col("risk_band"),
            col("proficiency_band"),
            col("scenarios_received")
        )
    )

    df = (base
        .join(rc_enrich,  "email", "left")
        .join(eng_enrich, "email", "left")
        .withColumn("display_name",
            coalesce(col("display_name"), col("name")))
        .withColumn("full_name",
            coalesce(col("name"),
                when(col("first_name").isNotNull(),
                     initcap(trim(col("first_name"))))
            ))
        .withColumn("risk_band",
            coalesce(col("risk_band"), lit("Unknown")))
        .withColumn("proficiency_band",
            coalesce(col("proficiency_band"), lit("Unknown")))
        .withColumn("is_third_party",
            col("email").startswith("3p-"))
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["email"])
    )
    write_gold(df, "dim_user")
    return df

dim_user = build_dim_user()
print("\n=== dim_user SCHEMA ===")
dim_user.printSchema()
display(dim_user.limit(5))
```

```python
# ============================================================
# Cell 4 — dim_scenario
# ============================================================
def build_dim_scenario():
    df = (spark.read.format("delta").load(f"{PROCESSED}/scenarios")
        .select(
            col("id").alias("scenario_id"),
            col("name").alias("scenario_name"),
            col("status"),
            col("scenario_type"),
            col("starts_at"),
            col("ends_at"),
            col("duration_days"),
            col("total_recipients"),
            col("emails_sent"),
            col("emails_reported"),
            col("emails_clicked"),
            col("emails_opened"),
            col("attachments_opened"),
            col("data_entered"),
            col("scenario_group_id"),
            col("scenario_group_name"),
            col("is_active"),
            # Derived metrics
            when(col("emails_sent") > 0,
                spark_round(col("emails_clicked") / col("emails_sent") * 100, 2)
            ).alias("click_rate_pct"),
            when(col("emails_sent") > 0,
                spark_round(col("emails_reported") / col("emails_sent") * 100, 2)
            ).alias("report_rate_pct"),
            when(col("emails_sent") > 0,
                spark_round(col("emails_opened") / col("emails_sent") * 100, 2)
            ).alias("open_rate_pct"),
        )
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["scenario_id"])
    )
    write_gold(df, "dim_scenario")
    return df

dim_scenario = build_dim_scenario()
print("\n=== dim_scenario SCHEMA ===")
dim_scenario.printSchema()
display(dim_scenario.limit(5))
```

```python
# ============================================================
# Cell 5 — fact_phishing_responses
# ============================================================
def build_fact_phishing_responses():
    src = spark.read.format("delta").load(f"{PROCESSED}/scenario_full_csv")

    df = (src
        .select(
            lower(trim(col("email"))).alias("email"),
            col("scenario_id"),
            col("recipient_name"),
            col("recipient_group"),
            col("department"),
            col("location"),
            col("opened_email").cast(BooleanType()),
            col("opened_email_at"),
            col("viewed_education").cast(BooleanType()),
            col("viewed_education_at"),
            col("reported_phish").cast(BooleanType()),
            col("reporter_type"),
            col("reported_phish_at"),
            col("time_to_report_secs").cast(LongType()),
            col("remote_ip"),
            col("geo_country"),
            col("geo_city"),
            col("geo_isp"),
            col("last_email_status"),
            col("is_mobile").cast(BooleanType()),
            col("browser"),
            col("ingested_date"),
        )
        # Parse timestamps
        .withColumn("opened_email_at",
            to_timestamp(col("opened_email_at"), "M/d/yyyy HH:mm:ss"))
        .withColumn("viewed_education_at",
            to_timestamp(col("viewed_education_at"), "M/d/yyyy HH:mm:ss"))
        .withColumn("reported_phish_at",
            to_timestamp(col("reported_phish_at"), "M/d/yyyy HH:mm:ss"))
        # Security metrics per row
        .withColumn("clicked_not_reported",
            col("opened_email") & ~col("reported_phish"))
        .withColumn("educated_after_click",
            col("opened_email") & col("viewed_education"))
        .withColumn("time_to_report_mins",
            when(col("time_to_report_secs").isNotNull(),
                spark_round(col("time_to_report_secs") / 60, 2)))
        .withColumn("response_category",
            when(col("reported_phish"),           lit("Reported"))
            .when(col("viewed_education"),         lit("Educated"))
            .when(col("opened_email"),             lit("Clicked"))
            .otherwise(                            lit("No Action")))
        .withColumn("ingested_at", current_timestamp())
        .filter(col("email").isNotNull())
    )
    write_gold(df, "fact_phishing_responses", partition_col="ingested_date")
    return df

fact_responses = build_fact_phishing_responses()
print("\n=== fact_phishing_responses SCHEMA ===")
fact_responses.printSchema()
display(fact_responses.limit(5))
```

```python
# ============================================================
# Cell 6 — fact_activity_timeline
# ============================================================
def build_fact_activity_timeline():
    df = (spark.read.format("delta")
        .load(f"{PROCESSED}/scenario_activity_timeline")
        .select(
            lower(trim(col("email"))).alias("email"),
            col("scenario_id"),
            col("tracking_id"),
            col("event_timestamp"),
            to_date(col("event_timestamp")).alias("event_date"),
            col("action"),
            col("recipient_group"),
            col("remote_ip"),
            col("country"),
            col("city"),
            col("isp"),
            col("browser"),
            col("user_agent"),
            col("is_mobile").cast(BooleanType()),
            col("is_email_client").cast(BooleanType()),
            col("in_ua_charts").cast(BooleanType()),
            col("ingested_date"),
        )
        # Classify action type for security analysis
        .withColumn("action_category",
            when(col("action").contains("Click"),      lit("Click"))
            .when(col("action").contains("Report"),    lit("Report"))
            .when(col("action").contains("Education"), lit("Education"))
            .when(col("action").contains("Email"),     lit("Email"))
            .when(col("action").contains("Data"),      lit("Data Entry"))
            .otherwise(                                lit("Other")))
        .withColumn("is_suspicious",
            col("action_category").isin("Click", "Data Entry"))
        .withColumn("ingested_at", current_timestamp())
        .filter(col("email").isNotNull())
    )
    write_gold(df, "fact_activity_timeline", partition_col="ingested_date")
    return df

fact_timeline = build_fact_activity_timeline()
print("\n=== fact_activity_timeline SCHEMA ===")
fact_timeline.printSchema()
display(fact_timeline.limit(5))
```

```python
# ============================================================
# Cell 7 — fact_activity_logs
# ============================================================
def build_fact_activity_logs():
    df = (spark.read.format("delta")
        .load(f"{PROCESSED}/activity_logs")
        .select(
            col("user"),
            col("activity_name"),
            col("event_timestamp"),
            to_date(col("event_timestamp")).alias("event_date"),
            col("ip_address"),
            col("ingested_date"),
        )
        .withColumn("action_type",
            when(col("activity_name").contains("In"),  lit("Login"))
            .when(col("activity_name").contains("Out"), lit("Logout"))
            .otherwise(lit("Other")))
        .withColumn("ingested_at", current_timestamp())
        .filter(col("user").isNotNull())
    )
    write_gold(df, "fact_activity_logs", partition_col="ingested_date")
    return df

fact_logs = build_fact_activity_logs()
display(fact_logs)
```

```python
# ============================================================
# Cell 8 — agg_user_risk  (Power BI ready security summary)
# ============================================================
def build_agg_user_risk():
    responses = spark.read.format("delta").load(f"{GOLD}/fact_phishing_responses")
    users     = spark.read.format("delta").load(f"{GOLD}/dim_user")

    # Per-user aggregations across all scenarios
    agg = (responses
        .groupBy("email")
        .agg(
            countDistinct("scenario_id").alias("total_scenarios"),
            count("email").alias("total_emails_received"),
            sum(col("opened_email").cast(IntegerType())).alias("total_clicks"),
            sum(col("reported_phish").cast(IntegerType())).alias("total_reports"),
            sum(col("viewed_education").cast(IntegerType())).alias("total_educated"),
            sum(col("clicked_not_reported").cast(IntegerType())).alias("clicks_not_reported"),
            avg(col("time_to_report_mins")).alias("avg_time_to_report_mins"),
            min("opened_email_at").alias("first_click_at"),
            max("opened_email_at").alias("last_click_at"),
        )
        .withColumn("click_rate_pct",
            spark_round(col("total_clicks") / col("total_emails_received") * 100, 2))
        .withColumn("report_rate_pct",
            spark_round(col("total_reports") / col("total_emails_received") * 100, 2))
        .withColumn("education_rate_pct",
            spark_round(col("total_educated") / col("total_emails_received") * 100, 2))
        .withColumn("user_risk_score",
            # Higher clicks + lower reports = higher risk
            spark_round(
                col("click_rate_pct") - (col("report_rate_pct") * 0.5), 2))
        .withColumn("user_risk_label",
            when(col("user_risk_score") >= 70, lit("Critical"))
            .when(col("user_risk_score") >= 40, lit("High"))
            .when(col("user_risk_score") >= 20, lit("Medium"))
            .otherwise(lit("Low")))
    )

    # Join with dim_user for full context
    df = (agg
        .join(users.select(
            "email", "full_name", "department", "location",
            "job_title", "manager", "country", "division",
            "is_active", "is_third_party", "risk_band",
            "proficiency_band", "proficiency_score"
        ), "email", "left")
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
    )
    write_gold(df, "agg_user_risk")
    return df

agg_user_risk = build_agg_user_risk()
print("\n=== agg_user_risk SCHEMA ===")
agg_user_risk.printSchema()
display(agg_user_risk.orderBy("user_risk_score", ascending=False).limit(20))
```

```python
# ============================================================
# Cell 9 — agg_scenario_performance  (Power BI ready)
# ============================================================
def build_agg_scenario_performance():
    responses = spark.read.format("delta").load(f"{GOLD}/fact_phishing_responses")
    scenarios = spark.read.format("delta").load(f"{GOLD}/dim_scenario")

    agg = (responses
        .groupBy("scenario_id")
        .agg(
            countDistinct("email").alias("unique_recipients"),
            sum(col("opened_email").cast(IntegerType())).alias("total_clicks"),
            sum(col("reported_phish").cast(IntegerType())).alias("total_reports"),
            sum(col("viewed_education").cast(IntegerType())).alias("total_educated"),
            sum(col("clicked_not_reported").cast(IntegerType())).alias("clicked_not_reported"),
            avg(col("time_to_report_mins")).alias("avg_time_to_report_mins"),
            countDistinct(
                when(col("response_category") == "No Action", col("email"))
            ).alias("no_action_count"),
        )
        .withColumn("click_rate_pct",
            spark_round(col("total_clicks") / col("unique_recipients") * 100, 2))
        .withColumn("report_rate_pct",
            spark_round(col("total_reports") / col("unique_recipients") * 100, 2))
        .withColumn("education_rate_pct",
            spark_round(col("total_educated") / col("unique_recipients") * 100, 2))
        .withColumn("resilience_score",
            # High reports + low clicks = high resilience
            spark_round(
                col("report_rate_pct") - (col("click_rate_pct") * 0.5), 2))
    )

    df = (agg
        .join(scenarios.select(
            "scenario_id", "scenario_name", "scenario_type",
            "starts_at", "ends_at", "duration_days", "status"
        ), "scenario_id", "left")
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
    )
    write_gold(df, "agg_scenario_performance")
    return df

agg_scenario = build_agg_scenario_performance()
print("\n=== agg_scenario_performance SCHEMA ===")
agg_scenario.printSchema()
display(agg_scenario.orderBy("click_rate_pct", ascending=False))
```

```python
# ============================================================
# Cell 10 — agg_department_risk  (Power BI ready)
# ============================================================
def build_agg_department_risk():
    user_risk = spark.read.format("delta").load(f"{GOLD}/agg_user_risk")

    df = (user_risk
        .filter(col("department").isNotNull())
        .groupBy("department")
        .agg(
            countDistinct("email").alias("total_users"),
            spark_round(avg("click_rate_pct"), 2).alias("avg_click_rate_pct"),
            spark_round(avg("report_rate_pct"), 2).alias("avg_report_rate_pct"),
            spark_round(avg("education_rate_pct"), 2).alias("avg_education_rate_pct"),
            spark_round(avg("user_risk_score"), 2).alias("avg_risk_score"),
            count(when(col("user_risk_label") == "Critical", True)).alias("critical_users"),
            count(when(col("user_risk_label") == "High",     True)).alias("high_risk_users"),
            count(when(col("user_risk_label") == "Medium",   True)).alias("medium_risk_users"),
            count(when(col("user_risk_label") == "Low",      True)).alias("low_risk_users"),
        )
        .withColumn("dept_risk_label",
            when(col("avg_risk_score") >= 70, lit("Critical"))
            .when(col("avg_risk_score") >= 40, lit("High"))
            .when(col("avg_risk_score") >= 20, lit("Medium"))
            .otherwise(lit("Low")))
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .orderBy("avg_risk_score", ascending=False)
    )
    write_gold(df, "agg_department_risk")
    return df

agg_dept = build_agg_department_risk()
display(agg_dept)
```

```python
# ============================================================
# Cell 11 — agg_monthly_trend  (Power BI time series)
# ============================================================
def build_agg_monthly_trend():
    timeline = spark.read.format("delta").load(f"{GOLD}/fact_activity_timeline")

    df = (timeline
        .filter(col("event_timestamp").isNotNull())
        .withColumn("year",  col("event_timestamp").cast("string").substr(1, 4))
        .withColumn("month", col("event_timestamp").cast("string").substr(6, 2))
        .withColumn("yyyymm", col("event_timestamp").cast("string").substr(1, 7))
        .groupBy("yyyymm", "year", "month", "scenario_id")
        .agg(
            countDistinct("email").alias("unique_users"),
            count("tracking_id").alias("total_events"),
            count(when(col("action_category") == "Click",      True)).alias("clicks"),
            count(when(col("action_category") == "Report",     True)).alias("reports"),
            count(when(col("action_category") == "Education",  True)).alias("educations"),
            count(when(col("action_category") == "Data Entry", True)).alias("data_entries"),
            count(when(col("is_suspicious"),                   True)).alias("suspicious_events"),
        )
        .withColumn("click_to_report_ratio",
            when(col("reports") > 0,
                spark_round(col("clicks") / col("reports"), 2)
            ).otherwise(lit(None)))
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .orderBy("yyyymm", "scenario_id")
    )
    write_gold(df, "agg_monthly_trend")
    return df

agg_trend = build_agg_monthly_trend()
display(agg_trend)
```

```python
# ============================================================
# Cell 12 — Final Summary
# ============================================================
print("=" * 60)
print("GOLD LAYER BUILD COMPLETE")
print("=" * 60)

gold_tables = [
    "dim_date", "dim_user", "dim_scenario",
    "fact_phishing_responses", "fact_activity_timeline", "fact_activity_logs",
    "agg_user_risk", "agg_scenario_performance",
    "agg_department_risk", "agg_monthly_trend"
]

for t in gold_tables:
    try:
        df = spark.read.format("delta").load(f"{GOLD}/{t}")
        print(f"  ✅ {t:<35} {df.count():>8,} rows")
    except Exception as e:
        print(f"  ❌ {t}: {e}")

print("=" * 60)
print(f"Power BI source path: /mnt/PhishMe/gold/")
print("=" * 60)
```

# **Gold layer tables ready for Power BI:**

# | Table | Type | Key metric |
# |---|---|---|
# | `dim_user` | Dimension | User master with risk bands |
# | `dim_scenario` | Dimension | Scenario metadata + rates |
# | `dim_date` | Dimension | Time intelligence |
# | `fact_phishing_responses` | Fact | Per-user per-scenario events |
# | `fact_activity_timeline` | Fact | Granular action events |
# | `fact_activity_logs` | Fact | Admin audit trail |
# | `agg_user_risk` | Aggregate | User risk scores + labels |
# | `agg_scenario_performance` | Aggregate | Resilience scores per scenario |
# | `agg_department_risk` | Aggregate | Dept-level risk breakdown |
# | `agg_monthly_trend` | Aggregate | Time series for trending |