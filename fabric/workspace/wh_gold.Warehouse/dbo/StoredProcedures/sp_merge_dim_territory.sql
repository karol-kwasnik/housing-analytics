CREATE PROCEDURE dbo.sp_merge_dim_territory
AS
BEGIN
    DECLARE @today DATE = CAST(GETDATE() AS DATE);

    UPDATE d
    SET valid_to = @today,
        is_current = 0
    FROM dbo.dim_territory d
    INNER JOIN lh_bronze.dbo.county_classification s
        ON s.teryt_code = d.teryt_code
    WHERE d.is_current = 1
      AND (ISNULL(d.unit_name, '')      <> ISNULL(s.name, '')
        OR ISNULL(d.voivodeship, '')    <> ISNULL(s.voivodeship, '')
        OR ISNULL(d.subregion_name, '') <> ISNULL(s.subregion_name, '')
        OR ISNULL(d.county_type, '')    <> ISNULL(s.county_type, ''));

    INSERT INTO dbo.dim_territory
        (territory_sk, teryt_code, unit_name, level_name, voivodeship,
         subregion_code, subregion_name, county_type, valid_from, valid_to, is_current)
    SELECT
        ROW_NUMBER() OVER (ORDER BY s.teryt_code)
            + ISNULL((SELECT MAX(territory_sk) FROM dbo.dim_territory), 0),
        s.teryt_code,
        s.name,
        'county',
        s.voivodeship,
        s.subregion_code,
        s.subregion_name,
        s.county_type,
        @today,
        NULL,
        1
    FROM lh_bronze.dbo.county_classification s
    LEFT JOIN dbo.dim_territory d
        ON d.teryt_code = s.teryt_code
       AND d.is_current = 1
    WHERE d.teryt_code IS NULL;
END