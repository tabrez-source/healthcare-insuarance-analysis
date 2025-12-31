IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hi_stg')
    EXEC('CREATE SCHEMA hi_stg');
GO

IF OBJECT_ID('hi_stg.insurance_raw','U') IS NOT NULL
    DROP TABLE hi_stg.insurance_raw;
GO

-- IMPORTANT: column order must match CSV:
-- age,sex,bmi,children,smoker,region,charges
CREATE TABLE hi_stg.insurance_raw (
    row_id    INT IDENTITY(1,1) PRIMARY KEY,
    age       VARCHAR(50) NULL,
    sex       VARCHAR(50) NULL,
    bmi       VARCHAR(50) NULL,
    children  VARCHAR(50) NULL,
    smoker    VARCHAR(50) NULL,
    region    VARCHAR(50) NULL,
    charges   VARCHAR(50) NULL
);
GO

TRUNCATE TABLE hi_stg.insurance_raw;
GO

BULK INSERT hi_stg.insurance_raw
FROM 'C:\Projects\healthcare-insuarance-analysis\data\insurance_clean.csv'
WITH (
  FORMATFILE = 'C:\Projects\healthcare-insuarance-analysis\data\insurance_7col.fmt',
  FIRSTROW = 2,
  TABLOCK
);
GO

SELECT COUNT(*) AS rows_loaded FROM hi_stg.insurance_raw;
SELECT TOP 10 * FROM hi_stg.insurance_raw ORDER BY row_id;

