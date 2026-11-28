-- ============================================================
-- Test 1: every expected table exists
-- ============================================================
-- Expected result: NO ROWS. Any row is a missing table.

USE bizkit;
GO

SELECT expected.table_name AS missing_table
FROM (VALUES
    ('SERVICE_AREA'), ('DINING_TABLE'), ('COURSE'),
    ('EMPLOYEE'), ('SERVER'), ('MANAGER'), ('SHIFT'),
    ('MENU_ENTRY'), ('CATEGORY'), ('MENU_ITEM'), ('ADD_ON'),
    ('GUEST_CHECK'), ('ORDER_ITEM'), ('ORDER_ITEM_ADD_ON'), ('ITEM_TRANSFER'),
    ('PAYMENT'), ('CARD_PAYMENT'), ('CASH_PAYMENT'),
    ('SHIFT_CARRYOVER')
) AS expected(table_name)
WHERE OBJECT_ID(N'dbo.' + expected.table_name, N'U') IS NULL
ORDER BY expected.table_name;
GO