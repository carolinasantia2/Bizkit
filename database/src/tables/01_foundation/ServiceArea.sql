-- SERVICE_AREA: dining areas (Main dining, Patio, Bar).
-- Level 1: points to nothing.
CREATE TABLE dbo.SERVICE_AREA (
    areaId   INT IDENTITY(1,1) NOT NULL,
    areaName VARCHAR(40)       NOT NULL,

    CONSTRAINT PK_SERVICE_AREA PRIMARY KEY (areaId),
    CONSTRAINT UQ_SERVICE_AREA_areaName UNIQUE (areaName)
);