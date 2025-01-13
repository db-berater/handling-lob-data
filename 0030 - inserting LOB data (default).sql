/*
	============================================================================
	File:		0030 - inserting LOB data (default).sql

	Summary:	This script demonstrates the behavior of LOB data before
				SQL Server 2005.

	Date:		December 2024
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
FROM	dbo.table_structure_info
		(
			N'demo.customers',
			N'U',
			1
		);
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
FROM	demo.Customers;
GO

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
FROM	demo.Customers;
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
FROM	dbo.table_structure_info
		(
			N'demo.customers',
			N'U',
			1
		);
GO

SET STATISTICS IO, TIME ON;
GO

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
FROM	demo.Customers;
GO

SELECT	sys.fn_physlocformatter(%%physloc%%) AS Position,
		c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	demo.Customers;
GO