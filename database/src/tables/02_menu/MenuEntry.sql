-- MENU_ENTRY: supertype of CATEGORY, MENU_ITEM and ADD_ON; one node of the menu tree.
-- Hierarchy: disjoint, total, discriminator entryType (C category, I item, A add-on).
-- parentEntryId is the recursive "parent of" relationship. Only the root has no parent:
-- see src/indexes/01_ux_menu_entry_single_root.sql.
-- Which types may sit under which (items under categories, add-ons under items) is
-- enforced by the MenuTree and checked by tests/04_foundation_menu_checks.sql.
-- Level 2: points to itself.
CREATE TABLE dbo.MENU_ENTRY (
    entryId       INT IDENTITY(1,1) NOT NULL,
    parentEntryId INT               NULL,
    entryName     VARCHAR(60)       NOT NULL,
    entryType     CHAR(1)           NOT NULL,
    displayOrder  INT               NOT NULL,

    CONSTRAINT PK_MENU_ENTRY PRIMARY KEY (entryId),
    CONSTRAINT FK_MENU_ENTRY_parent
        FOREIGN KEY (parentEntryId) REFERENCES dbo.MENU_ENTRY (entryId),
    -- Siblings can't share a display position.
    CONSTRAINT UQ_MENU_ENTRY_sibling_order UNIQUE (parentEntryId, displayOrder),
    CONSTRAINT CK_MENU_ENTRY_entryType CHECK (entryType IN ('C', 'I', 'A')),
    -- Only a category can be the root.
    CONSTRAINT CK_MENU_ENTRY_root_is_category CHECK (parentEntryId IS NOT NULL OR entryType = 'C'),
    CONSTRAINT CK_MENU_ENTRY_not_own_parent CHECK (parentEntryId IS NULL OR parentEntryId <> entryId),
    CONSTRAINT CK_MENU_ENTRY_displayOrder CHECK (displayOrder > 0)
);