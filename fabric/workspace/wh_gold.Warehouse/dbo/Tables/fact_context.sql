CREATE TABLE [dbo].[fact_context] (

	[territory_sk] bigint NOT NULL, 
	[date_sk] int NOT NULL, 
	[avg_gross_salary] decimal(12,2) NULL, 
	[population] int NULL, 
	[dwellings_completed] int NULL, 
	[floor_area_completed] decimal(14,2) NULL, 
	[dwellings_per_1000] decimal(10,2) NULL, 
	[persons_per_dwelling] decimal(10,2) NULL, 
	[floor_area_per_person] decimal(10,2) NULL
);