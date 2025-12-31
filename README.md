# 🏥 Healthcare Insurance Analytics Platform (MS SQL Server + Power BI)

## 📌 Project Overview

This project demonstrates an **end-to-end Business Intelligence (BI) data pipeline** built using **MS SQL Server** and designed for **analytical reporting and visualization in Power BI**.

The solution covers the complete lifecycle:

* Raw data ingestion
* Data validation & cleansing
* OLTP system design
* Data warehouse (OLAP) star schema modeling
* Analytics-ready data for BI tools

The project is intentionally structured to mirror **real-world enterprise BI systems**.

---

## 📊 Data Source

* **Dataset:** Kaggle – Healthcare Insurance Dataset
* **Records:** 1338 rows
* **Attributes:** age, sex, bmi, children, smoker, region, insurance charges

---

## 🏗️ Architecture Overview

```
CSV (Kaggle)
   ↓
STAGING (hi_stg)
   ↓
OLTP (hi_oltp)
   ↓
DATA WAREHOUSE / OLAP (hi_dw)
   ↓
Power BI (Visualization & Insights)
```

---

## 1️⃣ Staging Layer (Raw Data Ingestion)

### Purpose

* Safely ingest raw CSV data
* Preserve original structure
* Avoid early transformations

### Key Features

* Implemented using **BULK INSERT**
* Custom **format file** to handle column order and data types
* Encoding and CR/LF issues handled
* Data treated as **read-only source**

### Verification

* Rows loaded: **1338**
* Column alignment verified
* No data loss

---

## 2️⃣ OLTP Layer (Validated Transactional Model)

### Purpose

* Store clean, validated, structured data
* Enforce data quality rules
* Act as the system of record

### Design Highlights

* Fully normalized schema
* Tables:

  * `person`
  * `health_profile`
  * `insurance_policy`
  * `policy_charge`
* Strong **constraints** (CHECK, FK)
* **Indexes** for query optimization
* **Staging lineage (`stg_row_id`)** for traceability

### ETL Highlights

* Defensive ETL using `TRY_CONVERT`
* CR/LF cleansing for numeric fields
* Reject logging for invalid rows
* Rerunnable ETL logic

### Results

* OLTP persons: **1338**
* Policies: **1338**
* Charges: **1338**
* Rejected rows: **0**

---

## 3️⃣ Data Warehouse (OLAP – Star Schema)

### Purpose

* Enable fast analytical queries
* Power BI–ready dimensional model

### Star Schema Design

**Dimensions**

* `dim_person`
* `dim_region`
* `dim_sex`
* `dim_smoker`
* `dim_date`

**Fact Table**

* `fact_insurance_charge`

  * Grain: **1 row per policy**

### ETL Highlights

* OLTP → DW transformation
* SCD Type-1 handling for person dimension
* Deterministic reload strategy for facts
* Date dimension generated dynamically

### Results

* Dimension rows: **1338**
* Fact rows: **1338**

---

## 🔍 Sample Analytical Insight (SQL)

```sql
SELECT
    r.region,
    s.sex,
    sm.smoker,
    AVG(f.annual_charge) AS avg_charge
FROM hi_dw.fact_insurance_charge f
JOIN hi_dw.dim_person p ON p.person_key = f.person_key
JOIN hi_dw.dim_region r ON r.region_key = p.region_key
JOIN hi_dw.dim_sex s ON s.sex_key = p.sex_key
JOIN hi_dw.dim_smoker sm ON sm.smoker_key = p.smoker_key
GROUP BY r.region, s.sex, sm.smoker
ORDER BY avg_charge DESC;
```

**Insight example:**
Smokers consistently show **significantly higher insurance charges**, with regional and gender variations.

---

## 🧰 Technologies Used

* **Database:** MS SQL Server
* **ETL:** T-SQL (BULK INSERT, MERGE, validation logic)
* **Modeling:** OLTP + Star Schema (OLAP)
* **Version Control:** Git / GitHub
* **Visualization:** Power BI (next phase)

---

## 🚀 Next Steps

* Power BI semantic model
* DAX measures (average cost, smoker impact, trends)
* Interactive dashboards & slicers
* Final portfolio screenshots

---

## 📁 Repository Structure

```
/sql
  01_staging.sql
  02_oltp_schema.sql
  03_etl_stg_to_oltp.sql
  04_dw_schema.sql
  05_etl_oltp_to_dw.sql

/data
  (ignored – raw CSV files)

README.md
```

---

## ⭐ Why This Project Matters

This project demonstrates:

* Real-world data engineering problem solving
* Strong SQL & BI fundamentals
* Production-grade ETL practices
* Clear separation of OLTP vs OLAP workloads

It is designed to align with **BI Analyst, SQL Developer, and Data Analyst roles**.
