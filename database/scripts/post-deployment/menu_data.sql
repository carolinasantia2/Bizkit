-- ============================================================
-- Seed 2: menu tree (categories, items, add-ons)
-- ============================================================
-- Rows are inserted parent first, because parentEntryId points
-- back into MENU_ENTRY. IDs match the examples in docs/api.md.
--
-- Tree:
--   1 Menu
--     2 Food
--       10 Starters ......... 20 Fries, 21 Caesar salad, 22 Wings
--       11 Burgers .......... 40 Classic Burger, 44 Veggie Burger
--       12 Mains ............ 30 Chicken parm, 31 Carbonara, 32 Salmon
--       13 Desserts ......... 70 Brownie, 72 Tiramisu (sold out)
--       15 Brunch specials .. 80 Avocado toast (9:00-14:00 only)
--     3 Drinks
--       14 Soft drinks ...... 50 Soda, 51 Lemonade (no default course)

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

SET IDENTITY_INSERT dbo.MENU_ENTRY ON;

-- Root and top-level menus
INSERT INTO dbo.MENU_ENTRY (entryId, parentEntryId, entryName, entryType, displayOrder) VALUES
    (1, NULL, 'Menu',   'C', 1),
    (2, 1,    'Food',   'C', 1),
    (3, 1,    'Drinks', 'C', 2);

-- Groups
INSERT INTO dbo.MENU_ENTRY (entryId, parentEntryId, entryName, entryType, displayOrder) VALUES
    (10, 2, 'Starters',        'C', 1),
    (11, 2, 'Burgers',         'C', 2),
    (12, 2, 'Mains',           'C', 3),
    (13, 2, 'Desserts',        'C', 4),
    (15, 2, 'Brunch specials', 'C', 5),
    (14, 3, 'Soft drinks',     'C', 1);

-- Items
INSERT INTO dbo.MENU_ENTRY (entryId, parentEntryId, entryName, entryType, displayOrder) VALUES
    (20, 10, 'Fries',          'I', 1),
    (21, 10, 'Caesar salad',   'I', 2),
    (22, 10, 'Wings',          'I', 3),
    (40, 11, 'Classic Burger', 'I', 1),
    (44, 11, 'Veggie Burger',  'I', 2),
    (30, 12, 'Chicken parm',   'I', 1),
    (31, 12, 'Carbonara',      'I', 2),
    (32, 12, 'Salmon',         'I', 3),
    (70, 13, 'Brownie',        'I', 1),
    (72, 13, 'Tiramisu',       'I', 2),
    (80, 15, 'Avocado toast',  'I', 1),
    (50, 14, 'Soda',           'I', 1),
    (51, 14, 'Lemonade',       'I', 2);

-- Add-ons
INSERT INTO dbo.MENU_ENTRY (entryId, parentEntryId, entryName, entryType, displayOrder) VALUES
    (60, 20, 'Truffle oil',     'A', 1),
    (61, 21, 'Add chicken',     'A', 1),
    (62, 22, 'Extra hot',       'A', 1),
    (63, 22, 'Blue cheese dip', 'A', 2),
    (41, 40, 'Cheese',          'A', 1),
    (42, 40, 'Bacon',           'A', 2),
    (43, 40, 'Avocado',         'A', 3),
    (45, 44, 'Cheese',          'A', 1),
    (64, 32, 'Side salad',      'A', 1),
    (71, 70, 'Ice cream',       'A', 1);

SET IDENTITY_INSERT dbo.MENU_ENTRY OFF;

-- Category subtype rows (every 'C' entry)
INSERT INTO dbo.CATEGORY (entryId, availableFrom, availableTo) VALUES
    (1,  NULL, NULL),
    (2,  NULL, NULL),
    (3,  NULL, NULL),
    (10, NULL, NULL),
    (11, NULL, NULL),
    (12, NULL, NULL),
    (13, NULL, NULL),
    (14, NULL, NULL),
    (15, '09:00', '14:00');

-- Item subtype rows (every 'I' entry). Course 1 Apps, 2 Mains, 3 Dessert, NULL none.
INSERT INTO dbo.MENU_ITEM (entryId, basePrice, defaultCourseId, isAvailable) VALUES
    (20,  5.00, 1, 1),
    (21, 12.00, 1, 1),
    (22,  9.00, 1, 1),
    (40, 12.00, 2, 1),
    (44, 13.00, 2, 1),
    (30, 19.50, 2, 1),
    (31, 18.50, 2, 1),
    (32, 19.00, 2, 1),
    (70,  7.00, 3, 1),
    (72,  8.00, 3, 0),   -- sold out: shown greyed out
    (80, 11.00, 1, 1),
    (50,  3.00, NULL, 1),
    (51,  4.00, NULL, 1);

-- Add-on subtype rows (every 'A' entry)
INSERT INTO dbo.ADD_ON (entryId, addOnPrice) VALUES
    (60, 2.00),
    (61, 5.00),
    (62, 0.00),
    (63, 1.00),
    (41, 1.50),
    (42, 2.00),
    (43, 2.50),
    (45, 1.50),
    (64, 4.00),
    (71, 2.00);

COMMIT TRANSACTION;