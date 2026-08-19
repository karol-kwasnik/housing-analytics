CREATE TABLE dbo.fact_market (
    territory_sk       BIGINT        NOT NULL,
    date_sk            INT           NOT NULL,
    market_type_sk     INT           NOT NULL,
    size_range_sk      INT           NOT NULL,
    reliability_sk     INT           NOT NULL,
    median_price_sqm   DECIMAL(12,2) NULL,
    avg_price_sqm      DECIMAL(12,2) NULL,
    avg_dwelling_price DECIMAL(14,2) NULL,
    dwellings_sold     INT           NULL,
    floor_area_sold    DECIMAL(14,2) NULL,
    quality_flag       VARCHAR(10)   NULL
);
GO

DROP PROCEDURE IF EXISTS dbo.sp_load_fact_market;
GO

CREATE PROCEDURE dbo.sp_load_fact_market
AS
BEGIN
    TRUNCATE TABLE dbo.fact_market;

    WITH pivoted AS (
        SELECT
            t.territory_sk,
            s.year,
            mt.market_type_sk,
            sr.size_range_sk,
            MAX(CASE WHEN v.measure = 'median_price_sqm'   THEN s.value END) AS median_price_sqm,
            MAX(CASE WHEN v.measure = 'avg_price_sqm'      THEN s.value END) AS avg_price_sqm,
            MAX(CASE WHEN v.measure = 'avg_dwelling_price' THEN s.value END) AS avg_dwelling_price,
            MAX(CASE WHEN v.measure = 'dwellings_sold'     THEN s.value END) AS dwellings_sold,
            MAX(CASE WHEN v.measure = 'floor_area_sold'    THEN s.value END) AS floor_area_sold,
            MAX(s.quality_flag) AS quality_flag
        FROM lh_silver.dbo.fact_bdl s
        JOIN lh_bronze.dbo.variable v ON v.variable_id = s.variable_id
        JOIN dbo.dim_territory t      ON t.teryt_code = s.teryt_code AND t.is_current = 1
        JOIN dbo.dim_market_type mt   ON mt.market_type = v.dimension_1
        JOIN dbo.dim_size_range sr    ON sr.size_range = v.dimension_2
        WHERE v.category IN ('prices', 'transactions')
        GROUP BY t.territory_sk, s.year, mt.market_type_sk, sr.size_range_sk
    )
    INSERT INTO dbo.fact_market
        (territory_sk, date_sk, market_type_sk, size_range_sk, reliability_sk,
         median_price_sqm, avg_price_sqm, avg_dwelling_price,
         dwellings_sold, floor_area_sold, quality_flag)
    SELECT
        territory_sk,
        year * 10000 + 1231,
        market_type_sk,
        size_range_sk,
        CASE
            WHEN dwellings_sold IS NULL THEN 1
            WHEN dwellings_sold < 10    THEN 2
            WHEN dwellings_sold < 50    THEN 3
            ELSE 4
        END,
        CAST(median_price_sqm   AS DECIMAL(12,2)),
        CAST(avg_price_sqm      AS DECIMAL(12,2)),
        CAST(avg_dwelling_price AS DECIMAL(14,2)),
        CAST(dwellings_sold     AS INT),
        CAST(floor_area_sold    AS DECIMAL(14,2)),
        quality_flag
    FROM pivoted;
END
GO
