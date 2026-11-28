-- ============================================================
-- Test 2: row counts per table
-- ============================================================
-- Expected result: one row per table. After the seed script,
-- every table except SHIFT_CARRYOVER and ITEM_TRANSFER should
-- have rows (those two are filled by the demo itself).

USE bizkit;
GO

SELECT t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.partitions AS p
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)          -- the table itself, not extra indexes
GROUP BY t.name
ORDER BY t.name;
GO