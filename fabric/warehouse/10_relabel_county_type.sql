UPDATE dbo.dim_territory
SET county_type = 'miasto na prawach powiatu'
WHERE county_type = 'city';

UPDATE dbo.dim_territory
SET county_type = 'powiat ziemski'
WHERE county_type = 'rural';
