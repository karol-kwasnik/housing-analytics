CREATE TABLE [dbo].[dim_date] (

	[date_sk] int NOT NULL, 
	[full_date] date NOT NULL, 
	[year] int NOT NULL, 
	[quarter] int NOT NULL, 
	[month] int NOT NULL, 
	[is_year_end] bit NOT NULL
);