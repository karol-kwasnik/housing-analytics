CREATE TABLE [dbo].[fact_market] (

	[territory_sk] bigint NOT NULL, 
	[date_sk] int NOT NULL, 
	[market_type_sk] int NOT NULL, 
	[size_range_sk] int NOT NULL, 
	[reliability_sk] int NOT NULL, 
	[median_price_sqm] decimal(12,2) NULL, 
	[avg_price_sqm] decimal(12,2) NULL, 
	[avg_dwelling_price] decimal(14,2) NULL, 
	[dwellings_sold] int NULL, 
	[floor_area_sold] decimal(14,2) NULL, 
	[quality_flag] varchar(10) NULL
);