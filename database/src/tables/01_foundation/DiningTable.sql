-- DINING_TABLE: physical tables on the floor.
-- Level 2: points to SERVICE_AREA.
CREATE TABLE dbo.DINING_TABLE (
    tableId      INT IDENTITY(1,1) NOT NULL,
    areaId       INT               NOT NULL,
    tableNumber  INT               NOT NULL,
    seatCapacity INT               NOT NULL,

    CONSTRAINT PK_DINING_TABLE PRIMARY KEY (tableId),
    CONSTRAINT FK_DINING_TABLE_SERVICE_AREA
        FOREIGN KEY (areaId) REFERENCES dbo.SERVICE_AREA (areaId),
    CONSTRAINT UQ_DINING_TABLE_tableNumber UNIQUE (tableNumber),
    CONSTRAINT CK_DINING_TABLE_tableNumber CHECK (tableNumber > 0),
    CONSTRAINT CK_DINING_TABLE_seatCapacity CHECK (seatCapacity > 0)
);