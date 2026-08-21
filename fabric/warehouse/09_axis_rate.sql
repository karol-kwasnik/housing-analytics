DROP TABLE IF EXISTS dbo.axis_rate;
GO

CREATE TABLE dbo.axis_rate (
    rate DECIMAL(6,4) NOT NULL
);
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
),
numbers AS (
    SELECT d1.n + d2.n * 10 + d3.n * 100 AS n
    FROM digits d1 CROSS JOIN digits d2 CROSS JOIN digits d3
)
INSERT INTO dbo.axis_rate (rate)
SELECT CAST(n * 0.0005 AS DECIMAL(6,4))
FROM numbers
WHERE n <= 240;
GO
