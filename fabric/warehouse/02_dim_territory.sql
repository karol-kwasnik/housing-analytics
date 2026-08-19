CREATE TABLE dbo.dim_territory (
    territory_sk   BIGINT       NOT NULL,
    teryt_code     VARCHAR(12)  NOT NULL,
    unit_name      VARCHAR(200) NOT NULL,
    level_name     VARCHAR(20)  NULL,
    voivodeship    VARCHAR(100) NULL,
    subregion_code VARCHAR(7)   NULL,
    county_type    VARCHAR(30)  NULL,
    agglomeration  VARCHAR(100) NULL,
    geo_name       VARCHAR(300) NULL,
    valid_from     DATE         NOT NULL,
    valid_to       DATE         NULL,
    is_current     BIT          NOT NULL
);
GO

INSERT INTO dbo.dim_territory
    (territory_sk, teryt_code, unit_name, level_name, voivodeship, subregion_code,
     county_type, agglomeration, geo_name, valid_from, valid_to, is_current)
SELECT
    ROW_NUMBER() OVER (ORDER BY c.teryt_code),
    c.teryt_code,
    c.name,
    'county',
    c.voivodeship,
    LEFT(c.teryt_code, 7),
    c.county_type,
    c.agglomeration,
    c.geo_name,
    CAST('2010-01-01' AS DATE),
    NULL,
    1
FROM lh_bronze.dbo.county_classification c;
GO
