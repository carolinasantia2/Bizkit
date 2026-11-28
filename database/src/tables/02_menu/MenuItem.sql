-- MENU_ITEM: subtype of MENU_ENTRY (something a guest orders).
-- defaultCourseId is the course the item usually goes in; NULL for drinks.
-- Level 3: points to MENU_ENTRY and COURSE.
CREATE TABLE dbo.MENU_ITEM (
    entryId         INT          NOT NULL,
    basePrice       DECIMAL(8,2) NOT NULL,
    defaultCourseId INT          NULL,
    isAvailable     BIT          NOT NULL CONSTRAINT DF_MENU_ITEM_isAvailable DEFAULT (1),

    CONSTRAINT PK_MENU_ITEM PRIMARY KEY (entryId),
    CONSTRAINT FK_MENU_ITEM_MENU_ENTRY
        FOREIGN KEY (entryId) REFERENCES dbo.MENU_ENTRY (entryId),
    CONSTRAINT FK_MENU_ITEM_COURSE
        FOREIGN KEY (defaultCourseId) REFERENCES dbo.COURSE (courseId),
    CONSTRAINT CK_MENU_ITEM_basePrice CHECK (basePrice >= 0)
);