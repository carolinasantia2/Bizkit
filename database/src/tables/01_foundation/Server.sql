-- SERVER: subtype of EMPLOYEE (employees who take tables).
-- Level 2: points to EMPLOYEE.
CREATE TABLE dbo.SERVER (
    employeeId INT        NOT NULL,
    serverCode VARCHAR(4) NOT NULL,

    CONSTRAINT PK_SERVER PRIMARY KEY (employeeId),
    CONSTRAINT FK_SERVER_EMPLOYEE
        FOREIGN KEY (employeeId) REFERENCES dbo.EMPLOYEE (employeeId),
    CONSTRAINT UQ_SERVER_serverCode UNIQUE (serverCode)
);