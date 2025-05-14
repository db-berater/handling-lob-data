/*
	============================================================================
		File:		01 - ROW OVERFLOW DATA - row size matters.sql

		Summary:	This script demonstrates that not the filling grade of a page
					is mandatory for the usage of ROW OVERFLOW DATA!

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

/* Let's create a table with a - possible - row size of > 8060 bytes */
IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA demo AUTHORIZATION dbo;';
GO

DROP TABLE IF EXISTS demo.demo_table;
GO

CREATE TABLE demo.demo_table
(
	id	INT				NOT NULL	IDENTITY (1, 1)	PRIMARY KEY CLUSTERED,
	c1	VARCHAR(256)	NOT NULL,
	c2	VARCHAR(8000)	NOT NULL
);
GO

/* Let's insert n rows to fill the page to 50% */
INSERT INTO demo.demo_table
(c1, c2)
SELECT	c_name,
		c_comment
FROM	dbo.customers
WHERE	c_custkey <= 20;
GO

/* On what page(s) are the records stored? */
SELECT	plc.*,
		dt.*
FROM	demo.demo_table AS dt
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS plc
GO

/*
	Let's check the filling grade of the data page
	There are another 5828 bytes free for new data
*/
SELECT	page_type_desc,
		file_id,
		page_id,
		page_level,
		object_id,
		index_id,
		free_bytes,
		free_bytes_offset
FROM	sys.dm_db_page_info(DB_ID(), 1, 48384, N'DETAILED');
GO

/*
	We now insert another row into the table.
	The size of the data is 5.660 bytes!

	Will this row fit on the data page?
	Will only c1 stay on the same page and c2 will be OVERFLOW data?
*/
INSERT INTO demo.demo_table
(c1, c2)
VALUES
(
	REPLICATE('A', 200),
	REPLICATE('B', 5460)
);
GO

/* On what page(s) are the records stored? */
SELECT	plc.*,
		dt.*
FROM	demo.demo_table AS dt
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS plc
GO

/*
	Let's check the filling grade of the data page
*/
SELECT	page_type_desc,
		file_id,
		page_id,
		page_level,
		object_id,
		index_id,
		free_bytes,
		free_bytes_offset
FROM	sys.dm_db_page_info(DB_ID(), 1, 48384, N'DETAILED');
GO

/*
	We should have 149 bytes free space on the data page
	Let's one more record with 8.1xx bytes of row size!

	What will happen?
	- The record will be stored on the same page as the other records?
	- and the value for column c2 will be stored as ROW OVERFLOW DATA?

	- The record will be stored a new page and the complete row is stored on that page?
*/
INSERT INTO demo.demo_table
(c1, c2)
VALUES
(
	REPLICATE('A', 100),
	REPLICATE('B', 8000)
);
GO

SELECT	plc.*,
		dt.*
FROM	demo.demo_table AS dt
		CROSS APPLY sys.fn_physloccracker(%%physloc%%) AS plc
GO

/* Let's check the filling grade of the data page */
SELECT	page_type_desc,
		file_id,
		page_id,
		page_level,
		object_id,
		index_id,
		free_bytes,
		free_bytes_offset
FROM	sys.dm_db_page_info(DB_ID(), 1, 48384, N'DETAILED');
GO

/* Clean the kitchen */
DROP TABLE IF EXISTS demo.demo_table;
DROP SCHEMA demo;
GO
