CREATE TABLE [dbo].[dim_reliability] (

	[reliability_sk] int NOT NULL, 
	[reliability] varchar(30) NOT NULL, 
	[min_transactions] int NULL, 
	[max_transactions] int NULL
);