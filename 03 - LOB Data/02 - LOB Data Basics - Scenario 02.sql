/*
	============================================================================
	File:		02 - LOB Data Basics - Scenario 02.sql

	Summary:	This script is a copy of the first script but with this script
				we insert a picture which has a size of ~500 Kbytes!

	Date:		April 2024
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

CHECKPOINT;
GO

/* Now we insert a big picture which cannot fit on one data page */
BEGIN TRANSACTION UpdateRecord
GO
	;WITH pic
	AS
	(
		/* Size of data file: 465 KBytes */
		SELECT	blob_binary
		FROM	system.blob_data
		WHERE	id = 2
	)
	UPDATE	c
	SET		c.c_companylogo = p.blob_binary
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
	(1:57240:0)
*/
DBCC TRACEON (3604);
DBCC PAGE (0, 1, 57240, 3) WITH TABLERESULTS;
GO