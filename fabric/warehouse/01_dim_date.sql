CREATE TABLE dbo.dim_date (
    date_sk     INT  NOT NULL,
    full_date   DATE NOT NULL,
    year        INT  NOT NULL,
    quarter     INT  NOT NULL,
    month       INT  NOT NULL,
    is_year_end BIT  NOT NULL
);
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
),
numbers AS (
    SELECT d1.n + d2.n * 10 + d3.n * 100 + d4.n * 1000 AS n
    FROM digits d1 CROSS JOIN digits d2 CROSS JOIN digits d3 CROSS JOIN digits d4
)
INSERT INTO dbo.dim_date (date_sk, full_date, year, quarter, month, is_year_end)
SELECT
    YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt),
    dt,
    YEAR(dt),
    DATEPART(QUARTER, dt),
    MONTH(dt),
    CASE WHEN MONTH(dt) = 12 AND DAY(dt) = 31 THEN 1 ELSE 0 END
FROM (
    SELECT DATEADD(DAY, n, CAST('2010-01-01' AS DATE)) AS dt
    FROM numbers
    WHERE n <= 5843
) s;
GO
