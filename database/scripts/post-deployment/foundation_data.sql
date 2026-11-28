-- ============================================================
-- Seed 1: foundation (areas, tables, courses, staff, open shift)
-- ============================================================
-- Explicit IDs keep foreign keys predictable for the other seed
-- files and match the examples in docs/api.md.

-- Required for inserting into tables with filtered indexes (SHIFT).
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET XACT_ABORT ON;   -- any error rolls back the whole file
BEGIN TRANSACTION;

-- Service areas
SET IDENTITY_INSERT dbo.SERVICE_AREA ON;
INSERT INTO dbo.SERVICE_AREA (areaId, areaName) VALUES
    (1, 'Main dining'),
    (2, 'Patio'),
    (3, 'Bar');
SET IDENTITY_INSERT dbo.SERVICE_AREA OFF;

-- Dining tables: 1-4 main dining, 5-6 patio, 7-8 bar
SET IDENTITY_INSERT dbo.DINING_TABLE ON;
INSERT INTO dbo.DINING_TABLE (tableId, areaId, tableNumber, seatCapacity) VALUES
    (1, 1, 1, 4),
    (2, 1, 2, 4),
    (3, 1, 3, 2),
    (4, 1, 4, 6),
    (5, 2, 5, 4),
    (6, 2, 6, 4),
    (7, 3, 7, 2),
    (8, 3, 8, 2);
SET IDENTITY_INSERT dbo.DINING_TABLE OFF;

-- Courses
SET IDENTITY_INSERT dbo.COURSE ON;
INSERT INTO dbo.COURSE (courseId, courseNumber, courseName) VALUES
    (1, 1, 'Apps'),
    (2, 2, 'Mains'),
    (3, 3, 'Dessert');
SET IDENTITY_INSERT dbo.COURSE OFF;

-- Staff. Shows both EER constraints on EMPLOYEE:
--   overlapping: Jordan is a server AND a manager
--   partial:     Alex (host) is neither
SET IDENTITY_INSERT dbo.EMPLOYEE ON;
INSERT INTO dbo.EMPLOYEE (employeeId, firstName, lastName, posPin, hireDate, isServer, isManager) VALUES
    (1, 'Jordan', 'Lee',    '1001', '2022-03-14', 1, 1),
    (2, 'Maya',   'Rivera', '1002', '2023-06-01', 1, 0),
    (3, 'Sam',    'Chen',   '1003', '2024-01-22', 1, 0),
    (4, 'Alex',   'Kim',    '1004', '2025-08-09', 0, 0);
SET IDENTITY_INSERT dbo.EMPLOYEE OFF;

INSERT INTO dbo.SERVER (employeeId, serverCode) VALUES
    (1, 'JL'),
    (2, 'MR'),
    (3, 'SC');

INSERT INTO dbo.MANAGER (employeeId, overrideCode) VALUES
    (1, '482913');

-- One open brunch shift (the demo's current shift)
SET IDENTITY_INSERT dbo.SHIFT ON;
INSERT INTO dbo.SHIFT (shiftId, shiftName, businessDate, openedAt, closedAt, closedByEmployeeId) VALUES
    (1, 'Brunch', '2026-12-04', '2026-12-04T09:30:00', NULL, NULL);
SET IDENTITY_INSERT dbo.SHIFT OFF;

COMMIT TRANSACTION;