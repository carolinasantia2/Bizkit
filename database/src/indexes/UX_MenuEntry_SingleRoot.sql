-- The menu tree has exactly one root: at most one MENU_ENTRY with no parent.
-- A filtered unique index allows only one row where parentEntryId IS NULL.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE UNIQUE INDEX UX_MENU_ENTRY_single_root
    ON dbo.MENU_ENTRY (parentEntryId)
    WHERE parentEntryId IS NULL;