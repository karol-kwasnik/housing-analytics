CREATE TABLE dbo.param_rate (
    rate       DECIMAL(6,4) NOT NULL,
    rate_label VARCHAR(10)  NOT NULL
);
GO

CREATE TABLE dbo.param_down_payment (
    down_payment       DECIMAL(6,4) NOT NULL,
    down_payment_label VARCHAR(10)  NOT NULL
);
GO

CREATE TABLE dbo.param_loan_years (
    loan_years INT NOT NULL
);
GO

CREATE TABLE dbo.param_floor_area (
    floor_area INT NOT NULL
);
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
),
numbers AS (
    SELECT d1.n + d2.n * 10 AS n FROM digits d1 CROSS JOIN digits d2
)
INSERT INTO dbo.param_rate (rate, rate_label)
SELECT
    CAST(n * 0.0025 AS DECIMAL(6,4)),
    CONCAT(CAST(CAST(n * 0.25 AS DECIMAL(5,2)) AS VARCHAR(10)), '%')
FROM numbers
WHERE n <= 48;
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
)
INSERT INTO dbo.param_down_payment (down_payment, down_payment_label)
SELECT
    CAST(0.10 + n * 0.05 AS DECIMAL(6,4)),
    CONCAT(CAST(CAST(10 + n * 5 AS INT) AS VARCHAR(10)), '%')
FROM digits
WHERE n <= 8;
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
)
INSERT INTO dbo.param_loan_years (loan_years)
SELECT 15 + n * 5 FROM digits WHERE n <= 4;
GO

WITH digits(n) AS (
    SELECT * FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS x(n)
),
numbers AS (
    SELECT d1.n + d2.n * 10 AS n FROM digits d1 CROSS JOIN digits d2
)
INSERT INTO dbo.param_floor_area (floor_area)
SELECT 25 + n * 5 FROM numbers WHERE n <= 19;
GO
