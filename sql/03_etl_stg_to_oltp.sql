/* =========================================================
   STEP 2B: ETL STAGING -> OLTP (validated + reject logging)
   ========================================================= */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='hi_etl')
    EXEC('CREATE SCHEMA hi_etl');
GO

IF OBJECT_ID('hi_etl.insurance_rejects','U') IS NOT NULL
    DROP TABLE hi_etl.insurance_rejects;
GO

CREATE TABLE hi_etl.insurance_rejects (
    reject_id     INT IDENTITY(1,1) PRIMARY KEY,
    row_id        INT NOT NULL,
    reject_reason VARCHAR(4000) NOT NULL,
    rejected_at   DATETIME2(0) NOT NULL CONSTRAINT DF_reject_at DEFAULT (SYSUTCDATETIME())
);
GO

-- Build validated temp dataset
IF OBJECT_ID('tempdb..#val') IS NOT NULL DROP TABLE #val;

SELECT
    r.row_id,

    TRY_CONVERT(INT,
        REPLACE(REPLACE(LTRIM(RTRIM(r.age)), CHAR(13), ''), CHAR(10), '')
    ) AS age_i,

    LOWER(LTRIM(RTRIM(r.sex))) AS sex_txt,

    TRY_CONVERT(DECIMAL(5,2),
        REPLACE(REPLACE(LTRIM(RTRIM(r.bmi)), CHAR(13), ''), CHAR(10), '')
    ) AS bmi_d,

    TRY_CONVERT(INT,
        REPLACE(REPLACE(LTRIM(RTRIM(r.children)), CHAR(13), ''), CHAR(10), '')
    ) AS children_i,

    LOWER(LTRIM(RTRIM(r.smoker))) AS smoker_txt,
    LOWER(LTRIM(RTRIM(r.region))) AS region_txt,

    TRY_CONVERT(DECIMAL(12,2),
        REPLACE(REPLACE(LTRIM(RTRIM(r.charges)), CHAR(13), ''), CHAR(10), '')
    ) AS charges_d,

    CAST(NULL AS VARCHAR(4000)) AS reject_reason
INTO #val
FROM hi_stg.insurance_raw r;


-- Validation rules
UPDATE v
SET reject_reason =
  CASE
    WHEN age_i IS NULL THEN 'age not numeric'
    WHEN age_i NOT BETWEEN 0 AND 120 THEN 'age out of range'
    WHEN sex_txt NOT IN ('male','female') THEN 'invalid sex'
    WHEN bmi_d IS NULL THEN 'bmi not numeric'
    WHEN bmi_d NOT BETWEEN 10 AND 80 THEN 'bmi out of range'
    WHEN children_i IS NULL THEN 'children not numeric'
    WHEN children_i NOT BETWEEN 0 AND 20 THEN 'children out of range'
    WHEN smoker_txt NOT IN ('yes','no') THEN 'invalid smoker'
    WHEN region_txt NOT IN ('northeast','northwest','southeast','southwest') THEN 'invalid region'
    WHEN charges_d IS NULL THEN 'charges not numeric'
    WHEN charges_d < 0 THEN 'charges negative'
    ELSE NULL
  END
FROM #val v;

-- Log rejects
INSERT INTO hi_etl.insurance_rejects (row_id, reject_reason)
SELECT row_id, reject_reason
FROM #val
WHERE reject_reason IS NOT NULL;

-- Reset OLTP (child -> parent)
DELETE FROM hi_oltp.policy_charge;
DELETE FROM hi_oltp.insurance_policy;
DELETE FROM hi_oltp.health_profile;
DELETE FROM hi_oltp.person;

-- Insert persons (only valid) WITH staging lineage id
INSERT INTO hi_oltp.person (age, sex, region, children, stg_row_id)
SELECT v.age_i, v.sex_txt, v.region_txt, v.children_i, v.row_id
FROM #val v
WHERE v.reject_reason IS NULL;

-- Build map staging row -> person_id using stg_row_id
IF OBJECT_ID('tempdb..#map_person') IS NOT NULL DROP TABLE #map_person;
CREATE TABLE #map_person (
    row_id INT PRIMARY KEY,
    person_id INT NOT NULL
);

INSERT INTO #map_person (row_id, person_id)
SELECT p.stg_row_id, p.person_id
FROM hi_oltp.person p
WHERE p.stg_row_id IS NOT NULL;

-- Insert health_profile (1:1)
INSERT INTO hi_oltp.health_profile (person_id, bmi, smoker)
SELECT m.person_id, v.bmi_d, v.smoker_txt
FROM #map_person m
JOIN #val v ON v.row_id = m.row_id;

-- Insert policies (synthetic)
DECLARE @policyStart DATE = '2024-01-01';

INSERT INTO hi_oltp.insurance_policy (person_id, policy_number, policy_start_dt, policy_status)
SELECT
  m.person_id,
  CONCAT('POL-', RIGHT(CONCAT('000000', m.person_id), 6)),
  DATEADD(DAY, (m.person_id % 365), @policyStart),
  'active'
FROM #map_person m;

-- Insert charges
INSERT INTO hi_oltp.policy_charge (policy_id, annual_charge)
SELECT p.policy_id, v.charges_d
FROM hi_oltp.insurance_policy p
JOIN #map_person m ON m.person_id = p.person_id
JOIN #val v ON v.row_id = m.row_id;

-- Results
SELECT COUNT(*) AS oltp_persons  FROM hi_oltp.person;
SELECT COUNT(*) AS oltp_policies FROM hi_oltp.insurance_policy;
SELECT COUNT(*) AS oltp_charges  FROM hi_oltp.policy_charge;
SELECT COUNT(*) AS rejected_rows FROM hi_etl.insurance_rejects;

SELECT TOP 10 * FROM hi_etl.insurance_rejects ORDER BY reject_id DESC;
GO