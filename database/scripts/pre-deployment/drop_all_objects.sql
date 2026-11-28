-- ============================================================
-- Pre-deployment: drop every object, children first
-- ============================================================
-- Runs after the build script creates the bizkit database (if it
-- doesn't exist yet) and switches into it. On a rerun this drops
-- every table so the schema can be created cleanly again.
--
-- Order is the reverse of the TABLES list in build_dist.sh. When
-- you add a table, add its DROP here at its level, and add the
-- file to TABLES. Drop triggers and views in the first section,
-- before any table. Indexes are dropped with their tables.

-- Programmability and indexes (none yet)
-- DROP TRIGGER IF EXISTS dbo.trg_...;
-- DROP VIEW IF EXISTS dbo.vw_...;

-- Level 6: associative, history and payment subtype tables
DROP TABLE IF EXISTS dbo.ITEM_TRANSFER;
DROP TABLE IF EXISTS dbo.ORDER_ITEM_ADD_ON;
DROP TABLE IF EXISTS dbo.CARD_PAYMENT;
DROP TABLE IF EXISTS dbo.CASH_PAYMENT;

-- Level 5: tables that point to GUEST_CHECK
DROP TABLE IF EXISTS dbo.SHIFT_CARRYOVER;
DROP TABLE IF EXISTS dbo.PAYMENT;
DROP TABLE IF EXISTS dbo.ORDER_ITEM;

-- Level 4
DROP TABLE IF EXISTS dbo.GUEST_CHECK;

-- Level 3: menu subtypes
DROP TABLE IF EXISTS dbo.ADD_ON;
DROP TABLE IF EXISTS dbo.MENU_ITEM;
DROP TABLE IF EXISTS dbo.CATEGORY;

-- Level 2
DROP TABLE IF EXISTS dbo.MENU_ENTRY;
DROP TABLE IF EXISTS dbo.SHIFT;
DROP TABLE IF EXISTS dbo.MANAGER;
DROP TABLE IF EXISTS dbo.SERVER;
DROP TABLE IF EXISTS dbo.DINING_TABLE;

-- Level 1: tables that point to nothing
DROP TABLE IF EXISTS dbo.EMPLOYEE;
DROP TABLE IF EXISTS dbo.COURSE;
DROP TABLE IF EXISTS dbo.SERVICE_AREA;
GO