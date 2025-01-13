/*============================================================================
	File:		0070 - Optimize reading data in LOB tables 01.sql

	Summary:	This script demonstrates how you can improve the reading of data
				when it stores LOB data.

				THIS SCRIPT IS PART OF THE TRACK:
				"SQL Server - LOB Data Management"

	Date:		October 2022

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
	If a blob fits into a data page it will automatically stored 
	on the data page
*/
EXEC dbo.InsertCustomers
	@iteration_name = '0070 - optimize reading - small picture(s)',
	@num_of_iterations = 1000,
	@small_picture = 1,
	@drop_existing_table = 1;
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

SET NOCOUNT ON;
SET STATISTICS IO ON;
GO

/*
	Now we read all the rows from the table and will see a lot
	of lob data pages read.
*/
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
	but even if we do not address the LOB column we mus read the
	data from the LOB!
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

/*
	How can we optimize this behavior?
	We create an index on all - but not the BLOB - columns!
*/
CREATE UNIQUE NONCLUSTERED INDEX x3
ON demo.Customers
(
	c_custkey
)
INCLUDE
(
	c_mktsegment,
	c_nationkey,
	c_name,
	c_address,
	c_phone,
	c_acctbal,
	c_comment
);
GO

/*
	When we run the same query agaion the LOB is not part of the indexe
	and this will reduce the IO.
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
