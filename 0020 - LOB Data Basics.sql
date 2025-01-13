/*
	============================================================================
	File:		0020 - LOB Data Basics.sql

	Summary:	This script demonstrates the basic behavior of usage of LOB
				in a table

	Date:		October 2024
	Session:	SQL Server - LOB Data Management

	SQL Server Version: 2008 - 2019
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
USE ERP_Demo;
GO

DROP TABLE IF EXISTS demo.customers;
GO

SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment,
		CAST(NULL AS VARBINARY(MAX))	AS	c_companylogo
INTO	demo.customers
FROM	dbo.customers
WHERE	1 = 0;
GO

ALTER TABLE demo.customers
ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey);
GO

/*
	Insert 1.000 rows into the new table
*/
INSERT INTO demo.customers
(c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment)
SELECT	TOP (1000)
		c_custkey,
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
FROM	dbo.table_structure_info
		(
			N'demo.customers',
			N'U',
			1
		);
GO

/*
	There should be ~40 rows on one data page!
*/
SELECT	sys.fn_physLocFormatter(%%physloc%%) AS Position,
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
WHERE	c_custkey <= 100;
GO

/*
	See, how the data are organized on the data page
	NOTE: We have ~150 Bytes free on the data page!
	(1:2313608:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 2313608, 3) WITH TABLERESULTS;
GO

CHECKPOINT;
GO 5

BEGIN TRANSACTION UpdateRecord
GO
	;WITH pic
	AS
	(
		/* Size of data file: 465 KBytes */
		SELECT	Picture
		FROM	OPENROWSET(BULK N'S:\Pictures\Pic01.jpg', SINGLE_BLOB) as T1(Picture)
	)
	UPDATE	c
	SET		c.c_companylogo = p.Picture
	FROM	demo.Customers AS c
			CROSS JOIN pic AS p
	WHERE	c.c_custkey = 1;
	GO

	SELECT	fd.[Current LSN],
			fd.Operation,
			fd.Context,
			fd.[Log Record Length],
			fd.AllocUnitId,
			fd.AllocUnitName,
			fd.[Page ID],
			fd.[Slot ID]
	FROM	sys.fn_dblog(NULL, NULL) AS fd
	WHERE	Context <> 'LCX_NULL'
			AND LEFT(fd.[Current LSN], LEN(fd.[Current LSN]) - 5) IN
				(
					SELECT	LEFT([Current LSN], LEN([Current LSN]) - 5)
					FROM	sys.fn_dblog(NULL, NULL)
					WHERE	[Transaction Name] = 'UpdateRecord'
				)
	ORDER BY
			fd.[Current LSN];
	GO

COMMIT TRANSACTION UpdateRecord;
GO

/*
	What is the distribution of data?
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
FROM	dbo.table_structure_info
		(
			N'demo.customers',
			N'U',
			1
		);
GO


/*
	How did SQL Server store the data?
*/
SELECT	sys.fn_physLocFormatter(%%physloc%%) AS Position,
		c_custkey,
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
	See, how the data are organized on the data page
	(1:2313608:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 2313608, 3) WITH TABLERESULTS;
GO

/*
	TEXT TREE PAGE! - holds large chunks of LOB values from a single column value.
	(1:2305513:0)
*/
DBCC PAGE (0, 1, 2305513, 3);
GO

/* TEXT_MIXED_PAGE! - small chunks of LOB values plus internal parts of text tree */
DBCC PAGE (0, 1, 2252600, 3);
GO

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
FROM	demo.Customers
WHERE	c_custkey = 1;
GO

CHECKPOINT;
GO 5

BEGIN TRANSACTION UpdateRecord
GO
	;WITH pic
	AS
	(
		SELECT	Picture
		FROM	OPENROWSET(BULK N'S:\Pictures\Pic02.jpg', SINGLE_BLOB) as T1(Picture)
	)
	UPDATE	c
	SET		c.c_companyLogo = p.Picture
	FROM	demo.Customers AS c
			CROSS JOIN pic AS p
	WHERE	c.c_custkey = 2;
	GO

	SELECT	fd.[Current LSN],
			fd.Operation,
			fd.Context,
			fd.[Log Record Length],
			fd.AllocUnitId,
			fd.AllocUnitName,
			fd.[Page ID],
			fd.[Slot ID]
	FROM	sys.fn_dblog(NULL, NULL) AS fd
	WHERE	Context <> 'LCX_NULL'
			AND LEFT(fd.[Current LSN], LEN(fd.[Current LSN]) - 5) IN
				(
					SELECT	LEFT([Current LSN], LEN([Current LSN]) - 5)
					FROM	sys.fn_dblog(NULL, NULL)
					WHERE	[Transaction Name] = 'UpdateRecord'
				)
	ORDER BY
			fd.[Current LSN];
	GO

COMMIT TRANSACTION UpdateRecord;
GO


SELECT	sys.fn_physLocFormatter(%%physloc%%) AS Position,
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
WHERE	c_custkey <= 60;
GO

/*
	Will the second LOB entry use it's own TEXT TREE PAGE?
	(1:2331736:1)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 2331736, 3) WITH TABLERESULTS;
GO

/*
	TEXT TREE PAGE! - holds large chunks of LOB values from a single column value.
	(1:2244081:0)
*/
DBCC PAGE (0, 1, 2244081, 3);
/* TEXT_MIXED_PAGE! - small chunks of LOB values plus internal parts of text tree */
DBCC PAGE (0, 1, 2252600, 3);
GO



/*
	Update a few more rows and add pictures
*/
DECLARE	@c_custkey BIGINT = 3;

WHILE @c_custkey < 10
BEGIN
	;WITH pic
	AS
	(
		SELECT	Picture
		FROM	OPENROWSET(BULK N'S:\Pictures\Pic03.jpg', SINGLE_BLOB) as T1(Picture)
	)
	UPDATE	c
	SET		c.c_companylogo = p.Picture
	FROM	demo.Customers AS c
			CROSS JOIN pic AS p
	WHERE	c.c_custkey = @c_custkey;

	SET @c_custkey += 1;
END
GO

SELECT	sys.fn_physLocFormatter(%%physloc%%) AS Position,
		c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment,
        c_companylogo
FROM	demo.customers
WHERE	c_custkey <= 30;
GO

/*
	Will the second LOB entry use it's own TEXT TREE PAGE?
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 2252392, 3) WITH TABLERESULTS;
/*
	TEXT TREE PAGE! - holds large chunks of LOB values from a single column value.
	(1:2244081:0)
*/
DBCC PAGE (0, 1, 2244081, 3);
/* TEXT_MIXED_PAGE! - small chunks of LOB values plus internal parts of text tree */
DBCC PAGE (0, 1, 2252600, 3);
GO