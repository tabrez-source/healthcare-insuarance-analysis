1. Project Overview

This project implements an end-to-end Business Intelligence (BI) and Analytics platform using Microsoft SQL Server and Power BI, designed to reflect real-world enterprise data architectures.

The solution demonstrates the complete analytical data lifecycle—from raw data ingestion to executive-level reporting—using industry-standard modeling, validation, and visualization practices.

The primary objective of this project is to showcase strong SQL, data modeling, ETL, and BI capabilities aligned with BI Analyst, SQL Developer, and Data Analyst roles.

2. Data Source

Source: Kaggle – Healthcare Insurance Dataset

Records: 1,338

Attributes:

Age

Sex

BMI

Number of Children

Smoker Status

Region

Insurance Charges

3. Architecture Overview
CSV Source (Kaggle)
        ↓
Staging Layer (hi_stg)
        ↓
OLTP Layer (hi_oltp)
        ↓
Data Warehouse / OLAP (hi_dw)
        ↓
Power BI Dashboards

4. Staging Layer (Raw Data Ingestion)
Purpose

Ingest raw CSV data without transformation

Preserve source integrity

Isolate ingestion errors from downstream systems

Implementation

BULK INSERT with a custom format file

Explicit handling of encoding and CR/LF issues

All columns stored as text to avoid early type failures

Validation

Rows loaded: 1,338

Column alignment verified

Zero data loss during ingestion

5. OLTP Layer (Validated Transactional Model)
Purpose

Act as the system of record

Enforce business rules and data quality

Support downstream analytical workloads

Schema Design

Normalized OLTP schema consisting of:

person

health_profile

insurance_policy

policy_charge

Key Features

Strong CHECK constraints and foreign keys

Indexed columns for performance

Staging lineage via stg_row_id

Referential integrity with cascade rules

ETL Characteristics

Defensive transformations using TRY_CONVERT

Explicit validation rules for all attributes

Reject logging for invalid records

Fully rerunnable ETL scripts

Results

Persons loaded: 1,338

Policies created: 1,338

Charges recorded: 1,338

Rejected rows: 0

6. Data Warehouse (OLAP – Star Schema)
Purpose

Enable high-performance analytical queries

Provide a Power BI–optimized semantic layer

Dimensional Model

Dimensions

dim_person

dim_region

dim_sex

dim_smoker

dim_date

Fact Table

fact_insurance_charge

Grain: one row per insurance policy

ETL Strategy

Deterministic OLTP → DW transformations

Type-1 slowly changing dimensions

Dynamically generated date dimension

Clean separation between transactional and analytical workloads

Results

Dimension rows: 1,338

Fact rows: 1,338

7. Sample Analytical Query (SQL)
SELECT
    r.region,
    s.sex,
    sm.smoker,
    AVG(f.annual_charge) AS avg_charge
FROM hi_dw.fact_insurance_charge f
JOIN hi_dw.dim_person p   ON p.person_key = f.person_key
JOIN hi_dw.dim_region r   ON r.region_key = p.region_key
JOIN hi_dw.dim_sex s      ON s.sex_key = p.sex_key
JOIN hi_dw.dim_smoker sm  ON sm.smoker_key = p.smoker_key
GROUP BY r.region, s.sex, sm.smoker
ORDER BY avg_charge DESC;

Key Insight:
Smoking status is the dominant cost driver across all regions and demographics.

8. Power BI Dashboards

An interactive Power BI report was built directly on top of the SQL Server data warehouse.

Executive Overview

Overall Average Insurance Charge

Smoker vs Non-Smoker comparison

Regional and demographic cost distribution

Interactive slicers for region, sex, smoker status, and year

Smoker Impact Analysis

Direct smoker vs non-smoker cost comparison

Regional smoker cost breakdown

Gender-based smoker analysis

Reinforcement of smoker premium impact

9. Business Insights

Smokers incur approximately three times higher insurance charges than non-smokers

Average smoker premium is approximately $23,000

Smoking impact outweighs both gender and regional cost differences

Southeast and Southwest regions exhibit the highest average charges

10. Technologies Used

Database: Microsoft SQL Server

ETL & Validation: T-SQL (BULK INSERT, MERGE, constraints)

Modeling: OLTP and Star Schema (OLAP)

BI & Analytics: Power BI, DAX

Version Control: Git, GitHub

11. Repository Structure
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

12. Why This Project Matters

This project demonstrates:

Real-world data engineering and BI workflows

Strong SQL and dimensional modeling fundamentals

Production-grade ETL and validation techniques

Clear separation of OLTP and OLAP systems

Business-focused analytical storytelling

The design and implementation closely align with expectations for BI Analyst, SQL Developer, and Data Analyst roles in enterprise environments.