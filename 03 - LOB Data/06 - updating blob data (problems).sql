/*============================================================================
	File:		0060 - updating LOB data (problems).sql

	Summary:	This script demonstrates the problems of page splits
				when it comes to updates on (B)LOB data.

	Date:		April 2025
	Session:	SQL Server - LOB Data Management

	SQL Server Version: >=2016
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
DROP TABLE IF EXISTS demo.customers;
GO

CREATE TABLE demo.customers
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
	Now we insert 1.6 Mio rows into the demo table BUT we don't fill
	the company logo!
*/
INSERT INTO demo.customers WITH (TABLOCK)
(c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment)
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	dbo.customers;
GO

/*
	What different types of data pages have been allocated
	As long as (B)LOB data fit into the same page as the row
	itself NO LOB pages will be used!
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
    Due to the fact that the picture is so small that it fits with the
    record into ONE data page it is stored automatically with the record
    on the same page!
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
WHERE	c.c_custkey <= 50
ORDER BY
		c.c_custkey;
GO

/*
	Let's have a look to the page header of the page where
	the first ~40 rows are stored:
*/
DBCC TRACEON (3604);
DBCC PAGE(0, 1, 9008, 1)

/*
	What will happen, if we update 10 rows with a company logo.
	NOTE:	The table is configured to use a separate filegroup
			for the storage of LOB data.
			The pointer consumes 24 Bytes!
*/
;WITH pic
AS
(
	SELECT	blob_binary
	FROM	system.blob_data
	WHERE	id = 1
)
UPDATE	c
SET		c.c_companylogo = p.blob_binary
FROM	demo.Customers AS c
		CROSS JOIN pic AS p
WHERE	c_custkey <= 20
		AND c_custkey % 2 = 0;
GO

/*
    Due to the fact that the picture is so small that it fits with the
    record into ONE data page it is stored automatically with the record
    on the same page!
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
WHERE	c.c_custkey <= 50
ORDER BY
		c.c_custkey;
GO

/*
	Let's have a look to the page header of the page where
	the first ~40 rows are stored:
*/
DBCC TRACEON (3604);
DBCC PAGE(0, 1, 9008, 3)


/*
	How can we prevent the page splits when we must update LOB
	attributes in a row?

	Set ALWAYS a default value EVEN the LOB can be NULLable!
*/
/*
	We recreate the demo table to separate the LOB data in a separate filegroup.
*/
DROP TABLE IF EXISTS demo.customers;
GO

CREATE TABLE demo.customers
(
	c_custkey		BIGINT		NOT NULL,
	c_mktsegment	CHAR(10)	NULL,
	c_nationkey		INT			NOT NULL,
	c_name			VARCHAR(25)	NULL,
	c_address		VARCHAR(40)	NULL,
	c_phone			CHAR(15)	NULL,
	c_acctbal		MONEY		NULL,
	c_comment		VARCHAR(118)	NULL,
	c_companylogo	VARBINARY(MAX)	NULL	CONSTRAINT df_demo_customers_c_companylogo DEFAULT (0x00),

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
	Again we fill the table with 1.6 Mio rows but now with a default for the c_companylogo
*/
INSERT INTO demo.customers WITH (TABLOCK)
(c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment)
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	dbo.customers;
GO

/*
	What different types of data pages have been allocated
	As long as (B)LOB data fit into the same page as the row
	itself NO LOB pages will be used!
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
	On what data pages are the records stored?
*/
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
WHERE	c_custkey <= 50;
GO

/*
	What will happen, if we update 10 rows with a company logo.
	NOTE:	The table is configured to use a separate filegroup
			for the storage of LOB data.
			The pointer consumes 16 Bytes!
*/
;WITH pic
AS
(
	SELECT	blob_binary
	FROM	system.blob_data
	WHERE	id = 1
)
UPDATE	c
SET		c.c_companylogo = p.blob_binary
FROM	demo.Customers AS c
		CROSS JOIN pic AS p
WHERE	c_custkey <= 20
		AND c_custkey % 2 = 0;
GO

/*
	On what data pages are the records stored?
*/
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
WHERE	c_custkey <= 50;
GO
