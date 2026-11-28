-- ============================================================
-- Test 3: foreign keys exist and are trusted
-- ============================================================
-- Real foreign keys stop orphan rows from being inserted, so
-- checking that every constraint exists, is enabled and is
-- trusted says more than searching for orphans.

USE bizkit;
GO

-- 3a. Total number of foreign keys.
-- Expected once all 19 tables exist: 31
--   (24 relationships in the design doc, with ITEM_TRANSFER's
--    from/to check and from/to course as separate keys, plus
--    7 subtype-to-supertype links).
SELECT COUNT(*) AS foreign_key_count
FROM sys.foreign_keys;
GO

-- 3b. Problems only. Expected result: NO ROWS.
SELECT fk.name AS constraint_name,
       OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.is_disabled,
       fk.is_not_trusted
FROM sys.foreign_keys AS fk
WHERE fk.is_disabled = 1
   OR fk.is_not_trusted = 1;
GO

-- 3c. Full list, for reference.
SELECT OBJECT_NAME(fk.parent_object_id) AS child_table,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS child_column,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.name AS constraint_name
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
    ON fkc.constraint_object_id = fk.object_id
ORDER BY child_table, child_column;
GO