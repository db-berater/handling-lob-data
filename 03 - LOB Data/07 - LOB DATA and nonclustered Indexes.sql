/*
	============================================================================
	File:		07 - LOB DATA and nonclustered Indexes.sql

	Summary:	This script demonstrates the behavior of LOB data
				in a nonclustered index, which have been added to the
				index with INCLUDE

	Date:		April 2025
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
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	To optimize workloads we can move (B)LOB data
	to different filegroups
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

/*
	We recreate the demo table to separate the LOB data in a separate filegroup.
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
	If a blob fits into a data page it will automatically stored 
	on the data page!
	To prevent SQL Server storing fitting data the row store we must
	activate this option on table level
*/
EXEC sp_tableoption
	@TableNamePattern = N'demo.Customers',
	@OptionName = 'LARGE VALUE TYPES OUT OF ROW',
	@OptionValue = 'true';
GO

/*
	Let's insert 2.000 rows into the table for demonstration purposes
*/
;WITH b
AS
(
	SELECT	blob_binary
	FROM	system.blob_data
	WHERE	id = 1
)
INSERT INTO demo.customers WITH (TABLOCK)
SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment,
		b.blob_binary
FROM	dbo.customers AS c
		CROSS JOIN b
WHERE	c_custkey <= 2000;
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
	Now we add a nonclustered index on the [name] attribute
	but we include the Company Logo into the index
*/
CREATE NONCLUSTERED INDEX nix_demo_customers_c_nationkey
ON demo.customers (c_nationkey)
INCLUDE (c_companylogo);
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
			NULL
		);
GO

/*
	THIS DOES NOT WORK!!!!

	CREATE NONCLUSTERED INDEX nix_demo_customers_c_nationkey
	ON demo.customers (c_nationkey)
	INCLUDE (c_companylogo)
	TEXTIMAGE ON (blob_data]);
*/

