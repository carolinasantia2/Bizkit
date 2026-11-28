-- Only one shift can be open at a time: at most one SHIFT with closedAt IS NULL.
-- Closing a shift and opening the next must close the old one first.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE UNIQUE INDEX UX_SHIFT_single_open
    ON dbo.SHIFT (closedAt)
    WHERE closedAt IS NULL;