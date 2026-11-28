-- MANAGER: subtype of EMPLOYEE (approves voids and overrides).
-- Level 2: points to EMPLOYEE.
CREATE TABLE dbo.MANAGER (
    employeeId   INT     NOT NULL,
    overrideCode CHAR(6) NOT NULL,

    CONSTRAINT PK_MANAGER PRIMARY KEY (employeeId),
    CONSTRAINT FK_MANAGER_EMPLOYEE
        FOREIGN KEY (employeeId) REFERENCES dbo.EMPLOYEE (employeeId),
    CONSTRAINT UQ_MANAGER_overrideCode UNIQUE (overrideCode),
    CONSTRAINT CK_MANAGER_overrideCode CHECK (overrideCode NOT LIKE '%[^0-9]%')
);