/* =========================================================
   STEP 2A: OLTP Schema (MS SQL Server)
   Source: hi_stg.insurance_raw
   ========================================================= */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='hi_oltp')
    EXEC('CREATE SCHEMA hi_oltp');
GO

-- Drop in FK-safe order (rerunnable)
IF OBJECT_ID('hi_oltp.policy_charge','U') IS NOT NULL DROP TABLE hi_oltp.policy_charge;
IF OBJECT_ID('hi_oltp.insurance_policy','U') IS NOT NULL DROP TABLE hi_oltp.insurance_policy;
IF OBJECT_ID('hi_oltp.health_profile','U') IS NOT NULL DROP TABLE hi_oltp.health_profile;
IF OBJECT_ID('hi_oltp.person','U') IS NOT NULL DROP TABLE hi_oltp.person;
GO

CREATE TABLE hi_oltp.person (
    person_id   INT IDENTITY(1,1) PRIMARY KEY,
    age         TINYINT NOT NULL,
    sex         VARCHAR(10) NOT NULL,
    region      VARCHAR(20) NOT NULL,
    children    TINYINT NOT NULL,
    stg_row_id  INT NULL,  -- lineage key (maps back to staging row_id)
    created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_person_created_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT CK_person_age CHECK (age BETWEEN 0 AND 120),
    CONSTRAINT CK_person_children CHECK (children BETWEEN 0 AND 20),
    CONSTRAINT CK_person_sex CHECK (sex IN ('male','female')),
    CONSTRAINT CK_person_region CHECK (region IN ('northeast','northwest','southeast','southwest'))
);
GO

CREATE UNIQUE INDEX UX_person_stg_row_id
ON hi_oltp.person(stg_row_id)
WHERE stg_row_id IS NOT NULL;
GO

CREATE TABLE hi_oltp.health_profile (
    person_id  INT NOT NULL PRIMARY KEY,
    bmi        DECIMAL(5,2) NOT NULL,
    smoker     VARCHAR(3) NOT NULL,
    updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_health_updated_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT CK_health_bmi CHECK (bmi BETWEEN 10 AND 80),
    CONSTRAINT CK_health_smoker CHECK (smoker IN ('yes','no')),
    CONSTRAINT FK_health_person FOREIGN KEY (person_id)
        REFERENCES hi_oltp.person(person_id) ON DELETE CASCADE
);
GO

CREATE TABLE hi_oltp.insurance_policy (
    policy_id       INT IDENTITY(1,1) PRIMARY KEY,
    person_id       INT NOT NULL,
    policy_number   VARCHAR(30) NOT NULL UNIQUE,
    policy_start_dt DATE NOT NULL,
    policy_status   VARCHAR(10) NOT NULL,
    created_at      DATETIME2(0) NOT NULL CONSTRAINT DF_policy_created_at DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT CK_policy_status CHECK (policy_status IN ('active','expired','cancelled')),
    CONSTRAINT FK_policy_person FOREIGN KEY (person_id)
        REFERENCES hi_oltp.person(person_id) ON DELETE CASCADE
);
GO

CREATE TABLE hi_oltp.policy_charge (
    policy_id     INT NOT NULL PRIMARY KEY,
    annual_charge DECIMAL(12,2) NOT NULL,
    currency_code CHAR(3) NOT NULL CONSTRAINT DF_charge_ccy DEFAULT ('USD'),

    CONSTRAINT CK_charge_amount CHECK (annual_charge >= 0),
    CONSTRAINT FK_charge_policy FOREIGN KEY (policy_id)
        REFERENCES hi_oltp.insurance_policy(policy_id) ON DELETE CASCADE
);
GO

-- Indexes
CREATE INDEX IX_person_region ON hi_oltp.person(region);
CREATE INDEX IX_person_sex    ON hi_oltp.person(sex);
CREATE INDEX IX_person_age    ON hi_oltp.person(age);

CREATE INDEX IX_health_smoker ON hi_oltp.health_profile(smoker);
CREATE INDEX IX_health_bmi    ON hi_oltp.health_profile(bmi);

CREATE INDEX IX_policy_person ON hi_oltp.insurance_policy(person_id);
CREATE INDEX IX_charge_amount ON hi_oltp.policy_charge(annual_charge);
GO