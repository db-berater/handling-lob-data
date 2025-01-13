/*
	============================================================================
	File:		01 - extended event - physical_page_write.sql

	Summary:	This script creates an extended event which counts in a histogram
				the number of page writes.

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
IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'Multiple_File_Load')
	DROP EVENT SESSION [Multiple_File_Load] ON SERVER 
	GO

CREATE EVENT SESSION [Multiple_File_Load]
	ON SERVER
	ADD EVENT sqlserver.physical_page_write
	(WHERE [sqlserver].[database_name] = N'ERP_Demo')
	ADD TARGET package0.histogram
	(
		SET filtering_event_name = N'sqlserver.physical_page_write',
			source = N'file_id',
			source_type = 0
	)
	WITH
	(
		MAX_MEMORY = 4096KB ,
		EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
		MAX_DISPATCH_LATENCY = 5 SECONDS ,
		MAX_EVENT_SIZE = 0KB ,
		MEMORY_PARTITION_MODE = NONE ,
		TRACK_CAUSALITY = OFF ,
		STARTUP_STATE = ON
	);
GO

ALTER EVENT SESSION Multiple_File_Load ON SERVER STATE = START;
GO