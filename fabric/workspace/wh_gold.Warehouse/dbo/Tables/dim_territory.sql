CREATE TABLE [dbo].[dim_territory] (

	[territory_sk] bigint NOT NULL, 
	[teryt_code] varchar(12) NOT NULL, 
	[unit_name] varchar(200) NOT NULL, 
	[level_name] varchar(20) NULL, 
	[voivodeship] varchar(100) NULL, 
	[subregion_code] varchar(7) NULL, 
	[subregion_name] varchar(200) NULL, 
	[county_type] varchar(30) NULL, 
	[valid_from] date NOT NULL, 
	[valid_to] date NULL, 
	[is_current] bit NOT NULL
);