/*
	============================================================================
		File:		02 - ROW OVERFLOW DATA scenario 02.sql

		Summary:	This script demonstrates how Microsoft SQL Server store data
					when the row size exceeds the maximum number of 8,060 bytes

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
SET STATISTICS IO, TIME OFF;

USE ERP_Demo;
GO

/*
	We create a demo table with a VARCHAR(8000) attribute for the storage
	of visit descriptions.
*/
DROP TABLE IF EXISTS demo.customers;
GO

SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        CAST(c_name AS VARCHAR(256))	AS	c_name,
        c_address,
        c_phone,
        c_acctbal,
        CAST(NULL AS VARCHAR(8000))		AS	c_comment
INTO	demo.customers
FROM	dbo.customers
WHERE	1 = 0;
GO

CREATE UNIQUE CLUSTERED INDEX cuix_demo_customers_c_custkey
ON demo.customers (c_custkey);
GO

/*
	We insert 1000 rows into the table. Notice, that we only store the 
	customer name but no comment.
*/
INSERT INTO demo.Customers WITH (TABLOCK)
(c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment)
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        NULL
FROM	dbo.Customers
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

/*
	Let's see how many rows can fit on one data page!
	~75 - 78 rows can fit on one data page!
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
        c.c_comment
FROM	demo.Customers AS c
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS fpl
ORDER BY
		c.c_custkey;
GO

/*
	Now we update the customer with the c_custkey = 1 and extend the row as follows:
	c_comment becomes a length of	8.000 bytes!

	Question:	What will happen?
			a) the information of c_comment will be handled as ROW OVERFLOW
			b) the record will/must stay complete on ONE data page
*/
BEGIN TRANSACTION UpdateRecord;
GO
	UPDATE	demo.customers
	SET		c_comment = REPLICATE('b', 8000)
	WHERE	c_custkey = 1;

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
			AND AllocUnitName LIKE N'demo.customers%'
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

CHECKPOINT;
GO

SELECT	fpl.page_id,
		fpl.slot_id,
		c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        c.c_comment
FROM	demo.Customers AS c
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS fpl
ORDER BY
		c.c_custkey;
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

/* What page types have been allocated by the records */
SELECT	allocation_unit_id,
		allocation_unit_type_desc,
        allocated_page_page_id,
        is_iam_page,
        page_type,
        page_type_desc,
		page_free_space_percent
FROM	sys.dm_db_database_page_allocations
		(
			DB_ID(),
			OBJECT_ID(N'demo.Customers', N'U'),
			NULL,
			NULL,
			N'DETAILED'
		)
WHERE	is_allocated = 1
ORDER BY
		allocation_unit_id,
		page_type DESC;
GO

/*
	Length 24 Length (physical) 24	Level	0
	Length 24 Length (physical) 24	Unused	0
	Length 24 Length (physical) 24	UpdateSeq	1
	Length 24 Length (physical) 24	TimeStamp	2016804864
	Length 24 Length (physical) 24	Type	2
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
        c.c_comment
FROM	demo.Customers AS c
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS fpl
WHERE	c_custkey = 1;
GO

/*
	Let's get into the data page to see HOW the row overflow data are stored.
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 89464, 3) WITH TABLERESULTS;
GO

/* TEXT_MIXED_PAGE: (1:98664:0) */
DBCC PAGE (0, 1, 98664, 3);
GO

/*
	What is the IO of a table scan with a record with ROW_OVERFLOW data?
*/
SET STATISTICS IO ON;
GO

SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	demo.customers
WHERE	c_custkey = 1;
GO

SET STATISTICS IO OFF;
GO

/* Clean the kitchen */
DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA demo;
GO
