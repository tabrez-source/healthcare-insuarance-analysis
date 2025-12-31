/* =========================================================
   STEP 3A: Data Warehouse (Star Schema)
   Schema: hi_dw
   ========================================================= */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='hi_dw')
    EXEC('CREATE SCHEMA hi_dw');
GO

-- Drop in FK-safe order (rerunnable)
IF OBJECT_ID('hi_dw.fact_insurance_charge','U') IS NOT NULL DROP TABLE hi_dw.fact_insurance_charge;
IF OBJECT_ID('hi_dw.dim_person','U') IS NOT NULL DROP TABLE hi_dw.dim_person;
IF OBJECT_ID('hi_dw.dim_region','U') IS NOT NULL DROP TABLE hi_dw.dim_region;
IF OBJECT_ID('hi_dw.dim_smoker','U') IS NOT NULL DROP TABLE hi_dw.dim_smoker;
IF OBJECT_ID('hi_dw.dim_sex','U') IS NOT NULL DROP TABLE hi_dw.dim_sex;
IF OBJECT_ID('hi_dw.dim_date','U') IS NOT NULL DROP TABLE hi_dw.dim_date;
GO

-- Date dimension (minimal for this project)
CREATE TABLE hi_dw.dim_date (
    date_key     INT NOT NULL PRIMARY KEY,  -- YYYYMMDD
    [date]       DATE NOT NULL,
    [year]       SMALLINT NOT NULL,
    [quarter]    TINYINT NOT NULL,
    [month]      TINYINT NOT NULL,
    month_name   VARCHAR(10) NOT NULL,
    [day]        TINYINT NOT NULL,
    day_of_week  TINYINT NOT NULL,          -- 1=Mon ... depends on DATEFIRST
    day_name     VARCHAR(10) NOT NULL,
    is_weekend   BIT NOT NULL
);
GO

CREATE TABLE hi_dw.dim_sex (
    sex_key   INT IDENTITY(1,1) PRIMARY KEY,
    sex       VARCHAR(10) NOT NULL UNIQUE
);
GO

CREATE TABLE hi_dw.dim_smoker (
    smoker_key INT IDENTITY(1,1) PRIMARY KEY,
    smoker     VARCHAR(3) NOT NULL UNIQUE
);
GO

CREATE TABLE hi_dw.dim_region (
    region_key INT IDENTITY(1,1) PRIMARY KEY,
    region     VARCHAR(20) NOT NULL UNIQUE
);
GO

-- Person dimension (SCD Type 1 for this project)
CREATE TABLE hi_dw.dim_person (
    person_key   INT IDENTITY(1,1) PRIMARY KEY,
    person_id    INT NOT NULL UNIQUE,  -- business key from OLTP
    age          TINYINT NOT NULL,
    children     TINYINT NOT NULL,
    sex_key      INT NOT NULL,
    smoker_key   INT NOT NULL,
    region_key   INT NOT NULL,
    created_utc  DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_dim_person_sex FOREIGN KEY (sex_key) REFERENCES hi_dw.dim_sex(sex_key),
    CONSTRAINT FK_dim_person_smoker FOREIGN KEY (smoker_key) REFERENCES hi_dw.dim_smoker(smoker_key),
    CONSTRAINT FK_dim_person_region FOREIGN KEY (region_key) REFERENCES hi_dw.dim_region(region_key)
);
GO

-- Fact table (grain: 1 row per policy)
CREATE TABLE hi_dw.fact_insurance_charge (
    fact_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    policy_id      INT NOT NULL,        -- degenerate dimension (keep policy_id)
    person_key     INT NOT NULL,
    policy_start_date_key INT NOT NULL,
    annual_charge  DECIMAL(12,2) NOT NULL,
    currency_code  CHAR(3) NOT NULL,
    load_utc       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_fact_person FOREIGN KEY (person_key) REFERENCES hi_dw.dim_person(person_key),
    CONSTRAINT FK_fact_date FOREIGN KEY (policy_start_date_key) REFERENCES hi_dw.dim_date(date_key)
);
GO

-- Performance indexes
CREATE INDEX IX_fact_person ON hi_dw.fact_insurance_charge(person_key);
CREATE INDEX IX_fact_date ON hi_dw.fact_insurance_charge(policy_start_date_key);
CREATE INDEX IX_fact_charge ON hi_dw.fact_insurance_charge(annual_charge);
GO
