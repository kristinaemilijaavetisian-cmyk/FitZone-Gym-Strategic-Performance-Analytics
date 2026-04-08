-- ============================================================
--  GYM PERFORMANCE DATABASE  |  SQL SERVER VERSION
--  Tested on: SQL Server Express 17+ / SSMS 22
--  Author  : [Kristina Avetisian]
-- ============================================================

/*

This part of a project includes :
    a) Designing a 6-table relational database schema (members, coaches, attendance, payments, equipment, group_classes);
    b) Importing data into SQL Server Express via BULK INSERT.
*/

USE master;
GO

-- Drop and recreate the database cleanly
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GymAnalysis')
BEGIN
    ALTER DATABASE GymAnalysis SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymAnalysis;
END
GO

CREATE DATABASE GymAnalysis
    COLLATE Latin1_General_100_CI_AS_SC_UTF8; -- Lithuanian characters enabled
GO

USE GymAnalysis;
GO

-- ─────────────────────────────────────────────
-- Creating Tables
-- ─────────────────────────────────────────────

-- ─────────────────────────────────────────────
-- TABLE 1 : members
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS members;
CREATE TABLE members (
    member_id               INT             PRIMARY KEY,
    first_name              NVARCHAR(60)    NOT NULL,
    last_name               NVARCHAR(60)    NOT NULL,
    gender                  CHAR(1),
    date_of_birth           DATE,
    email                   NVARCHAR(120)   UNIQUE,
    phone                   NVARCHAR(25),
    address                 NVARCHAR(200),
    membership_type         NVARCHAR(30),
    membership_price_eur    DECIMAL(8,2),
    registration_date       DATE,
    status                  NVARCHAR(20),   -- Active | Inactive | Suspended
    referred_by_member_id   INT             NULL
);
GO

-- ─────────────────────────────────────────────
-- TABLE 2 : coaches
-- ─────────────────────────────────────────────

USE GymAnalysis;

DROP TABLE IF EXISTS coaches;
GO

CREATE TABLE coaches (
    coach_id                INT             PRIMARY KEY,
    first_name              NVARCHAR(60)    NOT NULL,
    last_name               NVARCHAR(60)    NOT NULL,
    gender                  CHAR(1),
    email                   NVARCHAR(120)   UNIQUE,
    phone                   NVARCHAR(25),
    specialty               NVARCHAR(60),
    license_type            NVARCHAR(40),
    license_expiry          DATE,
    hire_date               DATE,
    years_experience        INT,
    monthly_salary_eur      DECIMAL(8,2),
    employment_type         NVARCHAR(20),
    rating                  DECIMAL(3,1),
    active                  TINYINT         DEFAULT 1
);
GO

-- ─────────────────────────────────────────────
-- TABLE 3 : attendance
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS attendance;
CREATE TABLE attendance (
    attendance_id           INT             PRIMARY KEY,
    member_id               INT             NOT NULL,
    check_in_time           DATETIME        NOT NULL,
    check_out_time          DATETIME,
    duration_minutes        INT,
    workout_type            NVARCHAR(40),
    coach_id                INT             NULL,
    notes                   NVARCHAR(200)
);
GO

-- ─────────────────────────────────────────────
-- TABLE 4 : payments
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    payment_id              INT             PRIMARY KEY,
    member_id               INT             NOT NULL,
    payment_date            DATE            NOT NULL,
    amount_eur              DECIMAL(8,2),
    discount_pct            INT             DEFAULT 0,
    membership_type         NVARCHAR(30),
    payment_method          NVARCHAR(30),
    invoice_number          NVARCHAR(30)    UNIQUE,
    status                  NVARCHAR(20)    -- Paid | Pending | Failed | Refunded
);
GO

-- ─────────────────────────────────────────────
-- TABLE 5 : equipment
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS equipment;
CREATE TABLE equipment (
    equipment_id            INT             PRIMARY KEY,
    equipment_name          NVARCHAR(60),
    brand                   NVARCHAR(60),
    serial_number           NVARCHAR(30)    UNIQUE,
    purchase_date           DATE,
    purchase_cost_eur       DECIMAL(10,2),
    location_zone           NVARCHAR(60),
    status                  NVARCHAR(30),   -- Active | Under Maintenance | Out of Service | Retired
    last_maintenance_date   DATE,
    next_maintenance_date   DATE,
    warranty_expiry         DATE
);
GO

-- ─────────────────────────────────────────────
-- TABLE 6 : group_classes
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS group_classes;
CREATE TABLE dbo.group_classes (
    class_id                INT             PRIMARY KEY,
    class_name              NVARCHAR(80)    NOT NULL,
    coach_id                INT             NULL,
    day_of_week             NVARCHAR(15),
    start_time              TIME,
    duration_minutes        INT,
    capacity                INT,
    enrolled_count          INT,
    room                    NVARCHAR(40),
    difficulty              NVARCHAR(20),
    price_per_session_eur   DECIMAL(6,2),
    active                  TINYINT         DEFAULT 1
);
GO

-- ============================================================
--  IMPORT CSV FILES
-- ============================================================

DELETE FROM dbo.payments;
DELETE FROM dbo.coaches;

-- STEP 1: Import members.csv ──────────────────────────────
BULK INSERT members
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\CSV FILES\members.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',   -- handles both Windows and Unix line endings
    TABLOCK
);
GO

-- ── STEP 2: Import coaches.csv ──────────────────────────────
BULK INSERT coaches
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\files (3)\coaches.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    TABLOCK
);
GO

-- Note: reimported coaches table because there was an issue of generating data and not logical calculations. Data were regenerated.

-- Check test

SELECT COUNT(*) AS total, SUM(active) AS active_coaches
FROM coaches;

-- ── STEP 3: Import attendance.csv ───────────────────────────
BULK INSERT attendance
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\CSV FILES\attendance.csv'
WITH (
    FORMAT = 'CSV', FIRSTROW = 2,
    FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK
);
GO

-- ── STEP 4: Import payments.csv ─────────────────────────────

BULK INSERT payments
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\files (3)\payments.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    TABLOCK
);
GO

-- Note: reimported payments table because there was an issue of generating data and not logical calculations. Data were regenerated.

-- Note:  fixing the hidden character in payments status column

UPDATE dbo.payments SET status = REPLACE(status, CHAR(13), '');
UPDATE dbo.payments SET status = TRIM(status);
GO

-- Check test 

SELECT COUNT(*) AS total_payments FROM payments;

SELECT DISTINCT status FROM payments;

SELECT 
    COUNT(*)                   AS active_coaches,
    SUM(monthly_salary_eur)    AS monthly_payroll
FROM coaches WHERE active = 1;

-- ── STEP 5: Import equipment.csv ────────────────────────────
BULK INSERT equipment
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\CSV FILES\equipment.csv'
WITH (
    FORMAT = 'CSV', FIRSTROW = 2,
    FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK
);
GO


-- ── STEP 6: Import group_classes.csv ────────────────────────


BULK INSERT group_classes
FROM 'C:\Users\Yoga\OneDrive - Kauno Tado Ivanausko progimnazija\Darbalaukis\files\CSV FILES\group_classes.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    TABLOCK
);
GO

-- Check Test
SELECT COUNT(*) AS total, SUM(active) AS active_classes 
FROM dbo.group_classes;



-- ── Verify row counts after import ──────────────────────────

SELECT 'members'      AS tbl, COUNT(*) AS rows FROM members      UNION ALL
SELECT 'coaches'           , COUNT(*)          FROM coaches       UNION ALL
SELECT 'attendance'        , COUNT(*)          FROM attendance    UNION ALL
SELECT 'payments'          , COUNT(*)          FROM payments      UNION ALL
SELECT 'equipment'         , COUNT(*)          FROM equipment     UNION ALL
SELECT 'group_classes'     , COUNT(*)          FROM group_classes;

