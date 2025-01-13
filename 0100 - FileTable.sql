/*============================================================================
	File:		0100 - Filetables

	Summary:	This script demonstrates how you can store data in File Tables.

				THIS SCRIPT IS PART OF THE TRACK:
				"SQL Server - LOB Data Management"

	Date:		December 2022

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
USE master;
GO

EXEC dbo.sp_create_demo_db;
GO

/*
	FileTables extend the capabilities of the FILESTREAM feature of SQL Server.
	Therefore you have to enable FILESTREAM for file I/O access at the Windows
	level and on the instance of SQL Server.
*/
EXEC sp_configure N'filestream_access_level', 2;
RECONFIGURE WITH OVERRIDE;
GO

SELECT	DB_NAME(database_id),
		non_transacted_access,
		non_transacted_access_desc
FROM	sys.database_filestream_options
WHERE	database_id = DB_ID(N'demo_db');
GO

ALTER DATABASE demo_db
SET FILESTREAM
(
	NON_TRANSACTED_ACCESS = FULL
) WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE demo_db
SET FILESTREAM
(
	DIRECTORY_NAME = 'SQLFileTable'
) WITH ROLLBACK IMMEDIATE;
GO

SELECT	DB_NAME(database_id),
		non_transacted_access,
		non_transacted_access_desc,
		directory_name
FROM	sys.database_filestream_options
WHERE	database_id = DB_ID(N'demo_db');
GO

/*
	Before you can create FileTables in a database, the database must have a
	FILESTREAM filegroup.
*/
ALTER DATABASE demo_db ADD FILEGROUP FSGroup CONTAINS FILESTREAM;
GO

ALTER DATABASE demo_db
ADD FILE
(
	NAME = N' CustomerPics',
	FILENAME = N'S:\FileTables\CustomerPics'
)
TO FILEGROUP FSGroup;
GO

/* Cross check of preparations */
USE demo_db;
GO

SELECT	df.name				AS	Logical_name,
		df.size / 128		AS	size_mb,
		fg.name				AS	filegroup_name,
		df.physical_name	AS	physical_location
FROM	sys.database_files AS df
		LEFT JOIN sys.filegroups AS fg
		ON (df.data_space_id = fg.data_space_id);
GO

CREATE TABLE dbo.CustomerFiles
AS FILETABLE
WITH 
(
    FileTable_Directory = 'CustomerFiles',
    FileTable_Collate_Filename = database_default
);
GO

SELECT * FROM sys.filetables;

/*
	After directories and files have been copied to the directory
	we can now create hierarchies and infos about the file in the
	directory!
*/
WITH folders
AS
(
	SELECT	name,
			path_locator,
			file_type,
			cached_file_size,
			creation_time,
			last_write_time,
			last_access_time,
			1					AS level
	FROM	dbo.CustomerFiles
	WHERE	is_directory = 1
			AND parent_path_locator IS NULL

	UNION ALL

	SELECT	c.name,
			c.path_locator,
			c.file_type,
			c.cached_file_size,
			c.creation_time,
			c.last_write_time,
			c.last_access_time,
			f.level + 1			AS	level
	FROM	dbo.CustomerFiles AS c
			INNER JOIN folders AS f
			ON (c.parent_path_locator = f.path_locator)
	WHERE	is_directory = 1
)
SELECT	f.level,
		REPLICATE('--', f.level - 1) + '> ' + f.name,
        f.file_type,
        f.cached_file_size,
        f.creation_time,
        f.last_write_time,
        f.last_access_time,
        f.level
FROM	folders AS f
ORDER BY
		f.level;
GO
