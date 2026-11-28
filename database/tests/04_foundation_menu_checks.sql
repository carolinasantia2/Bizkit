-- ============================================================
-- Test 4: rules foreign keys can't enforce (foundation and menu)
-- ============================================================
-- Each query below should return NO ROWS, except 4d, which
-- should return rootCount = 1 and openShiftCount = 1.

USE bizkit;
GO

-- 4a. Each MENU_ENTRY has exactly the subtype row its entryType says.
SELECT e.entryId, e.entryName, e.entryType,
       CASE WHEN c.entryId IS NULL THEN 0 ELSE 1 END AS hasCategoryRow,
       CASE WHEN i.entryId IS NULL THEN 0 ELSE 1 END AS hasItemRow,
       CASE WHEN a.entryId IS NULL THEN 0 ELSE 1 END AS hasAddOnRow
FROM dbo.MENU_ENTRY AS e
LEFT JOIN dbo.CATEGORY  AS c ON c.entryId = e.entryId
LEFT JOIN dbo.MENU_ITEM AS i ON i.entryId = e.entryId
LEFT JOIN dbo.ADD_ON    AS a ON a.entryId = e.entryId
WHERE NOT (
       (e.entryType = 'C' AND c.entryId IS NOT NULL AND i.entryId IS NULL AND a.entryId IS NULL)
    OR (e.entryType = 'I' AND i.entryId IS NOT NULL AND c.entryId IS NULL AND a.entryId IS NULL)
    OR (e.entryType = 'A' AND a.entryId IS NOT NULL AND c.entryId IS NULL AND i.entryId IS NULL)
);
GO

-- 4b. Tree shape: categories and items sit under categories; add-ons sit under items.
SELECT child.entryId, child.entryName, child.entryType,
       parent.entryName AS parentName, parent.entryType AS parentType
FROM dbo.MENU_ENTRY AS child
JOIN dbo.MENU_ENTRY AS parent ON parent.entryId = child.parentEntryId
WHERE (child.entryType IN ('C', 'I') AND parent.entryType <> 'C')
   OR (child.entryType = 'A' AND parent.entryType <> 'I');
GO

-- 4c. EMPLOYEE flags match the SERVER and MANAGER rows.
SELECT e.employeeId, e.firstName, e.lastName,
       e.isServer,  CASE WHEN s.employeeId IS NULL THEN 0 ELSE 1 END AS hasServerRow,
       e.isManager, CASE WHEN m.employeeId IS NULL THEN 0 ELSE 1 END AS hasManagerRow
FROM dbo.EMPLOYEE AS e
LEFT JOIN dbo.SERVER  AS s ON s.employeeId = e.employeeId
LEFT JOIN dbo.MANAGER AS m ON m.employeeId = e.employeeId
WHERE e.isServer  <> CASE WHEN s.employeeId IS NULL THEN 0 ELSE 1 END
   OR e.isManager <> CASE WHEN m.employeeId IS NULL THEN 0 ELSE 1 END;
GO

-- 4d. Exactly one menu root and one open shift.
SELECT (SELECT COUNT(*) FROM dbo.MENU_ENTRY WHERE parentEntryId IS NULL) AS rootCount,
       (SELECT COUNT(*) FROM dbo.SHIFT      WHERE closedAt IS NULL)      AS openShiftCount;
GO