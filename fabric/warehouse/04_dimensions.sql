CREATE TABLE dbo.dim_market_type (
    market_type_sk INT          NOT NULL,
    market_type    VARCHAR(100) NOT NULL
);
GO

INSERT INTO dbo.dim_market_type (market_type_sk, market_type)
SELECT ROW_NUMBER() OVER (ORDER BY s.dimension_1), s.dimension_1
FROM (
    SELECT DISTINCT dimension_1
    FROM lh_bronze.dbo.variable
    WHERE category IN ('prices', 'transactions')
      AND dimension_1 IS NOT NULL
) s;
GO

CREATE TABLE dbo.dim_size_range (
    size_range_sk INT          NOT NULL,
    size_range    VARCHAR(100) NOT NULL,
    sort_order    INT          NOT NULL
);
GO

INSERT INTO dbo.dim_size_range (size_range_sk, size_range, sort_order)
SELECT ROW_NUMBER() OVER (ORDER BY s.sort_order), s.dimension_2, s.sort_order
FROM (
    SELECT DISTINCT
        dimension_2,
        CASE dimension_2
            WHEN 'ogółem'           THEN 1
            WHEN 'do 40 m2'         THEN 2
            WHEN 'od 40,1 do 60 m2' THEN 3
            WHEN 'od 60,1 do 80 m2' THEN 4
            WHEN 'od 80,1 m2'       THEN 5
            ELSE 9
        END AS sort_order
    FROM lh_bronze.dbo.variable
    WHERE category IN ('prices', 'transactions')
      AND dimension_2 IS NOT NULL
) s;
GO

CREATE TABLE dbo.dim_reliability (
    reliability_sk   INT         NOT NULL,
    reliability      VARCHAR(30) NOT NULL,
    min_transactions INT         NULL,
    max_transactions INT         NULL
);
GO

INSERT INTO dbo.dim_reliability (reliability_sk, reliability, min_transactions, max_transactions)
VALUES
    (1, 'unknown', NULL, NULL),
    (2, 'low',        1,    9),
    (3, 'medium',    10,   49),
    (4, 'high',      50, NULL);
GO
