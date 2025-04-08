/*
	============================================================================
	File:		03 - inserting LOB data (default).sql

	Summary:	This script demonstrates the default behavior of Microsoft SQL Server
                when it handles BLOB Data which fits into the same page as the
                record itself!

	Date:		April 2025
	Session:	SQL Server - LOB Data Management

	SQL Server Version: >= 2016
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

/*
	If a blob fits into a data page it will automatically stored 
	on the data page
*/
EXEC	dbo.InsertCustomers
		@iteration_name = '0030 - inserting LOB data (default) - small blob size',
		@num_of_iterations = 1000,
		@small_picture = 1,
		@drop_existing_table = 1;
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

SET STATISTICS IO ON;
GO

/*
    The first query does consider the picture in c_companylogo
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
    ... while the second query does not!
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

SET STATISTICS IO OFF;
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
ORDER BY
		c.c_custkey;
GO


/*
	If the LOB data are larger and it cannot fit on the same
	page as the rows itself, SQL Server move the BLOB to dedicated
	BLOB pages
*/
EXEC	dbo.InsertCustomers
	@iteration_name = '0030 - inserting LOB data (default) - big blob size',
	@num_of_iterations = 1000,
	@small_picture = 0,
	@drop_existing_table = 1;
GO

/*
	What different types of data pages have been allocated
	The LOB is larger extents the row size and gets automatically
	moved into a separate LOB space!
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