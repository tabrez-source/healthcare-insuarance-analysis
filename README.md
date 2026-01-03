# Healthcare Insurance Analytics Platform (MS SQL Server + Power BI)

## Project Overview

This project demonstrates an end-to-end Business Intelligence (BI) data pipeline built using Microsoft SQL Server and designed for analytical reporting and visualization in Power BI.

The solution covers the complete lifecycle:

- Raw data ingestion
- Data validation and cleansing
- OLTP system design
- Data warehouse (OLAP) star schema modeling
- Analytics-ready data for BI tools

The project is intentionally structured to mirror real-world enterprise BI systems.

---

## Data Source

- **Dataset:** Kaggle – Healthcare Insurance Dataset  
- **Records:** 1,338 rows  
- **Attributes:** age, sex, bmi, children, smoker, region, insurance charges  

---

## Architecture Overview

CSV (Kaggle)
↓
Staging Layer (hi_stg)
↓
OLTP Layer (hi_oltp)
↓
Data Warehouse / OLAP (hi_dw)
↓
Power BI (Visualization & Insights)

---

## 1. Staging Layer (Raw Data Ingestion)

### Purpose

- Safely ingest raw CSV data
- Preserve original structure
- Avoid early transformations

### Key Features

- Implemented using `BULK INSERT`
- Custom format file to handle column order and data types
- Encoding and CR/LF issues handled explicitly
- Data treated as a read-only source

### Verification

- Rows loaded: **1,338**
- Column alignment verified
- No data loss

---

## 2. OLTP Layer (Validated Transactional Model)

### Purpose

- Store clean, validated, structured data
- Enforce data quality rules
- Act as the system of record

### Design Highlights

- Fully normalized schema
- Tables:
  - `person`
  - `health_profile`
  - `insurance_policy`
  - `policy_charge`
- Strong constraints (CHECK, foreign keys)
- Indexes for query optimization
- Staging lineage (`stg_row_id`) for traceability

### ETL Highlights

- Defensive ETL using `TRY_CONVERT`
- CR/LF cleansing for numeric fields
- Reject logging for invalid rows
- Fully rerunnable ETL logic

### Results

- OLTP persons: **1,338**
- Policies: **1,338**
- Charges: **1,338**
- Rejected rows: **0**

---

## 3. Data Warehouse (OLAP – Star Schema)

### Purpose

- Enable fast analytical queries
- Provide a Power BI–ready dimensional model

### Star Schema Design

**Dimensions**

- `dim_person`
- `dim_region`
- `dim_sex`
- `dim_smoker`
- `dim_date`

**Fact Table**

- `fact_insurance_charge`  
- Grain: **one row per policy**

### ETL Highlights

- OLTP to DW transformation
- Type-1 slowly changing dimension handling
- Deterministic reload strategy for fact data
- Date dimension generated dynamically

### Results

- Dimension rows: **1,338**
- Fact rows: **1,338**

---

## Sample Analytical Insight (SQL)

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
Smokers consistently show significantly higher insurance charges, with variation across regions and genders.

---

## Technologies Used

- **Database:** Microsoft SQL Server
- **ETL:** T-SQL (BULK INSERT, MERGE, validation logic)
- **Modeling:** OLTP and Star Schema (OLAP)
- **Version Control:** Git, GitHub
- **Visualization:** Power BI

---

## Power BI Dashboards

This project includes an interactive Power BI report built on top of the SQL Server data warehouse.

### Executive Overview

- Key KPIs including Average Charge and Smoker Premium (absolute and percentage)
- Regional and demographic cost comparisons
- Interactive slicers for region, sex, smoker status, and year

### Smoker Impact Analysis

- Direct comparison of smoker versus non-smoker costs
- Regional and gender-based smoker cost breakdown
- Clear identification of smoking as the primary insurance cost driver

---

## Key Business Insights

- Smokers incur approximately three times higher insurance charges than non-smokers
- Average smoker premium is approximately **$23,000**
- Smoking impact outweighs both gender and regional cost differences
- Southeast and Southwest regions exhibit the highest average charges

---

## Skills Demonstrated

- SQL Server OLTP and OLAP design
- Data validation and ETL pipeline development
- Star schema modeling for analytics
- DAX measures and Power BI data modeling
- Business-focused analytical storytelling

---

## Repository Structure

/sql
01_staging.sql
02_oltp_schema.sql
03_etl_stg_to_oltp.sql
04_dw_schema.sql
05_etl_oltp_to_dw.sql

/data
(ignored – raw CSV files)

/powerbi
powerbi-executive-overview.png
powerbi-smoker-impact.png

.gitignore

README.md

---

## Why This Project Matters

This project demonstrates:

- Real-world data engineering and BI problem solving
- Strong SQL and dimensional modeling fundamentals
- Production-grade ETL practices
- Clear separation of OLTP and OLAP workloads

It is designed to align with **BI Analyst, SQL Developer, and Data Analyst roles in enterprise environments**.
