/*
	============================================================================
	File:		01 - Environment Preparation.sql

	Summary:	This script restores the database ERP_Demo which gets
				used for the demos of this session

				Additional objects (views / stored procedures) will be installed
				in master database for the demonstrations

	Date:		December 2022
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
USE master;
GO

EXEC dbo.sp_restore_ERP_demo @query_store = 1;

GO

USE ERP_Demo;
GO

EXEC dbo.sp_create_indexes_customers;
GO

/*
	Let's create a demo table for the customers!
*/
IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA demo AUTHORIZATION dbo;'
	GO


USE ERP_Demo;
GO

DROP TABLE IF EXISTS dbo.Runtime;
GO

CREATE TABLE dbo.Runtime
(
	Id			INT				NOT NULL	IDENTITY (1, 1),
	name		VARCHAR(256)	NOT NULL,
	num_of_rows	BIGINT			NOT NULL	DEFAULT (0),
	start_date	DATETIME2(7)	NOT NULL,
	end_date	DATETIME2(7)	NULL,
	diff_ms	AS	DATEDIFF(MILLISECOND, start_date, end_date),

	PRIMARY KEY CLUSTERED (Id)
);
GO

CREATE OR ALTER PROCEDURE dbo.InsertCustomers
	@iteration_name			VARCHAR(256),
	@num_of_iterations		INT = 0,
	@small_picture			INT = 0,
	@drop_existing_table	INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE	@Id			INT;
	DECLARE	@counter	INT = 1;

	IF @num_of_iterations = 0
		SET	@num_of_iterations = (SELECT COUNT_BIG(*) FROM dbo.customers);

	IF @drop_existing_table = 1
	BEGIN
		DROP TABLE IF EXISTS demo.customers;

		SELECT	c_custkey,
				c_mktsegment,
				c_nationkey,
				c_name,
				c_address,
				c_phone,
				c_acctbal,
				c_comment,
				CAST(NULL AS VARBINARY(MAX))	c_companylogo
		INTO	demo.customers
		FROM	dbo.customers
		WHERE	1 = 0;
	
		ALTER TABLE demo.customers
		ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey);
	END
	ELSE
		TRUNCATE TABLE demo.customers;

	DECLARE	@start_date	DATETIME2(7) = GETDATE();
	DECLARE	@end_date DATETIME2(7);

	WHILE @counter <= @num_of_iterations
	BEGIN
		WITH pic (picture)
		AS
		(
			/*
				If the variable @small_picture  = 0
				we take the 400K picture (id = 2)
				else we take the 4K picture (id = 1)
			*/
			SELECT	blob_binary
			FROM	system.blob_data
			WHERE	id = CASE WHEN @small_picture = 0
								THEN 2
								ELSE 1
							END
		)
		INSERT INTO demo.customers
		(c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment, c_companylogo)
		SELECT	c.c_custkey,
                c.c_mktsegment,
                c.c_nationkey,
                c.c_name,
                c.c_address,
                c.c_phone,
                c.c_acctbal,
                c.c_comment,
				pic.picture
		FROM	dbo.customers AS c
				CROSS JOIN pic
		WHERE	c.c_custkey = @counter;

		SET	@counter += 1;
	END

	BEGIN TRANSACTION
		SET	@end_date = GETDATE();
		INSERT INTO dbo.Runtime WITH (TABLOCK)
		(name, num_of_rows, start_date, end_date)
		VALUES
		(@iteration_name, @num_of_iterations, @start_date, @end_date);

		SET	@Id = SCOPE_IDENTITY();
		SELECT	name,
				num_of_rows,
				start_date,
				end_date,
				FORMAT(diff_ms, N'#,##0 ms', N'de-de') AS diff_ms
		FROM	dbo.Runtime
		WHERE	Id = @Id;
	COMMIT TRANSACTION;
END
GO