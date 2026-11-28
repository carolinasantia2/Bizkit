-- ADD_ON: subtype of MENU_ENTRY (a modifier under an item, e.g. Cheese).
-- Level 3: points to MENU_ENTRY.
CREATE TABLE dbo.ADD_ON (
    entryId    INT          NOT NULL,
    addOnPrice DECIMAL(8,2) NOT NULL,

    CONSTRAINT PK_ADD_ON PRIMARY KEY (entryId),
    CONSTRAINT FK_ADD_ON_MENU_ENTRY
        FOREIGN KEY (entryId) REFERENCES dbo.MENU_ENTRY (entryId),
    CONSTRAINT CK_ADD_ON_addOnPrice CHECK (addOnPrice >= 0)
);