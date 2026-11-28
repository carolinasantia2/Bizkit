-- SHIFT: a service period (Brunch, Dinner).
-- Only one shift may be open at a time: see src/indexes/02_ux_shift_single_open.sql.
-- Level 2: points to EMPLOYEE (who closed it).
CREATE TABLE dbo.SHIFT (
    shiftId            INT IDENTITY(1,1) NOT NULL,
    shiftName          VARCHAR(20)       NOT NULL,
    businessDate       DATE              NOT NULL,
    openedAt           DATETIME          NOT NULL,
    closedAt           DATETIME          NULL,
    closedByEmployeeId INT               NULL,

    CONSTRAINT PK_SHIFT PRIMARY KEY (shiftId),
    CONSTRAINT FK_SHIFT_EMPLOYEE
        FOREIGN KEY (closedByEmployeeId) REFERENCES dbo.EMPLOYEE (employeeId),
    -- A closed shift records both when and by whom; an open shift has neither.
    CONSTRAINT CK_SHIFT_closed_together CHECK (
        (closedAt IS NULL AND closedByEmployeeId IS NULL)
        OR (closedAt IS NOT NULL AND closedByEmployeeId IS NOT NULL)
    ),
    CONSTRAINT CK_SHIFT_closedAt_after_openedAt CHECK (closedAt IS NULL OR closedAt >= openedAt)
);