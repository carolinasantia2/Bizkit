-- CATEGORY: subtype of MENU_ENTRY (menus and groups, e.g. Food, Burgers).
-- availableFrom / availableTo limit a group to certain hours (e.g. brunch only).
-- Level 3: points to MENU_ENTRY.
CREATE TABLE dbo.CATEGORY (
    entryId       INT  NOT NULL,
    availableFrom TIME NULL,
    availableTo   TIME NULL,

    CONSTRAINT PK_CATEGORY PRIMARY KEY (entryId),
    CONSTRAINT FK_CATEGORY_MENU_ENTRY
        FOREIGN KEY (entryId) REFERENCES dbo.MENU_ENTRY (entryId),
    -- Hours are given as a pair or not at all.
    CONSTRAINT CK_CATEGORY_hours_together CHECK (
        (availableFrom IS NULL AND availableTo IS NULL)
        OR (availableFrom IS NOT NULL AND availableTo IS NOT NULL)
    ),
    CONSTRAINT CK_CATEGORY_hours_order CHECK (availableFrom IS NULL OR availableFrom < availableTo)
);