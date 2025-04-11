/*
	============================================================================
	File:		01 - LOB Data Basics - Scenario 01.sql

	Summary:	This script demonstrates the basic behavior of usage of LOB
				in a table

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
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

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
FROM	dbo.customers
WHERE	c_custkey <= 1000;
GO

/*
	We now check the page allocations for the inserted rows.
	NOTE: This function is part of the framework in ERP_Demo database
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

DBCC TRACEON (3604);
DBCC PAGE (0, 1, 37937, 3);
DBCC PAGE (0, 1, 56680, 3);
GO

/*
	There should be ~40 -  44 rows on one data page!
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
ORDER BY
		c.c_custkey;
GO

/*
	See, how the data are organized on the data page
	NOTE: We have ~150 Bytes free on the data page!
	(1:57240:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 48648, 3) WITH TABLERESULTS;
GO

CHECKPOINT;
GO

/* Let's first insert a small picture which fits on one data page */
BEGIN TRANSACTION UpdateRecord
GO
	;WITH pic
	AS
	(
		/* Size of data file: 4.582 Bytes */
		SELECT	blob_binary
		FROM	system.blob_data
		WHERE	id = 1
	)
	UPDATE	c
	SET		c.c_companylogo = p.blob_binary
	FROM	demo.Customers AS c
			CROSS JOIN pic AS p
	WHERE	c.c_custkey = 1;
	GO

	/* What happened inside the named transaction? */
	SELECT	fd.[Current LSN],
			fd.Operation,
			fd.Context,
			fd.[Log Record Length],
			fd.AllocUnitName,
			fd.[Page ID],
			fd.[Slot ID]
	FROM	sys.fn_dblog(NULL, NULL) AS fd
	WHERE	Context <> N'LCX_NULL'
			AND Operation <> N'LOP_INSYSXACT'
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
	We now check the page allocations for the inserted rows.
	NOTE: This function is part of the framework in ERP_Demo database
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
	How did SQL Server store the data?
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
ORDER BY
		c.c_custkey;
GO

/*
	See, how the data are organized on the data page
	(1:57240:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 64920, 3) WITH TABLERESULTS;
GO

DBCC CHECKDB('test') WITH ALL_INFOMSGS