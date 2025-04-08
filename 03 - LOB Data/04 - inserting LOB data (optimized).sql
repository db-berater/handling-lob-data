/*============================================================================
	File:		04 - inserting LOB data (optimized).sql

	Summary:	This script demonstrates an optimized solution to store LOB data
				in your database.
				When a table gets created we can define a separate filegroup for
				the storage of tbe LOB Data.

				NOTE: If a LOB fits with the row into one data page the separate
				filegroup will NOT be used!

	Date:		April 2024
	Session:	SQL Server - LOB Data Management

	SQL Server Version: >= 2016
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	To optimize workloads we can move LOB data to different filegroups
*/
IF NOT EXISTS (SELECT * FROM sys.filegroups WHERE name = N'blob_data')
	ALTER DATABASE ERP_Demo
	ADD FILEGROUP [blob_data];
	GO

IF NOT EXISTS (SELECT * FROM sys.master_files WHERE database_id = DB_ID() AND name = N'blob_data')
	ALTER DATABASE ERP_Demo
	ADD FILE
	(
		NAME = N'blob_data',
		FILENAME = N'F:\MSSQL16.SQL_2022\MSSQL\DATA\blob_data.ndf',
		SIZE = 4096MB,
		FILEGROWTH = 1024MB
	)
	TO FILEGROUP [blob_data];
	GO

SELECT	index_id,
        index_name,
		filegroup_name,
        rows,
        type_desc,
        total_pages,
        used_pages,
        data_pages,
        space_mb,
        first_iam_page,
        root_page
FROM	dbo.get_table_pages_info
		(
			N'demo.customers',
			1
		);
GO

/*
	We recreate the demo table to separate the LOB data
	in a separate filegroup.
*/
DROP TABLE IF EXISTS demo.Customers;
GO

CREATE TABLE demo.Customers
(
	c_custkey		BIGINT		NOT NULL,
	c_mktsegment	CHAR(10)	NULL,
	c_nationkey		INT			NOT NULL,
	c_name			VARCHAR(25)	NULL,
	c_address		VARCHAR(40)	NULL,
	c_phone			CHAR(15)	NULL,
	c_acctbal		MONEY		NULL,
	c_comment		VARCHAR(118)	NULL,
	c_companylogo	VARBINARY(MAX)	NULL,

	CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey)
)
ON [PRIMARY]
TEXTIMAGE_ON [blob_data];
GO

/*
	The question is: Will the small pictures (~4KB) been stored in the
	dedicated blob_data filegroup?
*/
EXEC dbo.InsertCustomers
	@iteration_name = '04 - inserting LOB data (optimized) - small blob size',
	@num_of_iterations = 1000,
	@small_picture = 1,
	@drop_existing_table = 0;
GO

/*
	Will the LOB data be stored on the separate filegroup?
	NO - because the LOB will - by default - only be stored
	on the dedicated filegroup when the LOB will not fit
	on the same data page as the row itself!
*/
SELECT	index_id,
        index_name,
		filegroup_name,
        rows,
        type_desc,
        total_pages,
        used_pages,
        data_pages,
        space_mb,
        first_iam_page,
        root_page
FROM	dbo.get_table_pages_info
		(
			N'demo.customers',
			1
		);
GO

/*
	If the LOB data are larger and it cannot fit on the same
	page as the rows itself, SQL Server move the LOB to dedicated
	LOB pages
*/
EXEC dbo.InsertCustomers
	@iteration_name = '04 - inserting LOB data (optimized) - big blog size',
	@num_of_iterations = 1000,
	@small_picture = 0,
	@drop_existing_table = 0;
GO

SELECT	index_id,
        index_name,
		filegroup_name,
        rows,
        type_desc,
        total_pages,
        used_pages,
        data_pages,
        space_mb,
        first_iam_page,
        root_page
FROM	dbo.get_table_pages_info
		(
			N'demo.customers',
			1
		);
GO
