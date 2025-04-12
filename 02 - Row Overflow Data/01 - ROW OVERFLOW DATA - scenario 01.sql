/*
	============================================================================
		File:		01 - ROW OVERFLOW DATA scenario 01.sql

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

IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA demo AUTHORIZATION dbo;';
GO

/*
	Let's create the indexes on dbo.customers first for better performance of the demos!

	NOTE: This function is part of the framework in ERP_Demo database
*/
EXEC sp_create_indexes_customers;
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
		COUNT_BIG(*)	AS	number_of_rows
FROM	demo.Customers AS c
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS fpl
GROUP BY
		fpl.page_id
ORDER BY
		fpl.page_id;
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
	Now we update one record by entering a comment of 5,714 bytes

	Question:	What will happen?
				a) the information of c_comment will be handled as ROW OVERFLOW
				b) the record will/must stay complete on ONE data page
*/
BEGIN TRANSACTION UpdateRecord;
GO
	;WITH b
	AS
	(
		/* We update the column with a 5.714 bytes string */
		SELECT	blob_string
		FROM	system.blob_data
		WHERE	id = 1
	)
	UPDATE	c
	SET		c.c_comment = b.blob_string
	FROM	demo.customers AS c
			CROSS JOIN b
	WHERE	c.c_custkey = 1;

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
	Check the allocated space in the database.
	Nothing should have changed!

	Note:	If the length of a record will fit into one data page
			we do not generate ROW OVERFLOW data!

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

CHECKPOINT;
GO


/* Clean the kitchen */
DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA demo;
GO
