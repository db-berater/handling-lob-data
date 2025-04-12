/*============================================================================
	File:		05 - inserting LOB data (force LOB storage).sql

	Summary:	This script demonstrates forcing the usage of dedicated
				usage of (B)lob Storage whether it is so small that it
				fits to the regular row page.

	Date:		April 202´5
	Session:	SQL Server - LOB Data Management

	SQL Server Version: >= 2026
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

DROP TABLE IF EXISTS demo.customers;
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

EXEC dbo.InsertCustomers
	@iteration_name = '05 - inserting LOB data (force LOB storage) - small blob size',
	@num_of_iterations = 1000,
	@small_picture = 1,
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

/*
	As cool it is to separate LOB data into a different filegroup or
	even out of row there could be some drawbacks if the avg size of
	a LOB is less than 8.192 Bytes!
*/
SELECT	fpl.page_id,
		fpl.slot_id,
		c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        c.c_comment,
		c.c_companylogo
FROM	demo.Customers AS c
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS fpl
WHERE	c.c_custkey <= 10
ORDER BY
		c.c_custkey;
GO

/*
	If we force LOB data out of rows Microsoft SQL Server will create for
	every LOB entry a NEW data page / mixed text page + text page(s)
	This could lead to waste of memory because a page will/cannot be used by
	multiple row entries!!!
	(1:2338408:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 2529456, 3) WITH TABLERESULTS;

/*
	Have a look to the LOB data on the separated data page in the LOB filegroup (3)
	(3:76584:1)
*/
DBCC PAGE (0, 3, 76584, 1);
GO

EXEC dbo.InsertCustomers
	@iteration_name = '05 - inserting LOB data (force LOB storage) - big blob size',
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

SELECT	sys.fn_physlocformatter(%%physloc%%) AS Position,
		c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment,
        c_companylogo
FROM	demo.Customers
WHERE	c_custkey <= 10;
GO