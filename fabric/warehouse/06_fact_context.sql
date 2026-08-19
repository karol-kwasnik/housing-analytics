CREATE TABLE dbo.fact_context (
    territory_sk          BIGINT        NOT NULL,
    date_sk               INT           NOT NULL,
    avg_gross_salary      DECIMAL(12,2) NULL,
    population            INT           NULL,
    dwellings_completed   INT           NULL,
    floor_area_completed  DECIMAL(14,2) NULL,
    dwellings_per_1000    DECIMAL(10,2) NULL,
    persons_per_dwelling  DECIMAL(10,2) NULL,
    floor_area_per_person DECIMAL(10,2) NULL
);
GO

DROP PROCEDURE IF EXISTS dbo.sp_load_fact_context;
GO

CREATE PROCEDURE dbo.sp_load_fact_context
AS
BEGIN
    TRUNCATE TABLE dbo.fact_context;

    WITH pivoted AS (
        SELECT
            t.territory_sk,
            s.year,
            MAX(CASE WHEN v.measure = 'avg_gross_salary'      THEN s.value END) AS avg_gross_salary,
            MAX(CASE WHEN v.measure = 'population'            THEN s.value END) AS population,
            MAX(CASE WHEN v.measure = 'dwellings_completed'   THEN s.value END) AS dwellings_completed,
            MAX(CASE WHEN v.measure = 'floor_area_completed'  THEN s.value END) AS floor_area_completed,
            MAX(CASE WHEN v.measure = 'dwellings_per_1000'    THEN s.value END) AS dwellings_per_1000,
            MAX(CASE WHEN v.measure = 'persons_per_dwelling'  THEN s.value END) AS persons_per_dwelling,
            MAX(CASE WHEN v.measure = 'floor_area_per_person' THEN s.value END) AS floor_area_per_person
        FROM lh_silver.dbo.fact_bdl s
        JOIN lh_bronze.dbo.variable v ON v.variable_id = s.variable_id
        JOIN dbo.dim_territory t      ON t.teryt_code = s.teryt_code AND t.is_current = 1
        WHERE v.category NOT IN ('prices', 'transactions')
        GROUP BY t.territory_sk, s.year
    )
    INSERT INTO dbo.fact_context
        (territory_sk, date_sk, avg_gross_salary, population,
         dwellings_completed, floor_area_completed,
         dwellings_per_1000, persons_per_dwelling, floor_area_per_person)
    SELECT
        territory_sk,
        year * 10000 + 1231,
        CAST(avg_gross_salary      AS DECIMAL(12,2)),
        CAST(population            AS INT),
        CAST(dwellings_completed   AS INT),
        CAST(floor_area_completed  AS DECIMAL(14,2)),
        CAST(dwellings_per_1000    AS DECIMAL(10,2)),
        CAST(persons_per_dwelling  AS DECIMAL(10,2)),
        CAST(floor_area_per_person AS DECIMAL(10,2))
    FROM pivoted;
END
GO

CREATE TABLE dbo.param_credit (
    parameter_name  VARCHAR(50)   NOT NULL,
    parameter_value DECIMAL(10,4) NOT NULL,
    description     VARCHAR(200)  NULL
);
GO

DROP PROCEDURE IF EXISTS dbo.sp_load_param_credit;
GO

CREATE PROCEDURE dbo.sp_load_param_credit
AS
BEGIN
    TRUNCATE TABLE dbo.param_credit;

    INSERT INTO dbo.param_credit (parameter_name, parameter_value, description)
    SELECT parameter_name, parameter_value, description
    FROM lh_bronze.dbo.credit_parameter;
END
GO
