/*============================================================================
	File:		0080 - Optimize reading data in LOB tables 02.sql

	Summary:	This script demonstrates how you can improve the reading of data
				when it stores LOB data.

				THIS SCRIPT IS PART OF THE TRACK:
				"SQL Server - LOB Data Management"

	Date:		October 2024

	SQL Server Version: 2012 - 2022
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
	To optimize workloads we can move LOB data
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
FROM	dbo.table_structure_info
		(
			N'demo.customers',
			N'U',
			1
		);
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
	If a blob fits into a data page it will automatically stored 
	on the data page
*/
EXEC dbo.InsertCustomers
	@iteration_name = '0080 - optimize reading - big picture(s)',
	@num_of_iterations = 1000,
	@small_picture = 0,
	@drop_existing_table = 0;
GO

SET NOCOUNT ON;
SET STATISTICS IO ON;
GO

SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment,
		c_companylogo
FROM	demo.Customers;
GO

/*
	If LOB data are not on the same page as the in-row data
	SQL Server will not touch the LOB data and the IO is going down.
*/
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	demo.Customers;
GO