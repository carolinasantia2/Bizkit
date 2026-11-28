-- EMPLOYEE: supertype of SERVER and MANAGER.
-- Hierarchy: overlapping (one person can be both), partial (hosts are neither).
-- isServer / isManager are the discriminator flags; they must match the
-- subtype rows (checked by tests/04_foundation_menu_checks.sql).
-- Level 1: points to nothing.
CREATE TABLE dbo.EMPLOYEE (
    employeeId INT IDENTITY(1,1) NOT NULL,
    firstName  VARCHAR(40)       NOT NULL,
    lastName   VARCHAR(40)       NOT NULL,
    posPin     CHAR(4)           NOT NULL,
    hireDate   DATE              NOT NULL,
    isServer   BIT               NOT NULL CONSTRAINT DF_EMPLOYEE_isServer  DEFAULT (0),
    isManager  BIT               NOT NULL CONSTRAINT DF_EMPLOYEE_isManager DEFAULT (0),

    CONSTRAINT PK_EMPLOYEE PRIMARY KEY (employeeId),
    CONSTRAINT UQ_EMPLOYEE_posPin UNIQUE (posPin),
    -- Exactly four digits (CHAR pads short values with spaces, which fail this).
    CONSTRAINT CK_EMPLOYEE_posPin CHECK (posPin NOT LIKE '%[^0-9]%')
);