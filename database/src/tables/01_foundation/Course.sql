-- COURSE: lookup of courses (1 Apps, 2 Mains, 3 Dessert).
-- Level 1: points to nothing.
CREATE TABLE dbo.COURSE (
    courseId     INT IDENTITY(1,1) NOT NULL,
    courseNumber INT               NOT NULL,
    courseName   VARCHAR(20)       NOT NULL,

    CONSTRAINT PK_COURSE PRIMARY KEY (courseId),
    CONSTRAINT UQ_COURSE_courseNumber UNIQUE (courseNumber),
    CONSTRAINT CK_COURSE_courseNumber CHECK (courseNumber > 0)
);