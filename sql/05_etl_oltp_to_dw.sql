/* =========================================================
   STEP 3B: ETL OLTP -> DW
   - Loads dim_date (range)
   - Loads small dims (sex/smoker/region)
   - Loads dim_person (SCD1)
   - Loads fact_insurance_charge
   ========================================================= */

-- 0) Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='hi_dw')
    EXEC('CREATE SCHEMA hi_dw');
GO

/* ---------------------------------------------------------
   1) Load dim_date (choose range that covers policy_start_dt)
--------------------------------------------------------- */
DECLARE @startDate DATE = (SELECT MIN(policy_start_dt) FROM hi_oltp.insurance_policy);
DECLARE @endDate   DATE = (SELECT MAX(policy_start_dt) FROM hi_oltp.insurance_policy);

-- If OLTP empty, stop
IF @startDate IS NULL OR @endDate IS NULL
BEGIN
    THROW 51001, 'DW ETL aborted: hi_oltp.insurance_policy has no data.', 1;
END;

-- Expand range a bit
SET @startDate = DATEADD(DAY, -7, @startDate);
SET @endDate   = DATEADD(DAY,  7, @endDate);

;WITH d AS (
    SELECT @startDate AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM d
    WHERE dt < @endDate
)
INSERT INTO hi_dw.dim_date (date_key, [date], [year], [quarter], [month], month_name, [day], day_of_week, day_name, is_weekend)
SELECT
    CONVERT(INT, FORMAT(dt, 'yyyyMMdd')) AS date_key,
    dt,
    DATEPART(YEAR, dt),
    DATEPART(QUARTER, dt),
    DATEPART(MONTH, dt),
    DATENAME(MONTH, dt),
    DATEPART(DAY, dt),
    DATEPART(WEEKDAY, dt),
    DATENAME(WEEKDAY, dt),
    CASE WHEN DATENAME(WEEKDAY, dt) IN ('Saturday','Sunday') THEN 1 ELSE 0 END
FROM d
WHERE NOT EXISTS (
    SELECT 1 FROM hi_dw.dim_date x WHERE x.[date] = d.dt
)
OPTION (MAXRECURSION 0);
GO

/* ---------------------------------------------------------
   2) Load small dimensions (sex/smoker/region)
--------------------------------------------------------- */
INSERT INTO hi_dw.dim_sex (sex)
SELECT DISTINCT p.sex
FROM hi_oltp.person p
WHERE NOT EXISTS (SELECT 1 FROM hi_dw.dim_sex s WHERE s.sex = p.sex);

INSERT INTO hi_dw.dim_smoker (smoker)
SELECT DISTINCT hp.smoker
FROM hi_oltp.health_profile hp
WHERE NOT EXISTS (SELECT 1 FROM hi_dw.dim_smoker s WHERE s.smoker = hp.smoker);

INSERT INTO hi_dw.dim_region (region)
SELECT DISTINCT p.region
FROM hi_oltp.person p
WHERE NOT EXISTS (SELECT 1 FROM hi_dw.dim_region r WHERE r.region = p.region);
GO

/* ---------------------------------------------------------
   3) Load dim_person (SCD Type 1)
--------------------------------------------------------- */
;WITH src AS (
    SELECT
        p.person_id,
        p.age,
        p.children,
        p.sex,
        hp.smoker,
        p.region
    FROM hi_oltp.person p
    JOIN hi_oltp.health_profile hp ON hp.person_id = p.person_id
),
lkp AS (
    SELECT
        s.person_id, s.age, s.children,
        sx.sex_key,
        sm.smoker_key,
        rg.region_key
    FROM src s
    JOIN hi_dw.dim_sex sx ON sx.sex = s.sex
    JOIN hi_dw.dim_smoker sm ON sm.smoker = s.smoker
    JOIN hi_dw.dim_region rg ON rg.region = s.region
)
MERGE hi_dw.dim_person AS tgt
USING lkp AS src
ON tgt.person_id = src.person_id
WHEN MATCHED THEN
  UPDATE SET
    tgt.age = src.age,
    tgt.children = src.children,
    tgt.sex_key = src.sex_key,
    tgt.smoker_key = src.smoker_key,
    tgt.region_key = src.region_key
WHEN NOT MATCHED THEN
  INSERT (person_id, age, children, sex_key, smoker_key, region_key)
  VALUES (src.person_id, src.age, src.children, src.sex_key, src.smoker_key, src.region_key);
GO

/* ---------------------------------------------------------
   4) Load fact table
   Grain: policy_id
--------------------------------------------------------- */

-- Rerunnable approach: delete and reload facts (simple for portfolio)
DELETE FROM hi_dw.fact_insurance_charge;

INSERT INTO hi_dw.fact_insurance_charge (policy_id, person_key, policy_start_date_key, annual_charge, currency_code)
SELECT
    pol.policy_id,
    dp.person_key,
    dd.date_key,
    ch.annual_charge,
    ch.currency_code
FROM hi_oltp.insurance_policy pol
JOIN hi_oltp.policy_charge ch ON ch.policy_id = pol.policy_id
JOIN hi_dw.dim_person dp ON dp.person_id = pol.person_id
JOIN hi_dw.dim_date dd ON dd.[date] = pol.policy_start_dt;
GO

-- Quick checks
SELECT COUNT(*) AS dim_person_rows FROM hi_dw.dim_person;
SELECT COUNT(*) AS fact_rows FROM hi_dw.fact_insurance_charge;

-- Sample analytic query (Power BI style)
SELECT TOP 10
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
GO
